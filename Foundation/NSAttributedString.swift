// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public struct NSAttributedStringKey : RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var hashValue: Int {
        return rawValue.hashValue
    }
}

open class NSAttributedString: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    fileprivate var _string: NSString
    fileprivate var _attributeArray: CFRunArrayRef
    
    public required init?(coder aDecoder: NSCoder) {
        
        func decodeAttributes(_ value: NSDictionary?) -> [NSAttributedStringKey: Any]? {
            guard let value = value else { return nil }
            return Dictionary(uniqueKeysWithValues: value.map({ (NSAttributedStringKey($0.key as! String), $0.value) }))
        }
        
        func iterateInfoArray(_ info: inout Data, from byteIdx: inout Int) -> (length: Int, index: Int) {
            var length = 0
            var index = 0
            while info[byteIdx] > 127 {
                length = length << 7 + Int(info[byteIdx])
                byteIdx += 1
            }
            length = length << 7 + Int(info[byteIdx])
            byteIdx += 1
            while info[byteIdx] > 127 {
                index = index << 7 + Int(info[byteIdx])
                byteIdx += 1
            }
            index = index << 7 + Int(info[byteIdx])
            byteIdx += 1
            return (length, index)
        }
        
        if aDecoder.allowsKeyedCoding {
            _string = aDecoder.decodeObject(of: NSString.self, forKey: "NSString") ?? ""
        } else {
            _string = aDecoder.decodeObject() as! NSString
        }
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        super.init()
        if _string.length == 0 { return }
        
        if aDecoder.allowsKeyedCoding {
            if aDecoder.containsValue(forKey: "NSAttributeInfo"),
                var info = aDecoder.decodeObject(of: NSData.self, forKey: "NSAttributeInfo")?._swiftObject,
                let attrsArrayD = aDecoder.decodeObject(of: [NSArray.self, NSDictionary.self], forKey: "NSAttributes"),
                let attrsArray = attrsArrayD as? [NSDictionary] {
                var offset = 0
                var byteIdx = 0
                while byteIdx < info.count {
                    let (rangeLength, index) = iterateInfoArray(&info, from: &byteIdx)
                    let range = NSRange(location: offset, length: rangeLength)
                    let attrs = attrsArray[index]
                    CFRunArrayInsert(_attributeArray, CFRange(range), attrs._cfObject)
                    offset += rangeLength
                }
            } else {
                let attrs = aDecoder.decodeObject(of: NSDictionary.self, forKey: "NSAttributes")
                addAttributesToAttributeArray(attrs: decodeAttributes(attrs))
            }
        } else {
            var position = 0
            while position < length {
                var rangeLength: UInt32 = 0
                aDecoder.decodeValue(ofObjCType: String(_NSSimpleObjCType.UInt), at: &rangeLength)
                let range = NSRange(location: position, length: Int(rangeLength))
                let attrs = aDecoder.decodeObject() as! NSDictionary
                CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), attrs._cfObject, false)
                position += Int(rangeLength)
            }
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        
        func appendUInt(_ value: UInt, data: inout Data) {
            var value = value
            while value >= 128 {
                let byte = UInt8(value & 0x7f + 128)
                data.append(byte)
                value /= 128
            }
            data.append(UInt8(value))
        }
        
        func encodableAttributes(_ value: [NSAttributedStringKey: Any]) -> NSMutableDictionary {
            return Dictionary(uniqueKeysWithValues: value.map({ ($0.key.rawValue, $0.value) }))
                ._nsObject.mutableCopy() as! NSMutableDictionary
        }
        
        // TODO: Implement thread lock
        if aCoder.allowsKeyedCoding {
            aCoder.encode(_string, forKey: "NSString")
            let length =  _string.length
            guard length > 0 else { return }
            var range = NSRange(location: NSNotFound, length: 0)
            let attrs = encodableAttributes(attributes(at: 0, effectiveRange: &range))
            if range.length == length {
                aCoder.encode(attrs, forKey: "NSAttributes")
            } else {
                var attrsArray = [Any]()
                var info = Data()
                var position = 0
                var counter: UInt = 0
                while position < length {
                    attrsArray.append(encodableAttributes(attributes(at: position, effectiveRange: &range)))
                    appendUInt(UInt(range.length), data: &info)
                    appendUInt(counter, data: &info)
                    counter += 1
                    position = range.upperBound
                }
                aCoder.encode(attrsArray._nsObject, forKey: "NSAttributes")
                aCoder.encode(info._nsObject.mutableCopy(), forKey: "NSAttributeInfo")
            }
        } else {
            aCoder.encode(_string)
            var range = NSRange(location: NSNotFound, length: 0)
            var position: UInt32 = 0
            while position < length {
                let attrs = attributes(at: Int(position), effectiveRange: &range)
                position = UInt32(range.upperBound)
                aCoder.encodeValue(ofObjCType: String(_NSSimpleObjCType.UInt), at: &position)
                aCoder.encode(encodableAttributes(attrs))
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
    open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
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
    open func attribute(_ attrName: NSAttributedStringKey, at location: Int, effectiveRange range: NSRangePointer?) -> Any? {
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
    open func attributes(at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> [NSAttributedStringKey : Any] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attributes(at: location, rangeInfo: rangeInfo)
    }

    /// Returns the value for the attribute with a given name of the character at a given index, and by reference the range over which the attribute applies.
    open func attribute(_ attrName: NSAttributedStringKey, at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> Any? {
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
    public init(string: String, attributes attrs: [NSAttributedStringKey : Any]? = nil) {
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
    open func enumerateAttributes(in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: ([NSAttributedStringKey : Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _enumerate(in: enumerationRange, reversed: opts.contains(.reverse)) { currentIndex, stop in
            var attributesEffectiveRange = NSRange(location: NSNotFound, length: 0)
            let attributesInRange: [NSAttributedStringKey : Any]
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
    open func enumerateAttribute(_ attrName: NSAttributedStringKey, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
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
    
    func _attributes(at location: Int, rangeInfo: RangeInfo) -> [NSAttributedStringKey : Any] {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> [NSAttributedStringKey : Any] in
            // Get attributes value using CoreFoundation function
            let value: CFDictionary
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                value = CFAttributedStringGetAttributesAndLongestEffectiveRange(_cfObject, location, CFRange(searchRange), cfRangePointer)
            } else {
                value = CFAttributedStringGetAttributes(_cfObject, location, cfRangePointer)
            }
            
            // Convert the value to [String : AnyObject]
            let dictionary = unsafeBitCast(value, to: NSDictionary.self)
            var results = [NSAttributedStringKey : Any]()
            for (key, value) in dictionary {
                guard let stringKey = (key as? NSString)?._swiftObject else {
                    continue
                }
                results[NSAttributedStringKey(stringKey)] = value
            }
            
            // Update effective range and return the results
            rangeInfo.rangePointer?.pointee.location = cfRangePointer.pointee.location
            rangeInfo.rangePointer?.pointee.length = cfRangePointer.pointee.length
            return results
        }
    }
    
    func _attribute(_ attrName: NSAttributedStringKey, atIndex location: Int, rangeInfo: RangeInfo) -> Any? {
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
    
    func addAttributesToAttributeArray(attrs: [NSAttributedStringKey : Any]?) {
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
    internal var _cfMutableObject: CFMutableAttributedString { return unsafeBitCast(self, to: CFMutableAttributedString.self) }
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
    
    open func setAttributes(_ attrs: [NSAttributedStringKey : Any]?, range: NSRange) {
        guard let attrs = attrs else {
            CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), nil, true)
            return
        }
        CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), attributesCFDictionary(from: attrs), true)
    }
    
    open var mutableString: NSMutableString {
        return _string as! NSMutableString
    }

    open func addAttribute(_ name: NSAttributedStringKey, value: Any, range: NSRange) {
        CFAttributedStringSetAttribute(_cfMutableObject, CFRange(range), name.rawValue._cfObject, _SwiftValue.store(value))
    }

    open func addAttributes(_ attrs: [NSAttributedStringKey : Any], range: NSRange) {
        CFAttributedStringSetAttributes(_cfMutableObject, CFRange(range), attributesCFDictionary(from: attrs), false)
    }
    
    open func removeAttribute(_ name: NSAttributedStringKey, range: NSRange) {
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
    
    public override init(string: String, attributes attrs: [NSAttributedStringKey : Any]? = nil) {
        super.init(string: string, attributes: attrs)
        _string = NSMutableString(string: string)
    }
    
    public override init(attributedString: NSAttributedString) {
        super.init(attributedString: attributedString)
        _string = NSMutableString(string: attributedString.string)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

private extension NSMutableAttributedString {
    
    func attributesCFDictionary(from attrs: [NSAttributedStringKey : Any]) -> CFDictionary {
        var attributesDictionary = [String : Any]()
        for (key, value) in attrs {
            attributesDictionary[key.rawValue] = value
        }
        return attributesDictionary._cfObject
    }
}
