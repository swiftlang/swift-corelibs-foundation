//
//  NSStringBridge.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 6/24/17.
//  Copyright © 2017 Apple. All rights reserved.
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
