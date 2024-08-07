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

# Build the vendored version of the BlocksRuntime library, which is used by
# platforms that don't support libdispatch.

add_library(BlocksRuntime
    data.c
    runtime.c)

target_include_directories(BlocksRuntime PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    # For CFTargetConditionals.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../include)

set_target_properties(BlocksRuntime PROPERTIES
    POSITION_INDEPENDENT_CODE FALSE)

add_library(BlocksRuntime::BlocksRuntime ALIAS BlocksRuntime)

if(NOT BUILD_SHARED_LIBS)
    set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS BlocksRuntime)
    install(TARGETS BlocksRuntime
        ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${SWIFT_SYSTEM_NAME}
        LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${SWIFT_SYSTEM_NAME})
endif()
