// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

/* Output from NSLogv is serialized, in that only one thread in a process can be doing 
 * the writing/logging described above at a time. All attempts at writing/logging a 
 * message complete before the next thread can begin its attempts. The format specification 
 * allowed by these functions is that which is understood by NSString's formatting capabilities.
 * CFLog1() uses writev/fprintf to write to stderr. Both these functions ensure atomic writes.
 */

public func NSLogv(_ format: String, _ args: CVaListPointer) {
    let message = NSString(format: format, arguments: args)
    CFLog1(CFLogLevel(kCFLogLevelWarning), message._cfObject)
}

public func NSLog(_ format: String, _ args: CVarArg...) {
    withVaList(args) { 
        NSLogv(format, $0) 
    }
}
