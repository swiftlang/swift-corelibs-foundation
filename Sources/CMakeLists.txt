add_subdirectory(UUID)
add_subdirectory(Foundation)

if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL wasm32)
  add_subdirectory(FoundationNetworking)
  add_subdirectory(FoundationXML)
  add_subdirectory(Tools)
endif()