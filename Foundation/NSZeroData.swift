// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal final class _NSZeroData : NSData {
    override var length: Int { return 0 }
    override var bytes: UnsafeRawPointer { return __NSDataNullBytes }
    
    override func _isCompact() -> Bool {
        return true
    }
    
    override func _providesConcreteBacking() -> Bool {
        return true
    }
}
