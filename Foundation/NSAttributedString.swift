// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class AttributedString: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    fileprivate var _string: NSString
    fileprivate var _attributeArray: CFRunArrayRef
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopy(with: nil)
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }
    
    public var string: String {
        return _string._swiftObject
    }
    
    public func attributesAtIndex(_ location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attributesAtIndex(location, rangeInfo: rangeInfo)
    }

    public var length: Int {
        return CFAttributedStringGetLength(_cfObject)
    }
    
    public func attribute(_ attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer) -> AnyObject? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }
    
    public func attributedSubstringFromRange(_ range: NSRange) -> AttributedString { NSUnimplemented() }
    
    public func attributesAtIndex(_ location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> [String : AnyObject] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attributesAtIndex(location, rangeInfo: rangeInfo)
    }
    
    public func attribute(_ attrName: String, atIndex location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> AnyObject? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }
    
    public func isEqualToAttributedString(_ other: AttributedString) -> Bool { NSUnimplemented() }
    
    public init(string str: String) {
        _string = str._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        super.init()
        addAttributesToAttributeArray(attrs: nil)
    }
    
    public init(string str: String, attributes attrs: [String : AnyObject]?) {
        _string = str._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        super.init()
        addAttributesToAttributeArray(attrs: attrs)
    }
    
    public init(attributedString attrStr: AttributedString) { NSUnimplemented() }

    public func enumerateAttributesInRange(_ enumerationRange: NSRange, options opts: EnumerationOptions, usingBlock block: ([String : AnyObject], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateAttribute(_ attrName: String, inRange enumerationRange: NSRange, options opts: EnumerationOptions, usingBlock block: (AnyObject?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    
}

private extension AttributedString {
    struct RangeInfo {
        let rangePointer: NSRangePointer
        let shouldFetchLongestEffectiveRange: Bool
        let longestEffectiveRangeSearchRange: NSRange?
    }
    
    func _attributesAtIndex(_ location: Int, rangeInfo: RangeInfo) -> [String : AnyObject] {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> [String : AnyObject] in
            // Get attributes value using CoreFoundation function
            let value: CFDictionary
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                value = CFAttributedStringGetAttributesAndLongestEffectiveRange(_cfObject, location, CFRange(searchRange), cfRangePointer)
            } else {
                value = CFAttributedStringGetAttributes(_cfObject, location, cfRangePointer)
            }
            
            // Convert the value to [String : AnyObject]
            let dictionary = unsafeBitCast(value, to: NSDictionary.self)
            var results = [String : AnyObject]()
            for (key, value) in dictionary {
                guard let stringKey = (key as? NSString)?._swiftObject else {
                    continue
                }
                results[stringKey] = value
            }
            
            // Update effective range
            let hasAttrs = results.count > 0
            rangeInfo.rangePointer.pointee.location = hasAttrs ? cfRangePointer.pointee.location : NSNotFound
            rangeInfo.rangePointer.pointee.length = hasAttrs ? cfRangePointer.pointee.length : 0
            
            return results
        }
    }
    
    func _attribute(_ attrName: String, atIndex location: Int, rangeInfo: RangeInfo) -> AnyObject? {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> AnyObject? in
            // Get attribute value using CoreFoundation function
            let attribute: AnyObject?
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                attribute = CFAttributedStringGetAttributeAndLongestEffectiveRange(_cfObject, location, attrName._cfObject, CFRange(searchRange), cfRangePointer)
            } else {
                attribute = CFAttributedStringGetAttribute(_cfObject, location, attrName._cfObject, cfRangePointer)
            }
            
            // Update effective range and return the result
            if let attribute = attribute {
                rangeInfo.rangePointer.pointee.location = cfRangePointer.pointee.location
                rangeInfo.rangePointer.pointee.length = cfRangePointer.pointee.length
                return attribute
            } else {
                rangeInfo.rangePointer.pointee.location = NSNotFound
                rangeInfo.rangePointer.pointee.length = 0
                return nil
            }
        }
    }
    
    func addAttributesToAttributeArray(attrs: [String : AnyObject]?) {
        guard _string.length > 0 else {
            return
        }
        
        let range = CFRange(location: 0, length: _string.length)
        if let attrs = attrs {
            CFRunArrayInsert(_attributeArray, range, attrs._cfObject)
        } else {
            let emptyAttrs = [String : AnyObject]()
            CFRunArrayInsert(_attributeArray, range, emptyAttrs._cfObject)
        }
    }
}

extension AttributedString: _CFBridgable {
    internal var _cfObject: CFAttributedString { return unsafeBitCast(self, to: CFAttributedString.self) }
}

extension AttributedString {

    public struct EnumerationOptions: OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        public static let Reverse = EnumerationOptions(rawValue: 1 << 1)
        public static let LongestEffectiveRangeNotRequired = EnumerationOptions(rawValue: 1 << 20)
    }

}


public class NSMutableAttributedString : AttributedString {
    
    public func replaceCharactersInRange(_ range: NSRange, withString str: String) { NSUnimplemented() }
    public func setAttributes(_ attrs: [String : AnyObject]?, range: NSRange) { NSUnimplemented() }
    
    public var mutableString: NSMutableString {
        return _string as! NSMutableString
    }
    
    public func addAttribute(_ name: String, value: AnyObject, range: NSRange) {
        CFAttributedStringSetAttribute(_cfMutableObject, CFRange(range), name._cfObject, value)
    }
    
    public func addAttributes(_ attrs: [String : AnyObject], range: NSRange) { NSUnimplemented() }
    
    public func removeAttribute(_ name: String, range: NSRange) { NSUnimplemented() }
    
    public func replaceCharactersInRange(_ range: NSRange, withAttributedString attrString: AttributedString) { NSUnimplemented() }
    public func insertAttributedString(_ attrString: AttributedString, atIndex loc: Int) { NSUnimplemented() }
    public func appendAttributedString(_ attrString: AttributedString) { NSUnimplemented() }
    public func deleteCharactersInRange(_ range: NSRange) { NSUnimplemented() }
    public func setAttributedString(_ attrString: AttributedString) { NSUnimplemented() }
    
    public func beginEditing() { NSUnimplemented() }
    public func endEditing() { NSUnimplemented() }
    
    public override init(string str: String) {
        super.init(string: str)
        _string = NSMutableString(string: str)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
}

extension NSMutableAttributedString {
    internal var _cfMutableObject: CFMutableAttributedString { return unsafeBitCast(self, to: CFMutableAttributedString.self) }
}
