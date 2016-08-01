// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

/* NSTextCheckingType in this project is limited to regular expressions. */
extension TextCheckingResult {
    public struct CheckingType : OptionSet {
        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }
        
        public static let RegularExpression = CheckingType(rawValue: 1 << 10) // regular expression matches
    }
}

open class TextCheckingResult: NSObject, NSCopying, NSCoding {
    
    public override init() {
        super.init()
    }
    
    open class func regularExpressionCheckingResultWithRanges(_ ranges: NSRangePointer, count: Int, regularExpression: RegularExpression) -> TextCheckingResult {
        return _NSRegularExpressionTextCheckingResultResult(ranges: ranges, count: count, regularExpression: regularExpression)
    }

    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }
    
    /* Mandatory properties, used with all types of results. */
    open var resultType: CheckingType { NSUnimplemented() }
    open var range: NSRange { return range(at: 0) }
    /* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
    open func range(at idx: Int) -> NSRange { NSUnimplemented() }
    open var regularExpression: RegularExpression? { return nil }
    open var numberOfRanges: Int { return 1 }
}

internal class _NSRegularExpressionTextCheckingResultResult : TextCheckingResult {
    var _ranges = [NSRange]()
    let _regularExpression: RegularExpression
    init(ranges: NSRangePointer, count: Int, regularExpression: RegularExpression) {
        _regularExpression = regularExpression
        super.init()
        let notFound = NSRange(location: NSNotFound,length: 0)
        for i in 0..<count {
            ranges[i].location == kCFNotFound ? _ranges.append(notFound) : _ranges.append(ranges[i])
        }  
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var resultType: CheckingType { return .RegularExpression }
    override func range(at idx: Int) -> NSRange { return _ranges[idx] }
    override var numberOfRanges: Int { return _ranges.count }
    override var regularExpression: RegularExpression? { return _regularExpression }
}

extension TextCheckingResult {
    
    public func resultByAdjustingRangesWithOffset(_ offset: Int) -> TextCheckingResult {
        let count = self.numberOfRanges
        var newRanges = [NSRange]()
        for idx in 0..<count {
           let currentRange = self.range(at: idx)
           if (currentRange.location == NSNotFound) {
              newRanges.append(currentRange)
           } else if ((offset > 0 && NSNotFound - currentRange.location <= offset) || (offset < 0 && currentRange.location < -offset)) {
              NSInvalidArgument(" \(offset) invalid offset for range {\(currentRange.location), \(currentRange.length)}")
           } else {
              newRanges.append(NSRange(location: currentRange.location + offset,length: currentRange.length))
           }
        }
        let result = TextCheckingResult.regularExpressionCheckingResultWithRanges(&newRanges, count: count, regularExpression: self.regularExpression!)
        return result
    }
}

