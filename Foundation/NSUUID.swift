// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public class NSUUID : NSObject, NSCopying, NSSecureCoding, NSCoding {
    internal var buffer = UnsafeMutablePointer<UInt8>.alloc(16)
    
    public override init() {
        _cf_uuid_generate_random(buffer)
    }
    
    public convenience init?(UUIDString string: String) {
        let buffer = UnsafeMutablePointer<UInt8>.alloc(16)
        if _cf_uuid_parse(string, buffer) != 0 {
            return nil
        }
        self.init(UUIDBytes: buffer)
    }
    
    public init(UUIDBytes bytes: UnsafePointer<UInt8>) {
        if (bytes != nil) {
            memcpy(unsafeBitCast(buffer, UnsafeMutablePointer<Void>.self), UnsafePointer<Void>(bytes), 16)
        } else {
            memset(unsafeBitCast(buffer, UnsafeMutablePointer<Void>.self), 0, 16)
        }
    }
    
    public func getUUIDBytes(uuid: UnsafeMutablePointer<UInt8>) {
        _cf_uuid_copy(uuid, buffer)
    }
    
    public var UUIDString: String {
        get {
            let strPtr = UnsafeMutablePointer<Int8>.alloc(37)
            _cf_uuid_unparse_lower(buffer, strPtr)
            return String.fromCString(strPtr)!
        }
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if object === self {
            return true
        } else if let other = object as? NSUUID {
            return _cf_uuid_compare(buffer, other.buffer) == 0
        } else {
            return false
        }
    }
    
    public override var hash: Int {
        return Int(CFHashBytes(buffer, 16))
    }
    
    public override var description: String {
        return UUIDString
    }
}
