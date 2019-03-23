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
            ("test_isEqual_positive", test_isEqual_positive),
            ("test_isEqual_negative", test_isEqual_negative)
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
        
        let swift = Host(name: "swift.org")
        let swiftAddressesFirst = swift.addresses
        let swiftAddressesSecond = swift.addresses
        XCTAssertEqual(swiftAddressesSecond.count, swiftAddressesFirst.count)
    }

    func test_isEqual_positive() {
        let host0 = Host(address: "8.8.8.8")
        let host1 = Host(address: "8.8.8.8")
        XCTAssertTrue(host0.isEqual(to: host1))
    }

    func test_isEqual_negative() {
        let host0 = Host(address: "8.8.8.8")
        let host1 = Host(address: "8.8.8.9")
        XCTAssertFalse(host0.isEqual(to: host1))
    }
}

