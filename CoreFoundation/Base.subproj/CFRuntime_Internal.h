/*	CFRuntime_Internal.h
	Copyright (c) 2018-2019, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#ifndef CFRuntime_Internal_h
#define CFRuntime_Internal_h

#include <CoreFoundation/CFRuntime.h>

// Note: Platform differences leave us with some holes in the table, but that's ok.

enum {
    _kCFRuntimeIDNotAType = 0,
    _kCFRuntimeIDCFType = 1,
    _kCFRuntimeIDCFAllocator = 2,
    _kCFRuntimeIDCFBasicHash = 3,
    _kCFRuntimeIDCFBag = 4,
    _kCFRuntimeIDCFString = 7,
    _kCFRuntimeIDCFNull = 16,
    _kCFRuntimeIDCFSet = 17,
    _kCFRuntimeIDCFDictionary = 18,
    _kCFRuntimeIDCFArray = 19,
    _kCFRuntimeIDCFData = 20,
    _kCFRuntimeIDCFBoolean = 21,
    _kCFRuntimeIDCFNumber = 22,
    _kCFRuntimeIDCFBinaryHeap = 23,
    _kCFRuntimeIDCFBitVector = 24,
    _kCFRuntimeIDCFCharacterSet = 25,
    _kCFRuntimeIDCFStorage = 26,
    _kCFRuntimeIDCFError = 27,
    _kCFRuntimeIDCFTree = 28,
    _kCFRuntimeIDCFURL = 29,
    _kCFRuntimeIDCFURLComponents = 30,
    _kCFRuntimeIDCFBundle = 31,
    _kCFRuntimeIDCFPFactory = 32,
    _kCFRuntimeIDCFPlugInInstance = 33,
    _kCFRuntimeIDCFUUID = 34,
    _kCFRuntimeIDCFMessagePort = 35,
#if TARGET_OS_MAC
    _kCFRuntimeIDCFMachPort = 36,
#endif
    _kCFRuntimeIDCFReadStream = 38,
    _kCFRuntimeIDCFWriteStream = 39,
    _kCFRuntimeIDCFKeyedArchiverUID = 41,
    _kCFRuntimeIDCFDate = 42,
    _kCFRuntimeIDCFRunLoop = 43,
    _kCFRuntimeIDCFRunLoopMode = 44,
    _kCFRuntimeIDCFRunLoopObserver = 45,
    _kCFRuntimeIDCFRunLoopSource = 46,
    _kCFRuntimeIDCFRunLoopTimer = 47,
    _kCFRuntimeIDCFTimeZone = 48,
    _kCFRuntimeIDCFCalendar = 49,
    _kCFRuntimeIDCFPreferencesDomain = 50,
#if TARGET_OS_WIN32
    _kCFRuntimeIDCFWindowsNamedPipe = 51,
#endif
    
    // After this point, the values were never hard-coded into __CFInitialize.
    
    _kCFRuntimeIDCFNotificationCenter = 52,
    _kCFRuntimeIDCFPasteboard = 53,
    _kCFRuntimeIDCFUserNotification = 54,
    _kCFRuntimeIDCFLocale = 55,
    _kCFRuntimeIDCFDateFormatter = 56,
    _kCFRuntimeIDCFNumberFormatter = 57,
#if TARGET_OS_OSX || DEPLOYMENT_RUNTIME_SWIFT
    _kCFRuntimeIDCFXMLParser = 58,
    _kCFRuntimeIDCFXMLNode = 59,
#endif
    _kCFRuntimeIDCFFileDescriptor = 60,
    _kCFRuntimeIDCFSocket = 61,
    _kCFRuntimeIDCFAttributedString = 62,
    _kCFRuntimeIDCFRunArray = 63,
    _kCFRuntimeIDCFDateComponents = 66,
    _kCFRuntimeIDCFDateIntervalFormatter = 69,

    // If you are adding a new value, it goes below this line.:
    
    // Stuff not in CF goes here. This value should be one more than the last one above.
    _kCFRuntimeStartingClassID
};

CF_PRIVATE const CFRuntimeClass __CFAllocatorClass;
CF_PRIVATE const CFRuntimeClass __CFBasicHashClass;
CF_PRIVATE const CFRuntimeClass __CFBagClass;
CF_PRIVATE const CFRuntimeClass __CFStringClass;
CF_PRIVATE const CFRuntimeClass __CFNullClass;
CF_PRIVATE const CFRuntimeClass __CFSetClass;
CF_PRIVATE const CFRuntimeClass __CFDictionaryClass;
CF_PRIVATE const CFRuntimeClass __CFArrayClass;
CF_PRIVATE const CFRuntimeClass __CFDataClass;
CF_PRIVATE const CFRuntimeClass __CFBooleanClass;
CF_PRIVATE const CFRuntimeClass __CFNumberClass;
CF_PRIVATE const CFRuntimeClass __CFBinaryHeapClass;
CF_PRIVATE const CFRuntimeClass __CFBitVectorClass;
CF_PRIVATE const CFRuntimeClass __CFCharacterSetClass;
CF_PRIVATE const CFRuntimeClass __CFStorageClass;
CF_PRIVATE const CFRuntimeClass __CFErrorClass;
CF_PRIVATE const CFRuntimeClass __CFTreeClass;
CF_PRIVATE const CFRuntimeClass __CFURLClass;
CF_PRIVATE const CFRuntimeClass __CFURLComponentsClass;
CF_PRIVATE const CFRuntimeClass __CFBundleClass;
CF_PRIVATE const CFRuntimeClass __CFPlugInInstanceClass;


CF_PRIVATE const CFRuntimeClass __CFPasteboardClass;
CF_PRIVATE const CFRuntimeClass __CFUserNotificationClass;
CF_PRIVATE const CFRuntimeClass __CFUUIDClass;
CF_PRIVATE const CFRuntimeClass __CFLocaleClass;
CF_PRIVATE const CFRuntimeClass __CFDateFormatterClass;
CF_PRIVATE const CFRuntimeClass __CFNumberFormatterClass;
CF_PRIVATE const CFRuntimeClass __CFCalendarClass;
CF_PRIVATE const CFRuntimeClass __CFDateClass;
CF_PRIVATE const CFRuntimeClass __CFTimeZoneClass;
CF_PRIVATE const CFRuntimeClass __CFDateClass;
CF_PRIVATE const CFRuntimeClass __CFKeyedArchiverUIDClass;
CF_PRIVATE const CFRuntimeClass __CFXMLParserClass;
CF_PRIVATE const CFRuntimeClass __CFXMLNodeClass;
CF_PRIVATE const CFRuntimeClass __CFPFactoryClass;

CF_PRIVATE const CFRuntimeClass __CFPreferencesDomainClass;

CF_PRIVATE const CFRuntimeClass __CFMachPortClass;


CF_PRIVATE const CFRuntimeClass __CFRunLoopModeClass;
CF_PRIVATE const CFRuntimeClass __CFRunLoopClass;
CF_PRIVATE const CFRuntimeClass __CFRunLoopSourceClass;
CF_PRIVATE const CFRuntimeClass __CFRunLoopObserverClass;
CF_PRIVATE const CFRuntimeClass __CFRunLoopTimerClass;
CF_PRIVATE const CFRuntimeClass __CFSocketClass;
CF_PRIVATE const CFRuntimeClass __CFReadStreamClass;
CF_PRIVATE const CFRuntimeClass __CFWriteStreamClass;
CF_PRIVATE const CFRuntimeClass __CFAttributedStringClass;
CF_PRIVATE const CFRuntimeClass __CFRunArrayClass;
#if TARGET_OS_WIN32
CF_PRIVATE const CFRuntimeClass __CFWindowsNamedPipeClass;
#endif
CF_PRIVATE const CFRuntimeClass __CFTimeZoneClass;
CF_PRIVATE const CFRuntimeClass __CFCalendarClass;
CF_PRIVATE const CFRuntimeClass __CFDateComponentsClass;
CF_PRIVATE const CFRuntimeClass __CFDateIntervalFormatterClass;

#pragma mark - Private initialiers to run at process start time

CF_PRIVATE void __CFDateInitialize(void);
CF_PRIVATE void __CFCharacterSetInitialize(void);

#if TARGET_OS_WIN32
CF_PRIVATE void __CFTSDWindowsInitialize(void);
#endif

#if TARGET_OS_MAC || TARGET_OS_IPHONE || TARGET_OS_WIN32
CF_PRIVATE void __CFXPreferencesInitialize(void);
#endif


#endif /* CFRuntime_Internal_h */
