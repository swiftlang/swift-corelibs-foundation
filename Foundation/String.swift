//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import CoreFoundation

extension String : _ObjectiveCBridgeable {
    
    public typealias _ObjectType = NSString
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSString(self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout String?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout String?) -> Bool {
        if type(of: source) == NSString.self || type(of: source) == NSMutableString.self {
            result = source._storage
        } else if type(of: source) == _NSCFString.self {
            let cf = unsafeBitCast(source, to: CFString.self)
            if let str = CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingUTF8)) {
                result = String(cString: str)
            } else {
                let length = CFStringGetLength(cf)
                let buffer = UnsafeMutablePointer<UniChar>.allocate(capacity: length)
                CFStringGetCharacters(cf, CFRangeMake(0, length), buffer)
                
                let str = String(decoding: UnsafeBufferPointer(start: buffer, count: length), as: UTF16.self)
                buffer.deinitialize(count: length)
                buffer.deallocate()
                result = str
            }
        } else if type(of: source) == _NSCFConstantString.self {
            let conststr = unsafeDowncast(source, to: _NSCFConstantString.self)
            let str = String(decoding: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)), as: UTF8.self)
            result = str
        } else {
            let len = source.length
            var characters = [unichar](repeating: 0, count: len)
            result = characters.withUnsafeMutableBufferPointer() { (buffer: inout UnsafeMutableBufferPointer<unichar>) -> String? in
                source.getCharacters(buffer.baseAddress!, range: NSRange(location: 0, length: len))
                return String(decoding: buffer, as: UTF16.self)
            }
        }
        return result != nil
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> String {
        if let object = source {
            var value: String?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return ""
        }
    }
}
