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

cmake_minimum_required(VERSION 3.24)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

if(POLICY CMP0156)
    # Deduplicate linked libraries where appropriate
    cmake_policy(SET CMP0156 NEW)
endif()

if(POLICY CMP0157)
    # New Swift build model: improved incremental build performance and LSP support
    cmake_policy(SET CMP0157 NEW)
endif()

if (NOT DEFINED CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER clang)
endif()

project(Foundation
    LANGUAGES C Swift)

if(NOT SWIFT_SYSTEM_NAME)
  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(SWIFT_SYSTEM_NAME macosx)
  else()
    set(SWIFT_SYSTEM_NAME "$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>")
  endif()
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

# Fetchable dependcies
include(FetchContent)
if (_SwiftFoundationICU_SourceDIR)
    FetchContent_Declare(SwiftFoundationICU
        SOURCE_DIR ${_SwiftFoundationICU_SourceDIR})
else()
    FetchContent_Declare(SwiftFoundationICU
        GIT_REPOSITORY https://github.com/apple/swift-foundation-icu.git
        GIT_TAG 0.0.8)
endif()

if (_SwiftFoundation_SourceDIR)
    FetchContent_Declare(SwiftFoundation
        SOURCE_DIR ${_SwiftFoundation_SourceDIR})
else()
    FetchContent_Declare(SwiftFoundation
        GIT_REPOSITORY https://github.com/apple/swift-foundation.git
        GIT_TAG main)
endif()
FetchContent_MakeAvailable(SwiftFoundationICU SwiftFoundation)

# System dependencies (fail fast if dependencies are missing)
find_package(LibXml2 REQUIRED)
find_package(CURL REQUIRED)
find_package(dispatch CONFIG REQUIRED)

# Common build flags (_CFURLSessionInterface, _CFXMLInterface, CoreFoundation)
list(APPEND _Foundation_common_build_flags
    "-DDEPLOYMENT_RUNTIME_SWIFT"
    "-DCF_BUILDING_CF"
    "-DDEPLOYMENT_ENABLE_LIBDISPATCH"
    "-DHAVE_STRUCT_TIMESPEC"
    "-DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS"
    "-Wno-shorten-64-to-32"
    "-Wno-deprecated-declarations"
    "-Wno-unreachable-code"
    "-Wno-conditional-uninitialized"
    "-Wno-unused-variable"
    "-Wno-unused-function"
    "-Wno-microsoft-enum-forward-reference"
    "-fconstant-cfstrings"
    "-fexceptions" # TODO: not on OpenBSD
    "-fdollars-in-identifiers"
    "-fno-common"
    "-fcf-runtime-abi=swift"
    "-fblocks")

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    list(APPEND _Foundation_common_build_flags
        "-DDEBUG")
endif()

# Swift build flags (Foundation, FoundationNetworking, FoundationXML)
set(_Foundation_swift_build_flags)
list(APPEND _Foundation_swift_build_flags
    "-DDEPLOYMENT_RUNTIME_SWIFT"
    "-DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
    list(APPEND _Foundation_common_build_flags
        "-D_GNU_SOURCE"
        "-I/usr/lib/swift") # dispatch
endif()

include(FoundationSwiftSupport)

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
