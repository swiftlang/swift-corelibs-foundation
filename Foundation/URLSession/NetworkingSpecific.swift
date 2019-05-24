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
    func contentsOf(url: URL) throws -> (result: NSData, textEncodingNameIfAvailable: String?) {
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
        
        guard let data = resData else {
            throw resError!
        }
        return (NSData(bytes: UnsafeMutableRawPointer(mutating: (data as NSData).bytes), length: data.count), urlResponse?.textEncodingName)
    }
}
