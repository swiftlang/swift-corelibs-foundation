
add_subdirectory(xdgTestHelper)

add_executable(TestFoundation
  main.swift
  HTTPServer.swift
  FTPServer.swift
  ../Foundation/ProgressFraction.swift
  Utilities.swift
  FixtureValues.swift)

# Test Cases
target_sources(TestFoundation PRIVATE
  TestAffineTransform.swift
  TestBundle.swift
  TestByteCountFormatter.swift
  TestCachedURLResponse.swift
  TestCalendar.swift
  TestCharacterSet.swift
  TestCodable.swift
  TestDateComponents.swift
  TestDateFormatter.swift
  TestDateInterval.swift
  TestDateIntervalFormatter.swift
  TestDate.swift
  TestDecimal.swift
  TestDimension.swift
  TestEnergyFormatter.swift
  TestFileHandle.swift
  TestFileManager.swift
  TestHost.swift
  TestHTTPCookieStorage.swift
  TestHTTPCookie.swift
  TestHTTPURLResponse.swift
  TestImports.swift
  TestIndexPath.swift
  TestIndexSet.swift
  TestISO8601DateFormatter.swift
  TestJSONEncoder.swift
  TestJSONSerialization.swift
  TestLengthFormatter.swift
  TestMassFormatter.swift
  TestMeasurement.swift
  TestNotificationCenter.swift
  TestNotificationQueue.swift
  TestNotification.swift
  TestNSArray.swift
  TestNSAttributedString.swift
  TestNSCache.swift
  TestNSCalendar.swift
  TestNSCompoundPredicate.swift
  TestNSData.swift
  TestNSDateComponents.swift
  TestNSDictionary.swift
  TestNSError.swift
  TestNSGeometry.swift
  TestNSKeyedArchiver.swift
  TestNSKeyedUnarchiver.swift
  TestNSLocale.swift
  TestNSLock.swift
  TestNSNull.swift
  TestNSNumberBridging.swift
  TestNSNumber.swift
  TestNSOrderedSet.swift
  TestNSPredicate.swift
  TestNSRange.swift
  TestNSRegularExpression.swift
  TestNSSet.swift
  TestNSSortDescriptor.swift
  TestNSString.swift
  TestNSTextCheckingResult.swift
  TestNSURLRequest.swift
  TestNSUUID.swift
  TestNSValue.swift
  TestNumberFormatter.swift
  TestObjCRuntime.swift
  TestOperationQueue.swift
  TestPersonNameComponents.swift
  TestPipe.swift
  TestProcessInfo.swift
  TestProcess.swift
  TestProgress.swift
  TestProgressFraction.swift
  TestPropertyListEncoder.swift
  TestPropertyListSerialization.swift
  TestRunLoop.swift
  TestScanner.swift
  TestSocketPort.swift
  TestStream.swift
  TestThread.swift
  TestTimer.swift
  TestTimeZone.swift
  TestUnitConverter.swift
  TestUnitVolume.swift
  TestUnit.swift
  TestURLCache.swift
  TestURLCredential.swift
  TestURLCredentialStorage.swift
  TestURLComponents.swift
  TestURLProtectionSpace.swift
  TestURLProtocol.swift
  TestURLRequest.swift
  TestURLResponse.swift
  TestURLSession.swift
  TestURLSessionFTP.swift
  TestURL.swift
  TestUserDefaults.swift
  TestUtils.swift
  TestUUID.swift
  TestXMLDocument.swift
  TestXMLParser.swift)
target_link_libraries(TestFoundation PRIVATE
  Foundation
  FoundationNetworking
  FoundationXML)
target_link_libraries(TestFoundation PRIVATE
  XCTest)

# NOTE(compnerd) create a test "app" directory as we need the xdgTestHelper as
# an executable peer and the binary will be placed in the directory with the
# same name as a peer in the build tree.

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  set(Resources TestFoundation.resources)
else()
  set(Resources Resources)
endif()

add_custom_command(TARGET TestFoundation POST_BUILD
  COMMAND
    ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:TestFoundation> ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:plutil> ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:xdgTestHelper> ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/TestFoundation.app/${Resources}
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
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
    ${CMAKE_BINARY_DIR}/TestFoundation.app/${Resources}
  COMMAND
    ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/TestFoundation/Fixtures ${CMAKE_BINARY_DIR}/TestFoundation.app/${Resources}/Fixtures
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:Foundation> ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:FoundationNetworking> ${CMAKE_BINARY_DIR}/TestFoundation.app
  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:FoundationXML> ${CMAKE_BINARY_DIR}/TestFoundation.app)

xctest_discover_tests(TestFoundation
                      COMMAND
                      ${CMAKE_BINARY_DIR}/TestFoundation.app/TestFoundation${CMAKE_EXECUTABLE_SUFFIX}
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/TestFoundation.app
                      PROPERTIES
                        ENVIRONMENT
                          LD_LIBRARY_PATH=${CMAKE_BINARY_DIR}/TestFoundation.app:$<TARGET_LINKER_FILE_DIR:XCTest>:$<TARGET_LINKER_FILE_DIR:dispatch>:$<TARGET_LINKER_FILE_DIR:swiftDispatch>:$<TARGET_LINKER_FILE_DIR:BlocksRuntime>)

