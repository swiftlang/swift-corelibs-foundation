// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal final class _NSCFSet : NSMutableSet {
    deinit {
        _CFDeinit(self)
        _CFZeroUnsafeIvars(&_storage)
    }
    
    required init() {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    required init(capacity numItems: Int) {
        fatalError()
    }
    
    override var classForCoder: AnyClass {
        return NSMutableSet.self
    }
}
