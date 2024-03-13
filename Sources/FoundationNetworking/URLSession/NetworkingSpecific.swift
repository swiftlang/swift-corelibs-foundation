// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif

@_spi(SwiftCorelibsFoundation) import FoundationEssentials

internal func NSUnimplemented(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not yet implemented. \(file):\(line)")
    #endif
    fatalError("\(fn) is not yet implemented", file: file, line: line)
}

internal func NSUnsupported(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not supported. \(file):\(line)")
    #endif
    fatalError("\(fn) is not supported", file: file, line: line)
}

internal func NSRequiresConcreteImplementation(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) must be overridden. \(file):\(line)")
    #endif
    fatalError("\(fn) must be overridden", file: file, line: line)
}

@usableFromInline
class _NSNonfileURLContentLoader: _NSNonfileURLContentLoading {
    @usableFromInline
    required init() {}
    
    @usableFromInline
    func contentsOf(url: Foundation.URL) throws -> (result: NSData, textEncodingNameIfAvailable: String?) {

        func cocoaError(with error: Error? = nil) -> Error {
            var userInfo: [String: AnyHashable] = [:]
            if let error = error as? AnyHashable {
                userInfo[NSUnderlyingErrorKey] = error
            }
            // Temporary workaround for lack of URL in swift-foundation
            // TODO: Replace with argument
            let feURL = FoundationEssentials.URL(path: url.path)
            return CocoaError.error(.fileReadUnknown, userInfo: userInfo, url: feURL)
        }

        var urlResponse: URLResponse?
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let cond = NSCondition()
        cond.lock()
        
        var resError: Error?
        var resData: Data?
        var taskFinished = false
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            cond.lock()
            resData = data
            urlResponse = response
            resError = error
            taskFinished = true
            cond.signal()
            cond.unlock()
        })
        
        task.resume()
        while taskFinished == false {
            cond.wait()
        }
        cond.unlock()

        guard resError == nil else {
            throw cocoaError(with: resError)
        }

        guard let data = resData else {
            throw cocoaError()
        }

        if let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode {
            switch statusCode {
                // These are the only valid response codes that data will be returned for, all other codes will be treated as error.
                case 101, 200...399, 401, 407:
                    return (NSData(data: data), urlResponse?.textEncodingName)

                default:
                    break
            }
        }
        throw cocoaError()
    }
}
