// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class NSAttributedString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    private let _string: String
    private let _attributeArray: CFRunArrayRef
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public var string: String {
        return _string
    }
    
    public func attributesAtIndex(_ location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] { NSUnimplemented() }

    public var length: Int {
        return _string.length
    }
    
    public func attribute(_ attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer) -> AnyObject? { NSUnimplemented() }
    public func attributedSubstringFromRange(_ range: NSRange) -> NSAttributedString { NSUnimplemented() }
    
    public func attributesAtIndex(_ location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> [String : AnyObject] { NSUnimplemented() }
    public func attribute(_ attrName: String, atIndex location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> AnyObject? { NSUnimplemented() }
    
    public func isEqualToAttributedString(_ other: NSAttributedString) -> Bool { NSUnimplemented() }
    
    public init(string str: String) {
        _string = str
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
    }
    
    public init(string str: String, attributes attrs: [String : AnyObject]?) {
        _string = str
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        let length = _string.length
        if (length > 0) {
            CFRunArrayInsert(_attributeArray, CFRange(location: 0, length: length), attrs?._cfObject)
        }
    }
    
    public init(attributedString attrStr: NSAttributedString) { NSUnimplemented() }
    
    public func enumerateAttributesInRange(_ enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: ([String : AnyObject], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateAttribute(_ attrName: String, inRange enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: (AnyObject?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
}

public struct NSAttributedStringEnumerationOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let Reverse = NSAttributedStringEnumerationOptions(rawValue: 1 << 1)
    public static let LongestEffectiveRangeNotRequired = NSAttributedStringEnumerationOptions(rawValue: 1 << 20)
}



public class NSMutableAttributedString : NSAttributedString {
    
    public func replaceCharactersInRange(_ range: NSRange, withString str: String) { NSUnimplemented() }
    public func setAttributes(_ attrs: [String : AnyObject]?, range: NSRange) { NSUnimplemented() }

    
    public var mutableString: NSMutableString { NSUnimplemented() }
    
    public func addAttribute(_ name: String, value: AnyObject, range: NSRange) { NSUnimplemented() }
    public func addAttributes(_ attrs: [String : AnyObject], range: NSRange) { NSUnimplemented() }
    public func removeAttribute(_ name: String, range: NSRange) { NSUnimplemented() }
    
    public func replaceCharactersInRange(_ range: NSRange, withAttributedString attrString: NSAttributedString) { NSUnimplemented() }
    public func insertAttributedString(_ attrString: NSAttributedString, atIndex loc: Int) { NSUnimplemented() }
    public func appendAttributedString(_ attrString: NSAttributedString) { NSUnimplemented() }
    public func deleteCharactersInRange(_ range: NSRange) { NSUnimplemented() }
    public func setAttributedString(_ attrString: NSAttributedString) { NSUnimplemented() }
    
    public func beginEditing() { NSUnimplemented() }
    public func endEditing() { NSUnimplemented() }
}

