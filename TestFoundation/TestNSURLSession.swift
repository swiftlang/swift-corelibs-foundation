// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// This file contains unit tests of the NSURLSession API implementation.
///
// -----------------------------------------------------------------------------


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    @testable import Foundation
    import XCTest
#else
    @testable import SwiftFoundation
    import SwiftXCTest
#endif
import Dispatch



class TestNSURLSessionConfiguration : XCTestCase {
    static var allTests: [(String, TestNSURLSessionConfiguration -> () throws -> Void)] {
        return [("test_DefaultSessionProperties", test_DefaultSessionProperties),
        ]
    }
    
    func test_DefaultSessionProperties() {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        XCTAssertEqual(config.requestCachePolicy, NSURLRequestCachePolicy.useProtocolCachePolicy)
        XCTAssertEqual(config.timeoutIntervalForRequest, 60)
        XCTAssertEqual(config.timeoutIntervalForResource, 604800)
        XCTAssertEqual(config.networkServiceType, NSURLRequestNetworkServiceType.networkServiceTypeDefault)
        XCTAssertEqual(config.allowsCellularAccess, true)
        // XCTAssertEqual(config.discretionary, false)
        XCTAssertNil(config.connectionProxyDictionary)
        XCTAssertEqual(config.httpShouldUsePipelining, false)
        XCTAssertEqual(config.httpShouldSetCookies, true)
        XCTAssertEqual(config.httpCookieAcceptPolicy, NSHTTPCookieAcceptPolicy.OnlyFromMainDocumentDomain)
        XCTAssertNil(config.httpAdditionalHeaders)
        XCTAssertEqual(config.httpMaximumConnectionsPerHost, 6)
        
        //TODO: Once these classes work,
        // XCTAssertNotNil(config.httpCookieStorage)
        // XCTAssertNotNil(config.urlCredentialStorage)
        // XCTAssertNotNil(config.urlCache)
    }
}

class TestNSURLSession_Helpers : XCTestCase {
    static var allTests: [(String, TestNSURLSession_Helpers -> () throws -> Void)] {
        return [
            ("test_HTTPBodyDataSource", test_HTTPBodyDataSource),
            ("test_HTTPBodyFileSource", test_HTTPBodyFileSource),
            
            ("test_parsingResponseHeaderLines", test_parsingResponseHeaderLines),
            ("test_parsingResponseHeaderLines_withoutFinal", test_parsingResponseHeaderLines_withoutFinal),
            ("test_parsingResponseHeaderLines_withoutTrailingCRLF_1", test_parsingResponseHeaderLines_withoutTrailingCRLF_1),
            ("test_parsingResponseHeaderLines_withoutTrailingCRLF_2", test_parsingResponseHeaderLines_withoutTrailingCRLF_2),
            ("test_parsingResponseHeaderLines_withoutTrailingCRLF_3", test_parsingResponseHeaderLines_withoutTrailingCRLF_3),
            ("test_parsingResponseHeaderLines_withoutTrailingCRLF_4", test_parsingResponseHeaderLines_withoutTrailingCRLF_4),
            
            ("test_parsingHeadersFromLines", test_parsingHeadersFromLines),
            ("test_parsingHeadersFromLines_foldedLines", test_parsingHeadersFromLines_foldedLines),
            ("test_parsingHeadersFromLines_failWithInvalidStatusLine_1", test_parsingHeadersFromLines_failWithInvalidStatusLine_1),
            ("test_parsingHeadersFromLines_failWithInvalidStatusLine_2", test_parsingHeadersFromLines_failWithInvalidStatusLine_2),
            ("test_parsingHeadersFromLines_failWithInvalidStatusLine_3", test_parsingHeadersFromLines_failWithInvalidStatusLine_3),
            ("test_parsingHeadersFromLines_failWithInvalidStatusLine_4", test_parsingHeadersFromLines_failWithInvalidStatusLine_4),
            ("test_parsingHeadersFromLines_failWithInvalidStatusLine_5", test_parsingHeadersFromLines_failWithInvalidStatusLine_5),
            
            ("test_TransferState_init", test_TransferState_init),
            ("test_TransferState_appendingCompleteHeader", test_TransferState_appendingCompleteHeader),
            ("test_TransferState_appendingInvalidHeader", test_TransferState_appendingInvalidHeader),
            ("test_TransferState_appendingIgnoredBodyData", test_TransferState_appendingIgnoredBodyData),
            ("test_TransferState_appendingInMemoryBodyData", test_TransferState_appendingInMemoryBodyData),
        ]
    }
    
    /// Helper to check an HTTPBodySource with a given chunk length
    func check(httpBodySource sut: HTTPBodySource, testData data: NSData, chunkLength: Int, file: String = #file, line: UInt = #line) {
        var dataRead = dispatch_data_create(nil, 0, nil, nil)
        
        let maxLoopCount = 2 * (data.length + chunkLength) / chunkLength
        var loopCount = 0
        loop: repeat {
            loopCount += 1
            
            switch sut.getNextChunk(withLength: chunkLength) {
            case .data(let chunk):
                XCTAssertNotEqual(dispatch_data_get_size(chunk), 0, "data length \(data.length), chunk length \(chunkLength)")
                dataRead = dispatch_data_create_concat(dataRead, chunk)
            case .done:
                break loop
            case .retryLater:
                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.001))
            case .error:
                XCTFail("Error from HTTP body source.")
                break loop
            }
        } while loopCount <= maxLoopCount
        XCTAssertLessThanOrEqual(loopCount, maxLoopCount, "data length \(data.length), chunk length \(chunkLength)")
        
        XCTAssertEqual(dispatch_data_get_size(dataRead), data.length, "data length \(data.length), chunk length \(chunkLength)")
        XCTAssertEqual(NSData(dispatchData: dataRead), data, "data length \(data.length), chunk length \(chunkLength)")
    }
    
    func test_HTTPBodyDataSource() {
        for length in 1..<100 {
            for chunkLength in [1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 100, 101] {
                let data = createTestData(length: length)
                let sut = HTTPBodyDataSource(data: createDispatchData(data))
                check(httpBodySource: sut, testData: data, chunkLength: chunkLength)
            }
        }
    }
    
    /// Helper to check an HTTPBodySource with a given chunk length
    func check(httpBodyFileSource sut: HTTPBodySource, workQueue: dispatch_queue_t, @noescape wait: () -> Bool, testData data: NSData, chunkLength: Int, file: String = #file, line: UInt = #line) {
        
        // This version is slightly more complex, because it will only call
        // getNextChunk() on the given work queue.
        
        var dataRead = dispatch_data_create(nil, 0, nil, nil)
        
        let maxLoopCount = 2 + 3 * (data.length + chunkLength) / chunkLength
        var loopCount = 0
        var done = false
        
        enum Action {
            case wait
            case loop
            case done
        }
        
        func read() -> Action {
            switch sut.getNextChunk(withLength: chunkLength) {
            case .data(let chunk):
                XCTAssertNotEqual(dispatch_data_get_size(chunk), 0, "data length \(data.length), chunk length \(chunkLength)")
                dataRead = dispatch_data_create_concat(dataRead, chunk)
                return .loop
            case .done:
                return .done
            case .retryLater:
                return .wait
            case .error:
                XCTFail("Error from HTTP body source.")
                return .done
            }
        }
        
        loop: repeat {
            loopCount += 1

            var action = Action.loop
            dispatch_sync(workQueue) {
                action = read()
            }
            switch action {
            case .wait:
                if !wait() {
                    break loop
                }
            case .loop:
                break
            case .done:
                break loop
            }
            
        } while loopCount <= maxLoopCount
        XCTAssertLessThanOrEqual(loopCount, maxLoopCount, "data length \(data.length), chunk length \(chunkLength)")
        
        XCTAssertEqual(dispatch_data_get_size(dataRead), data.length, "data length \(data.length), chunk length \(chunkLength)")
        XCTAssertEqual(NSData(dispatchData: dataRead), data, "data length \(data.length), chunk length \(chunkLength)")
    }
    
    func test_HTTPBodyFileSource() {
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("test_HTTPBodyFileSource")!
        let queue = dispatch_queue_create("test_HTTPBodyFileSource", DISPATCH_QUEUE_SERIAL)
        for length in 1..<100 {
            for chunkLength in [1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 100, 101] {
                let data = createTestData(length: length)
                do {
                    try data.writeToURL(fileURL, options: [])
                } catch let e {
                    XCTFail("Unable to write test data to file: \(e)")
                    break
                }
                
                let sem = dispatch_semaphore_create(0)
                let wait: () -> Bool = {
                    let t = dispatch_time(DISPATCH_TIME_NOW, 2 * Int64(NSEC_PER_MSEC))
                    let w = dispatch_semaphore_wait(sem, t)
                    XCTAssertEqual(w, 0, "Failed waiting for source.")
                    return w == 0
                }
                let sut = HTTPBodyFileSource(fileURL: fileURL, workQueue: queue, dataAvailableHandler: { 
                    dispatch_semaphore_signal(sem)
                })
                check(httpBodyFileSource: sut, workQueue: queue, wait: wait, testData: data, chunkLength: chunkLength)
            }
        }
    }
    
    func buildParsedResponseHeader(fromLines lines: [String]) -> NSURLSessionTask.ParsedResponseHeader? {
        var prh: NSURLSessionTask.ParsedResponseHeader? = NSURLSessionTask.ParsedResponseHeader.partial(NSURLSessionTask.ResponseHeaderLines())
        lines.forEach {
            $0.withNonterminatedUTF8Buffer {
                prh = prh?.byAppending(headerLine: $0)
            }
        }
        return prh
    }
    
    func test_parsingResponseHeaderLines() {
        // All lines should end with <CRLF> and the final line should only consist of <CRLF>.
        let prh = buildParsedResponseHeader(fromLines: ["A\u{d}\u{a}", "B\u{d}\u{a}", "\u{d}\u{a}"])
        switch prh {
        case .none: XCTFail()
        case .some(.partial): XCTFail("Header should have been complete.")
        case .some(.complete(let lines)):
            XCTAssertEqual(lines.lines.count, 2)
            if 2 <= lines.lines.count {
                XCTAssertEqual(lines.lines[0], "A")
                XCTAssertEqual(lines.lines[1], "B")
            }
        }
    }
    func test_parsingResponseHeaderLines_withoutFinal() {
        let prh = buildParsedResponseHeader(fromLines: ["A\u{d}\u{a}", "B\u{d}\u{a}"])
        switch prh {
        case .none: XCTFail()
        case .some(.partial): break
        case .some(.complete): XCTFail()
        }
    }
    func test_parsingResponseHeaderLines_withoutTrailingCRLF_1() {
        let prh = buildParsedResponseHeader(fromLines: ["AAA\u{a}", "B\u{d}\u{a}", "\u{d}\u{a}"])
        XCTAssertNil(prh)
    }
    func test_parsingResponseHeaderLines_withoutTrailingCRLF_2() {
        let prh = buildParsedResponseHeader(fromLines: ["AAA\u{d}", "B\u{d}\u{a}", "\u{d}\u{a}"])
        XCTAssertNil(prh)
    }
    func test_parsingResponseHeaderLines_withoutTrailingCRLF_3() {
        let prh = buildParsedResponseHeader(fromLines: ["AAA", "B\u{d}\u{a}", "\u{d}\u{a}"])
        XCTAssertNil(prh)
    }
    func test_parsingResponseHeaderLines_withoutTrailingCRLF_4() {
        let prh = buildParsedResponseHeader(fromLines: ["", "B\u{d}\u{a}", "\u{d}\u{a}"])
        XCTAssertNil(prh)
    }
    func test_parsingHeadersFromLines() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1 200 OK",
             "Accept-Ranges: bytes",
             "Connection: Keep-Alive",
             "Content-Length: 5299",
             "Content-Type: text/html; charset=UTF-8",
             "Date: Tue, 15 Mar 2016 14:36:48 GMT",
             "ETag: \"19788-14b3-52e1726c31d40\"",
             "Last-Modified: Tue, 15 Mar 2016 14:24:13 GMT",
             "Proxy-Connection: Keep-Alive",
             "Server: Apache/2.2.15 (Red Hat)",
             "Strict-Transport-Security: max-age=15768000",
             "Via: HTTP/1.1 swiftproxy3.softlayer.com (IBM-PROXY-WTE)",
             ])
        guard let message = lines.createHTTPMessage() else { XCTFail(); return }
        switch message.startLine {
        case .requestLine: XCTFail()
        case .statusLine(version: let version, status: let status, reason: let reason):
            XCTAssertEqual(version.rawValue, "HTTP/1.1")
            XCTAssertEqual(status, 200)
            XCTAssertEqual(reason, "OK")
        }
        XCTAssertEqual(message.headers.count, 11)
        if 11 <= message.headers.count {
            XCTAssertEqual(message.headers[0].name, "Accept-Ranges")
            XCTAssertEqual(message.headers[0].value, "bytes")
            XCTAssertEqual(message.headers[1].name, "Connection")
            XCTAssertEqual(message.headers[1].value, "Keep-Alive")
            XCTAssertEqual(message.headers[2].name, "Content-Length")
            XCTAssertEqual(message.headers[2].value, "5299")
            XCTAssertEqual(message.headers[3].name, "Content-Type")
            XCTAssertEqual(message.headers[3].value, "text/html; charset=UTF-8")
            XCTAssertEqual(message.headers[4].name, "Date")
            XCTAssertEqual(message.headers[4].value, "Tue, 15 Mar 2016 14:36:48 GMT")
            XCTAssertEqual(message.headers[5].name, "ETag")
            XCTAssertEqual(message.headers[5].value, "\"19788-14b3-52e1726c31d40\"")
            XCTAssertEqual(message.headers[6].name, "Last-Modified")
            XCTAssertEqual(message.headers[6].value, "Tue, 15 Mar 2016 14:24:13 GMT")
            XCTAssertEqual(message.headers[7].name, "Proxy-Connection")
            XCTAssertEqual(message.headers[7].value, "Keep-Alive")
            XCTAssertEqual(message.headers[8].name, "Server")
            XCTAssertEqual(message.headers[8].value, "Apache/2.2.15 (Red Hat)")
            XCTAssertEqual(message.headers[9].name, "Strict-Transport-Security")
            XCTAssertEqual(message.headers[9].value, "max-age=15768000")
            XCTAssertEqual(message.headers[10].name, "Via")
            XCTAssertEqual(message.headers[10].value, "HTTP/1.1 swiftproxy3.softlayer.com (IBM-PROXY-WTE)")
        }
    }
    func test_parsingHeadersFromLines_foldedLines() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1 200 OK",
             "Accept-Ranges:",
             " bytes",
             "Connection: Keep-Alive",
             "Content-Length: 5299",
             "Content-Type: text/html;",
             "\tcharset=UTF-8",
             "Date: Tue, 15",
             "    Mar 2016 14:36:48 GMT",
             "ETag: \"19788-14b3-52e1726c31d40\"",
             "Last-Modified:     Tue, 15 Mar 2016 14:24:13 GMT",
             "Proxy-Connection: Keep-Alive",
             "Server: Apache/2.2.15 (Red Hat)",
             "Strict-Transport-Security: max-age=15768000",
             "Via: HTTP/1.1 swiftproxy3.softlayer.com (IBM-PROXY-WTE)",
             ])
        guard let message = lines.createHTTPMessage() else { XCTFail(); return }
        XCTAssertEqual(message.headers.count, 11)
        if 11 <= message.headers.count {
            XCTAssertEqual(message.headers[0].name, "Accept-Ranges")
            XCTAssertEqual(message.headers[0].value, "bytes")
            XCTAssertEqual(message.headers[1].name, "Connection")
            XCTAssertEqual(message.headers[1].value, "Keep-Alive")
            XCTAssertEqual(message.headers[2].name, "Content-Length")
            XCTAssertEqual(message.headers[2].value, "5299")
            XCTAssertEqual(message.headers[3].name, "Content-Type")
            XCTAssertEqual(message.headers[3].value, "text/html; charset=UTF-8")
            XCTAssertEqual(message.headers[4].name, "Date")
            XCTAssertEqual(message.headers[4].value, "Tue, 15 Mar 2016 14:36:48 GMT")
            XCTAssertEqual(message.headers[5].name, "ETag")
            XCTAssertEqual(message.headers[5].value, "\"19788-14b3-52e1726c31d40\"")
            XCTAssertEqual(message.headers[6].name, "Last-Modified")
            XCTAssertEqual(message.headers[6].value, "Tue, 15 Mar 2016 14:24:13 GMT")
            XCTAssertEqual(message.headers[7].name, "Proxy-Connection")
            XCTAssertEqual(message.headers[7].value, "Keep-Alive")
            XCTAssertEqual(message.headers[8].name, "Server")
            XCTAssertEqual(message.headers[8].value, "Apache/2.2.15 (Red Hat)")
            XCTAssertEqual(message.headers[9].name, "Strict-Transport-Security")
            XCTAssertEqual(message.headers[9].value, "max-age=15768000")
            XCTAssertEqual(message.headers[10].name, "Via")
            XCTAssertEqual(message.headers[10].value, "HTTP/1.1 swiftproxy3.softlayer.com (IBM-PROXY-WTE)")
        }
    }
    func test_parsingHeadersFromLines_failWithInvalidStatusLine_1() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1200 OK",
             "Content-Length: 5299",
             "Content-Type: text/html",
             ])
        let message = lines.createHTTPMessage()
        XCTAssertNil(message)
    }
    func test_parsingHeadersFromLines_failWithInvalidStatusLine_2() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1 200OK",
             "Content-Length: 5299",
             "Content-Type: text/html",
             ])
        let message = lines.createHTTPMessage()
        XCTAssertNil(message)
    }
    func test_parsingHeadersFromLines_failWithInvalidStatusLine_3() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            [" 200 OK",
             "Content-Length: 5299",
             "Content-Type: text/html",
             ])
        let message = lines.createHTTPMessage()
        XCTAssertNil(message)
    }
    func test_parsingHeadersFromLines_failWithInvalidStatusLine_4() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1  OK",
             "Content-Length: 5299",
             "Content-Type: text/html",
             ])
        let message = lines.createHTTPMessage()
        XCTAssertNil(message)
    }
    func test_parsingHeadersFromLines_failWithInvalidStatusLine_5() {
        let lines = NSURLSessionTask.ResponseHeaderLines(headerLines:
            ["HTTP/1.1 200 ",
             "Content-Length: 5299",
             "Content-Type: text/html",
             ])
        let message = lines.createHTTPMessage()
        XCTAssertNil(message)
    }
    
    func test_TransferState_init() {
        let url = NSURL(string: "https://www.swift.org/")!
        let sut = NSURLSessionTask.TransferState(url: url, bodyDataDrain: .ignore)
        XCTAssert(sut.url == url)
        if case .partial(let l) = sut.parsedResponseHeader {
            XCTAssert(l.lines.isEmpty)
        } else {
            XCTFail()
        }
        XCTAssertNil(sut.response)
    }
    func test_TransferState_appendingCompleteHeader() {
        let url = NSURL(string: "https://www.swift.org/")!
        var sut = NSURLSessionTask.TransferState(url: url, bodyDataDrain: .ignore)
        let CRLF = "\u{d}\u{a}"
        ["HTTP/1.1 200 OK\(CRLF)",
             "Content-Length: 5299\(CRLF)",
             "Content-Type: text/html\(CRLF)",
             "\(CRLF)",
             ]
            .forEach { line in
                line.withNonterminatedUTF8Buffer {
                    do {
                        sut = try sut.byAppending(headerLine: $0)
                    } catch let e {
                        XCTFail("line: '\(line)': \(e)")
                    }
                }
        }
        XCTAssert(sut.url == url)
        if case .partial(let l) = sut.parsedResponseHeader {
            XCTAssert(l.lines.isEmpty)
        } else {
            XCTFail()
        }
        guard let response = sut.response else { XCTFail(); return }
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.url, url)
    }
    func test_TransferState_appendingInvalidHeader() {
        let url = NSURL(string: "https://www.swift.org/")!
        var sut = NSURLSessionTask.TransferState(url: url, bodyDataDrain: .ignore)
        let CRLF = "\u{d}\u{a}"
        ["HTTP/1.1\(CRLF)",
         "Content-Length: 5299\(CRLF)",
         "Content-Type: text/html\(CRLF)",
         ]
            .forEach { line in
                line.withNonterminatedUTF8Buffer {
                    do {
                        sut = try sut.byAppending(headerLine: $0)
                    } catch let e {
                        XCTFail("line: '\(line)': \(e)")
                    }
                }
        }
        "\(CRLF)".withNonterminatedUTF8Buffer {
            do {
                sut = try sut.byAppending(headerLine: $0)
                XCTFail("Should have thrown an error.")
            } catch {
                // Pass
            }
        }
    }
    func test_TransferState_appendingIgnoredBodyData() {
        let url = NSURL(string: "https://www.swift.org/")!
        var sut = NSURLSessionTask.TransferState(url: url, bodyDataDrain: .ignore)
        
        guard case .ignore = sut.bodyDataDrain else {
            XCTFail(); return
        }
        
        "ab".withNonterminatedUTF8Buffer {
            sut = sut.byAppending(bodyData: $0)
        }
        guard case .ignore = sut.bodyDataDrain else {
            XCTFail(); return
        }
    }
    func test_TransferState_appendingInMemoryBodyData() {
        let url = NSURL(string: "https://www.swift.org/")!
        var sut = NSURLSessionTask.TransferState(url: url, bodyDataDrain: .inMemory(nil))
        
        guard case .inMemory(let d0) = sut.bodyDataDrain where d0 == nil else {
            XCTFail(); return
        }
        
        "ab".withNonterminatedUTF8Buffer {
            sut = sut.byAppending(bodyData: $0)
        }
        guard case .inMemory(let d1) = sut.bodyDataDrain else {
            XCTFail(); return
        }
        XCTAssertEqual(d1?.length, 2)
    }
}


private extension String {
    /// Calls the block with a `Int8` buffer containing UTF8 data of the `String`.
    /// The buffer is not zero terminated.
    func withNonterminatedUTF8Buffer<R>(block: (UnsafeBufferPointer<Int8>) -> R) -> R {
        var utf8: [UInt8] = []
        unicodeScalars.forEach {
            UTF8.encode($0, sendingOutputTo: { utf8.append($0) })
        }
        return utf8.withUnsafeBufferPointer { buffer in
            let b2 = UnsafeBufferPointer(start: UnsafePointer<Int8>(buffer.baseAddress), count: buffer.count)
            return block(b2)
        }
    }
}
