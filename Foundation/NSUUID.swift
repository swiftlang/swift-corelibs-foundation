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
        memcpy(unsafeBitCast(buffer, UnsafeMutablePointer<Void>.self), UnsafePointer<Void>(bytes), 16)
    }
    
    public func getUUIDBytes(uuid: UnsafeMutablePointer<UInt8>) {
        _cf_uuid_copy(uuid, buffer)
    }
    
    public var UUIDString: String {
        get {
            let strPtr = UnsafeMutablePointer<Int8>.alloc(37)
            _cf_uuid_unparse_upper(buffer, strPtr)
            return String(strPtr)
        }
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder: NSCoder) {
        
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
    }
}
