// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//

import Synchronization

#if canImport(SwiftFoundationNetworking) && !DEPLOYMENT_RUNTIME_OBJC
@testable import SwiftFoundationNetworking
#else
@testable import FoundationNetworking
#endif

private final class RedirectProbeProtocol: URLProtocol {
    static let declinedResponse = Mutex<(@Sendable () -> Void)?>(nil)
    static let nativeTarget = Mutex<URL?>(nil)
    static let visits = Mutex<[String]>([])

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "redirect-probe.test"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.visits.withLock { $0.append(url.path) }
        if url.path == "/native" {
            let next = Self.nativeTarget.withLock { $0! }
            let response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location": next.absoluteString])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: next), redirectResponse: response)
        } else if url.path == "/start" || url.path == "/hop" || url.path == "/loop" || url.path == "/decline" {
            let path = url.path == "/loop" ? "/loop" : url.path == "/start" ? "/hop" : "/final"
            let next = URL(string: path, relativeTo: url)!.absoluteURL
            let response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: "HTTP/1.1",
                                           headerFields: ["Location": next.absoluteString])!
            if url.path == "/decline" {
                nonisolated(unsafe) let protocolInstance = self
                Self.declinedResponse.withLock { callback in
                    callback = {
                        protocolInstance.client?.urlProtocol(protocolInstance, didReceive: response, cacheStoragePolicy: .notAllowed)
                        protocolInstance.client?.urlProtocol(protocolInstance, didLoad: Data("declined".utf8))
                        protocolInstance.client?.urlProtocolDidFinishLoading(protocolInstance)
                    }
                }
            }
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: next), redirectResponse: response)
        } else {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("final".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

private final class RedirectProbeDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    let mode: String
    let proposals = Mutex<[String]>([])
    let pending = Mutex<(@Sendable (URLRequest?) -> Void)?>(nil)
    var onPending: (() -> Void)?

    init(mode: String) { self.mode = mode }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @Sendable @escaping (URLRequest?) -> Void) {
        proposals.withLock { $0.append(request.url!.path) }
        switch mode {
        case "modify":
            completionHandler(URLRequest(url: URL(string: "/modified", relativeTo: request.url!)!.absoluteURL))
        case "decline":
            completionHandler(nil)
            task.workQueue.async {
                RedirectProbeProtocol.declinedResponse.withLock { $0 }?()
            }
        case "pending":
            pending.withLock { $0 = completionHandler }
            onPending?()
        default:
            completionHandler(request)
        }
    }
}

final class TestURLProtocolRedirects: LoopbackServerTest {
    override func tearDown() {
        RedirectProbeProtocol.declinedResponse.withLock { $0 = nil }
        RedirectProbeProtocol.nativeTarget.withLock { $0 = nil }
        super.tearDown()
    }

    func test_declinedCustomRedirectReturnsResponseBody() {
        let session = session(delegate: RedirectProbeDelegate(mode: "decline"))
        defer {
            session.invalidateAndCancel()
            RedirectProbeProtocol.declinedResponse.withLock { $0 = nil }
        }
        let done = expectation(description: "declined redirect response")
        let task = session.dataTask(with: URL(string: "http://redirect-probe.test/decline")!) { data, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 302)
            XCTAssertEqual(data, Data("declined".utf8))
            done.fulfill()
        }
        task.resume()
        wait(for: [done], timeout: 5)
        XCTAssertEqual(task.currentRequest?.url?.path, "/decline")
    }

    func test_customRedirectToNativeHTTP() {
        for nativeRedirects in [1, 20] {
            RedirectProbeProtocol.nativeTarget.withLock {
                $0 = URL(string: "http://127.0.0.1:\(Self.serverPort)/redirect/\(nativeRedirects)")!
            }
            let session = session()
            let done = expectation(description: "custom to native: \(nativeRedirects)")
            let task = session.dataTask(with: URL(string: "http://redirect-probe.test/native")!) { _, response, error in
                if nativeRedirects == 20 {
                    XCTAssertEqual((error as? URLError)?.code, .httpTooManyRedirects)
                } else {
                    XCTAssertNil(error)
                    XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
                }
                done.fulfill()
            }
            task.resume()
            wait(for: [done], timeout: 10)
            XCTAssertEqual(task.originalRequest?.url?.host, "redirect-probe.test")
            session.invalidateAndCancel()
        }
    }

    private func session(delegate: URLSessionTaskDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RedirectProbeProtocol.self]
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 3
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func test_followAndModifyCustomRedirect() {
        for mode in ["automatic", "follow", "modify"] {
            RedirectProbeProtocol.visits.withLock { $0 = [] }
            let delegate = mode == "automatic" ? nil : RedirectProbeDelegate(mode: mode)
            let session = session(delegate: delegate)
            let done = expectation(description: mode)
            let url = URL(string: "http://redirect-probe.test/start")!
            let task = session.dataTask(with: url) { data, response, error in
                XCTAssertNil(error)
                XCTAssertEqual(data, Data("final".utf8))
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
                done.fulfill()
            }
            task.resume()
            wait(for: [done], timeout: 5)
            XCTAssertEqual(task.originalRequest?.url?.path, "/start")
            XCTAssertEqual(task.currentRequest?.url?.path,
                           mode == "modify" ? "/modified" : "/final")
            XCTAssertEqual(RedirectProbeProtocol.visits.withLock { $0 },
                           mode == "modify" ? ["/start", "/modified"] :
                               ["/start", "/hop", "/final"])
            XCTAssertEqual(delegate?.proposals.withLock { $0 },
                           mode == "automatic" ? nil : mode == "modify" ? ["/hop"] :
                               ["/hop", "/final"])
            session.invalidateAndCancel()
        }
    }

    func test_customRedirectLimit() {
        RedirectProbeProtocol.visits.withLock { $0 = [] }
        let session = session()
        let done = expectation(description: "redirect limit")
        session.dataTask(with: URL(string: "http://redirect-probe.test/loop")!) { data, response, error in
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertEqual((error as? URLError)?.code, .httpTooManyRedirects)
            done.fulfill()
        }.resume()
        wait(for: [done], timeout: 5)
        XCTAssertEqual(RedirectProbeProtocol.visits.withLock { $0.count }, 21)
        session.invalidateAndCancel()
    }

    func test_cancelPendingCustomRedirect() {
        RedirectProbeProtocol.visits.withLock { $0 = [] }
        let delegate = RedirectProbeDelegate(mode: "pending")
        let session = session(delegate: delegate)
        let proposed = expectation(description: "redirect proposed")
        let done = expectation(description: "task canceled")
        delegate.onPending = { proposed.fulfill() }
        let task = session.dataTask(with: URL(string: "http://redirect-probe.test/start")!) { _, _, error in
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
            done.fulfill()
        }
        task.resume()
        wait(for: [proposed], timeout: 5)
        task.cancel()
        wait(for: [done], timeout: 5)
        let decision = delegate.pending.withLock { $0 }
        decision?(URLRequest(url: URL(string: "http://redirect-probe.test/hop")!))
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(RedirectProbeProtocol.visits.withLock { $0 }, ["/start"])
        session.invalidateAndCancel()
    }
}
