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

# Build the BlocksRuntime as an object library, shipped as a part
# of libCoreFoundation.
add_library(BlocksRuntime OBJECT
    data.c
    runtime.c)

target_include_directories(BlocksRuntime PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    # For CFTargetConditionals.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../include)

set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS BlocksRuntime)
