
add_executable(plutil
  main.swift)
target_link_libraries(plutil PRIVATE
  Foundation)
# TODO(compnerd) properly propogate `BUILD_RPATH` to the target using CMake
if(NOT CMAKE_SYSTEM_NAME STREQUAL Windows AND NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_link_options(plutil PRIVATE
    "SHELL:-Xlinker -rpath -Xlinker $$$$ORIGIN/../lib/swift/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>:$<TARGET_FILE_DIR:Foundation>")
endif()

set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS plutil)
install(TARGETS plutil
  DESTINATION ${CMAKE_INSTALL_BINDIR})
