// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSCache : XCTestCase {
    
    static var allTests: [(String, (TestNSCache) -> () throws -> Void)] {
        return [
            ("test_setWithUnmutableKeys", test_setWithUnmutableKeys),
            ("test_setWithMutableKeys", test_setWithMutableKeys),
            ("test_costLimit", test_costLimit),
            ("test_countLimit", test_countLimit),
            ("test_hashableKey", test_hashableKey),
            ("test_nonHashableKey", test_nonHashableKey),
            ("test_objectCorrectlyReleased", test_objectCorrectlyReleased)
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

        // Mutating the key probably changes the hash value, which often makes
        // the value inaccessible by sorting the key into a different bucket.
        // On the other hand, the bucket may remain the same by coincidence.
        // Therefore, `cache.object(forKey: key1)` may or may not be nil at 
        // this point -- no useful check can be made.
        // The object can definitely not be reached via the original key,
        // though.
        XCTAssertNil(cache.object(forKey: key2), "should be nil")

		// Restoring key1 to the original string will make the value 
		// accessible again.
        key1.setString("key")
        XCTAssertEqual(cache.object(forKey: key1), value, "should be equal to \(value) when using first key")
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value) when using second key")        
    }
    
    func test_costLimit() {
        let cache = NSCache<NSString, NSString>()
        cache.totalCostLimit = 10
        
        cache.setObject("object0", forKey: "0", cost: 4)
        cache.setObject("object2", forKey: "2", cost: 5)
        
        cache.setObject("object1", forKey: "1", cost: 5)
        
        XCTAssertNil(cache.object(forKey: "0"), "should be nil")
        XCTAssertEqual(cache.object(forKey: "2"), "object2", "should be equal to 'object2'")
        XCTAssertEqual(cache.object(forKey: "1"), "object1", "should be equal to 'object1'")
    }
    
    func test_countLimit() {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 2
        
        let key1 = NSString(string: "key1")
        let key2 = NSString(string: "key2")
        let key3 = NSString(string: "key3")
        let value = NSString(string: "value")
        
        cache.setObject(value, forKey: key1, cost: 1)
        cache.setObject(value, forKey: key2, cost: 2)
        cache.setObject(value, forKey: key3, cost: 3)
        
        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value)")
        XCTAssertEqual(cache.object(forKey: key3), value, "should be equal to \(value)")
        XCTAssertNil(cache.object(forKey: key1), "should be nil")
        
    }


    class TestHashableCacheKey: Hashable {
        let string: String
        var hashValue: Int { return string.hashValue }

        init(string: String) {
            self.string = string
        }

        static func ==(lhs: TestHashableCacheKey,
            rhs:TestHashableCacheKey) -> Bool {
            return lhs.string == rhs.string
        }
    }

    // Test when NSCacheKey.value is AnyHashable
    func test_hashableKey() {
        let cache = NSCache<TestHashableCacheKey, NSString>()
        cache.countLimit = 2

        let key1 = TestHashableCacheKey(string: "key1")
        let key2 = TestHashableCacheKey(string: "key2")
        let key3 = TestHashableCacheKey(string: "key3")
        let value = NSString(string: "value")

        cache.setObject(value, forKey: key1, cost: 1)
        cache.setObject(value, forKey: key2, cost: 2)
        cache.setObject(value, forKey: key3, cost: 3)

        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value)")
        XCTAssertEqual(cache.object(forKey: key3), value, "should be equal to \(value)")
        XCTAssertNil(cache.object(forKey: key1), "should be nil")
    }


    class TestCacheKey {
        let string: String

        init(string: String) {
            self.string = string
        }
    }

    // Test when NSCacheKey.value is neither NSObject or AnyHashable
    func test_nonHashableKey() {
        let cache = NSCache<TestCacheKey, NSString>()
        cache.countLimit = 2

        let key1 = TestCacheKey(string: "key1")
        let key2 = TestCacheKey(string: "key2")
        let key3 = TestCacheKey(string: "key3")
        let value = NSString(string: "value")

        cache.setObject(value, forKey: key1, cost: 1)
        cache.setObject(value, forKey: key2, cost: 2)
        cache.setObject(value, forKey: key3, cost: 3)

        XCTAssertEqual(cache.object(forKey: key2), value, "should be equal to \(value)")
        XCTAssertEqual(cache.object(forKey: key3), value, "should be equal to \(value)")
        XCTAssertNil(cache.object(forKey: key1), "should be nil")
    }
    
    func test_objectCorrectlyReleased() {
        let cache = NSCache<NSString, AnyObject>()
        cache.totalCostLimit = 10
        
        var object1 = NSObject()
        weak var weakObject1: NSObject? = object1
        
        var object2 = NSObject()
        weak var weakObject2: NSObject? = object2
        
        var object3 = NSObject()
        weak var weakObject3: NSObject? = object3
        
        let object4 = NSObject()
        let object5 = NSObject()
        
        cache.setObject(object1, forKey: "key1", cost: 1)
        cache.setObject(object2, forKey: "key2", cost: 2)
        cache.setObject(object3, forKey: "key3", cost: 3)
        cache.setObject(object4, forKey: "key4", cost: 4)
        cache.setObject(object5, forKey: "key5", cost: 5)
        
        object1 = NSObject()
        object2 = NSObject()
        object3 = NSObject()
        
        XCTAssertNil(weakObject1, "removed cached object not released")
        XCTAssertNil(weakObject2, "removed cached object not released")
        XCTAssertNil(weakObject3, "removed cached object not released")
    }
}
