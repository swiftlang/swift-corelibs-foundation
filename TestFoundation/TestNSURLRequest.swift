// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSURLRequest : XCTestCase {
    
    static var allTests: [(String, (TestNSURLRequest) -> () throws -> Void)] {
        return [
            ("test_construction", test_construction),
            ("test_mutableConstruction", test_mutableConstruction),
            ("test_headerFields", test_headerFields),
            ("test_copy", test_copy),
            ("test_mutableCopy_1", test_mutableCopy_1),
            ("test_mutableCopy_2", test_mutableCopy_2),
            ("test_mutableCopy_3", test_mutableCopy_3),
            ("test_NSCoding_1", test_NSCoding_1),
            ("test_NSCoding_2", test_NSCoding_2),
            ("test_NSCoding_3", test_NSCoding_3),
            ("test_methodNormalization", test_methodNormalization),
            ("test_description", test_description),
        ]
    }
    
    let url = URL(string: "http://swift.org")!
    
    func test_construction() {
        let request = NSURLRequest(url: url)
        // Match macOS Foundation responses
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.allHTTPHeaderFields)
        XCTAssertNil(request.mainDocumentURL)
    }
    
    func test_mutableConstruction() {
        let url = URL(string: "http://swift.org")!
        let request = NSMutableURLRequest(url: url)
        
        //Confirm initial state matches NSURLRequest responses
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.allHTTPHeaderFields)
        XCTAssertNil(request.mainDocumentURL)
        
        request.mainDocumentURL = url
        XCTAssertEqual(request.mainDocumentURL, url)
        
        request.httpMethod = "POST"
        XCTAssertEqual(request.httpMethod, "POST")
        
        let newURL = URL(string: "http://github.com")!
        request.url = newURL
        XCTAssertEqual(request.url, newURL)
    }
    
    func test_headerFields() {
        let request = NSMutableURLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        XCTAssertNotNil(request.allHTTPHeaderFields)
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")
        
        // Setting "accept" should update "Accept"
        request.setValue("application/xml", forHTTPHeaderField: "accept")
        XCTAssertNil(request.allHTTPHeaderFields?["accept"])
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/xml")
        
        // Adding to "Accept" should add to "Accept"
        request.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/xml,text/html")
    }
    
    func test_copy() {
        let mutableRequest = NSMutableURLRequest(url: url)
        
        let urlA = URL(string: "http://swift.org")!
        let urlB = URL(string: "http://github.com")!
        let postBody = "here is body".data(using: .utf8)

        mutableRequest.mainDocumentURL = urlA
        mutableRequest.url = urlB
        mutableRequest.httpMethod = "POST"
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        mutableRequest.httpBody = postBody

        guard let requestCopy1 = mutableRequest.copy() as? NSURLRequest else {
            XCTFail(); return
        }
        
        // Check that all attributes are copied and that the original ones are
        // unchanged:
        XCTAssertEqual(mutableRequest.mainDocumentURL, urlA)
        XCTAssertEqual(requestCopy1.mainDocumentURL, urlA)
        XCTAssertEqual(mutableRequest.httpMethod, "POST")
        XCTAssertEqual(requestCopy1.httpMethod, "POST")
        XCTAssertEqual(mutableRequest.url, urlB)
        XCTAssertEqual(requestCopy1.url, urlB)
        XCTAssertEqual(mutableRequest.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertEqual(requestCopy1.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertEqual(mutableRequest.httpBody, postBody)
        XCTAssertEqual(requestCopy1.httpBody, postBody)

        // Change the original, and check that the copy has unchanged
        // values:
        let urlC = URL(string: "http://apple.com")!
        let urlD = URL(string: "http://ibm.com")!
        mutableRequest.mainDocumentURL = urlC
        mutableRequest.url = urlD
        mutableRequest.httpMethod = "HEAD"
        mutableRequest.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertEqual(requestCopy1.mainDocumentURL, urlA)
        XCTAssertEqual(requestCopy1.httpMethod, "POST")
        XCTAssertEqual(requestCopy1.url, urlB)
        XCTAssertEqual(requestCopy1.allHTTPHeaderFields?["Accept"], "application/json")

        // Check that we can copy the copy:
        guard let requestCopy2 = requestCopy1.copy() as? NSURLRequest else {
            XCTFail(); return
        }
        XCTAssertEqual(requestCopy2.mainDocumentURL, urlA)
        XCTAssertEqual(requestCopy2.httpMethod, "POST")
        XCTAssertEqual(requestCopy2.url, urlB)
        XCTAssertEqual(requestCopy2.allHTTPHeaderFields?["Accept"], "application/json")
    }

    func test_mutableCopy_1() {
        let originalRequest = NSMutableURLRequest(url: url)
        
        let urlA = URL(string: "http://swift.org")!
        let urlB = URL(string: "http://github.com")!

        originalRequest.mainDocumentURL = urlA
        originalRequest.url = urlB
        originalRequest.httpMethod = "POST"
        originalRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        guard let requestCopy = originalRequest.mutableCopy() as? NSMutableURLRequest else {
            XCTFail(); return
        }
        
        // Change the original, and check that the copy has unchanged values:
        let urlC = URL(string: "http://apple.com")!
        let urlD = URL(string: "http://ibm.com")!
        originalRequest.mainDocumentURL = urlC
        originalRequest.url = urlD
        originalRequest.httpMethod = "HEAD"
        originalRequest.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertEqual(requestCopy.mainDocumentURL, urlA)
        XCTAssertEqual(requestCopy.httpMethod, "POST")
        XCTAssertEqual(requestCopy.url, urlB)
        XCTAssertEqual(requestCopy.allHTTPHeaderFields?["Accept"], "application/json")
    }

    func test_mutableCopy_2() {
        let originalRequest = NSMutableURLRequest(url: url)
        
        let urlA = URL(string: "http://swift.org")!
        let urlB = URL(string: "http://github.com")!
        originalRequest.mainDocumentURL = urlA
        originalRequest.url = urlB
        originalRequest.httpMethod = "POST"
        originalRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        guard let requestCopy = originalRequest.mutableCopy() as? NSMutableURLRequest else {
            XCTFail(); return
        }
        
        // Change the copy, and check that the original has unchanged values:
        let urlC = URL(string: "http://apple.com")!
        let urlD = URL(string: "http://ibm.com")!
        requestCopy.mainDocumentURL = urlC
        requestCopy.url = urlD
        requestCopy.httpMethod = "HEAD"
        requestCopy.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertEqual(originalRequest.mainDocumentURL, urlA)
        XCTAssertEqual(originalRequest.httpMethod, "POST")
        XCTAssertEqual(originalRequest.url, urlB)
        XCTAssertEqual(originalRequest.allHTTPHeaderFields?["Accept"], "application/json")
    }

    func test_mutableCopy_3() {
        let urlA = URL(string: "http://swift.org")!
        let originalRequest = NSURLRequest(url: urlA)
        
        guard let requestCopy = originalRequest.mutableCopy() as? NSMutableURLRequest else {
            XCTFail(); return
        }
        
        // Change the copy, and check that the original has unchanged values:
        let urlC = URL(string: "http://apple.com")!
        let urlD = URL(string: "http://ibm.com")!
        requestCopy.mainDocumentURL = urlC
        requestCopy.url = urlD
        requestCopy.httpMethod = "HEAD"
        requestCopy.addValue("text/html", forHTTPHeaderField: "Accept")
        XCTAssertNil(originalRequest.mainDocumentURL)
        XCTAssertEqual(originalRequest.httpMethod, "GET")
        XCTAssertEqual(originalRequest.url, urlA)
        XCTAssertNil(originalRequest.allHTTPHeaderFields)
    }
    
    func test_NSCoding_1() {
        let url = URL(string: "https://apple.com")!
        let requestA = NSURLRequest(url: url)
        let requestB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: requestA)) as! NSURLRequest
        XCTAssertEqual(requestA, requestB, "Archived then unarchived url request must be equal.")
    }
    
    func test_NSCoding_2() {
        let url = URL(string: "https://apple.com")!
        let requestA = NSMutableURLRequest(url: url)
        //Also checks crash on NSData.bytes
        requestA.httpBody = Data()
        let requestB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: requestA)) as! NSURLRequest
        XCTAssertEqual(requestA, requestB, "Archived then unarchived url request must be equal.")
        //Check `.httpBody` as it is not checked in `isEqual(_:)`
        XCTAssertEqual(requestB.httpBody, requestA.httpBody)
    }
    
    func test_NSCoding_3() {
        let url = URL(string: "https://apple.com")!
        let urlForDocument = URL(string: "http://ibm.com")!
        
        let requestA = NSMutableURLRequest(url: url)
        requestA.mainDocumentURL = urlForDocument
        //Also checks crash on NSData.bytes
        requestA.httpBody = Data(bytes: [1, 2, 3])
        let requestB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: requestA)) as! NSURLRequest
        XCTAssertEqual(requestA, requestB, "Archived then unarchived url request must be equal.")
        //Check `.httpBody` as it is not checked in `isEqual(_:)`
        XCTAssertNotNil(requestB.httpBody)
        XCTAssertEqual(3, requestB.httpBody!.count)
        XCTAssertEqual(requestB.httpBody, requestA.httpBody)
    }

    func test_methodNormalization() {
        let expectedNormalizations = [
            "GET": "GET",
            "get": "GET",
            "gEt": "GET",
            "HEAD": "HEAD",
            "hEAD": "HEAD",
            "head": "HEAD",
            "HEAd": "HEAD",
            "POST": "POST",
            "post": "POST",
            "pOST": "POST",
            "POSt": "POST",
            "PUT": "PUT",
            "put": "PUT",
            "PUt": "PUT",
            "DELETE": "DELETE",
            "delete": "DELETE",
            "DeleTE": "DELETE",
            "dELETe": "DELETE",
            "CONNECT": "CONNECT",
            "connect": "CONNECT",
            "Connect": "CONNECT",
            "cOnNeCt": "CONNECT",
            "OPTIONS": "OPTIONS",
            "options": "options",
            "TRACE": "TRACE",
            "trace": "trace",
            "PATCH": "PATCH",
            "patch": "patch",
            "foo": "foo",
            "BAR": "BAR",
        ]

        let request = NSMutableURLRequest(url: url)

        for n in expectedNormalizations {
            request.httpMethod = n.key
            XCTAssertEqual(request.httpMethod, n.value)
        }
    }

    func test_description() {
        let url = URL(string: "http://swift.org")!
        let request = NSMutableURLRequest(url: url)

        if request.description.range(of: "http://swift.org") == nil {
            XCTFail("description should contain URL")
        }

        request.url = nil
        if request.description.range(of: "(null)") == nil {
            XCTFail("description of nil URL should contain (null)")
        }
    }
}
