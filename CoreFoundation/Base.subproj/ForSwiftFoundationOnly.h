// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#ifndef __COREFOUNDATION_FORSWIFTFOUNDATIONONLY__
#define __COREFOUNDATION_FORSWIFTFOUNDATIONONLY__ 1

#if !defined(CF_PRIVATE)
#define CF_PRIVATE __attribute__((__visibility__("hidden")))
#endif

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFNumber.h>
#include <CoreFoundation/CFLocaleInternal.h>
#include <CoreFoundation/CFCalendar.h>
#include <CoreFoundation/CFPriv.h>
#include <CoreFoundation/CFXMLInterface.h>
#include <CoreFoundation/CFRegularExpression.h>
#include <CoreFoundation/CFLogUtilities.h>
#include <CoreFoundation/CFURLSessionInterface.h>
#include <CoreFoundation/ForFoundationOnly.h>
#include <fts.h>
#include <pthread.h>

#if __has_include(<execinfo.h>)
#include <execinfo.h>
#endif

#if __has_include(<malloc/malloc.h>)
#include <malloc/malloc.h>
#endif

_CF_EXPORT_SCOPE_BEGIN

struct __CFSwiftObject {
    uintptr_t isa;
};

typedef struct __CFSwiftObject *CFSwiftRef;

#define CF_IS_SWIFT(type, obj) (_CFIsSwift(type, (CFSwiftRef)obj))

#define CF_SWIFT_FUNCDISPATCHV(type, ret, obj, fn, ...) do { \
    if (CF_IS_SWIFT(type, obj)) { \
        return (ret)__CFSwiftBridge.fn((CFSwiftRef)obj, ##__VA_ARGS__); \
    } \
} while (0)

CF_EXPORT bool _CFIsSwift(CFTypeID type, CFSwiftRef obj);
CF_EXPORT void _CFDeinit(CFTypeRef cf);

struct _NSObjectBridge {
    CFTypeID (*_cfTypeID)(CFTypeRef object);
    CFHashCode (*hash)(CFTypeRef object);
    bool (*isEqual)(CFTypeRef object, CFTypeRef other);
    _Nonnull CFTypeRef (*_Nonnull copyWithZone)(_Nonnull CFTypeRef object, _Nullable CFTypeRef zone);
};

struct _NSArrayBridge {
    CFIndex (*_Nonnull count)(CFTypeRef obj);
    _Nonnull CFTypeRef (*_Nonnull objectAtIndex)(CFTypeRef obj, CFIndex index);
    void (*_Nonnull getObjects)(CFTypeRef array, CFRange range, CFTypeRef _Nullable *_Nonnull values);
};

struct _NSMutableArrayBridge {
    void (*addObject)(CFTypeRef array, CFTypeRef value);
    void (*setObject)(CFTypeRef array, CFTypeRef value, CFIndex idx);
    void (*replaceObjectAtIndex)(CFTypeRef array, CFIndex idx, CFTypeRef value);
    void (*insertObject)(CFTypeRef array, CFIndex idx, CFTypeRef value);
    void (*exchangeObjectAtIndex)(CFTypeRef array, CFIndex idx1, CFIndex idx2);
    void (*removeObjectAtIndex)(CFTypeRef array, CFIndex idx);
    void (*removeAllObjects)(CFTypeRef array);
    void (*replaceObjectsInRange)(CFTypeRef array, CFRange range, CFTypeRef _Nonnull * _Nonnull newValues, CFIndex newCount);
};

struct _NSDictionaryBridge {
    CFIndex (*count)(CFTypeRef dictionary);
    CFIndex (*countForKey)(CFTypeRef dictionary, CFTypeRef key);
    bool (*containsKey)(CFTypeRef dictionary, CFTypeRef key);
    _Nullable CFTypeRef (*_Nonnull objectForKey)(CFTypeRef dictionary, CFTypeRef key);
    bool (*_getValueIfPresent)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef _Nullable *_Nullable value);
    CFIndex (*__getValue)(CFTypeRef dictionary, CFTypeRef value, CFTypeRef key);
    bool (*containsObject)(CFTypeRef dictionary, CFTypeRef value);
    CFIndex (*countForObject)(CFTypeRef dictionary, CFTypeRef value);
    void (*getObjects)(CFTypeRef dictionary, CFTypeRef _Nullable *_Nullable valuebuf, CFTypeRef _Nullable *_Nullable keybuf);
    void (*__apply)(CFTypeRef dictionary, void (*applier)(CFTypeRef key, CFTypeRef value, void *context), void *context);
    _Nonnull CFTypeRef (*_Nonnull copy)(CFTypeRef obj);
};

struct _NSMutableDictionaryBridge {
    void (*__addObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*replaceObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*__setObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*removeObjectForKey)(CFTypeRef dictionary, CFTypeRef key);
    void (*removeAllObjects)(CFTypeRef dictionary);
};

struct _NSSetBridge {
    CFIndex (*_Nonnull count)(CFTypeRef obj);
    bool (*containsObject)(CFTypeRef set, CFTypeRef value);
    _Nullable CFTypeRef (*_Nonnull __getValue)(CFTypeRef set, CFTypeRef value, CFTypeRef key);
    bool (*getValueIfPresent)(CFTypeRef set, CFTypeRef object, CFTypeRef _Nullable *_Nullable value);
    void (*getObjects)(CFTypeRef set, CFTypeRef _Nullable *_Nullable values);
    void (*__apply)(CFTypeRef set, void (*applier)(CFTypeRef value, void *context), void *context);
    _Nonnull CFTypeRef (*_Nonnull copy)(CFTypeRef obj);
    CFIndex (*_Nonnull countForKey)(CFTypeRef obj, CFTypeRef key);
    _Nullable CFTypeRef (*_Nonnull member)(CFTypeRef obj, CFTypeRef value);
};

struct _NSMutableSetBridge {
    void (*addObject)(CFTypeRef set, CFTypeRef value);
    void (*replaceObject)(CFTypeRef set, CFTypeRef value);
    void (*setObject)(CFTypeRef set, CFTypeRef value);
    void (*removeObject)(CFTypeRef set, CFTypeRef value);
    void (*removeAllObjects)(CFTypeRef set);
};

struct _NSStringBridge {
    _Nonnull CFTypeRef (*_Nonnull _createSubstringWithRange)(CFTypeRef str, CFRange range);
    _Nonnull CFTypeRef (*_Nonnull copy)(CFTypeRef str);
    _Nonnull CFTypeRef (*_Nonnull mutableCopy)(CFTypeRef str);
    CFIndex (*length)(CFTypeRef str);
    UniChar (*characterAtIndex)(CFTypeRef str, CFIndex idx);
    void (*getCharacters)(CFTypeRef str, CFRange range, UniChar *buffer);
    CFIndex (*__getBytes)(CFTypeRef str, CFStringEncoding encoding, CFRange range, uint8_t *_Nullable buffer, CFIndex maxBufLen, CFIndex *_Nullable usedBufLen);
    const char *_Nullable (*_Nonnull _fastCStringContents)(CFTypeRef str, bool nullTerminated);
    const UniChar *_Nullable (*_Nonnull _fastCharacterContents)(CFTypeRef str);
    bool (*_getCString)(CFTypeRef str, char *buffer, size_t len, UInt32 encoding);
    bool (*_encodingCantBeStoredInEightBitCFString)(CFTypeRef str);
};

struct _NSMutableStringBridge {
    void (*insertString)(CFTypeRef str, CFIndex idx, CFTypeRef inserted);
    void (*deleteCharactersInRange)(CFTypeRef str, CFRange range);
    void (*replaceCharactersInRange)(CFTypeRef str, CFRange range, CFTypeRef replacement);
    void (*setString)(CFTypeRef str, CFTypeRef replacement);
    void (*appendString)(CFTypeRef str, CFTypeRef appended);
    void (*appendCharacters)(CFTypeRef str, const UniChar *chars, CFIndex appendLength);
    void (*_cfAppendCString)(CFTypeRef str, const char *chars, CFIndex appendLength);
};

struct _NSXMLParserBridge {
    _CFXMLInterface _Nullable (*_Nonnull currentParser)(void);
    _CFXMLInterfaceParserInput _Nullable (*_Nonnull _xmlExternalEntityWithURL)(_CFXMLInterface interface, const char *url, const char * identifier, _CFXMLInterfaceParserContext context, _CFXMLInterfaceExternalEntityLoader originalLoaderFunction);
    
    _CFXMLInterfaceParserContext _Nonnull (*_Nonnull getContext)(_CFXMLInterface ctx);
    
    void (*internalSubset)(_CFXMLInterface ctx, const unsigned char *name, const unsigned char *ExternalID, const unsigned char *SystemID);
    int (*isStandalone)(_CFXMLInterface ctx);
    int (*hasInternalSubset)(_CFXMLInterface ctx);
    int (*hasExternalSubset)(_CFXMLInterface ctx);
    _CFXMLInterfaceEntity _Nullable (*_Nonnull getEntity)(_CFXMLInterface ctx, const unsigned char *name);
    void (*notationDecl)(_CFXMLInterface ctx,
                         const unsigned char *name,
                         const unsigned char *publicId,
                         const unsigned char *systemId);
    void (*attributeDecl)(_CFXMLInterface ctx,
                          const unsigned char *elem,
                          const unsigned char *fullname,
                          int type,
                          int def,
                          const unsigned char *defaultValue,
                          _CFXMLInterfaceEnumeration tree);
    void (*elementDecl)(_CFXMLInterface ctx,
                        const unsigned char *name,
                        int type,
                        _CFXMLInterfaceElementContent content);
    void (*unparsedEntityDecl)(_CFXMLInterface ctx,
                               const unsigned char *name,
                               const unsigned char *publicId,
                               const unsigned char *systemId,
                               const unsigned char *notationName);
    void (*startDocument)(_CFXMLInterface ctx);
    void (*endDocument)(_CFXMLInterface ctx);
    void (*startElementNs)(_CFXMLInterface ctx,
                           const unsigned char *localname,
                           const unsigned char *_Nullable prefix,
                           const unsigned char *_Nullable URI,
                           int nb_namespaces,
                           const unsigned char *_Nullable *_Nonnull namespaces,
                           int nb_attributes,
                           int nb_defaulted,
                           const unsigned char *_Nullable *_Nonnull attributes);
    void (*endElementNs)(_CFXMLInterface ctx,
                         const unsigned char *localname,
                         const unsigned char *_Nullable prefix,
                         const unsigned char *_Nullable URI);
    void (*characters)(_CFXMLInterface ctx,
                       const unsigned char *ch,
                       int len);
    void (*processingInstruction)(_CFXMLInterface ctx,
                                  const unsigned char *target,
                                  const unsigned char *data);
    void (*cdataBlock)(_CFXMLInterface ctx,
                       const unsigned char *value,
                       int len);
    void (*comment)(_CFXMLInterface ctx, const unsigned char *value);
    void (*externalSubset)(_CFXMLInterface ctx,
                           const unsigned char *name,
                           const unsigned char *ExternalID,
                           const unsigned char *SystemID);
};

struct _NSRunLoop {
    _Nonnull CFTypeRef (*_Nonnull _new)(CFRunLoopRef rl);
};

struct _NSCharacterSetBridge {
    _Nullable CFCharacterSetRef (*_Nonnull _expandedCFCharacterSet)(CFTypeRef cset);
    _Nonnull CFDataRef (*_Nonnull _retainedBitmapRepresentation)(CFTypeRef cset);
    
    bool (*_Nonnull characterIsMember)(CFTypeRef cset, UniChar ch);
    _Nonnull CFMutableCharacterSetRef (*_Nonnull mutableCopy)(CFTypeRef cset);
    bool (*_Nonnull longCharacterIsMember)(CFTypeRef cset, UTF32Char ch);
    bool (*_Nonnull hasMemberInPlane)(CFTypeRef cset, uint8_t thePlane);
    _Nonnull CFCharacterSetRef (*_Nonnull invertedSet)(CFTypeRef cset);
};

struct _NSMutableCharacterSetBridge {
    void (*_Nonnull addCharactersInRange)(CFTypeRef cset, CFRange range);
    void (*_Nonnull removeCharactersInRange)(CFTypeRef cset, CFRange range);
    void (*_Nonnull addCharactersInString)(CFTypeRef cset, CFStringRef string);
    void (*_Nonnull removeCharactersInString)(CFTypeRef cset, CFStringRef string);
    void (*_Nonnull formUnionWithCharacterSet)(CFTypeRef cset, CFTypeRef other);
    void (*_Nonnull formIntersectionWithCharacterSet)(CFTypeRef cset, CFTypeRef other);
    void (*_Nonnull invert)(CFTypeRef cset);
};

struct _NSNumberBridge {
    CFNumberType (*_Nonnull _cfNumberGetType)(CFTypeRef number);
    bool (*_Nonnull boolValue)(CFTypeRef number);
    bool (*_Nonnull _getValue)(CFTypeRef number, void *value, CFNumberType type);
};

struct _CFSwiftBridge {
    struct _NSObjectBridge NSObject;
    struct _NSArrayBridge NSArray;
    struct _NSMutableArrayBridge NSMutableArray;
    struct _NSDictionaryBridge NSDictionary;
    struct _NSMutableDictionaryBridge NSMutableDictionary;
    struct _NSSetBridge NSSet;
    struct _NSMutableSetBridge NSMutableSet;
    struct _NSStringBridge NSString;
    struct _NSMutableStringBridge NSMutableString;
    struct _NSXMLParserBridge NSXMLParser;
    struct _NSRunLoop NSRunLoop;
    struct _NSCharacterSetBridge NSCharacterSet;
    struct _NSMutableCharacterSetBridge NSMutableCharacterSet;
    struct _NSNumberBridge NSNumber;
};

CF_EXPORT struct _CFSwiftBridge __CFSwiftBridge;

CF_PRIVATE void *_Nullable _CFSwiftRetain(void *_Nullable t);
CF_PRIVATE void _CFSwiftRelease(void *_Nullable t);

CF_EXPORT void _CFRuntimeBridgeTypeToClass(CFTypeID type, const void *isa);

CF_EXPORT CFNumberType _CFNumberGetType2(CFNumberRef number);

typedef	unsigned char __cf_uuid[16];
typedef	char __cf_uuid_string[37];
typedef __cf_uuid _cf_uuid_t;
typedef __cf_uuid_string _cf_uuid_string_t;

CF_EXPORT void _cf_uuid_clear(_cf_uuid_t _Nonnull uu);
CF_EXPORT int _cf_uuid_compare(const _cf_uuid_t _Nonnull uu1, const _cf_uuid_t _Nonnull uu2);
CF_EXPORT void _cf_uuid_copy(_cf_uuid_t _Nonnull dst, const _cf_uuid_t _Nonnull src);
CF_EXPORT void _cf_uuid_generate(_cf_uuid_t _Nonnull out);
CF_EXPORT void _cf_uuid_generate_random(_cf_uuid_t _Nonnull out);
CF_EXPORT void _cf_uuid_generate_time(_cf_uuid_t _Nonnull out);
CF_EXPORT int _cf_uuid_is_null(const _cf_uuid_t _Nonnull uu);
CF_EXPORT int _cf_uuid_parse(const _cf_uuid_string_t _Nonnull in, _cf_uuid_t _Nonnull uu);
CF_EXPORT void _cf_uuid_unparse(const _cf_uuid_t _Nonnull uu, _cf_uuid_string_t _Nonnull out);
CF_EXPORT void _cf_uuid_unparse_lower(const _cf_uuid_t _Nonnull uu, _cf_uuid_string_t _Nonnull out);
CF_EXPORT void _cf_uuid_unparse_upper(const _cf_uuid_t _Nonnull uu, _cf_uuid_string_t _Nonnull out);


extern CFWriteStreamRef _CFWriteStreamCreateFromFileDescriptor(CFAllocatorRef alloc, int fd);
#if !__COREFOUNDATION_FORFOUNDATIONONLY__
typedef const struct __CFKeyedArchiverUID * CFKeyedArchiverUIDRef;
extern CFTypeID _CFKeyedArchiverUIDGetTypeID(void);
extern CFKeyedArchiverUIDRef _CFKeyedArchiverUIDCreate(CFAllocatorRef allocator, uint32_t value);
extern uint32_t _CFKeyedArchiverUIDGetValue(CFKeyedArchiverUIDRef uid);
#endif

extern CFIndex __CFBinaryPlistWriteToStream(CFPropertyListRef plist, CFTypeRef stream);
extern CFDataRef _CFPropertyListCreateXMLDataWithExtras(CFAllocatorRef allocator, CFPropertyListRef propertyList);
extern CFWriteStreamRef _CFWriteStreamCreateFromFileDescriptor(CFAllocatorRef alloc, int fd);

extern _Nullable CFDateRef CFCalendarCopyGregorianStartDate(CFCalendarRef calendar);
extern void CFCalendarSetGregorianStartDate(CFCalendarRef calendar, CFDateRef date);

CF_EXPORT char *_Nullable *_Nonnull _CFEnviron(void);

CF_EXPORT void CFLog1(CFLogLevel lev, CFStringRef message);

CF_EXPORT Boolean _CFIsMainThread(void);
CF_EXPORT pthread_t _CFMainPThread;

CF_EXPORT CFHashCode __CFHashDouble(double d);

typedef pthread_key_t _CFThreadSpecificKey;
CF_EXPORT CFTypeRef _Nullable _CFThreadSpecificGet(_CFThreadSpecificKey key);
CF_EXPORT void _CFThreadSpecificSet(_CFThreadSpecificKey key, CFTypeRef _Nullable value);
CF_EXPORT _CFThreadSpecificKey _CFThreadSpecificKeyCreate(void);

typedef pthread_attr_t _CFThreadAttributes;
typedef pthread_t _CFThreadRef;

CF_EXPORT _CFThreadRef _CFThreadCreate(const _CFThreadAttributes attrs, void *_Nullable (* _Nonnull startfn)(void *_Nullable), void *restrict _Nullable context);

CF_SWIFT_EXPORT int _CFThreadSetName(pthread_t thread, const char *_Nonnull name);
CF_SWIFT_EXPORT int _CFThreadGetName(char *_Nonnull buf, int length);

CF_EXPORT Boolean _CFCharacterSetIsLongCharacterMember(CFCharacterSetRef theSet, UTF32Char theChar);
CF_EXPORT CFCharacterSetRef _CFCharacterSetCreateCopy(CFAllocatorRef alloc, CFCharacterSetRef theSet);
CF_EXPORT CFMutableCharacterSetRef _CFCharacterSetCreateMutableCopy(CFAllocatorRef alloc, CFCharacterSetRef theSet);

CF_EXPORT CFReadStreamRef CFReadStreamCreateWithData(CFAllocatorRef alloc, CFDataRef data);

CF_EXPORT _Nullable CFErrorRef _CFReadStreamCopyError(CFReadStreamRef stream);

CF_EXPORT _Nullable CFErrorRef _CFWriteStreamCopyError(CFWriteStreamRef stream);

// https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
// Version 0.8

// note: All paths set in these environment variables must be absolute.

/// a single base directory relative to which user-specific data files should be written. This directory is defined by the environment variable $XDG_DATA_HOME.
CF_EXPORT CFStringRef _CFXDGCreateDataHomePath(void);

/// a single base directory relative to which user-specific configuration files should be written. This directory is defined by the environment variable $XDG_CONFIG_HOME.
CF_EXPORT CFStringRef _CFXDGCreateConfigHomePath(void);

/// a set of preference ordered base directories relative to which data files should be searched. This set of directories is defined by the environment variable $XDG_DATA_DIRS.
CF_EXPORT CFArrayRef _CFXDGCreateDataDirectoriesPaths(void);

/// a set of preference ordered base directories relative to which configuration files should be searched. This set of directories is defined by the environment variable $XDG_CONFIG_DIRS.
CF_EXPORT CFArrayRef _CFXDGCreateConfigDirectoriesPaths(void);

/// a single base directory relative to which user-specific non-essential (cached) data should be written. This directory is defined by the environment variable $XDG_CACHE_HOME.
CF_EXPORT CFStringRef _CFXDGCreateCacheDirectoryPath(void);

/// a single base directory relative to which user-specific runtime files and other file objects should be placed. This directory is defined by the environment variable $XDG_RUNTIME_DIR.
CF_EXPORT CFStringRef _CFXDGCreateRuntimeDirectoryPath(void);


typedef struct {
    void *_Nonnull memory;
    size_t capacity;
    _Bool onStack;
} _ConditionalAllocationBuffer;

static inline _Bool _resizeConditionalAllocationBuffer(_ConditionalAllocationBuffer *_Nonnull buffer, size_t amt) {
#if TARGET_OS_MAC
    size_t amount = malloc_good_size(amt);
#else
    size_t amount = amt;
#endif
    if (amount <= buffer->capacity) { return true; }
    void *newMemory;
    if (buffer->onStack) {
        newMemory = malloc(amount);
        if (newMemory == NULL) { return false; }
        memcpy(newMemory, buffer->memory, buffer->capacity);
        buffer->onStack = false;
    } else {
        newMemory = realloc(buffer->memory, amount);
        if (newMemory == NULL) { return false; }
    }
    if (newMemory == NULL) { return false; }
    buffer->memory = newMemory;
    buffer->capacity = amount;
    return true;
}

static inline _Bool _withStackOrHeapBuffer(size_t amount, void (__attribute__((noescape)) ^ _Nonnull applier)(_ConditionalAllocationBuffer *_Nonnull)) {
    _ConditionalAllocationBuffer buffer;
#if TARGET_OS_MAC
    buffer.capacity = malloc_good_size(amount);
#else
    buffer.capacity = amount;
#endif
    buffer.onStack = (_CFIsMainThread() != 0 ? buffer.capacity < 2048 : buffer.capacity < 512);
    buffer.memory = buffer.onStack ? alloca(buffer.capacity) : malloc(buffer.capacity);
    if (buffer.memory == NULL) { return false; }
    applier(&buffer);
    if (!buffer.onStack) {
        free(buffer.memory);
    }
    return true;
}


_CF_EXPORT_SCOPE_END

#endif /* __COREFOUNDATION_FORSWIFTFOUNDATIONONLY__ */
