##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift open source project
##
## Copyright (c) 2024 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.md for the list of Swift project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

add_subdirectory(CoreFoundation)
add_subdirectory(_CFXMLInterface)
if(FOUNDATION_BUILD_NETWORKING)
    add_subdirectory(_CFURLSessionInterface)
endif()
add_subdirectory(Foundation)
add_subdirectory(FoundationXML)
if(FOUNDATION_BUILD_NETWORKING)
    add_subdirectory(FoundationNetworking)
endif()
if(FOUNDATION_BUILD_TOOLS)
	add_subdirectory(plutil)
endif()
