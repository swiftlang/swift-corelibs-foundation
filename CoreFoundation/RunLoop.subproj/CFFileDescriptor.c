/*	CFFileDescriptor.c
	Copyright (c) 1998-2021, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
	Responsibility: Serhii Mumriak
*/

// #if TARGET_OS_LINUX

#include <CoreFoundation/CFFileDescriptor.h>
#include <CoreFoundation/CFRunLoop.h>
#include <dlfcn.h>
#include <sys/epoll.h>
#include "CFInternal.h"
#include "CFRuntime_Internal.h"
#include <stdio.h>

CF_ENUM(CFIndex, CFFileDescriptorState) {
    CFFileDescriptorStateReady = 0,
    CFFileDescriptorStateInvalidating = 1,
    CFFileDescriptorStateInvalid = 2,
    CFFileDescriptorStateDeallocating = 3
};

struct __CFFileDescriptor {
    CFRuntimeBase _base;
    CFFileDescriptorState _state;
    CFFileDescriptorNativeDescriptor _fileDescriptor;
    CFFileDescriptorNativeDescriptor _epollFileDescriptor;
    Boolean _closeOnInvalidate;
    CFFileDescriptorCallBackIdentifier _callBackIdentifiers;
    CFLock_t _lock;
    CFRunLoopSourceRef _source;
    CFFileDescriptorCallBack _callout;
    CFFileDescriptorInvalidationCallBack _invalidationCallout;
    CFFileDescriptorContext _context;
};

CF_INLINE Boolean __CFFileDescriptorIsValid(CFFileDescriptorRef fdp) {
    return CFFileDescriptorStateReady == fdp->_state;
}

// Only call with fdp->_lock locked
CF_INLINE void __CFFileDescriptorInvalidateLocked(CFRunLoopSourceRef source, CFFileDescriptorRef fdp) {
    CFFileDescriptorInvalidationCallBack invalidationCallout = fdp->_invalidationCallout;
    void *const info = fdp->_context.info;
    void (*const release)(const void *info) = fdp->_context.release;

    fdp->_context.info = NULL;
    
    if (invalidationCallout) {
        __CFUnlock(&fdp->_lock);
        invalidationCallout(fdp, info);
        __CFLock(&fdp->_lock);
    }

    if (NULL != source) {
        __CFUnlock(&fdp->_lock);
        CFRunLoopSourceInvalidate(source);
        CFRelease(source);
        __CFLock(&fdp->_lock);
    }

    if (release && info) {
        __CFUnlock(&fdp->_lock);
        release(info);
        __CFLock(&fdp->_lock);
    }

    close(fdp->_epollFileDescriptor);

    if (fdp->_closeOnInvalidate) {
        close(fdp->_fileDescriptor);
    }

    fdp->_state = CFFileDescriptorStateInvalid;
    OSMemoryBarrier();
}

static CFFileDescriptorNativeDescriptor __CFFileDescriptorGetEpollFileDescriptor(void *info) {
    CFFileDescriptorRef fdp = (CFFileDescriptorRef)info;
    return fdp->_epollFileDescriptor;
}

CF_INLINE void __CFFileDescriptorAddEpollLocked(CFFileDescriptorRef fdp) {
    struct epoll_event epollEvent = {0};
    epollEvent.data.fd = fdp->_fileDescriptor;
    epollEvent.events = EPOLLONESHOT | EPOLLET;
    
    if ((fdp->_callBackIdentifiers & CFFileDescriptorCallBackIdentifierRead) != 0) {
        epollEvent.events |= EPOLLIN;
    }

    if ((fdp->_callBackIdentifiers & CFFileDescriptorCallBackIdentifierWrite) != 0) {
        epollEvent.events |= EPOLLOUT;
    }

    int epollCtlReturn = epoll_ctl(fdp->_epollFileDescriptor, EPOLL_CTL_ADD, fdp->_fileDescriptor, &epollEvent);
    
    if (epollCtlReturn != 0) {
        CFRunLoopSourceRef source = fdp->_source;
        fdp->_source = NULL;
        __CFFileDescriptorInvalidateLocked(source, fdp);
    }
}

CF_INLINE void __CFFileDescriptorRemoveEpollLocked(CFFileDescriptorRef fdp) {
    struct epoll_event epollEvent = {0};
    epollEvent.data.fd = fdp->_fileDescriptor;
    int epollCtlReturn = epoll_ctl(fdp->_epollFileDescriptor, EPOLL_CTL_DEL, fdp->_fileDescriptor, &epollEvent);
    
    if (epollCtlReturn != 0) {
        CFRunLoopSourceRef source = fdp->_source;
        fdp->_source = NULL;
        __CFFileDescriptorInvalidateLocked(source, fdp);
    }
}

static void __CFFileDescriptorPerform(void *info) {
    CFFileDescriptorRef fdp = (CFFileDescriptorRef)info;

    __CFLock(&fdp->_lock);

    void *contextInfo = NULL;
    void (*contextInfoRelease)(const void *) = NULL;

    if (fdp->_context.retain) {
        contextInfo = (void *)fdp->_context.retain(fdp->_context.info);
        contextInfoRelease = fdp->_context.release;
    } else {
        contextInfo = (void *)fdp->_context.info;
    }

    fdp->_callBackIdentifiers = 0;
    __CFFileDescriptorRemoveEpollLocked(fdp);

    __CFUnlock(&fdp->_lock);

    if (fdp->_callout) {
        fdp->_callout(fdp, contextInfo);
    }

    if (contextInfoRelease) {
        contextInfoRelease(contextInfo);
    }
}

static void __CFFileDescriptorDeallocate(CFTypeRef cf) {
    CFFileDescriptorRef fdp = (CFFileDescriptorRef)cf;

    __CFLock(&fdp->_lock);

    Boolean wasReady = (CFFileDescriptorStateReady == fdp->_state);
    CFRunLoopSourceRef source = NULL;

    if (wasReady) {
        fdp->_state = CFFileDescriptorStateInvalidating;
        OSMemoryBarrier();
        source = fdp->_source;
        fdp->_source = NULL;
    }    

    if (wasReady) {
        __CFFileDescriptorInvalidateLocked(source, fdp);
    }
    
    fdp->_state = CFFileDescriptorStateDeallocating;

    __CFUnlock(&fdp->_lock);
}

static Boolean __CFFileDescriptorEqual(CFTypeRef cf1, CFTypeRef cf2) {
    CFFileDescriptorRef fdp1 = (CFFileDescriptorRef)cf1;
    CFFileDescriptorRef fdp2 = (CFFileDescriptorRef)cf2;
    return (fdp1->_fileDescriptor == fdp2->_fileDescriptor);
}

static CFHashCode __CFFileDescriptorHash(CFTypeRef cf) {
    CFFileDescriptorRef fdp = (CFFileDescriptorRef)cf;
    return (CFHashCode)fdp->_fileDescriptor;
}

static CFStringRef __CFFileDescriptorCopyDescription(CFTypeRef cf) {
    CFFileDescriptorRef fdp = (CFFileDescriptorRef)cf;
    CFStringRef contextDesc = NULL;
    if (NULL != fdp->_context.info && NULL != fdp->_context.copyDescription) {
        contextDesc = fdp->_context.copyDescription(fdp->_context.info);
    }
    if (NULL == contextDesc) {
        contextDesc = CFStringCreateWithFormat(kCFAllocatorSystemDefault, NULL, CFSTR("<CFFileDescriptor context %p>"), fdp->_context.info);
    }
    Dl_info info;
    void *addr = fdp->_callout;
    const char *name = (dladdr(addr, &info) && info.dli_saddr == addr && info.dli_sname) ? info.dli_sname : "???";
    CFStringRef result = CFStringCreateWithFormat(kCFAllocatorSystemDefault, NULL, CFSTR("<CFFileDescriptor %p [%p]>{fileDescriptor = %x, source = %p, callout = %s (%p), context = %@}"), cf, CFGetAllocator(fdp), fdp->_fileDescriptor, fdp->_source, name, addr, contextDesc);
    if (NULL != contextDesc) {
        CFRelease(contextDesc);
    }
    return result;
}

// This lock protects __CFAllFileDescriptorPorts. Acquire this lock before acquiring any instance-specific lock in create or invalidate functions
static CFLock_t __CFAllFileDescriptorPortsLock = CFLockInit;

static CFMutableArrayRef __CFAllFileDescriptorPorts = NULL;

const CFRuntimeClass __CFFileDescriptorClass = {
    0                                   /* version */,
    "CFFileDescriptor"                  /* className */,
    NULL                                /* init */,
    NULL                                /* copy */,
    __CFFileDescriptorDeallocate        /* finalize */,
    __CFFileDescriptorEqual             /* equal */,
    __CFFileDescriptorHash              /* hash */,
    NULL                                /* copyFormattingDesc */,      
    __CFFileDescriptorCopyDescription   /* copyDebugDesc */
};

CFTypeID CFFileDescriptorGetTypeID(void) {
    return _kCFRuntimeIDCFFileDescriptor;
}

CFFileDescriptorRef CFFileDescriptorCreate(CFAllocatorRef allocator, CFFileDescriptorNativeDescriptor fileDescriptor, Boolean closeOnInvalidate, CFFileDescriptorCallBack callout, const CFFileDescriptorContext *context) {
    if (fileDescriptor == -1) {
        return NULL;
    }

    CFFileDescriptorRef fdp = NULL;

    __CFLock(&__CFAllFileDescriptorPortsLock);

    if (__CFAllFileDescriptorPorts != NULL) {
        CFIndex const portsCount = CFArrayGetCount(__CFAllFileDescriptorPorts);
        for (CFIndex idx = 0; idx < portsCount; idx++) {
            CFFileDescriptorRef const p = (CFFileDescriptorRef)CFArrayGetValueAtIndex(__CFAllFileDescriptorPorts, idx);
            if (p && p->_fileDescriptor == fileDescriptor) {
                CFRetain(p);
                fdp = p; // fdp now has +2 retain count:  1: from set  2: from this local retain
                break;
            }
        }
    }

    if (fdp) {
        __CFUnlock(&__CFAllFileDescriptorPortsLock);
        return fdp;        
    } else {
        // We need to create a new CFFileDescriptorRef. 
        // keep the global lock a bit longer, until we add it to the set of all ports.


        // there's a bug in kernel which makes all nested epoll file descriptors in edge-trigged mode behave like leve-triggered. the fix for this issue is not landed, details can be found in https://lkml.org/lkml/2019/9/2/17. because of that we can not just add fd to epoll fd as soon as possible, but rather have to add it every time client code enables callbacks. for the same reason every time the "perform" function is invoked by runloop the code removes file descriptor from epoll file descriptor. yea, this is a sad user-space workaround for kernel bug, but it is needed in order to NOT generate spam from file descriptors
        
        CFFileDescriptorNativeDescriptor epollFileDescriptor = epoll_create1(EPOLL_CLOEXEC);

        if (epollFileDescriptor == -1) {
            return NULL;
        }

        CFIndex const size = sizeof(struct __CFFileDescriptor) - sizeof(CFRuntimeBase);
        CFFileDescriptorRef const memory = (CFFileDescriptorRef)_CFRuntimeCreateInstance(allocator, CFFileDescriptorGetTypeID(), size, NULL);

        if (NULL == memory) {
            __CFUnlock(&__CFAllFileDescriptorPortsLock);
            return NULL;
        }

        memory->_fileDescriptor = fileDescriptor;
        
        memory->_epollFileDescriptor = epollFileDescriptor;
        memory->_callout = callout;
        memory->_lock = CFLockInit;
        memory->_closeOnInvalidate = closeOnInvalidate;

        if (NULL != context) {
            memmove(&memory->_context, context, sizeof(CFFileDescriptorContext));
            if (context->retain) {
                memory->_context.info = (void *)context->retain(context->info);
            }
        } else {
            memset(&memory->_context, 0, sizeof(CFFileDescriptorContext));
        }
        
        memory->_state = CFFileDescriptorStateReady;
        if (!__CFAllFileDescriptorPorts) {
            // Create the array of all file descriptor ports if it doesn't exist
            __CFAllFileDescriptorPorts = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
        }
        CFArrayAppendValue(__CFAllFileDescriptorPorts, memory);

        __CFUnlock(&__CFAllFileDescriptorPortsLock);

        fdp = memory;  // NOTE: at this point fdp has +2 retain count, 1: from birth  2: from being added to the set
    }

    if (fdp && !CFFileDescriptorIsValid(fdp)) { // must do this outside lock to avoid deadlock
        CFRelease(fdp); // NOTE: we release the extra +1 introduced in this function (or birth) so that the only potential refcount left for this frame is from the set of all ports.
        fdp = NULL;
    }
    return fdp;
}

CFFileDescriptorNativeDescriptor CFFileDescriptorGetNativeDescriptor(CFFileDescriptorRef fdp) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    CFFileDescriptorNativeDescriptor result = fdp->_fileDescriptor;

    __CFUnlock(&fdp->_lock);

    return result;
}

void CFFileDescriptorGetContext(CFFileDescriptorRef fdp, CFFileDescriptorContext *context) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());

    CFAssert1(0 == context->version, __kCFLogAssertion, "%s(): context version not initialized to 0", __PRETTY_FUNCTION__);

    __CFLock(&fdp->_lock);

    memmove(context, &fdp->_context, sizeof(CFFileDescriptorContext));

    __CFUnlock(&fdp->_lock);
}

CFFileDescriptorInvalidationCallBack CFFileDescriptorGetInvalidationCallBack(CFFileDescriptorRef fdp) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    CFFileDescriptorInvalidationCallBack result = fdp->_invalidationCallout;

    __CFUnlock(&fdp->_lock);

    return result;
}

void CFFileDescriptorSetInvalidationCallBack(CFFileDescriptorRef fdp, CFFileDescriptorInvalidationCallBack invalidationCallout) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    void *const info = fdp->_context.info;

    if (__CFFileDescriptorIsValid(fdp) || !invalidationCallout) {
        fdp->_invalidationCallout = invalidationCallout;
    } else if (!fdp->_invalidationCallout && invalidationCallout) {
        __CFUnlock(&fdp->_lock);
        invalidationCallout(fdp, info);
        __CFLock(&fdp->_lock);
    } else {
        CFLog(kCFLogLevelWarning, CFSTR("CFFileDescriptorSetInvalidationCallBack(): attempt to set invalidation callback (%p) on invalid CFFileDescriptor (%p) thwarted"), invalidationCallout, fdp);
    }

    __CFUnlock(&fdp->_lock);
}


void CFFileDescriptorEnableCallBacks(CFFileDescriptorRef fdp, CFOptionFlags callBackTypes) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    Boolean needsToBeRemoved = fdp->_callBackIdentifiers != 0;

    fdp->_callBackIdentifiers |= callBackTypes;

    if (__CFFileDescriptorIsValid(fdp) && needsToBeRemoved) {
        __CFFileDescriptorRemoveEpollLocked(fdp);
    }
    // fdp might become invalid during epoll remove
    if (__CFFileDescriptorIsValid(fdp)) {
        __CFFileDescriptorAddEpollLocked(fdp);
    }

    __CFUnlock(&fdp->_lock);
}

void CFFileDescriptorDisableCallBacks(CFFileDescriptorRef fdp, CFOptionFlags callBackTypes) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    Boolean needsToBeRemoved = fdp->_callBackIdentifiers != 0;

    fdp->_callBackIdentifiers &= ~callBackTypes;

    if (__CFFileDescriptorIsValid(fdp) && needsToBeRemoved) {
        __CFFileDescriptorRemoveEpollLocked(fdp);
    } 
    // fdp might become invalid during epoll remove
    if (__CFFileDescriptorIsValid(fdp)) {
        __CFFileDescriptorAddEpollLocked(fdp);
    }

    __CFUnlock(&fdp->_lock);
}

void CFFileDescriptorInvalidate(CFFileDescriptorRef fdp) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());

    CFRetain(fdp);

    __CFLock(&__CFAllFileDescriptorPortsLock);
    __CFLock(&fdp->_lock);

    Boolean wasReady = (CFFileDescriptorStateReady == fdp->_state);
    CFRunLoopSourceRef source = NULL;

    if (wasReady) {
        fdp->_state = CFFileDescriptorStateInvalidating;

        OSMemoryBarrier();
        
        if (__CFAllFileDescriptorPorts != NULL) {
            CFIndex const portsCount = CFArrayGetCount(__CFAllFileDescriptorPorts);
            for (CFIndex idx = 0; idx < portsCount; idx++) {
                CFFileDescriptorRef p = (CFFileDescriptorRef)CFArrayGetValueAtIndex(__CFAllFileDescriptorPorts, idx);
                if (p == fdp) {
                    CFArrayRemoveValueAtIndex(__CFAllFileDescriptorPorts, idx);
                    break;
                }
            }
        }

        source = fdp->_source;
        fdp->_source = NULL;
    }

    __CFUnlock(&fdp->_lock);
    __CFUnlock(&__CFAllFileDescriptorPortsLock);

    if (wasReady) {
        __CFLock(&fdp->_lock);
        __CFFileDescriptorInvalidateLocked(source, fdp);
        __CFUnlock(&fdp->_lock);
    }

    CFRelease(fdp);    
}

Boolean CFFileDescriptorIsValid(CFFileDescriptorRef fdp) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());
    __CFLock(&fdp->_lock);

    Boolean result = __CFFileDescriptorIsValid(fdp);

    __CFUnlock(&fdp->_lock);

    return result;
}

CFRunLoopSourceRef CFFileDescriptorCreateRunLoopSource(CFAllocatorRef allocator, CFFileDescriptorRef fdp, CFIndex order) {
    __CFGenericValidateType(fdp, CFFileDescriptorGetTypeID());

    CFRunLoopSourceRef result = NULL;

    __CFLock(&fdp->_lock);

    if (__CFFileDescriptorIsValid(fdp)) {
        if (NULL != fdp->_source && !CFRunLoopSourceIsValid(fdp->_source)) {
            CFRelease(fdp->_source);
            fdp->_source = NULL;
        }

        if (NULL == fdp->_source) {
            CFRunLoopSourceContext1 context;
            context.version = 1;
            context.info = (void *)fdp;
            context.retain = (const void *(*)(const void *))CFRetain;
            context.release = (void (*)(const void *))CFRelease;
            context.copyDescription = (CFStringRef (*)(const void *))__CFFileDescriptorCopyDescription;
            context.equal = (Boolean (*)(const void *, const void *))__CFFileDescriptorEqual;
            context.hash = (CFHashCode (*)(const void *))__CFFileDescriptorHash;
            context.getPort = __CFFileDescriptorGetEpollFileDescriptor;
            context.perform = __CFFileDescriptorPerform;
            fdp->_source = CFRunLoopSourceCreate(allocator, order, (CFRunLoopSourceContext *)&context);
        }
    }

    if (fdp->_source) {
        result = (CFRunLoopSourceRef)CFRetain(fdp->_source);
    }

    __CFUnlock(&fdp->_lock);

    return result;
}

// #endif
