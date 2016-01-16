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

class TestNSURLRequest : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_construction", test_construction),
            ("test_mutableConstruction", test_mutableConstruction),
            ("test_headerFields", test_headerFields)
        ]
    }
    
    let URL = NSURL(string: "http://swift.org")!
    
    func test_construction() {
        let request = NSURLRequest(URL: URL)
        // Match OS X Foundation responses
        XCTAssertNotNil(request)
        XCTAssertEqual(request.URL, URL)
        XCTAssertEqual(request.HTTPMethod, "GET")
        XCTAssertNil(request.allHTTPHeaderFields)
        XCTAssertNil(request.mainDocumentURL)
    }
    
    func test_mutableConstruction() {
        let URL = NSURL(string: "http://swift.org")!
        let request = NSMutableURLRequest(URL: URL)
        
        //Confirm initial state matches NSURLRequest responses
        XCTAssertNotNil(request)
        XCTAssertEqual(request.URL, URL)
        XCTAssertEqual(request.HTTPMethod, "GET")
        XCTAssertNil(request.allHTTPHeaderFields)
        XCTAssertNil(request.mainDocumentURL)
        
        request.mainDocumentURL = URL
        XCTAssertEqual(request.mainDocumentURL, URL)
        
        request.HTTPMethod = "POST"
        XCTAssertEqual(request.HTTPMethod, "POST")
        
        let newURL = NSURL(string: "http://github.com")!
        request.URL = newURL
        XCTAssertEqual(request.URL, newURL)
    }
    
    func test_headerFields() {
        let request = NSMutableURLRequest(URL: URL)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        XCTAssertNotNil(request.allHTTPHeaderFields)
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")

        // Setting "accept" should remove "Accept"
        request.setValue("application/xml", forHTTPHeaderField: "accept")
        XCTAssertNil(request.allHTTPHeaderFields?["Accept"])
        XCTAssertEqual(request.allHTTPHeaderFields?["accept"], "application/xml")
        
        // Adding to "Accept" should add to "accept"
        request.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertEqual(request.allHTTPHeaderFields?["accept"], "application/xml,text/html")
    }
}