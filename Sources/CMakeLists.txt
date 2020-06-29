add_subdirectory(UUID)
add_subdirectory(Foundation)
add_subdirectory(FoundationXML)

if(NOT CMAKE_SYSTEM_NAME STREQUAL WASI)
  add_subdirectory(FoundationNetworking)
  add_subdirectory(Tools)
endif()