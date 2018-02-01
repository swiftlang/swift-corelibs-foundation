// This source file is part of the Swift.org open source project
//
// Copyright (c) 2017 Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(Linux)
    import Foundation
#else
    import SwiftFoundation
#endif

enum HelperCheckStatus : Int32 {
    case ok                 = 0
    case fail               = 1
    case cookieStorageNil   = 20
    case cookieStorePathWrong
}

protocol HelperCheck {

    static func run() -> Never
}

XDGCheck.run()

