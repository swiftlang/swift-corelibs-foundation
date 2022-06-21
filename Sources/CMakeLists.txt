add_subdirectory(UUID)
add_subdirectory(Foundation)
add_subdirectory(FoundationNetworking)
add_subdirectory(FoundationXML)

if(BUILD_TOOLS)
  add_subdirectory(Tools)
endif()
