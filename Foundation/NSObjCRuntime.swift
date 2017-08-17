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
internal let kCFCompareLessThan = CFComparisonResult.compareLessThan
internal let kCFCompareEqualTo = CFComparisonResult.compareEqualTo
internal let kCFCompareGreaterThan = CFComparisonResult.compareGreaterThan
#endif

internal enum _NSSimpleObjCType : UnicodeScalar {
    case ID = "@"
    case Class = "#"
    case Sel = ":"
    case Char = "c"
    case UChar = "C"
    case Short = "s"
    case UShort = "S"
    case Int = "i"
    case UInt = "I"
    case Long = "l"
    case ULong = "L"
    case LongLong = "q"
    case ULongLong = "Q"
    case Float = "f"
    case Double = "d"
    case Bitfield = "b"
    case Bool = "B"
    case Void = "v"
    case Undef = "?"
    case Ptr = "^"
    case CharPtr = "*"
    case Atom = "%"
    case ArrayBegin = "["
    case ArrayEnd = "]"
    case UnionBegin = "("
    case UnionEnd = ")"
    case StructBegin = "{"
    case StructEnd = "}"
    case Vector = "!"
    case Const = "r"
}

extension Int {
    init(_ v: _NSSimpleObjCType) {
        self.init(UInt8(ascii: v.rawValue))
    }
}

extension Int8 {
    init(_ v: _NSSimpleObjCType) {
        self.init(Int(v))
    }
}

extension String {
    init(_ v: _NSSimpleObjCType) {
        self.init(v.rawValue)
    }
}

extension _NSSimpleObjCType {
    init?(_ v: UInt8) {
        self.init(rawValue: UnicodeScalar(v))
    }
    
    init?(_ v: String?) {
        if let rawValue = v?.unicodeScalars.first {
            self.init(rawValue: rawValue)
        } else {
            return nil
        }
    }
}

// mapping of ObjC types to sizes and alignments (note that .Int is 32-bit)
// FIXME use a generic function, unfortuantely this seems to promote the size to 8
private let _NSObjCSizesAndAlignments : Dictionary<_NSSimpleObjCType, (Int, Int)> = [
    .ID         : ( MemoryLayout<AnyObject>.size,              MemoryLayout<AnyObject>.alignment          ),
    .Class      : ( MemoryLayout<AnyClass>.size,               MemoryLayout<AnyClass>.alignment           ),
    .Char       : ( MemoryLayout<CChar>.size,                  MemoryLayout<CChar>.alignment              ),
    .UChar      : ( MemoryLayout<UInt8>.size,                  MemoryLayout<UInt8>.alignment              ),
    .Short      : ( MemoryLayout<Int16>.size,                  MemoryLayout<Int16>.alignment              ),
    .UShort     : ( MemoryLayout<UInt16>.size,                 MemoryLayout<UInt16>.alignment             ),
    .Int        : ( MemoryLayout<Int32>.size,                  MemoryLayout<Int32>.alignment              ),
    .UInt       : ( MemoryLayout<UInt32>.size,                 MemoryLayout<UInt32>.alignment             ),
    .Long       : ( MemoryLayout<Int32>.size,                  MemoryLayout<Int32>.alignment              ),
    .ULong      : ( MemoryLayout<UInt32>.size,                 MemoryLayout<UInt32>.alignment             ),
    .LongLong   : ( MemoryLayout<Int64>.size,                  MemoryLayout<Int64>.alignment              ),
    .ULongLong  : ( MemoryLayout<UInt64>.size,                 MemoryLayout<UInt64>.alignment             ),
    .Float      : ( MemoryLayout<Float>.size,                  MemoryLayout<Float>.alignment              ),
    .Double     : ( MemoryLayout<Double>.size,                 MemoryLayout<Double>.alignment             ),
    .Bool       : ( MemoryLayout<Bool>.size,                   MemoryLayout<Bool>.alignment               ),
    .CharPtr    : ( MemoryLayout<UnsafePointer<CChar>>.size,   MemoryLayout<UnsafePointer<CChar>>.alignment)
]

internal func _NSGetSizeAndAlignment(_ type: _NSSimpleObjCType,
                                     _ size : inout Int,
                                     _ align : inout Int) -> Bool {
    guard let sizeAndAlignment = _NSObjCSizesAndAlignments[type] else {
        return false
    }
    
    size = sizeAndAlignment.0
    align = sizeAndAlignment.1
    
    return true
}

public func NSGetSizeAndAlignment(_ typePtr: UnsafePointer<Int8>,
                                  _ sizep: UnsafeMutablePointer<Int>?,
                                  _ alignp: UnsafeMutablePointer<Int>?) -> UnsafePointer<Int8> {
    let type = _NSSimpleObjCType(UInt8(typePtr.pointee))!

    var size : Int = 0
    var align : Int = 0
    
    if !_NSGetSizeAndAlignment(type, &size, &align) {
        // FIXME: This used to return nil, but the corresponding Darwin
        // implementation is defined as returning a non-optional value.
        fatalError("invalid type encoding")
    }
    
    sizep?.pointee = size
    alignp?.pointee = align

    return typePtr.advanced(by: 1)
}

public enum ComparisonResult : Int {
    
    case orderedAscending = -1
    case orderedSame
    case orderedDescending
    
    internal static func _fromCF(_ val: CFComparisonResult) -> ComparisonResult {
        if val == kCFCompareLessThan {
            return .orderedAscending
        } else if  val == kCFCompareGreaterThan {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
}

/* Note: QualityOfService enum is available on all platforms, but it may not be implemented on all platforms. */
public enum QualityOfService : Int {
    
    /* UserInteractive QoS is used for work directly involved in providing an interactive UI such as processing events or drawing to the screen. */
    case userInteractive
    
    /* UserInitiated QoS is used for performing work that has been explicitly requested by the user and for which results must be immediately presented in order to allow for further user interaction.  For example, loading an email after a user has selected it in a message list. */
    case userInitiated
    
    /* Utility QoS is used for performing work which the user is unlikely to be immediately waiting for the results.  This work may have been requested by the user or initiated automatically, does not prevent the user from further interaction, often operates at user-visible timescales and may have its progress indicated to the user by a non-modal progress indicator.  This work will run in an energy-efficient manner, in deference to higher QoS work when resources are constrained.  For example, periodic content updates or bulk file operations such as media import. */
    case utility
    
    /* Background QoS is used for work that is not user initiated or visible.  In general, a user is unaware that this work is even happening and it will run in the most efficient manner while giving the most deference to higher QoS work.  For example, pre-fetching content, search indexing, backups, and syncing of data with external systems. */
    case background
    
    /* Default QoS indicates the absence of QoS information.  Whenever possible QoS information will be inferred from other sources.  If such inference is not possible, a QoS between UserInitiated and Utility will be used. */
    case `default`
}

public struct NSSortOptions: OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let concurrent = NSSortOptions(rawValue: UInt(1 << 0))
    public static let stable = NSSortOptions(rawValue: UInt(1 << 4))
}

public struct NSEnumerationOptions: OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let concurrent = NSEnumerationOptions(rawValue: UInt(1 << 0))
    public static let reverse = NSEnumerationOptions(rawValue: UInt(1 << 1))
}

public typealias Comparator = (Any, Any) -> ComparisonResult

public let NSNotFound: Int = Int.max

internal func NSRequiresConcreteImplementation(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("\(fn) must be overriden in subclass implementations", file: file, line: line)
}

internal func NSUnimplemented(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not yet implemented. \(file):\(line)")
    #endif
    fatalError("\(fn) is not yet implemented", file: file, line: line)
}

internal func NSUnsupported(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not supported on this platform. \(file):\(line)")
    #endif
    fatalError("\(fn) is not supported on this platform", file: file, line: line)
}

internal func NSInvalidArgument(_ message: String, method: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("\(method): \(message)", file: file, line: line)
}

internal struct _CFInfo {
    // This must match _CFRuntimeBase
    var info: UInt32
    var pad : UInt32
    init(typeID: CFTypeID) {
        // This matches what _CFRuntimeCreateInstance does to initialize the info value
        info = UInt32((UInt32(typeID) << 8) | (UInt32(0x80)))
        pad = 0
    }
    init(typeID: CFTypeID, extra: UInt32) {
        info = UInt32((UInt32(typeID) << 8) | (UInt32(0x80)))
        pad = extra
    }
}

#if os(OSX) || os(iOS)
private let _SwiftFoundationModuleName = "SwiftFoundation"
#else
private let _SwiftFoundationModuleName = "Foundation"
#endif

/**
    Returns the class name for a class. For compatibility with Foundation on Darwin,
    Foundation classes are returned as unqualified names.
 
    Only top-level Swift classes (Foo.bar) are supported at present. There is no
    canonical encoding for other types yet, except for the mangled name, which is
    neither stable nor human-readable.
 */
public func NSStringFromClass(_ aClass: AnyClass) -> String {
    let aClassName = String(reflecting: aClass)._bridgeToObjectiveC()
    let components = aClassName.components(separatedBy: ".")
    
    guard components.count == 2 else {
        fatalError("NSStringFromClass: \(String(reflecting: aClass)) is not a top-level class")
    }
    
    if components[0] == _SwiftFoundationModuleName {
        return components[1]
    } else {
        return String(describing: aClassName)
    }
}

/**
    Returns the class metadata given a string. For compatibility with Foundation on Darwin,
    unqualified names are looked up in the Foundation module.
 
    Only top-level Swift classes (Foo.bar) are supported at present. There is no
    canonical encoding for other types yet, except for the mangled name, which is
    neither stable nor human-readable.
 */
public func NSClassFromString(_ aClassName: String) -> AnyClass? {
    switch aClassName {
    case "NSAffineTransform": return NSAffineTransform.self
    case "NSArray": return NSArray.self
    case "NSByteCountFormatter": return ByteCountFormatter.self
    case "NSCachedURLResponse": return CachedURLResponse.self
    case "NSCalendar": return NSCalendar.self
    case "NSCharacterSet": return NSCharacterSet.self
    case "NSCoder": return NSCoder.self
    case "NSComparisonPredicate": return NSComparisonPredicate.self
    case "NSCompoundPredicate": return NSCompoundPredicate.self
    case "NSConditionLock": return NSConditionLock.self
    case "NSCountedSet": return NSCountedSet.self
    case "NSData": return NSData.self
    case "NSDate": return NSDate.self
    case "NSDateComponents": return NSDateComponents.self
    case "NSDateComponentsFormatter": return DateComponentsFormatter.self
    case "NSDateFormatter": return DateFormatter.self
    case "NSDateInterval": return NSDateInterval.self
    case "NSDateIntervalFormatter": return DateIntervalFormatter.self
    case "NSDecimalNumber": return NSDecimalNumber.self
    case "NSDecimalNumberHandler": return NSDecimalNumberHandler.self
    case "NSDictionary": return NSDictionary.self
    case "NSDimension": return Dimension.self
    case "NSDirectoryEnumerator": return FileManager.DirectoryEnumerator.self
    case "NSEnumerator": return NSEnumerator.self
    case "NSError": return NSError.self
    case "NSExpression": return NSExpression.self
    case "NSFileHandle": return FileHandle.self
    case "NSFileManager": return FileManager.self
    case "NSFormatter": return Formatter.self
    case "NSHTTPCookie": return HTTPCookie.self
    case "NSHTTPURLResponse": return HTTPURLResponse.self
    case "NSIndexPath": return NSIndexPath.self
    case "NSIndexSet": return NSIndexSet.self
    case "NSISO8601DateFormatter": return ISO8601DateFormatter.self
    case "NSJSONSerialization": return JSONSerialization.self
    case "NSKeyedArchiver": return NSKeyedArchiver.self
    case "NSKeyedUnarchiver": return NSKeyedUnarchiver.self
    case "NSLengthFormatter": return LengthFormatter.self
    case "NSMassFormatter": return MassFormatter.self
    case "NSMeasurement": return NSMeasurement.self
    case "NSMeasurementFormatter": return MeasurementFormatter.self
    case "NSMessagePort": return MessagePort.self
    case "NSMutableArray": return NSMutableArray.self
    case "NSMutableAttributedString": return NSMutableAttributedString.self
    case "NSMutableCharacterSet": return NSMutableCharacterSet.self
    case "NSMutableData": return NSMutableData.self
    case "NSMutableDictionary": return NSMutableDictionary.self
    case "NSMutableIndexSet": return NSMutableIndexSet.self
    case "NSMutableOrderedSet": return NSMutableOrderedSet.self
    case "NSMutableSet": return NSMutableSet.self
    case "NSMutableString": return NSMutableString.self
    case "NSMutableURLRequest": return NSMutableURLRequest.self
    case "NSNull": return NSNull.self
    case "NSNumber": return NSNumber.self
    case "NSNumberFormatter": return NumberFormatter.self
    case "NSObject": return NSObject.self
    case "NSOperation": return Operation.self
    case "NSOrderedSet": return NSOrderedSet.self
    case "NSOutputStream": return OutputStream.self
    case "NSPersonNameComponents": return NSPersonNameComponents.self
    case "NSPersonNameComponentsFormatter": return PersonNameComponentsFormatter.self
    case "NSPort": return Port.self
    case "NSPortMessage": return PortMessage.self
    case "NSPredicate": return NSPredicate.self
    case "NSProgress": return Progress.self
    case "NSPropertyListSerialization": return PropertyListSerialization.self
    case "NSSet": return NSSet.self
    case "NSSocketPort": return SocketPort.self
    case "NSString": return NSString.self
    case "NSThread": return Thread.self
    case "NSTimer": return Timer.self
    case "NSTimeZone": return NSTimeZone.self
    case "NSUnit": return Unit.self
    case "NSUnitAcceleration": return UnitAcceleration.self
    case "NSUnitAngle": return UnitAngle.self
    case "NSUnitArea": return UnitArea.self
    case "NSUnitConcentrationMass": return UnitConcentrationMass.self
    case "NSUnitConverter": return UnitConverter.self
    case "NSUnitConverterLinear": return UnitConverterLinear.self
    case "NSUnitDispersion": return UnitDispersion.self
    case "NSUnitDuration": return UnitDuration.self
    case "NSUnitElectricCharge": return UnitElectricCharge.self
    case "NSUnitElectricCurrent": return UnitElectricCurrent.self
    case "NSUnitElectricPotentialDifference": return UnitElectricPotentialDifference.self
    case "NSUnitElectricResistance": return UnitElectricResistance.self
    case "NSUnitEnergy": return UnitEnergy.self
    case "NSUnitFrequency": return UnitFrequency.self
    case "NSUnitFuelEfficiency": return UnitFuelEfficiency.self
    case "NSUnitIlluminance": return UnitIlluminance.self
    case "NSUnitLength": return UnitLength.self
    case "NSUnitMass": return UnitMass.self
    case "NSUnitPower": return UnitPower.self
    case "NSUnitPressure": return UnitPressure.self
    case "NSUnitSpeed": return UnitSpeed.self
    case "NSUnitTemperature": return UnitTemperature.self
    case "NSUnitVolume": return UnitVolume.self
    case "NSURL": return NSURL.self
    case "NSURLAuthenticationChallenge": return URLAuthenticationChallenge.self
    case "NSURLCache": return URLCache.self
    case "NSURLCredential": return URLCredential.self
    case "NSURLProtectionSpace": return URLProtectionSpace.self
    case "NSURLProtocol": return URLProtocol.self
    case "NSURLQueryItem": return NSURLQueryItem.self
    case "NSURLRequest": return NSURLRequest.self
    case "NSURLResponse": return URLResponse.self
    case "NSURLSession": return URLSession.self
    case "NSURLSessionConfiguration": return URLSessionConfiguration.self
    case "NSURLSessionDataTask": return URLSessionDataTask.self
    case "NSURLSessionDownloadTask": return URLSessionDownloadTask.self
    case "NSURLSessionStreamTask": return URLSessionStreamTask.self
    case "NSURLSessionTask": return URLSessionTask.self
    case "NSURLSessionUploadTask": return URLSessionUploadTask.self
    case "NSUUID": return NSUUID.self
    case "NSValue": return NSValue.self
    case "NSXMLDocument": return XMLDocument.self
    case "NSXMLDTD": return XMLDTD.self
    case "NSXMLParser": return XMLParser.self
    default:
        let aClassNameWithPrefix : String
        let components = aClassName._bridgeToObjectiveC().components(separatedBy: ".")
        
        switch components.count {
        case 1:
            guard !aClassName.hasPrefix("_Tt") else {
                NSLog("*** NSClassFromString(\(aClassName)): cannot yet decode mangled class names")
                return nil
            }
            aClassNameWithPrefix = _SwiftFoundationModuleName + "." + aClassName
        case 2:
            aClassNameWithPrefix = aClassName
        default:
            NSLog("*** NSClassFromString(\(aClassName)): nested class names not yet supported")
            return nil
        }
        
        return _typeByName(aClassNameWithPrefix) as? AnyClass
    }
    
}
