/*    CFString_Private.h
    Copyright (c) 2020, Apple Inc. All rights reserved.
*/

#if !defined(__COREFOUNDATION_CFSTRING_PRIVATE__)
#define __COREFOUNDATION_CFSTRING_PRIVATE__ 1

#include "CFString.h"
#include "CFBundle.h"

CF_ASSUME_NONNULL_BEGIN
CF_EXTERN_C_BEGIN

CF_EXPORT CFStringRef _Nullable _CFStringCreateTaggedPointerString(const uint8_t *bytes, CFIndex numBytes);

// Returns a string containing the vocative case of \c givenName based on the language and region of \c locale.
// Not all languages or regions use the vocative case, so very often, this will return \c givenName as-is.
CF_EXPORT CFStringRef _Nullable _CFStringCopyVocativeCaseOfGivenName(CFStringRef givenName, CFLocaleRef locale) API_UNAVAILABLE(macos, ios, watchos, tvos);

/*
 If a process is loading strings manually from an Apple bundle, that process should use this call to ensure that any Markdown is parsed and inflected before using the string. If a process is using CFCopyLocalizedString…, CFBundleCopyLocalizedString, or the Foundation counterparts, this step is unnecessary, as those calls will do it for you if needed.
 
 Note that only strings from Apple bundles need inflection; all others will just be returned retained.
 */
CF_EXPORT CFStringRef _CFStringCreateByParsingMarkdownAndInflectingIfNeeded(CFStringRef source, CFBundleRef _Nullable originBundle, CFURLRef _Nullable sourceStringsFileURLIfAny)
    API_UNAVAILABLE(macos, ios, watchos, tvos);

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END

#endif /* ! __COREFOUNDATION_CFSTRING_PRIVATE__ */

