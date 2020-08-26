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
extension NSTextCheckingResult {
    public struct CheckingType : OptionSet {
        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }
        
        public static let regularExpression = CheckingType(rawValue: 1 << 10)
    }
}

open class NSTextCheckingResult: NSObject, NSCopying, NSSecureCoding {
    
    public override init() {
        if type(of: self) == NSTextCheckingResult.self {
            NSRequiresConcreteImplementation()
        }
    }
    
    open class func regularExpressionCheckingResult(ranges: NSRangePointer, count: Int, regularExpression: NSRegularExpression) -> NSTextCheckingResult {
        let buffer = UnsafeBufferPointer(start: ranges, count: count)
        let array = Array(buffer)
        
        if count > 0 && count <= 3 {
            return NSSimpleRegularExpressionCheckingResult(rangeArray: array, regularExpression: regularExpression)
        } else if count > 3 && count <= 7 {
            return NSExtendedRegularExpressionCheckingResult(rangeArray: array, regularExpression: regularExpression)
        } else {
            return NSComplexRegularExpressionCheckingResult(rangeArray: array, regularExpression: regularExpression)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        if type(of: self) == NSTextCheckingResult.self {
            NSRequiresConcreteImplementation()
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        NSRequiresConcreteImplementation()
    }
    
    open class var supportsSecureCoding: Bool {
        NSRequiresConcreteImplementation()
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    /* Mandatory properties, used with all types of results. */
    open var resultType: CheckingType { NSRequiresConcreteImplementation() }
    open var range: NSRange { return range(at: 0) }
    /* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
    open func range(at idx: Int) -> NSRange { NSRequiresConcreteImplementation() }
    @available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
    open func range(withName: String) -> NSRange { NSRequiresConcreteImplementation() }
    open var regularExpression: NSRegularExpression? { return nil }
    open var numberOfRanges: Int { return 1 }
    
    internal func encodeRange(with coder: NSCoder) {
        guard coder.allowsKeyedCoding else {
            fatalError("Encoding this class requires keyed coding")
        }
        
        coder.encode(range.location, forKey: "NSRangeLocation")
        coder.encode(range.length,   forKey: "NSRangeLength")
    }
    
    internal func decodeRange(from coder: NSCoder) -> NSRange {
        guard coder.allowsKeyedCoding else {
            fatalError("Decoding this class requires keyed coding")
        }
        
        return NSMakeRange(coder.decodeInteger(forKey: "NSRangeLocation"), coder.decodeInteger(forKey: "NSRangeLength"))
    }
}

// Darwin uses these private subclasses, each of which can be archived. We reimplement all three here so that NSKeyed{Una,A}rchiver can find them.
// Since we do not have to box an array of NSRanges into a NSArray of NSValues, we do not implement the storage optimization these subclasses would have on Darwin. They exist purely to be encoded or decoded. When we produce instances, we will produce the correct subclass for the count Darwin expects so that _that_ implementation can likewise be efficient.

internal class NSRegularExpressionCheckingResult: NSTextCheckingResult {
    let _regularExpression: NSRegularExpression!
    override var regularExpression: NSRegularExpression? { return _regularExpression }
    
    let _rangeArray: [NSRange]!
    var rangeArray: [NSRange] { return _rangeArray }

    init(rangeArray: [NSRange], regularExpression: NSRegularExpression) {
        _rangeArray = rangeArray.map { $0.location == kCFNotFound ? NSMakeRange(NSNotFound, 0) : $0 }
        _regularExpression = regularExpression
        super.init()
    }
    
    override init() {
        if type(of: self) == NSRegularExpressionCheckingResult.self {
            NSRequiresConcreteImplementation()
        }
        
        _regularExpression = nil
        _rangeArray = nil
        super.init()
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            fatalError("Decoding this class requires keyed coding")
        }
        
        let regularExpression = aDecoder.decodeObject(of: NSRegularExpression.self, forKey: "NSRegularExpression")!
        let nsRanges = aDecoder.decodeObject(of: [ NSArray.self, NSValue.self ], forKey: "NSRangeArray") as! NSArray
        let rangeArray = nsRanges.compactMap { return ($0 as! NSValue).rangeValue }
        
        self.init(rangeArray: rangeArray, regularExpression: regularExpression)
    }
    
    override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            fatalError("Encoding this class requires keyed coding")
        }
        
        let ranges = rangeArray.map { NSValue(range: $0) }._nsObject
        
        encodeRange(with: aCoder)
        aCoder.encode(regularExpression, forKey: "NSRegularExpression")
        aCoder.encode(ranges, forKey: "NSRangeArray")
    }
    
    override class var supportsSecureCoding: Bool { return true }
    
    override var resultType: NSTextCheckingResult.CheckingType { return .regularExpression }
    
    override func range(withName name: String) -> NSRange {
        let idx = regularExpression!._captureGroupNumber(withName: name)
        if idx != kCFNotFound, idx < numberOfRanges {
            return range(at: idx)
        }
        
        return NSRange(location: NSNotFound, length: 0)
    }
    
    override func range(at idx: Int) -> NSRange {
        return rangeArray[idx]
    }
    
    override var numberOfRanges: Int {
        return rangeArray.count
    }
}

internal class NSSimpleRegularExpressionCheckingResult: NSRegularExpressionCheckingResult {}
internal class NSExtendedRegularExpressionCheckingResult: NSRegularExpressionCheckingResult {}
internal class NSComplexRegularExpressionCheckingResult: NSRegularExpressionCheckingResult {}


extension NSTextCheckingResult {
    
    public func adjustingRanges(offset: Int) -> NSTextCheckingResult {
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
        let result = NSTextCheckingResult.regularExpressionCheckingResult(ranges: &newRanges, count: count, regularExpression: self.regularExpression!)
        return result
    }
}

// MARK: Availability diagnostics for unsupported features

@available(*, deprecated, message: "These types of result will not be returned by swift-corelibs-foundation API.")
extension NSTextCheckingResult.CheckingType {
    public static let orthography = NSTextCheckingResult.CheckingType(rawValue: 1 << 1)
    public static let spelling = NSTextCheckingResult.CheckingType(rawValue: 1 << 2)
    public static let grammar = NSTextCheckingResult.CheckingType(rawValue: 1 << 3)
    public static let date = NSTextCheckingResult.CheckingType(rawValue: 1 << 4)
    public static let address = NSTextCheckingResult.CheckingType(rawValue: 1 << 5)
    public static let link = NSTextCheckingResult.CheckingType(rawValue: 1 << 6)
    public static let quote = NSTextCheckingResult.CheckingType(rawValue: 1 << 7)
    public static let dash = NSTextCheckingResult.CheckingType(rawValue: 1 << 8)
    public static let replacement = NSTextCheckingResult.CheckingType(rawValue: 1 << 9)
    public static let correction = NSTextCheckingResult.CheckingType(rawValue: 1 << 10)
    public static let phoneNumber = NSTextCheckingResult.CheckingType(rawValue: 1 << 11)
    public static let transitInformation = NSTextCheckingResult.CheckingType(rawValue: 1 << 12)
}

public struct NSTextCheckingKey: RawRepresentable, Hashable {
    public var rawValue: String
    
    init(_ string: String) {
        self.init(rawValue: string)
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@available(*, deprecated, message: "Results associated with these keys are not available in swift-corelibs-foundation.")
extension NSTextCheckingKey {
    static let airline = NSTextCheckingKey(rawValue: "Airline")
    static let city = NSTextCheckingKey(rawValue: "City")
    static let country = NSTextCheckingKey(rawValue: "Country")
    static let flight = NSTextCheckingKey(rawValue: "Flight")
    static let jobTitle = NSTextCheckingKey(rawValue: "JobTitle")
    static let name = NSTextCheckingKey(rawValue: "Name")
    static let organization = NSTextCheckingKey(rawValue: "Organization")
    static let phone = NSTextCheckingKey(rawValue: "Phone")
    static let state = NSTextCheckingKey(rawValue: "State")
    static let street = NSTextCheckingKey(rawValue: "Street")
    static let zip = NSTextCheckingKey(rawValue: "Zip")
}

@available(*, unavailable, message: "These types of results cannot be constructed in swift-corelibs-foundation")
extension NSTextCheckingResult {
    open class func orthographyCheckingResult(range: NSRange, orthography: NSOrthography) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func spellCheckingResult(range: NSRange) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func grammarCheckingResult(range: NSRange, details: [[String : Any]]) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func dateCheckingResult(range: NSRange, date: Date) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func dateCheckingResult(range: NSRange, date: Date, timeZone: TimeZone, duration: TimeInterval) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func addressCheckingResult(range: NSRange, components: [NSTextCheckingKey : String]) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func linkCheckingResult(range: NSRange, url: URL) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func quoteCheckingResult(range: NSRange, replacementString: String) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func dashCheckingResult(range: NSRange, replacementString: String) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func replacementCheckingResult(range: NSRange, replacementString: String) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func correctionCheckingResult(range: NSRange, replacementString: String, alternativeStrings: [String]) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func phoneNumberCheckingResult(range: NSRange, phoneNumber: String) -> NSTextCheckingResult {
        NSUnsupported()
    }
    
    open class func transitInformationCheckingResult(range: NSRange, components: [NSTextCheckingKey : String]) -> NSTextCheckingResult {
        NSUnsupported()
    }
}

@available(*, deprecated, message: "NSOrtography is not available in swift-corelibs-foundation")
open class NSOrthography: NSObject, NSCopying, NSSecureCoding {
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open class func defaultOrtography(forLanguage: String) -> Self {
        NSUnsupported()
    }
    
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    public init(dominantScript: String, languageMap: [String: [String]]) {
        NSUnsupported()
    }
    
    public func copy(with zone: NSZone?) -> Any {
        NSUnsupported()
    }
    
    open class var supportsSecureCoding: Bool { NSUnsupported() }
    
    public func encode(with aCoder: NSCoder) {
        NSUnsupported()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnsupported()
    }
    
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open var languageMap: [String: [String]] { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open var dominantLanguage: String { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open var dominantScript: String { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open func dominantLanguage(forScript: String) -> String? { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open func language(forScript: String) -> [String]? { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open var alLScripts: [String] { NSUnsupported() }
    @available(*, unavailable, message: "NSOrtography is not available in swift-corelibs-foundation")
    open var allLanguages: [String] { NSUnsupported() }
}
