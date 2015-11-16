// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


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
}

extension _NSRange {
    public init(_ x: Range<Int>) {
        if let start = x.first {
            if let end = x.last {
                self.init(location: start, length: end - start)
                return
            }
        }
        self.init(location: 0, length: 0)
    }
    
    @warn_unused_result
    public func toRange() -> Range<Int>? {
        return Range<Int>(start: location, end: location + length)
    }
}

public typealias NSRange = _NSRange

public typealias NSRangePointer = UnsafeMutablePointer<NSRange>

public func NSMakeRange(loc: Int, _ len: Int) -> NSRange {
    return NSRange(location: loc, length: len)
}

public func NSMaxRange(range: NSRange) -> Int {
    return range.location + range.length
}

public func NSLocationInRange(loc: Int, _ range: NSRange) -> Bool {
    return !(loc < range.location) && (loc - range.location) < range.length
}

public func NSEqualRanges(range1: NSRange, _ range2: NSRange) -> Bool {
    return range1.location == range2.location && range1.length == range2.length
}

public func NSUnionRange(range1: NSRange, _ range2: NSRange) -> NSRange {
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

public func NSIntersectionRange(range1: NSRange, _ range2: NSRange) -> NSRange {
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

public func NSStringFromRange(range: NSRange) -> String {
    return "{\(range.location), \(range.length)}"
}

public func NSRangeFromString(aString: String) -> NSRange {
    NSUnimplemented()
}