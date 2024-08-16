// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#include "CFBase.h"
#include "CFString.h"

#if TARGET_OS_WINDOWS

CF_PRIVATE CFStringRef _CFTimeZoneCopyWindowsNameForOlsonName(CFStringRef olson);
CF_PRIVATE CFStringRef _CFTimeZoneCopyOlsonNameForWindowsName(CFStringRef windows);

#endif
