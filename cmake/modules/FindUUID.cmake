#.rst
# FindUUID
# --------
#
# Find libuuid library and headers
#
# The module defines the following variables:
#
# ::
#
#   uuid_FOUND        - true if libuuid was found
#   uuid_INCLUDE_DIRS - include search path
#   uuid_LIBRARIES    - libraries to link

if(uuid_INCLUDE_DIRS AND uuid_LIBRARIES)
  set(uuid_FOUND TRUE)
else()
  find_package(PkgConfig QUIET)
  pkg_check_modules(PC_UUID QUIET uuid)

  find_path(uuid_INCLUDE_DIRS
            NAMES
              uuid.h
              uuid/uuid.h
            HINTS
              ${PC_UUID_INCLUDEDIR}
              ${PC_UUID_INCLUDE_DIRS}
              ${CMAKE_INSTALL_FULL_INCLUDEDIR})
  if(NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
    find_library(uuid_LIBRARIES
                 NAMES
                   uuid
                 HINTS
                   ${PC_UUID_LIBDIR}
                   ${PC_UUID_LIBRARY_DIRS}
                   ${CMAKE_INSTALL_FULL_LIBDIR})
  endif()

  include(FindPackageHandleStandardArgs)
  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    find_package_handle_standard_args(uuid
                                      REQUIRED_VARS
                                        uuid_INCLUDE_DIRS)
  else()
    find_package_handle_standard_args(uuid
                                      REQUIRED_VARS
                                        uuid_INCLUDE_DIRS
                                        uuid_LIBRARIES)
  endif()
  mark_as_advanced(uuid_INCLUDE_DIRS uuid_LIBRARIES)
endif()

