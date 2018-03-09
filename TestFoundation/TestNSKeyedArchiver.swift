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

public class NSUserClass : NSObject, NSSecureCoding {
    var ivar : Int
    
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    public func encode(with aCoder : NSCoder) {
        aCoder.encode(ivar, forKey:"$ivar") // also test escaping
    }
    
    init(_ value: Int) {
        self.ivar = value
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.ivar = aDecoder.decodeInteger(forKey: "$ivar")
    }
    
    public override var description: String {
        get {
            return "NSUserClass \(ivar)"
        }
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let custom = object as? NSUserClass {
            return self.ivar == custom.ivar
        } else {
            return false
        }
    }
}

public class UserClass : CustomStringConvertible, Equatable, Hashable, NSSecureCoding {
    var ivar : Int
    
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    public func encode(with aCoder : NSCoder) {
        aCoder.encode(ivar, forKey:"$ivar") // also test escaping
    }
    
    init(_ value: Int) {
        self.ivar = value
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.ivar = aDecoder.decodeInteger(forKey: "$ivar")
    }
    
    public var description: String {
        get {
            return "UserClass \(ivar)"
        }
    }
    
    public static func ==(lhs: UserClass, rhs: UserClass) -> Bool {
        return lhs.ivar == rhs.ivar
    }
    
    public var hashValue: Int {
        return ivar
    }
}

class TestNSKeyedArchiver : XCTestCase {
    static var allTests: [(String, (TestNSKeyedArchiver) -> () throws -> Void)] {
        return [
            ("test_archive_array", test_archive_array),
            ("test_archive_charptr", test_archive_charptr),
            ("test_archive_concrete_value", test_archive_concrete_value),
            ("test_archive_dictionary", test_archive_dictionary),
            ("test_archive_generic_objc", test_archive_generic_objc),
            ("test_archive_locale", test_archive_locale),
            ("test_archive_string", test_archive_string),
            ("test_archive_mutable_array", test_archive_mutable_array),
            ("test_archive_mutable_dictionary", test_archive_mutable_dictionary),
            ("test_archive_ns_user_class", test_archive_ns_user_class),
            ("test_archive_nspoint", test_archive_nspoint),
            ("test_archive_nsrange", test_archive_nsrange),
            ("test_archive_nsrect", test_archive_nsrect),
            ("test_archive_null", test_archive_null),
            ("test_archive_set", test_archive_set),
            ("test_archive_url", test_archive_url),
            ("test_archive_user_class", test_archive_user_class),
            ("test_archive_uuid_bvref", test_archive_uuid_byref),
            ("test_archive_uuid_byvalue", test_archive_uuid_byvalue),
            ("test_archive_unhashable", test_archive_unhashable),
            ("test_archiveRootObject_String", test_archiveRootObject_String),
            ("test_archiveRootObject_URLRequest()", test_archiveRootObject_URLRequest),
        ]
    }

    private func test_archive(_ encode: (NSKeyedArchiver) -> Bool,
                              decode: (NSKeyedUnarchiver) -> Bool) {
        // Archiving using custom NSMutableData instance
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        
        XCTAssertTrue(encode(archiver))
        archiver.finishEncoding()
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: Data._unconditionallyBridgeFromObjectiveC(data))
        XCTAssertTrue(decode(unarchiver))
        
        // Archiving using the default initializer
        let archiver1 = NSKeyedArchiver()
        
        XCTAssertTrue(encode(archiver1))
        let archivedData = archiver1.encodedData
        
        let unarchiver1 = NSKeyedUnarchiver(forReadingWith: archivedData)
        XCTAssertTrue(decode(unarchiver1))
    }

    private func test_archive(_ object: Any, classes: [AnyClass], allowsSecureCoding: Bool = true, outputFormat: PropertyListSerialization.PropertyListFormat) {
        test_archive({ archiver -> Bool in
                archiver.requiresSecureCoding = allowsSecureCoding
                archiver.outputFormat = outputFormat
                archiver.encode(object, forKey: NSKeyedArchiveRootObjectKey)
                archiver.finishEncoding()
                return true
            },
            decode: { unarchiver -> Bool in
                unarchiver.requiresSecureCoding = allowsSecureCoding
                
                do {
                    guard let rootObj = try unarchiver.decodeTopLevelObject(of: classes, forKey: NSKeyedArchiveRootObjectKey) else {
                        XCTFail("Unable to decode data")
                        return false
                    }
                
                    XCTAssertEqual(object as? AnyHashable, rootObj as? AnyHashable, "unarchived object \(rootObj) does not match \(object)")
                } catch {
                    XCTFail("Error thrown: \(error)")
                }
                return true
        })
    }
    
    private func test_archive(_ object: Any, classes: [AnyClass], allowsSecureCoding: Bool = true) {
        // test both XML and binary encodings
        test_archive(object, classes: classes, allowsSecureCoding: allowsSecureCoding, outputFormat: PropertyListSerialization.PropertyListFormat.xml)
        test_archive(object, classes: classes, allowsSecureCoding: allowsSecureCoding, outputFormat: PropertyListSerialization.PropertyListFormat.binary)
    }
    
    private func test_archive(_ object: AnyObject, allowsSecureCoding: Bool = true) {
        return test_archive(object, classes: [type(of: object)], allowsSecureCoding: allowsSecureCoding)
    }
    
    func test_archive_array() {
        let array = NSArray(array: ["one", "two", "three"])
        test_archive(array)
    }
    
    func test_archive_concrete_value() {
        let array: Array<UInt64> = [12341234123, 23452345234, 23475982345, 9893563243, 13469816598]
        let objctype = "[5Q]"
        array.withUnsafeBufferPointer { cArray in
            let concrete = NSValue(bytes: cArray.baseAddress!, objCType: objctype)
            test_archive(concrete)
        }
    }
    
    func test_archive_dictionary() {
        let dictionary = NSDictionary(dictionary: ["one" : 1, "two" : 2, "three" : 3])
        test_archive(dictionary)
    }
    
    func test_archive_generic_objc() {
        let array: Array<Int32> = [1234, 2345, 3456, 10000]

        test_archive({ archiver -> Bool in
            array.withUnsafeBufferPointer { cArray in
                archiver.encodeValue(ofObjCType: "[4i]", at: cArray.baseAddress!)
            }
            return true
        },
        decode: {unarchiver -> Bool in
            var expected: Array<Int32> = [0, 0, 0, 0]
            expected.withUnsafeMutableBufferPointer {(p: inout UnsafeMutableBufferPointer<Int32>) in
                unarchiver.decodeValue(ofObjCType: "[4i]", at: UnsafeMutableRawPointer(p.baseAddress!))
            }
            XCTAssertEqual(expected, array)
            return true
            })
    }

    func test_archive_locale() {
        let locale = Locale.current
        test_archive(locale._bridgeToObjectiveC())
    }
    
    func test_archive_string() {
        let string = NSString(string: "hello")
        test_archive(string)
    }
    
    func test_archive_mutable_array() {
        let array = NSMutableArray(array: ["one", "two", "three"])
        test_archive(array)
    }

    func test_archive_mutable_dictionary() {
        let one: NSNumber = NSNumber(value: Int(1))
        let two: NSNumber = NSNumber(value: Int(2))
        let three: NSNumber = NSNumber(value: Int(3))
        let dict: [String : Any] = [
            "one": one,
            "two": two,
            "three": three,
        ]
        let mdictionary = NSMutableDictionary(dictionary: dict)
        test_archive(mdictionary)
    }
    
    func test_archive_nspoint() {
        let point = NSValue(point: NSPoint(x: CGFloat(20.0), y: CGFloat(35.0)))
        test_archive(point)
    }

    func test_archive_nsrange() {
        let range = NSValue(range: NSRange(location: 1234, length: 5678))
        test_archive(range)
    }
    
    func test_archive_nsrect() {
        let point = NSPoint(x: CGFloat(20.0), y: CGFloat(35.4))
        let size = NSSize(width: CGFloat(50.0), height: CGFloat(155.0))

        let rect = NSValue(rect: NSRect(origin: point, size: size))
        test_archive(rect)
    }

    func test_archive_null() {
        let null = NSNull()
        test_archive(null)
    }
    
    func test_archive_set() {
        let set = NSSet(array: [NSNumber(value: Int(1234234)),
                                NSNumber(value: Int(2374853)),
                                NSString(string: "foobarbarbar"),
                                NSValue(point: NSPoint(x: CGFloat(5.0), y: CGFloat(Double(1.5))))])
        test_archive(set, classes: [NSValue.self, NSSet.self])
    }
    
    func test_archive_url() {
        let url = NSURL(string: "index.html", relativeTo: URL(string: "http://www.apple.com"))!
        test_archive(url)
    }
    
    func test_archive_charptr() {
        let charArray = [CChar]("Hello world, we are testing!\0".utf8CString)
        var charPtr = UnsafeMutablePointer(mutating: charArray)

        test_archive({ archiver -> Bool in
                let value = NSValue(bytes: &charPtr, objCType: "*")
                
                archiver.encode(value, forKey: "root")
                return true
            },
             decode: {unarchiver -> Bool in
                guard let value = unarchiver.decodeObject(of: NSValue.self, forKey: "root") else {
                    return false
                }
                var expectedCharPtr: UnsafeMutablePointer<CChar>? = nil
                value.getValue(&expectedCharPtr)
                
                let s1 = String(cString: charPtr)
                let s2 = String(cString: expectedCharPtr!)

#if !DEPLOYMENT_RUNTIME_OBJC
                // On Darwin decoded strings would belong to the autorelease pool, but as we don't have
                // one in SwiftFoundation let's explicitly deallocate it here.
                expectedCharPtr!.deallocate()
#endif
                return s1 == s2
        })
    }
    
    func test_archive_user_class() {
#if !DARWIN_COMPATIBILITY_TESTS  // Causes SIGABRT
        let userClass = UserClass(1234)
        test_archive(userClass)
#endif
    }
    
    func test_archive_ns_user_class() {
        let nsUserClass = NSUserClass(5678)
        test_archive(nsUserClass)
    }
    
    func test_archive_uuid_byref() {
        let uuid = NSUUID()
        test_archive(uuid)
    }
    
    func test_archive_uuid_byvalue() {
        let uuid = UUID()
        return test_archive(uuid, classes: [NSUUID.self])
    }

    func test_archive_unhashable() {
        let data = """
            {
              "args": {},
              "headers": {
                "Accept": "*/*",
                "Accept-Encoding": "deflate, gzip",
                "Accept-Language": "en",
                "Connection": "close",
                "Host": "httpbin.org",
                "User-Agent": "TestFoundation (unknown version) curl/7.54.0"
              },
              "origin": "0.0.0.0",
              "url": "https://httpbin.org/get"
            }
            """.data(using: .utf8)!
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            _ = NSKeyedArchiver.archivedData(withRootObject: json)
            XCTAssert(true, "NSKeyedArchiver.archivedData handles unhashable")
        }
        catch {
            XCTFail("test_archive_unhashable, de-serialization error \(error)")
        }
    }

    func test_archiveRootObject_String() {
        let filePath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        let result = NSKeyedArchiver.archiveRootObject("Hello", toFile: filePath)
        XCTAssertTrue(result)
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            XCTFail("Failed to clean up file")
        }
    }

    func test_archiveRootObject_URLRequest() {
        let filePath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        let url = URL(string: "http://swift.org")!
        let request = URLRequest(url: url)._bridgeToObjectiveC()
        let result = NSKeyedArchiver.archiveRootObject(request, toFile: filePath)
        XCTAssertTrue(result)
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            XCTFail("Failed to clean up file")
        }
    }

}
