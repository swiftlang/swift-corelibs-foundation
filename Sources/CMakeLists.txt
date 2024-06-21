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
add_subdirectory(_CFURLSessionInterface)
add_subdirectory(Foundation)
add_subdirectory(FoundationXML)
add_subdirectory(FoundationNetworking)
if(FOUNDATION_BUILD_TOOLS)
	add_subdirectory(plutil)
endif()
