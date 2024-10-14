// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal import CoreFoundation

let kCFPropertyListOpenStepFormat = CFPropertyListFormat.openStepFormat
let kCFPropertyListXMLFormat_v1_0 = CFPropertyListFormat.xmlFormat_v1_0
let kCFPropertyListBinaryFormat_v1_0 = CFPropertyListFormat.binaryFormat_v1_0

extension PropertyListSerialization {

    public struct MutabilityOptions : OptionSet, Sendable {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let mutableContainers = MutabilityOptions(rawValue: 1)
        public static let mutableContainersAndLeaves = MutabilityOptions(rawValue: 2)
    }

    public typealias PropertyListFormat = PropertyListDecoder.PropertyListFormat

    public typealias ReadOptions = MutabilityOptions
    public typealias WriteOptions = Int
}

@available(*, unavailable)
extension PropertyListSerialization : @unchecked Sendable { }

open class PropertyListSerialization : NSObject {

    open class func propertyList(_ plist: Any, isValidFor format: PropertyListFormat) -> Bool {
        let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
        let plistObj = __SwiftValue.store(plist)
        return CFPropertyListIsValid(plistObj, fmt)
    }

    open class func data(fromPropertyList plist: Any, format: PropertyListFormat, options opt: WriteOptions) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        let result = withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> CFData? in
            let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
            let options = CFOptionFlags(opt)
            let plistObj = __SwiftValue.store(plist)
            let d = CFPropertyListCreateData(kCFAllocatorSystemDefault, plistObj, fmt, options, outErr)
            return d?.takeRetainedValue()
        }
        if let res = result {
            return res._swiftObject
        } else {
            throw error!.takeRetainedValue()._nsObject
        }
    }

    open class func propertyList(from data: Data, options opt: ReadOptions = [], format: UnsafeMutablePointer<PropertyListFormat>?) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointer(to: &fmt) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>) -> AnyObject? in
            withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> AnyObject? in
                let d = CFPropertyListCreateWithData(kCFAllocatorSystemDefault, data._cfObject, CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr)
		return d?.takeRetainedValue()
            }
        }
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt.rawValue))!
        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return __SwiftValue.fetch(nonOptional: decoded!)
        }
    }
    
#if !os(WASI)
    internal final class func propertyList(with stream: CFReadStream, options opt: ReadOptions, format: UnsafeMutablePointer <PropertyListFormat>?) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointer(to: &fmt) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>) -> AnyObject? in
            withUnsafeMutablePointer(to: &error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> AnyObject? in
                return CFPropertyListCreateWithStream(kCFAllocatorSystemDefault, stream, 0, CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr).takeRetainedValue()
            }
        }
        format?.pointee = PropertyListFormat(rawValue: UInt(fmt.rawValue))!
        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return __SwiftValue.fetch(nonOptional: decoded!)
        }
    }
    
    open class func propertyList(with stream: InputStream, options opt: ReadOptions = [], format: UnsafeMutablePointer<PropertyListFormat>?) throws -> Any {
        return try propertyList(with: stream._stream, options: opt, format: format)
    }
#endif
}
