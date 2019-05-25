
# FIXME(compnerd) workaround linker flag munging
set(CMAKE_SHARED_LINKER_FLAGS "")
set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "")
# FIXME(compnerd) workaround the library search path flag
set(CMAKE_LIBRARY_PATH_FLAG -L)
set(CMAKE_LINK_LIBRARY_FLAG "-l")

add_library(Foundation
  AffineTransform.swift
  Array.swift
  Boxing.swift
  Bridging.swift
  Bundle.swift
  ByteCountFormatter.swift
  Calendar.swift
  CGFloat.swift
  CharacterSet.swift
  Codable.swift
  Collections+DataProtocol.swift
  ContiguousBytes.swift
  Data.swift
  DataProtocol.swift
  Date.swift
  DateComponents.swift
  DateComponentsFormatter.swift
  DateFormatter.swift
  DateInterval.swift
  DateIntervalFormatter.swift
  Decimal.swift
  Dictionary.swift
  DispatchData+DataProtocol.swift
  EnergyFormatter.swift
  ExtraStringAPIs.swift
  FileHandle.swift
  FileManager.swift
  FileManager+POSIX.swift
  FileManager+Win32.swift
  FileManager_XDG.swift
  Formatter.swift
  FoundationErrors.swift
  Host.swift
  IndexPath.swift
  IndexSet.swift
  ISO8601DateFormatter.swift
  JSONEncoder.swift
  JSONSerialization.swift
  LengthFormatter.swift
  Locale.swift
  MassFormatter.swift
  Measurement.swift
  MeasurementFormatter.swift
  Notification.swift
  NotificationQueue.swift
  NSArray.swift
  NSAttributedString.swift
  NSCache.swift
  NSCalendar.swift
  NSCFArray.swift
  NSCFBoolean.swift
  NSCFCharacterSet.swift
  NSCFDictionary.swift
  NSCFSet.swift
  NSCFString.swift
  NSCharacterSet.swift
  NSCoder.swift
  NSComparisonPredicate.swift
  NSCompoundPredicate.swift
  NSConcreteValue.swift
  NSData+DataProtocol.swift
  NSData.swift
  NSDate.swift
  NSDecimalNumber.swift
  NSDictionary.swift
  NSEnumerator.swift
  NSError.swift
  NSExpression.swift
  NSGeometry.swift
  NSIndexPath.swift
  NSIndexSet.swift
  NSKeyedArchiver.swift
  NSKeyedArchiverHelpers.swift
  NSKeyedCoderOldStyleArray.swift
  NSKeyedUnarchiver.swift
  NSLocale.swift
  NSLock.swift
  NSLog.swift
  NSMeasurement.swift
  NSNotification.swift
  NSNull.swift
  NSNumber.swift
  NSObjCRuntime.swift
  NSObject.swift
  NSOrderedSet.swift
  NSPathUtilities.swift
  NSPersonNameComponents.swift
  NSPlatform.swift
  NSPredicate.swift
  NSRange.swift
  NSRegularExpression.swift
  NSSet.swift
  NSSortDescriptor.swift
  NSSpecialValue.swift
  NSString.swift
  NSStringAPI.swift
  NSSwiftRuntime.swift
  NSTextCheckingResult.swift
  NSTimeZone.swift
  NSURL.swift
  NSURLError.swift
  NSUUID.swift
  NSValue.swift
  NumberFormatter.swift
  Operation.swift
  PersonNameComponents.swift
  PersonNameComponentsFormatter.swift
  Pointers+DataProtocol.swift
  Port.swift
  PortMessage.swift
  Process.swift
  ProcessInfo.swift
  Progress.swift
  ProgressFraction.swift
  PropertyListEncoder.swift
  PropertyListSerialization.swift
  ReferenceConvertible.swift
  RunLoop.swift
  Scanner.swift
  ScannerAPI.swift
  Set.swift
  Stream.swift
  String.swift
  StringEncodings.swift
  Thread.swift
  Timer.swift
  TimeZone.swift
  Unit.swift
  URL.swift
  URLComponents.swift
  UserDefaults.swift
  UUID.swift
  XMLDocument.swift
  XMLDTD.swift
  XMLDTDNode.swift
  XMLElement.swift
  XMLNode.swift
  XMLParser.swift)

target_compile_definitions(Foundation PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT)

target_compile_options(Foundation PRIVATE
  $<$<BOOL:ENABLE_TESTING>:-enable-testing>)
target_compile_options(Foundation PUBLIC
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")

set_target_properties(Foundation PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY}
  INTERFACE_LINK_DIRECTORIES $<TARGET_LINKER_FILE_DIR:Foundation>)

if(FOUNDATION_ENABLE_LIBDISPATCH)
  target_compile_definitions(Foundation PRIVATE
    DEPLOYMENT_ENABLE_LIBDISPATCH)

  # FIXME(compnerd) these three can go away with export targets
  target_compile_options(Foundation PUBLIC
    "SHELL:-Xcc -fblocks"
    "SHELL:-Xcc -I${FOUNDATION_PATH_TO_LIBDISPATCH_SOURCE}")
  target_include_directories(Foundation PUBLIC
    ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/swift)
  target_link_directories(Foundation PUBLIC
    ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src
    ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/BlocksRuntime
    ${FOUNDATION_PATH_TO_LIBDISPATCH_BUILD}/src/swift)

  target_link_libraries(Foundation PRIVATE
    swiftDispatch)
endif()

target_link_libraries(Foundation PRIVATE
  uuid CoreFoundation)
target_link_libraries(Foundation PRIVATE
  ${ICU_UC_LIBRARY} ${ICU_I18N_LIBRARY})
target_link_libraries(Foundation PRIVATE
  ${LIBXML2_LIBRARIES})
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_libraries(Foundation PRIVATE
    DbgHelp Ole32 ShLwApi Shell32 WS2_32 iphlpapi pathcch)
  target_link_libraries(Foundation PRIVATE
    CoreFoundationResources)

  # FIXME(compnerd) SR-9138
  target_link_options(Foundation PRIVATE
    "LINKER:-ignore:4217")
endif()

add_library(FoundationNetworking
  Boxing.swift
  NSURLRequest.swift
  HTTPCookie.swift
  HTTPCookieStorage.swift
  URLAuthenticationChallenge.swift
  URLCache.swift
  URLCredential.swift
  URLCredentialStorage.swift
  URLProtectionSpace.swift
  URLProtocol.swift
  URLRequest.swift
  URLResponse.swift
  URLSession/BodySource.swift
  URLSession/Configuration.swift
  URLSession/http/HTTPMessage.swift
  URLSession/http/HTTPURLProtocol.swift
  URLSession/libcurl/EasyHandle.swift
  URLSession/libcurl/libcurlHelpers.swift
  URLSession/libcurl/MultiHandle.swift
  URLSession/Message.swift
  URLSession/NativeProtocol.swift
  URLSession/NetworkingSpecific.swift
  URLSession/ftp/FTPURLProtocol.swift
  URLSession/TaskRegistry.swift
  URLSession/TransferState.swift
  URLSession/URLSession.swift
  URLSession/URLSessionConfiguration.swift
  URLSession/URLSessionDelegate.swift
  URLSession/URLSessionTask.swift)

target_compile_definitions(FoundationNetworking PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT
  NS_BUILDING_FOUNDATION_NETWORKING)

target_compile_options(FoundationNetworking PRIVATE
  $<$<BOOL:ENABLE_TESTING>:-enable-testing>)

target_link_libraries(FoundationNetworking PRIVATE
  Foundation
  CFURLSessionInterface)

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  # FIXME(compnerd) SR-9138
  target_link_options(FoundationNetworking PRIVATE
    "LINKER:-ignore:4217")
endif()

set_target_properties(FoundationNetworking PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY}
  INTERFACE_LINK_DIRECTORIES $<TARGET_LINKER_FILE_DIR:FoundationNetworking>)


install(FILES
          ${CMAKE_Swift_MODULE_DIRECTORY}/Foundation.swiftdoc
          ${CMAKE_Swift_MODULE_DIRECTORY}/Foundation.swiftmodule
          ${CMAKE_Swift_MODULE_DIRECTORY}/FoundationNetworking.swiftdoc
          ${CMAKE_Swift_MODULE_DIRECTORY}/FoundationNetworking.swiftmodule
        DESTINATION
          lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
install(TARGETS
          Foundation
          FoundationNetworking
        ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch}
        LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch}
        RUNTIME DESTINATION bin)

