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

add_library(FoundationXML
    CFAccess.swift
    XMLDocument.swift
    XMLDTD.swift
    XMLDTDNode.swift
    XMLElement.swift
    XMLNode.swift
    XMLParser.swift)

target_compile_options(FoundationXML PRIVATE
    "SHELL:$<$<COMPILE_LANGUAGE:Swift>:${_Foundation_swift_build_flags}>")

target_link_libraries(FoundationXML
    PRIVATE
        CoreFoundation
        _CFXMLInterface
    PUBLIC
        Foundation)

target_link_options(FoundationXML PRIVATE
    "SHELL:-no-toolchain-stdlib-rpath")

set_target_properties(FoundationXML PROPERTIES
    INSTALL_RPATH "$ORIGIN")

set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS FoundationXML)
_foundation_install_target(FoundationXML)
