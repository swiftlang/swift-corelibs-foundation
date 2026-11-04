// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#include "CFTimeZone_WindowsMapping.h"

#if TARGET_OS_WINDOWS

#include <_foundation_unicode/ucal.h>

#define COUNT_OF(array) (sizeof((array)) / sizeof((array)[0]))

CFStringRef _CFTimeZoneCopyWindowsNameForOlsonName(CFStringRef olson) {
    if (olson == NULL) {
        return NULL;
    }
    UniChar olsonBuffer[128];
    UChar windowsBuffer[128];
    const CFIndex capacity = COUNT_OF(olsonBuffer);
    CFIndex length = CFStringGetLength(olson);
    if (length <= 0 || length >= capacity) {
        return NULL;
    }
    const UniChar *olsonPtr = CFStringGetCharactersPtr(olson);
    if (olsonPtr == NULL) {
        CFStringGetCharacters(olson, CFRangeMake(0, length), olsonBuffer);
        olsonPtr = olsonBuffer;
    }
    UErrorCode status = U_ZERO_ERROR;
    int32_t windowsLength = ucal_getWindowsTimeZoneID((const UChar *)olsonPtr, length, windowsBuffer, capacity, &status);
    if (U_SUCCESS(status) && windowsLength > 0) {
        return CFStringCreateWithCharacters(kCFAllocatorSystemDefault, (const UniChar *)windowsBuffer, windowsLength);
    }
    return NULL;
}

CFStringRef _CFTimeZoneCopyOlsonNameForWindowsName(CFStringRef windows) {
    if (windows == NULL) {
        return NULL;
    }
    UniChar windowsBuffer[128];
    UChar olsonBuffer[128];
    const CFIndex capacity = COUNT_OF(windowsBuffer);
    CFIndex length = CFStringGetLength(windows);
    if (length <= 0 || length >= capacity) {
        return NULL;
    }
    const UniChar *windowsPtr = CFStringGetCharactersPtr(windows);
    if (windowsPtr == NULL) {
        CFStringGetCharacters(windows, CFRangeMake(0, length), windowsBuffer);
        windowsPtr = windowsBuffer;
    }
    UErrorCode status = U_ZERO_ERROR;
    int32_t olsonLength = ucal_getTimeZoneIDForWindowsID((const UChar *)windowsPtr, length, NULL, olsonBuffer, capacity, &status);
    if (U_SUCCESS(status) && olsonLength > 0) {
        return CFStringCreateWithCharacters(kCFAllocatorSystemDefault, (const UniChar *)olsonBuffer, olsonLength);
    }
    return NULL;
}

#endif
