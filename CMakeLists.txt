
cmake_minimum_required(VERSION 3.4.3)

list(APPEND CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

project(Foundation
        LANGUAGES
          C)
enable_testing()

option(BUILD_SHARED_LIBS "build shared libraries" ON)

option(FOUNDATION_ENABLE_LIBDISPATCH "Enable GCD Support" YES)
option(FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE "Path to libdispatch source" "")
option(FOUNDATION_PATH_TO_LIBDISPATCH_BUILD "Path to libdispatch build" "")
option(FOUNDATION_PATH_TO_XCTEST_BUILD "Path to XCTest build" "")

find_package(CURL REQUIRED)
find_package(ICU COMPONENTS uc i18n REQUIRED)
find_package(LibXml2 REQUIRED)

include(SwiftSupport)
include(GNUInstallDirs)
include(ExternalProject)

string(TOLOWER ${CMAKE_SYSTEM_NAME} swift_os)
get_swift_host_arch(swift_arch)

ExternalProject_Add(CoreFoundation
                    SOURCE_DIR
                      ${CMAKE_CURRENT_SOURCE_DIR}/CoreFoundation
                    CMAKE_COMMAND
                      ${CMAKE_COMMAND}
                    CMAKE_ARGS
                      -DBUILD_SHARED_LIBS=NO
                      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                      -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                      # NOTE(compnerd) ensure that we build it as a DLL as we
                      # wish to re-export the symbols from Foundation
                      -DCMAKE_C_FLAGS=-D_USRDLL
                      -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
                      -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                      -DCMAKE_INSTALL_LIBDIR=usr/lib
                      -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
                      -DCMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}
                      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
                      -DCF_DEPLOYMENT_SWIFT=YES
                      -DCF_ENABLE_LIBDISPATCH=${FOUNDATION_ENABLE_LIBDISPATCH}
                      -DCF_PATH_TO_LIBDISPATCH_SOURCE=${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE}
                      -DCF_PATH_TO_LIBDISPATCH_BUILD=${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}
                      -DICU_LIBRARY=${ICU_LIBRARY}
                      -DICU_INCLUDE_DIR=${ICU_INCLUDE_DIR}
                      -DCURL_LIBRARY=${CURL_LIBRARY}
                      -DCURL_INCLUDE_DIR=${CURL_INCLUDE_DIR}
                      -DLIBXML2_LIBRARY=${LIBXML2_LIBRARY}
                      -DLIBXML2_INCLUDE_DIR=${LIBXML2_INCLUDE_DIR}
                    INSTALL_COMMAND
                      ${CMAKE_COMMAND} -E env --unset=DESTDIR ${CMAKE_COMMAND} --build . --target install)
ExternalProject_Get_Property(CoreFoundation install_dir)

add_library(uuid
            STATIC
              uuid/uuid.h
              uuid/uuid.c)
set_target_properties(uuid
                      PROPERTIES
                        POSITION_INDEPENDENT_CODE YES)
# Add an include directory for the CoreFoundation framework headers to satisfy
# the dependency on TargetConditionals.h
target_compile_options(uuid
                       PUBLIC
                         -I${install_dir}/System/Library/Frameworks/CoreFoundation.framework/Headers)
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_compile_definitions(uuid
                             PRIVATE
                               _CRT_NONSTDC_NO_WARNINGS
                               _CRT_SECURE_NO_DEPRECATE
                               _CRT_SECURE_NO_WARNINGS)
endif()
add_dependencies(uuid CoreFoundation)

set(swift_optimization_flags)
if(CMAKE_BUILD_TYPE MATCHES Release)
  set(swift_optimization_flags -O)
endif()
if(ENABLE_TESTING)
  set(swift_enable_testing -enable-testing)
endif()

set(deployment_enable_libdispatch)
set(libdispatch_cflags)
set(libdispatch_ldflags)
if(FOUNDATION_ENABLE_LIBDISPATCH)
  set(deployment_enable_libdispatch -DDEPLOYMENT_ENABLE_LIBDISPATCH)
  set(libdispatch_cflags -I;${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE};-I;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/swift;-Xcc;-fblocks)
  set(libdispatch_ldflags -L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD};-L;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src;-ldispatch;-lswiftDispatch)
  if(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
    list(APPEND libdispatch_ldflags -Xlinker;-rpath;-Xlinker;${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src)
  endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Android OR CMAKE_SYSTEM_NAME STREQUAL Linux)
  set(deployment_target -DDEPLOYMENT_TARGET_LINUX)
  set(Foundation_rpath_flags -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN")
elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  set(deployment_target -DDEPLOYMENT_TARGET_MACOSX)
elseif(CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  set(deployment_target -DDEPLOYMENT_TARGET_FREEBSD)
  set(Foundation_rpath_flags -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN")
elseif(CMAKE_SYSTEM_NAME STREQUAL Windows)
  set(deployment_target -DDEPLOYMENT_TARGET_WINDOWS)
  set(CoreFoundation_INTERFACE_LIBRARIES -lWS2_32 -lUser32 -lmsvcrt -ladvapi32 -lshell32 -lrpcrt4 -lsecur32 -lPathcch -lOle32 -lCrypt32 -lwldap32 -lNormaliz -lDbgHelp -lIphlpapi)
endif()

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
                    Foundation/FileManager_XDG.swift
                    Foundation/Formatter.swift
                    Foundation/FoundationErrors.swift
                    Foundation/Host.swift
                    Foundation/HTTPCookie.swift
                    Foundation/HTTPCookieStorage.swift
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
                    Foundation/NSURLRequest.swift
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
                    Foundation/Set.swift
                    Foundation/Stream.swift
                    Foundation/String.swift
                    Foundation/StringEncodings.swift
                    Foundation/Thread.swift
                    Foundation/Timer.swift
                    Foundation/TimeZone.swift
                    Foundation/Unit.swift
                    Foundation/URL.swift
                    Foundation/URLAuthenticationChallenge.swift
                    Foundation/URLCache.swift
                    Foundation/URLComponents.swift
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
                    Foundation/URLSession/TaskRegistry.swift
                    Foundation/URLSession/TransferState.swift
                    Foundation/URLSession/URLSession.swift
                    Foundation/URLSession/URLSessionConfiguration.swift
                    Foundation/URLSession/URLSessionDelegate.swift
                    Foundation/URLSession/URLSessionTask.swift
                    Foundation/UserDefaults.swift
                    Foundation/UUID.swift
                    Foundation/XMLDocument.swift
                    Foundation/XMLDTD.swift
                    Foundation/XMLDTDNode.swift
                    Foundation/XMLElement.swift
                    Foundation/XMLNode.swift
                    Foundation/XMLParser.swift
                  TARGET
                    ${CMAKE_C_COMPILER_TARGET}
                  CFLAGS
                    ${deployment_target}
                    ${deployment_enable_libdispatch}
                    -F${install_dir}/System/Library/Frameworks
                    -D_DLL
                  LINK_FLAGS
                    -L${install_dir}/usr/lib
                    -lCoreFoundation
                    ${CURL_LIBRARIES}
                    ${ICU_UC_LIBRARY} ${ICU_I18N_LIBRARY}
                    ${LIBXML2_LIBRARIES}
                    ${libdispatch_ldflags}
                    -L${CMAKE_CURRENT_BINARY_DIR}
                    -luuid
                    ${Foundation_rpath_flags}
                    ${CoreFoundation_INTERFACE_LIBRARIES}
                  SWIFT_FLAGS
                    -DDEPLOYMENT_RUNTIME_SWIFT
                    ${deployment_enable_libdispatch}
                    -I;${ICU_INCLUDE_DIR}
                    ${libdispatch_cflags}
                    ${swift_enable_testing}
                    ${swift_optimization_flags}
                    -Xcc -D_DLL
                  DEPENDS
                    CoreFoundation)

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
                     CFLAGS
                       ${deployment_target}
                       ${deployment_enable_libdispatch}
                       -F${install_dir}/System/Library/Frameworks
                     LINK_FLAGS
                       ${libdispatch_ldflags}
                       -L${CMAKE_CURRENT_BINARY_DIR}
                       -lFoundation
                       ${Foundation_INTERFACE_LIBRARIES}
                       -Xlinker;-rpath;-Xlinker;"\\\$\$ORIGIN/../lib/swift/${swift_os}"
                     SWIFT_FLAGS
                       -DDEPLOYMENT_RUNTIME_SWIFT
                       ${deployment_enable_libdispatch}
                       -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                       -I;${ICU_INCLUDE_DIR}
                       ${libdispatch_cflags}
                       ${swift_enable_testing}
                       ${swift_optimization_flags}
                     DEPENDS
                       uuid
                       Foundation
                       CoreFoundation)

if(ENABLE_TESTING)
  add_swift_executable(xdgTestHelper
                       CFLAGS
                         ${deployment_target}
                         ${deployment_enable_libdispatch}
                         -F${install_dir}/System/Library/Frameworks
                       LINK_FLAGS
                         ${libdispatch_ldflags}
                         -L${CMAKE_CURRENT_BINARY_DIR}
                         -lFoundation
                         ${Foundation_INTERFACE_LIBRARIES}
                       SOURCES
                         TestFoundation/xdgTestHelper/main.swift
                       SWIFT_FLAGS
                         -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                         -I;${ICU_INCLUDE_DIR}
                         ${libdispatch_cflags}
                       DEPENDS
                         uuid
                         Foundation
                         CoreFoundation)

  add_swift_executable(TestFoundation
                       SOURCES
                         TestFoundation/main.swift
                         TestFoundation/HTTPServer.swift
                         Foundation/ProgressFraction.swift
                         TestFoundation/Utilities.swift
                         # Test Cases
                         TestFoundation/TestAffineTransform.swift
                         TestFoundation/TestBundle.swift
                         TestFoundation/TestByteCountFormatter.swift
                         TestFoundation/TestCalendar.swift
                         TestFoundation/TestCharacterSet.swift
                         TestFoundation/TestCodable.swift
                         TestFoundation/TestDateComponents.swift
                         TestFoundation/TestDateFormatter.swift
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
                         TestFoundation/TestPropertyListEncoder.swift
                         TestFoundation/TestJSONSerialization.swift
                         TestFoundation/TestLengthFormatter.swift
                         TestFoundation/TestMassFormatter.swift
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
                         TestFoundation/TestNSProgressFraction.swift
                         TestFoundation/TestNSRange.swift
                         TestFoundation/TestNSRegularExpression.swift
                         TestFoundation/TestNSSet.swift
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
                         TestFoundation/TestPropertyListSerialization.swift
                         TestFoundation/TestRunLoop.swift
                         TestFoundation/TestScanner.swift
                         TestFoundation/TestStream.swift
                         TestFoundation/TestThread.swift
                         TestFoundation/TestTimer.swift
                         TestFoundation/TestTimeZone.swift
                         TestFoundation/TestUnitConverter.swift
                         TestFoundation/TestUnit.swift
                         TestFoundation/TestURLCredential.swift
                         TestFoundation/TestURLProtectionSpace.swift
                         TestFoundation/TestURLProtocol.swift
                         TestFoundation/TestURLRequest.swift
                         TestFoundation/TestURLResponse.swift
                         TestFoundation/TestURLSession.swift
                         TestFoundation/TestURL.swift
                         TestFoundation/TestUserDefaults.swift
                         TestFoundation/TestUtils.swift
                         TestFoundation/TestUUID.swift
                         TestFoundation/TestXMLDocument.swift
                         TestFoundation/TestXMLParser.swift
                       CFLAGS
                         ${deployment_enable_libdispatch}
                         -F${install_dir}/System/Library/Frameworks
                       LINK_FLAGS
                         ${libdispatch_ldflags}
                         -L${CMAKE_CURRENT_BINARY_DIR}
                         -lFoundation
                         ${Foundation_INTERFACE_LIBRARIES}
                         -L${FOUNDATION_PATH_TO_XCTEST_BUILD}
                         -lXCTest
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
                       SWIFT_FLAGS
                         ${deployment_enable_libdispatch}
                         -I;${CMAKE_CURRENT_BINARY_DIR}/swift
                         -I;${FOUNDATION_PATH_TO_XCTEST_BUILD}/swift
                         -I;${ICU_INCLUDE_DIR}
                         ${libdispatch_cflags}
                         ${swift_optimization_flags}
                       DEPENDS
                         Foundation
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
endif()

# TODO(compnerd) honour lib vs lib64
install(FILES
          ${CMAKE_CURRENT_BINARY_DIR}/swift/Foundation.swiftdoc
          ${CMAKE_CURRENT_BINARY_DIR}/swift/Foundation.swiftmodule
        DESTINATION
          lib/swift/${swift_os}/${swift_arch})
if(BUILD_SHARED_LIBS)
  install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}Foundation${CMAKE_SHARED_LIBRARY_SUFFIX}
          DESTINATION
            lib/swift/${swift_os})
else()
  install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}Foundation${CMAKE_STATIC_LIBRARY_SUFFIX}
          DESTINATION
            lib/swift_static/${swift_os})
endif()
# TODO(compnerd) install as a Framework as that is how swift actually is built
install(DIRECTORY
          ${install_dir}/System/Library/Frameworks/CoreFoundation.framework/Headers/
        DESTINATION
          lib/swift/CoreFoundation
        FILES_MATCHING PATTERN "*.h")
install(FILES
          CoreFoundation/Base.subproj/module.map
        DESTINATION
          lib/swift/CoreFoundation)
install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/plutil
        DESTINATION
          ${CMAKE_INSTALL_FULL_BINDIR})
