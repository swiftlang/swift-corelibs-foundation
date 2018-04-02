// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
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

class TestUserDefaults : XCTestCase {
	static var allTests : [(String, (TestUserDefaults) -> () throws -> ())] {
		return [
			("test_createUserDefaults", test_createUserDefaults ),
			("test_getRegisteredDefaultItem", test_getRegisteredDefaultItem ),
			("test_getRegisteredDefaultItem_NSString", test_getRegisteredDefaultItem_NSString ),
			("test_getRegisteredDefaultItem_String", test_getRegisteredDefaultItem_String ),
			("test_getRegisteredDefaultItem_NSURL", test_getRegisteredDefaultItem_NSURL ),
			("test_getRegisteredDefaultItem_URL", test_getRegisteredDefaultItem_URL ),
			("test_getRegisteredDefaultItem_NSData", test_getRegisteredDefaultItem_NSData ),
			("test_getRegisteredDefaultItem_Data)", test_getRegisteredDefaultItem_Data ),
			("test_getRegisteredDefaultItem_BoolFromString", test_getRegisteredDefaultItem_BoolFromString ),
			("test_getRegisteredDefaultItem_IntFromString", test_getRegisteredDefaultItem_IntFromString ),
			("test_getRegisteredDefaultItem_DoubleFromString", test_getRegisteredDefaultItem_DoubleFromString ),
			("test_setValue_NSString", test_setValue_NSString ),
			("test_setValue_String", test_setValue_String ),
			("test_setValue_NSURL", test_setValue_NSURL ),
			("test_setValue_URL", test_setValue_URL ),
			("test_setValue_NSData", test_setValue_NSData ),
			("test_setValue_Data", test_setValue_Data ),
			("test_setValue_BoolFromString", test_setValue_BoolFromString ),
			("test_setValue_IntFromString", test_setValue_IntFromString ),
			("test_setValue_DoubleFromString", test_setValue_DoubleFromString ),
			("test_volatileDomains", test_volatileDomains),
			("test_persistentDomain", test_persistentDomain ),
		]
	}

	func test_createUserDefaults() {
		let defaults = UserDefaults.standard
		
		defaults.set(4, forKey: "ourKey")
	}
	
	func test_getRegisteredDefaultItem() {
		let defaults = UserDefaults.standard
		
		defaults.register(defaults: ["key1": NSNumber(value: Int(5))])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.integer(forKey: "key1"), 5)
	}
	
	func test_getRegisteredDefaultItem_NSString() {
		let defaults = UserDefaults.standard
		
		// Register a NSString value. UserDefaults.string(forKey:) is supposed to return the NSString as a String
		defaults.register(defaults: ["key1": "hello" as NSString])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.string(forKey: "key1"), "hello")
	}

	func test_getRegisteredDefaultItem_String() {
		let defaults = UserDefaults.standard
		
		// Register a String value. UserDefaults.string(forKey:) is supposed to return the String
		defaults.register(defaults: ["key1": "hello"])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.string(forKey: "key1"), "hello")
	}

	func test_getRegisteredDefaultItem_NSURL() {
		let defaults = UserDefaults.standard
		
		// Register an NSURL value. UserDefaults.url(forKey:) is supposed to return the URL
		defaults.register(defaults: ["key1": NSURL(fileURLWithPath: "/hello/world")])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.url(forKey: "key1"), URL(fileURLWithPath: "/hello/world"))
	}

	func test_getRegisteredDefaultItem_URL() {
		let defaults = UserDefaults.standard
		
		// Register an URL value. UserDefaults.url(forKey:) is supposed to return the URL
		defaults.register(defaults: ["key1": URL(fileURLWithPath: "/hello/world")])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.url(forKey: "key1"), URL(fileURLWithPath: "/hello/world"))
	}

	func test_getRegisteredDefaultItem_NSData() {
		let defaults = UserDefaults.standard
		let bytes = [0, 1, 2, 3, 4] as [UInt8]
		
		// Register an NSData value. UserDefaults.data(forKey:) is supposed to return the Data
		defaults.register(defaults: ["key1": NSData(bytes: bytes, length: bytes.count)])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.data(forKey: "key1"), Data(bytes: bytes))
	}
	
	func test_getRegisteredDefaultItem_Data() {
		let defaults = UserDefaults.standard
		let bytes = [0, 1, 2, 3, 4] as [UInt8]
		
		// Register a Data value. UserDefaults.data(forKey:) is supposed to return the Data
		defaults.register(defaults: ["key1": Data(bytes: bytes)])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.data(forKey: "key1"), Data(bytes: bytes))
	}

	func test_getRegisteredDefaultItem_BoolFromString() {
		let defaults = UserDefaults.standard
		
		// Register a boolean default value as a string. UserDefaults.bool(forKey:) is supposed to return the parsed Bool value
		defaults.register(defaults: ["key1": "YES"])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.bool(forKey: "key1"), true)
	}
	
	func test_getRegisteredDefaultItem_IntFromString() {
		let defaults = UserDefaults.standard
		
		// Register an int default value as a string. UserDefaults.integer(forKey:) is supposed to return the parsed Int value
		defaults.register(defaults: ["key1": "1234"])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.integer(forKey: "key1"), 1234)
	}
	
	func test_getRegisteredDefaultItem_DoubleFromString() {
		let defaults = UserDefaults.standard
		
		// Register a double default value as a string. UserDefaults.double(forKey:) is supposed to return the parsed Double value
		defaults.register(defaults: ["key1": "12.34"])
		
		//make sure we don't have anything in the saved plist.
		defaults.removeObject(forKey: "key1")
		
		XCTAssertEqual(defaults.double(forKey: "key1"), 12.34)
	}
	
	func test_setValue_NSString() {
		let defaults = UserDefaults.standard
		
		// Set a NSString value. UserDefaults.string(forKey:) is supposed to return the NSString as a String
		defaults.set("hello" as NSString, forKey: "key1")
		
		XCTAssertEqual(defaults.string(forKey: "key1"), "hello")
	}
	
	func test_setValue_String() {
		let defaults = UserDefaults.standard
		
		// Register a String value. UserDefaults.string(forKey:) is supposed to return the String
		defaults.set("hello", forKey: "key1")
		
		XCTAssertEqual(defaults.string(forKey: "key1"), "hello")
	}

	func test_setValue_NSURL() {
		let defaults = UserDefaults.standard
		
		// Set a NSURL value. UserDefaults.url(forKey:) is supposed to return the NSURL as a URL
		defaults.set(NSURL(fileURLWithPath: "/hello/world"), forKey: "key1")
		
		XCTAssertEqual(defaults.url(forKey: "key1"), URL(fileURLWithPath: "/hello/world"))
	}

	func test_setValue_URL() {
		let defaults = UserDefaults.standard
		
		// Set a URL value. UserDefaults.url(forKey:) is supposed to return the URL
		defaults.set(URL(fileURLWithPath: "/hello/world"), forKey: "key1")
		
		XCTAssertEqual(defaults.url(forKey: "key1"), URL(fileURLWithPath: "/hello/world"))
	}

	func test_setValue_NSData() {
		let defaults = UserDefaults.standard
		let bytes = [0, 1, 2, 3, 4] as [UInt8]
		
		// Set a NSData value. UserDefaults.data(forKey:) is supposed to return the Data
		defaults.set(NSData(bytes: bytes, length: bytes.count), forKey: "key1")
		
		XCTAssertEqual(defaults.data(forKey: "key1"), Data(bytes: bytes))
	}
	
	func test_setValue_Data() {
		let defaults = UserDefaults.standard
		let bytes = [0, 1, 2, 3, 4] as [UInt8]
		
		// Set a Data value. UserDefaults.data(forKey:) is supposed to return the Data
		defaults.set(Data(bytes: bytes), forKey: "key1")
		
		XCTAssertEqual(defaults.data(forKey: "key1"), Data(bytes: bytes))
	}

	func test_setValue_BoolFromString() {
		let defaults = UserDefaults.standard
		
		// Register a boolean default value as a string. UserDefaults.bool(forKey:) is supposed to return the parsed Bool value
		defaults.set("YES", forKey: "key1")
		
		XCTAssertEqual(defaults.bool(forKey: "key1"), true)
	}
	
	func test_setValue_IntFromString() {
		let defaults = UserDefaults.standard
		
		// Register an int default value as a string. UserDefaults.integer(forKey:) is supposed to return the parsed Int value
		defaults.set("1234", forKey: "key1")
		
		XCTAssertEqual(defaults.integer(forKey: "key1"), 1234)
	}
	
	func test_setValue_DoubleFromString() {
		let defaults = UserDefaults.standard
		
		// Register a double default value as a string. UserDefaults.double(forKey:) is supposed to return the parsed Double value
		defaults.set("12.34", forKey: "key1")
		
		XCTAssertEqual(defaults.double(forKey: "key1"), 12.34)
	}
	
	func test_volatileDomains() {
		let dateKey = "A Date",
		stringKey = "A String",
		arrayKey = "An Array",
		dictionaryKey = "A Dictionary",
		dataKey = "Some Data",
		boolKey = "A Bool"
		
		let defaultsIn: [String: Any] = [
			dateKey: Date(),
			stringKey: "The String",
			arrayKey: [1, 2, 3],
			dictionaryKey: ["Swift": "Imperative", "Haskell": "Functional", "LISP": "LISP", "Today": Date()],
			dataKey: "The Data".data(using: .utf8)!,
			boolKey: true
		]
		
		let domainName = "TestDomain"
		
		let defaults = UserDefaults(suiteName: nil)!
		XCTAssertFalse(defaults.volatileDomainNames.contains(domainName))
		
		defaults.setVolatileDomain(defaultsIn, forName: domainName)
		let defaultsOut = defaults.volatileDomain(forName: domainName)
		
		XCTAssertEqual(defaultsIn.count, defaultsOut.count)
		XCTAssertEqual(defaultsIn[dateKey] as! Date, defaultsOut[dateKey] as! Date)
		XCTAssertEqual(defaultsIn[stringKey] as! String, defaultsOut[stringKey] as! String)
		XCTAssertEqual(defaultsIn[arrayKey] as! [Int], defaultsOut[arrayKey] as! [Int])
		XCTAssertEqual(defaultsIn[dictionaryKey] as! [String: AnyHashable], defaultsOut[dictionaryKey] as! [String: AnyHashable])
		XCTAssertEqual(defaultsIn[dataKey] as! Data, defaultsOut[dataKey] as! Data)
		XCTAssertEqual(defaultsIn[boolKey] as! Bool, defaultsOut[boolKey] as! Bool)
	}
	
	func test_persistentDomain() {
		let int = (key: "An Integer", value: 1234)
		let double = (key: "A Double", value: 5678.1234)
		let string = (key: "A String", value: "Some string")
		let array = (key: "An Array", value: [ 1, 2, 3, 4, "Surprise" ] as [AnyHashable])
		let dictionary = (key: "A Dictionary", value: [ "Swift": "Imperative", "Haskell": "Functional", "LISP": "LISP", "Today": Date() ] as [String: AnyHashable])
		
		let domainName = "org.swift.Foundation.TestPersistentDomainName"

		let done = expectation(description: "All notifications have fired.")
		
		var countOfFiredNotifications = 0
		let expectedNotificationCount = 3
		
		let observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { (_) in
			countOfFiredNotifications += 1
			
			if countOfFiredNotifications == expectedNotificationCount {
				done.fulfill()
			} else if countOfFiredNotifications > expectedNotificationCount {
				XCTFail("Too many UserDefaults.didChangeNotification notifications posted.")
			}
		}
		
		let defaults1 = UserDefaults(suiteName: nil)!
		
		defaults1.removePersistentDomain(forName: domainName)
		if let domain = defaults1.persistentDomain(forName: domainName) {
			XCTAssertEqual(domain.count, 0)
		} // else it's nil, which is also OK.
		
		let defaultsIn: [String : Any] =
			[ int.key: int.value,
			  double.key: double.value,
			  string.key: string.value,
			  array.key: array.value,
			  dictionary.key: dictionary.value ]
		
		defaults1.setPersistentDomain(defaultsIn, forName: domainName)
		
		let defaults2 = UserDefaults(suiteName: nil)!
		let returned = defaults2.persistentDomain(forName: domainName)
		XCTAssertNotNil(returned)
		
		if let returned = returned {
			XCTAssertEqual(returned.count, defaultsIn.count)
			XCTAssertEqual(returned[int.key] as? Int, int.value)
			XCTAssertEqual(returned[double.key] as? Double, double.value)
			XCTAssertEqual(returned[string.key] as? String, string.value)
			XCTAssertEqual(returned[array.key] as? [AnyHashable], array.value)
			XCTAssertEqual(returned[dictionary.key] as? [String: AnyHashable], dictionary.value)
		}
		
		defaults2.removePersistentDomain(forName: domainName)
		
		let defaults3 = UserDefaults(suiteName: nil)!
		if let domain = defaults3.persistentDomain(forName: domainName) {
			XCTAssertEqual(domain.count, 0)
		} // else it's nil, which is also OK.
		
		waitForExpectations(timeout: 10)
		
		NotificationCenter.default.removeObserver(observer)
	}
}
