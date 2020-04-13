add_executable(plutil
  main.swift)
target_link_libraries(plutil PRIVATE
  Foundation)
set_target_properties(plutil PROPERTIES
  INSTALL_RPATH "$ORIGIN/../lib/swift/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>")


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS plutil)
install(TARGETS plutil
  DESTINATION ${CMAKE_INSTALL_BINDIR})
