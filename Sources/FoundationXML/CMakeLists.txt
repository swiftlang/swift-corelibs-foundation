add_library(FoundationXML
  XMLDocument.swift
  XMLDTD.swift
  XMLDTDNode.swift
  XMLElement.swift
  XMLNode.swift
  XMLParser.swift
  CFAccess.swift)
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

if(NOT CMAKE_SYSTEM_NAME MATCHES "Darwin|Windows")
  target_link_options(FoundationXML PRIVATE "SHELL:-no-toolchain-stdlib-rpath")
endif()


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS FoundationXML)
_install_target(FoundationXML)
