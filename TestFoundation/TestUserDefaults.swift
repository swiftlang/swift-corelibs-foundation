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
			// __kCFXMLPropertyListDomainCallBacks is causing a failure
			// ("test_createUserDefaults", test_createUserDefaults ),
			// ("test_getRegisteredDefaultItem", test_getRegisteredDefaultItem ),
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
}
