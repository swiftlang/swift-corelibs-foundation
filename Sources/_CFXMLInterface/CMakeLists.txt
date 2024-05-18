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

add_library(_CFXMLInterface STATIC CFXMLInterface.c)

target_include_directories(_CFXMLInterface
    PUBLIC
        include
    PRIVATE
        ../CoreFoundation/internalInclude
        ../CoreFoundation/include
        /usr/include/libxml2/)

target_compile_options(_CFXMLInterface PRIVATE
    "SHELL:$<$<COMPILE_LANGUAGE:C>:${_Foundation_common_build_flags}>")

target_link_libraries(_CFXMLInterface PRIVATE
    CoreFoundation
    dispatch
    LibXml2::LibXml2)

if(NOT BUILD_SHARED_LIBS)
    set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS _CFXMLInterface)
endif()