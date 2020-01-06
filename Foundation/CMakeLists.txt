
if(CMAKE_VERSION VERSION_LESS 3.16)
  set(CMAKE_LINK_LIBRARY_FLAG "-l")
endif()

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
  UUID.swift)
target_compile_definitions(Foundation PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT)
target_compile_options(Foundation PUBLIC
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")
if(CMAKE_SYSTEM_NAME STREQUAL Windows AND CMAKE_VERSION VERSION_LESS 3.16)
  # Work around for CMake 15 which doesn't link in the resource file
  # target properly
  add_dependencies(Foundation CoreFoundationResources)
  target_link_options(Foundation PRIVATE $<TARGET_OBJECTS:CoreFoundationResources>)
endif()
if(ENABLE_TESTING)
  target_compile_options(Foundation PRIVATE
    -enable-testing)
endif()
target_link_libraries(Foundation PRIVATE
  CoreFoundation
  uuid)
target_link_libraries(Foundation PUBLIC
  swiftDispatch)

# TODO(compnerd) properly propogate `BUILD_RPATH` to the target using CMake
if(NOT CMAKE_SYSTEM_NAME STREQUAL Windows AND NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
  target_link_options(Foundation PRIVATE
    "SHELL:-Xlinker -rpath -Xlinker $<TARGET_FILE_DIR:swiftDispatch>")
endif()
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_libraries(Foundation PRIVATE
    CoreFoundationResources)
  target_link_libraries(Foundation PRIVATE
    Ole32
    Shell32
    pathcch)
endif()
set_target_properties(Foundation PROPERTIES
  INSTALL_RPATH "$ORIGIN"
  Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/swift)


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
target_compile_options(FoundationNetworking PUBLIC
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")
if(ENABLE_TESTING)
  target_compile_options(FoundationNetworking PRIVATE
    -enable-testing)
endif()
target_link_libraries(FoundationNetworking PRIVATE
  Foundation
  CFURLSessionInterface)
set_target_properties(FoundationNetworking PROPERTIES
  INSTALL_RPATH "$ORIGIN"
  Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/swift)


add_library(FoundationXML
  XMLDocument.swift
  XMLDTD.swift
  XMLDTDNode.swift
  XMLElement.swift
  XMLNode.swift
  XMLParser.swift)
target_compile_definitions(FoundationXML PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT)
target_compile_options(FoundationXML PUBLIC
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")
if(ENABLE_TESTING)
  target_compile_options(FoundationXML PRIVATE
    -enable-testing)
endif()
target_link_libraries(FoundationXML PRIVATE
  Foundation
  CFXMLInterface)
set_target_properties(FoundationXML PROPERTIES
  INSTALL_RPATH "$ORIGIN"
  Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/swift)


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS
  Foundation FoundationNetworking FoundationXML)
get_swift_host_arch(swift_arch)
install(TARGETS Foundation FoundationNetworking FoundationXML
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
install(FILES
  ${CMAKE_BINARY_DIR}/swift/Foundation.swiftdoc
  ${CMAKE_BINARY_DIR}/swift/Foundation.swiftmodule
  ${CMAKE_BINARY_DIR}/swift/FoundationNetworking.swiftdoc
  ${CMAKE_BINARY_DIR}/swift/FoundationNetworking.swiftmodule
  ${CMAKE_BINARY_DIR}/swift/FoundationXML.swiftdoc
  ${CMAKE_BINARY_DIR}/swift/FoundationXML.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
