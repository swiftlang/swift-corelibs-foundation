//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

import XCTest

class TestFileManager : XCTestCase {
    func testReplaceItem() {
        let fm = FileManager.default
        
        // Temporary directory
        let dirPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(NSUUID().uuidString)
        try! fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        defer { try! FileManager.default.removeItem(atPath: dirPath) }
        
        let filePath = (dirPath as NSString).appendingPathComponent("temp_file")
        try! "1".write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        let newItemPath = (dirPath as NSString).appendingPathComponent("temp_file_new")
        try! "2".write(toFile: newItemPath, atomically: true, encoding: String.Encoding.utf8)
        
        let result = try! fm.replaceItemAt(URL(fileURLWithPath:filePath, isDirectory:false), withItemAt:URL(fileURLWithPath:newItemPath, isDirectory:false))
        XCTAssertEqual(result!.path, filePath)
        
        let fromDisk = try! String(contentsOf: URL(fileURLWithPath:filePath, isDirectory:false), encoding: String.Encoding.utf8)
        XCTAssertEqual(fromDisk, "2")

    }
    
    func testReplaceItem_error() {
        let fm = FileManager.default
        
        // Temporary directory
        let dirPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(NSUUID().uuidString)
        try! fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        defer { try! FileManager.default.removeItem(atPath: dirPath) }
        
        let filePath = (dirPath as NSString).appendingPathComponent("temp_file")
        try! "1".write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        let newItemPath = (dirPath as NSString).appendingPathComponent("temp_file_new")
        // Don't write the file.
        
        var threw = false
        do {
            let _ = try fm.replaceItemAt(URL(fileURLWithPath:filePath, isDirectory:false), withItemAt:URL(fileURLWithPath:newItemPath, isDirectory:false))
        } catch {
            threw = true
        }
        XCTAssertTrue(threw, "Should have thrown")

    }
    
    func testDirectoryEnumerator_error() {
        let fm = FileManager.default
        let nonexistentURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/nonexistent")
        
        var invoked = false
        let e = fm.enumerator(at: nonexistentURL, includingPropertiesForKeys: []) { (url, err) in
            invoked = true
            XCTAssertEqual(nonexistentURL, url)
            XCTAssertEqual((err as NSError).code, NSFileReadNoSuchFileError)
            return true
        }

        let url = e?.nextObject()
        XCTAssertTrue(invoked)
        XCTAssertTrue(url == nil)
        
    }

    func testDirectoryEnumerator_error_noHandler() {
        let fm = FileManager.default
        let nonexistentURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/nonexistent")
        
        let e = fm.enumerator(at: nonexistentURL, includingPropertiesForKeys: [])
        let url = e?.nextObject()
        XCTAssertTrue(url == nil)
        
    }
    
    func testDirectoryEnumerator_simple() {
        let fm = FileManager.default
        let dirPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(NSUUID().uuidString)
        try! fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        defer { try! FileManager.default.removeItem(atPath: dirPath) }

        let item1 = URL(fileURLWithPath: "\(dirPath)/1", isDirectory: false)
        let item2 = URL(fileURLWithPath: "\(dirPath)/2", isDirectory: false)
        
        try! Data().write(to: item1)
        try! Data().write(to: item2)
        
        let e = fm.enumerator(at: URL(fileURLWithPath: dirPath, isDirectory: true), includingPropertiesForKeys: [])
        let result1 = e?.nextObject()
        let result2 = e?.nextObject()
        let result3 = e?.nextObject()
        
        // Avoid potential symlink discrepancy between the result and the original URL
        XCTAssertEqual((result1! as! URL).lastPathComponent, item1.lastPathComponent)
        XCTAssertEqual((result2! as! URL).lastPathComponent, item2.lastPathComponent)
        XCTAssertTrue(result3 == nil)
        
    }

}
