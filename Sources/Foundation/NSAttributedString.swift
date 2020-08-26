// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension NSAttributedString {
    public struct Key: RawRepresentable, Equatable, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension NSAttributedString.Key: _ObjectiveCBridgeable {
    public func _bridgeToObjectiveC() -> NSString {
        return rawValue as NSString
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: NSString, result: inout NSAttributedString.Key?) {
        result = NSAttributedString.Key(source as String)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSString, result: inout NSAttributedString.Key?) -> Bool {
        result = NSAttributedString.Key(source as String)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSString?) -> NSAttributedString.Key {
        guard let source = source else { return NSAttributedString.Key("") }
        return NSAttributedString.Key(source as String)
    }
}

@available(*, unavailable, renamed: "NSAttributedString.Key")
public typealias NSAttributedStringKey = NSAttributedString.Key

open class NSAttributedString: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    fileprivate var _string: NSString
    fileprivate var _attributeArray: CFRunArrayRef
    
    public required init?(coder aDecoder: NSCoder) {
        let mutableAttributedString = NSMutableAttributedString(string: "")
        guard _NSReadMutableAttributedStringWithCoder(aDecoder, mutableAttributedString: mutableAttributedString) else {
            return nil
        }
        
        // use the resulting _string and _attributeArray to initialize a new instance, just like init
        _string = mutableAttributedString._string
        _attributeArray = mutableAttributedString._attributeArray
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else { fatalError("We do not support saving to a non-keyed coder.") }
        
        aCoder.encode(string, forKey: "NSString")
        let length = self.length
        
        if length > 0 {
            var range = NSMakeRange(NSNotFound, NSNotFound)
            var loc = 0
            var dict = attributes(at: loc, effectiveRange: &range) as NSDictionary
            if range.length == length {
                // Special single-attribute run case
                // If NSAttributeInfo is not written, then NSAttributes is a dictionary
                aCoder.encode(dict, forKey: "NSAttributes")
            } else {
                let attrsArray = NSMutableArray(capacity: 20)
                let data = NSMutableData(capacity: 100) ?? NSMutableData()
                let attrsTable = NSMutableDictionary()
                while true {
                    var arraySlot = 0
                    if let cachedSlot = attrsTable.object(forKey: dict) as? Int {
                        arraySlot = cachedSlot
                    } else {
                        arraySlot = attrsArray.count
                        attrsTable.setObject(arraySlot, forKey: dict)
                        attrsArray.add(dict)
                    }
                    
                    _NSWriteIntToMutableAttributedStringCoding(range.length, data)
                    _NSWriteIntToMutableAttributedStringCoding(arraySlot, data)
                    
                    loc += range.length
                    guard loc < length else { break }
                    dict = attributes(at: loc, effectiveRange: &range) as NSDictionary
                }
                aCoder.encode(attrsArray, forKey: "NSAttributes")
                aCoder.encode(data, forKey: "NSAttributeInfo")
            }
        }
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        return NSMutableAttributedString(attributedString: self)
    }

    /// The character contents of the receiver as an NSString object.
    open var string: String {
        return _string._swiftObject
    }

    /// Returns the attributes for the character at a given index.
    open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attributes(at: location, rangeInfo: rangeInfo)
    }

    /// The length of the receiver’s string object.
    open var length: Int {
        return CFAttributedStringGetLength(_cfObject)
    }

    /// Returns the value for an attribute with a given name of the character at a given index, and by reference the range over which the attribute applies.
    open func attribute(_ attrName: NSAttributedString.Key, at location: Int, effectiveRange range: NSRangePointer?) -> Any? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }

    /// Returns an NSAttributedString object consisting of the characters and attributes within a given range in the receiver.
    open func attributedSubstring(from range: NSRange) -> NSAttributedString {
        let attributedSubstring = CFAttributedStringCreateWithSubstring(kCFAllocatorDefault, _cfObject, CFRange(range))
        return unsafeBitCast(attributedSubstring, to: NSAttributedString.self)
    }

    /// Returns the attributes for the character at a given index, and by reference the range over which the attributes apply.
    open func attributes(at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> [NSAttributedString.Key: Any] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attributes(at: location, rangeInfo: rangeInfo)
    }

    /// Returns the value for the attribute with a given name of the character at a given index, and by reference the range over which the attribute applies.
    open func attribute(_ attrName: NSAttributedString.Key, at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> Any? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSAttributedString else { return false }
        return isEqual(to: other)
    }
    
    /// Returns a Boolean value that indicates whether the receiver is equal to another given attributed string.
    open func isEqual(to other: NSAttributedString) -> Bool {
        guard let runtimeClass = _CFRuntimeGetClassWithTypeID(CFAttributedStringGetTypeID()) else {
            fatalError("Could not obtain CFRuntimeClass of CFAttributedString")
        }
        
        guard let equalFunction = runtimeClass.pointee.equal else {
            fatalError("Could not obtain equal function from CFRuntimeClass of CFAttributedString")
        }
        
        return equalFunction(_cfObject, other._cfObject) == true
    }

    /// Returns an NSAttributedString object initialized with the characters of a given string and no attribute information.
    public init(string: String) {
        _string = string._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        super.init()
        addAttributesToAttributeArray(attrs: nil)
    }

    /// Returns an NSAttributedString object initialized with a given string and attributes.
    public init(string: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) {
        _string = string._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)

        super.init()
        addAttributesToAttributeArray(attrs: attrs)
    }

    /// Returns an NSAttributedString object initialized with the characters and attributes of another given attributed string.
    public init(attributedString: NSAttributedString) {
        // create an empty mutable attr string then immediately replace all of its contents
        let mutableAttributedString = NSMutableAttributedString(string: "")
        mutableAttributedString.setAttributedString(attributedString)
        
        // use the resulting _string and _attributeArray to initialize a new instance
        _string = mutableAttributedString._string
        _attributeArray = mutableAttributedString._attributeArray
    }

    /// Executes the block for each attribute in the range.
    open func enumerateAttributes(in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: ([NSAttributedString.Key: Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _enumerate(in: enumerationRange, reversed: opts.contains(.reverse)) { currentIndex, stop in
            var attributesEffectiveRange = NSRange(location: NSNotFound, length: 0)
            let attributesInRange: [NSAttributedString.Key: Any]
            if opts.contains(.longestEffectiveRangeNotRequired) {
                attributesInRange = attributes(at: currentIndex, effectiveRange: &attributesEffectiveRange)
            } else {
                attributesInRange = attributes(at: currentIndex, longestEffectiveRange: &attributesEffectiveRange, in: enumerationRange)
            }
            
            var shouldStop: ObjCBool = false
            block(attributesInRange, attributesEffectiveRange, &shouldStop)
            stop.pointee = shouldStop
            
            return attributesEffectiveRange
        }
    }

    /// Executes the block for the specified attribute run in the specified range.
    open func enumerateAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _enumerate(in: enumerationRange, reversed: opts.contains(.reverse)) { currentIndex, stop in
            var attributeEffectiveRange = NSRange(location: NSNotFound, length: 0)
            let attributeInRange: Any?
            if opts.contains(.longestEffectiveRangeNotRequired) {
                attributeInRange = attribute(attrName, at: currentIndex, effectiveRange: &attributeEffectiveRange)
            } else {
                attributeInRange = attribute(attrName, at: currentIndex, longestEffectiveRange: &attributeEffectiveRange, in: enumerationRange)
            }
            
            var shouldStop: ObjCBool = false
            block(attributeInRange, attributeEffectiveRange, &shouldStop)
            stop.pointee = shouldStop
            
            return attributeEffectiveRange
        }
    }

}

private extension NSAttributedString {
    
    struct AttributeEnumerationRange {
        let startIndex: Int
        let endIndex: Int
        let reversed: Bool
        var currentIndex: Int
        
        var hasMore: Bool {
            if reversed {
                return currentIndex >= endIndex
            } else {
                return currentIndex <= endIndex
            }
        }
        
        init(range: NSRange, reversed: Bool) {
            let lowerBound = range.location
            let upperBound = range.location + range.length - 1
            self.reversed = reversed
            startIndex = reversed ? upperBound : lowerBound
            endIndex = reversed ? lowerBound : upperBound
            currentIndex = startIndex
        }
        
        mutating func advance(step: Int = 1) {
            if reversed {
                currentIndex -= step
            } else {
                currentIndex += step
            }
        }
    }
    
    struct RangeInfo {
        let rangePointer: NSRangePointer?
        let shouldFetchLongestEffectiveRange: Bool
        let longestEffectiveRangeSearchRange: NSRange?
    }
    
    func _attributes(at location: Int, rangeInfo: RangeInfo) -> [NSAttributedString.Key: Any] {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> [NSAttributedString.Key: Any] in
            // Get attributes value using CoreFoundation function
            let value: CFDictionary
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                value = CFAttributedStringGetAttributesAndLongestEffectiveRange(_cfObject, location, CFRange(searchRange), cfRangePointer)
            } else {
                value = CFAttributedStringGetAttributes(_cfObject, location, cfRangePointer)
            }
            
            // Convert the value to [String : AnyObject]
            let dictionary = unsafeBitCast(value, to: NSDictionary.self)
            var results = [NSAttributedString.Key: Any]()
            for (key, value) in dictionary {
                guard let stringKey = (key as? NSString)?._swiftObject else {
                    continue
                }
                results[NSAttributedString.Key(stringKey)] = value
            }
            
            // Update effective range and return the results
            rangeInfo.rangePointer?.pointee.location = cfRangePointer.pointee.location
            rangeInfo.rangePointer?.pointee.length = cfRangePointer.pointee.length
            return results
        }
    }
    
    func _attribute(_ attrName: NSAttributedString.Key, atIndex location: Int, rangeInfo: RangeInfo) -> Any? {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> AnyObject? in
            // Get attribute value using CoreFoundation function
            let attribute: AnyObject?
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                attribute = CFAttributedStringGetAttributeAndLongestEffectiveRange(_cfObject, location, attrName.rawValue._cfObject, CFRange(searchRange), cfRangePointer)
            } else {
                attribute = CFAttributedStringGetAttribute(_cfObject, location, attrName.rawValue._cfObject, cfRangePointer)
            }
            
            // Update effective range and return the result
            rangeInfo.rangePointer?.pointee.location = cfRangePointer.pointee.location
            rangeInfo.rangePointer?.pointee.length = cfRangePointer.pointee.length
            return attribute
        }
    }
    
    func _enumerate(in enumerationRange: NSRange, reversed: Bool, using block: (Int, UnsafeMutablePointer<ObjCBool>) -> NSRange) {
        var attributeEnumerationRange = AttributeEnumerationRange(range: enumerationRange, reversed: reversed)
        while attributeEnumerationRange.hasMore {
            var stop: ObjCBool = false
            let effectiveRange = block(attributeEnumerationRange.currentIndex, &stop)
            attributeEnumerationRange.advance(step: effectiveRange.length)
            if stop.boolValue {
                break
            }
        }
    }
    
    func addAttributesToAttributeArray(attrs: [NSAttributedString.Key: Any]?) {
        guard _string.length > 0 else {
            return
        }
        
        let range = CFRange(location: 0, length: _string.length)
        var attributes: [String : Any] = [:]
        if let attrs = attrs {
            attrs.forEach { attributes[$0.rawValue] = $1 }
        }
        CFRunArrayInsert(_attributeArray, range, attributes._cfObject)
    }
}

extension NSAttributedString: _CFBridgeable {
    internal var _cfObject: CFAttributedString { return unsafeBitCast(self, to: CFAttributedString.self) }
}

extension NSAttributedString {

    public struct EnumerationOptions: OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        public static let reverse = EnumerationOptions(rawValue: 1 << 1)
        public static let longestEffectiveRangeNotRequired = EnumerationOptions(rawValue: 1 << 20)
    }

}


open class NSMutableAttributedString : NSAttributedString {
    
    open func replaceCharacters(in range: NSRange, with str: String) {
        CFAttributedStringReplaceString(_cfMutableObject, CFRange(range), str._cfObject)
    }
    
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        guard let attrs = attrs else {
            CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), nil, true)
            return
        }
        CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), attributesCFDictionary(from: attrs), true)
    }
    
    open var mutableString: NSMutableString {
        return _string as! NSMutableString
    }

    open func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
        CFAttributedStringSetAttribute(_cfMutableObject, CFRange(range), name.rawValue._cfObject, __SwiftValue.store(value))
    }

    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), attributesCFDictionary(from: attrs), false)
    }
    
    open func removeAttribute(_ name: NSAttributedString.Key, range: NSRange) {
        CFAttributedStringRemoveAttribute(_cfMutableObject, CFRange(range), name.rawValue._cfObject)
    }
    
    open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        CFAttributedStringReplaceAttributedString(_cfMutableObject, CFRange(range), attrString._cfObject)
    }
    
    open func insert(_ attrString: NSAttributedString, at loc: Int) {
        let insertRange = NSRange(location: loc, length: 0)
        replaceCharacters(in: insertRange, with: attrString)
    }
    
    open func append(_ attrString: NSAttributedString) {
        let appendRange = NSRange(location: length, length: 0)
        replaceCharacters(in: appendRange, with: attrString)
    }
    
    open func deleteCharacters(in range: NSRange) {
        // To delete a range of the attributed string, call CFAttributedStringReplaceString() with empty string and specified range
        let emptyString = ""._cfObject
        CFAttributedStringReplaceString(_cfMutableObject, CFRange(range), emptyString)
    }
    
    open func setAttributedString(_ attrString: NSAttributedString) {
        let fullStringRange = NSRange(location: 0, length: length)
        replaceCharacters(in: fullStringRange, with: attrString)
    }
    
    open func beginEditing() {
        CFAttributedStringBeginEditing(_cfMutableObject)
    }
    
    open func endEditing() {
        CFAttributedStringEndEditing(_cfMutableObject)
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return NSAttributedString(attributedString: self)
    }
    
    public override init(string: String) {
        super.init(string: string)
        _string = NSMutableString(string: string)
    }
    
    public override init(string: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) {
        super.init(string: string, attributes: attrs)
        _string = NSMutableString(string: string)
    }
    
    public override init(attributedString: NSAttributedString) {
        super.init(attributedString: attributedString)
        _string = NSMutableString(string: attributedString.string)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        let mutableAttributedString = NSMutableAttributedString(string: "")
        guard _NSReadMutableAttributedStringWithCoder(aDecoder, mutableAttributedString: mutableAttributedString) else {
            return nil
        }
        
        super.init(attributedString: mutableAttributedString)
        _string = NSMutableString(string: mutableAttributedString.string)
    }
    
}

extension NSMutableAttributedString {
    internal var _cfMutableObject: CFMutableAttributedString { return unsafeBitCast(self, to: CFMutableAttributedString.self) }
}

private extension NSMutableAttributedString {
    
    func attributesCFDictionary(from attrs: [NSAttributedString.Key: Any]) -> CFDictionary {
        var attributesDictionary = [String : Any]()
        for (key, value) in attrs {
            attributesDictionary[key.rawValue] = value
        }
        return attributesDictionary._cfObject
    }
}

// MARK: Coding

fileprivate let _allowedCodingClasses: [AnyClass] = [
    NSNumber.self,
    NSArray.self,
    NSDictionary.self,
    NSURL.self,
    NSString.self,
]

internal func _NSReadIntFromMutableAttributedStringCoding(_ data: NSData, _ startingOffset: Int) -> (value: Int, newOffset: Int)? {
    var multiplier = 1
    var offset = startingOffset
    let length = data.length
    
    var value = 0
    
    while offset < length {
        let i = Int(data.bytes.load(fromByteOffset: offset, as: UInt8.self))
        
        offset += 1
        
        let isLast = i < 128
        
        let intermediateValue = multiplier.multipliedReportingOverflow(by: isLast ? i : (i - 128))
        guard !intermediateValue.overflow else { return nil }
        
        let newValue = value.addingReportingOverflow(intermediateValue.partialValue)
        guard !newValue.overflow else { return nil }
        
        value = newValue.partialValue

        if isLast {
            return (value: value, newOffset: offset)
        }
        
        multiplier *= 128
    }
    
    return nil // Getting to the end of the stream indicates error, since we were still expecting more bytes
}

internal func _NSWriteIntToMutableAttributedStringCoding(_ i: Int, _ data: NSMutableData) {
    if i > 127 {
        let byte = UInt8(128 + i % 128);
        data.append(Data([byte]))
        _NSWriteIntToMutableAttributedStringCoding(i / 128, data)
    } else {
        data.append(Data([UInt8(i)]))
    }
}

internal func _NSReadMutableAttributedStringWithCoder(_ decoder: NSCoder, mutableAttributedString: NSMutableAttributedString) -> Bool {
    
    // NSAttributedString.Key is not currently bridging correctly every time we'd like it to.
    // Ensure we manually go through String in the meanwhile. SR-XXXX.
    func toAttributesDictionary(_ ns: NSDictionary) -> [NSAttributedString.Key: Any]? {
        if let bridged = __SwiftValue.fetch(ns) as? [String: Any] {
            return Dictionary(bridged.map { (NSAttributedString.Key($0.key), $0.value) }, uniquingKeysWith: { $1 })
        } else {
            return nil
        }
    }
    
    guard decoder.allowsKeyedCoding else { /* Unkeyed unarchiving is not supported. */ return false }
    
    let string = decoder.decodeObject(of: NSString.self, forKey: "NSString") ?? ""
    
    mutableAttributedString.replaceCharacters(in: NSMakeRange(0, 0), with: string as String)
    
    guard string.length > 0 else { return true }
    
    var allowed = _allowedCodingClasses
    for aClass in decoder.allowedClasses ?? [] {
        if !allowed.contains(where: { $0 === aClass }) {
            allowed.append(aClass)
        }
    }
    
    let attributes = decoder.decodeObject(of: allowed, forKey: "NSAttributes")
    // If this is present, 'attributes' should be an array; otherwise, a dictionary:
    let attrData = decoder.decodeObject(of: NSData.self, forKey: "NSAttributeInfo")
    if attrData == nil, let attributesNS = attributes as? NSDictionary, let attributes = toAttributesDictionary(attributesNS) {
        mutableAttributedString.setAttributes(attributes, range: NSMakeRange(0, string.length))
        return true
    } else if let attrData = attrData, let attributesNS = attributes as? [NSDictionary] {
        let attributes = attributesNS.compactMap { toAttributesDictionary($0) }
        guard attributes.count == attributesNS.count else { return false }
        
        var loc = 0
        var offset = 0
        let length = string.length
        while loc < length {
            var rangeLen = 0, arraySlot = 0
            guard let intResult1 = _NSReadIntFromMutableAttributedStringCoding(attrData, offset) else { return false }
            rangeLen = intResult1.value
            offset = intResult1.newOffset
            
            guard let intResult2 = _NSReadIntFromMutableAttributedStringCoding(attrData, offset) else { return false }
            arraySlot = intResult2.value
            offset = intResult2.newOffset
            
            guard arraySlot < attributes.count else { return false }
            mutableAttributedString.setAttributes(attributes[arraySlot], range: NSMakeRange(loc, rangeLen))
            
            loc += rangeLen
        }
        
        return true
    }
    
    return false
}
