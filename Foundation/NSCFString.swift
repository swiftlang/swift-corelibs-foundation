// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal class _NSCFString : NSMutableString {
    required init(characters: UnsafePointer<unichar>, length: Int) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    required init(extendedGraphemeClusterLiteral value: StaticString) {
        fatalError()
    }

    required init(stringLiteral value: StaticString) {
        fatalError()
    }

    required init(capacity: Int) {
        fatalError()
    }

    required init(string aString: String) {
        fatalError()
    }
    
    deinit {
        _CFDeinit(self)
        _CFZeroUnsafeIvars(&_storage)
    }
    
    override var length: Int {
        return CFStringGetLength(unsafeBitCast(self, CFStringRef.self))
    }
    
    override func characterAtIndex(index: Int) -> unichar {
        return CFStringGetCharacterAtIndex(unsafeBitCast(self, CFStringRef.self), index)
    }
    
    override func replaceCharactersInRange(range: NSRange, withString aString: String) {
        CFStringReplace(unsafeBitCast(self, CFMutableStringRef.self), CFRangeMake(range.location, range.length), aString._cfObject)
    }
    
    override var classForCoder: AnyClass {
        return NSMutableString.self
    }
}

internal final class _NSCFConstantString : _NSCFString {
    internal var _ptr : UnsafePointer<UInt8> {
        let ptr = unsafeAddressOf(self) + sizeof(COpaquePointer) + sizeof(Int32) + sizeof(Int32) + sizeof(_CFInfo)
        return UnsafePointer<UnsafePointer<UInt8>>(ptr).memory
    }
    internal var _length : UInt32 {
        let offset = sizeof(COpaquePointer) + sizeof(Int32) + sizeof(Int32) + sizeof(_CFInfo) + sizeof(UnsafePointer<UInt8>)
        let ptr = unsafeAddressOf(self) + offset
        return UnsafePointer<UInt32>(ptr).memory
    }
    
    required init(characters: UnsafePointer<unichar>, length: Int) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    required init(extendedGraphemeClusterLiteral value: StaticString) {
        fatalError()
    }
    
    required init(stringLiteral value: StaticString) {
        fatalError()
    }
    
    required init(capacity: Int) {
        fatalError()
    }

    required init(string aString: String) {
        fatalError("Constant strings cannot be constructed in code")
    }
    
    deinit {
        fatalError("Constant strings cannot be deallocated")
    }

    override var length: Int {
        return Int(_length)
    }
    
    override func characterAtIndex(index: Int) -> unichar {
        return unichar(_ptr[index])
    }
    
    override func replaceCharactersInRange(range: NSRange, withString aString: String) {
        fatalError()
    }
    
    override var classForCoder: AnyClass {
        return NSString.self
    }
}

internal func _CFSwiftStringGetLength(string: AnyObject) -> CFIndex {
    return (string as! NSString).length
}

internal func _CFSwiftStringGetCharacterAtIndex(str: AnyObject, index: CFIndex) -> UniChar {
    return (str as! NSString).characterAtIndex(index)
}

internal func _CFSwiftStringGetCharacters(str: AnyObject, range: CFRange, buffer: UnsafeMutablePointer<UniChar>) {
    (str as! NSString).getCharacters(buffer, range: NSMakeRange(range.location, range.length))
}

internal func _CFSwiftStringGetBytes(str: AnyObject, encoding: CFStringEncoding, range: CFRange, buffer: UnsafeMutablePointer<UInt8>, maxBufLen: CFIndex, usedBufLen: UnsafeMutablePointer<CFIndex>) -> CFIndex {
    switch encoding {
        // TODO: Don't treat many encodings like they are UTF8
    case CFStringEncoding(kCFStringEncodingUTF8), CFStringEncoding(kCFStringEncodingISOLatin1), CFStringEncoding(kCFStringEncodingMacRoman), CFStringEncoding(kCFStringEncodingASCII), CFStringEncoding(kCFStringEncodingNonLossyASCII):
        let encodingView = (str as! NSString)._swiftObject.utf8
        let start = encodingView.startIndex
        if buffer != nil {
            for idx in 0..<range.length {
                let character = encodingView[start.advancedBy(idx + range.location)]
                buffer.advancedBy(idx).initialize(character)
            }
        }
        if usedBufLen != nil {
            usedBufLen.memory = range.length
        }
        
    case CFStringEncoding(kCFStringEncodingUTF16):
        let encodingView = (str as! NSString)._swiftObject.utf16
        let start = encodingView.startIndex
        if buffer != nil {
            for idx in 0..<range.length {
                // Since character is 2 bytes but the buffer is in term of 1 byte values, we have to split it up
                let character = encodingView[start.advancedBy(idx + range.location)]
                let byte0 = UInt8(character & 0x00ff)
                let byte1 = UInt8((character >> 8) & 0x00ff)
                buffer.advancedBy(idx * 2).initialize(byte0)
                buffer.advancedBy((idx * 2) + 1).initialize(byte1)
            }
        }
        if usedBufLen != nil {
            // Every character was 2 bytes
            usedBufLen.memory = range.length * 2
        }


    default:
        fatalError("Attempted to get bytes of a Swift string using an unsupported encoding")
    }
    
    return range.length
}

internal func _CFSwiftStringCreateWithSubstring(str: AnyObject, range: CFRange) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).substringWithRange(NSMakeRange(range.location, range.length))._nsObject)
}


internal func _CFSwiftStringCreateCopy(str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).copyWithZone(nil))
}

internal func _CFSwiftStringCreateMutableCopy(str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).mutableCopyWithZone(nil))
}

internal func _CFSwiftStringFastCStringContents(str: AnyObject) -> UnsafePointer<Int8> {
    return (str as! NSString)._fastCStringContents
}

internal func _CFSwiftStringFastContents(str: AnyObject) -> UnsafePointer<UniChar> {
    return (str as! NSString)._fastContents
}

internal func _CFSwiftStringGetCString(str: AnyObject, buffer: UnsafeMutablePointer<Int8>, maxLength: Int, encoding: CFStringEncoding) -> Bool {
    return (str as! NSString).getCString(buffer, maxLength: maxLength, encoding: CFStringConvertEncodingToNSStringEncoding(encoding))
}

internal func _CFSwiftStringIsUnicode(str: AnyObject) -> Bool {
    return (str as! NSString)._encodingCantBeStoredInEightBitCFString
}

internal func _CFSwiftStringInsert(str: AnyObject, index: CFIndex, inserted: AnyObject) {
    (str as! NSMutableString).insertString((inserted as! NSString)._swiftObject, atIndex: index)
}

internal func _CFSwiftStringDelete(str: AnyObject, range: CFRange) {
    (str as! NSMutableString).deleteCharactersInRange(NSMakeRange(range.location, range.length))
}

internal func _CFSwiftStringReplace(str: AnyObject, range: CFRange, replacement: AnyObject) {
    (str as! NSMutableString).replaceCharactersInRange(NSMakeRange(range.location, range.length), withString: (replacement as! NSString)._swiftObject)
}

internal func _CFSwiftStringReplaceAll(str: AnyObject, replacement: AnyObject) {
    (str as! NSMutableString).setString((replacement as! NSString)._swiftObject)
}

internal func _CFSwiftStringAppend(str: AnyObject, appended: AnyObject) {
    (str as! NSMutableString).appendString((appended as! NSString)._swiftObject)
}

internal func _CFSwiftStringAppendCharacters(str: AnyObject, chars: UnsafePointer<UniChar>, length: CFIndex) {
    (str as! NSMutableString).appendCharacters(chars, length: length)
}

internal func _CFSwiftStringAppendCString(str: AnyObject, chars: UnsafePointer<Int8>, length: CFIndex) {
    (str as! NSMutableString)._cfAppendCString(chars, length: length)
}

