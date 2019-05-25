
# FIXME(compnerd) workaround linker flag munging
set(CMAKE_EXE_LINKER_FLAGS "")
set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "")
# FIXME(compnerd) workaround the library search path flag
set(CMAKE_LIBRARY_PATH_FLAG -L)
set(CMAKE_LINK_LIBRARY_FLAG "-l")
set(CMAKE_CREATE_CONSOLE_EXE "")

add_executable(xdgTestHelper
  xdgTestHelper/main.swift)
target_link_libraries(xdgTestHelper PRIVATE
  Foundation
  FoundationNetworking)

add_executable(TestFoundation
  main.swift
  HTTPServer.swift
  FTPServer.swift
  ../Foundation/ProgressFraction.swift
  Utilities.swift
  FixtureValues.swift
  # Test Cases
  TestAffineTransform.swift
  TestBundle.swift
  TestByteCountFormatter.swift
  TestCalendar.swift
  TestCharacterSet.swift
  TestCodable.swift
  TestDateComponents.swift
  TestDateFormatter.swift
  TestDateInterval.swift
  TestDateIntervalFormatter.swift
  TestDate.swift
  TestDecimal.swift
  TestEnergyFormatter.swift
  TestFileHandle.swift
  TestFileManager.swift
  TestHost.swift
  TestHTTPCookieStorage.swift
  TestHTTPCookie.swift
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
  TestStream.swift
  TestThread.swift
  TestTimer.swift
  TestTimeZone.swift
  TestUnitConverter.swift
  TestUnit.swift
  TestURLCredential.swift
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
  Foundation)

target_link_libraries(TestFoundation PRIVATE
  XCTest)
# FIXME(compnerd) these two can go away with export targets
target_include_directories(TestFoundation PRIVATE
  ${FOUNDATION_PATH_TO_XCTEST_BUILD}/swift)
target_link_directories(TestFoundation PRIVATE
  ${FOUNDATION_PATH_TO_XCTEST_BUILD})

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_libraries(TestFoundation PRIVATE
    WS2_32)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  # FIXME(compnerd) SR-9138
  target_link_options(TestFoundation PRIVATE
    "LINKER:-ignore:4217")
endif()

add_custom_command(TARGET TestFoundation POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory TestFoundation
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/Resources TestFoundation/Resources/
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/Fixtures TestFoundation/Fixtures/
  COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:TestFoundation> TestFoundation/
  COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:xdgTestHelper> TestFoundation/
  BYPRODUCTS TestFoundation)

add_test(NAME TestFoundation
  COMMAND TestFoundation/TestFoundation${CMAKE_EXECUTABLE_SUFFIX})
set_tests_properties(TestFoundation PROPERTIES
  ENVIRONMENT LD_LIBRARY_PATH=$<TARGET_FILE_DIR:Foundation>:${FOUNDATION_PATH_TO_XCTEST_BUILD}:${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}:${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src
  DEPENDS xdgTestHelper)

