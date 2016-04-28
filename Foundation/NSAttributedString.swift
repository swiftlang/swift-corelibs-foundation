// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class NSAttributedString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    private let _string: NSString
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
        return _string._swiftObject
    }
    
    public func attributesAtIndex(_ location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(&cfRange) { (rangePointer: UnsafeMutablePointer<CFRange>) -> [String : AnyObject] in
            // Get attributes value using CoreFoundation function
            let value = CFAttributedStringGetAttributes(_cfObject, location, rangePointer)
            
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
            range.pointee.location = hasAttrs ? rangePointer.pointee.location : NSNotFound
            range.pointee.length = hasAttrs ? rangePointer.pointee.length : 0
            
            return results
        }
    }

    public var length: Int {
        return CFAttributedStringGetLength(_cfObject)
    }
    
    public func attribute(_ attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer) -> AnyObject? {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(&cfRange) { (rangePointer: UnsafeMutablePointer<CFRange>) -> AnyObject? in
            // Get attribute value using CoreFoundation function
            let attribute = CFAttributedStringGetAttribute(_cfObject, location, attrName._cfObject, rangePointer)
            
            // Update effective range and return the result
            if let attribute = attribute {
                range.pointee.location = rangePointer.pointee.location
                range.pointee.length = rangePointer.pointee.length
                return attribute
            } else {
                range.pointee.location = NSNotFound
                range.pointee.length = 0
                return nil
            }
        }
    }
    
    public func attributedSubstringFromRange(_ range: NSRange) -> NSAttributedString { NSUnimplemented() }
    
    public func attributesAtIndex(_ location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> [String : AnyObject] { NSUnimplemented() }
    public func attribute(_ attrName: String, atIndex location: Int, longestEffectiveRange range: NSRangePointer, inRange rangeLimit: NSRange) -> AnyObject? { NSUnimplemented() }
    
    public func isEqualToAttributedString(_ other: NSAttributedString) -> Bool { NSUnimplemented() }
    
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
    
    public init(attributedString attrStr: NSAttributedString) { NSUnimplemented() }
    
    private func addAttributesToAttributeArray(attrs: [String : AnyObject]?) {
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

    public func enumerateAttributesInRange(_ enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: ([String : AnyObject], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateAttribute(_ attrName: String, inRange enumerationRange: NSRange, options opts: NSAttributedStringEnumerationOptions, usingBlock block: (AnyObject?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
}

extension NSAttributedString: _CFBridgable {
    internal var _cfObject: CFAttributedString { return unsafeBitCast(self, to: CFAttributedString.self) }
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

