/*	CFDateFormatter.h
	Copyright (c) 2003-2019, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#if !defined(__COREFOUNDATION_CFDATEFORMATTER__)
#define __COREFOUNDATION_CFDATEFORMATTER__ 1

#include "CFBase.h"
#include "CFDate.h"
#include "CFLocale.h"

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN

typedef CFStringRef CFDateFormatterKey CF_STRING_ENUM;

typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFDateFormatter *CFDateFormatterRef;

// CFDateFormatters are not thread-safe.  Do not use one from multiple threads!

CF_EXPORT
CFStringRef CFDateFormatterCreateDateFormatFromTemplate(CFAllocatorRef allocator, CFStringRef tmplate, CFOptionFlags options, CFLocaleRef locale) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
	// no options defined, pass 0 for now

CF_EXPORT
CFTypeID CFDateFormatterGetTypeID(void);

// The exact formatted result for these date and time styles depends on the
// locale, but generally:
//     Short is completely numeric, such as "12/13/52" or "3:30pm"
//     Medium is longer, such as "Jan 12, 1952"
//     Long is longer, such as "January 12, 1952" or "3:30:32pm"
//     Full is pretty complete; e.g. "Tuesday, April 12, 1952 AD" or "3:30:42pm PST"
// The specifications though are left fuzzy, in part simply because a user's
// preference choices may affect the output, and also the results may change
// from one OS release to another.  To produce an exactly formatted date you
// should not rely on styles and localization, but set the format string and
// use nothing but numbers.

typedef CF_ENUM(CFIndex, CFDateFormatterStyle) {	// date and time format styles
    kCFDateFormatterNoStyle = 0,
    kCFDateFormatterShortStyle = 1,
    kCFDateFormatterMediumStyle = 2,
    kCFDateFormatterLongStyle = 3,
    kCFDateFormatterFullStyle = 4
};

CF_EXPORT
CFDateFormatterRef CFDateFormatterCreate(CFAllocatorRef allocator, CFLocaleRef locale, CFDateFormatterStyle dateStyle, CFDateFormatterStyle timeStyle);
	// Returns a CFDateFormatter, localized to the given locale, which
	// will format dates to the given date and time styles.

CF_EXPORT
CFLocaleRef CFDateFormatterGetLocale(CFDateFormatterRef formatter);

CF_EXPORT
CFDateFormatterStyle CFDateFormatterGetDateStyle(CFDateFormatterRef formatter);

CF_EXPORT
CFDateFormatterStyle CFDateFormatterGetTimeStyle(CFDateFormatterRef formatter);
	// Get the properties with which the date formatter was created.

CF_EXPORT
CFStringRef CFDateFormatterGetFormat(CFDateFormatterRef formatter);

CF_EXPORT
void CFDateFormatterSetFormat(CFDateFormatterRef formatter, CFStringRef formatString);
	// Set the format description string of the date formatter.  This
	// overrides the style settings.  The format of the format string
	// is as defined by the ICU library.  The date formatter starts with a
	// default format string defined by the style arguments with
	// which it was created.


CF_EXPORT
CFStringRef CFDateFormatterCreateStringWithDate(CFAllocatorRef allocator, CFDateFormatterRef formatter, CFDateRef date);

CF_EXPORT
CFStringRef CFDateFormatterCreateStringWithAbsoluteTime(CFAllocatorRef allocator, CFDateFormatterRef formatter, CFAbsoluteTime at);
	// Create a string representation of the given date or CFAbsoluteTime
	// using the current state of the date formatter.


CF_EXPORT
CFDateRef CFDateFormatterCreateDateFromString(CFAllocatorRef allocator, CFDateFormatterRef formatter, CFStringRef string, CFRange *rangep);

CF_EXPORT
Boolean CFDateFormatterGetAbsoluteTimeFromString(CFDateFormatterRef formatter, CFStringRef string, CFRange *rangep, CFAbsoluteTime *atp);
	// Parse a string representation of a date using the current state
	// of the date formatter.  The range parameter specifies the range
	// of the string in which the parsing should occur in input, and on
	// output indicates the extent that was used; this parameter can
	// be NULL, in which case the whole string may be used.  The
	// return value indicates whether some date was computed and
	// (if atp is not NULL) stored at the location specified by atp.


CF_EXPORT
void CFDateFormatterSetProperty(CFDateFormatterRef formatter, CFStringRef key, CFTypeRef value);

CF_EXPORT
CFTypeRef CFDateFormatterCopyProperty(CFDateFormatterRef formatter, CFDateFormatterKey key);
	// Set and get various properties of the date formatter, the set of
	// which may be expanded in the future.

CF_EXPORT const CFDateFormatterKey kCFDateFormatterIsLenient;	// CFBoolean
CF_EXPORT const CFDateFormatterKey kCFDateFormatterTimeZone;		// CFTimeZone
CF_EXPORT const CFDateFormatterKey kCFDateFormatterCalendarName;	// CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterDefaultFormat;	// CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterTwoDigitStartDate; // CFDate
CF_EXPORT const CFDateFormatterKey kCFDateFormatterDefaultDate;	// CFDate
CF_EXPORT const CFDateFormatterKey kCFDateFormatterCalendar;		// CFCalendar
CF_EXPORT const CFDateFormatterKey kCFDateFormatterEraSymbols;	// CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterMonthSymbols;	// CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortMonthSymbols; // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterWeekdaySymbols;	// CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortWeekdaySymbols; // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterAMSymbol;		// CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterPMSymbol;		// CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterLongEraSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));   // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterVeryShortMonthSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterStandaloneMonthSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortStandaloneMonthSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterVeryShortStandaloneMonthSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterVeryShortWeekdaySymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterStandaloneWeekdaySymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortStandaloneWeekdaySymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterVeryShortStandaloneWeekdaySymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterQuarterSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); 	// CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortQuarterSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterStandaloneQuarterSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterShortStandaloneQuarterSymbols API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFArray of CFString
CF_EXPORT const CFDateFormatterKey kCFDateFormatterGregorianStartDate API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)); // CFDate
CF_EXPORT const CFDateFormatterKey kCFDateFormatterDoesRelativeDateFormattingKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0)); // CFBoolean

// See CFLocale.h for these calendar constants:
//	const CFStringRef kCFGregorianCalendar;
//	const CFStringRef kCFBuddhistCalendar;
//	const CFStringRef kCFJapaneseCalendar;
//	const CFStringRef kCFIslamicCalendar;
//	const CFStringRef kCFIslamicCivilCalendar;
//	const CFStringRef kCFHebrewCalendar;
//	const CFStringRef kCFChineseCalendar;
//	const CFStringRef kCFRepublicOfChinaCalendar;
//	const CFStringRef kCFPersianCalendar;
//	const CFStringRef kCFIndianCalendar;
//	const CFStringRef kCFISO8601Calendar;

CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* ! __COREFOUNDATION_CFDATEFORMATTER__ */

