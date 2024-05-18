##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift open source project
##
## Copyright (c) 2024 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.md for the list of Swift project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

add_library(FoundationNetworking
    Boxing.swift
    DataURLProtocol.swift
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
    URLSession/libcurl/EasyHandle.swift
    URLSession/libcurl/libcurlHelpers.swift
    URLSession/libcurl/MultiHandle.swift
    URLSession/Message.swift
    URLSession/NativeProtocol.swift
    URLSession/NetworkingSpecific.swift
    URLSession/TaskRegistry.swift
    URLSession/TransferState.swift
    URLSession/URLSession.swift
    URLSession/URLSessionConfiguration.swift
    URLSession/URLSessionDelegate.swift
    URLSession/URLSessionTask.swift
    URLSession/URLSessionTaskMetrics.swift
    URLSession/WebSocket/WebSocketURLProtocol.swift)

target_compile_options(FoundationNetworking PRIVATE
    "SHELL:$<$<COMPILE_LANGUAGE:Swift>:${_Foundation_swift_build_flags}>")

target_link_libraries(FoundationNetworking
    PRIVATE
        Foundation
        CoreFoundation
        _CFURLSessionInterface
    PUBLIC
        FoundationEssentials)

set_target_properties(FoundationNetworking PROPERTIES
    INSTALL_RPATH "$ORIGIN")

set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS FoundationNetworking)
_install_target(FoundationNetworking)
