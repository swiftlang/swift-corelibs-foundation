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

class TestURL : XCTestCase {
    
    func testBasics() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        
        XCTAssertTrue(url.pathComponents.count > 0)
    }
    
    func testProperties() {
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
        
        // Modify an existing resource value
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
    }
    
#if os(macOS)
    func testQuarantineProperties() {
        // Test the quarantine stuff; it has special logic
        if #available(OSX 10.11, iOS 9.0, *) {
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

            // Set the quarantine info on a file
            do {
                var resourceValues = URLResourceValues()
                resourceValues.quarantineProperties = ["LSQuarantineAgentName" : "TestURL"]
                try file.setResourceValues(resourceValues)
            } catch {
                XCTAssertTrue(false, "Unable to set quarantine info")
            }
            
            // Get the quarantine info back
            do {
                var resourceValues = try file.resourceValues(forKeys: [.quarantinePropertiesKey])
                XCTAssertEqual(resourceValues.quarantineProperties?["LSQuarantineAgentName"] as? String, "TestURL")
            } catch {
                XCTAssertTrue(false, "Unable to get quarantine info")
            }
            
            // Clear the quarantine info
            do {
                var resourceValues = URLResourceValues()
                resourceValues.quarantineProperties = nil // this effectively sets a flag
                try file.setResourceValues(resourceValues)
                
                // Make sure that the resourceValues property returns nil
                XCTAssertNil(resourceValues.quarantineProperties)
            } catch {
                XCTAssertTrue(false, "Unable to clear quarantine info")
            }

            // Get the quarantine info back again
            do {
                var resourceValues = try file.resourceValues(forKeys: [.quarantinePropertiesKey])
                XCTAssertNil(resourceValues.quarantineProperties)
            } catch {
                XCTAssertTrue(false, "Unable to get quarantine info after clearing")
            }

        }
    }
#endif
    
    func testMoreSetProperties() {
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

    }
    
    func testURLComponents() {
        // Not meant to be a test of all URL components functionality, just some basic bridging stuff
        let s = "http://www.apple.com/us/search/ipad?src=global%7Cnav"
        var components = URLComponents(string: s)!
        XCTAssertNotNil(components)
        
        XCTAssertNotNil(components.host)
        XCTAssertEqual("www.apple.com", components.host)
        
        
        if #available(OSX 10.11, iOS 9.0, *) {
            let rangeOfHost = components.rangeOfHost!
            XCTAssertNotNil(rangeOfHost)
            XCTAssertEqual(s[rangeOfHost], "www.apple.com")
        }
        
        if #available(OSX 10.10, iOS 8.0, *) {
            let qi = components.queryItems!
            XCTAssertNotNil(qi)
            
            XCTAssertEqual(1, qi.count)
            let first = qi[0]
            
            XCTAssertEqual("src", first.name)
            XCTAssertNotNil(first.value)
            XCTAssertEqual("global|nav", first.value)
        }

        if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
            components.percentEncodedQuery = "name1%E2%80%A2=value1%E2%80%A2&name2%E2%80%A2=value2%E2%80%A2"
            var qi = components.queryItems!
            XCTAssertNotNil(qi)
            
            XCTAssertEqual(2, qi.count)
            
            XCTAssertEqual("name1•", qi[0].name)
            XCTAssertNotNil(qi[0].value)
            XCTAssertEqual("value1•", qi[0].value)
            
            XCTAssertEqual("name2•", qi[1].name)
            XCTAssertNotNil(qi[1].value)
            XCTAssertEqual("value2•", qi[1].value)
            
            qi = components.percentEncodedQueryItems!
            XCTAssertNotNil(qi)
            
            XCTAssertEqual(2, qi.count)
            
            XCTAssertEqual("name1%E2%80%A2", qi[0].name)
            XCTAssertNotNil(qi[0].value)
            XCTAssertEqual("value1%E2%80%A2", qi[0].value)
            
            XCTAssertEqual("name2%E2%80%A2", qi[1].name)
            XCTAssertNotNil(qi[0].value)
            XCTAssertEqual("value2%E2%80%A2", qi[1].value)
            
            qi[0].name = "%E2%80%A2name1"
            qi[0].value = "%E2%80%A2value1"
            qi[1].name = "%E2%80%A2name2"
            qi[1].value = "%E2%80%A2value2"
            
            components.percentEncodedQueryItems = qi
            
            XCTAssertEqual("%E2%80%A2name1=%E2%80%A2value1&%E2%80%A2name2=%E2%80%A2value2", components.percentEncodedQuery)
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
    }

    func test_AnyHashableContainingURL() {
        let values: [URL] = [
            URL(string: "https://example.com/")!,
            URL(string: "https://example.org/")!,
            URL(string: "https://example.org/")!,
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(URL.self, type(of: anyHashables[0].base))
        expectEqual(URL.self, type(of: anyHashables[1].base))
        expectEqual(URL.self, type(of: anyHashables[2].base))
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
        expectEqual(URL.self, type(of: anyHashables[0].base))
        expectEqual(URL.self, type(of: anyHashables[1].base))
        expectEqual(URL.self, type(of: anyHashables[2].base))
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
        expectEqual(URLComponents.self, type(of: anyHashables[0].base))
        expectEqual(URLComponents.self, type(of: anyHashables[1].base))
        expectEqual(URLComponents.self, type(of: anyHashables[2].base))
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
        expectEqual(URLComponents.self, type(of: anyHashables[0].base))
        expectEqual(URLComponents.self, type(of: anyHashables[1].base))
        expectEqual(URLComponents.self, type(of: anyHashables[2].base))
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
            expectEqual(URLQueryItem.self, type(of: anyHashables[0].base))
            expectEqual(URLQueryItem.self, type(of: anyHashables[1].base))
            expectEqual(URLQueryItem.self, type(of: anyHashables[2].base))
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
            expectEqual(URLQueryItem.self, type(of: anyHashables[0].base))
            expectEqual(URLQueryItem.self, type(of: anyHashables[1].base))
            expectEqual(URLQueryItem.self, type(of: anyHashables[2].base))
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
        expectEqual(URLRequest.self, type(of: anyHashables[0].base))
        expectEqual(URLRequest.self, type(of: anyHashables[1].base))
        expectEqual(URLRequest.self, type(of: anyHashables[2].base))
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
        expectEqual(URLRequest.self, type(of: anyHashables[0].base))
        expectEqual(URLRequest.self, type(of: anyHashables[1].base))
        expectEqual(URLRequest.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
