/*	CFURLComponents.h
	Copyright (c) 2015-2019, Apple Inc. All rights reserved.
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#ifndef __COREFOUNDATION_CFURLCOMPONENTS__
#define __COREFOUNDATION_CFURLCOMPONENTS__

// This file is for the use of NSURLComponents only.

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFURL.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFNumber.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN
CF_ASSUME_NONNULL_BEGIN

typedef struct CF_BRIDGED_TYPE(id) __CFURLComponents *CFURLComponentsRef;

CF_EXPORT CFTypeID _CFURLComponentsGetTypeID(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// URLComponents are always mutable.
CF_EXPORT _Nullable CFURLComponentsRef _CFURLComponentsCreate(CFAllocatorRef alloc) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFURLComponentsRef _CFURLComponentsCreateWithURL(CFAllocatorRef alloc, CFURLRef url, Boolean resolveAgainstBaseURL) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFURLComponentsRef _CFURLComponentsCreateWithString(CFAllocatorRef alloc, CFStringRef string) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFURLComponentsRef _CFURLComponentsCreateCopy(CFAllocatorRef alloc, CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFURLRef _CFURLComponentsCopyURL(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFURLRef _CFURLComponentsCopyURLRelativeToURL(CFURLComponentsRef components, _Nullable CFURLRef relativeToURL) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyString(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyScheme(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyUser(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPassword(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyHost(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFNumberRef _CFURLComponentsCopyPort(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPath(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyQuery(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyFragment(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// Returns true if the scheme argument can be passed to _CFURLComponentsSetScheme. A valid scheme string is an ALPHA character followed by 0 or more ALPHA, DIGIT, "+", "-", or "." characters. Because NULL can be passed to _CFURLComponentsSetScheme to clear the scheme component, passing NULL to this function also returns true.
CF_EXPORT Boolean _CFURLComponentsSchemeIsValid(_Nullable CFStringRef scheme) API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0));

// These return false if the conversion fails
CF_EXPORT Boolean _CFURLComponentsSetScheme(CFURLComponentsRef components, _Nullable CFStringRef scheme) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetUser(CFURLComponentsRef components, _Nullable CFStringRef user) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPassword(CFURLComponentsRef components, _Nullable CFStringRef password) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetHost(CFURLComponentsRef components, _Nullable CFStringRef host) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPort(CFURLComponentsRef components, _Nullable CFNumberRef port) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPath(CFURLComponentsRef components, _Nullable CFStringRef path) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetQuery(CFURLComponentsRef components, _Nullable CFStringRef query) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetFragment(CFURLComponentsRef components, _Nullable CFStringRef fragment) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedUser(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedPassword(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedHost(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedPath(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedQuery(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT _Nullable CFStringRef _CFURLComponentsCopyPercentEncodedFragment(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// These return false if the conversion fails
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedUser(CFURLComponentsRef components, _Nullable CFStringRef user) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedPassword(CFURLComponentsRef components, _Nullable CFStringRef password) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedHost(CFURLComponentsRef components, _Nullable CFStringRef host) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedPath(CFURLComponentsRef components, _Nullable CFStringRef path) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedQuery(CFURLComponentsRef components, _Nullable CFStringRef query) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedFragment(CFURLComponentsRef components, _Nullable CFStringRef fragment) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT CFRange _CFURLComponentsGetRangeOfScheme(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfUser(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfPassword(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfHost(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfPort(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfPath(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfQuery(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFRange _CFURLComponentsGetRangeOfFragment(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT CFStringRef _CFStringCreateByAddingPercentEncodingWithAllowedCharacters(CFAllocatorRef alloc, CFStringRef string, CFCharacterSetRef allowedCharacters) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFStringRef _Nullable _CFStringCreateByRemovingPercentEncoding(CFAllocatorRef alloc, CFStringRef string) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// These return singletons
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLUserAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLPasswordAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLHostAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLPathAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLQueryAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT CFCharacterSetRef _CFURLComponentsGetURLFragmentAllowedCharacterSet(void) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// keys for dictionaries returned by _CFURLComponentsCopyQueryItems
CF_EXPORT const CFStringRef _kCFURLComponentsNameKey API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0));
CF_EXPORT const CFStringRef _kCFURLComponentsValueKey API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0));

CF_EXPORT _Nullable CFArrayRef _CFURLComponentsCopyQueryItems(CFURLComponentsRef components) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));
CF_EXPORT void _CFURLComponentsSetQueryItems(CFURLComponentsRef components, CFArrayRef names, CFArrayRef values) API_AVAILABLE(macos(10.12), ios(10.0), watchos(3.0), tvos(10.0));

CF_EXPORT _Nullable CFArrayRef _CFURLComponentsCopyPercentEncodedQueryItems(CFURLComponentsRef components) API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0));
CF_EXPORT Boolean _CFURLComponentsSetPercentEncodedQueryItems(CFURLComponentsRef components, CFArrayRef names, CFArrayRef values) API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0));

CF_ASSUME_NONNULL_END
CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif // __COREFOUNDATION_CFURLCOMPONENTS__
