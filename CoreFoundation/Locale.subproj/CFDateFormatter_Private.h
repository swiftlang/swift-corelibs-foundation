/*	CFDateFormatter_Private.h
	Copyright (c) 2015-2016, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2016 Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#if !defined(__COREFOUNDATION_CFDATEFORMATTER_PRIVATE__)
#define __COREFOUNDATION_CFDATEFORMATTER_PRIVATE__ 1

#include <CoreFoundation/CFDateFormatter.h>
#include <CoreFoundation/CFAttributedString.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN

CF_EXPORT
CFAttributedStringRef _CFDateFormatterCreateAttributedStringAndFieldsWithAbsoluteTime(CFAllocatorRef allocator, CFDateFormatterRef formatter, CFAbsoluteTime at) CF_AVAILABLE(10_11, 9_0);

CF_EXPORT const CFStringRef kCFDateFormatterPatternCharacterKey CF_AVAILABLE(10_11, 9_0);
CF_EXPORT const CFStringRef kCFDateFormatterPatternLiteralKey CF_AVAILABLE(10_11, 9_0);
CF_EXPORT const CFStringRef kCFDateFormatterPatternStringKey CF_AVAILABLE(10_11, 9_0);
CF_EXPORT const CFStringRef kCFDateFormatterPatternRangeKey CF_AVAILABLE(10_11, 9_0);

CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* ! __COREFOUNDATION_CFDATEFORMATTER_PRIVATE__ */

