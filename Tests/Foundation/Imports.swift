// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Centralized conditional imports for all test sources

#if !DEPLOYMENT_RUNTIME_OBJC && canImport(SwiftFoundation) && canImport(SwiftFoundationNetworking) && canImport(SwiftFoundationXML) && canImport(SwiftXCTest) 
@_exported import SwiftFoundation
@_exported import SwiftFoundationNetworking
@_exported import SwiftFoundationXML
@_exported import SwiftXCTest
#else
@_exported import Foundation
#if canImport(FoundationNetworking)
@_exported import FoundationNetworking
#endif
#if canImport(FoundationXML)
@_exported import FoundationXML
#endif
@_exported import XCTest
#endif
