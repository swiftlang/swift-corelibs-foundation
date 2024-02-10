/*  CFCalendarPriv.h
    Copyright (c) 2004-2019, Apple Inc. and the Swift project authors
 
    Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
    Licensed under Apache License v2.0 with Runtime Library Exception
    See http://swift.org/LICENSE.txt for license information
    See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#if !defined(__COREFOUNDATION_CFCALENDAR_PRIV__)
#define __COREFOUNDATION_CFCALENDAR_PRIV__ 1

#include "CFBase.h"
#include "CFLocale.h"
#include "CFDate.h"
#include "CFTimeZone.h"
#include "CFDateComponents.h"
#include "CFCalendar.h"

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN
CF_ASSUME_NONNULL_BEGIN

// swift-corelibs-foundation only

typedef struct {
    CFTimeInterval onsetTime;
    CFTimeInterval ceaseTime;
    CFIndex start;
    CFIndex end;
} _CFCalendarWeekendRange;

CF_EXPORT Boolean _CFCalendarInitWithIdentifier(CFCalendarRef calendar, CFStringRef identifier);
CF_EXPORT Boolean _CFCalendarComposeAbsoluteTimeV(CFCalendarRef calendar, /* out */ CFAbsoluteTime *atp, const char *componentDesc, int32_t *vector, int32_t count);
CF_EXPORT Boolean _CFCalendarDecomposeAbsoluteTimeV(CFCalendarRef calendar, CFAbsoluteTime at, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
CF_EXPORT Boolean _CFCalendarAddComponentsV(CFCalendarRef calendar, /* inout */ CFAbsoluteTime *atp, CFOptionFlags options, const char *componentDesc, int32_t *vector, int32_t count);
CF_EXPORT Boolean _CFCalendarGetComponentDifferenceV(CFCalendarRef calendar, CFAbsoluteTime startingAT, CFAbsoluteTime resultAT, CFOptionFlags options, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
CF_EXPORT void _CFCalendarEnumerateDates(CFCalendarRef calendar, CFDateRef start, CFDateComponentsRef matchingComponents, CFOptionFlags opts, void (^block)(CFDateRef _Nullable, Boolean, Boolean*));

CF_EXPORT Boolean _CFCalendarIsDateInWeekend(CFCalendarRef calendar, CFDateRef date);
CF_EXPORT Boolean _CFCalendarGetNextWeekend(CFCalendarRef calendar, _CFCalendarWeekendRange *range);

CF_EXPORT void _CFCalendarEnumerateDates(CFCalendarRef calendar, CFDateRef start, CFDateComponentsRef matchingComponents, CFOptionFlags opts, void (^block)(CFDateRef _Nullable, Boolean, Boolean*));
CF_EXPORT void CFCalendarSetGregorianStartDate(CFCalendarRef calendar, CFDateRef _Nullable date);
CF_EXPORT _Nullable CFDateRef CFCalendarCopyGregorianStartDate(CFCalendarRef calendar);

CF_ASSUME_NONNULL_END
CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* ! __COREFOUNDATION_CFCALENDAR_PRIV__ */

