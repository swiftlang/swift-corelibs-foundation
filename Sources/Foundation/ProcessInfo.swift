// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal import CoreFoundation

// SPI for TestFoundation
internal extension ProcessInfo {
  var _processPath: String {
    return String(cString: _CFProcessPath())
  }
}
