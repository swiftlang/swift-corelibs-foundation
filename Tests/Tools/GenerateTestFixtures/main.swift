// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

/*
 This tool generates fixtures from Foundation that can be used by TestFoundation
 to test cross-platform serialization compatibility. It can generate fixtures
 either from the Foundation that ships with Apple OSes, or from swift-corelibs-foundation,
 depending on the OS and linkage.
 
 usage: GenerateTestFixtures <OUTPUT ROOT>
 The fixtures will be generated either in <OUTPUT ROOT>/Darwin or <OUTPUT ROOT>/Swift,
 depending on whether Darwin Foundation or swift-corelibs-foundation produced the fixtures.
 */

// 1. Get the right Foundation imported.
#if os(iOS) || os(watchOS) || os(tvOS)
#error("macOS only, please.")
#endif

#if os(macOS) && NS_GENERATE_FIXTURES_FROM_SWIFT_CORELIBS_FOUNDATION_ON_DARWIN

#if canImport(SwiftFoundation)
    import SwiftFoundation
    fileprivate let foundationVariant = "Swift"
    fileprivate let foundationPlatformVersion = swiftVersionString()
#else
    // A better diagnostic message:
    #error("You specified NS_GENERATE_FIXTURES_FROM_SWIFT_CORELIBS_FOUNDATION_ON_DARWIN, but the SwiftFoundation module isn't available. Make sure you have set up this project to link with the result of the SwiftFoundation target in the swift-corelibs-foundation workspace")
#endif

#else
    import Foundation

    #if os(macOS)
        fileprivate let foundationVariant = "macOS"
        fileprivate let foundationPlatformVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion)"
        }()
    #else
        fileprivate let foundationVariant = "Swift"
        fileprivate let foundationPlatformVersion = swiftVersionString()
    #endif
#endif

// 2. Figure out the output path and create it if needed.

let arguments = ProcessInfo.processInfo.arguments
let outputRoot: URL
if arguments.count > 1 {
    outputRoot = URL(fileURLWithPath: arguments[1], relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
} else {
    outputRoot = Bundle.main.executableURL!.deletingLastPathComponent()
}

let outputDirectory = outputRoot.appendingPathComponent("\(foundationVariant)-\(foundationPlatformVersion)", isDirectory: true)

try! FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)

// 3. Generate the fixtures.
// Fixture objects are defined in TestFoundation/FixtureValues.swift, which needs to be compiled into this module.

for fixture in Fixtures.all {
    let outputFile = outputDirectory.appendingPathComponent(fixture.identifier, isDirectory: false).appendingPathExtension("archive")
    print(" == Archiving fixture: \(fixture.identifier) to \(outputFile.path)")
    
    let value = try! fixture.make()

    let data = try! NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: fixture.supportsSecureCoding)
    
    try! data.write(to: outputFile)
}
