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

set(Foundation_EXPORTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/FoundationExports.cmake)
set(SwiftFoundation_EXPORTS_FILE ${SwiftFoundation_BINARY_DIR}/cmake/modules/SwiftFoundationExports.cmake)
set(SwiftFoundationICU_EXPORTS_FILE ${SwiftFoundationICU_BINARY_DIR}/cmake/modules/SwiftFoundationICUExports.cmake)
set(SwiftCollections_EXPORTS_FILE ${SwiftCollections_BINARY_DIR}/cmake/modules/SwiftCollectionsExports.cmake)

configure_file(FoundationConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/FoundationConfig.cmake)

get_property(Foundation_EXPORTS GLOBAL PROPERTY Foundation_EXPORTS)
export(TARGETS ${Foundation_EXPORTS}
    FILE ${Foundation_EXPORTS_FILE}
    EXPORT_LINK_INTERFACE_LIBRARIES)
