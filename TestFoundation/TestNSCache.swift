// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSCache : XCTestCase {
    
    static var allTests: [(String, (TestNSCache) -> () throws -> Void)] {
        return [
            ("test_setWithUnmutableKeys", test_setWithUnmutableKeys),
            ("test_setWithMutableKeys", test_setWithMutableKeys),
//            ("test_countLimit", test_countLimit),
        ]
    }
    
    func test_setWithUnmutableKeys() {
        let cache = NSCache<NSString, NSString>()
        
        var key1 = NSString(string: "key")
        var key2 = NSString(string: "key")
        var value = NSString(string: "value")
        
        cache.setObject(value, forKey: key1)
        
        XCTAssertEqual(cache.object(forKey: key1), value, "should be equal to \(value) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value) when using second key")
        
        value = NSString(string: "value1")
        cache.setObject(value, forKey: key2)
        
        XCTAssertEqual(cache.object(forKey: key1), value, "should be equal to \(value) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value) when using second key")
        
        key1 = "kkey"
        key2 = "kkey"
        let value1 = NSString(string: "value1")
        let value2 = NSString(string: "value1")
        cache.setObject(value1, forKey: key1)
        
        XCTAssertEqual(cache.object(forKey: key1), value1, "should be equal to \(value1) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value1, "should be equal to \(value1) when using second key")
        XCTAssertEqual(cache.object(forKey: key1), value2, "should be equal to \(value1) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value2, "should be equal to \(value1) when using second key")
    }
    
    func test_setWithMutableKeys() {
        let cache = NSCache<NSMutableString, NSString>()
        
        let key1 = NSMutableString(string: "key")
        let key2 = NSMutableString(string: "key")
        let value = NSString(string: "value")
        
        cache.setObject(value, forKey: key1)
        
        XCTAssertEqual(cache.object(forKey: key1), value, "should be equal to \(value) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value) when using second key")
        
        key1.append("1")
        
        XCTAssertEqual(cache.object(forKey: key1), value, "should be equal to \(value) when using first key")
        XCTAssertNil(cache.object(forKey: key2), "should be nil")
    }
    
    func test_countLimit() {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 1
        
        let key1 = NSString(string: "key1")
        let key2 = NSString(string: "key2")
        let value = NSString(string: "value")
        
        cache.setObject(value, forKey: key1)
        cache.setObject(value, forKey: key2)
        
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value)")
        XCTAssertNil(cache.object(forKey: key1), "should be nil")

    }
}
