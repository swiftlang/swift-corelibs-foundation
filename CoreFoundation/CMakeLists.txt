
cmake_minimum_required(VERSION 3.4.3)
list(APPEND CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

project(CoreFoundation
        VERSION
          1338
        LANGUAGES
          ASM C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED YES)

# TODO(compnerd): this should be re-enabled once CoreFoundation annotations have
# been reconciled.  Hidden visibility should ensure that internal interfaces are
# not accidentally exposed on platforms without exports lists and explicit
# annotations (i.e. ELFish and MachO targets).
if(0)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_C_VISIBILITY_INLINES_HIDDEN ON)
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE YES)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG ON)
if(CMAKE_VERSION VERSION_LESS 3.10)
  if(CMAKE_CROSSCOMPILING)
    if(NOT CMAKE_C_COMPILER_ID MATCHES Clang OR CMAKE_C_SIMULATE_ID STREQUAL MSVC)
      set(THREADS_HAVE_PTHREAD_ARG FALSE)
    else()
      set(THREADS_HAVE_PTHREAD_ARG TRUE)
    endif()
  endif()
endif()
find_package(Threads)

include(GNUInstallDirs)
include(CoreFoundationAddFramework)

option(CF_ENABLE_LIBDISPATCH "Enable GCD Support" YES)
option(CF_PATH_TO_LIBDISPATCH_SOURCE "Path to libdispatch source")
option(CF_PATH_TO_LIBDISPATCH_BUILD "Path to libdispatch build")
option(CF_DEPLOYMENT_SWIFT "Build for swift" NO)

if(BUILD_SHARED_LIBS)
  set(FRAMEWORK_LIBRARY_TYPE SHARED)
else()
  set(FRAMEWORK_LIBRARY_TYPE STATIC)
endif()

add_framework(CoreFoundation
                ${FRAMEWORK_LIBRARY_TYPE}
              FRAMEWORK_DIRECTORY
                CoreFoundation_FRAMEWORK_DIRECTORY
              MODULE_MAP
                Base.subproj/module.modulemap
              PRIVATE_HEADERS
                # Base
                Base.subproj/CFAsmMacros.h
                Base.subproj/CFInternal.h
                Base.subproj/CFKnownLocations.h
                Base.subproj/CFLogUtilities.h
                Base.subproj/CFPriv.h
                Base.subproj/CFOverflow.h
                Base.subproj/CFRuntime.h
                Base.subproj/CFRuntime_Internal.h
                Base.subproj/ForFoundationOnly.h
                Base.subproj/ForSwiftFoundationOnly.h
                # Collections
                Collections.subproj/CFBasicHash.h
                Collections.subproj/CFStorage.h
                Collections.subproj/CFCollections_Internal.h
                # Error
                Error.subproj/CFError_Private.h
                # Locale
                Locale.subproj/CFCalendar_Internal.h
                Locale.subproj/CFDateComponents.h
                Locale.subproj/CFDateFormatter_Private.h
                Locale.subproj/CFDateInterval.h
                Locale.subproj/CFICULogging.h
                Locale.subproj/CFLocaleInternal.h
                Locale.subproj/CFLocale_Private.h
                # NumberDate
                NumberDate.subproj/CFBigNumber.h
                # Parsing
                Parsing.subproj/CFPropertyList_Private.h
                Parsing.subproj/CFXMLInputStream.h
                Parsing.subproj/CFXMLInterface.h
                # PlugIn
                PlugIn.subproj/CFBundlePriv.h
                PlugIn.subproj/CFBundle_BinaryTypes.h
                PlugIn.subproj/CFBundle_Internal.h
                PlugIn.subproj/CFPlugIn_Factory.h
                # RunLoop
                RunLoop.subproj/CFMachPort_Internal.h
                RunLoop.subproj/CFMachPort_Lifetime.h
                # Stream
                Stream.subproj/CFStreamAbstract.h
                Stream.subproj/CFStreamInternal.h
                Stream.subproj/CFStreamPriv.h
                # String
                String.subproj/CFAttributedStringPriv.h
                String.subproj/CFBurstTrie.h
                String.subproj/CFCharacterSetPriv.h
                String.subproj/CFRegularExpression.h
                String.subproj/CFRunArray.h
                String.subproj/CFString_Internal.h
                String.subproj/CFStringDefaultEncoding.h
                String.subproj/CFStringLocalizedFormattingInternal.h
                # StringEncodings
                StringEncodings.subproj/CFICUConverters.h
                StringEncodings.subproj/CFStringEncodingConverter.h
                StringEncodings.subproj/CFStringEncodingConverterExt.h
                StringEncodings.subproj/CFStringEncodingConverterPriv.h
                StringEncodings.subproj/CFStringEncodingDatabase.h
                StringEncodings.subproj/CFUniChar.h
                StringEncodings.subproj/CFUniCharPriv.h
                StringEncodings.subproj/CFUnicodeDecomposition.h
                StringEncodings.subproj/CFUnicodePrecomposition.h
                # URL
                URL.subproj/CFURL.inc.h
                URL.subproj/CFURLPriv.h
                URL.subproj/CFURLSessionInterface.h
              PUBLIC_HEADERS
                # FIXME: PrivateHeaders referenced by public headers
                Base.subproj/CFKnownLocations.h
                Base.subproj/CFLogUtilities.h
                Base.subproj/CFPriv.h
                Base.subproj/CFRuntime.h
                Base.subproj/ForFoundationOnly.h
                Base.subproj/ForSwiftFoundationOnly.h
                Locale.subproj/CFCalendar_Internal.h
                Locale.subproj/CFDateComponents.h
                Locale.subproj/CFDateInterval.h
                Locale.subproj/CFLocaleInternal.h
                Parsing.subproj/CFXMLInterface.h
                PlugIn.subproj/CFBundlePriv.h
                Stream.subproj/CFStreamPriv.h
                String.subproj/CFRegularExpression.h
                String.subproj/CFRunArray.h
                StringEncodings.subproj/CFStringEncodingConverter.h
                StringEncodings.subproj/CFStringEncodingConverterExt.h
                URL.subproj/CFURLPriv.h
                URL.subproj/CFURLSessionInterface.h

                # AppServices
                AppServices.subproj/CFNotificationCenter.h
                AppServices.subproj/CFUserNotification.h
                # Base
                Base.subproj/CFAvailability.h
                Base.subproj/CFBase.h
                Base.subproj/CFByteOrder.h
                Base.subproj/CFUUID.h
                Base.subproj/CFUtilities.h
                Base.subproj/SwiftRuntime/CoreFoundation.h
                Base.subproj/SwiftRuntime/TargetConditionals.h
                # Collections
                Collections.subproj/CFArray.h
                Collections.subproj/CFBag.h
                Collections.subproj/CFBinaryHeap.h
                Collections.subproj/CFBitVector.h
                Collections.subproj/CFData.h
                Collections.subproj/CFDictionary.h
                Collections.subproj/CFSet.h
                Collections.subproj/CFTree.h
                # Error
                Error.subproj/CFError.h
                # Locale
                Locale.subproj/CFCalendar.h
                Locale.subproj/CFDateFormatter.h
                Locale.subproj/CFLocale.h
                Locale.subproj/CFNumberFormatter.h
                # NumberDate
                NumberDate.subproj/CFDate.h
                NumberDate.subproj/CFNumber.h
                NumberDate.subproj/CFTimeZone.h
                # Parsing
                Parsing.subproj/CFPropertyList.h
                Parsing.subproj/CFXMLNode.h
                Parsing.subproj/CFXMLParser.h
                # PlugIn
                PlugIn.subproj/CFBundle.h
                PlugIn.subproj/CFPlugIn.h
                PlugIn.subproj/CFPlugInCOM.h
                # Preferences
                Preferences.subproj/CFPreferences.h
                # RunLoop
                RunLoop.subproj/CFMachPort.h
                RunLoop.subproj/CFMessagePort.h
                RunLoop.subproj/CFRunLoop.h
                RunLoop.subproj/CFSocket.h
                # Stream
                Stream.subproj/CFStream.h
                # String
                String.subproj/CFAttributedString.h
                String.subproj/CFCharacterSet.h
                String.subproj/CFString.h
                String.subproj/CFStringEncodingExt.h
                # URL
                URL.subproj/CFURL.h
                URL.subproj/CFURLAccess.h
                URL.subproj/CFURLComponents.h
              SOURCES
                # Base
                Base.subproj/CFBase.c
                Base.subproj/CFFileUtilities.c
                Base.subproj/CFKnownLocations.c
                Base.subproj/CFPlatform.c
                Base.subproj/CFRuntime.c
                Base.subproj/CFSortFunctions.c
                Base.subproj/CFSystemDirectories.c
                Base.subproj/CFUtilities.c
                Base.subproj/CFUUID.c
                Base.subproj/CFWindowsUtilities.c
                # Collections
                Collections.subproj/CFArray.c
                Collections.subproj/CFBag.c
                Collections.subproj/CFBasicHash.c
                Collections.subproj/CFBinaryHeap.c
                Collections.subproj/CFBitVector.c
                Collections.subproj/CFData.c
                Collections.subproj/CFDictionary.c
                Collections.subproj/CFSet.c
                Collections.subproj/CFStorage.c
                Collections.subproj/CFTree.c
                # Error
                Error.subproj/CFError.c
                # Locale
                Locale.subproj/CFCalendar.c
                Locale.subproj/CFCalendar_Enumerate.c
                Locale.subproj/CFDateComponents.c
                Locale.subproj/CFDateFormatter.c
                Locale.subproj/CFDateInterval.c
                Locale.subproj/CFLocale.c
                Locale.subproj/CFLocaleIdentifier.c
                Locale.subproj/CFLocaleKeys.c
                Locale.subproj/CFNumberFormatter.c
                # NumberData
                NumberDate.subproj/CFBigNumber.c
                NumberDate.subproj/CFDate.c
                NumberDate.subproj/CFNumber.c
                NumberDate.subproj/CFTimeZone.c
                # Parsing
                Parsing.subproj/CFBinaryPList.c
                Parsing.subproj/CFOldStylePList.c
                Parsing.subproj/CFPropertyList.c
                Parsing.subproj/CFXMLInputStream.c
                Parsing.subproj/CFXMLInterface.c
                Parsing.subproj/CFXMLNode.c
                Parsing.subproj/CFXMLParser.c
                Parsing.subproj/CFXMLTree.c
                # PlugIn
                PlugIn.subproj/CFBundle_Binary.c
                PlugIn.subproj/CFBundle.c
                PlugIn.subproj/CFBundle_DebugStrings.c
                PlugIn.subproj/CFBundle_Executable.c
                PlugIn.subproj/CFBundle_Grok.c
                PlugIn.subproj/CFBundle_InfoPlist.c
                PlugIn.subproj/CFBundle_Locale.c
                PlugIn.subproj/CFBundle_Main.c
                PlugIn.subproj/CFBundle_ResourceFork.c
                PlugIn.subproj/CFBundle_Resources.c
                PlugIn.subproj/CFBundle_Strings.c
                PlugIn.subproj/CFBundle_Tables.c
                PlugIn.subproj/CFPlugIn.c
                PlugIn.subproj/CFPlugIn_Factory.c
                PlugIn.subproj/CFPlugIn_Instance.c
                PlugIn.subproj/CFPlugIn_PlugIn.c
                # Preferences
                Preferences.subproj/CFApplicationPreferences.c
                Preferences.subproj/CFPreferences.c
                Preferences.subproj/CFXMLPreferencesDomain.c
                # RunLoop
                # TODO(compnerd) make this empty on non-Mach targets
                # RunLoop.subproj/CFMachPort.c
                # RunLoop.subproj/CFMachPort_Lifetime.c
                # RunLoop.subproj/CFMessagePort.c
                RunLoop.subproj/CFRunLoop.c
                RunLoop.subproj/CFSocket.c
                # Stream
                Stream.subproj/CFConcreteStreams.c
                Stream.subproj/CFSocketStream.c
                Stream.subproj/CFStream.c
                # String
                String.subproj/CFAttributedString.c
                String.subproj/CFBurstTrie.c
                String.subproj/CFCharacterSet.c
                String.subproj/CFCharacterSetData.S
                String.subproj/CFRegularExpression.c
                String.subproj/CFRunArray.c
                String.subproj/CFString.c
                String.subproj/CFStringEncodings.c
                String.subproj/CFStringScanner.c
                String.subproj/CFStringTransform.c
                String.subproj/CFStringUtilities.c
                String.subproj/CFUniCharPropertyDatabase.S
                String.subproj/CFUnicodeData.S
                # StringEncodings
                StringEncodings.subproj/CFBuiltinConverters.c
                StringEncodings.subproj/CFICUConverters.c
                StringEncodings.subproj/CFPlatformConverters.c
                StringEncodings.subproj/CFStringEncodingConverter.c
                StringEncodings.subproj/CFStringEncodingDatabase.c
                StringEncodings.subproj/CFUniChar.c
                StringEncodings.subproj/CFUnicodeDecomposition.c
                StringEncodings.subproj/CFUnicodePrecomposition.c
                # URL
                URL.subproj/CFURLAccess.c
                URL.subproj/CFURL.c
                URL.subproj/CFURLComponents.c
                URL.subproj/CFURLComponents_URIParser.c
                URL.subproj/CFURLSessionInterface.c)
if(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_SYSTEM_NAME STREQUAL Android)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_TARGET_LINUX
                               -D_GNU_SOURCE)
elseif(CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_TARGET_FREEBSD)
elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_TARGET_MACOSX)
elseif(CMAKE_SYSTEM_NAME STREQUAL Windows)
  # NOTE(compnerd) we only support building with the dynamic CRT as using the
  # static CRT causes problems for users of the library.
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -D_DLL)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_TARGET_WINDOWS)
  if(BUILD_SHARED_LIBS)
    target_compile_definitions(CoreFoundation
                               PRIVATE
                                 -D_USRDLL)
  endif()
endif()
target_compile_definitions(CoreFoundation
                           PRIVATE
                             -DU_SHOW_DRAFT_API
                             -DCF_BUILDING_CF)
if(CF_ENABLE_LIBDISPATCH)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_ENABLE_LIBDISPATCH)
endif()
if(CF_DEPLOYMENT_SWIFT)
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_RUNTIME_SWIFT)
  if(CMAKE_SYSTEM_NAME STREQUAL Windows)
    target_compile_definitions(CoreFoundation
                               PRIVATE
                                 -D_DLL
                                 -DCURL_STATICLIB)
  endif()
else()
  target_compile_definitions(CoreFoundation
                             PRIVATE
                               -DDEPLOYMENT_RUNTIME_C)
endif()
target_compile_definitions(CoreFoundation
                           PRIVATE
                              $<$<COMPILE_LANGUAGE:ASM>:CF_CHARACTERSET_BITMAP="CharacterSets/CFCharacterSetBitmaps.bitmap">
                              $<$<COMPILE_LANGUAGE:ASM>:CF_CHARACTERSET_UNICHAR_DB="CharacterSets/CFUniCharPropertyDatabase.data">
                              $<$<COMPILE_LANGUAGE:ASM>:CF_CHARACTERSET_UNICODE_DATA_B="CharacterSets/CFUnicodeData-B.mapping">
                              $<$<COMPILE_LANGUAGE:ASM>:CF_CHARACTERSET_UNICODE_DATA_L="CharacterSets/CFUnicodeData-L.mapping">)

target_include_directories(CoreFoundation
                           PRIVATE
                             ${CMAKE_SOURCE_DIR})
if(NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
  find_package(LibXml2 REQUIRED)
  target_include_directories(CoreFoundation
                             PRIVATE
                               ${LIBXML2_INCLUDE_DIR})
  find_package(CURL REQUIRED)
  target_include_directories(CoreFoundation
                             PRIVATE
                               ${CURL_INCLUDE_DIRS})
  find_package(ICU COMPONENTS uc i18n REQUIRED)
  target_include_directories(CoreFoundation
                             PRIVATE
                               ${ICU_INCLUDE_DIR})
endif()
if(CF_ENABLE_LIBDISPATCH)
  target_include_directories(CoreFoundation
                             PRIVATE
                               ${CF_PATH_TO_LIBDISPATCH_SOURCE}
                               ${CF_PATH_TO_LIBDISPATCH_BUILD}/tests)
  if(NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
    target_include_directories(CoreFoundation
                               SYSTEM PRIVATE
                                 ${CF_PATH_TO_LIBDISPATCH_SOURCE}/src/BlocksRuntime)
  endif()
endif()

if("${CMAKE_C_SIMULATE_ID}" STREQUAL "MSVC")
  target_compile_options(CoreFoundation
                         PRIVATE
                           $<$<COMPILE_LANGUAGE:C>:/FI${CMAKE_SOURCE_DIR}/Base.subproj/CoreFoundation_Prefix.h>)
else()
  target_compile_options(CoreFoundation
                         PRIVATE
                           $<$<COMPILE_LANGUAGE:C>:-include;${CMAKE_SOURCE_DIR}/Base.subproj/CoreFoundation_Prefix.h>)
endif()

if("${CMAKE_C_SIMULATE_ID}" STREQUAL "MSVC")
  target_compile_options(CoreFoundation
                         PRIVATE
                           -fblocks
                           /EHsc)
else()
  target_compile_options(CoreFoundation
                         PRIVATE
                           -fblocks
                           -fconstant-cfstrings
                           -fdollars-in-identifiers
                           -fexceptions
                           -fno-common)
endif()
if(CF_DEPLOYMENT_SWIFT)
  if("${CMAKE_C_SIMULATE_ID}" STREQUAL "MSVC")
    target_compile_options(CoreFoundation
                           PRIVATE
                             /clang:-fcf-runtime-abi=swift)
  else()
    target_compile_options(CoreFoundation
                           PRIVATE
                             -fcf-runtime-abi=swift)
  endif()
endif()

target_compile_options(CoreFoundation
                       PRIVATE
                         -Wno-shorten-64-to-32
                         -Wno-deprecated-declarations
                         -Wno-unreachable-code
                         -Wno-conditional-uninitialized
                         -Wno-unused-variable
                         -Wno-int-conversion
                         -Wno-unused-function
                         -Wno-microsoft-enum-forward-reference)

if(NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_link_libraries(CoreFoundation
                        PRIVATE
                          ${CURL_LIBRARIES}
                          ${LIBXML2_LIBRARIES})
endif()
if(CMAKE_SYSTEM_NAME STREQUAL Android)
  target_link_libraries(CoreFoundation
                        PRIVATE
                          log)
endif()
target_link_libraries(CoreFoundation
                      PRIVATE
                        Threads::Threads
                        ${CMAKE_DL_LIBS})
if(NOT CMAKE_SYSTEM_NAME STREQUAL Windows AND NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_link_libraries(CoreFoundation
                        PRIVATE
                          m)
endif()
if(CF_ENABLE_LIBDISPATCH)
  target_link_libraries(CoreFoundation
                        PRIVATE
                          dispatch)
endif()
if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_link_libraries(CoreFoundation
                        PRIVATE
                          icucore)
  set_target_properties(CoreFoundation
                        PROPERTIES LINK_FLAGS
                          -Xlinker;-alias_list;-Xlinker;Base.subproj/DarwinSymbolAliases;-twolevel_namespace;-sectcreate;__UNICODE;__csbitmaps;CharacterSets/CFCharacterSetBitmaps.bitmap;-sectcreate;__UNICODE;__properties;CharacterSets/CFUniCharPropertyDatabase.data;-sectcreate;__UNICODE;__data;CharacterSets/CFUnicodeData-L.mapping;-segprot;__UNICODE;r;r)
endif()

install(TARGETS
          CoreFoundation
        DESTINATION
          "${CMAKE_INSTALL_FULL_LIBDIR}")
install(DIRECTORY
          ${CoreFoundation_FRAMEWORK_DIRECTORY}
        DESTINATION
          ${CMAKE_INSTALL_PREFIX}/System/Library/Frameworks
        USE_SOURCE_PERMISSIONS
        PATTERN PrivateHeaders EXCLUDE)

