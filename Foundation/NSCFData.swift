// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal final class NSCFData : NSMutableData {
    override var length: Int {
        get {
            return CFDataGetLength(unsafeBitCast(self, to: CFData.self))
        }
        set {
            CFDataSetLength(unsafeBitCast(self, to: CFMutableData.self), newValue)
        }
    }
    
    override var bytes: UnsafeRawPointer {
        if let bytes = CFDataGetBytePtr(unsafeBitCast(self, to: CFData.self)) {
            return UnsafeRawPointer(bytes)
        } else {
            return __NSDataNullBytes
        }
    }
    
    override var mutableBytes: UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(CFDataGetMutableBytePtr(unsafeBitCast(self, to: CFMutableData.self)))
    }
    
    override func _isCompact() -> Bool {
        return true
    }
    
    override func _providesConcreteBacking() -> Bool {
        return true
    }
}

internal func _CFSwiftDataLength(_ data: CFTypeRef) -> CFIndex {
    return unsafeBitCast(data, to: NSData.self).length
}

internal func _CFSwiftDataBytes(_ data: CFTypeRef) -> UnsafeRawPointer? {
    return unsafeBitCast(data, to: NSData.self).bytes
}

internal func _CFSwiftDataGetBytes(_ data: CFTypeRef, _ buffer: UnsafeMutableRawPointer, _ range: CFRange) {
    unsafeBitCast(data, to: NSData.self).getBytes(buffer, range: NSRange(location: range.location, length: range.length))
}

internal func _CFSwiftMutableDataMutableBytes(_ data: CFTypeRef) -> UnsafeMutablePointer<UInt8>? {
    let d = unsafeBitCast(data, to: NSMutableData.self)
    if d.length == 0 { return nil }
    return d.mutableBytes.assumingMemoryBound(to: UInt8.self)
}

internal func _CFSwiftMutableDataSetLength(_ data: CFTypeRef, _ length: CFIndex) {
    unsafeBitCast(data, to: NSMutableData.self).length = length
}

internal func _CFSwiftMutableDataIncreaseLengthBy(_ data: CFTypeRef, _ amt: CFIndex) {
    unsafeBitCast(data, to: NSMutableData.self).increaseLength(by: amt)
}

internal func _CFSwiftMutableDataAppendBytes(_ data: CFTypeRef, _ bytes: UnsafePointer<UInt8>, _ length: CFIndex) {
    unsafeBitCast(data, to: NSMutableData.self).append(bytes, length: length)
}

internal func _CFSwiftMutableDataReplaceBytesInRange(_ data: CFTypeRef, _ range: CFRange, _ bytes: UnsafeMutableRawPointer?, _ length: CFIndex) {
    unsafeBitCast(data, to: NSMutableData.self).replaceBytes(in: NSRange(location: range.location, length: range.length), withBytes: bytes, length: length)
}
