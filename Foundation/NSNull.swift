// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class NSNull : NSObject, NSCopying, NSSecureCoding {
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override init() {
        // Nothing to do here
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // Nothing to do here
    }
    
    open func encode(with aCoder: NSCoder) {
        // Nothing to do here
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        return object is NSNull
    }
}

public func ===(lhs: NSNull?, rhs: NSNull?) -> Bool {
    guard let _ = lhs, let _ = rhs else { return false }
    return true
}
