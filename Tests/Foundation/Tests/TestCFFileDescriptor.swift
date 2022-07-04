// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(Linux)
    import CoreFoundation
    import Dispatch
    import Glibc

    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
            @testable import SwiftFoundation
        #else
            @testable import Foundation
        #endif
    #endif

    let kCFRunLoopSourceOrder: CFIndex = 600

    // TODO: maybe add epoll related API to Glibc swift module to avoid dynamically loading these functions in tests
    typealias eventfd_f = @convention(c) (_ count: CUnsignedInt, _ flags: CInt) -> CInt
    typealias eventfd_read_f = @convention(c) (_ fd: CInt, _ value: UnsafeMutablePointer<UInt64>) -> CInt
    typealias eventfd_write_f = @convention(c) (_ fd: CInt, _ value: UInt64) -> CInt
    typealias explain_eventfd_f = @convention(c) (_ count: CUnsignedInt, _ flags: CInt) -> UnsafePointer<CChar>?

    let eventfd_p: eventfd_f = {
        guard let symbol = dlsym(nil, "eventfd") else {
            return { _, _ in -1 }
        }

        return unsafeBitCast(symbol, to: eventfd_f.self)
    }()

    let eventfd_read_p: eventfd_read_f = {
        guard let symbol = dlsym(nil, "eventfd_read") else {
            return { _, _ in -1 }
        }

        return unsafeBitCast(symbol, to: eventfd_read_f.self)
    }()

    let eventfd_write_p: eventfd_write_f = {
        guard let symbol = dlsym(nil, "eventfd_write") else {
            return { _, _ in -1 }
        }

        return unsafeBitCast(symbol, to: eventfd_write_f.self)
    }()

    let explain_eventfd_p: explain_eventfd_f = {
        guard let symbol = dlsym(nil, "explain_eventfd") else {
            return { _, _ in nil }
        }

        return unsafeBitCast(symbol, to: explain_eventfd_f.self)
    }()

    class FileDescriptorTestHelper {
        typealias Callback = (_ helper: FileDescriptorTestHelper) -> Void

        let callback: Callback
        private(set) var cffd: CFFileDescriptor!
        let fd: CInt

        deinit {
            invalidate()
        }

        init(_ fd: CInt, callback: @escaping Callback) throws {
            self.callback = callback
            self.fd = fd

            let callout: CFFileDescriptorCallBack = { _, info in
                let helper = Unmanaged<FileDescriptorTestHelper>.fromOpaque(info!).takeUnretainedValue()

                helper.callback(helper)
            }

            var context = CFFileDescriptorContext()
            context.info = Unmanaged.passUnretained(self).toOpaque()

            cffd = try XCTUnwrap(CFFileDescriptorCreate(kCFAllocatorSystemDefault /* allocator */,
                                                        fd /* fileDescriptor */,
                                                        true /* closeOnInvalidate */,
                                                        callout /* callout */,
                                                        &context /* context */ ))
        }

        func enableCallbacks(_ callbacks: CFFileDescriptorCallBackIdentifier) {
            CFFileDescriptorEnableCallBacks(cffd, callbacks.rawValue)
        }

        func invalidate() {
            if CFFileDescriptorIsValid(cffd) {
                CFFileDescriptorInvalidate(cffd)
            }
        }

        func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) throws {
            let source = try XCTUnwrap(CFFileDescriptorCreateRunLoopSource(nil, cffd, kCFRunLoopSourceOrder))
            CFRunLoopAddSource(runLoop.currentCFRunLoop, source, mode._cfStringUniquingKnown)
        }

        func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode) {
            if let source = CFFileDescriptorCreateRunLoopSource(nil, cffd, kCFRunLoopSourceOrder) {
                CFRunLoopRemoveSource(runLoop.currentCFRunLoop, source, mode.rawValue._cfObject)
            }
        }
    }

    class TestCFFileDescriptor: XCTestCase {
        func createEventFD() -> CInt {
            return eventfd_p(0, O_CLOEXEC | O_NONBLOCK)
        }

        func testCFFileDescriptorCallOutFileDescriptorPortDelegate() throws {
            let fd = createEventFD()
            var awokenCounter = 0
            let writtenValue: UInt64 = 42

            let helper = try FileDescriptorTestHelper(fd) { helper in
                XCTAssertEqual(fd, helper.fd)

                var readValue: UInt64 = 0
                _ = eventfd_read_p(helper.fd, &readValue)

                XCTAssertEqual(writtenValue, readValue)

                awokenCounter += 1
            }

            defer {
                helper.invalidate()
            }

            let runLoop = RunLoop.current

            helper.enableCallbacks(.read)
            try helper.schedule(in: .main, forMode: .common)
            defer {
                helper.remove(from: .main, forMode: .common)
            }

            DispatchQueue.main.async {
                _ = eventfd_write_p(fd, writtenValue)
            }

            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))

            XCTAssertEqual(awokenCounter, 1)

            helper.enableCallbacks(.read)
            DispatchQueue.main.async {
                _ = eventfd_write_p(fd, writtenValue)
            }

            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))

            XCTAssertEqual(awokenCounter, 2)
        }

        func testCFFileDescriptorCallBackNotEnabledAgainCallsOutOnlyOnce() throws {
            let fd = createEventFD()
            var awokenCounter = 0
            var writtenValue: UInt64 = 42

            let helper = try FileDescriptorTestHelper(fd) { helper in
                XCTAssertEqual(fd, helper.fd)

                awokenCounter += 1
            }

            defer {
                helper.invalidate()
            }

            let runLoop = RunLoop.current

            helper.enableCallbacks(.read)
            try helper.schedule(in: .main, forMode: .common)
            defer {
                helper.remove(from: .main, forMode: .common)
            }

            DispatchQueue.main.async {
                _ = eventfd_write_p(fd, writtenValue)
            }

            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))

            XCTAssertEqual(awokenCounter, 1)

            writtenValue = 43

            DispatchQueue.main.async {
                _ = eventfd_write_p(fd, writtenValue)
            }

            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))

            XCTAssertEqual(awokenCounter, 1)
        }

        func testCFFileDescriptorCallBackEnabledAgainWithoutServicingFDCallsOutMoreThanOnce() throws {
            let fd = createEventFD()
            var awokenCounter = 0
            let writtenValue: UInt64 = 42

            let helper = try FileDescriptorTestHelper(fd) { helper in
                XCTAssertEqual(fd, helper.fd)

                helper.enableCallbacks(.read)

                awokenCounter += 1
            }

            defer {
                helper.invalidate()
            }

            let runLoop = RunLoop.current

            helper.enableCallbacks(.read)
            try helper.schedule(in: .main, forMode: .common)
            defer {
                helper.remove(from: .main, forMode: .common)
            }

            DispatchQueue.main.async {
                _ = eventfd_write_p(fd, writtenValue)
            }

            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))

            XCTAssertTrue(awokenCounter > 1)
        }

        static var allTests: [(String, (TestCFFileDescriptor) -> () throws -> Void)] {
            return [
                ("testCFFileDescriptorCallOutFileDescriptorPortDelegate", testCFFileDescriptorCallOutFileDescriptorPortDelegate),
                ("testCFFileDescriptorCallBackNotEnabledAgainCallsOutOnlyOnce", testCFFileDescriptorCallBackNotEnabledAgainCallsOutOnlyOnce),
                ("testCFFileDescriptorCallBackEnabledAgainWithoutServicingFDCallsOutMoreThanOnce", testCFFileDescriptorCallBackEnabledAgainWithoutServicingFDCallsOutMoreThanOnce),
            ]
        }
    }

#endif
