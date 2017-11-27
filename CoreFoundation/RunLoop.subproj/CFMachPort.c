/*	CFMachPort.c
	Copyright (c) 1998-2017, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2017, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
	Responsibility: Christopher Kane
*/

#include <CoreFoundation/CFMachPort.h>
#include <CoreFoundation/CFRunLoop.h>
#include <CoreFoundation/CFArray.h>
#include <dispatch/dispatch.h>
#if __has_include(<dispatch/private.h>)
#include <dispatch/private.h>
#endif
#include <mach/mach.h>
#include <dlfcn.h>
#include <stdio.h>
#include "CFInternal.h"
#include <os/lock.h>


// This queue is used for the cancel/event handler for dead name notification.
static dispatch_queue_t _CFMachPortQueue() {
    static volatile dispatch_queue_t __CFMachPortQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t dqattr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0);
        __CFMachPortQueue = dispatch_queue_create("com.apple.CFMachPort", dispatch_queue_attr_make_with_overcommit(dqattr, true));
    });
    return __CFMachPortQueue;
}

// NOTE: all _cfmp_ prefixed state/functions exist to orchestrate the exact time/circumstances we want to call _cfmp_mod_refs.
CF_INLINE void _cfmp_mod_refs(const mach_port_t port, const Boolean doSend, const Boolean doReceive) {
    // MUST deallocate the send right FIRST if necessary,
    // then the receive right if necessary.  Don't ask me why;
    // if it's done in the other order the port will leak.
    if (doSend) {
        mach_port_mod_refs(mach_task_self(), port, MACH_PORT_RIGHT_SEND, -1);
    }
    if (doReceive) {
        mach_port_mod_refs(mach_task_self(), port, MACH_PORT_RIGHT_RECEIVE, -1);
    }
}

// Records information relevant for cleaning up after a given mach port. It has states:
//   port & invalidated         -- dispatch_source invalidated, but _CFMachPortDeallocate has yet to be called
//   port & doSend & doReceive  -- _CFMachPortDeallocate has been called, but dispatch_source not yet invalidate
typedef struct {
    mach_port_t port;
    uint8_t doSend:1;
    uint8_t doReceive:1;
    uint8_t invalidated:1; // flag to indicate that the source has already been invalidated and the port can be cleaned up inline during deallocation
    uint8_t unused:5;
} _cfmp_deallocation_record;
// Various CFSet callbacks for _cfmp_deallocation_record
Boolean _cfmp_equal(const void *value1, const void *value2) {
    Boolean equal = false;
    if (value1 && value2) {
        if (value1 == value2) {
            equal = true;
        } else {
            const _cfmp_deallocation_record R1 = *(_cfmp_deallocation_record *)value1;
            const _cfmp_deallocation_record R2 = *(_cfmp_deallocation_record *)value2;
            equal = R1.port == R2.port;
        }
    }
    return equal;
}
CFHashCode _cfmp_hash(const void *value) {
    CFHashCode hash = 0;
    if (value) {
        const _cfmp_deallocation_record R = *(_cfmp_deallocation_record *)value;
        hash = _CFHashInt(R.port);
    }
    return hash;
}
void _cfmp_deallocation_record_release(CFAllocatorRef allocator, const void *value) {
    free((_cfmp_deallocation_record *)value);
}
CFStringRef _cfmp_copy_description(const void *value) {
    CFStringRef s = CFSTR("{null}");
    if (value) {
        const _cfmp_deallocation_record R = *(_cfmp_deallocation_record *)value;
        s = CFStringCreateWithFormat(NULL, NULL, CFSTR("{p:%d,s:%d,r:%d,i:%d}"), R.port, R.doSend, R.doReceive, R.invalidated);
    }
    return s;
}
CF_BREAKPOINT_FUNCTION(void _CFMachPortDeallocationFailure(void));
void _cfmp_log_failure(const char *const msg, _cfmp_deallocation_record *pr) {
    if (pr) {
        const _cfmp_deallocation_record R = *pr;
        os_log(OS_LOG_DEFAULT, "*** %{public}s break on '_CFMachPortDeallocationFailure' to debug: {p:%{private}d,s:%d,r:%d,i:%d}", msg, R.port, R.doSend, R.doReceive, R.invalidated);
    }
    else {
        os_log(OS_LOG_DEFAULT, "*** %{public}s break on  '_CFMachPortDeallocationFailure' to debug: {null}", msg);
    }
    _CFMachPortDeallocationFailure();
}

// all pending deallocates are recording in this global set, if there are every
static os_unfair_lock _cfmp_records_lock = OS_UNFAIR_LOCK_INIT;
CF_INLINE CFMutableSetRef _cfmp_records()  { // mutations of result GuardedBy(_cfmp_records_lock)
    static CFSetCallBacks oCallbacks;
    static CFMutableSetRef oRecords;
    static dispatch_once_t oGuard;
    dispatch_once(&oGuard, ^{
        oCallbacks.hash = _cfmp_hash;
        oCallbacks.equal = _cfmp_equal;
        oCallbacks.release = _cfmp_deallocation_record_release;
        oCallbacks.copyDescription = _cfmp_copy_description;
        oRecords = CFSetCreateMutable(NULL, 16, &oCallbacks);
    });
    return oRecords;
};
CF_INLINE _cfmp_deallocation_record *_cfmp_find_record_for_port(CFSetRef records, const mach_port_t port) {
    _cfmp_deallocation_record lookup = {.port = port};
    _cfmp_deallocation_record *pr = (_cfmp_deallocation_record *)CFSetGetValue(records, &lookup);
    return pr;
}
CF_INLINE void _cfmp_record_deallocation(const mach_port_t port, const Boolean doSend, const Boolean doReceive) {
    if (port == MACH_PORT_NULL) { return; }
    if (doSend == false && doReceive == false) { return; }

    // now that we know we're not a no-op, look for an existing deallocation record
    CFMutableSetRef records = _cfmp_records();
    Boolean cleanupNow = false;
    _cfmp_deallocation_record R;

    os_unfair_lock_lock(&_cfmp_records_lock);
    _cfmp_deallocation_record *pr = _cfmp_find_record_for_port(records, port);
    if (pr) {
        // if we have a pr it means we're expecting invalidation.  which has either happened or not.  if not, record doSend/Receive for later, otherwise get ready to handle it.
        R = *(_cfmp_deallocation_record *)pr;
        if (R.invalidated) {
            cleanupNow = true;
            R.port = port;
            R.doSend = doSend;
            R.doReceive = doReceive;
            CFSetRemoveValue(records, pr);
        } else {
            pr->doSend = doSend;
            pr->doReceive = doReceive;
        }
    } else  {
        cleanupNow = true;
        R.port = port;
        R.doSend = doSend;
        R.doReceive = doReceive;
    }
    os_unfair_lock_unlock(&_cfmp_records_lock);

    if (cleanupNow) {
        _cfmp_mod_refs(R.port, R.doSend, R.doReceive);
    }
}
CF_INLINE void _cfmp_record_intent_to_invalidate(const mach_port_t port) {
    CFMutableSetRef records = _cfmp_records();
    _cfmp_deallocation_record *pr = calloc(1, sizeof(_cfmp_deallocation_record));
    if (pr) {
        pr->port = port;
        os_unfair_lock_lock(&_cfmp_records_lock);
        CFSetAddValue(records, pr);
        os_unfair_lock_unlock(&_cfmp_records_lock);
    }
}
CF_INLINE void _cfmp_source_invalidated(mach_port_t port) {
    Boolean cleanupNow = false;
    _cfmp_deallocation_record R;
    
    CFMutableSetRef records = _cfmp_records();
    os_unfair_lock_lock(&_cfmp_records_lock);
    _cfmp_deallocation_record *pr = _cfmp_find_record_for_port(records, port);
    if (pr) {
        R = *(_cfmp_deallocation_record *)pr;
        if (!R.invalidated) {
            cleanupNow = true;
            CFSetRemoveValue(records, pr);            
        } else {
            _cfmp_log_failure("already invalidated", pr);
        }
    } else {
        _cfmp_log_failure("not expecting invalidation", pr);
    }
    os_unfair_lock_unlock(&_cfmp_records_lock);
    
    if (cleanupNow) {
        _cfmp_mod_refs(R.port, R.doSend, R.doReceive);
    }
}

enum {
    kCFMachPortStateReady = 0,
    kCFMachPortStateInvalidating = 1,
    kCFMachPortStateInvalid = 2,
    kCFMachPortStateDeallocating = 3
};

struct __CFMachPort {
    CFRuntimeBase _base;
    int32_t _state;
    mach_port_t _port;                          /* immutable */
    dispatch_source_t _dsrc;                    /* protected by _lock */
    CFMachPortInvalidationCallBack _icallout;   /* protected by _lock */
    CFRunLoopSourceRef _source;                 /* immutable, once created */
    CFMachPortCallBack _callout;                /* immutable */
    CFMachPortContext _context;                 /* immutable */
    CFLock_t _lock;
    const void *(*retain)(const void *info); // use these to store the real callbacks
    void        (*release)(const void *info);
};

/* Bit 1 in the base reserved bits is used for has-receive-ref state */
/* Bit 2 in the base reserved bits is used for has-send-ref state */

CF_INLINE Boolean __CFMachPortHasReceive(CFMachPortRef mp) {
    return __CFRuntimeGetFlag(mp, 1);
}

CF_INLINE void __CFMachPortSetHasReceive(CFMachPortRef mp) {
    __CFRuntimeSetFlag(mp, 1, true);
}

CF_INLINE Boolean __CFMachPortHasSend(CFMachPortRef mp) {
    return __CFRuntimeGetFlag(mp, 2);
}

CF_INLINE void __CFMachPortSetHasSend(CFMachPortRef mp) {
    __CFRuntimeSetFlag(mp, 2, true);
}

CF_INLINE Boolean __CFMachPortIsValid(CFMachPortRef mp) {
    return kCFMachPortStateReady == mp->_state;
}


void _CFMachPortInstallNotifyPort(CFRunLoopRef rl, CFStringRef mode) {
}

static Boolean __CFMachPortEqual(CFTypeRef cf1, CFTypeRef cf2) {
    CFMachPortRef mp1 = (CFMachPortRef)cf1;
    CFMachPortRef mp2 = (CFMachPortRef)cf2;
    return (mp1->_port == mp2->_port);
}

static CFHashCode __CFMachPortHash(CFTypeRef cf) {
    CFMachPortRef mp = (CFMachPortRef)cf;
    return (CFHashCode)mp->_port;
}

static CFStringRef __CFMachPortCopyDescription(CFTypeRef cf) {
    CFMachPortRef mp = (CFMachPortRef)cf;
    CFStringRef contextDesc = NULL;
    if (NULL != mp->_context.info && NULL != mp->_context.copyDescription) {
        contextDesc = mp->_context.copyDescription(mp->_context.info);
    }
    if (NULL == contextDesc) {
        contextDesc = CFStringCreateWithFormat(kCFAllocatorSystemDefault, NULL, CFSTR("<CFMachPort context %p>"), mp->_context.info);
    }
    Dl_info info;
    void *addr = mp->_callout;
    const char *name = (dladdr(addr, &info) && info.dli_saddr == addr && info.dli_sname) ? info.dli_sname : "???";
    CFStringRef result = CFStringCreateWithFormat(kCFAllocatorSystemDefault, NULL, CFSTR("<CFMachPort %p [%p]>{valid = %s, port = %x, source = %p, callout = %s (%p), context = %@}"), cf, CFGetAllocator(mp), (__CFMachPortIsValid(mp) ? "Yes" : "No"), mp->_port, mp->_source, name, addr, contextDesc);
    if (NULL != contextDesc) {
        CFRelease(contextDesc);
    }
    return result;
}

// Only call with mp->_lock locked
CF_INLINE void __CFMachPortInvalidateLocked(CFRunLoopSourceRef source, CFMachPortRef mp) {
    CFMachPortInvalidationCallBack cb = mp->_icallout;
    if (cb) {
        __CFUnlock(&mp->_lock);
        cb(mp, mp->_context.info);
        __CFLock(&mp->_lock);
    }
    if (NULL != source) {
        __CFUnlock(&mp->_lock);
        CFRunLoopSourceInvalidate(source);
        CFRelease(source);
        __CFLock(&mp->_lock);
    }
    void *info = mp->_context.info;
    void (*release)(const void *info) = mp->release;
    mp->_context.info = NULL;
    if (release) {
        __CFUnlock(&mp->_lock);
        release(info);
        __CFLock(&mp->_lock);
    }
    mp->_state = kCFMachPortStateInvalid;
    OSMemoryBarrier();
}

static void __CFMachPortDeallocate(CFTypeRef cf) {
    CHECK_FOR_FORK_RET();
    CFMachPortRef mp = (CFMachPortRef)cf;

    // CFMachPortRef is invalid before we get here
    __CFLock(&mp->_lock);
    CFRunLoopSourceRef source = NULL;
    Boolean wasReady = (mp->_state == kCFMachPortStateReady);
    if (wasReady) {
        mp->_state = kCFMachPortStateInvalidating;
        OSMemoryBarrier();
        if (mp->_dsrc) {
            dispatch_source_cancel(mp->_dsrc);
            mp->_dsrc = NULL;
        }
        source = mp->_source;
        mp->_source = NULL;
    }    
    if (wasReady) {
        __CFMachPortInvalidateLocked(source, mp);
    }
    mp->_state = kCFMachPortStateDeallocating;

    const mach_port_t port = mp->_port;
    const Boolean doSend = __CFMachPortHasSend(mp), doReceive = __CFMachPortHasReceive(mp);
    __CFUnlock(&mp->_lock);
    
    _cfmp_record_deallocation(port, doSend, doReceive);
    
}

// This lock protects __CFAllMachPorts. Take before any instance-specific lock.
static CFLock_t __CFAllMachPortsLock = CFLockInit;

static CFMutableArrayRef __CFAllMachPorts = NULL;

static Boolean __CFMachPortCheck(mach_port_t) __attribute__((noinline));
static Boolean __CFMachPortCheck(mach_port_t port) {
    mach_port_type_t type = 0;
    kern_return_t ret = mach_port_type(mach_task_self(), port, &type);
    return (KERN_SUCCESS != ret || (0 == (type & MACH_PORT_TYPE_PORT_RIGHTS))) ? false : true;
}

static void __CFMachPortChecker(Boolean fromTimer) {
    __CFLock(&__CFAllMachPortsLock); // take this lock first before any instance-specific lock
    for (CFIndex idx = 0, cnt = __CFAllMachPorts ? CFArrayGetCount(__CFAllMachPorts) : 0; idx < cnt; idx++) {
        CFMachPortRef mp = (CFMachPortRef)CFArrayGetValueAtIndex(__CFAllMachPorts, idx);
        if (!mp) continue;
        // second clause cleans no-longer-wanted CFMachPorts out of our strong table
        if (!__CFMachPortCheck(mp->_port) || (1 == CFGetRetainCount(mp))) {
            CFRunLoopSourceRef source = NULL;
            Boolean wasReady = (mp->_state == kCFMachPortStateReady);
            if (wasReady) {
                __CFLock(&mp->_lock); // take this lock second
                // double check the state under lock, just in case, we should be the last reference per retain count check above... but it doesn't hurt to be robust.
                wasReady = (mp->_state == kCFMachPortStateReady);
                if (!wasReady) {
                    __CFUnlock(&mp->_lock);
                }
                else {
                    mp->_state = kCFMachPortStateInvalidating;
                    OSMemoryBarrier();
                    if (mp->_dsrc) {
                        dispatch_source_cancel(mp->_dsrc);
                        mp->_dsrc = NULL;
                    }
                    source = mp->_source;
                    mp->_source = NULL;
                    CFRetain(mp);
                    __CFUnlock(&mp->_lock);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // We can grab the mach port-specific spin lock here since we're no longer on the same thread as the one taking the all mach ports spin lock.
                        // But be sure to release it during callouts
                        __CFLock(&mp->_lock);
                        __CFMachPortInvalidateLocked(source, mp);
                        __CFUnlock(&mp->_lock);
                        CFRelease(mp);
                    });
                }
            }
            CFArrayRemoveValueAtIndex(__CFAllMachPorts, idx);
            idx--;
            cnt--;
        }
    }
    __CFUnlock(&__CFAllMachPortsLock);
};


static CFTypeID __kCFMachPortTypeID = _kCFRuntimeNotATypeID;

static const CFRuntimeClass __CFMachPortClass = {
    0,
    "CFMachPort",
    NULL,      // init
    NULL,      // copy
    __CFMachPortDeallocate,
    __CFMachPortEqual,
    __CFMachPortHash,
    NULL,      // 
    __CFMachPortCopyDescription
};

CFTypeID CFMachPortGetTypeID(void) {
    static dispatch_once_t initOnce;
    dispatch_once(&initOnce, ^{ __kCFMachPortTypeID = _CFRuntimeRegisterClass(&__CFMachPortClass); });
    return __kCFMachPortTypeID;
}

/* Note: any receive or send rights that the port contains coming in will
 * not be cleaned up by CFMachPort; it will increment and decrement
 * references on the port if the kernel ever allows that in the future,
 * but will not cleanup any references you got when you got the port. */
CFMachPortRef _CFMachPortCreateWithPort2(CFAllocatorRef allocator, mach_port_t port, CFMachPortCallBack callout, CFMachPortContext *context, Boolean *shouldFreeInfo, Boolean deathWatch) {
    if (shouldFreeInfo) *shouldFreeInfo = true;
    CHECK_FOR_FORK_RET(NULL);

    mach_port_type_t type = 0;
    kern_return_t ret = mach_port_type(mach_task_self(), port, &type);
    if (KERN_SUCCESS != ret || (0 == (type & MACH_PORT_TYPE_PORT_RIGHTS))) {
        if (type & ~MACH_PORT_TYPE_DEAD_NAME) {
            CFLog(kCFLogLevelError, CFSTR("*** CFMachPortCreateWithPort(): bad Mach port parameter (0x%lx) or unsupported mysterious kind of Mach port (%d, %ld)"), (unsigned long)port, ret, (unsigned long)type);
        }
        return NULL;
    }

#if 0
    static dispatch_source_t timerSource = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_INTERVAL, 60 * 1000 /* milliseconds */, 0, _CFMachPortQueue());
        dispatch_source_set_event_handler(timerSource, ^{
            __CFMachPortChecker(true);
        });
        dispatch_resume(timerSource);
    });
#endif

    CFMachPortRef mp = NULL;
    __CFLock(&__CFAllMachPortsLock);
    for (CFIndex idx = 0, cnt = __CFAllMachPorts ? CFArrayGetCount(__CFAllMachPorts) : 0; idx < cnt; idx++) {
        CFMachPortRef p = (CFMachPortRef)CFArrayGetValueAtIndex(__CFAllMachPorts, idx);
        if (p && p->_port == port) {
            CFRetain(p);
            mp = p;
            break;
        }
    }
    __CFUnlock(&__CFAllMachPortsLock);
    
    if (!mp) {
        CFIndex size = sizeof(struct __CFMachPort) - sizeof(CFRuntimeBase);
        CFMachPortRef memory = (CFMachPortRef)_CFRuntimeCreateInstance(allocator, CFMachPortGetTypeID(), size, NULL);
        if (NULL == memory) {
            return NULL;
        }
        memory->_port = port;
        memory->_dsrc = NULL;
        memory->_icallout = NULL;
        memory->_source = NULL;
        memory->_context.info = NULL;
        memory->_context.retain = NULL;
        memory->_context.release = NULL;
        memory->_context.copyDescription = NULL;
        memory->retain = NULL;
        memory->release = NULL;
        memory->_callout = callout;
        memory->_lock = CFLockInit;
        if (NULL != context) {
            memmove(&memory->_context, context, sizeof(CFMachPortContext));
            memory->_context.info = context->retain ? (void *)context->retain(context->info) : context->info;
            memory->retain = context->retain;
            memory->release = context->release;
	    memory->_context.retain = (void *)0xAAAAAAAAAACCCAAA;
            memory->_context.release = (void *)0xAAAAAAAAAABBBAAA;
        }
        memory->_state = kCFMachPortStateReady;
        __CFLock(&__CFAllMachPortsLock);
        if (!__CFAllMachPorts) __CFAllMachPorts = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
        CFArrayAppendValue(__CFAllMachPorts, memory);
        __CFUnlock(&__CFAllMachPortsLock);
        mp = memory;
        if (shouldFreeInfo) *shouldFreeInfo = false;

        if (type & MACH_PORT_TYPE_SEND_RIGHTS) {
            _cfmp_record_intent_to_invalidate(port);
            dispatch_source_t theSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_SEND, port, DISPATCH_MACH_SEND_DEAD, _CFMachPortQueue());
	    if (theSource) {
                dispatch_source_set_cancel_handler(theSource, ^{
                    _cfmp_source_invalidated(port);
                    dispatch_release(theSource);
                });
                dispatch_source_set_event_handler(theSource, ^{ __CFMachPortChecker(false); });
                memory->_dsrc = theSource;
                dispatch_resume(theSource);
	    }
        }
    }
    
    if (mp && !CFMachPortIsValid(mp)) { // must do this outside lock to avoid deadlock
        CFRelease(mp);
        mp = NULL;
    }
    return mp;
}

CFMachPortRef CFMachPortCreateWithPort(CFAllocatorRef allocator, mach_port_t port, CFMachPortCallBack callout, CFMachPortContext *context, Boolean *shouldFreeInfo) {
    return _CFMachPortCreateWithPort2(allocator, port, callout, context, shouldFreeInfo, true);
}

CFMachPortRef CFMachPortCreate(CFAllocatorRef allocator, CFMachPortCallBack callout, CFMachPortContext *context, Boolean *shouldFreeInfo) {
    if (shouldFreeInfo) *shouldFreeInfo = true;
    CHECK_FOR_FORK_RET(NULL);
    mach_port_t port = MACH_PORT_NULL;
    kern_return_t ret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    if (KERN_SUCCESS == ret) {
        ret = mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
    }
    if (KERN_SUCCESS != ret) {
        if (MACH_PORT_NULL != port) mach_port_destroy(mach_task_self(), port);
        return NULL;
    }
    CFMachPortRef result = _CFMachPortCreateWithPort2(allocator, port, callout, context, shouldFreeInfo, true);
    if (NULL == result) {
        if (MACH_PORT_NULL != port) mach_port_destroy(mach_task_self(), port);
        return NULL;
    }
    __CFMachPortSetHasReceive(result);
    __CFMachPortSetHasSend(result);
    return result;
}

void CFMachPortInvalidate(CFMachPortRef mp) {
    CHECK_FOR_FORK_RET();
    CF_OBJC_FUNCDISPATCHV(CFMachPortGetTypeID(), void, (NSMachPort *)mp, invalidate);
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    CFRetain(mp);
    CFRunLoopSourceRef source = NULL;
    Boolean wasReady = false;
    __CFLock(&__CFAllMachPortsLock); // take this lock first
    __CFLock(&mp->_lock);
    wasReady = (mp->_state == kCFMachPortStateReady);
    if (wasReady) {
        mp->_state = kCFMachPortStateInvalidating;
        OSMemoryBarrier();
        for (CFIndex idx = 0, cnt = __CFAllMachPorts ? CFArrayGetCount(__CFAllMachPorts) : 0; idx < cnt; idx++) {
            CFMachPortRef p = (CFMachPortRef)CFArrayGetValueAtIndex(__CFAllMachPorts, idx);
            if (p == mp) {
                CFArrayRemoveValueAtIndex(__CFAllMachPorts, idx);
                break;
            }
        }
        if (mp->_dsrc) {
            dispatch_source_cancel(mp->_dsrc);
            mp->_dsrc = NULL;
        }
        source = mp->_source;
        mp->_source = NULL;
    }
    __CFUnlock(&mp->_lock);
    __CFUnlock(&__CFAllMachPortsLock); // release this lock last
    if (wasReady) {
        __CFLock(&mp->_lock);
        __CFMachPortInvalidateLocked(source, mp);
        __CFUnlock(&mp->_lock);
    }
    CFRelease(mp);
}

mach_port_t CFMachPortGetPort(CFMachPortRef mp) {
    CHECK_FOR_FORK_RET(0);
    CF_OBJC_FUNCDISPATCHV(CFMachPortGetTypeID(), mach_port_t, (NSMachPort *)mp, machPort);
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    return mp->_port;
}

void CFMachPortGetContext(CFMachPortRef mp, CFMachPortContext *context) {
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    CFAssert1(0 == context->version, __kCFLogAssertion, "%s(): context version not initialized to 0", __PRETTY_FUNCTION__);
    memmove(context, &mp->_context, sizeof(CFMachPortContext));
}

Boolean CFMachPortIsValid(CFMachPortRef mp) {
    CF_OBJC_FUNCDISPATCHV(CFMachPortGetTypeID(), Boolean, (NSMachPort *)mp, isValid);
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    if (!__CFMachPortIsValid(mp)) return false;
    mach_port_type_t type = 0;
    MACH_PORT_TYPE_PORT_RIGHTS;
    kern_return_t ret = mach_port_type(mach_task_self(), mp->_port, &type);
    if (KERN_SUCCESS != ret || (0 == (type & MACH_PORT_TYPE_PORT_RIGHTS))) {
	return false;
    }
    return true;
}

CFMachPortInvalidationCallBack CFMachPortGetInvalidationCallBack(CFMachPortRef mp) {
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    __CFLock(&mp->_lock);
    CFMachPortInvalidationCallBack cb = mp->_icallout;
    __CFUnlock(&mp->_lock);
    return cb;
}

/* After the CFMachPort has started going invalid, or done invalid, you can't change this, and
   we'll only do the callout directly on a transition from NULL to non-NULL. */
void CFMachPortSetInvalidationCallBack(CFMachPortRef mp, CFMachPortInvalidationCallBack callout) {
    CHECK_FOR_FORK_RET();
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    if (callout) {
	mach_port_type_t type = 0;
	kern_return_t ret = mach_port_type(mach_task_self(), mp->_port, &type);
	if (KERN_SUCCESS != ret || 0 == (type & MACH_PORT_TYPE_SEND_RIGHTS)) {
	    CFLog(kCFLogLevelError, CFSTR("*** WARNING: CFMachPortSetInvalidationCallBack() called on a CFMachPort with a Mach port (0x%x) which does not have any send rights.  This is not going to work.  Callback function: %p"), mp->_port, callout);
	}
    }
    __CFLock(&mp->_lock);
    if (__CFMachPortIsValid(mp) || !callout) {
        mp->_icallout = callout;
    } else if (!mp->_icallout && callout) {
        __CFUnlock(&mp->_lock);
        callout(mp, mp->_context.info);
        __CFLock(&mp->_lock);
    } else {
        CFLog(kCFLogLevelWarning, CFSTR("CFMachPortSetInvalidationCallBack(): attempt to set invalidation callback (%p) on invalid CFMachPort (%p) thwarted"), callout, mp);
    }
    __CFUnlock(&mp->_lock);
}

/* Returns the number of messages queued for a receive port. */
CFIndex CFMachPortGetQueuedMessageCount(CFMachPortRef mp) {  
    CHECK_FOR_FORK_RET(0);
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    mach_port_status_t status;
    mach_msg_type_number_t num = MACH_PORT_RECEIVE_STATUS_COUNT;
    kern_return_t ret = mach_port_get_attributes(mach_task_self(), mp->_port, MACH_PORT_RECEIVE_STATUS, (mach_port_info_t)&status, &num);
    return (KERN_SUCCESS != ret) ? 0 : status.mps_msgcount;
}

static mach_port_t __CFMachPortGetPort(void *info) {
    CFMachPortRef mp = (CFMachPortRef)info;
    return mp->_port;
}

CF_PRIVATE void *__CFMachPortPerform(void *msg, CFIndex size, CFAllocatorRef allocator, void *info) {
    CHECK_FOR_FORK_RET(NULL);
    CFMachPortRef mp = (CFMachPortRef)info;
    __CFLock(&mp->_lock);
    Boolean isValid = __CFMachPortIsValid(mp);
    void *context_info = NULL;
    void (*context_release)(const void *) = NULL;
    if (isValid) {
        if (mp->retain) {
            context_info = (void *)mp->retain(mp->_context.info);
            context_release = mp->release;
        } else {
            context_info = mp->_context.info;
        }
    }
    __CFUnlock(&mp->_lock);
    if (isValid) {
        mp->_callout(mp, msg, size, context_info);

        if (context_release) {
            context_release(context_info);
        }
        CHECK_FOR_FORK_RET(NULL);
    }
    return NULL;
}


    
    
CFRunLoopSourceRef CFMachPortCreateRunLoopSource(CFAllocatorRef allocator, CFMachPortRef mp, CFIndex order) {
    CHECK_FOR_FORK_RET(NULL);
    __CFGenericValidateType(mp, CFMachPortGetTypeID());
    if (!CFMachPortIsValid(mp)) return NULL;
    CFRunLoopSourceRef result = NULL;
    __CFLock(&mp->_lock);
    if (__CFMachPortIsValid(mp)) {
        if (NULL != mp->_source && !CFRunLoopSourceIsValid(mp->_source)) {
            CFRelease(mp->_source);
            mp->_source = NULL;
        }
        if (NULL == mp->_source) {
            CFRunLoopSourceContext1 context;
            context.version = 1;
            context.info = (void *)mp;
            context.retain = (const void *(*)(const void *))CFRetain;
            context.release = (void (*)(const void *))CFRelease;
            context.copyDescription = (CFStringRef (*)(const void *))__CFMachPortCopyDescription;
            context.equal = (Boolean (*)(const void *, const void *))__CFMachPortEqual;
            context.hash = (CFHashCode (*)(const void *))__CFMachPortHash;
            context.getPort = __CFMachPortGetPort;
            context.perform = __CFMachPortPerform;
            mp->_source = CFRunLoopSourceCreate(allocator, order, (CFRunLoopSourceContext *)&context);
        }
        result = mp->_source ? (CFRunLoopSourceRef)CFRetain(mp->_source) : NULL;
    }
    __CFUnlock(&mp->_lock);
    return result;
}

