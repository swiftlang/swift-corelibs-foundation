// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/* NSTextCheckingType in this project is limited to regular expressions. */
public struct NSTextCheckingType : OptionSetType {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    
    public static let RegularExpression = NSTextCheckingType(rawValue: 1 << 10) // regular expression matches
}

public class NSTextCheckingResult : NSObject, NSCopying, NSCoding {
    
    public class func regularExpressionCheckingResultWithRanges(ranges: NSRangePointer, count: Int, regularExpression: NSRegularExpression) -> NSTextCheckingResult { NSUnimplemented() }

    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /* Mandatory properties, used with all types of results. */
    public var resultType: NSTextCheckingType { NSUnimplemented() }
    public var range: NSRange { NSUnimplemented() }
}

extension NSTextCheckingResult {
    
    /*@NSCopying*/ public var regularExpression: NSRegularExpression? { NSUnimplemented() }
    
    /* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
    public var numberOfRanges: Int { NSUnimplemented() }
    public func rangeAtIndex(idx: Int) -> NSRange { NSUnimplemented() }
    public func resultByAdjustingRangesWithOffset(offset: Int) -> NSTextCheckingResult { NSUnimplemented() }
}
