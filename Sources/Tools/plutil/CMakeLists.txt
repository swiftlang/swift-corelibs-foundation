add_executable(plutil
  main.swift)
target_link_libraries(plutil PRIVATE
  Foundation)

# On ELF platforms, remove the absolute rpath to the host toolchain's stdlib,
# then add it back temporarily as a BUILD_RPATH just for the tests.
if(NOT CMAKE_SYSTEM_NAME MATCHES "Darwin|Windows")
  target_link_options(plutil PRIVATE "SHELL:-no-toolchain-stdlib-rpath")

  string(REPLACE " " ";" ARGS_LIST "${CMAKE_Swift_FLAGS}")
  execute_process(
    COMMAND ${CMAKE_Swift_COMPILER} ${ARGS_LIST} -print-target-info
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error_output
    RESULT_VARIABLE result
  )
  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "Error getting target info with\n"
      "  `${CMAKE_Swift_COMPILER} ${CMAKE_Swift_FLAGS} -print-target-info`\n"
      "Error:\n"
      "  ${error_output}")
  endif()

  string(REGEX MATCH "\"runtimeLibraryPaths\": \\[\n\ +\"([^\"]+)\""
           path ${output})
  set_target_properties(plutil PROPERTIES BUILD_RPATH ${CMAKE_MATCH_1})
endif()

set_target_properties(plutil PROPERTIES
  INSTALL_RPATH "$ORIGIN/../lib/swift/${SWIFT_SYSTEM_NAME}")


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS plutil)
install(TARGETS plutil
  DESTINATION ${CMAKE_INSTALL_BINDIR})
