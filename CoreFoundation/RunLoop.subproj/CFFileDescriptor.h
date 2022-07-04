/*	CFFileDescriptor.h
	Copyright (c) 1998-2021, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2021-2021, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
	Responsibility: Serhii Mumriak
*/

#if !defined(__COREFOUNDATION_CFFILEDESCRIPTOR__)
#define __COREFOUNDATION_CFFILEDESCRIPTOR__ 1

#include <CoreFoundation/CFRunLoop.h>
#if TARGET_OS_LINUX

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN

typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFFileDescriptor * CFFileDescriptorRef;

typedef int CFFileDescriptorNativeDescriptor;

typedef CF_OPTIONS(CFOptionFlags, CFFileDescriptorCallBackIdentifier) {
    CFFileDescriptorCallBackIdentifierRead = 1UL << 0,
    CFFileDescriptorCallBackIdentifierWrite = 1UL << 1,
};

static CFFileDescriptorCallBackIdentifier kCFFileDescriptorReadCallBack = CFFileDescriptorCallBackIdentifierRead;
static CFFileDescriptorCallBackIdentifier kCFFileDescriptorWriteCallBack = CFFileDescriptorCallBackIdentifierWrite;

typedef struct {
    CFIndex version;
    void *info;
    const void *(*retain)(const void *info);
    void (*release)(const void *info);
    CFStringRef	(*copyDescription)(const void *info);
} CFFileDescriptorContext;

typedef void (*CFFileDescriptorCallBack)(CFFileDescriptorRef fileDescriptorPort, void *info);
typedef void (*CFFileDescriptorInvalidationCallBack)(CFFileDescriptorRef fileDescriptorPort, void *info);

CF_EXPORT CFTypeID CFFileDescriptorGetTypeID(void);

CF_EXPORT CFFileDescriptorRef CFFileDescriptorCreate(CFAllocatorRef allocator, CFFileDescriptorNativeDescriptor fileDescriptor, Boolean closeOnInvalidate, CFFileDescriptorCallBack callout, const CFFileDescriptorContext *context);

CF_EXPORT CFFileDescriptorNativeDescriptor CFFileDescriptorGetNativeDescriptor(CFFileDescriptorRef fileDescriptorPort);
CF_EXPORT void CFFileDescriptorGetContext(CFFileDescriptorRef fileDescriptorPort, CFFileDescriptorContext *context);

CF_EXPORT CFFileDescriptorInvalidationCallBack CFFileDescriptorGetInvalidationCallBack(CFFileDescriptorRef fileDescriptorPort);
CF_EXPORT void CFFileDescriptorSetInvalidationCallBack(CFFileDescriptorRef fileDescriptorPort, CFFileDescriptorInvalidationCallBack invalidationCallout);

CF_EXPORT void CFFileDescriptorEnableCallBacks(CFFileDescriptorRef fileDescriptor, CFOptionFlags callBackTypes);
CF_EXPORT void CFFileDescriptorDisableCallBacks(CFFileDescriptorRef fileDescriptor, CFOptionFlags callBackTypes);

CF_EXPORT void CFFileDescriptorInvalidate(CFFileDescriptorRef fileDescriptorPort);
CF_EXPORT Boolean CFFileDescriptorIsValid(CFFileDescriptorRef fileDescriptorPort);

CF_EXPORT CFRunLoopSourceRef CFFileDescriptorCreateRunLoopSource(CFAllocatorRef allocator, CFFileDescriptorRef fileDescriptorPort, CFIndex order);

CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif

#endif /* ! __COREFOUNDATION_CFFILEDESCRIPTOR__ */
