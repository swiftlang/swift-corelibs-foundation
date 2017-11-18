/*	CFLocale_Private.h
	Copyright (c) 2016, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2016 Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors 
 */

#if !defined(__COREFOUNDATION_CFLOCALE_PRIVATE__)
#define __COREFOUNDATION_CFLOCALE_PRIVATE__ 1

#include <CoreFoundation/CoreFoundation.h>

typedef CF_ENUM(CFIndex, _CFLocaleCalendarDirection) {
    _kCFLocaleCalendarDirectionLeftToRight = 0,
    _kCFLocaleCalendarDirectionRightToLeft = 1
} API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _CFLocaleCalendarDirection _CFLocaleGetCalendarDirection(void) API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT const CFLocaleKey kCFLocaleTemperatureUnit API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT const CFStringRef kCFLocaleTemperatureUnitCelsius API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT const CFStringRef kCFLocaleTemperatureUnitFahrenheit API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));


#endif /* __COREFOUNDATION_CFLOCALE_PRIVATE__ */
