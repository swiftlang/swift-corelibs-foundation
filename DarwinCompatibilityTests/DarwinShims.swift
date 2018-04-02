// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// These shims are used solely by the DarwinCompatibilityTests Xcode project to
// allow the TestFoundation tests to compile and run against Darwin's native
// Foundation.
// It contains wrappers for methods (some experimental) added in
// swift-corelibs-foundation which do not exist in Foundation, and other small
// differences.

import Foundation


public typealias unichar = UInt16

extension unichar : ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = UnicodeScalar

    public init(unicodeScalarLiteral scalar: UnicodeScalar) {
        self.init(scalar.value)
    }
}

extension NSURL {
    func checkResourceIsReachable() throws -> Bool {
        var error: NSError?
        if checkResourceIsReachableAndReturnError(&error) {
            return true
        } else {
            if let e = error {
                throw e
            }
        }
        return false
    }
}

extension Thread {
    class var mainThread: Thread {
        return Thread.main
    }
}

extension Scanner {
    public func scanString(_ searchString: String) -> String? {
        var result: NSString? = nil
        if scanString(searchString, into: &result), let str = result {
            return str as String
        }
        return nil
    }
}

extension JSONSerialization {
    class func writeJSONObject(_ obj: Any, toStream stream: OutputStream, options opt: WritingOptions) throws -> Int {
        var error: NSError?
        let ret = writeJSONObject(obj, to: stream, options: opt, error: &error)
        guard ret != 0 else {
            throw error!
        }
        return ret
    }
}

extension NSIndexSet {
    func _bridgeToSwift() -> NSIndexSet {
        return self
    }
}

extension CharacterSet {
    func _bridgeToSwift() -> CharacterSet {
        return self
    }
}

extension NSCharacterSet {
    func _bridgeToSwift() -> CharacterSet {
        return self as CharacterSet
    }
}
