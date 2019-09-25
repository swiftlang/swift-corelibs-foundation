
cmake_minimum_required(VERSION 3.4.3)

list(APPEND CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# NOTE(compnerd) enable CMP0091 - select MSVC runtime based on
# CMAKE_MSVC_RUNTIME_LIBRARY.  Requires CMake 3.15 or newer
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

project(Foundation
        LANGUAGES
          C)
enable_testing()

# NOTE(compnerd) default to /MD or /MDd by default based on the configuration.
# Cache the variable to allow the user to alter the configuration.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE
  STRING "MSVC Runtime Library")

option(BUILD_SHARED_LIBS "build shared libraries" ON)

option(FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE "Path to libdispatch source" "")
option(FOUNDATION_PATH_TO_LIBDISPATCH_BUILD "Path to libdispatch build" "")
option(FOUNDATION_PATH_TO_XCTEST_BUILD "Path to XCTest build" "")

find_package(CURL CONFIG)
if(CURL_FOUND)
  include(CMakeExpandImportedTargets)
  cmake_expand_imported_targets(CURL_LIBRARIES LIBRARIES CURL::libcurl)
else()
  find_package(CURL REQUIRED)
endif()
find_package(ICU COMPONENTS uc i18n REQUIRED)
find_package(LibXml2 REQUIRED)

include(SwiftSupport)
include(GNUInstallDirs)

string(TOLOWER ${CMAKE_SYSTEM_NAME} swift_os)
get_swift_host_arch(swift_arch)

set(CF_PATH_TO_LIBDISPATCH_SOURCE ${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE} CACHE PATH "Path to libdispatch source" FORCE)
set(CF_PATH_TO_LIBDISPATCH_BUILD ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD} CACHE PATH "Path to libdispatch build" FORCE)
set(CF_DEPLOYMENT_SWIFT YES CACHE BOOL "Build for Swift" FORCE)

set(SAVED_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS NO)
add_subdirectory(CoreFoundation EXCLUDE_FROM_ALL)
set(BUILD_SHARED_LIBS ${SAVED_BUILD_SHARED_LIBS})

# Setup include paths for uuid/uuid.h
target_include_directories(CoreFoundation PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}/CoreFoundation.framework/Headers)

add_library(uuid
            STATIC
              uuid/uuid.h
              uuid/uuid.c)
set_target_properties(uuid
                      PROPERTIES
                        POSITION_INDEPENDENT_CODE YES)
# Add an include directory for the CoreFoundation framework headers to satisfy
# the dependency on TargetConditionals.h
target_include_directories(uuid PUBLIC
  ${CMAKE_CURRENT_BINARY_DIR}/CoreFoundation.framework/Headers)
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_compile_definitions(uuid
                             PRIVATE
                               _CRT_NONSTDC_NO_WARNINGS
                               _CRT_SECURE_NO_DEPRECATE
                               _CRT_SECURE_NO_WARNINGS)
  target_link_libraries(uuid PRIVATE Bcrypt)
endif()
add_dependencies(uuid CoreFoundation)

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  set(swift_libc_flags -libc;${CMAKE_MSVC_RUNTIME_LIBRARY})
  if(CMAKE_SYSTEM_NAME STREQUAL Debug)
    list(APPEND swift_libc_flags -Xcc;-D_DEBUG)
  endif()
endif()

set(libdispatch_cflags -I;${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE};-I;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/swift;-I;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/swift/swift;-Xcc;-fblocks)
set(libdispatch_ldflags -L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD};-L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/bin;-L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/BlocksRuntime;-L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src;-ldispatch;-lswiftDispatch)
if(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  file(TO_CMAKE_PATH "${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}" FOUNDATION_PATH_TO_LIBDISPATCH_BUILD)
  list(APPEND libdispatch_ldflags -Xlinker;-rpath;-Xlinker;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD};-Xlinker;-rpath;-Xlinker;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src)
endif()

set(plutil_rpath)
if(CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL Linux OR
    CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  set(Foundation_RPATH -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN")
  set(XDG_TEST_HELPER_RPATH -Xlinker;-rpath;-Xlinker;${CMAKE_CURRENT_BINARY_DIR})
  set(plutil_rpath -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN/../lib/swift/${swift_os}")
elseif(CMAKE_SYSTEM_NAME STREQUAL Windows)
  # FIXME(SR9138) Silence "locally defined symbol '…' imported in function '…'
  set(WORKAROUND_SR9138 -Xlinker;-ignore:4049;-Xlinker;-ignore:4217)
endif()

# NOTE(compnerd) this is a horrible hack to work around the fact that we do not
# have a proper library target for Foundation which can link against the
# CoreFoundation target.  When we gain proper CMake support for Swift, we should
# be able to remove this and just use
# `target_link_libraries(Foundation PRIVATE CoreFoundation)`.
set(CoreFoundation_LIBRARIES $<TARGET_FILE:CoreFoundation>)
set(CFURLSessionInterface_LIBRARIES $<TARGET_FILE:CFURLSessionInterface>)
set(CFXMLInterface_LIBRARIES $<TARGET_FILE:CFXMLInterface>)
get_target_property(CoreFoundation_LINK_LIBRARIES CoreFoundation LINK_LIBRARIES)
foreach(library ${CoreFoundation_LINK_LIBRARIES})
  if(NOT library STREQUAL Threads::Threads)
    list(APPEND CoreFoundation_LIBRARIES -l${library})
    list(APPEND CFURLSessionInterface_LIBRARIES -l${library})
    list(APPEND CFXMLInterface_LIBRARIES -l${library})
  endif()
endforeach()

add_swift_library(Foundation
                  MODULE_NAME
                    Foundation
                  MODULE_LINK_NAME
                    Foundation
                  MODULE_PATH
                    ${CMAKE_CURRENT_BINARY_DIR}/swift/Foundation.swiftmodule
                  SOURCES
                    Foundation/AffineTransform.swift
                    Foundation/Array.swift
                    Foundation/Boxing.swift
                    Foundation/Bridging.swift
                    Foundation/Bundle.swift
                    Foundation/ByteCountFormatter.swift
                    Foundation/Calendar.swift
                    Foundation/CGFloat.swift
                    Foundation/CharacterSet.swift
                    Foundation/Codable.swift
                    Foundation/Collections+DataProtocol.swift
                    Foundation/ContiguousBytes.swift
                    Foundation/Data.swift
                    Foundation/DataProtocol.swift
                    Foundation/Date.swift
                    Foundation/DateComponents.swift
                    Foundation/DateComponentsFormatter.swift
                    Foundation/DateFormatter.swift
                    Foundation/DateInterval.swift
                    Foundation/DateIntervalFormatter.swift
                    Foundation/Decimal.swift
                    Foundation/Dictionary.swift
                    Foundation/DispatchData+DataProtocol.swift
                    Foundation/EnergyFormatter.swift
                    Foundation/ExtraStringAPIs.swift
                    Foundation/FileHandle.swift
                    Foundation/FileManager.swift
                    Foundation/FileManager+POSIX.swift
                    Foundation/FileManager+Win32.swift
                    Foundation/FileManager_XDG.swift
                    Foundation/Formatter.swift
                    Foundation/FoundationErrors.swift
                    Foundation/Host.swift
                    Foundation/IndexPath.swift
                    Foundation/IndexSet.swift
                    Foundation/ISO8601DateFormatter.swift
                    Foundation/JSONEncoder.swift
                    Foundation/JSONSerialization.swift
                    Foundation/LengthFormatter.swift
                    Foundation/Locale.swift
                    Foundation/MassFormatter.swift
                    Foundation/Measurement.swift
                    Foundation/MeasurementFormatter.swift
                    Foundation/Notification.swift
                    Foundation/NotificationQueue.swift
                    Foundation/NSArray.swift
                    Foundation/NSAttributedString.swift
                    Foundation/NSCache.swift
                    Foundation/NSCalendar.swift
                    Foundation/NSCFArray.swift
                    Foundation/NSCFBoolean.swift
                    Foundation/NSCFCharacterSet.swift
                    Foundation/NSCFDictionary.swift
                    Foundation/NSCFSet.swift
                    Foundation/NSCFString.swift
                    Foundation/NSCharacterSet.swift
                    Foundation/NSCoder.swift
                    Foundation/NSComparisonPredicate.swift
                    Foundation/NSCompoundPredicate.swift
                    Foundation/NSConcreteValue.swift
                    Foundation/NSData+DataProtocol.swift
                    Foundation/NSData.swift
                    Foundation/NSDate.swift
                    Foundation/NSDecimalNumber.swift
                    Foundation/NSDictionary.swift
                    Foundation/NSEnumerator.swift
                    Foundation/NSError.swift
                    Foundation/NSExpression.swift
                    Foundation/NSGeometry.swift
                    Foundation/NSIndexPath.swift
                    Foundation/NSIndexSet.swift
                    Foundation/NSKeyedArchiver.swift
                    Foundation/NSKeyedArchiverHelpers.swift
                    Foundation/NSKeyedCoderOldStyleArray.swift
                    Foundation/NSKeyedUnarchiver.swift
                    Foundation/NSLocale.swift
                    Foundation/NSLock.swift
                    Foundation/NSLog.swift
                    Foundation/NSMeasurement.swift
                    Foundation/NSNotification.swift
                    Foundation/NSNull.swift
                    Foundation/NSNumber.swift
                    Foundation/NSObjCRuntime.swift
                    Foundation/NSObject.swift
                    Foundation/NSOrderedSet.swift
                    Foundation/NSPathUtilities.swift
                    Foundation/NSPersonNameComponents.swift
                    Foundation/NSPlatform.swift
                    Foundation/NSPredicate.swift
                    Foundation/NSRange.swift
                    Foundation/NSRegularExpression.swift
                    Foundation/NSSet.swift
                    Foundation/NSSortDescriptor.swift
                    Foundation/NSSpecialValue.swift
                    Foundation/NSString.swift
                    Foundation/NSStringAPI.swift
                    Foundation/NSSwiftRuntime.swift
                    Foundation/NSTextCheckingResult.swift
                    Foundation/NSTimeZone.swift
                    Foundation/NSURL.swift
                    Foundation/NSURLError.swift
                    Foundation/NSUUID.swift
                    Foundation/NSValue.swift
                    Foundation/NumberFormatter.swift
                    Foundation/Operation.swift
                    Foundation/PersonNameComponents.swift
                    Foundation/PersonNameComponentsFormatter.swift
                    Foundation/Pointers+DataProtocol.swift
                    Foundation/Port.swift
                    Foundation/PortMessage.swift
                    Foundation/Process.swift
                    Foundation/ProcessInfo.swift
                    Foundation/Progress.swift
                    Foundation/ProgressFraction.swift
                    Foundation/PropertyListEncoder.swift
                    Foundation/PropertyListSerialization.swift
                    Foundation/ReferenceConvertible.swift
                    Foundation/RunLoop.swift
                    Foundation/Scanner.swift
                    Foundation/ScannerAPI.swift
                    Foundation/Set.swift
                    Foundation/Stream.swift
                    Foundation/String.swift
                    Foundation/StringEncodings.swift
                    Foundation/Thread.swift
                    Foundation/Timer.swift
                    Foundation/TimeZone.swift
                    Foundation/Unit.swift
                    Foundation/URL.swift
                    Foundation/URLComponents.swift
                    Foundation/UserDefaults.swift
                    Foundation/UUID.swift
                  TARGET
                    ${CMAKE_C_COMPILER_TARGET}
                  LINK_FLAGS
                    ${CoreFoundation_LIBRARIES}
                    ${ICU_UC_LIBRARY} ${ICU_I18N_LIBRARY}
                    ${libdispatch_ldflags}
                    $<TARGET_FILE:uuid>
                    ${Foundation_RPATH}
                    ${WORKAROUND_SR9138}
                    $<$<PLATFORM_ID:Windows>:-lOle32>
                    $<$<PLATFORM_ID:Windows>:-lShell32>
                    $<$<PLATFORM_ID:Windows>:-lpathcch>
                    $<$<PLATFORM_ID:Windows>:$<TARGET_OBJECTS:CoreFoundationResources>>
                  SWIFT_FLAGS
                    -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                    -DDEPLOYMENT_RUNTIME_SWIFT
                    -I;${ICU_INCLUDE_DIR}
                    ${libdispatch_cflags}
                    $<$<BOOL:ENABLE_TESTING>:-enable-testing>
                    $<$<NOT:$<CONFIG:Debug>>:-O>
                    ${swift_libc_flags}
                  DEPENDS
                    uuid
                    CoreFoundation
                    $<$<PLATFORM_ID:Windows>:CoreFoundationResources>)

add_swift_library(FoundationNetworking
                  MODULE_NAME
                    FoundationNetworking
                  MODULE_LINK_NAME
                    FoundationNetworking
                  MODULE_PATH
                    ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationNetworking.swiftmodule
                  SOURCES
                  Foundation/Boxing.swift
                  Foundation/NSURLRequest.swift
                  Foundation/HTTPCookie.swift
                  Foundation/HTTPCookieStorage.swift
                  Foundation/URLAuthenticationChallenge.swift
                  Foundation/URLCache.swift
                  Foundation/URLCredential.swift
                  Foundation/URLCredentialStorage.swift
                  Foundation/URLProtectionSpace.swift
                  Foundation/URLProtocol.swift
                  Foundation/URLRequest.swift
                  Foundation/URLResponse.swift
                  Foundation/URLSession/BodySource.swift
                  Foundation/URLSession/Configuration.swift
                  Foundation/URLSession/http/HTTPMessage.swift
                  Foundation/URLSession/http/HTTPURLProtocol.swift
                  Foundation/URLSession/libcurl/EasyHandle.swift
                  Foundation/URLSession/libcurl/libcurlHelpers.swift
                  Foundation/URLSession/libcurl/MultiHandle.swift
                  Foundation/URLSession/Message.swift
                  Foundation/URLSession/NativeProtocol.swift
                  Foundation/URLSession/NetworkingSpecific.swift
                  Foundation/URLSession/ftp/FTPURLProtocol.swift
                  Foundation/URLSession/TaskRegistry.swift
                  Foundation/URLSession/TransferState.swift
                  Foundation/URLSession/URLSession.swift
                  Foundation/URLSession/URLSessionConfiguration.swift
                  Foundation/URLSession/URLSessionDelegate.swift
                  Foundation/URLSession/URLSessionTask.swift
                  TARGET
                    ${CMAKE_C_COMPILER_TARGET}
                  LINK_FLAGS
                    ${MSVCRT_LINK_FLAGS}
                    -L${CMAKE_CURRENT_BINARY_DIR}
                    ${libdispatch_ldflags}
                    -lFoundation
                    ${Foundation_INTERFACE_LIBRARIES}
                    ${CFURLSessionInterface_LIBRARIES}
                    ${CURL_LIBRARIES}
                    ${ZLIB_LIBRARY}
                    ${Foundation_RPATH}
                    ${WORKAROUND_SR9138}
                    ${WORKAROUND_SR9995}
                  SWIFT_FLAGS
                    -DDEPLOYMENT_RUNTIME_SWIFT
                    -DNS_BUILDING_FOUNDATION_NETWORKING
                    -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                    -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                    ${libdispatch_cflags}
                    $<$<BOOL:ENABLE_TESTING>:-enable-testing>
                    $<$<NOT:$<CONFIG:Debug>>:-O>
                  DEPENDS
                    uuid
                    CoreFoundation
                    $<$<PLATFORM_ID:Windows>:CoreFoundationResources>
                    Foundation)

add_swift_library(FoundationXML
                  MODULE_NAME
                    FoundationXML
                  MODULE_LINK_NAME
                    FoundationXML
                  MODULE_PATH
                    ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationXML.swiftmodule
                  SOURCES
                  Foundation/XMLDocument.swift
                  Foundation/XMLDTD.swift
                  Foundation/XMLDTDNode.swift
                  Foundation/XMLElement.swift
                  Foundation/XMLNode.swift
                  Foundation/XMLParser.swift
                  TARGET
                    ${CMAKE_C_COMPILER_TARGET}
                  LINK_FLAGS
                    ${MSVCRT_LINK_FLAGS}
                    -L${CMAKE_CURRENT_BINARY_DIR}
                    ${libdispatch_ldflags}
                    -lFoundation
                    ${Foundation_INTERFACE_LIBRARIES}
                    ${CFXMLInterface_LIBRARIES}
                    ${LIBXML2_LIBRARIES}
                    ${Foundation_RPATH}
                    ${WORKAROUND_SR9138}
                    ${WORKAROUND_SR9995}
                  SWIFT_FLAGS
                    -DDEPLOYMENT_RUNTIME_SWIFT
                    -DNS_BUILDING_FOUNDATION_NETWORKING
                    -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                    -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                    ${libdispatch_cflags}
                    $<$<BOOL:ENABLE_TESTING>:-enable-testing>
                    $<$<NOT:$<CONFIG:Debug>>:-O>
                  DEPENDS
                    uuid
                    CoreFoundation
                    $<$<PLATFORM_ID:Windows>:CoreFoundationResources>
                    Foundation)



if(NOT BUILD_SHARED_LIBS)
  set(Foundation_INTERFACE_LIBRARIES
      -L${install_dir}/usr/lib
      -lCoreFoundation
      -L${CMAKE_CURRENT_BINARY_DIR}
      -luuid
      ${CURL_LIBRARIES}
      ${ICU_UC_LIBRARY}
      ${ICU_I18N_LIBRARY}
      ${LIBXML2_LIBRARIES})
endif()

add_swift_executable(plutil
                     SOURCES
                       Tools/plutil/main.swift
                     TARGET
                       ${CMAKE_C_COMPILER_TARGET}
                     LINK_FLAGS
                       ${libdispatch_ldflags}
                       -L${CMAKE_CURRENT_BINARY_DIR}
                       -lFoundation
                       ${Foundation_INTERFACE_LIBRARIES}
                       ${plutil_rpath}
                     SWIFT_FLAGS
                       -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                       -DDEPLOYMENT_RUNTIME_SWIFT
                       -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                       -I;${ICU_INCLUDE_DIR}
                       ${libdispatch_cflags}
                       $<$<BOOL:ENABLE_TESTING>:-enable-testing>
                       $<$<NOT:$<CONFIG:Debug>>:-O>
                       ${swift_libc_flags}
                     DEPENDS
                       uuid
                       Foundation
                       CoreFoundation)

add_swift_executable(GenerateTestFixtures
                     SOURCES
                       Tools/GenerateTestFixtures/GenerateTestFixtures/main.swift
                       Tools/GenerateTestFixtures/GenerateTestFixtures/Utilities.swift
                       TestFoundation/FixtureValues.swift
                     TARGET
                       ${CMAKE_C_COMPILER_TARGET}
                     LINK_FLAGS
                       ${libdispatch_ldflags}
                       -L${CMAKE_CURRENT_BINARY_DIR}
                       -lFoundation
                       ${Foundation_INTERFACE_LIBRARIES}
                     SWIFT_FLAGS
                       -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                       -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                       -I;${ICU_INCLUDE_DIR}
                       ${libdispatch_cflags}
                       $<$<NOT:$<CONFIG:Debug>>:-O>
                       ${swift_libc_flags}
                     DEPENDS
                       Foundation)

if(ENABLE_TESTING)
  add_swift_executable(xdgTestHelper
                       TARGET
                         ${CMAKE_C_COMPILER_TARGET}
                       LINK_FLAGS
                         ${libdispatch_ldflags}
                         -L${CMAKE_CURRENT_BINARY_DIR}
                         -lFoundation
                         ${Foundation_INTERFACE_LIBRARIES}
                         ${XDG_TEST_HELPER_RPATH}
                       SOURCES
                         TestFoundation/xdgTestHelper/main.swift
                       SWIFT_FLAGS
                         -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                         -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                         -I;${ICU_INCLUDE_DIR}
                         ${libdispatch_cflags}
                       DEPENDS
                         uuid
                         Foundation
                         FoundationNetworking
                         FoundationXML
                         CoreFoundation)

  add_swift_executable(TestFoundation
                       SOURCES
                         TestFoundation/main.swift
                         TestFoundation/HTTPServer.swift
                         TestFoundation/FTPServer.swift
                         Foundation/ProgressFraction.swift
                         TestFoundation/Utilities.swift
                         TestFoundation/FixtureValues.swift
                         # Test Cases
                         TestFoundation/TestAffineTransform.swift
                         TestFoundation/TestBundle.swift
                         TestFoundation/TestByteCountFormatter.swift
                         TestFoundation/TestCachedURLResponse.swift
                         TestFoundation/TestCalendar.swift
                         TestFoundation/TestCharacterSet.swift
                         TestFoundation/TestCodable.swift
                         TestFoundation/TestDateComponents.swift
                         TestFoundation/TestDateFormatter.swift
                         TestFoundation/TestDateInterval.swift
                         TestFoundation/TestDateIntervalFormatter.swift
                         TestFoundation/TestDate.swift
                         TestFoundation/TestDecimal.swift
                         TestFoundation/TestEnergyFormatter.swift
                         TestFoundation/TestFileHandle.swift
                         TestFoundation/TestFileManager.swift
                         TestFoundation/TestHost.swift
                         TestFoundation/TestHTTPCookieStorage.swift
                         TestFoundation/TestHTTPCookie.swift
                         TestFoundation/TestImports.swift
                         TestFoundation/TestIndexPath.swift
                         TestFoundation/TestIndexSet.swift
                         TestFoundation/TestISO8601DateFormatter.swift
                         TestFoundation/TestJSONEncoder.swift
                         TestFoundation/TestJSONSerialization.swift
                         TestFoundation/TestLengthFormatter.swift
                         TestFoundation/TestMassFormatter.swift
                         TestFoundation/TestMeasurement.swift
                         TestFoundation/TestNotificationCenter.swift
                         TestFoundation/TestNotificationQueue.swift
                         TestFoundation/TestNotification.swift
                         TestFoundation/TestNSArray.swift
                         TestFoundation/TestNSAttributedString.swift
                         TestFoundation/TestNSCache.swift
                         TestFoundation/TestNSCalendar.swift
                         TestFoundation/TestNSCompoundPredicate.swift
                         TestFoundation/TestNSData.swift
                         TestFoundation/TestNSDictionary.swift
                         TestFoundation/TestNSError.swift
                         TestFoundation/TestNSGeometry.swift
                         TestFoundation/TestNSKeyedArchiver.swift
                         TestFoundation/TestNSKeyedUnarchiver.swift
                         TestFoundation/TestNSLocale.swift
                         TestFoundation/TestNSLock.swift
                         TestFoundation/TestNSNull.swift
                         TestFoundation/TestNSNumberBridging.swift
                         TestFoundation/TestNSNumber.swift
                         TestFoundation/TestNSOrderedSet.swift
                         TestFoundation/TestNSPredicate.swift
                         TestFoundation/TestNSRange.swift
                         TestFoundation/TestNSRegularExpression.swift
                         TestFoundation/TestNSSet.swift
                         TestFoundation/TestNSSortDescriptor.swift
                         TestFoundation/TestNSString.swift
                         TestFoundation/TestNSTextCheckingResult.swift
                         TestFoundation/TestNSURLRequest.swift
                         TestFoundation/TestNSUUID.swift
                         TestFoundation/TestNSValue.swift
                         TestFoundation/TestNumberFormatter.swift
                         TestFoundation/TestObjCRuntime.swift
                         TestFoundation/TestOperationQueue.swift
                         TestFoundation/TestPersonNameComponents.swift
                         TestFoundation/TestPipe.swift
                         TestFoundation/TestProcessInfo.swift
                         TestFoundation/TestProcess.swift
                         TestFoundation/TestProgress.swift
                         TestFoundation/TestProgressFraction.swift
                         TestFoundation/TestPropertyListEncoder.swift
                         TestFoundation/TestPropertyListSerialization.swift
                         TestFoundation/TestRunLoop.swift
                         TestFoundation/TestScanner.swift
                         TestFoundation/TestSocketPort.swift
                         TestFoundation/TestStream.swift
                         TestFoundation/TestThread.swift
                         TestFoundation/TestTimer.swift
                         TestFoundation/TestTimeZone.swift
                         TestFoundation/TestUnitConverter.swift
                         TestFoundation/TestUnit.swift
                         TestFoundation/TestURLCache.swift
                         TestFoundation/TestURLCredential.swift
                         TestFoundation/TestURLCredentialStorage.swift
                         TestFoundation/TestURLProtectionSpace.swift
                         TestFoundation/TestURLProtocol.swift
                         TestFoundation/TestURLRequest.swift
                         TestFoundation/TestURLResponse.swift
                         TestFoundation/TestURLSession.swift
                         TestFoundation/TestURLSessionFTP.swift
                         TestFoundation/TestURL.swift
                         TestFoundation/TestUserDefaults.swift
                         TestFoundation/TestUtils.swift
                         TestFoundation/TestUUID.swift
                         TestFoundation/TestXMLDocument.swift
                         TestFoundation/TestXMLParser.swift
                       TARGET
                         ${CMAKE_C_COMPILER_TARGET}
                       LINK_FLAGS
                         ${libdispatch_ldflags}
                         -L${CMAKE_CURRENT_BINARY_DIR}
                         -lFoundation
                         ${Foundation_INTERFACE_LIBRARIES}
                         -L${FOUNDATION_PATH_TO_XCTEST_BUILD}
                         -lXCTest
                         ${WORKAROUND_SR9138}
                       RESOURCES
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/Info.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSURLTestData.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/Test.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSStringTestData.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSString-UTF16-BE-data.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSString-UTF16-LE-data.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSString-UTF32-BE-data.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSString-UTF32-LE-data.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSString-ISO-8859-1-data.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSXMLDocumentTestData.xml
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/PropertyList-1.0.dtd
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSXMLDTDTestData.xml
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-ArrayTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-ComplexTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-ConcreteValueTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-EdgeInsetsTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-NotificationTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-RangeTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-RectTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-URLTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-UUIDTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/NSKeyedUnarchiver-OrderedSetTest.plist
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Resources/TestFileWithZeros.txt
                         ${CMAKE_SOURCE_DIR}/TestFoundation/Fixtures
                       SWIFT_FLAGS
                         -Xcc -F${CMAKE_CURRENT_BINARY_DIR}
                         -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                         -I;${FOUNDATION_PATH_TO_XCTEST_BUILD}/swift
                         -I;${ICU_INCLUDE_DIR}
                         ${libdispatch_cflags}
                         $<$<NOT:$<CONFIG:Debug>>:-O>
                         ${swift_libc_flags}
                       DEPENDS
                         Foundation
                         FoundationNetworking
                         FoundationXML
                         CoreFoundation
                         xdgTestHelper)

  add_custom_command(TARGET TestFoundation
                     POST_BUILD
                     BYPRODUCTS
                       ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/xdgTestHelper${CMAKE_EXECUTABLE_SUFFIX}
                     COMMAND
                       ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_BINARY_DIR}/xdgTestHelper${CMAKE_EXECUTABLE_SUFFIX} ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/xdgTestHelper${CMAKE_EXECUTABLE_SUFFIX}
                     DEPENDS
                       TestFoundation
                       xdgTestHelper)
  add_test(NAME
             TestFoundation
           COMMAND
             ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/TestFoundation
           WORKING_DIRECTORY
             ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation)
  set_tests_properties(TestFoundation
                       PROPERTIES
                         ENVIRONMENT
                           LD_LIBRARY_PATH=${CMAKE_CURRENT_BINARY_DIR}:${FOUNDATION_PATH_TO_XCTEST_BUILD}:${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}:${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src
                         DEPENDS
                         ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/xdgTestHelper${CMAKE_EXECUTABLE_SUFFIX})

  add_custom_command(TARGET TestFoundation
                     POST_BUILD
                     BYPRODUCTS
                       ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/plutil${CMAKE_EXECUTABLE_SUFFIX}
                     COMMAND
                       ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_BINARY_DIR}/plutil${CMAKE_EXECUTABLE_SUFFIX} ${CMAKE_CURRENT_BINARY_DIR}/TestFoundation/plutil${CMAKE_EXECUTABLE_SUFFIX}
                     DEPENDS
                       TestFoundation
                       plutil)
endif()

if(BUILD_SHARED_LIBS)
  set(library_kind SHARED)
  set(swift_dir swift)
else()
  set(library_kind STATIC)
  set(swift_dir swift_static)
endif()

# TODO(compnerd) honour lib vs lib64
install(FILES
          ${CMAKE_CURRENT_BINARY_DIR}/swift/Foundation.swiftdoc
          ${CMAKE_CURRENT_BINARY_DIR}/swift/Foundation.swiftmodule
          ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationNetworking.swiftdoc
          ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationNetworking.swiftmodule
          ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationXML.swiftdoc
          ${CMAKE_CURRENT_BINARY_DIR}/swift/FoundationXML.swiftmodule
        DESTINATION
          lib/${swift_dir}/${swift_os}/${swift_arch})


set(Foundation_OUTPUT_FILE
  ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_${library_kind}_LIBRARY_PREFIX}Foundation${CMAKE_${library_kind}_LIBRARY_SUFFIX})
set(FoundationNetworking_OUTPUT_FILE
  ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_${library_kind}_LIBRARY_PREFIX}FoundationNetworking${CMAKE_${library_kind}_LIBRARY_SUFFIX})
set(FoundationXML_OUTPUT_FILE
  ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_${library_kind}_LIBRARY_PREFIX}FoundationXML${CMAKE_${library_kind}_LIBRARY_SUFFIX})

if(CMAKE_SYSTEM_NAME STREQUAL Windows AND BUILD_SHARED_LIBS)
  install(FILES
            ${Foundation_OUTPUT_FILE}
            ${FoundationNetworking_OUTPUT_FILE}
            ${FoundationXML_OUTPUT_FILE}
          DESTINATION
            bin)
  install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}Foundation${CMAKE_IMPORT_LIBRARY_SUFFIX}
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}FoundationNetworking${CMAKE_IMPORT_LIBRARY_SUFFIX}
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}FoundationXML${CMAKE_IMPORT_LIBRARY_SUFFIX}
          DESTINATION
            lib/${swift_dir}/${swift_os})
else()
  install(FILES
            ${Foundation_OUTPUT_FILE}
            ${FoundationNetworking_OUTPUT_FILE}
            ${FoundationXML_OUTPUT_FILE}
          DESTINATION
            lib/${swift_dir}/${swift_os})
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
install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/plutil${CMAKE_EXECUTABLE_SUFFIX}
        DESTINATION
          ${CMAKE_INSTALL_FULL_BINDIR})
