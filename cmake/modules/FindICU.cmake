# Find libicu's libraries

function(_icu_find)
  set(icu_programs
      gencnval icuinfo genbrk icu-config genrb gendict derb pkgdata uconv gencfu
      makeconf gennorm2 genccode gensprep icupkg gencmn)
  set(icu_data
      Makefile.inc pkgdata.inc)

  # Set up search paths, taking compiler into account.  Search ICU_ROOT, with
  # ICU_ROOT in the environment as a fallback if unset.
  if(ICU_ROOT)
    list(APPEND icu_roots ${ICU_ROOT})
  else()
    if(NOT "$ENV{ICU_ROOT}" STREQUAL "")
      file(TO_CMAKE_PATH "$ENV{ICU_ROOT}" NATIVE_PATH)
      set(ICU_ROOT "${NATIVE_PATH}" CACHE PATH
          "Location of the ICU installation" FORCE)
      list(APPEND icu_roots ${NATIVE_PATH})
    endif()
  endif()

  # Find the include directory.
  list(APPEND icu_include_suffixes "include")
  find_path(ICU_INCLUDE_DIR
            NAMES "unicode/utypes.h"
            HINTS ${icu_roots}
            PATH_SUFFIXES ${icu_include_suffixes}
            DOC "ICU include directory")
  set(ICU_INCLUDE_DIR "${ICU_INCLUDE_DIR}" PARENT_SCOPE)

  # Get the version.
  if(ICU_INCLUDE_DIR AND EXISTS "${ICU_INCLUDE_DIR}/unicode/uvernum.h")
    file(STRINGS "${ICU_INCLUDE_DIR}/unicode/uvernum.h" icu_header_str
         REGEX "^#define[\t ]+U_ICU_VERSION[\t ]+\".*\".*")

    string(REGEX REPLACE "^#define[\t ]+U_ICU_VERSION[\t ]+\"([^ \\n]*)\".*"
          "\\1" icu_version_string "${icu_header_str}")
    set(ICU_VERSION "${icu_version_string}" PARENT_SCOPE)

    unset(icu_header_str)
    unset(icu_version_string)
  endif()

  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_bin64 "bin64")
    set(_lib64 "lib64")
  endif()

  # Find all ICU programs.
  list(APPEND icu_binary_suffixes "${_bin64}" "bin" "sbin")
  foreach(program ${icu_programs})
    string(TOUPPER ${program} program_upcase)
    set(cache_var "ICU_${program_upcase}_EXECUTABLE")
    find_program(${cache_var} ${program}
                 HINTS ${icu_roots}
                 PATH_SUFFIXES ${icu_binary_suffixes}
                 DOC "ICU ${program} executable")
    mark_as_advanced(cache_var)
    set(${cache_var} "${${cache_var}}" PARENT_SCOPE)
  endforeach()

  set(static_prefix )
  if(MSVC)
    set(static_prefix "s")
  endif()

  # Find all ICU libraries.
  list(APPEND icu_library_suffixes "${_lib64}" "lib")
  set(ICU_REQUIRED_LIBS_FOUND YES)
  foreach(component ${ICU_FIND_COMPONENTS})
    string(TOUPPER ${component} component_upcase)

    set(component_cache "ICU_${component_upcase}_LIBRARY")
    set(component_cache_release "${component_cache}_RELEASE")
    set(component_cache_debug "${component_cache}_DEBUG")
    set(component_found "${component_cache}_FOUND")

    unset(component_libnames)
    unset(component_debug_libnames)
    list(APPEND component_libnames "icu${component}")
    list(APPEND component_debug_libnames "icu${component}d")
    if(component STREQUAL data)
      list(APPEND component_libnames icudt)
      list(APPEND component_debug_libnames icudtd)
    elseif(component STREQUAL dt)
      list(APPEND component_libnames icudata)
      list(APPEND component_debug_libnames icudatad)
    elseif(component STREQUAL i18n)
      list(APPEND component_libnames icuin)
      list(APPEND component_debug_libnames icuind)
    elseif(component STREQUAL in)
      list(APPEND component_libnames icui18n)
      list(APPEND component_debug_libnames icui18nd)
    endif()

    if(static_prefix)
      unset(static_component_libnames)
      foreach(component_libname ${component_libnames})
        list(APPEND static_component_libnames
             ${static_prefix}${component_libname})
      endforeach()
      list(APPEND component_libnames ${static_component_libnames})

      unset(static_component_debug_libnames)
      foreach(component_libname ${component_debug_libnames})
        list(APPEND static_component_debug_libnames
             ${static_prefix}${component_libname})
      endforeach()
      list(APPEND component_debug_libnames ${static_component_debug_libnames})
    endif()

    find_library(${component_cache_release} ${component_libnames}
                 HINTS ${icu_roots}
                 PATH_SUFFIXES ${icu_library_suffixes}
                 DOC "ICU ${component} library (release)")
    find_library(${component_cache_debug} ${component_debug_libnames}
                 HINTS ${icu_roots}
                 PATH_SUFFIXES ${icu_library_suffixes}
                 DOC "ICU ${component} library (debug)")

    include(SelectLibraryConfigurations)
    select_library_configurations(ICU_${component_upcase})
    mark_as_advanced(${component_cache_release} ${component_cache_debug})

    if(${component_cache})
      set(${component_found} YES)
      list(APPEND ICU_LIBRARY ${${component_cache}})
    endif()
    mark_as_advanced(${component_found})

    set(${component_cache} "${${component_cache}}" PARENT_SCOPE)
    set(${component_found} "${${component_found}}" PARENT_SCOPE)
    if(${component_found})
      if(ICU_FIND_REQUIRED_${component})
        list(APPEND ICU_LIBS_FOUND "${component} (required)")
      else()
        list(APPEND ICU_LIBS_FOUND "${component} (optional)")
      endif()
    else()
      if(ICU_FIND_REQUIRED_${component})
        list(APPEND ICU_LIBS_NOTFOUND "${component} (required)")
      else()
        list(APPEND ICU_LIBS_NOTFOUND "${component} (optional)")
      endif()
    endif()

    set(_ICU_REQUIRED_LIBS_FOUND "${ICU_REQUIRED_LIBS_FOUND}" PARENT_SCOPE)
    set(ICU_LIBRARY "${ICU_LIBRARY}" PARENT_SCOPE)
  endforeach()

  if(CMAKE_LIBRARY_ARCHITECTURE)
    list(APPEND icu_data_suffixes
         "${_lib64}/${CMAKE_LIBRARY_ARCHITECTURE}/icu/${ICU_VERSION}"
         "lib/${CMAKE_LIBRARY_ARCHITECTURE}/icu/${ICU_VERSION}"
         "${_lib64}/${CMAKE_LIBRARY_ARCHITECTURE}/icu"
         "lib/${CMAKE_LIBRARY_ARCHITECTURE}/icu")
  endif()
  list(APPEND icu_data_suffixes
       "${_lib64}/icu/${ICU_VERSION}"
       "lib/icu/${ICU_VERSION}"
       "${_lib64}/icu"
       "lib/icu")
  foreach(data ${icu_data})
    string(TOUPPER ${data} data_upcase)
    STRING(REPLACE "." "_" data_upcase ${data_upcase})

    set(cache_var ICU_${data_upcase})
    find_file(${cache_Var} ${data}
              HINTS ${icu_roots}
              PATH_SUFFIXES ${icu_data_suffixes}
              DOC "ICU ${data} data file")
    mark_as_advanced(cache_var)
    set(${cache_var} "${${cache_var}}" PARENT_SCOPE)
  endforeach()
endfunction()

_icu_find()
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ICU
                                  FOUND_VAR
                                    ICU_FOUND
                                  REQUIRED_VARS
                                    ICU_INCLUDE_DIR
                                    ICU_LIBRARY
                                    _ICU_REQUIRED_LIBS_FOUND
                                  VERSION_VAR
                                    ICU_VERSION
                                  FAIL_MESSAGE
                                    "Failed to find all ICU components")
unset(_ICU_REQUIRED_LIBS_FOUND)

if(ICU_FOUND)
  set(ICU_INCLUDE_DIRS "${ICU_INCLUDE_DIR}")
  set(ICU_LIBRARIES "${ICU_LIBRARY}")
  foreach(_ICU_component ${ICU_FIND_COMPONENTS})
    string(TOUPPER ${_ICU_component} _ICU_component_upcase)

    set(_ICU_component_cache "ICU_${_ICU_component_upcase}_LIBRARY")
    set(_ICU_component_cache_release "ICU_${_ICU_component_upcase}_LIBRARY_RELEASE")
    set(_ICU_component_cache_debug "ICU_${_ICU_component_upcase}_LIBRARY_DEBUG")
    set(_ICU_component_lib "ICU_${_ICU_component_upcase}_LIBRARIES")
    set(_ICU_component_found "${_ICU_component_upcase}_FOUND")
    set(_ICU_imported_target "ICU::${_ICU_component}")

    if(${_ICU_component_found})
      set(${_ICU_component_lib} "${${_ICU_component_cache}}")
      if(NOT TARGET ${_ICU_imported_target})
        add_library(${_ICU_imported_target} UNKNOWN IMPORTED)
        if(ICU_INCLUDE_DIR)
          set_target_properties(${_ICU_imported_target} PROPERTIES
                                INTERFACE_INCLUDE_DIRECTORIES
                                  ${ICU_INCLUDE_DIR})
        endif()
        if(EXISTS ${${_ICU_component_cache}})
          set_target_properties(${_ICU_imported_target} PROPERTIES
                                IMPORTED_LINK_INTERFACE_LANGUAGES
                                  CXX
                                IMPORTED_LOCATION
                                  ${${_ICU_component_cache}})
        endif()
        if(EXISTS ${${_ICU_component_cache_release}})
          set_property(TARGET ${_ICU_imported_target} APPEND PROPERTY
                       IMPORTED_CONFIGURATIONS
                         RELEASE)
          set_target_properties(${_ICU_imported_target} PROPERTIES
                                IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE
                                  CXX
                                IMPORTED_LOCATION_RELEASE
                                  ${${_ICU_component_cache_release}})
        endif()
        if(EXISTS ${${_ICU_component_cache_debug}})
          set_property(TARGET ${_ICU_imported_target} APPEND PROPERTY
                       IMPORTED_CONFIGURATIONS
                         DEBUG)
          set_target_properties(${_ICU_imported_target} PROPERTIES
                                IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG
                                  CXX
                                IMPORTED_LOCATION_DEBUG
                                  ${${_ICU_component_cache_debug}})
        endif()
      endif()
    endif()

    unset(_ICU_imported_target)
    unset(_ICU_component_found)
    unset(_ICU_component_lib)
    unset(_ICU_component_cache_debug)
    unset(_ICU_component_cache_release)
    unset(_ICU_component_cache)
  endforeach()
endif()

