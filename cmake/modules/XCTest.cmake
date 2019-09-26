cmake_policy(PUSH)
cmake_policy(SET CMP0057 NEW)

# Automatically add tests with CTest by querying the compiled test executable
# for available tests.
#
#   xctest_discover_tests(target
#                         [COMMAND command]
#                         [WORKING_DIRECTORY dir]
#                         [PROPERTIES name1 value1...]
#                         [DISCOVERY_TIMEOUT seconds]
#   )
#
# `xctest_discover_tests` sets up a post-build command on the test executable
# that generates the list of tests by parsing the output from running the test
# with the `--list-tests` argument.
#
# The options are:
#
# `target`
#   Specifies the XCTest executable, which must be a known CMake target. CMake
#   will substitute the location of the built executable when running the test.
#
# `COMMAND command`
#   Override the command used for the test executable. If you executable is not
#   created with CMake add_executable, you will have to provide a command path.
#   If this option is not provided, the target file of the target is used.
#
# `WORKING_DIRECTORY dir`
#   Specifies the directory in which to run the discovered test cases. If this
#   option is not provided, the current binary directory is used.
#
# `PROPERTIES name1 value1...`
#   Specifies additional properties to be set on all tests discovered by this
#   invocation of `xctest_discover_tests`.
#
# `DISCOVERY_TIMEOUT seconds`
#   Specifies how long (in seconds) CMake will wait for the test to enumerate
#   available tests. If the test takes longer than this, discovery (and your
#   build) will fail. The default is 5 seconds.
#
# The inspiration for this is CMake `gtest_discover_tests`. The official
# documentation might be useful for using this function. Many details of that
# function has been dropped in the name of simplicity, and others have been
# improved.
function(xctest_discover_tests TARGET)
  cmake_parse_arguments(
    ""
    ""
    "COMMAND;WORKING_DIRECTORY;DISCOVERY_TIMEOUT"
    "PROPERTIES"
    ${ARGN}
  )

  if(NOT _COMMAND)
    set(_COMMAND "$<TARGET_FILE:${TARGET}>")
  endif()
  if(NOT _WORKING_DIRECTORY)
    set(_WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  endif()
  if(NOT _DISCOVERY_TIMEOUT)
    set(_DISCOVERY_TIMEOUT 5)
  endif()

  set(ctest_file_base ${CMAKE_CURRENT_BINARY_DIR}/${TARGET})
  set(ctest_include_file "${ctest_file_base}_include.cmake")
  set(ctest_tests_file "${ctest_file_base}_tests.cmake")

  add_custom_command(
    TARGET ${TARGET} POST_BUILD
    BYPRODUCTS "${ctest_tests_file}"
    COMMAND "${CMAKE_COMMAND}"
            -D "TEST_TARGET=${TARGET}"
            -D "TEST_EXECUTABLE=${_COMMAND}"
            -D "TEST_WORKING_DIR=${_WORKING_DIRECTORY}"
            -D "TEST_PROPERTIES=${_PROPERTIES}"
            -D "CTEST_FILE=${ctest_tests_file}"
            -D "TEST_DISCOVERY_TIMEOUT=${_DISCOVERY_TIMEOUT}"
            -P "${_XCTEST_DISCOVER_TESTS_SCRIPT}"
    VERBATIM
  )

  file(WRITE "${ctest_include_file}"
    "if(EXISTS \"${ctest_tests_file}\")\n"
    "  include(\"${ctest_tests_file}\")\n"
    "else()\n"
    "  add_test(${TARGET}_NOT_BUILT ${TARGET}_NOT_BUILT)\n"
    "endif()\n"
  )

  set_property(DIRECTORY
    APPEND PROPERTY TEST_INCLUDE_FILES "${ctest_include_file}"
  )
endfunction()

set(_XCTEST_DISCOVER_TESTS_SCRIPT
  ${CMAKE_CURRENT_LIST_DIR}/XCTestAddTests.cmake
)

cmake_policy(POP)
