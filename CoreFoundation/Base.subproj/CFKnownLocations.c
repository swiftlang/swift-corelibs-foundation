/*	CFKnownLocations.c
	Copyright (c) 1999-2017, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2017, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#include "CFKnownLocations.h"

#include <CoreFoundation/CFString.h>
#include "CFPriv.h"
#include "CFInternal.h"

CONST_STRING_DECL(_kCFKnownLocationUserAny, " == _kCFKnownLocationUserAny");
CONST_STRING_DECL(_kCFKnownLocationUserCurrent, " == _kCFKnownLocationUserCurrent");

CFURLRef _Nullable _CFKnownLocationCreatePreferencesURLForUser(CFKnownLocationUser user) {
    CFURLRef location = NULL;
    
#if (DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI)
    
/*
 Building for a Darwin OS. (We use these paths on Swift builds as well, so that we can interoperate a little with Darwin's defaults(1) command and the other system facilities; but you want to use the system version of CF if possible on those platforms, which will talk to cfprefsd(8) and has stronger interprocess consistency guarantees.)
 
 User:
 - Any: /Library/Preferences
 - Current: $HOME/Library/Preferences
 */
    
    if (user == _kCFKnownLocationUserAny) {
        location = CFURLCreateWithFileSystemPath(kCFAllocatorSystemDefault, CFSTR("/Library/Preferences"), kCFURLPOSIXPathStyle, true);
    } else {
        if (user == _kCFKnownLocationUserCurrent) {
            user = NULL;
        }
        
        CFURLRef home = CFCopyHomeDirectoryURLForUser(user);
        location = CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorSystemDefault, CFSTR("/Library/Preferences"), kCFURLPOSIXPathStyle, true, home);
        CFRelease(home);
    }
    
#elif !DEPLOYMENT_RUNTIME_OBJC && !DEPLOYMENT_TARGET_WINDOWS
    
/*
 Building for an OS that uses the FHS, BSD's hier(7), and/or the XDG specification for paths:
 
 User:
 - Any: /usr/local/etc/
 - Current: $XDG_CONFIG_PATH (usually: $HOME/.config/).
 */
    
    if (user == _kCFKnownLocationUserAny) {
        location = CFURLCreateWithFileSystemPath(kCFAllocatorSystemDefault, CFSTR("/usr/local/etc"), kCFURLPOSIXPathStyle, true);
    } else {
        assert(user == _kCFKnownLocationUserCurrent);
        
        if (user == _kCFKnownLocationUserCurrent) {
            location = _CFXDGCreateConfigHomePath();
        }
    }
    
#else
    
    #error For this platform, you need to define a preferences path for both 'any user' (i.e. installation-wide preferences) or the current user.
    
#endif
    
    return location;
}
