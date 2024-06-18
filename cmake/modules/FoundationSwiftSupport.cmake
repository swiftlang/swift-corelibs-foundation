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

function(_foundation_install_target module)
  set(swift_os ${SWIFT_SYSTEM_NAME})
  get_target_property(type ${module} TYPE)

  if(type STREQUAL STATIC_LIBRARY)
    set(swift swift_static)
  else()
    set(swift swift)
  endif()

  install(TARGETS ${module}
    ARCHIVE DESTINATION lib/${swift}/${swift_os}
    LIBRARY DESTINATION lib/${swift}/${swift_os}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  if(type STREQUAL EXECUTABLE)
    return()
  endif()

  get_target_property(module_name ${module} Swift_MODULE_NAME)
  if(NOT module_name)
    set(module_name ${module})
  endif()

  if(NOT SwiftFoundation_MODULE_TRIPLE)
    set(module_triple_command "${CMAKE_Swift_COMPILER}" -print-target-info)
    if(CMAKE_Swift_COMPILER_TARGET)
      list(APPEND module_triple_command -target ${CMAKE_Swift_COMPILER_TARGET})
    endif()
    execute_process(COMMAND ${module_triple_command} OUTPUT_VARIABLE target_info_json)
    string(JSON module_triple GET "${target_info_json}" "target" "moduleTriple")
    set(SwiftFoundation_MODULE_TRIPLE "${module_triple}" CACHE STRING "swift module triple used for installed swiftmodule and swiftinterface files")
    mark_as_advanced(SwiftFoundation_MODULE_TRIPLE)
  endif()

  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftdoc
    DESTINATION lib/${swift}/${swift_os}/${module_name}.swiftmodule
    RENAME ${SwiftFoundation_MODULE_TRIPLE}.swiftdoc)
  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftmodule
    DESTINATION lib/${swift}/${swift_os}/${module_name}.swiftmodule
    RENAME ${SwiftFoundation_MODULE_TRIPLE}.swiftmodule)

endfunction()
