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

extension unichar : ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = UnicodeScalar
    
    public init(unicodeScalarLiteral scalar: UnicodeScalar) {
        self.init(scalar.value)
    }
}

extension String {
    public init(_ cocoaString: NSString) {
        var len: Int = 0
        if let str = cocoaString as? _NSSwiftString {
            self = str._storage
            return
        } else {
            if let cstr = cocoaString._fastCStringContents(true) {
                self = String(cString: cstr)
                return
            } else if let chars = cocoaString._fastCharacterContents() {
                len = cocoaString.length
                if let str = String._fromCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: chars, count: len)) {
                    self = str
                    return
                }
            } else {
                len = cocoaString.length
            }
        }
        if len == 0 {
            self = ""
            return
        }
        var buffer = [unichar](repeating: 0, count: len)
        self = buffer.withUnsafeMutableBufferPointer {
            cocoaString.getCharacters($0.baseAddress!, range: NSRange(location: 0, length: len))
            return String._fromCodeUnitSequence(UTF16.self, input: $0)!
        }
    }
}

extension String : _ObjectTypeBridgeable {
    
    public typealias _ObjectType = NSString
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSString(string: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout String?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout String?) -> Bool {
        if let str = source as? _NSSwiftString {
            result = str._storage
            return true
        } else if type(of: source) == _NSCFString.self {
            let cf = unsafeBitCast(source, to: CFString.self)
            let str = CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingUTF8))
            if str != nil {
                result = String(cString: str!)
            } else {
                let length = CFStringGetLength(cf)
                let buffer = UnsafeMutablePointer<UniChar>.allocate(capacity: length)
                CFStringGetCharacters(cf, CFRangeMake(0, length), buffer)
                
                let str = String._fromCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: buffer, count: length))
                buffer.deinitialize(count: length)
                buffer.deallocate(capacity: length)
                result = str
            }
        } else if type(of: source) == _NSCFConstantString.self {
            let conststr = unsafeDowncast(source, to: _NSCFConstantString.self)
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

