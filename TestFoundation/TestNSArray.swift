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



class TestNSArray : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_getObjects", test_getObjects),
            ("test_objectAtIndex", test_objectAtIndex)
        ]
    }
    
    func test_BasicConstruction() {
        let array = NSArray()
        let array2 : NSArray = ["foo", "bar"].bridge()
        XCTAssertEqual(array.count, 0)
        XCTAssertEqual(array2.count, 2)
    }
    
    func test_enumeration() {
        let array : NSArray = ["foo", "bar", "baz"].bridge()
        let e = array.objectEnumerator()
        XCTAssertEqual((e.nextObject() as! NSString).bridge(), "foo")
        XCTAssertEqual((e.nextObject() as! NSString).bridge(), "bar")
        XCTAssertEqual((e.nextObject() as! NSString).bridge(), "baz")
        XCTAssertNil(e.nextObject())
        XCTAssertNil(e.nextObject())
        
        let r = array.reverseObjectEnumerator()
        XCTAssertEqual((r.nextObject() as! NSString).bridge(), "baz")
        XCTAssertEqual((r.nextObject() as! NSString).bridge(), "bar")
        XCTAssertEqual((r.nextObject() as! NSString).bridge(), "foo")
        XCTAssertNil(r.nextObject())
        XCTAssertNil(r.nextObject())
        
        let empty = NSArray().objectEnumerator()
        XCTAssertNil(empty.nextObject())
        XCTAssertNil(empty.nextObject())
        
        let reverseEmpty = NSArray().reverseObjectEnumerator()
        XCTAssertNil(reverseEmpty.nextObject())
        XCTAssertNil(reverseEmpty.nextObject())
    }
    
    func test_sequenceType() {
        let array : NSArray = ["foo", "bar", "baz"].bridge()
        var res = [String]()
        for obj in array {
            res.append((obj as! NSString).bridge())
        }
        XCTAssertEqual(res, ["foo", "bar", "baz"])
    }

    func test_getObjects() {
        let array : NSArray = ["foo", "bar", "baz", "foo1", "bar2", "baz3",].bridge()
        var objects = [AnyObject]()
        array.getObjects(&objects, range: NSMakeRange(1, 3))
        XCTAssertEqual(objects.count, 3)
        let fetched = [
            (objects[0] as! NSString).bridge(),
            (objects[1] as! NSString).bridge(),
            (objects[2] as! NSString).bridge(),
        ]
        XCTAssertEqual(fetched, ["bar", "baz", "foo1"])
    }
    
    func test_objectAtIndex() {
        let array : NSArray = ["foo", "bar"].bridge()
        let foo = array.objectAtIndex(0) as! NSString
        XCTAssertEqual(foo, "foo")
        
        let bar = array.objectAtIndex(1) as! NSString
        XCTAssertEqual(bar, "bar")
    }

}
