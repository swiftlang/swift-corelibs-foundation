
cmake_minimum_required(VERSION 3.15.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

# NOTE(compnerd) enable CMP0091 - select MSVC runtime based on
# CMAKE_MSVC_RUNTIME_LIBRARY.  Requires CMake 3.15 or newer
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

project(Foundation
  LANGUAGES C Swift)
enable_testing()

# NOTE(compnerd) default to /MD or /MDd by default based on the configuration.
# Cache the variable to allow the user to alter the configuration.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE
  STRING "MSVC Runtime Library")

if(CMAKE_VERSION VERSION_LESS 3.16.0)
  if(NOT (CMAKE_SYSTEM_NAME STREQUAL Windows OR CMAKE_SYSTEM_NAME STREQUAL Darwin))
    set(CMAKE_SHARED_LIBRARY_RUNTIME_Swift_FLAG "-Xlinker -rpath -Xlinker ")
    set(CMAKE_SHARED_LIBRARY_RUNTIME_Swift_FLAG_SEP ":")
  endif()
  # Workaround for CMake 3.15 which doesn't link libraries properly on Windows
  set(CMAKE_LINK_LIBRARY_FLAG "-l")
endif()

option(BUILD_SHARED_LIBS "build shared libraries" ON)

find_package(dispatch CONFIG REQUIRED)

include(SwiftSupport)
include(GNUInstallDirs)
include(XCTest)

set(CF_DEPLOYMENT_SWIFT YES CACHE BOOL "Build for Swift" FORCE)

set(SAVED_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS NO)
add_subdirectory(CoreFoundation EXCLUDE_FROM_ALL)
set(BUILD_SHARED_LIBS ${SAVED_BUILD_SHARED_LIBS})

# Setup include paths for uuid/uuid.h
target_include_directories(CoreFoundation PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}/CoreFoundation.framework/Headers)

add_subdirectory(Sources)
if(ENABLE_TESTING)
  find_package(XCTest CONFIG REQUIRED)
  add_subdirectory(Tests)
endif()

if(NOT BUILD_SHARED_LIBS)
  set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS
    CoreFoundation CFXMLInterface CFURLSessionInterface)
  install(TARGETS CoreFoundation CFXMLInterface CFURLSessionInterface
    DESTINATION lib/swift_static/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>)
endif()
# TODO(compnerd) install as a Framework as that is how swift actually is built
install(DIRECTORY
          ${CMAKE_CURRENT_BINARY_DIR}/CoreFoundation.framework/Headers/
        DESTINATION
          lib/swift/CoreFoundation
        FILES_MATCHING PATTERN "*.h")
install(FILES
          CoreFoundation/Base.subproj/module.map
        DESTINATION
          lib/swift/CoreFoundation)
install(DIRECTORY
          ${CMAKE_CURRENT_BINARY_DIR}/CFURLSessionInterface.framework/Headers/
        DESTINATION
          lib/swift/CFURLSessionInterface
        FILES_MATCHING PATTERN "*.h")
install(FILES
          CoreFoundation/URL.subproj/module.map
        DESTINATION
          lib/swift/CFURLSessionInterface)
install(DIRECTORY
          ${CMAKE_CURRENT_BINARY_DIR}/CFXMLInterface.framework/Headers/
        DESTINATION
          lib/swift/CFXMLInterface
        FILES_MATCHING PATTERN "*.h")
install(FILES
          CoreFoundation/Parsing.subproj/module.map
        DESTINATION
          lib/swift/CFXMLInterface)

add_subdirectory(cmake/modules)
