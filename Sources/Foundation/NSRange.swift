// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_SWIFT

internal import CoreFoundation

public struct _NSRange : Sendable {
    public var location: Int
    public var length: Int
    
    
    public init() {
        location = 0
        length = 0
    }
    
    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
}
    
public typealias NSRange = _NSRange
    
public typealias NSRangePointer = UnsafeMutablePointer<NSRange>

public func NSMakeRange(_ loc: Int, _ len: Int) -> NSRange {
    return NSRange(location: loc, length: len)
}

public func NSMaxRange(_ range: NSRange) -> Int {
    return range.location + range.length
}

public func NSLocationInRange(_ loc: Int, _ range: NSRange) -> Bool {
    return !(loc < range.location) && (loc - range.location) < range.length
}

public func NSEqualRanges(_ range1: NSRange, _ range2: NSRange) -> Bool {
    return range1.location == range2.location && range1.length == range2.length
}

public func NSUnionRange(_ range1: NSRange, _ range2: NSRange) -> NSRange {
    let end1 = range1.location + range1.length
    let end2 = range2.location + range2.length
    let maxend: Int
    if end1 > end2 {
        maxend = end1
    } else {
        maxend = end2
    }
    let minloc: Int
    if range1.location < range2.location {
        minloc = range1.location
    } else {
        minloc = range2.location
    }
    return NSRange(location: minloc, length: maxend - minloc)
}

public func NSIntersectionRange(_ range1: NSRange, _ range2: NSRange) -> NSRange {
    let end1 = range1.location + range1.length
    let end2 = range2.location + range2.length
    let minend: Int
    if end1 < end2 {
        minend = end1
    } else {
        minend = end2
    }
    if range2.location <= range1.location && range1.location < end2 {
        return NSRange(location: range1.location, length: minend - range1.location)
    } else if range1.location <= range2.location && range2.location < end1 {
        return NSRange(location: range2.location, length: minend - range2.location)
    }
    return NSRange(location: 0, length: 0)
}

public func NSStringFromRange(_ range: NSRange) -> String {
    return "{\(range.location), \(range.length)}"
}

public func NSRangeFromString(_ aString: String) -> NSRange {
    let emptyRange = NSRange(location: 0, length: 0)
    if aString.isEmpty {
        // fail early if the string is empty
        return emptyRange
    }
    let scanner = Scanner(string: aString)
    let digitSet = CharacterSet.decimalDigits
    let _ = scanner.scanUpToCharacters(from: digitSet)
    if scanner.isAtEnd {
        // fail early if there are no decimal digits
        return emptyRange
    }
    guard let location = scanner.scanInt() else {
        return emptyRange
    }
    let partialRange = NSRange(location: location, length: 0)
    if scanner.isAtEnd {
        // return early if there are no more characters after the first int in the string
        return partialRange
    }
    let _ = scanner.scanUpToCharacters(from: digitSet)
    if scanner.isAtEnd {
        // return early if there are no integer characters after the first int in the string
        return partialRange
    }
    guard let length = scanner.scanInt() else {
        return partialRange
    }
    return NSRange(location: location, length: length)
}
    
#else
@_exported import Foundation // Clang module
#endif

extension NSRange : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
        hasher.combine(length)
    }
    
    public static func==(_ lhs: NSRange, _ rhs: NSRange) -> Bool {
        return lhs.location == rhs.location && lhs.length == rhs.length
    }
}

extension NSRange : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { return "{\(location), \(length)}" }
    public var debugDescription: String {
        guard location != NSNotFound else {
            return "{NSNotFound, \(length)}"
        }
        return "{\(location), \(length)}"
    }
}

extension NSRange {
    public init?(_ string: String) {
        var savedLocation = 0
        if string.isEmpty {
            // fail early if the string is empty
            return nil
        }
        let scanner = Scanner(string: string)
        let digitSet = CharacterSet.decimalDigits
        let _ = scanner.scanUpToCharacters(from: digitSet)
        if scanner.isAtEnd {
            // fail early if there are no decimal digits
            return nil
        }
        var location = 0
        savedLocation = scanner.scanLocation
        guard scanner.scanInt(&location) else {
            return nil
        }
        if scanner.isAtEnd {
            // return early if there are no more characters after the first int in the string
            return nil
        }
        if scanner.scanString(".") != nil {
            scanner.scanLocation = savedLocation
            var double = 0.0
            guard scanner.scanDouble(&double) else {
                return nil
            }
            guard let integral = Int(exactly: double) else {
                return nil
            }
            location = integral
        }
        
        let _ = scanner.scanUpToCharacters(from: digitSet)
        if scanner.isAtEnd {
            // return early if there are no integer characters after the first int in the string
            return nil
        }
        var length = 0
        savedLocation = scanner.scanLocation
        guard scanner.scanInt(&length) else {
            return nil
        }
        
        if !scanner.isAtEnd {
            if scanner.scanString(".") != nil {
                scanner.scanLocation = savedLocation
                var double = 0.0
                guard scanner.scanDouble(&double) else {
                    return nil
                }
                guard let integral = Int(exactly: double) else {
                    return nil
                }
                length = integral
            }
        }
        
        
        self.location = location
        self.length = length
    }
}

extension NSRange {
    public var lowerBound: Int { return location }
    
    public var upperBound: Int { return location + length }
    
    public func contains(_ index: Int) -> Bool { return (!(index < location) && (index - location) < length) }
    
    public mutating func formUnion(_ other: NSRange) {
        self = union(other)
    }
    
    public func union(_ other: NSRange) -> NSRange {
        let end1 = location + length
        let end2 = other.location + other.length
        let maxend = (end1 < end2) ? end2 : end1
        let minloc = location < other.location ? location : other.location
        return NSRange(location: minloc, length: maxend - minloc)
    }
    
    public func intersection(_ other: NSRange) -> NSRange? {
        let end1 = location + length
        let end2 = other.location + other.length
        let minend = (end1 < end2) ? end1 : end2
        if other.location <= location && location < end2 {
            return NSRange(location: location, length: minend - location)
        } else if location <= other.location && other.location < end1 {
            return NSRange(location: other.location, length: minend - other.location);
        }
        return nil
    }
}


//===----------------------------------------------------------------------===//
// Ranges
//===----------------------------------------------------------------------===//

extension NSRange {
    public init<R: RangeExpression>(_ region: R)
        where R.Bound: FixedWidthInteger {
            let r = region.relative(to: 0..<R.Bound.max)
            location = numericCast(r.lowerBound)
            length = numericCast(r.count)
    }
    
    public init<R: RangeExpression, S: StringProtocol>(_ region: R, in target: S)
        where R.Bound == S.Index {
            let r = region.relative(to: target)
            self.init(target._toUTF16Offsets(r))
    }
    
    @available(swift, deprecated: 4, renamed: "Range.init(_:)")
    public func toRange() -> Range<Int>? {
        if location == NSNotFound { return nil }
        return location..<(location+length)
    }
}

extension Range where Bound: BinaryInteger {
    public init?(_ range: NSRange) {
        guard range.location != NSNotFound else { return nil }
        self.init(uncheckedBounds: (numericCast(range.lowerBound), numericCast(range.upperBound)))
    }
}

// This additional overload will mean Range.init(_:) defaults to Range<Int> when
// no additional type context is provided:
extension Range where Bound == Int {
    public init?(_ range: NSRange) {
        guard range.location != NSNotFound else { return nil }
        self.init(uncheckedBounds: (range.lowerBound, range.upperBound))
    }
}

extension Range where Bound == String.Index {
    public init?(_ range: NSRange, in string: String) {
        let u = string.utf16
        guard range.location != NSNotFound,
            let start = u.index(u.startIndex, offsetBy: range.location, limitedBy: u.endIndex),
            let end = u.index(u.startIndex, offsetBy: range.location + range.length, limitedBy: u.endIndex),
            let lowerBound = String.Index(start, within: string),
            let upperBound = String.Index(end, within: string)
            else { return nil }
        
        self = lowerBound..<upperBound
    }
}

extension NSRange : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: ["location": location, "length": length])
    }
}

extension NSRange : CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return (Int64(location), Int64(length))
    }
}

extension NSRange : Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let location = try container.decode(Int.self)
        let length = try container.decode(Int.self)
        self.init(location: location, length: length)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.location)
        try container.encode(self.length)
    }
}

#if DEPLOYMENT_RUNTIME_SWIFT

    
extension NSRange {
    internal init(_ range: CFRange) {
        location = range.location == kCFNotFound ? NSNotFound : range.location
        length = range.length
    }
}
    
extension CFRange {
    internal init(_ range: NSRange) {
        let _location = range.location == NSNotFound ? kCFNotFound : range.location
        self.init(location: _location, length: range.length)
    }
}
    
extension NSRange {
    public init(_ x: Range<Int>) {
        location = x.lowerBound
        length = x.count
    }
}
    
extension NSRange: NSSpecialValueCoding {
    init(bytes: UnsafeRawPointer) {
        self.location = bytes.load(as: Int.self)
        self.length = bytes.load(fromByteOffset: MemoryLayout<Int>.stride, as: Int.self)
    }
    
    init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        if let location = aDecoder.decodeObject(of: NSNumber.self, forKey: "NS.rangeval.location") {
            self.location = location.intValue
        } else {
            self.location = 0
        }
        if let length = aDecoder.decodeObject(of: NSNumber.self, forKey: "NS.rangeval.length") {
            self.length = length.intValue
        } else {
            self.length = 0
        }
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(NSNumber(value: self.location), forKey: "NS.rangeval.location")
        aCoder.encode(NSNumber(value: self.length), forKey: "NS.rangeval.length")
    }
    
    static func objCType() -> String {
#if arch(i386) || arch(arm) || arch(wasm32)
        return "{_NSRange=II}"
#elseif arch(x86_64) || arch(arm64) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
        return "{_NSRange=QQ}"
#else
        #error("This architecture isn't known. Add it to the 32-bit or 64-bit line.")
#endif
    }
    
    func getValue(_ value: UnsafeMutableRawPointer) {
        value.initializeMemory(as: NSRange.self, repeating: self, count: 1)
    }
    
    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? NSRange {
            return other.location == self.location && other.length == self.length
        } else {
            return false
        }
    }
}
    
extension NSValue {
    public convenience init(range: NSRange) {
        self.init { NSSpecialValue(range) as! Self }
    }
    
    public var rangeValue: NSRange {
        let specialValue = self as! NSSpecialValue
        return specialValue._value as! NSRange
    }
}
#endif
