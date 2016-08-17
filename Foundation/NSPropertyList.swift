// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
let kCFPropertyListOpenStepFormat = CFPropertyListFormat.openStepFormat
let kCFPropertyListXMLFormat_v1_0 = CFPropertyListFormat.xmlFormat_v1_0
let kCFPropertyListBinaryFormat_v1_0 = CFPropertyListFormat.binaryFormat_v1_0
#endif

extension PropertyListSerialization {

    public struct MutabilityOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        static let immutable = MutabilityOptions(rawValue: 0)
        static let mutableContainers = MutabilityOptions(rawValue: 1)
        static let mutableContainersAndLeaves = MutabilityOptions(rawValue: 2)
    }

    public enum PropertyListFormat : UInt {
        
        case openStep = 1
        case xml = 100
        case binary = 200
    }

    public typealias ReadOptions = MutabilityOptions
    public typealias WriteOptions = Int
}

open class PropertyListSerialization : NSObject {

    open class func propertyList(_ plist: Any, isValidFor format: PropertyListFormat) -> Bool {
#if os(OSX) || os(iOS)
        let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
#else
        let fmt = CFPropertyListFormat(format.rawValue)
#endif
        return CFPropertyListIsValid(unsafeBitCast(_SwiftValue.store(plist), to: CFPropertyList.self), fmt)
    }
    
    open class func data(fromPropertyList plist: AnyObject, format: PropertyListFormat, options opt: WriteOptions) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        let result = withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> CFData? in
#if os(OSX) || os(iOS)
            let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
#else
            let fmt = CFPropertyListFormat(format.rawValue)
#endif
            let options = CFOptionFlags(opt)
            return CFPropertyListCreateData(kCFAllocatorSystemDefault, plist, fmt, options, outErr)
        }
        if let res = result {
            return res._swiftObject
        } else {
            throw error!.takeRetainedValue()._nsObject
        }
    }
    
    /// - Experiment: Note that the return type of this function is different than on Darwin Foundation (Any instead of AnyObject). This is likely to change once we have a more complete story for bridging in place.
    open class func propertyList(from data: Data, options opt: ReadOptions = [], format: UnsafeMutablePointer<PropertyListFormat>?) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointer(to: &fmt) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>) -> NSObject? in
            withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> NSObject? in
                return unsafeBitCast(CFPropertyListCreateWithData(kCFAllocatorSystemDefault, data._cfObject, CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr), to: NSObject.self)
            }
        }
#if os(OSX) || os(iOS)
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt.rawValue))!
#else
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt))!
#endif
        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return _SwiftValue.fetch(decoded!)
        }
    }
    
    internal class func propertyListWithStream(_ stream: CFReadStream, length streamLength: Int, options opt: ReadOptions, format: UnsafeMutablePointer <PropertyListFormat>?) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointer(to: &fmt) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>) -> NSObject? in
            withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> NSObject? in
                return unsafeBitCast(CFPropertyListCreateWithStream(kCFAllocatorSystemDefault, stream, streamLength, CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr), to: NSObject.self)
            }
        }
#if os(OSX) || os(iOS)
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt.rawValue))!
#else
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt))!
#endif
        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return _SwiftValue.fetch(decoded!)
        }
    }
    
    open class func propertyList(with stream: InputStream, options opt: ReadOptions = [], format: UnsafeMutablePointer<PropertyListFormat>?) throws -> Any {
        NSUnimplemented()
    }
}
