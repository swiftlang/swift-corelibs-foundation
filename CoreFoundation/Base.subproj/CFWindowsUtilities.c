/*	
	CFWindowsUtilities.c
	Copyright (c) 2008-2019, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
	Responsibility: Tony Parker
*/

#if TARGET_OS_WIN32
    
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFString.h>
#include "CFInternal.h"
#include "CFPriv.h"

#include <shlobj.h>

#include <sys/stat.h>

#include <stdatomic.h>

void _CFGetFrameworkPath(wchar_t *path, int maxLength) {
#ifdef _DEBUG
    // might be nice to get this from the project file at some point
    wchar_t *DLLFileName = L"CoreFoundation_debug.dll";
#else
    wchar_t *DLLFileName = L"CoreFoundation.dll";
#endif
    path[0] = path[1] = 0;
    DWORD wResult;
    CFIndex idx;
    HMODULE ourModule = GetModuleHandleW(DLLFileName);
    
    CFAssert(ourModule, __kCFLogAssertion, "GetModuleHandle failed");
    
    wResult = GetModuleFileNameW(ourModule, path, maxLength);
    CFAssert1(wResult > 0, __kCFLogAssertion, "GetModuleFileName failed: %d", GetLastError());
    CFAssert1(wResult < maxLength, __kCFLogAssertion, "GetModuleFileName result truncated: %s", path);
    
    // strip off last component, the DLL name
    for (idx = wResult - 1; idx; idx--) {
        if ('\\' == path[idx]) {
            path[idx] = '\0';
            break;
        }
    }
}

#endif

