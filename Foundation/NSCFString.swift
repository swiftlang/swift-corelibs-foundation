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
        // FIXME: Split expression as a work-around for slow type
        //        checking (tracked by SR-5322).
        let offTemp1 = MemoryLayout<OpaquePointer>.size + MemoryLayout<uintptr_t>.size
        let offset = offTemp1 + MemoryLayout<_CFInfo>.size
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        return ptr.load(fromByteOffset: offset, as: UnsafePointer<UInt8>.self)
    }

    private var _lenOffset : Int {
        // FIXME: Split expression as a work-around for slow type
        //        checking (tracked by SR-5322).
        let offTemp1 = MemoryLayout<OpaquePointer>.size + MemoryLayout<uintptr_t>.size
        let offset = offTemp1 + MemoryLayout<_CFInfo>.size
        return offset + MemoryLayout<UnsafePointer<UInt8>>.size
    }

    private var _lenPtr :  UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(self).toOpaque()
    }

#if arch(s390x)
    internal var _length : UInt64 {
        return _lenPtr.load(fromByteOffset: _lenOffset, as: UInt64.self)
    }
#else
    internal var _length : UInt32 {
        return _lenPtr.load(fromByteOffset: _lenOffset, as: UInt32.self)
    }
#endif
    
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
    (str as! NSString).getCharacters(buffer, range: NSRange(location: range.location, length: range.length))
}

internal func _CFSwiftStringGetBytes(_ str: AnyObject, encoding: CFStringEncoding, range: CFRange, buffer: UnsafeMutablePointer<UInt8>?, maxBufLen: CFIndex, usedBufLen: UnsafeMutablePointer<CFIndex>?) -> CFIndex {
    let convertedLength: CFIndex
    switch encoding {
        // TODO: Don't treat many encodings like they are UTF8
    case CFStringEncoding(kCFStringEncodingUTF8), CFStringEncoding(kCFStringEncodingISOLatin1), CFStringEncoding(kCFStringEncodingMacRoman), CFStringEncoding(kCFStringEncodingASCII), CFStringEncoding(kCFStringEncodingNonLossyASCII):
        let encodingView = (str as! NSString).substring(with: NSRange(range)).utf8
        if let buffer = buffer {
            for (idx, character) in encodingView.enumerated() {
                buffer.advanced(by: idx).initialize(to: character)
            }
        }
        usedBufLen?.pointee = encodingView.count
        convertedLength = encodingView.count
        
    case CFStringEncoding(kCFStringEncodingUTF16):
        let encodingView = (str as! NSString)._swiftObject.utf16
        let start = encodingView.startIndex
        if let buffer = buffer {
            for idx in 0..<range.length {
                // Since character is 2 bytes but the buffer is in term of 1 byte values, we have to split it up
                let character = encodingView[encodingView.index(start, offsetBy: idx + range.location)]
#if _endian(big)
                let byte0 = UInt8((character >> 8) & 0x00ff)
                let byte1 = UInt8(character & 0x00ff)
#else
                let byte0 = UInt8(character & 0x00ff)
                let byte1 = UInt8((character >> 8) & 0x00ff)
#endif
                buffer.advanced(by: idx * 2).initialize(to: byte0)
                buffer.advanced(by: (idx * 2) + 1).initialize(to: byte1)
            }
        }
        // Every character was 2 bytes
        usedBufLen?.pointee = range.length * 2
        convertedLength = range.length

    default:
        fatalError("Attempted to get bytes of a Swift string using an unsupported encoding")
    }
    
    return convertedLength
}

internal func _CFSwiftStringCreateWithSubstring(_ str: AnyObject, range: CFRange) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).substring(with: NSRange(location: range.location, length: range.length))._nsObject)
}


internal func _CFSwiftStringCreateCopy(_ str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).copy() as! NSObject)
}

internal func _CFSwiftStringCreateMutableCopy(_ str: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((str as! NSString).mutableCopy() as! NSObject)
}

internal func _CFSwiftStringFastCStringContents(_ str: AnyObject, _ nullTerminated: Bool) -> UnsafePointer<Int8>? {
    return (str as! NSString)._fastCStringContents(nullTerminated)
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
    (str as! NSMutableString).deleteCharacters(in: NSRange(location: range.location, length: range.length))
}

internal func _CFSwiftStringReplace(_ str: AnyObject, range: CFRange, replacement: AnyObject) {
    (str as! NSMutableString).replaceCharacters(in: NSRange(location: range.location, length: range.length), with: (replacement as! NSString)._swiftObject)
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

