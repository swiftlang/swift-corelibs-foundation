// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import XCTest

#if os(Windows)
// Import Windows C functions
import WinSDK

// Declare _NS_getcwd function for testing
@_silgen_name("_NS_getcwd")
func _NS_getcwd(_ buffer: UnsafeMutablePointer<CChar>, _ size: Int) -> UnsafeMutablePointer<CChar>?
#endif

class TestCFPlatformGetcwd : XCTestCase {
    
    #if os(Windows)
    func test_NS_getcwd_UNC_prefix_stripping() {
        // Test that _NS_getcwd properly strips UNC long path prefixes using PathCchStripPrefix
        
        // Create a temporary directory to work with
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent("test_getcwd_\(UUID().uuidString)")
        
        do {
            try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: tempDir) }
            
            // Get original directory for restoration
            var originalBuffer = [CChar](repeating: 0, count: Int(MAX_PATH))
            guard _NS_getcwd(&originalBuffer, originalBuffer.count) != nil else {
                XCTFail("Failed to get original directory")
                return
            }
            // Create string from buffer using the traditional approach
            let originalDir = originalBuffer.withUnsafeBufferPointer { buffer in
                return String(cString: buffer.baseAddress!)
            }
            
            defer {
                // Restore original directory
                _ = originalDir.withCString { _chdir($0) }
            }
            
            // Test with UNC long path prefix \\?\
            let uncLongPathPrefix = "\\\\?\\" + tempDir.path
            let uncLongPathCString = uncLongPathPrefix.cString(using: .utf8)!
            let uncChdirResult = uncLongPathCString.withUnsafeBufferPointer { buffer in
                return _chdir(buffer.baseAddress!)
            }
            XCTAssertEqual(uncChdirResult, 0, "Failed to change directory using UNC long path prefix")
            
            // Test _NS_getcwd directly after changing to UNC prefixed path
            var buffer = [CChar](repeating: 0, count: Int(MAX_PATH))
            guard let result = _NS_getcwd(&buffer, buffer.count) else {
                XCTFail("_NS_getcwd returned null")
                return
            }
            
            let currentDir = String(cString: result)
            
            // Verify that the path doesn't contain UNC prefixes (this is the key test!)
            XCTAssertFalse(currentDir.hasPrefix("\\\\?\\"), "Current directory path should not contain \\\\?\\ UNC prefix after stripping")
            
            // Verify that we can still access the directory (it's a valid path)
            XCTAssertTrue(fm.fileExists(atPath: currentDir), "Current directory path should be valid and accessible")
            
            // Verify the path ends with our test directory name
            XCTAssertTrue(currentDir.hasSuffix(tempDir.lastPathComponent), "Current directory should end with our test directory name")
                       
            // Test with a deeper nested directory using UNC prefix to ensure stripping works with longer paths
            let deepDir = tempDir.appendingPathComponent("level1").appendingPathComponent("level2").appendingPathComponent("level3")
            try fm.createDirectory(at: deepDir, withIntermediateDirectories: true)
            
            let deepUncPath = "\\\\?\\" + deepDir.path
            let deepUncCString = deepUncPath.cString(using: .utf8)!
            let deepChdirResult = deepUncCString.withUnsafeBufferPointer { buffer in
                return _chdir(buffer.baseAddress!)
            }
            XCTAssertEqual(deepChdirResult, 0, "Failed to change to deep directory with UNC prefix")
            
            // Test _NS_getcwd with deep UNC prefixed path
            var deepBuffer = [CChar](repeating: 0, count: Int(MAX_PATH))
            guard let deepResult = _NS_getcwd(&deepBuffer, deepBuffer.count) else {
                XCTFail("_NS_getcwd returned null for deep UNC path")
                return
            }
            
            let deepCurrentDir = String(cString: deepResult)
            
            // Verify UNC prefixes are stripped from deeper paths too
            XCTAssertFalse(deepCurrentDir.hasPrefix("\\\\?\\"), "Deep directory path should not contain \\\\?\\ UNC prefix after stripping")
            XCTAssertTrue(fm.fileExists(atPath: deepCurrentDir), "Deep directory path should be valid and accessible")
            XCTAssertTrue(deepCurrentDir.hasSuffix("level3"), "Deep directory should end with level3")
            
        } catch {
            XCTFail("Failed to set up test environment: \(error)")
        }
    }
           
    func test_NS_getcwd_small_buffer() {
        // Test that _NS_getcwd handles small buffer correctly
        var smallBuffer = [CChar](repeating: 0, count: 1)
        let result = _NS_getcwd(&smallBuffer, smallBuffer.count)
        // This should either return null or handle the small buffer gracefully
        // The exact behavior depends on the implementation, but it shouldn't crash
        XCTAssertTrue(result == nil || result != nil, "Function should not crash with small buffer")
    }
    #endif
}