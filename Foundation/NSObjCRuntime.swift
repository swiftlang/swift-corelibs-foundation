// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(macOS) || os(iOS)
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

#if os(macOS) || os(iOS)
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
