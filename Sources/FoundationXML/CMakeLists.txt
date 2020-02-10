add_library(FoundationXML
  XMLDocument.swift
  XMLDTD.swift
  XMLDTDNode.swift
  XMLElement.swift
  XMLNode.swift
  XMLParser.swift)
target_compile_definitions(FoundationXML PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT)
target_compile_options(FoundationXML PUBLIC
  $<$<BOOL:${ENABLE_TESTING}>:-enable-testing>
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")
target_link_libraries(FoundationXML
  PRIVATE
    CFXMLInterface
  PUBLIC
    Foundation)
set_target_properties(FoundationXML PROPERTIES
  INSTALL_RPATH "$ORIGIN"
  Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/swift)


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS FoundationXML)
install(TARGETS FoundationXML
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
get_swift_host_arch(swift_arch)
install(FILES
  $<TARGET_PROPERTY:FoundationXML,Swift_MODULE_DIRECTORY>/FoundationXML.swiftdoc
  $<TARGET_PROPERTY:FoundationXML,Swift_MODULE_DIRECTORY>/FoundationXML.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
