// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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
        return CFStringGetLength(unsafeBitCast(self, to: CFString.self))
    }
    
    override func character(at index: Int) -> unichar {
        return CFStringGetCharacterAtIndex(unsafeBitCast(self, to: CFString.self), index)
    }
    
    override func replaceCharacters(in range: NSRange, with aString: String) {
        CFStringReplace(unsafeBitCast(self, to: CFMutableString.self), CFRangeMake(range.location, range.length), aString._cfObject)
    }
    
    override var classForCoder: AnyClass {
        return NSMutableString.self
    }
}

internal final class _NSCFConstantString : _NSCFString {
    internal var _ptr : UnsafePointer<UInt8> {
        let offset = MemoryLayout<OpaquePointer>.size + MemoryLayout<Int32>.size + MemoryLayout<Int32>.size + MemoryLayout<_CFInfo>.size
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        return ptr.load(fromByteOffset: offset, as: UnsafePointer<UInt8>.self)
    }
    internal var _length : UInt32 {
        let offset = MemoryLayout<OpaquePointer>.size + MemoryLayout<Int32>.size + MemoryLayout<Int32>.size + MemoryLayout<_CFInfo>.size + MemoryLayout<UnsafePointer<UInt8>>.size
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        return ptr.load(fromByteOffset: offset, as: UInt32.self)
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
    
    override func character(at index: Int) -> unichar {
        return unichar(_ptr[index])
    }
    
    override func replaceCharacters(in range: NSRange, with aString: String) {
        fatalError()
    }
    
    override var classForCoder: AnyClass {
        return NSString.self
    }
}

internal func _CFSwiftStringGetLength(_ string: AnyObject) -> CFIndex {
    return (string as! NSString).length
}

internal func _CFSwiftStringGetCharacterAtIndex(_ str: AnyObject, index: CFIndex) -> UniChar {
    return (str as! NSString).character(at: index)
}

internal func _CFSwiftStringGetCharacters(_ str: AnyObject, range: CFRange, buffer: UnsafeMutablePointer<UniChar>) {
    (str as! NSString).getCharacters(buffer, range: NSMakeRange(range.location, range.length))
}

internal func _CFSwiftStringGetBytes(_ str: AnyObject, encoding: CFStringEncoding, range: CFRange, buffer: UnsafeMutablePointer<UInt8>?, maxBufLen: CFIndex, usedBufLen: UnsafeMutablePointer<CFIndex>?) -> CFIndex {
    switch encoding {
        // TODO: Don't treat many encodings like they are UTF8
    case CFStringEncoding(kCFStringEncodingUTF8), CFStringEncoding(kCFStringEncodingISOLatin1), CFStringEncoding(kCFStringEncodingMacRoman), CFStringEncoding(kCFStringEncodingASCII), CFStringEncoding(kCFStringEncodingNonLossyASCII):
        let encodingView = (str as! NSString)._swiftObject.utf8
        let start = encodingView.startIndex
        if let buffer = buffer {
            for idx in 0..<range.length {
                let characterIndex = encodingView.index(start, offsetBy: idx + range.location)
                let character = encodingView[characterIndex]
                buffer.advanced(by: idx).initialize(to: character)
            }
        }
        usedBufLen?.pointee = range.length
        
    case CFStringEncoding(kCFStringEncodingUTF16):
        let encodingView = (str as! NSString)._swiftObject.utf16
        let start = encodingView.startIndex
        if let buffer = buffer {
            for idx in 0..<range.length {
                // Since character is 2 bytes but the buffer is in term of 1 byte values, we have to split it up
                let character = encodingView[start.advanced(by: idx + range.location)]
                let byte0 = UInt8(character & 0x00ff)
                let byte1 = UInt8((character >> 8) & 0x00ff)
                buffer.advanced(by: idx * 2).initialize(to: byte0)
                buffer.advanced(by: (idx * 2) + 1).initialize(to: byte1)
            }
        }
        // Every character was 2 bytes
        usedBufLen?.pointee = range.length * 2


    default:
        fatalError("Attempted to get bytes of a Swift string using an unsupported encoding")
    }
    
    return range.length
}

internal func _CFSwiftStringCreateWithSubstring(_ str: AnyObject, range: CFRange) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).substring(with: NSMakeRange(range.location, range.length))._nsObject)
}


internal func _CFSwiftStringCreateCopy(_ str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).copy(with: nil))
}

internal func _CFSwiftStringCreateMutableCopy(_ str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).mutableCopy(with: nil))
}

internal func _CFSwiftStringFastCStringContents(_ str: AnyObject) -> UnsafePointer<Int8>? {
    return (str as! NSString)._fastCStringContents
}

internal func _CFSwiftStringFastContents(_ str: AnyObject) -> UnsafePointer<UniChar>? {
    return (str as! NSString)._fastContents
}

internal func _CFSwiftStringGetCString(_ str: AnyObject, buffer: UnsafeMutablePointer<Int8>, maxLength: Int, encoding: CFStringEncoding) -> Bool {
    return (str as! NSString).getCString(buffer, maxLength: maxLength, encoding: CFStringConvertEncodingToNSStringEncoding(encoding))
}

internal func _CFSwiftStringIsUnicode(_ str: AnyObject) -> Bool {
    return (str as! NSString)._encodingCantBeStoredInEightBitCFString
}

internal func _CFSwiftStringInsert(_ str: AnyObject, index: CFIndex, inserted: AnyObject) {
    (str as! NSMutableString).insert((inserted as! NSString)._swiftObject, at: index)
}

internal func _CFSwiftStringDelete(_ str: AnyObject, range: CFRange) {
    (str as! NSMutableString).deleteCharacters(in: NSMakeRange(range.location, range.length))
}

internal func _CFSwiftStringReplace(_ str: AnyObject, range: CFRange, replacement: AnyObject) {
    (str as! NSMutableString).replaceCharacters(in: NSMakeRange(range.location, range.length), with: (replacement as! NSString)._swiftObject)
}

internal func _CFSwiftStringReplaceAll(_ str: AnyObject, replacement: AnyObject) {
    (str as! NSMutableString).setString((replacement as! NSString)._swiftObject)
}

internal func _CFSwiftStringAppend(_ str: AnyObject, appended: AnyObject) {
    (str as! NSMutableString).append((appended as! NSString)._swiftObject)
}

internal func _CFSwiftStringAppendCharacters(_ str: AnyObject, chars: UnsafePointer<UniChar>, length: CFIndex) {
    (str as! NSMutableString).appendCharacters(chars, length: length)
}

internal func _CFSwiftStringAppendCString(_ str: AnyObject, chars: UnsafePointer<Int8>, length: CFIndex) {
    (str as! NSMutableString)._cfAppendCString(chars, length: length)
}

