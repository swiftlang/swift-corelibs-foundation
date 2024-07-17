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

add_library(_CFURLSessionInterface STATIC CFURLSessionInterface.c)

target_include_directories(_CFURLSessionInterface
    PUBLIC
        include
        ../CoreFoundation/include
    PRIVATE
        ../CoreFoundation/internalInclude)

target_precompile_headers(_CFURLSessionInterface PRIVATE ${CMAKE_SOURCE_DIR}/Sources/CoreFoundation/internalInclude/CoreFoundation_Prefix.h)

target_compile_options(_CFURLSessionInterface PRIVATE
    "SHELL:$<$<COMPILE_LANGUAGE:C>:${_Foundation_common_build_flags}>")

target_link_libraries(_CFURLSessionInterface PRIVATE
    dispatch
    CURL::libcurl)

if(NOT BUILD_SHARED_LIBS)
    set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS _CFURLSessionInterface)
    install(TARGETS _CFURLSessionInterface
        ARCHIVE DESTINATION lib/swift_static/${SWIFT_SYSTEM_NAME}
        LIBRARY DESTINATION lib/swift_static/${SWIFT_SYSTEM_NAME}
        RUNTIME DESTINATION bin)
endif()
