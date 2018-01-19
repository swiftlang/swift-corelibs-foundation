/*	CFKnownLocations.h
	Copyright (c) 1999-2017, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2017, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#if !defined(__COREFOUNDATION_CFKNOWNLOCATIONS__)
#define __COREFOUNDATION_CFKNOWNLOCATIONS__ 1

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFURL.h>

CF_ASSUME_NONNULL_BEGIN

typedef CFStringRef CFKnownLocationUser CF_TYPED_EXTENSIBLE_ENUM;

extern const CFKnownLocationUser _kCFKnownLocationUserAny;

extern const CFKnownLocationUser _kCFKnownLocationUserCurrent;

/* A note on support:
 
 - We document that CFPreferences… can only take AnyUser or CurrentUser as users.
 - The code we shipped so far accepted the name of any one user on the current system as an alternative, but:
 - For platforms that use the XDG spec to identify a configuration path in a user's home, we cannot determine that path for any user other than the one we're currently running as.
 
 So:
  - We're keeping that behavior when building Core Foundation for Darwin/ObjC for compatibility, hence the _EXTENSIBLE above; but
  - For Swift and any new platform, we are enforcing the documented constraint. Using a user value other than …Any or …Current above will assert (or return NULL if asserts are off).
 
 See CFKnownLocations.c for a summary of what paths are returned.
 */

extern CFURLRef _Nullable _CFKnownLocationCreatePreferencesURLForUser(CFKnownLocationUser user);

CF_ASSUME_NONNULL_END

#endif /* __COREFOUNDATION_CFKNOWNLOCATIONS__ */
