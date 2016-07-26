// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation


public struct InputStream: ReferenceConvertible, CustomStringConvertible, Equatable, Hashable,_MutablePairBoxing{
    public typealias ReferenceType = NSInputStream
    public typealias Status = NSStream.Status
    
//MARK: - Stored Properties
    internal var _wrapped : _SwiftInputStream

//MARK: - Computed Properties
    public var description: String { return _mapUnmanaged{ $0.description } }
    
    public var debugDescription: String { return _mapUnmanaged{ $0.debugDescription } }
    
    public var hashValue: Int { return _mapUnmanaged{ $0.hashValue } }
    
    public var streamError:NSError? { return _wrapped._mapUnmanaged{ $0.streamError } }
    
    public var hasBytesAvailable:Bool {
        return _wrapped._mapUnmanaged{ $0.hasBytesAvailable }
    }
    
    public var streamStatus: Status {
        return _wrapped._mapUnmanaged{ $0.streamStatus }
    }
    
//MARK: - Initialization
    public init(data: Data) {
        _wrapped = _SwiftInputStream(immutableObject: NSInputStream(data: data))
    }
    
    public init?(url: URL) {
        guard let nsis = NSInputStream(url:url) else { return nil }
        _wrapped = _SwiftInputStream(immutableObject: nsis)
    }
    
    internal init(_bridged inputStream:NSInputStream){
        _wrapped = _SwiftInputStream(immutableObject: inputStream.copy())
    }
    
    public init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
    
//MARK: - Functions
    public func open() {
        _wrapped._mapUnmanaged{ $0.open() }
    }
    
    public func close() {
        _wrapped._mapUnmanaged{ $0.close() }
    }
    
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return _wrapped._mapUnmanaged{ $0.read(buffer, maxLength: len) }
    }
    
    public func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return _wrapped._mapUnmanaged{ $0.getBuffer(buffer, length: len) }
    }
    
    public func propertyForKey(_ key: String) -> AnyObject? {
        return _wrapped._mapUnmanaged{ $0.propertyForKey(key) }
    }
    
    public mutating func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        return _applyUnmanagedMutation{
            return $0.setProperty(property, forKey: key)
        }
    }
    
}

public func === (lhs: InputStream, rhs: InputStream) -> Bool {
    return lhs._mapUnmanaged{ unsafeAddress(of: $0) } == rhs._mapUnmanaged{ unsafeAddress(of: $0) }
}

public func ==(lhs : InputStream, rhs : InputStream) -> Bool {
    return lhs._wrapped.isEqual(rhs._bridgeToObjectiveC())
}

extension InputStream {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSInputStream.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSInputStream {
        return unsafeBitCast(_wrapped, to: NSInputStream.self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSInputStream, result: inout InputStream?) {
        result = InputStream(_bridged: input)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSInputStream, result: inout InputStream?) -> Bool {
        result = InputStream(_bridged: input)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSInputStream?) -> InputStream {
        return InputStream(_bridged: source!)
    }
    
}
