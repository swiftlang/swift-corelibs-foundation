// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFLogLevelEmergency = CFLogLevel.Emergency
internal let kCFLogLevelAlert = CFLogLevel.Alert
internal let kCFLogLevelCritical = CFLogLevel.Critical
internal let kCFLogLevelError = CFLogLevel.Error
internal let kCFLogLevelWarning = CFLogLevel.Warning
internal let kCFLogLevelNotice = CFLogLevel.Notice
internal let kCFLogLevelInfo = CFLogLevel.Info
internal let kCFLogLevelDebug = CFLogLevel.Debug
#endif

internal func NSLog(message : String) {
#if os(OSX) || os(iOS)
    CFLog1(kCFLogLevelWarning, message._cfObject)
#else
    CFLog1(Int32(kCFLogLevelWarning), message._cfObject)
#endif
}
