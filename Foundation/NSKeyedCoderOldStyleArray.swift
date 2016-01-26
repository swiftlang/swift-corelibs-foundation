// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal final class _NSKeyedCoderOldStyleArray : NSObject, NSCopying, NSSecureCoding, NSCoding {

    private var _addr : UnsafeMutablePointer<UInt8> = nil // free if decoding
    private var _count : Int
    private var _size : Int
    private var _type : _NSSimpleObjCType
    private var _decoded : Bool = false
    
    static func sizeForObjCType(type: _NSSimpleObjCType) -> Int? {
        var size : Int = 0
        var align : Int = 0
        
        return _NSGetSizeAndAlignment(type, &size, &align) ? size : nil
    }

    init?(objCType type: _NSSimpleObjCType, count: Int, at addr: UnsafePointer<Void>) {
        self._addr = UnsafeMutablePointer<UInt8>(addr)
        self._count = count
        
        guard let size = _NSKeyedCoderOldStyleArray.sizeForObjCType(type) else {
            return nil
        }
        
        self._size = size
        self._type = type
        self._decoded = false
    }

    deinit {
        if self._decoded {
            self._addr.destroy(self._count * self._size)
            self._addr.dealloc(self._count * self._size)
        }
    }
    
    init?(coder aDecoder: NSCoder) {
        assert(aDecoder.allowsKeyedCoding)
        
        guard let type = _NSSimpleObjCType(UInt8(aDecoder.decodeIntegerForKey("NS.type"))) else {
            return nil
        }
        
        self._count = aDecoder.decodeIntegerForKey("NS.count")
        self._size = aDecoder.decodeIntegerForKey("NS.size")
        self._type = type
        self._decoded = true

        if self._size != _NSKeyedCoderOldStyleArray.sizeForObjCType(type) {
            return nil
        }
        
        self._addr = UnsafeMutablePointer<UInt8>.alloc(self._count * self._size)
        
        super.init()
        
        for idx in 0..<self._count {
            var type = Int8(self._type)
            
            withUnsafePointer(&type) { typep in
                let addr = self._addr.advancedBy(idx * self._size)
                aDecoder.decodeValueOfObjCType(typep, at: addr)
            }
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self._count, forKey: "NS.count")
        aCoder.encodeInteger(self._size, forKey: "NS.size")
        aCoder.encodeInteger(Int(self._type), forKey: "NS.type")
        
        for idx in 0..<self._count {
            var type = Int8(self._type)

            withUnsafePointer(&type) { typep in
                aCoder.encodeValueOfObjCType(typep, at: &self._addr[idx * self._size])
            }
        }
    }
    
    static func supportsSecureCoding() -> Bool {
        return true
    }
    
    func fillObjCType(type: _NSSimpleObjCType, count: Int, at addr: UnsafeMutablePointer<Void>) {
        if type == self._type && count <= self._count {
            UnsafeMutablePointer<UInt8>(addr).moveInitializeFrom(self._addr, count: count * self._size)
        }
    }
    
    override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
}
