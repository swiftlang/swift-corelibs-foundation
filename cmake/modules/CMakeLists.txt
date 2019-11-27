
set(Foundation_EXPORTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/FoundationExports.cmake)
configure_file(FoundationConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/FoundationConfig.cmake)

get_property(Foundation_EXPORTS GLOBAL PROPERTY Foundation_EXPORTS)
export(TARGETS ${Foundation_EXPORTS} FILE ${Foundation_EXPORTS_FILE})
