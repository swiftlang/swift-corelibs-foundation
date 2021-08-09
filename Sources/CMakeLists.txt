add_subdirectory(UUID)
add_subdirectory(Foundation)
add_subdirectory(FoundationXML)

if(BUILD_NETWORKING)
  add_subdirectory(FoundationNetworking)
endif()

if(BUILD_TOOLS)
  add_subdirectory(Tools)
endif()
