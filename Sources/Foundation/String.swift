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

internal import CoreFoundation

extension String: _ObjectiveCBridgeable {
    
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
            let length = CFStringGetLength(cf)
            if length == 0 {
                result = ""
            } else if let ptr = CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingASCII)) {
                // ASCII encoding has 1 byte per code point and CFStringGetLength() returned the length in
                // codepoints so length should be the length of the ASCII string in bytes. We can't ask for the UTF-8
                // encoding as some codepoints are multi-byte in UTF8 so the buffer length wouldn't be known.
                // Note: CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingUTF8)) does seems to return NULL
                // for strings with multibyte UTF-8 but this isn't guaranteed or documented so ASCII is safer.
                result = ptr.withMemoryRebound(to: UInt8.self, capacity: length) {
                    return String(decoding: UnsafeBufferPointer(start: $0, count: length), as: UTF8.self)
                }
            } else if let ptr = CFStringGetCharactersPtr(cf) {
                result = String(decoding: UnsafeBufferPointer(start: ptr, count: length), as: UTF16.self)
            } else {
                let buffer = UnsafeMutablePointer<UniChar>.allocate(capacity: length)
                CFStringGetCharacters(cf, CFRangeMake(0, length), buffer)
                
                result = String(decoding: UnsafeBufferPointer(start: buffer, count: length), as: UTF16.self)
                buffer.deinitialize(count: length)
                buffer.deallocate()
            }
        } else if type(of: source) == _NSCFConstantString.self {
            let conststr = unsafeDowncast(source, to: _NSCFConstantString.self)
            result = String(decoding: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)), as: UTF8.self)
        } else {
            let len = source.length
            let characters = [unichar](unsafeUninitializedCapacity: len) { buf, initializedCount in
                source.getCharacters(buf.baseAddress!, range: NSRange(location: 0, length: len))
                initializedCount = len
            }
            result = String(decoding: characters, as: UTF16.self)
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


extension Substring: _ObjectiveCBridgeable {

    public func _bridgeToObjectiveC() -> NSString {
        return NSString(String(self))
    }

    public static func _forceBridgeFromObjectiveC(_ source: NSString, result: inout Substring?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }

    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSString, result: inout Substring?) -> Bool {
        var value: String?
        if String._conditionallyBridgeFromObjectiveC(source, result: &value) {
            result = Substring(value!)
            return true
        } else {
            return false
        }
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSString?) -> Substring {
        if let object = source {
            var value: Substring?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return ""
        }
    }

}
