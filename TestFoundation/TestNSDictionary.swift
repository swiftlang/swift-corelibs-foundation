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
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_ArrayConstruction", test_ArrayConstruction),
            ("test_description", test_description),
            ("test_enumeration", test_enumeration),
            ("test_equality", test_equality),
            ("test_copying", test_copying),
            ("test_mutableCopying", test_mutableCopying),
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

    func test_equality() {
        let keys = ["foo", "whiz", "toil"].bridge().bridge()
        let objects1 = ["bar", "bang", "trouble"].bridge().bridge()
        let objects2 = ["bar", "bang", "troubl"].bridge().bridge()
        let dict1 = NSDictionary(objects: objects1, forKeys: keys.map({ $0 as! NSObject}))
        let dict2  = NSDictionary(objects: objects1, forKeys: keys.map({ $0 as! NSObject}))
        let dict3  = NSDictionary(objects: objects2, forKeys: keys.map({ $0 as! NSObject}))

        XCTAssertTrue(dict1 == dict2)
        XCTAssertTrue(dict1.isEqual(dict2))
        XCTAssertTrue(dict1.isEqualToDictionary(dict2.bridge()))
        XCTAssertEqual(dict1.hash, dict2.hash)
        XCTAssertEqual(dict1.hashValue, dict2.hashValue)

        XCTAssertFalse(dict1 == dict3)
        XCTAssertFalse(dict1.isEqual(dict3))
        XCTAssertFalse(dict1.isEqualToDictionary(dict3.bridge()))

        XCTAssertFalse(dict1.isEqual(nil))
        XCTAssertFalse(dict1.isEqual(NSObject()))
    }

    func test_copying() {
        let inputDictionary : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()

        let copy: NSDictionary = inputDictionary.copy() as! NSDictionary
        XCTAssertTrue(inputDictionary === copy)

        let dictMutableCopy = inputDictionary.mutableCopy() as! NSMutableDictionary
        let dictCopy2 = dictMutableCopy.copy() as! NSDictionary
        XCTAssertTrue(dictCopy2.dynamicType === NSDictionary.self)
        XCTAssertFalse(dictMutableCopy === dictCopy2)
        XCTAssertTrue(dictMutableCopy == dictCopy2)
    }

    func test_mutableCopying() {
        let inputDictionary : NSDictionary = ["foo" : "bar", "whiz" : "bang", "toil" : "trouble"].bridge()

        let dictMutableCopy1 = inputDictionary.mutableCopy() as! NSMutableDictionary
        XCTAssertTrue(dictMutableCopy1.dynamicType === NSMutableDictionary.self)
        XCTAssertFalse(inputDictionary === dictMutableCopy1)
        XCTAssertTrue(inputDictionary == dictMutableCopy1)

        let dictMutableCopy2 = dictMutableCopy1.mutableCopy() as! NSMutableDictionary
        XCTAssertTrue(dictMutableCopy2.dynamicType === NSMutableDictionary.self)
        XCTAssertFalse(dictMutableCopy2 === dictMutableCopy1)
        XCTAssertTrue(dictMutableCopy2 == dictMutableCopy1)
    }

}
