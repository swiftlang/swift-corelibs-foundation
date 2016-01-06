// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSAttributedString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public var string: String { NSUnimplemented() }
    public func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] { NSUnimplemented() }

    public var length: Int { NSUnimplemented() }
    public func attribute(attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer) -> AnyObject? { NSUnimplemented() }
    public func attributedSubstringFromRange(range: NSRange) -> NSAttributedString { NSUnimplemented() }
    
    public func attributesAtIndex(location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> [String : AnyObject] { NSUnimplemented() }
    public func attribute(attrName: String, atIndex location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> AnyObject? { NSUnimplemented() }
    
    public func isEqualToAttributedString(other: NSAttributedString) -> Bool { NSUnimplemented() }
    
    public init(string str: String) { NSUnimplemented() }
    public init(string str: String, attributes attrs: [String : AnyObject]?) { NSUnimplemented() }
    public init(attributedString attrStr: NSAttributedString) { NSUnimplemented() }
    
    public func enumerateAttributesInRange(enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: ([String : AnyObject], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateAttribute(attrName: String, inRange enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: (AnyObject?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
}

public struct NSAttributedStringEnumerationOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let Reverse = NSAttributedStringEnumerationOptions(rawValue: 1 << 1)
    public static let LongestEffectiveRangeNotRequired = NSAttributedStringEnumerationOptions(rawValue: 1 << 20)
}



public class NSMutableAttributedString : NSAttributedString {
    
    public func replaceCharactersInRange(range: NSRange, withString str: String) { NSUnimplemented() }
    public func setAttributes(attrs: [String : AnyObject]?, range: NSRange) { NSUnimplemented() }

    
    public var mutableString: NSMutableString { NSUnimplemented() }
    
    public func addAttribute(name: String, value: AnyObject, range: NSRange) { NSUnimplemented() }
    public func addAttributes(attrs: [String : AnyObject], range: NSRange) { NSUnimplemented() }
    public func removeAttribute(name: String, range: NSRange) { NSUnimplemented() }
    
    public func replaceCharactersInRange(range: NSRange, withAttributedString attrString: NSAttributedString) { NSUnimplemented() }
    public func insertAttributedString(attrString: NSAttributedString, atIndex loc: Int) { NSUnimplemented() }
    public func appendAttributedString(attrString: NSAttributedString) { NSUnimplemented() }
    public func deleteCharactersInRange(range: NSRange) { NSUnimplemented() }
    public func setAttributedString(attrString: NSAttributedString) { NSUnimplemented() }
    
    public func beginEditing() { NSUnimplemented() }
    public func endEditing() { NSUnimplemented() }
}

