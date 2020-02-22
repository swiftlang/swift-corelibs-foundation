add_library(FoundationNetworking
  ../Foundation/Boxing.swift
  HTTPCookie.swift
  HTTPCookieStorage.swift
  NSURLRequest.swift
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
  URLSession/FTP/FTPURLProtocol.swift
  URLSession/HTTP/HTTPMessage.swift
  URLSession/HTTP/HTTPURLProtocol.swift
  URLSession/Message.swift
  URLSession/NativeProtocol.swift
  URLSession/NetworkingSpecific.swift
  URLSession/TaskRegistry.swift
  URLSession/TransferState.swift
  URLSession/URLSession.swift
  URLSession/URLSessionConfiguration.swift
  URLSession/URLSessionDelegate.swift
  URLSession/URLSessionTask.swift
  URLSession/libcurl/EasyHandle.swift
  URLSession/libcurl/MultiHandle.swift
  URLSession/libcurl/libcurlHelpers.swift)
target_compile_definitions(FoundationNetworking PRIVATE
  DEPLOYMENT_RUNTIME_SWIFT
  NS_BUILDING_FOUNDATION_NETWORKING)
target_compile_options(FoundationNetworking PUBLIC
  -autolink-force-load
  # SR-12254: workaround for the swift compiler not properly tracking the
  # forced load symbol when validating the TBD
  -Xfrontend -validate-tbd-against-ir=none
  $<$<BOOL:${ENABLE_TESTING}>:-enable-testing>
  "SHELL:-Xcc -F${CMAKE_BINARY_DIR}")
target_link_libraries(FoundationNetworking
  PRIVATE
    CFURLSessionInterface
  PUBLIC
    Foundation)
set_target_properties(FoundationNetworking PROPERTIES
  INSTALL_RPATH "$ORIGIN"
  Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/swift)


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS FoundationNetworking)
install(TARGETS FoundationNetworking
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
get_swift_host_arch(swift_arch)
install(FILES
  $<TARGET_PROPERTY:FoundationNetworking,Swift_MODULE_DIRECTORY>/FoundationNetworking.swiftdoc
  $<TARGET_PROPERTY:FoundationNetworking,Swift_MODULE_DIRECTORY>/FoundationNetworking.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
