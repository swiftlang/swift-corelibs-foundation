// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation


//MARK: OUTPUT STREAM 
//OutputStream name taken as a protocol
public struct OutStream: ReferenceConvertible, CustomStringConvertible, Equatable, Hashable,_MutablePairBoxing{
    public typealias ReferenceType = NSOutputStream
    public typealias Status = NSStream.Status
 
    
//MARK: - Stored Properties
    internal var _wrapped : _SwiftOutputStream
    
//MARK: - Computed Properties
    public var description: String {
        return _mapUnmanaged{ $0.description }
    }
    
    public var debugDescription: String {
        return _mapUnmanaged{ $0.debugDescription }
    }
    
    public var hashValue: Int {
        return _mapUnmanaged{ $0.hashValue }
    }
    
    public var streamError:NSError? {
        return _wrapped._mapUnmanaged{ $0.streamError }
    }
    
    public var hasSpaceAvailable: Bool {
        return _wrapped._mapUnmanaged{ $0.hasSpaceAvailable }
    }
    
    public var streamStatus: Status {
        return _wrapped._mapUnmanaged{ $0.streamStatus }
    }
    
//MARK: - Initialization
    public init(toMemory: ()) {
        _wrapped = _SwiftOutputStream(immutableObject: NSOutputStream(toMemory: toMemory))
    }
    
    public init?(url: URL, append shouldAppend: Bool) {
        guard let nsis = NSOutputStream(url:url, append:shouldAppend) else { return nil }
        _wrapped = _SwiftOutputStream(immutableObject: nsis)
    }
    
    internal init(_bridged outputStream:NSOutputStream){
        _wrapped = _SwiftOutputStream(immutableObject: outputStream.copy())
    }
    
    public init?(toFileAtPath path: String, append shouldAppend: Bool) {
        self.init(url: URL(fileURLWithPath: path), append: shouldAppend)
    }
    
    public init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
         let nsis = NSOutputStream(toBuffer: buffer, capacity: capacity)
        _wrapped = _SwiftOutputStream(immutableObject: nsis)
    }

//MARK: - Functions
    /**
     open: A stream must be created before it can be opened. Once opened, a stream cannot be closed and reopened.
     ```swift
     let didOpen = outStream.open()
     ```
    */
    public func open() {
        _wrapped._mapUnmanaged{ $0.open() }
    }
    
    public func close() {
        _wrapped._mapUnmanaged{ $0.close() }
    }
   
    /**
     propertyForKey: get Stream's configuration for a key
     ```swift
        let val = outStream.propertyForKey(akey)
     ```
     - Parameter key: The key for one of the receiver's properties.
     
     - SeeAlso: Constants for a description of the available property-key constants and associated values.
     

     - Returns: The receiver’s property for the key key.
     */
    public func propertyForKey(_ key: String) -> AnyObject? {
        return _wrapped._mapUnmanaged{ $0.propertyForKey(key) }
    }
    
    /**
     setProperty: Attempts to set the value of a given property of the receiver and returns a Boolean value that indicates whether the value is accepted by the receiver.
     ```swift
        outStream.setProperty(value, forKey:aValidKey)
     ```
     - Parameter property: The value for key.
     - Parameter key: The key for one of the receiver's properties.
     
    
     - SeeAlso: Constants for a description of the available property-key constants and associated values.
     
     
     - Returns: The receiver’s property for the key key.
     */
    public mutating func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        return _applyUnmanagedMutation{
            return $0.setProperty(property, forKey: key)
        }
    }
    
    /**
     write: Writes the contents of a provided data buffer to the receiver.
     ```swift
     outStream.write(encodedData, maxLength: encodedData.count)
     ```
     - Parameter buffer: The data to write.
     - Parameter length: The length of the data buffer, in bytes.
     

     - Note: The behavior of this method is undefined if you pass a negative or zero number as length.
     
     Returns
        - A positive number indicates the number of bytes written.
        - 0 indicates that a fixed-length stream and has reached its capacity.
        - -1 means that the operation failed; more information about the error can be obtained with streamError.
     */
    public func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return _mapUnmanaged{
            return $0.write(buffer, maxLength: len)
        }
    }
    /**
     outputStreamToMemory: Creates and returns an initialized output stream that will write stream data to memory.
     The stream must be opened before it can be used.
     
     You retrieve the contents of the memory stream by sending the message propertyForKey: to the receiver with an argument of NSStreamDataWrittenToMemoryStreamKey.
     ```swift
        OutStream.outputStreamToMemory()
     ```
     
     - Returns: An initialized output stream that will write stream data to memory.
     */
    public static func outputStreamToMemory() -> OutStream {
        return OutStream(toMemory: ())
    }
    
}

public func === (lhs: OutStream, rhs: OutStream) -> Bool {
    return lhs._mapUnmanaged{ unsafeAddress(of: $0) } == rhs._mapUnmanaged{ unsafeAddress(of: $0) }
}

public func ==(lhs : OutStream, rhs : OutStream) -> Bool {
    return lhs._wrapped.isEqual(rhs._bridgeToObjectiveC())
}

extension OutStream {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSOutputStream.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSOutputStream {
        return unsafeBitCast(_wrapped, to: NSOutputStream.self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSOutputStream, result: inout OutStream?) {
        result = OutStream(_bridged: input)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSOutputStream, result: inout OutStream?) -> Bool {
        result = OutStream(_bridged: input)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSOutputStream?) -> OutStream {
        return OutStream(_bridged: source!)
    }
    
}




