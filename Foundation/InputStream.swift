// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public struct InputStream: ReferenceConvertible, CustomStringConvertible, Equatable, Hashable, _MutablePairBoxing{
    public typealias ReferenceType = NSInputStream
    public typealias Status = NSStream.Status

//MARK: - Stored Properties
    internal var _wrapped : _SwiftInputStream

    
//MARK: - Computed Properties
    public weak var delegate: StreamDelegate? {
        get{
            return _mapUnmanaged{ $0.delegate }
        }
        set{
            _applyUnmanagedMutation {
                $0.delegate = newValue
            }
        }
    }

    public var description: String {
        return _mapUnmanaged{ $0.description }
    }
    
    public var debugDescription: String {
        return _mapUnmanaged{ $0.debugDescription }
    }
    
    public var hashValue: Int {
        return _mapUnmanaged{ $0.hashValue }
    }
    
    /**
     Returns an NSError object representing the stream error.
     ```swift
     let error = inStream.streamError
     ```
     - Returns: An NSError object representing the stream error, or nil if no error has been encountered.
     */
    public var streamError:NSError? {
        return _wrapped._mapUnmanaged{ $0.streamError }
    }
    
    /**
     A Boolean value that indicates whether the receiver has bytes available to read. (read-only)
     ```swift
     let hasBytes = inStream.hasBytesAvailable
     ```
     - Returns: true if the receiver has bytes available to read, otherwise false. May also return true if a read must be attempted in order to determine the availability of bytes.
     */
    public var hasBytesAvailable:Bool {
        return _wrapped._mapUnmanaged{ $0.hasBytesAvailable }
    }
    
    /**
     Returns the receiver’s status.
     ```swift
     let status = inStream.streamStatus
     ```
     - Notes: See Constants for a description of the available NSStreamStatus constants.
     - Returns: The receiver’s status.
     */
    public var streamStatus: Status {
        return _wrapped._mapUnmanaged{ $0.streamStatus }
    }
    
//MARK: - Initialization
    
    /**
    Initializes and returns an NSInputStream object for reading from a given NSData object.
    The stream must be opened before it can be used.
     ```swift
     InputStream(data:someData)
     ```
     - Parameter data: The data object from which to read. The contents of data are copied.
     - Returns: An initialized NSInputStream object for reading from data.
     */
    public init(data: Data) {
        _wrapped = _SwiftInputStream(immutableObject: NSInputStream(data: data))
    }
    
    /**
     Initializes and returns an NSInputStream object that reads data from the file at a given URL.
     The stream must be opened before it can be used.
     ```swift
     InputStream(url:someURL)
     ```
     - Parameter url: The URL to the file.
     - Returns: An initialized NSInputStream object for reading from data.
     */
    public init?(url: URL) {
        guard let nsis = NSInputStream(url:url) else { return nil }
        _wrapped = _SwiftInputStream(immutableObject: nsis)
    }
    
    internal init(_bridged inputStream:NSInputStream){
        _wrapped = _SwiftInputStream(immutableObject: inputStream.copy())
    }
    
    /**
     Initializes and returns an NSInputStream object that reads data from the file at a given path
     The stream must be opened before it can be used.
     ```swift
     InputStream(fileAtPath:filePath)
     ```
     - Parameter filePath: The path to the file.
     - Returns: An initialized NSInputStream object that reads data from the file at path.
     */
    public init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
    
//MARK: - Functions
    /**
     A stream must be created before it can be opened. Once opened, a stream cannot be closed and reopened.
     ```swift
     let didOpen = inStream.open()
     ```
     */
    public func open() {
        _wrapped._mapUnmanaged{ $0.open() }
    }
    
    /**
     Closing the stream terminates the flow of bytes and releases system resources that were reserved for the stream when it was opened. If the stream has been scheduled on a run loop, closing the stream implicitly removes the stream from the run loop. A stream that is closed can still be queried for its properties.   
     ```swift
     let didOpen = inStream.close()
     ```
     */
    public func close() {
        _wrapped._mapUnmanaged{ $0.close() }
    }
    
    /**
     Reads up to a given number of bytes into a given buffer
     ```swift
     ```
     - Parameter buffer: A data buffer. The buffer must be large enough to contain the number of bytes specified by len.
     - Parameter len: The maximum number of bytes to read.

     Returns A number indicating the outcome of the operation:
     - A positive number indicates the number of bytes written.
     - 0 indicates that a fixed-length stream and has reached its capacity.
     - -1 means that the operation failed; more information about the error can be obtained with streamError.
     */
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return _wrapped._mapUnmanaged{ $0.read(buffer, maxLength: len) }
    }
    
    /**
     Returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.   
     ```swift
     inStream.getBuffer(buffer, length: len)
     ```
     - Parameter buffer: Upon return, contains a pointer to a read buffer. The buffer is only valid until the next stream operation is performed.
     - Parameter len: Upon return, contains the number of bytes available.
     - Note: The behavior of this method is undefined if you pass a negative or zero number as length.
     - Returns: true if the buffer is available, otherwise false.
     */
    public func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return _wrapped._mapUnmanaged{ $0.getBuffer(buffer, length: len) }
    }
    
    /**
     Returns the receiver’s property for a given key.
     
     ```swift
     inStream.propertyForKey(key)
     
     ```
     - Parameter key: The key for one of the receiver's properties.
     - Notes: See Constants for a description of the available property-key constants and associated values.
     - Returns: The receiver’s property for the key key.
     */
    public func propertyForKey(_ key: String) -> AnyObject? {
        return _wrapped._mapUnmanaged{ $0.propertyForKey(key) }
    }
    
    /**
     Attempts to set the value of a given property of the receiver and returns a Boolean value that indicates whether the value is accepted by the receiver.
     ```swift
     inStream.setProperty(property, forKey: key)
     
     ```
     - Parameter key: The value for key.
     - Parameter property: The key for one of the receiver's properties.
     - Notes: See Constants for a description of the available property-key constants and associated values.
     - Returns: The receiver’s property for the key key.
     */
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
