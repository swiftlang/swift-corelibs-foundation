
include(CMakeParseArguments)

function(add_framework NAME)
  set(options STATIC SHARED)
  set(single_value_args MODULE_MAP FRAMEWORK_DIRECTORY)
  set(multiple_value_args PRIVATE_HEADERS PUBLIC_HEADERS SOURCES)
  cmake_parse_arguments(AF "${options}" "${single_value_args}" "${multiple_value_args}" ${ARGN})

  set(AF_TYPE)
  if(AF_STATIC)
    set(AF_TYPE STATIC)
  elseif(AF_SHARED)
    set(AF_TYPE SHARED)
  endif()

  if(AF_MODULE_MAP)
    file(COPY
           ${AF_MODULE_MAP}
         DESTINATION
           ${CMAKE_BINARY_DIR}/${NAME}.framework/Modules
         NO_SOURCE_PERMISSIONS)
  endif()
  if(AF_PUBLIC_HEADERS)
    file(COPY
           ${AF_PUBLIC_HEADERS}
         DESTINATION
           ${CMAKE_BINARY_DIR}/${NAME}.framework/Headers
         NO_SOURCE_PERMISSIONS)
  endif()
  if(AF_PRIVATE_HEADERS)
    file(COPY
           ${AF_PRIVATE_HEADERS}
         DESTINATION
           ${CMAKE_BINARY_DIR}/${NAME}.framework/PrivateHeaders
         NO_SOURCE_PERMISSIONS)
  endif()
  add_custom_target(${NAME}_POPULATE_HEADERS
                    DEPENDS
                      ${AF_MODULE_MAP}
                      ${AF_PUBLIC_HEADERS}
                      ${AF_PRIVATE_HEADERS}
                    SOURCES
                      ${AF_MODULE_MAP}
                      ${AF_PUBLIC_HEADERS}
                      ${AF_PRIVATE_HEADERS})

  add_library(${NAME}
              ${AF_TYPE}
              ${AF_SOURCES})
  set_target_properties(${NAME}
                        PROPERTIES
                          LIBRARY_OUTPUT_DIRECTORY
                              ${CMAKE_BINARY_DIR}/${NAME}.framework)
  if("${CMAKE_C_SIMULATE_ID}" STREQUAL "MSVC")
    target_compile_options(${NAME}
                           PRIVATE
                             -Xclang;-F${CMAKE_BINARY_DIR})
  else()
    target_compile_options(${NAME}
                           PRIVATE
                             -F;${CMAKE_BINARY_DIR})
  endif()
  target_compile_options(${NAME}
                         PRIVATE
                           -I;${CMAKE_BINARY_DIR}/${NAME}.framework/PrivateHeaders)
  add_dependencies(${NAME} ${NAME}_POPULATE_HEADERS)

  if(AF_FRAMEWORK_DIRECTORY)
    set(${AF_FRAMEWORK_DIRECTORY} ${CMAKE_BINARY_DIR}/${NAME}.framework PARENT_SCOPE)
  endif()
endfunction()

