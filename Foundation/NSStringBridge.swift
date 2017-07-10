// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension NSString : _CFBridgeable, _SwiftBridgeable {
    var _cfObject: CFString { return _unsafeReferenceCast(self, to: CFString.self) }
    var _swiftObject: String { return String(self) }
}

extension CFString : _NSBridgeable, _SwiftBridgeable {
    var _nsObject: NSString { return _unsafeReferenceCast(self, to: NSString.self) }
    var _swiftObject: String { return String(_nsObject) }
}

extension String : _CFBridgeable, _NSBridgeable {
    var _cfObject: CFString { return _unsafeReferenceCast(_nsObject, to: CFString.self) }
    var _nsObject: NSString { return NSString(string: self) }
}

extension NSString : _StructTypeBridgeable {
    public func _bridgeToSwift() -> String {
        return String(self)
    }
}
