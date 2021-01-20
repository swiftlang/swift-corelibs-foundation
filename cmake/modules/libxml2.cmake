# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(LIBXML2_TARGET external.libxml2)
set(LIBXML2_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${LIBXML2_TARGET})
set(LIBXML2_SRC_DIR ${LIBXML2_INSTALL_DIR}/src/${LIBXML2_TARGET})

list(APPEND LIBXML2_LIBRARIES xml2)

foreach(lib IN LISTS LIBXML2_LIBRARIES)
  list(APPEND LIBXML2_BUILD_BYPRODUCTS ${LIBXML2_INSTALL_DIR}/lib/lib${lib}.a)

  add_library(${lib} STATIC IMPORTED)
  set_property(TARGET ${lib} PROPERTY IMPORTED_LOCATION
               ${LIBXML2_INSTALL_DIR}/lib/lib${lib}.a)
  add_dependencies(${lib} ${LIBXML2_TARGET})
endforeach(lib)

include (ExternalProject)
ExternalProject_Add(${LIBXML2_TARGET}
    PREFIX ${LIBXML2_TARGET}
    GIT_REPOSITORY GIT_REPOSITORY https://gitlab.gnome.org/GNOME/libxml2
    GIT_TAG 79301d3d5e553d46fc3201f48dcec3a93068c5a2
    UPDATE_COMMAND ""
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS ${LIBXML2_BUILD_BYPRODUCTS}
)

ExternalProject_Get_property(${LIBXML2_TARGET} BINARY_DIR)

set(LIBXML2_INCLUDE_DIRS 
  "${LIBXML2_SRC_DIR}/include" 
  "${LIBXML2_INSTALL_DIR}/include/libxml2"
  "${BINARY_DIR}")