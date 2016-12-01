// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestURL : XCTestCase {
    static var allTests: [(String, (TestURL) -> () throws -> Void)] {
        return [
            ("testBasics", testBasics),
            ("testProperties", testProperties),
            ("testSetProperties", testSetProperties),
            ("testMoreSetProperties", testMoreSetProperties),
            ("testURLComponents", testURLComponents),
            ("testURLResourceValues", testURLResourceValues),
            ("test_AnyHashableContainingURL", test_AnyHashableContainingURL),
            ("test_AnyHashableCreatedFromNSURL", test_AnyHashableCreatedFromNSURL),
            ("test_AnyHashableContainingURLComponents", test_AnyHashableContainingURLComponents),
            ("test_AnyHashableCreatedFromNSURLComponents", test_AnyHashableCreatedFromNSURLComponents),
            ("test_AnyHashableContainingURLQueryItem", test_AnyHashableContainingURLQueryItem),
            ("test_AnyHashableCreatedFromNSURLQueryItem", test_AnyHashableCreatedFromNSURLQueryItem),
            ("test_AnyHashableContainingURLRequest", test_AnyHashableContainingURLRequest),
            ("test_AnyHashableCreatedFromNSURLRequest", test_AnyHashableCreatedFromNSURLRequest),
        ]
    }
    
    func testBasics() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        
        XCTAssertTrue(url.pathComponents.count > 0)
    }
    
    func testProperties() {
#if !DEPLOYMENT_RUNTIME_SWIFT // not implemented
        let url = URL(fileURLWithPath: "/")
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isVolumeKey, .nameKey])
            if let isVolume = resourceValues.isVolume {
                XCTAssertTrue(isVolume)
            }
            XCTAssertNotNil(resourceValues.name)
        } catch {
            XCTAssertTrue(false, "Should not have thrown")
        }
#endif
    }
    
    func testSetProperties() {
        // Create a temporary file
        var file = URL(fileURLWithPath: NSTemporaryDirectory())
        let name = "my_great_file" + UUID().uuidString
        file.appendPathComponent(name)
        let data = Data(bytes: [1, 2, 3, 4, 5])
        do {
            try data.write(to: file)
        } catch {
            XCTAssertTrue(false, "Unable to write data")
        }
#if !DEPLOYMENT_RUNTIME_SWIFT // not implemented
        // Modify an existing resource values
        do {
            var resourceValues = try file.resourceValues(forKeys: [.nameKey])
            XCTAssertNotNil(resourceValues.name)
            XCTAssertEqual(resourceValues.name!, name)
            
            let newName = "goodbye cruel " + UUID().uuidString
            resourceValues.name = newName
            try file.setResourceValues(resourceValues)
        } catch {
            XCTAssertTrue(false, "Unable to set resources")
        }
#endif
    }
    
    func testMoreSetProperties() {
#if !DEPLOYMENT_RUNTIME_SWIFT // not implemented
        // Create a temporary file
        var file = URL(fileURLWithPath: NSTemporaryDirectory())
        let name = "my_great_file" + UUID().uuidString
        file.appendPathComponent(name)
        let data = Data(bytes: [1, 2, 3, 4, 5])
        do {
            try data.write(to: file)
        } catch {
            XCTAssertTrue(false, "Unable to write data")
        }
        
        do {
            var resourceValues = try file.resourceValues(forKeys: [.labelNumberKey])
            XCTAssertNotNil(resourceValues.labelNumber)
            
            // set label number
            resourceValues.labelNumber = 1
            try file.setResourceValues(resourceValues)
            
            // get label number
            let _ = try file.resourceValues(forKeys: [.labelNumberKey])
            XCTAssertNotNil(resourceValues.labelNumber)
            XCTAssertEqual(resourceValues.labelNumber!, 1)
        } catch (let e as NSError) {
            XCTAssertTrue(false, "Unable to load or set resources \(e)")
        } catch {
            XCTAssertTrue(false, "Unable to load or set resources (mysterious error)")
        }
        
        // Construct values from scratch
        do {
            var resourceValues = URLResourceValues()
            resourceValues.labelNumber = 2
            
            try file.setResourceValues(resourceValues)
            let resourceValues2 = try file.resourceValues(forKeys: [.labelNumberKey])
            XCTAssertNotNil(resourceValues2.labelNumber)
            XCTAssertEqual(resourceValues2.labelNumber!, 2)
        } catch (let e as NSError) {
            XCTAssertTrue(false, "Unable to load or set resources \(e)")
        } catch {
            XCTAssertTrue(false, "Unable to load or set resources (mysterious error)")
        }
        
        do {
            try FileManager.default.removeItem(at: file)
        } catch {
            XCTAssertTrue(false, "Unable to remove file")
        }
#endif
    }
    
    func testURLComponents() {
        // Not meant to be a test of all URL components functionality, just some basic bridging stuff
        let s = "http://www.apple.com/us/search/ipad?src=globalnav"
        let components = URLComponents(string: s)!
        XCTAssertNotNil(components)
        
        XCTAssertNotNil(components.host)
        XCTAssertEqual("www.apple.com", components.host)
        
        
        if #available(OSX 10.11, iOS 9.0, *) {
            let rangeOfHost = components.rangeOfHost!
            XCTAssertNotNil(rangeOfHost)
            XCTAssertEqual(s[rangeOfHost], "www.apple.com")
        }
        
        if #available(OSX 10.10, iOS 8.0, *) {
#if !DEPLOYMENT_RUNTIME_SWIFT // crashes in CF because of an invalid object
            let qi = components.queryItems!
            XCTAssertNotNil(qi)
            
            XCTAssertEqual(1, qi.count)
            let first = qi[0]
            
            XCTAssertEqual("src", first.name)
            XCTAssertNotNil(first.value)
            XCTAssertEqual("globalnav", first.value)
#endif
        }
    }
    
    func testURLResourceValues() {
        
        let fileName = "temp_file"
        var dir = URL(fileURLWithPath: NSTemporaryDirectory())
        dir.appendPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        
        dir.appendPathComponent(fileName)
        try! Data(bytes: [1,2,3,4]).write(to: dir)
        
        defer {
            do {
                try FileManager.default.removeItem(at: dir)
            } catch {
                // Oh well
            }
        }
        
#if !DEPLOYMENT_RUNTIME_SWIFT // resourceValues(forKeys:) is not implemented
        do {
            let values = try dir.resourceValues(forKeys: [.nameKey, .isDirectoryKey])
            XCTAssertEqual(values.name, fileName)
            XCTAssertFalse(values.isDirectory!)
            XCTAssertEqual(nil, values.creationDate) // Didn't ask for this
        } catch {
            XCTAssertTrue(false, "Unable to get resource value")
        }
        
        let originalDate : Date
        do {
            var values = try dir.resourceValues(forKeys: [.creationDateKey])
            XCTAssertNotEqual(nil, values.creationDate)
            originalDate = values.creationDate!
        } catch {
            originalDate = Date()
            XCTAssertTrue(false, "Unable to get creation date")
        }
        
        let newDate = originalDate + 100
        
        do {
            var values = URLResourceValues()
            values.creationDate = newDate
            try dir.setResourceValues(values)
        } catch {
            XCTAssertTrue(false, "Unable to set resource value")
        }
        
        do {
            let values = try dir.resourceValues(forKeys: [.creationDateKey])
            XCTAssertEqual(newDate, values.creationDate)
        } catch {
            XCTAssertTrue(false, "Unable to get values")
        }
#endif
    }
    
    func test_AnyHashableContainingURL() {
        let values: [URL] = [
            URL(string: "https://example.com/")!,
            URL(string: "https://example.org/")!,
            URL(string: "https://example.org/")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URL.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URL.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URL.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSURL() {
        let values: [NSURL] = [
            NSURL(string: "https://example.com/")!,
            NSURL(string: "https://example.org/")!,
            NSURL(string: "https://example.org/")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URL.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URL.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URL.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableContainingURLComponents() {
        let values: [URLComponents] = [
            URLComponents(string: "https://example.com/")!,
            URLComponents(string: "https://example.org/")!,
            URLComponents(string: "https://example.org/")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSURLComponents() {
        let values: [NSURLComponents] = [
            NSURLComponents(string: "https://example.com/")!,
            NSURLComponents(string: "https://example.org/")!,
            NSURLComponents(string: "https://example.org/")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URLComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableContainingURLQueryItem() {
        if #available(OSX 10.10, iOS 8.0, *) {
            let values: [URLQueryItem] = [
                URLQueryItem(name: "foo", value: nil),
                URLQueryItem(name: "bar", value: nil),
                URLQueryItem(name: "bar", value: nil),
                ]
            let anyHashables = values.map(AnyHashable.init)
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[0].base))
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[1].base))
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }
    
    func test_AnyHashableCreatedFromNSURLQueryItem() {
        if #available(OSX 10.10, iOS 8.0, *) {
            let values: [NSURLQueryItem] = [
                NSURLQueryItem(name: "foo", value: nil),
                NSURLQueryItem(name: "bar", value: nil),
                NSURLQueryItem(name: "bar", value: nil),
                ]
            let anyHashables = values.map(AnyHashable.init)
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[0].base))
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[1].base))
            XCTAssertSameType(URLQueryItem.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }
    
    func test_AnyHashableContainingURLRequest() {
        let values: [URLRequest] = [
            URLRequest(url: URL(string: "https://example.com/")!),
            URLRequest(url: URL(string: "https://example.org/")!),
            URLRequest(url: URL(string: "https://example.org/")!),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSURLRequest() {
        let values: [NSURLRequest] = [
            NSURLRequest(url: URL(string: "https://example.com/")!),
            NSURLRequest(url: URL(string: "https://example.org/")!),
            NSURLRequest(url: URL(string: "https://example.org/")!),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[0].base))
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[1].base))
        XCTAssertSameType(URLRequest.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}

