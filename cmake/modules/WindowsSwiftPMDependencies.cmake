##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift open source project
##
## Copyright (c) 2025 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.md for the list of Swift project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

# Builds Windows CMake dependencies for a SwiftPM build (zlib, libxml, and curl)
function(_foundation_setup_windows_swiftpm_dependencies_target)

  message(STATUS "Configuring Windows SwiftPM dependencies target")

  if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
  	message(FATAL_ERROR "Windows SwiftPM dependencies is only allowed on Windows hosts. Building on Linux does not require pre-building dependencies via CMake.")
  endif()

  include(ExternalProject)

  set(DEST_DIR "${CMAKE_BINARY_DIR}/windows-deps")

  ExternalProject_Add(zlib
    GIT_REPOSITORY    https://github.com/madler/zlib.git
    GIT_TAG           v1.3.1
    CMAKE_ARGS		   
      -DCMAKE_INSTALL_PREFIX=${DEST_DIR}/zlib
      -DCMAKE_C_COMPILER=cl
      -DBUILD_SHARED_LIBS=NO
      -DCMAKE_POSITION_INDEPENDENT_CODE=YES
      -DCMAKE_BUILD_TYPE=Release
    EXCLUDE_FROM_ALL  YES
  )

  ExternalProject_Add(brotli
    GIT_REPOSITORY    https://github.com/google/brotli
    GIT_TAG           v1.1.0
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${DEST_DIR}/brotli
      -DCMAKE_C_COMPILER=cl
      -DBUILD_SHARED_LIBS=NO
      -DCMAKE_POSITION_INDEPENDENT_CODE=YES
      -DCMAKE_BUILD_TYPE=Release
    EXCLUDE_FROM_ALL  YES
  )

  ExternalProject_Add(libxml
    GIT_REPOSITORY    https://github.com/gnome/libxml2.git
    GIT_TAG           v2.11.5
    CMAKE_ARGS		    
      -DCMAKE_INSTALL_PREFIX=${DEST_DIR}/libxml
      -DCMAKE_C_COMPILER=cl
      -DBUILD_SHARED_LIBS=NO
      -DLIBXML2_WITH_ICONV=NO
      -DLIBXML2_WITH_ICU=NO
      -DLIBXML2_WITH_LZMA=NO
      -DLIBXML2_WITH_PYTHON=NO
      -DLIBXML2_WITH_TESTS=NO
      -DLIBXML2_WITH_THREADS=YES
      -DLIBXML2_WITH_ZLIB=NO
      -DCMAKE_BUILD_TYPE=Release
    EXCLUDE_FROM_ALL  YES
  )

  set(ZLIB_ROOT "${DEST_DIR}/zlib")
  set(ZLIB_LIBRARY_DIR "${ZLIB_ROOT}/lib")
  set(ZLIB_INCLUDE_DIR "${ZLIB_ROOT}/include")
  set(ZLIB_LIBRARY_PATH "${ZLIB_LIBRARY_DIR}/zlibstatic.lib")

  # Add a custom target for zlib's install step that curl can depend on
  ExternalProject_Add_StepTargets(zlib install)

  set(BROTLI_ROOT "${DEST_DIR}/brotli")
  set(BROTLI_LIBRARY_DIR "${BROTLI_ROOT}/lib")
  set(BROTLI_INCLUDE_DIR "${BROTLI_ROOT}/include")
  set(BROTLICOMMON_LIBRARY_PATH "${BROTLI_LIBRARY_DIR}/brotlicommon.lib")
  set(BROTLIDEC_LIBRARY_PATH "${BROTLI_LIBRARY_DIR}/brotlidec.lib")

  # Add a custom target for brotli's install step that curl can depend on
  ExternalProject_Add_StepTargets(brotli install)

  ExternalProject_Add(curl
    GIT_REPOSITORY    https://github.com/curl/curl.git
    GIT_TAG           curl-8_9_1
    CMAKE_ARGS		    
      -DCMAKE_INSTALL_PREFIX=${DEST_DIR}/curl
      -DCMAKE_C_COMPILER=cl
      -DBUILD_SHARED_LIBS=NO
      -DBUILD_TESTING=NO
      -DBUILD_CURL_EXE=NO
      -DCURL_CA_BUNDLE=none
      -DCURL_CA_FALLBACK=NO
      -DCURL_CA_PATH=none
      -DCURL_BROTLI=YES
      -DCURL_DISABLE_ALTSVC=NO
      -DCURL_DISABLE_AWS=YES
      -DCURL_DISABLE_BASIC_AUTH=NO
      -DCURL_DISABLE_BEARER_AUTH=NO
      -DCURL_DISABLE_COOKIES=NO
      -DCURL_DISABLE_DICT=YES
      -DCURL_DISABLE_DIGEST_AUTH=NO
      -DCURL_DISABLE_DOH=NO
      -DCURL_DISABLE_FILE=YES
      -DCURL_DISABLE_FORM_API=NO
      -DCURL_DISABLE_FTP=YES
      -DCURL_DISABLE_GETOPTIONS=NO
      -DCURL_DISABLE_GOPHER=YES
      -DCURL_DISABLE_HSTS=NO
      -DCURL_DISABLE_HTTP=NO
      -DCURL_DISABLE_HTTP_AUTH=NO
      -DCURL_DISABLE_IMAP=YES
      -DCURL_DISABLE_KERBEROS_AUTH=NO
      -DCURL_DISABLE_LDAP=YES
      -DCURL_DISABLE_LDAPS=YES
      -DCURL_DISABLE_MIME=NO
      -DCURL_DISABLE_MQTT=YES
      -DCURL_DISABLE_NEGOTIATE_AUTH=NO
      -DCURL_DISABLE_NETRC=NO
      -DCURL_DISABLE_NTLM=NO
      -DCURL_DISABLE_PARSEDATE=NO
      -DCURL_DISABLE_POP3=YES
      -DCURL_DISABLE_PROGRESS_METER=YES
      -DCURL_DISABLE_PROXY=NO
      -DCURL_DISABLE_RTSP=YES
      -DCURL_DISABLE_SHUFFLE_DNS=YES
      -DCURL_DISABLE_SMB=YES
      -DCURL_DISABLE_SMTP=YES
      -DCURL_DISABLE_SOCKETPAIR=YES
      -DCURL_DISABLE_SRP=NO
      -DCURL_DISABLE_TELNET=YES
      -DCURL_DISABLE_TFTP=YES
      -DCURL_DISABLE_VERBOSE_STRINGS=NO
      -DCURL_LTO=NO
      -DCURL_USE_BEARSSL=NO
      -DCURL_USE_GNUTLS=NO
      -DCURL_USE_GSSAPI=NO
      -DCURL_USE_LIBPSL=NO
      -DCURL_USE_LIBSSH=NO
      -DCURL_USE_LIBSSH2=NO
      -DCURL_USE_MBEDTLS=NO
      -DCURL_USE_OPENSSL=NO
      -DCURL_USE_SCHANNEL=YES
      -DCURL_USE_WOLFSSL=NO
      -DCURL_WINDOWS_SSPI=YES
      -DCURL_ZLIB=YES
      -DCURL_ZSTD=NO
      -DENABLE_ARES=NO
      -DENABLE_CURLDEBUG=NO
      -DENABLE_DEBUG=NO
      -DENABLE_IPV6=YES
      -DENABLE_MANUAL=NO
      -DENABLE_THREADED_RESOLVER=NO
      -DENABLE_UNICODE=YES
      -DENABLE_UNIX_SOCKETS=NO
      -DENABLE_WEBSOCKETS=YES
      -DHAVE_POLL_FINE=NO
      -DUSE_IDN2=NO
      -DUSE_MSH3=NO
      -DUSE_NGHTTP2=NO
      -DUSE_NGTCP2=NO
      -DUSE_QUICHE=NO
      -DUSE_WIN32_IDN=YES
      -DUSE_WIN32_LARGE_FILES=YES
      -DUSE_WIN32_LDAP=NO
      -DCMAKE_BUILD_TYPE=Release
      -DZLIB_ROOT=${ZLIB_ROOT}
      -DZLIB_LIBRARY=${ZLIB_LIBRARY_PATH}
      -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
      -DBROTLIDEC_LIBRARY=${BROTLIDEC_LIBRARY_PATH}
      -DBROTLICOMMON_LIBRARY=${BROTLICOMMON_LIBRARY_PATH}
      -DBROTLI_INCLUDE_DIR=${BROTLI_INCLUDE_DIR}
    DEPENDS           zlib-install brotli-install
    EXCLUDE_FROM_ALL  YES
  )


  set(LIBXML_LIBRARY_DIR "${DEST_DIR}/libxml/lib")
  set(LIBXML_INCLUDE_DIR "${DEST_DIR}/libxml/include/libxml2")

  set(CURL_LIBRARY_DIR "${DEST_DIR}/curl/lib")
  set(CURL_INCLUDE_DIR "${DEST_DIR}/curl/include")

  message(STATUS "LIBXML_INCLUDE_PATH=${LIBXML_INCLUDE_DIR}")
  message(STATUS "LIBXML_LIBRARY_PATH=${LIBXML_LIBRARY_DIR}")
  message(STATUS "CURL_INCLUDE_PATH=${CURL_INCLUDE_DIR}")
  message(STATUS "CURL_LIBRARY_PATH=${CURL_LIBRARY_DIR}")
  message(STATUS "ZLIB_LIBRARY_PATH=${ZLIB_LIBRARY_DIR}")
  message(STATUS "BROTLI_LIBRARY_PATH=${BROTLI_LIBRARY_DIR}")

  ExternalProject_Add_StepTargets(libxml install)
  ExternalProject_Add_StepTargets(curl install)
  add_custom_target(WindowsSwiftPMDependencies
    DEPENDS libxml-install curl-install)

  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo Please set the following environment variables for the SwiftPM build:)
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo:)
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo LIBXML_INCLUDE_PATH=${LIBXML_INCLUDE_DIR})
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo LIBXML_LIBRARY_PATH=${LIBXML_LIBRARY_DIR})
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo CURL_INCLUDE_PATH=${CURL_INCLUDE_DIR})
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo CURL_LIBRARY_PATH=${CURL_LIBRARY_DIR})
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo ZLIB_LIBRARY_PATH=${ZLIB_LIBRARY_DIR})
  add_custom_command(TARGET WindowsSwiftPMDependencies POST_BUILD
    COMMAND echo BROTLI_LIBRARY_PATH=${BROTLI_LIBRARY_DIR})

endfunction()
