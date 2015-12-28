// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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



class TestNSDictionary : XCTestCase {
    
    var allTests : [(String, () -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_ArrayConstruction", test_ArrayConstruction),
            ("test_description", test_description),
            ("test_enumeration", test_enumeration),
            ("test_NSCopying", test_NSCopying),
            ("test_NSMutableCopying", test_NSMutableCopying),
        ]
    }
        
    func test_BasicConstruction() {
        let dict = NSDictionary()
         let dict2: NSDictionary = ["foo": "bar"].bridge()
        XCTAssertEqual(dict.count, 0)
        XCTAssertEqual(dict2.count, 1)
    }
    

    func test_description() {
        // Disabled due to [SR-251]
        // Assertion disabled since it fails on linux targets due to heterogenious collection conversion failure
        /*
        let d1: NSDictionary = [ "foo": "bar", "baz": "qux"].bridge()
        XCTAssertEqual(d1.description, "{\n    baz = qux;\n    foo = bar;\n}")
        let d2: NSDictionary = ["1" : ["1" : ["1" : "1"]]].bridge()
        XCTAssertEqual(d2.description, "{\n    1 =     {\n        1 =         {\n            1 = 1;\n        };\n    };\n}")
        */
    }

    func test_HeterogeneousConstruction() {
//        let dict2: NSDictionary = [
//            "foo": "bar",
//            1 : 2
//        ]
//        XCTAssertEqual(dict2.count, 2)
//        XCTAssertEqual(dict2["foo"] as? NSString, NSString(UTF8String:"bar"))
//        XCTAssertEqual(dict2[1] as? NSNumber, NSNumber(int: 2))
    }
    
    func test_ArrayConstruction() {
//        let objects = ["foo", "bar", "baz"]
//        let keys = ["foo", "bar", "baz"]
//        let dict = NSDictionary(objects: objects, forKeys: keys as [NSObject])
//        XCTAssertEqual(dict.count, 3)
    }
    
    func test_ObjectForKey() {
        // let dict: NSDictionary = [
        //     "foo" : "bar"
        // ]
    }
    
    func test_enumeration() {
        let dict : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()
        let e = dict.keyEnumerator()
        var keys = Set<String>()
        keys.insert((e.nextObject()! as! NSString).bridge())
        keys.insert((e.nextObject()! as! NSString).bridge())
        keys.insert((e.nextObject()! as! NSString).bridge())
        XCTAssertNil(e.nextObject())
        XCTAssertNil(e.nextObject())
        XCTAssertEqual(keys, ["foo", "whiz", "toil"])
        
        let o = dict.objectEnumerator()
        var objs = Set<String>()
        objs.insert((o.nextObject()! as! NSString).bridge())
        objs.insert((o.nextObject()! as! NSString).bridge())
        objs.insert((o.nextObject()! as! NSString).bridge())
        XCTAssertNil(o.nextObject())
        XCTAssertNil(o.nextObject())
        XCTAssertEqual(objs, ["bar", "bang", "trouble"])
    }
    
    func test_sequenceType() {
        let dict : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()
        var result = [String:String]()
        for (key, value) in dict {
            result[key as! String] = (value as! NSString).bridge()
        }
        XCTAssertEqual(result, ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"])
    }
    
    func test_NSCopying() {
        let dict1 : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()
        let dict2 : NSDictionary = dict1.copy() as! NSDictionary
        XCTAssertEqual(dict1, dict2)
        XCTAssert(dict1 === dict2, "dict1's copy should have returned self")
        
        // NSMutableDictionary copying
        let mutDict1 = NSMutableDictionary(objects: ["bar".bridge(), "bang".bridge(), "trouble".bridge()], forKeys: ["foo".bridge(), "whiz".bridge(), "toil".bridge()])
        let dict4 = mutDict1.copy() as! NSDictionary
        XCTAssertEqual(mutDict1, dict4)
        mutDict1.setObject("bubble".bridge(), forKey: "toil".bridge())
        XCTAssertNotEqual(mutDict1, dict4)
    }
    
    func test_NSMutableCopying() {
        let dict1 : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()
        
        let mutDict1 = dict1.mutableCopy() as! NSMutableDictionary
        XCTAssertEqual(dict1, mutDict1)
        
        mutDict1.setObject("bubble".bridge(), forKey: "toil".bridge())
        XCTAssertNotEqual(dict1, mutDict1)
        let mutDict2 = mutDict1.mutableCopy() as! NSMutableDictionary
        XCTAssertEqual(mutDict1, mutDict2)
        mutDict1.setObject("baz".bridge(), forKey: "foo".bridge())
        XCTAssertNotEqual(mutDict1, mutDict2)
    }
}