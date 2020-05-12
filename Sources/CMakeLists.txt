add_subdirectory(UUID)
add_subdirectory(Foundation)
add_subdirectory(FoundationXML)

if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL wasm32)
  add_subdirectory(FoundationNetworking)
  add_subdirectory(Tools)
endif()