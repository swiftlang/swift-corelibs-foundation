// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFLogLevelEmergency = CFLogLevel.emergency
internal let kCFLogLevelAlert = CFLogLevel.alert
internal let kCFLogLevelCritical = CFLogLevel.critical
internal let kCFLogLevelError = CFLogLevel.error
internal let kCFLogLevelWarning = CFLogLevel.warning
internal let kCFLogLevelNotice = CFLogLevel.notice
internal let kCFLogLevelInfo = CFLogLevel.info
internal let kCFLogLevelDebug = CFLogLevel.debug
#endif

internal func NSLog(_ message : String) {
#if os(OSX) || os(iOS)
    CFLog1(kCFLogLevelWarning, message._cfObject)
#else
    CFLog1(Int32(kCFLogLevelWarning), message._cfObject)
#endif
}
