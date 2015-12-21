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

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFNumber.h>
#include <CoreFoundation/CFLocaleInternal.h>
#include <CoreFoundation/CFCalendar.h>
#include <CoreFoundation/CFPriv.h>
#include <CoreFoundation/CFXMLInterface.h>
#include <fts.h>

CF_ASSUME_NONNULL_BEGIN
CF_IMPLICIT_BRIDGING_ENABLED

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

extern bool _CFIsSwift(CFTypeID type, CFSwiftRef obj);
extern void _CFDeinit(CFTypeRef cf);

struct _NSObjectBridge {
    CFTypeID (*_cfTypeID)(CFTypeRef object);
    CFHashCode (*hash)(CFTypeRef object);
    bool (*isEqual)(CFTypeRef object, CFTypeRef other);
};

struct _NSArrayBridge {
    CFIndex (*_Nonnull count)(CFTypeRef obj);
    _Nonnull CFTypeRef (*_Nonnull objectAtIndex)(CFTypeRef obj, CFIndex index);
    void (*_Nonnull getObjects)(CFTypeRef array, CFRange range, CFTypeRef _Nonnull * _Nonnull values);
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
    bool (*_getValueIfPresent)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef _Nonnull * _Nullable value);
    CFIndex (*__getValue)(CFTypeRef dictionary, CFTypeRef value, CFTypeRef key);
    bool (*containsObject)(CFTypeRef dictionary, CFTypeRef value);
    CFIndex (*countForObject)(CFTypeRef dictionary, CFTypeRef value);
    void (*getObjects)(CFTypeRef dictionary, CFTypeRef _Nonnull * _Nonnull valuebuf, CFTypeRef _Nonnull * _Nonnull keybuf);
    void (*__apply)(CFTypeRef dictionary, void (*applier)(CFTypeRef key, CFTypeRef value, void *context), void *context);
};

struct _NSMutableDictionaryBridge {
    void (*__addObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*replaceObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*__setObject)(CFTypeRef dictionary, CFTypeRef key, CFTypeRef value);
    void (*removeObjectForKey)(CFTypeRef dictionary, CFTypeRef key);
    void (*removeAllObjects)(CFTypeRef dictionary);
};

struct _NSSetBridge {
    
};

struct _NSMutableSetBridge {
    
};

struct _NSStringBridge {
    _Nonnull CFTypeRef (*_Nonnull _createSubstringWithRange)(CFTypeRef str, CFRange range);
    _Nonnull CFTypeRef (*_Nonnull copy)(CFTypeRef str);
    _Nonnull CFTypeRef (*_Nonnull mutableCopy)(CFTypeRef str);
    CFIndex (*length)(CFTypeRef str);
    UniChar (*characterAtIndex)(CFTypeRef str, CFIndex idx);
    void (*getCharacters)(CFTypeRef str, CFRange range, UniChar *buffer);
    CFIndex (*__getBytes)(CFTypeRef str, CFStringEncoding encoding, CFRange range, uint8_t *buffer, CFIndex maxBufLen, CFIndex *usedBufLen);
    const char *_Nullable (*_Nonnull _fastCStringContents)(CFTypeRef str);
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
    _CFXMLInterface _Nullable (*_Nonnull currentParser)();
    _CFXMLInterfaceParserInput _Nonnull (*_Nonnull _xmlExternalEntityWithURL)(_CFXMLInterface interface, const char *url, const char * identifier, _CFXMLInterfaceParserContext context, _CFXMLInterfaceExternalEntityLoader originalLoaderFunction);
    
    _CFXMLInterfaceParserContext _Nonnull (*_Nonnull getContext)(_CFXMLInterface ctx);
    
    void (*internalSubset)(_CFXMLInterface ctx, const unsigned char *name, const unsigned char *ExternalID, const unsigned char *SystemID);
    int (*isStandalone)(_CFXMLInterface ctx);
    int (*hasInternalSubset)(_CFXMLInterface ctx);
    int (*hasExternalSubset)(_CFXMLInterface ctx);
    _CFXMLInterfaceEntity _Nonnull (*_Nonnull getEntity)(_CFXMLInterface ctx, const unsigned char *name);
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
                           const unsigned char *prefix,
                           const unsigned char *URI,
                           int nb_namespaces,
                           const unsigned char *_Nonnull *_Nonnull namespaces,
                           int nb_attributes,
                           int nb_defaulted,
                           const unsigned char *_Nonnull *_Nonnull attributes);
    void (*endElementNs)(_CFXMLInterface ctx,
                         const unsigned char *localname,
                         const unsigned char *prefix,
                         const unsigned char *URI);
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
};

__attribute__((__visibility__("hidden"))) extern struct _CFSwiftBridge __CFSwiftBridge;


CF_EXPORT CFStringEncoding __CFDefaultEightBitStringEncoding;

extern void _CFRuntimeBridgeTypeToClass(CFTypeID type, const void *isa);

extern void _CFNumberInitBool(CFNumberRef result, Boolean value);
extern void _CFNumberInitInt8(CFNumberRef result, int8_t value);
extern void _CFNumberInitUInt8(CFNumberRef result, uint8_t value);
extern void _CFNumberInitInt16(CFNumberRef result, int16_t value);
extern void _CFNumberInitUInt16(CFNumberRef result, uint16_t value);
extern void _CFNumberInitInt32(CFNumberRef result, int32_t value);
extern void _CFNumberInitUInt32(CFNumberRef result, uint32_t value);
extern void _CFNumberInitInt(CFNumberRef result, long value);
extern void _CFNumberInitUInt(CFNumberRef result, unsigned long value);
extern void _CFNumberInitInt64(CFNumberRef result, int64_t value);
extern void _CFNumberInitUInt64(CFNumberRef result, uint64_t value);
extern void _CFNumberInitFloat(CFNumberRef result, float value);
extern void _CFNumberInitDouble(CFNumberRef result, double value);

extern void _CFURLInitWithFileSystemPathRelativeToBase(CFURLRef url, CFStringRef fileSystemPath, CFURLPathStyle pathStyle, Boolean isDirectory, _Nullable CFURLRef baseURL);
extern Boolean _CFURLInitWithURLString(CFURLRef url, CFStringRef string, Boolean checkForLegalCharacters, _Nullable CFURLRef baseURL);
extern Boolean _CFURLInitAbsoluteURLWithBytes(CFURLRef url, const UInt8 *relativeURLBytes, CFIndex length, CFStringEncoding encoding, _Nullable CFURLRef baseURL);

extern CFHashCode CFHashBytes(uint8_t *bytes, CFIndex length);
extern CFIndex __CFProcessorCount();
extern uint64_t __CFMemorySize();
extern CFStringRef _CFProcessNameString(void);
extern CFIndex __CFActiveProcessorCount();
extern CFDictionaryRef __CFGetEnvironment();
extern int32_t __CFGetPid();

extern void _CFDataInit(CFMutableDataRef memory, CFOptionFlags flags, CFIndex capacity, const uint8_t *bytes, CFIndex length, Boolean noCopy);

extern int32_t _CF_SOCK_STREAM();

extern CFStringRef CFCopySystemVersionString(void);
extern CFDictionaryRef _CFCopySystemVersionDictionary(void);

extern Boolean _CFCalendarInitWithIdentifier(CFCalendarRef calendar, CFStringRef identifier);
extern Boolean _CFCalendarComposeAbsoluteTimeV(CFCalendarRef calendar, /* out */ CFAbsoluteTime *atp, const char *componentDesc, int32_t *vector, int32_t count);
extern Boolean _CFCalendarDecomposeAbsoluteTimeV(CFCalendarRef calendar, CFAbsoluteTime at, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
extern Boolean _CFCalendarAddComponentsV(CFCalendarRef calendar, /* inout */ CFAbsoluteTime *atp, CFOptionFlags options, const char *componentDesc, int32_t *vector, int32_t count);
extern Boolean _CFCalendarGetComponentDifferenceV(CFCalendarRef calendar, CFAbsoluteTime startingAT, CFAbsoluteTime resultAT, CFOptionFlags options, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
extern Boolean _CFCalendarIsWeekend(CFCalendarRef calendar, CFAbsoluteTime at);

typedef struct {
    CFTimeInterval onsetTime;
    CFTimeInterval ceaseTime;
    CFIndex start;
    CFIndex end;
} _CFCalendarWeekendRange;

extern Boolean _CFCalendarGetNextWeekend(CFCalendarRef calendar, _CFCalendarWeekendRange *range);

extern Boolean _CFLocaleInit(CFLocaleRef locale, CFStringRef identifier);

extern Boolean _CFTimeZoneInit(CFTimeZoneRef timeZone, CFStringRef name, _Nullable CFDataRef data);

extern Boolean _CFCharacterSetInitWithCharactersInRange(CFMutableCharacterSetRef cset, CFRange theRange);
extern Boolean _CFCharacterSetInitWithCharactersInString(CFMutableCharacterSetRef cset, CFStringRef theString);
extern Boolean _CFCharacterSetInitMutable(CFMutableCharacterSetRef cset);
extern Boolean _CFCharacterSetInitWithBitmapRepresentation(CFMutableCharacterSetRef cset, CFDataRef theData);
extern CFIndex __CFCharDigitValue(UniChar ch);

extern CFTimeInterval CFGetSystemUptime(void);

extern int _CFOpenFileWithMode(const char *path, int opts, mode_t mode);
extern int _CFOpenFile(const char *path, int opts);
extern void *_CFReallocf(void *ptr, size_t size);

CFHashCode CFStringHashNSString(CFStringRef str);

extern CFTypeRef _CFRunLoopGet2(CFRunLoopRef rl);

extern CFIndex __CFStringEncodeByteStream(CFStringRef string, CFIndex rangeLoc, CFIndex rangeLen, Boolean generatingExternalFile, CFStringEncoding encoding, uint8_t lossByte,  UInt8 * _Nullable buffer, CFIndex max, CFIndex * _Nullable usedBufLen);

typedef	unsigned char __cf_uuid[16];
typedef	char __cf_uuid_string[37];
typedef __cf_uuid _cf_uuid_t;
typedef __cf_uuid_string _cf_uuid_string_t;

extern void _cf_uuid_clear(_cf_uuid_t uu);
extern int _cf_uuid_compare(const _cf_uuid_t uu1, const _cf_uuid_t uu2);
extern void _cf_uuid_copy(_cf_uuid_t dst, const _cf_uuid_t src);
extern void _cf_uuid_generate(_cf_uuid_t out);
extern void _cf_uuid_generate_random(_cf_uuid_t out);
extern void _cf_uuid_generate_time(_cf_uuid_t out);
extern int _cf_uuid_is_null(const _cf_uuid_t uu);
extern int _cf_uuid_parse(const _cf_uuid_string_t in, _cf_uuid_t uu);
extern void _cf_uuid_unparse(const _cf_uuid_t uu, _cf_uuid_string_t out);
extern void _cf_uuid_unparse_lower(const _cf_uuid_t uu, _cf_uuid_string_t out);
extern void _cf_uuid_unparse_upper(const _cf_uuid_t uu, _cf_uuid_string_t out);

CF_IMPLICIT_BRIDGING_DISABLED
CF_ASSUME_NONNULL_END

#endif /* __COREFOUNDATION_FORSWIFTFOUNDATIONONLY__ */
