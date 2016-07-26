// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public struct _NSRange {
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
    
    internal init(_ range: CFRange) {
        location = range.location == kCFNotFound ? NSNotFound : range.location
        length = range.length
    }
}

extension CFRange {
    internal init(_ range: NSRange) {
        location = range.location == NSNotFound ? kCFNotFound : range.location
        length = range.length
    }
}

public typealias NSRange = _NSRange

extension NSRange {
    public init(_ x: CountableRange<Int>) {
        location = x.startIndex
        length = x.count
    }
    
    public func toRange() -> CountableRange<Int>? {
        if location == NSNotFound { return nil }
        let min = location
        let max = location + length
        return min..<max
    }
}

extension NSRange: NSSpecialValueCoding {
    init(bytes: UnsafePointer<Void>) {
        let buffer = UnsafePointer<Int>(bytes)
        
        self.location = buffer.pointee
        self.length = buffer.advanced(by: 1).pointee
    }
    
    init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            if let location = aDecoder.decodeObjectOfClass(NSNumber.self, forKey: "NS.rangeval.location") {
                self.location = location.intValue
            } else {
                self.location = 0
            }
            if let length = aDecoder.decodeObjectOfClass(NSNumber.self, forKey: "NS.rangeval.length") {
                self.length = length.intValue
            } else {
                self.length = 0
            }
        } else {
            NSUnimplemented()
        }
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encode(NSNumber(value: self.location), forKey: "NS.rangeval.location")
            aCoder.encode(NSNumber(value: self.length), forKey: "NS.rangeval.length")
        } else {
            NSUnimplemented()
        }
    }
    
    static func objCType() -> String {
#if arch(i386) || arch(arm)
        return "{_NSRange=II}"
#elseif arch(x86_64) || arch(arm64) || arch(s390x)
        return "{_NSRange=QQ}"
#else
        NSUnimplemented()
#endif
    }
    
    func getValue(_ value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<NSRange>(value).pointee = self
    }
    
    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? NSRange {
            return other.location == self.location && other.length == self.length
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.location &+ self.length
    }
    
    var description: String? {
        return NSStringFromRange(self)
    }
}

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
    let max1 = range1.location + range1.length
    let max2 = range2.location + range2.length
    let maxend: Int
    if max1 > max2 {
        maxend = max1
    } else {
        maxend = max2
    }
    let minloc: Int
    if range1.location < range2.location {
        minloc = range1.location
    } else {
        minloc = range2.location
    }
    return NSMakeRange(minloc, maxend - minloc)
}

public func NSIntersectionRange(_ range1: NSRange, _ range2: NSRange) -> NSRange {
    let max1 = range1.location + range1.length
    let max2 = range2.location + range2.length
    let minend: Int
    if max1 < max2 {
        minend = max1
    } else {
        minend = max2
    }
    if range2.location <= range1.location && range1.location < max2 {
        return NSMakeRange(range1.location, minend - range1.location)
    } else if range1.location <= range2.location && range2.location < max1 {
        return NSMakeRange(range2.location, minend - range2.location)
    }
    return NSMakeRange(0, 0)
}

public func NSStringFromRange(_ range: NSRange) -> String {
    return "{\(range.location), \(range.length)}"
}

public func NSRangeFromString(_ aString: String) -> NSRange {
    let emptyRange = NSMakeRange(0, 0)
    if aString.isEmpty {
        // fail early if the string is empty
        return emptyRange
    }
    let scanner = Scanner(string: aString)
    let digitSet = CharacterSet.decimalDigits
    let _ = scanner.scanUpToCharactersFromSet(digitSet)
    if scanner.atEnd {
        // fail early if there are no decimal digits
        return emptyRange
    }
    guard let location = scanner.scanInteger() else {
        return emptyRange
    }
    let partialRange = NSMakeRange(location, 0)
    if scanner.atEnd {
        // return early if there are no more characters after the first int in the string
        return partialRange
    }
    let _ = scanner.scanUpToCharactersFromSet(digitSet)
    if scanner.atEnd {
        // return early if there are no integer characters after the first int in the string
        return partialRange
    }
    guard let length = scanner.scanInteger() else {
        return partialRange
    }
    return NSMakeRange(location, length)
}

extension NSValue {
    public convenience init(range: NSRange) {
        self.init()
        self._concreteValue = NSSpecialValue(range)
    }
    
    public var rangeValue: NSRange {
        let specialValue = self._concreteValue as! NSSpecialValue
        return specialValue._value as! NSRange
    }
}
