// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation

// NSURL and URL are implemented in Swift. CoreFoundation has its own, separate CFURL that it uses internally (for example, in CFBundle).
// These conversions go through the URL string so that the two never share storage.

extension URL {
    /// A new `CFURL` with the same string and base URL.
    internal var _cfObject: CFURL {
        return CFURLCreateWithString(kCFAllocatorSystemDefault, relativeString._cfObject, baseURL?._cfObject)
    }
}

extension CFURL {
    internal var _swiftObject: URL {
        let string = CFURLGetString(self)._swiftObject
        let base = CFURLGetBaseURL(self)?._swiftObject
        return URL(string: string, relativeTo: base)!
    }

    internal var _nsObject: NSURL {
        return NSURL(_url: _swiftObject)
    }
}

extension CFArray {
    /// Converts an array of `CFURL` to `NSURL`.
    internal var _urlArray: [NSURL] {
        let count = CFArrayGetCount(self)
        return (0..<count).map { index in
            unsafeBitCast(CFArrayGetValueAtIndex(self, index), to: CFURL.self)._nsObject
        }
    }
}
