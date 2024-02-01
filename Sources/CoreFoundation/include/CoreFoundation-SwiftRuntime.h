// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*
    This version of CoreFoundation.h is for the "Swift Runtime" mode of CF only.
 
    Note: The contents of this file are only meant for compiling the Swift Foundation module. The library is not ABI or API stable and is not meant to be used as a general-purpose C library on Linux.
 
*/

#if !defined(__COREFOUNDATION_COREFOUNDATION__)
#define __COREFOUNDATION_COREFOUNDATION__ 1
#define __COREFOUNDATION__ 1

#define DEPLOYMENT_RUNTIME_SWIFT 1

#if !defined(CF_EXCLUDE_CSTD_HEADERS)

#include <sys/types.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#if !defined(__wasi__)
#include <setjmp.h>
#endif
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if __has_include(<netdb.h>)
#include <netdb.h> // for Host.swift
#endif

#if __has_include(<ifaddrs.h>) && !defined(__wasi__)
#include <ifaddrs.h> // for Host.swift
#endif

#if defined(__STDC_VERSION__) && (199901L <= __STDC_VERSION__)

#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>

#endif

#endif

#include "CFBase.h"
#include "CFArray.h"
#include "CFBag.h"
#include "CFBinaryHeap.h"
#include "CFBitVector.h"
#include "CFByteOrder.h"
#include "CFCalendar.h"
#include "CFCharacterSet.h"
#include "CFData.h"
#include "CFDate.h"
#include "CFDateFormatter.h"
#include "CFDictionary.h"
#include "CFError.h"
#include "CFLocale.h"
#include "CFNumber.h"
#include "CFNumberFormatter.h"
#include "CFPropertyList.h"
#include "CFSet.h"
#include "CFString.h"
#include "CFStringEncodingExt.h"
#include "CFTimeZone.h"
#include "CFTree.h"
#include "CFURL.h"
#include "CFURLAccess.h"
#include "CFUUID.h"
#include "CFUtilities.h"

#if !TARGET_OS_WASI
#include "CFBundle.h"
#include "CFPlugIn.h"
#include "CFMessagePort.h"
#include "CFPreferences.h"
#include "CFRunLoop.h"
#include "CFStream.h"
#include "CFSocket.h"
#include "CFMachPort.h"
#endif

#include "CFAttributedString.h"
#include "CFNotificationCenter.h"

#include "ForSwiftFoundationOnly.h"

#endif /* ! __COREFOUNDATION_COREFOUNDATION__ */

