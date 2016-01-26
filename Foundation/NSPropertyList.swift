// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public struct NSPropertyListMutabilityOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    static let Immutable = NSPropertyListMutabilityOptions(rawValue: 0)
    static let MutableContainers = NSPropertyListMutabilityOptions(rawValue: 1)
    static let MutableContainersAndLeaves = NSPropertyListMutabilityOptions(rawValue: 2)
}

public enum NSPropertyListFormat : UInt {
    
    case OpenStepFormat = 1
    case XMLFormat_v1_0 = 100
    case BinaryFormat_v1_0 = 200
}

#if os(OSX) || os(iOS)
let kCFPropertyListOpenStepFormat = CFPropertyListFormat.OpenStepFormat
let kCFPropertyListXMLFormat_v1_0 = CFPropertyListFormat.XMLFormat_v1_0
let kCFPropertyListBinaryFormat_v1_0 = CFPropertyListFormat.BinaryFormat_v1_0
#endif

public typealias NSPropertyListReadOptions = NSPropertyListMutabilityOptions
public typealias NSPropertyListWriteOptions = Int

public class NSPropertyListSerialization : NSObject {

    public class func propertyList(plist: AnyObject, isValidForFormat format: NSPropertyListFormat) -> Bool {
#if os(OSX) || os(iOS)
        let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
#else
        let fmt = CFPropertyListFormat(format.rawValue)
#endif
        return CFPropertyListIsValid(unsafeBitCast(plist, CFPropertyList.self), fmt)
    }
    
    public class func dataWithPropertyList(plist: AnyObject, format: NSPropertyListFormat, options opt: NSPropertyListWriteOptions) throws -> NSData {
        var error: Unmanaged<CFError>? = nil
        let result = withUnsafeMutablePointer(&error) { (outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> CFData? in
#if os(OSX) || os(iOS)
            let fmt = CFPropertyListFormat(rawValue: CFIndex(format.rawValue))!
#else
            let fmt = CFPropertyListFormat(format.rawValue)
#endif
            let options = CFOptionFlags(opt)
            return CFPropertyListCreateData(kCFAllocatorSystemDefault, plist, fmt, options, outErr)
        }
        if let res = result {
            return res._nsObject
        } else {
            throw error!.takeRetainedValue()._nsObject
        }
    }
    
    /// - Experiment: Note that the return type of this function is different than on Darwin Foundation (Any instead of AnyObject). This is likely to change once we have a more complete story for bridging in place.
    public class func propertyListWithData(data: NSData, options opt: NSPropertyListReadOptions, format: UnsafeMutablePointer<NSPropertyListFormat>) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointers(&fmt, &error) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>, outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> NSObject? in
            return unsafeBitCast(CFPropertyListCreateWithData(kCFAllocatorSystemDefault, unsafeBitCast(data, CFDataRef.self), CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr), NSObject.self)
        }
        if format != nil {
#if os(OSX) || os(iOS)
            format.memory = NSPropertyListFormat(rawValue: UInt(fmt.rawValue))!
#else
            format.memory = NSPropertyListFormat(rawValue: UInt(fmt))!
#endif
        }

        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return _expensivePropertyListConversion(decoded!)
        }
    }
    
    internal class func propertyListWithStream(stream: CFReadStream, length streamLength: Int, options opt: NSPropertyListReadOptions, format: UnsafeMutablePointer <NSPropertyListFormat>) throws -> Any {
        var fmt = kCFPropertyListBinaryFormat_v1_0
        var error: Unmanaged<CFError>? = nil
        let decoded = withUnsafeMutablePointers(&fmt, &error) { (outFmt: UnsafeMutablePointer<CFPropertyListFormat>, outErr: UnsafeMutablePointer<Unmanaged<CFError>?>) -> NSObject? in
            return unsafeBitCast(CFPropertyListCreateWithStream(kCFAllocatorSystemDefault, stream, streamLength, CFOptionFlags(CFIndex(opt.rawValue)), outFmt, outErr), NSObject.self)
        }
        if format != nil {
#if os(OSX) || os(iOS)
            format.memory = NSPropertyListFormat(rawValue: UInt(fmt.rawValue))!
#else
            format.memory = NSPropertyListFormat(rawValue: UInt(fmt))!
#endif
        }
        if let err = error {
            throw err.takeUnretainedValue()._nsObject
        } else {
            return _expensivePropertyListConversion(decoded!)
        }
    }
}

// Until we have proper bridging support, we will have to recursively convert NS/CFTypes to Swift types when we return them to callers. Otherwise, they may expect to treat them as Swift types and it will fail. Obviously this will cause a problem if they treat them as NS types, but we'll live with that for now.
internal func _expensivePropertyListConversion(input : AnyObject) -> Any {
    if let dict = input as? NSDictionary {
        var result : [String : Any] = [:]
        dict.enumerateKeysAndObjectsUsingBlock { key, value, _ in
            guard let k = key as? NSString else {
                fatalError("Non-string key in a property list")
            }
            
            result[k._swiftObject] = _expensivePropertyListConversion(value)
        }

        return result
    } else if let array = input as? NSArray {
        var result : [Any] = []
        array.enumerateObjectsUsingBlock { value, _, _ in
            result.append(_expensivePropertyListConversion(value))
        }

        return result
    } else if let str = input as? NSString {
        return str._swiftObject
    } else if let date = input as? NSDate {
        return date
    } else if let data = input as? NSData {
        return data
    } else if let number = input as? NSNumber {
        return number
    } else if input === kCFBooleanTrue {
        return true
    } else if input === kCFBooleanFalse {
        return false
    } else if input is __NSCFType && CFGetTypeID(input) == _CFKeyedArchiverUIDGetTypeID() {
        return input
    } else {
        fatalError("Attempt to convert a non-plist type \(input)")
    }
}

