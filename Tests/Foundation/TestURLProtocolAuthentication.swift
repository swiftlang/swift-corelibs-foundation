// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//

import Synchronization

private final class AuthenticationProbeProtocol: URLProtocol {
    static let decisions = Mutex<[String]>([])

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "authentication-probe.invalid"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        if url.path == "/unauthorized" {
            let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "HTTP/1.1",
                                           headerFields: ["WWW-Authenticate": "Basic realm=\"probe\""])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("denied".utf8))
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let space = URLProtectionSpace(host: url.host!, port: 80, protocol: "http", realm: "probe",
                                       authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        let sender = AuthenticationProbeSender(self)
        let challenge = URLAuthenticationChallenge(protectionSpace: space, proposedCredential: nil,
                                                   previousFailureCount: 0, failureResponse: nil,
                                                   error: nil, sender: sender)
        client?.urlProtocol(self, didReceive: challenge)
    }

    override func stopLoading() {}
}

private final class AuthenticationProbeSender: NSObject, URLAuthenticationChallengeSender, @unchecked Sendable {
    private weak var owner: AuthenticationProbeProtocol?

    init(_ owner: AuthenticationProbeProtocol) { self.owner = owner }

    private func finish(_ decision: String) {
        AuthenticationProbeProtocol.decisions.withLock { $0.append(decision) }
        guard let owner, let url = owner.request.url else { return }
        if decision == "cancel" {
            owner.client?.urlProtocol(owner, didFailWithError: URLError(.cancelled))
            return
        }
        let authorized = decision == "use"
        let response = HTTPURLResponse(url: url, statusCode: authorized ? 200 : 401,
                                       httpVersion: "HTTP/1.1", headerFields: nil)!
        owner.client?.urlProtocol(owner, didReceive: response, cacheStoragePolicy: .notAllowed)
        owner.client?.urlProtocol(owner, didLoad: Data((authorized ? "authorized" : "denied").utf8))
        owner.client?.urlProtocolDidFinishLoading(owner)
    }

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        finish(credential.user == "probe-user" ? "use" : "wrongCredential")
    }

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) { finish("withoutCredential") }
    func cancel(_ challenge: URLAuthenticationChallenge) { finish("cancel") }
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) { finish("default") }
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) { finish("reject") }
}

private final class AuthenticationProbeDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    let mode: String

    init(_ mode: String) { self.mode = mode }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @Sendable @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch mode {
        case "use":
            completionHandler(.useCredential, URLCredential(user: "probe-user", password: "probe-password", persistence: .none))
        case "reject": completionHandler(.rejectProtectionSpace, nil)
        case "cancel": completionHandler(.cancelAuthenticationChallenge, nil)
        case "withoutCredential": completionHandler(.useCredential, nil)
        default: completionHandler(.performDefaultHandling, nil)
        }
    }
}

final class TestURLProtocolAuthentication: XCTestCase {
    func test_customUnauthorizedResponseDoesNotInventChallenge() {
        AuthenticationProbeProtocol.decisions.withLock { $0 = [] }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthenticationProbeProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration, delegate: AuthenticationProbeDelegate("use"), delegateQueue: nil)
        let done = expectation(description: "custom 401")
        session.dataTask(with: URL(string: "http://authentication-probe.invalid/unauthorized")!) { data, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
            XCTAssertEqual(data, Data("denied".utf8))
            done.fulfill()
        }.resume()
        wait(for: [done], timeout: 5)
        XCTAssertEqual(AuthenticationProbeProtocol.decisions.withLock { $0 }, [])
        session.invalidateAndCancel()
    }

    func test_customChallengeReturnsEachDecisionToItsSender() {
        for mode in ["use", "default", "reject", "cancel", "noDelegate", "withoutCredential"] {
            AuthenticationProbeProtocol.decisions.withLock { $0 = [] }
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [AuthenticationProbeProtocol.self]
            configuration.urlCache = nil
            configuration.urlCredentialStorage = nil
            configuration.timeoutIntervalForRequest = 3
            let delegate = mode == "noDelegate" ? nil : AuthenticationProbeDelegate(mode)
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            let done = expectation(description: mode)
            let url = URL(string: "http://authentication-probe.invalid/challenge")!
            session.dataTask(with: url) { data, response, error in
                if mode == "cancel" {
                    XCTAssertEqual((error as? URLError)?.code, .cancelled)
                } else {
                    XCTAssertNil(error)
                    XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, mode == "use" ? 200 : 401)
                    XCTAssertEqual(data, Data((mode == "use" ? "authorized" : "denied").utf8))
                }
                done.fulfill()
            }.resume()
            wait(for: [done], timeout: 5)
            XCTAssertEqual(AuthenticationProbeProtocol.decisions.withLock { $0 },
                           [mode == "noDelegate" ? "default" : mode])
            session.invalidateAndCancel()
        }
    }
}

private final class HTTPAuthenticationDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    typealias Reply = @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    let handler: @Sendable (URLSessionTask, URLAuthenticationChallenge, @escaping Reply) -> Void

    init(_ handler: @escaping @Sendable (URLSessionTask, URLAuthenticationChallenge, @escaping Reply) -> Void) {
        self.handler = handler
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping Reply) {
        handler(task, challenge, completionHandler)
    }
}

private final class HTTPAuthenticationDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let finished: @Sendable (URL) -> Void

    init(finished: @escaping @Sendable (URL) -> Void) { self.finished = finished }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @Sendable @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(user: "user", password: "passwd", persistence: .none))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        finished(location)
    }
}

private final class HTTPAuthenticationCredentialStorage: URLCredentialStorage, @unchecked Sendable {
    let credential: URLCredential
    let useDefault: Bool
    let lookups = Mutex(0)

    init(password: String, useDefault: Bool) {
        credential = URLCredential(user: "user", password: password, persistence: .forSession)
        self.useDefault = useDefault
        super.init()
    }

    override func credentials(for space: URLProtectionSpace) -> [String: URLCredential]? {
        lookups.withLock { $0 += 1 }
        XCTAssertEqual(space.host, "127.0.0.1")
        XCTAssertEqual(space.realm, "Fake Relam")
        return useDefault ? nil : ["user": credential]
    }

    override func defaultCredential(for space: URLProtectionSpace) -> URLCredential? { credential }
}

final class TestHTTPProtocolAuthentication: LoopbackServerTest {
    private static let authorizedBody = Data("{\"authenticated\":true,\"user\":\"user\"}\n".utf8)

    func test_retryPreservesFailureCountAndFinalBody() async {
        let failures = Mutex<[Int]>([])
        let delegate = HTTPAuthenticationDelegate { _, challenge, reply in
            failures.withLock { $0.append(challenge.previousFailureCount) }
            let password = challenge.previousFailureCount == 0 ? "wrong" : "passwd"
            reply(.useCredential, URLCredential(user: "user", password: password, persistence: .none))
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let done = expectation(description: "HTTP retries")
        session.dataTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic/body")!) { data, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertEqual(data, Self.authorizedBody)
            done.fulfill()
        }.resume()
        await fulfillment(of: [done], timeout: 12)
        XCTAssertEqual(failures.withLock { $0 }, [0, 1])
    }

    func test_downloadRetryDiscardsUnauthorizedBody() async {
        let delegate = HTTPAuthenticationDelegate { _, _, reply in
            reply(.useCredential, URLCredential(user: "user", password: "passwd", persistence: .none))
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let done = expectation(description: "authenticated download")
        session.downloadTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic/body")!) { file, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertEqual(file.flatMap { try? Data(contentsOf: $0) }, Self.authorizedBody)
            done.fulfill()
        }.resume()
        await fulfillment(of: [done], timeout: 12)
    }

    func test_defaultHandlingUsesProposedCredentialOnlyOnce() async {
        for (password, useDefault) in [("passwd", false), ("wrong", false), ("passwd", true), ("wrong", true)] {
            let configuration = URLSessionConfiguration.ephemeral
            // Supply credentials by value: URLProtectionSpace currently inherits
            // NSObject identity equality, so separate equivalent spaces do not
            // find the same entry in the default storage implementation.
            let storage = HTTPAuthenticationCredentialStorage(password: password, useDefault: useDefault)
            configuration.urlCredentialStorage = storage
            let session = URLSession(configuration: configuration)
            defer { session.invalidateAndCancel() }
            let done = expectation(description: "stored credential: \(password)")
            session.dataTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic/body")!) { data, response, error in
                XCTAssertNil(error)
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, password == "passwd" ? 200 : 401)
                XCTAssertEqual(data, password == "passwd" ? Self.authorizedBody : Data(String(repeating: "denied", count: 20).utf8))
                done.fulfill()
            }.resume()
            await fulfillment(of: [done], timeout: 12)
            XCTAssertEqual(storage.lookups.withLock { $0 }, password == "passwd" ? 1 : 2)
        }
    }

    func test_delegateDownloadRetryDiscardsUnauthorizedBody() async {
        let done = expectation(description: "authenticated delegate download")
        let delegate = HTTPAuthenticationDownloadDelegate { file in
            XCTAssertEqual(try? Data(contentsOf: file), Self.authorizedBody)
            done.fulfill()
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        session.downloadTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic/body")!).resume()
        await fulfillment(of: [done], timeout: 12)
    }

    func test_decliningAndCancellingChallenges() async {
        for disposition: URLSession.AuthChallengeDisposition in [.useCredential, .performDefaultHandling, .rejectProtectionSpace, .cancelAuthenticationChallenge] {
            let delegate = HTTPAuthenticationDelegate { _, _, reply in reply(disposition, nil) }
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCredentialStorage = nil
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            defer { session.invalidateAndCancel() }
            let done = expectation(description: "HTTP disposition")
            session.dataTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic/body")!) { data, response, error in
                switch disposition {
                case .rejectProtectionSpace, .cancelAuthenticationChallenge:
                    XCTAssertEqual((error as? URLError)?.code, .cancelled)
                default:
                    XCTAssertNil(error)
                    XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
                    XCTAssertEqual(data, Data(String(repeating: "denied", count: 20).utf8))
                }
                done.fulfill()
            }.resume()
            await fulfillment(of: [done], timeout: 12)
        }
    }

    func test_successfulCredentialIsStored() async {
        let credential = URLCredential(user: "user", password: "passwd", persistence: .forSession)
        let protectionSpace = Mutex<URLProtectionSpace?>(nil)
        let delegate = HTTPAuthenticationDelegate { _, challenge, reply in
            protectionSpace.withLock { $0 = challenge.protectionSpace }
            reply(.useCredential, credential)
        }
        let configuration = URLSessionConfiguration.ephemeral
        let storage = URLCredentialStorage()
        configuration.urlCredentialStorage = storage
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let done = expectation(description: "credential persisted")
        session.dataTask(with: URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic")!) { _, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            done.fulfill()
        }.resume()
        await fulfillment(of: [done], timeout: 12)
        guard let space = protectionSpace.withLock({ $0 }) else {
            XCTFail("Missing authentication challenge")
            return
        }
        XCTAssertEqual(storage.credentials(for: space)?["user"], credential)
    }

    func test_redirectAuthorizationForSuppliedAndChallengedCredentials() async {
        for supplied in [false, true] {
            for sameOrigin in [false, true] {
                let challenges = Mutex(0)
                let delegate = HTTPAuthenticationDelegate { _, _, reply in
                    let count = challenges.withLock { $0 += 1; return $0 }
                    // Bound retries so a regression cannot create an endless challenge loop.
                    if count == 1 {
                        reply(.useCredential, URLCredential(user: "user", password: "passwd", persistence: .none))
                    } else {
                        reply(.cancelAuthenticationChallenge, nil)
                    }
                }
                let configuration = URLSessionConfiguration.ephemeral
                configuration.urlCredentialStorage = nil
                let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
                defer { session.invalidateAndCancel() }
                let done = expectation(description: "redirect: supplied=\(supplied), sameOrigin=\(sameOrigin)")
                let path = sameOrigin ? "/auth/basic/redirect-same-origin" : "/auth/basic/redirect"
                var request = URLRequest(url: URL(string: "http://127.0.0.1:\(Self.serverPort)\(path)")!)
                if supplied {
                    request.setValue("Basic dXNlcjpwYXNzd2Q=", forHTTPHeaderField: "Authorization")
                }
                session.dataTask(with: request) { data, response, error in
                    XCTAssertNil(error)
                    XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
                    XCTAssertEqual(response?.url?.host, sameOrigin ? "127.0.0.1" : "localhost")
                    XCTAssertEqual(response?.url?.path, "/requestHeaders")
                    let headers = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    if sameOrigin {
                        XCTAssertTrue(headers.contains("Basic dXNlcjpwYXNzd2Q="))
                    } else {
                        XCTAssertFalse(headers.lowercased().contains("authorization"))
                    }
                    done.fulfill()
                }.resume()
                await fulfillment(of: [done], timeout: 12)
                XCTAssertEqual(challenges.withLock { $0 }, supplied ? 0 : 1)
            }
        }
    }

    func test_replyAfterCancellationIsIgnored() async {
        for customProtocol in [false, true] {
            let pendingReply = Mutex<HTTPAuthenticationDelegate.Reply?>(nil)
            let challenged = expectation(description: "challenge received")
            let delegate = HTTPAuthenticationDelegate { _, _, reply in
                pendingReply.withLock { $0 = reply }
                challenged.fulfill()
            }
            AuthenticationProbeProtocol.decisions.withLock { $0 = [] }
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCredentialStorage = nil
            if customProtocol { configuration.protocolClasses = [AuthenticationProbeProtocol.self] }
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            defer { session.invalidateAndCancel() }
            let done = expectation(description: "cancelled while awaiting credentials")
            let url = customProtocol ? URL(string: "http://authentication-probe.invalid/challenge")!
                : URL(string: "http://127.0.0.1:\(Self.serverPort)/auth/basic")!
            let task = session.dataTask(with: url) { _, _, error in
                XCTAssertEqual((error as? URLError)?.code, .cancelled)
                done.fulfill()
            }
            task.resume()
            await fulfillment(of: [challenged], timeout: 12)
            task.cancel()
            await fulfillment(of: [done], timeout: 12)
            let callbacksFinished = expectation(description: "cancellation callback returned")
            session.delegateQueue.addOperation { callbacksFinished.fulfill() }
            await fulfillment(of: [callbacksFinished], timeout: 12)
            let reply = pendingReply.withLock { $0 }
            reply?(.useCredential, URLCredential(user: "user", password: "passwd", persistence: .none))
            XCTAssertEqual(task.state, .completed)
            XCTAssertEqual(AuthenticationProbeProtocol.decisions.withLock { $0 }, [])
        }
    }
}
