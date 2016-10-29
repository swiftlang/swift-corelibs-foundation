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

extension String : _ObjectTypeBridgeable {
    
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
            let length = CFStringGetLength(cf) // This value is not always the length in characters, in spite of what the documentation says

            // FIXME: If we had a reliable way to determine the length of `cf`
            //        in bytes, then we wouldn't have to allocate a new buffer
            //        if `CFStringGetCStringPtr(_:_:)` doesn't return nil.
            if let buffer = CFStringGetCharactersPtr(cf) {
                result = String._fromCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: buffer, count: length))
            } else {
                // Retrieving Unicode characters is unreliable; instead retrieve UTF8-encoded bytes
                let max = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8)
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: max)
                var count: CFIndex = -1
                CFStringGetBytes(cf, CFRangeMake(0, length), kCFStringEncodingUTF8, 0, false, buffer, max, &count)
                let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: buffer, count: count))
                buffer.deinitialize(count: length)
                buffer.deallocate(capacity: length)
                result = str
            }
        } else if type(of: source) == _NSCFConstantString.self {
            let conststr = unsafeBitCast(source, to: _NSCFConstantString.self)
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)))
            result = str
        } else {
            let len = source.length
            var characters = [unichar](repeating: 0, count: len)
            result = characters.withUnsafeMutableBufferPointer() { (buffer: inout UnsafeMutableBufferPointer<unichar>) -> String? in
                source.getCharacters(buffer.baseAddress!, range: NSMakeRange(0, len))
                return String._fromCodeUnitSequence(UTF16.self, input: buffer)
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

