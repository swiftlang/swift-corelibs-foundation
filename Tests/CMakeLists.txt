##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift open source project
##
## Copyright (c) 2026 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.md for the list of Swift project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    add_executable(CoreFoundationHashableTests
        CoreFoundation/TestCFObjectHashable.swift)

    target_compile_options(CoreFoundationHashableTests PRIVATE
        "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library -swift-version 6>"
        "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xcc -fmodule-map-file=${CMAKE_SOURCE_DIR}/Sources/CoreFoundation/include/module.modulemap>")
    target_include_directories(CoreFoundationHashableTests PRIVATE
        ${CMAKE_SOURCE_DIR}/Sources/CoreFoundation/include)

    target_link_libraries(CoreFoundationHashableTests PRIVATE
        Foundation)

    add_test(NAME CoreFoundation.Hashable
        COMMAND CoreFoundationHashableTests)
    set_property(TEST CoreFoundation.Hashable PROPERTY
        ENVIRONMENT_MODIFICATION
            "LD_LIBRARY_PATH=path_list_prepend:$<TARGET_FILE_DIR:Foundation>")
endif()
