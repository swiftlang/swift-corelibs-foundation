// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

open class NSUUID : NSObject, NSCopying, NSSecureCoding, NSCoding, @unchecked Sendable {
    internal var uuid: UUID

    public override init() {
        uuid = UUID()
    }

    private init(_ uuid: UUID) {
        self.uuid = uuid
    }

    public convenience init?(uuidString string: String) {
        guard let uuid = UUID(uuidString: string) else {
            return nil
        }
        self.init(uuid)
    }
    
    public init(uuidBytes bytes: UnsafePointer<UInt8>) {
        self.uuid = UUID(copying: Span(_unsafeStart: bytes, count: 16).bytes)
    }
    
    open func getBytes(_ uuid: UnsafeMutablePointer<UInt8>) {
        Span<UInt8>(viewing: self.uuid.bytes).withUnsafeBufferPointer { buffer in
            uuid.initialize(from: buffer.baseAddress!, count: buffer.count)
        }
    }
    
    open var uuidString: String {
        uuid.uuidString
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let decoded : UUID? = coder.withDecodedUnsafeBufferPointer(forKey: "NS.uuidbytes") { buffer -> UUID? in
            guard let buffer else { return nil }
            return UUID(copying: buffer.span.bytes)
        }

        guard let decoded else { return nil }
        self.init(decoded)
    }
    
    open func encode(with aCoder: NSCoder) {
        Span<UInt8>(viewing: uuid.bytes).withUnsafeBufferPointer { buffer in
            aCoder.encodeBytes(buffer.baseAddress, length: buffer.count, forKey: "NS.uuidbytes")
        }
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as FoundationEssentials.UUID:
            return self.uuid == other
        case let other as NSUUID:
            return other === self || self.uuid == other.uuid
        default:
            return false
        }
    }
    
    open override var hash: Int {
        self.uuid.hashValue
    }
    
    open override var description: String {
        return uuidString
    }
}

extension NSUUID : _StructTypeBridgeable {
    public typealias _StructType = UUID
    
    public func _bridgeToSwift() -> UUID {
        return self.uuid
    }
}
