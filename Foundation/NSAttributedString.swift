// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

private struct _NSAttributedStringAttribute {
    let range: Range<Int>
    let name: String
    let value: NSObject
}

extension _NSAttributedStringAttribute : Equatable {
}

private func ==(lhs: _NSAttributedStringAttribute, rhs: _NSAttributedStringAttribute) -> Bool {
    return lhs.range == rhs.range &&
        lhs.name == rhs.name &&
        lhs.value == rhs.value
}

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
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return NSAttributedString(attributedString: self)
    }

    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        return NSMutableAttributedString(attributedString: self)
    }
    
    private var _string: String
    public var string: String {
        return _string
    }
    
    public func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        let attributesAtIndex = _attributes?.filter({
            $0.range.contains(location)
        })

        var result = [String: AnyObject]()
        attributesAtIndex?.forEach {
            result[$0.name] = $0.value
        }
        
        return result
    }

    public var length: Int {
        return string.length
    }
    
    private var _attributes: [_NSAttributedStringAttribute]?
    public func attribute(attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer) -> AnyObject? {
        let attributeWithNameAtIndex = _attributes?.filter({
            $0.name == attrName && $0.range.contains(location)
        }).last
        
        if let attributeWithNameAtIndex = attributeWithNameAtIndex {
            range.memory = NSRange(attributeWithNameAtIndex.range)
        }
        
        return attributeWithNameAtIndex?.value
    }
    
    public func attributedSubstringFromRange(range: NSRange) -> NSAttributedString {
        let effectiveAttributes = 
        let attr = _attributes.map {
            
        }
        
    }
    
    public func attributesAtIndex(location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> [String : AnyObject] { NSUnimplemented() }
    public func attribute(attrName: String, atIndex location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> AnyObject? { NSUnimplemented() }
    
    public func isEqualToAttributedString(other: NSAttributedString) -> Bool { NSUnimplemented() }
    
    public init(string str: String) {
        _string = str
    }
    
    public init(string str: String, attributes attrs: [String : AnyObject]?) {
        _string = str
        
        let len = str.length
        _attributes = attrs?.map { key, value in
            _NSAttributedStringAttribute(range: Range(start: 0, end: len), name: key, value: value as! NSObject)
        }
    }
    public init(attributedString attrStr: NSAttributedString) {
        _string = attrStr._string
        _attributes = attrStr._attributes
    }
    
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

