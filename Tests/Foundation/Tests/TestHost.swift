// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestHost: XCTestCase {
    
    static var allTests: [(String, (TestHost) -> () throws -> Void)] {
        return [
            ("test_addressesDoNotGrow", test_addressesDoNotGrow),
            ("test_isEqual", test_isEqual)
        ]
    }
    
    // SR-6391
    func test_addressesDoNotGrow() {
        let local = Host.current()
        let localAddressesFirst = local.addresses
        let localAddressesSecond = local.addresses
        XCTAssertEqual(localAddressesSecond.count, localAddressesFirst.count)
        
        let dns = Host(address: "8.8.8.8")
        let dnsAddressesFirst = dns.addresses
        let dnsAddressesSecond = dns.addresses
        XCTAssertEqual(dnsAddressesSecond.count, dnsAddressesFirst.count)
        
        let swift = Host(name: "localhost")
        let swiftAddressesFirst = swift.addresses
        let swiftAddressesSecond = swift.addresses
        XCTAssertEqual(swiftAddressesSecond.count, swiftAddressesFirst.count)
    }

    func test_isEqual() {
        let host0 = Host(address: "8.8.8.8")
        let host1 = Host(address: "8.8.8.8")
        XCTAssertTrue(host0.isEqual(to: host1))

        let host2 = Host(address: "8.8.8.9")
        XCTAssertFalse(host0.isEqual(to: host2))

        let swift0 = Host(name: "localhost")
        let swift1 = Host(name: "localhost")
        XCTAssertTrue(swift0.isEqual(to: swift1))

        let google = Host(name: "google.com")
        XCTAssertFalse(swift0.isEqual(to: google))
    }
}

