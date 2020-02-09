add_executable(xdgTestHelper
  main.swift)
target_link_libraries(xdgTestHelper PRIVATE
  Foundation
  FoundationNetworking
  FoundationXML)

if(CMAKE_VERSION VERSION_LESS 3.16)
  if(NOT CMAKE_SYSTEM_NAME STREQUAL Windows AND NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
    target_link_options(xdgTestHelper PRIVATE
      "SHELL:-Xlinker -rpath -Xlinker $<TARGET_FILE_DIR:swiftDispatch>"
      "SHELL:-Xlinker -rpath -Xlinker $<TARGET_FILE_DIR:Foundation>")
  endif()
endif()
