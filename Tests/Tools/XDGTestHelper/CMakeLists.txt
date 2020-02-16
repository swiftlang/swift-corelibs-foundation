add_executable(xdgTestHelper
  main.swift)
target_link_libraries(xdgTestHelper PRIVATE
  Foundation
  FoundationNetworking
  FoundationXML)
set_target_properties(xdgTestHelper PROPERTIES
  BUILD_RPATH "$<TARGET_FILE_DIR:swiftDispatch>;$<TARGET_FILE_DIR:Foundation>;$<TARGET_FILE_DIR:FoundationNetworking>;$<TARGET_FILE_DIR:FoundationXML>")
if(NOT CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_options(xdgTestHelper PRIVATE
    "SHELL:-Xlinker -rpath -Xlinker $<TARGET_FILE_DIR:swiftDispatch>:$<TARGET_FILE_DIR:Foundation>:$<TARGET_FILE_DIR:FoundationNetworking>:$<TARGET_FILE_DIR:FoundationXML>")
endif()
