
cmake_minimum_required(VERSION 3.14.20190522)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

# NOTE(compnerd) enable CMP0091 - select MSVC runtime based on
# CMAKE_MSVC_RUNTIME_LIBRARY.  Requires CMake 3.15 or newer
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

project(Foundation LANGUAGES Swift C)

# NOTE(compnerd) default to /MD or /MDd by default based on the configuration.
# Cache the variable to allow the user to alter the configuration.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE
  STRING "MSVC Runtime Library")

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

option(BUILD_SHARED_LIBS "build shared libraries" ON)

option(ENABLE_TESTING "enable testing" YES)
if(ENABLE_TESTING)
  enable_testing()
endif()

option(FOUNDATION_ENABLE_LIBDISPATCH "Enable GCD Support" YES)

# FIXME(compnerd) these can go away with export targts
option(FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE "Path to libdispatch source" "")
option(FOUNDATION_PATH_TO_LIBDISPATCH_BUILD "Path to libdispatch build" "")

# FIXME(compnerd) this can go away with export targets
option(FOUNDATION_PATH_TO_XCTEST_BUILD "Path to XCTest build" "")

find_package(CURL REQUIRED)
find_package(ICU COMPONENTS uc i18n REQUIRED)
find_package(LibXml2 REQUIRED)

include(SwiftSupport)
include(GNUInstallDirs)

if(CMAKE_SYSTEM_NAME STREQUAL Linux)
  include(CheckSymbolExists)
  include(CheckIncludeFile)

  list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)

  check_include_file("sched.h" HAVE_SCHED_H)
  check_symbol_exists(sched_getaffinity "sched.h" HAVE_SCHED_GETAFFINITY)
endif()

get_swift_host_arch(swift_arch)

# FIXME(compnerd) these two can go away with export targets
set(CF_PATH_TO_LIBDISPATCH_SOURCE ${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE} CACHE PATH "Path to libdispatch source" FORCE)
set(CF_PATH_TO_LIBDISPATCH_BUILD ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD} CACHE PATH "Path to libdispatch build" FORCE)

set(CF_DEPLOYMENT_SWIFT YES CACHE BOOL "Build for Swift" FORCE)

set(SAVED_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS NO)
add_subdirectory(CoreFoundation)
set(BUILD_SHARED_LIBS ${SAVED_BUILD_SHARED_LIBS})

add_subdirectory(uuid)

if(FOUNDATION_ENABLE_LIBDISPATCH)
  if(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
    list(APPEND libdispatch_ldflags -Xlinker;-rpath;-Xlinker;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src)
  endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL Linux)
  set(Foundation_RPATH -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN")
  set(XDG_TEST_HELPER_RPATH -Xlinker;-rpath;-Xlinker;${CMAKE_CURRENT_BINARY_DIR})
elseif(CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  set(Foundation_RPATH -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN")
  set(XDG_TEST_HELPER_RPATH -Xlinker;-rpath;-Xlinker;${CMAKE_CURRENT_BINARY_DIR})
elseif(CMAKE_SYSTEM_NAME STREQUAL Windows)
  # FIXME(SR9138) Silence "locally defined symbol '…' imported in function '…'
  set(WORKAROUND_SR9138 -Xlinker;-ignore:4049;-Xlinker;-ignore:4217)
endif()

add_subdirectory(Foundation)
add_subdirectory(Tools)

if(ENABLE_TESTING)
  add_subdirectory(TestFoundation)
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
