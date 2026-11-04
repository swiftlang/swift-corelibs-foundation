// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension Range<AttributedString.Index> {
    init(_ nsRange: NSRange, in attrStr: AttributedString) {
        guard let start = attrStr.utf16.index(attrStr.utf16.startIndex, offsetBy: nsRange.location, limitedBy: attrStr.utf16.endIndex),
              let end = attrStr.utf16.index(start, offsetBy: nsRange.length, limitedBy: attrStr.utf16.endIndex) else {
            preconditionFailure("Range {\(nsRange.location), \(nsRange.length)} is out of bounds {0, \(attrStr.utf16.count)")
        }
        self = start ..< end
    }
}

extension NSAttributedString {
    public struct Key: RawRepresentable, Equatable, Hashable, Sendable {
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

@available(*, unavailable)
extension NSAttributedString : @unchecked Sendable { }

extension AttributeScopes {
    fileprivate struct CorelibsFoundationAttributes : AttributeScope {
        let nsAttributes: NSAttributesAttributedStringKey

        enum NSAttributesAttributedStringKey: AttributedStringKey {
            static let name = "NSAttributes"
            typealias Value = [NSAttributedString.Key : _AttributeValue]
        }
    }
}

// Unsafely wrap an NSObject in an @unchecked Sendable box. This is safe because it will only be used in a non-sendable NSAttributedString. The wrapped AttributedString (which is Sendable) can never escape that non-sendable box
private struct _AttributeValue: @unchecked Sendable, Hashable {
    let object: NSObject

    init(value: Any) {
        object = __SwiftValue.store(value)
    }

    var value: Any {
        __SwiftValue.fetch(nonOptional: object)
    }
}

extension AttributeDynamicLookup {
    fileprivate subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.CorelibsFoundationAttributes, T>) -> T {
        return self[T.self]
    }
}

open class NSAttributedString: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    var contents: AttributedString

    private init(contents: AttributedString) {
        self.contents = contents
    }

    public required init?(coder aDecoder: NSCoder) {
        let mutableAttributedString = NSMutableAttributedString(string: "")
        guard _NSReadMutableAttributedStringWithCoder(aDecoder, mutableAttributedString: mutableAttributedString) else {
            return nil
        }
        
        contents = mutableAttributedString.contents
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
        return String(contents.characters)
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
        return contents.utf16.count
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
        let range = Range(range, in: contents)
        let newContents = AttributedString(contents[range])
        return NSAttributedString(contents: newContents)
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
        return self.contents == other.contents
    }

    /// Returns an NSAttributedString object initialized with the characters of a given string and no attribute information.
    public init(string: String) {
        contents = AttributedString(string)
        super.init()
    }

    /// Returns an NSAttributedString object initialized with a given string and attributes.
    public init(string: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) {
        if let attrs {
            contents = AttributedString(string, attributes: AttributeContainer.nsAttributes(attrs.mapValues({
                _AttributeValue(value: $0)
            })))
        } else {
            contents = AttributedString(string)
        }
        super.init()
    }

    /// Returns an NSAttributedString object initialized with the characters and attributes of another given attributed string.
    public init(attributedString: NSAttributedString) {
        self.contents = attributedString.contents
    }

    /// Executes the block for each attribute in the range.
    open func enumerateAttributes(in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: ([NSAttributedString.Key: Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _enumerate(in: enumerationRange, reversed: opts.contains(.reverse)) { currentIndex, rangeLimit, stop in
            var attributesEffectiveRange = NSRange(location: NSNotFound, length: 0)
            let attributesInRange: [NSAttributedString.Key: Any]
            if opts.contains(.longestEffectiveRangeNotRequired) {
                attributesInRange = attributes(at: currentIndex, effectiveRange: &attributesEffectiveRange)
            } else {
                attributesInRange = attributes(at: currentIndex, longestEffectiveRange: &attributesEffectiveRange, in: rangeLimit)
            }
            
            var shouldStop: ObjCBool = false
            block(attributesInRange, attributesEffectiveRange, &shouldStop)
            stop.pointee = shouldStop
            
            return attributesEffectiveRange
        }
    }

    /// Executes the block for the specified attribute run in the specified range.
    open func enumerateAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _enumerate(in: enumerationRange, reversed: opts.contains(.reverse)) { currentIndex, rangeLimit, stop in
            var attributeEffectiveRange = NSRange(location: NSNotFound, length: 0)
            let attributeInRange: Any?
            if opts.contains(.longestEffectiveRangeNotRequired) {
                attributeInRange = attribute(attrName, at: currentIndex, effectiveRange: &attributeEffectiveRange)
            } else {
                attributeInRange = attribute(attrName, at: currentIndex, longestEffectiveRange: &attributeEffectiveRange, in: rangeLimit)
            }
            
            var shouldStop: ObjCBool = false
            block(attributeInRange, attributeEffectiveRange, &shouldStop)
            stop.pointee = shouldStop
            
            return attributeEffectiveRange
        }
    }
    
    public override var description: String {
        let string = self.string
        var description = ""
        var lastUpperBound = string.startIndex

        enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { dict, range, stop in
            var attrs = "{\n"
            let keys = dict.keys.map({ $0.rawValue }).sorted()
            for key in keys {
                attrs += "    \(key) = \(dict[NSAttributedString.Key(rawValue: key)]!);\n"
            }
            attrs += "}"
            
            let stringRange = Range(NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound), in: contents)
            description += String(contents[stringRange].characters)

            description += attrs
        }
        
        return description
    }

}

private extension NSAttributedString {
    
    struct AttributeEnumerationRange {
        var startIndex: Int
        var endIndex: Int
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
        
        mutating func advance(range: NSRange, oldLength: Int, newLength: Int) {
            if reversed {
                startIndex = min(startIndex, newLength - 1)
                currentIndex = range.lowerBound - 1
            } else {
                endIndex -= oldLength - newLength
                currentIndex = range.upperBound - oldLength + newLength
            }
        }
        
        var range: NSRange {
            if reversed {
                return NSRange(location: endIndex, length: startIndex - endIndex + 1)
            }
            else {
                return NSRange(location: startIndex, length: endIndex - startIndex + 1)
            }
        }
    }
    
    struct RangeInfo {
        let rangePointer: NSRangePointer?
        let shouldFetchLongestEffectiveRange: Bool
        let longestEffectiveRangeSearchRange: NSRange?
    }
    
    func _attributes(at location: Int, rangeInfo: RangeInfo) -> [NSAttributedString.Key: Any] {
        guard let idx = contents.utf16.index(contents.utf16.startIndex, offsetBy: location, limitedBy: contents.utf16.endIndex) else {
            preconditionFailure("Index \(location) is out of bounds")
        }
        let run = contents.runs[idx]
        if let ptr = rangeInfo.rangePointer {
            ptr.pointee.location = contents.utf16.distance(from: contents.utf16.startIndex, to: run.range.lowerBound)
            ptr.pointee.length = contents.utf16.distance(from: run.range.lowerBound, to: run.range.upperBound)

            if let rangeLimit = rangeInfo.longestEffectiveRangeSearchRange {
                ptr.pointee = ptr.pointee.intersection(rangeLimit)!
            }
        }
        guard let attrs = run.nsAttributes else { return [:] }
        return attrs.mapValues(\.value)
    }
    
    func _attribute(_ attrName: NSAttributedString.Key, atIndex location: Int, rangeInfo: RangeInfo) -> Any? {
        guard let idx = contents.utf16.index(contents.utf16.startIndex, offsetBy: location, limitedBy: contents.utf16.endIndex) else {
            preconditionFailure("Index \(location) is out of bounds")
        }
        let run = contents.runs[idx]
        let value = run.nsAttributes?[attrName]
        if let ptr = rangeInfo.rangePointer {
            if rangeInfo.shouldFetchLongestEffectiveRange {
                let searchRange = Range(rangeInfo.longestEffectiveRangeSearchRange!, in: contents)
                let startIdx = contents[searchRange.lowerBound ..< run.range.lowerBound].runs.last(where: {
                    $0.nsAttributes?[attrName] != value
                })?.range.upperBound ?? searchRange.lowerBound
                let endIdx = contents[run.range.upperBound ..< searchRange.upperBound].runs.first(where: {
                    $0.nsAttributes?[attrName] != value
                })?.range.lowerBound ?? searchRange.upperBound
                let clippedStart = Swift.max(searchRange.lowerBound, startIdx)
                let clippedEnd = Swift.min(searchRange.upperBound, endIdx)
                ptr.pointee.location = contents.utf16.distance(from: contents.utf16.startIndex, to: clippedStart)
                ptr.pointee.length = contents.utf16.distance(from: clippedStart, to: clippedEnd)
            } else {
                ptr.pointee.location = contents.utf16.distance(from: contents.utf16.startIndex, to: run.range.lowerBound)
                ptr.pointee.length = contents.utf16.distance(from: run.range.lowerBound, to: run.range.upperBound)
            }
        }
        return value?.value
    }
    
    func _enumerate(in enumerationRange: NSRange, reversed: Bool, using block: (Int, NSRange, UnsafeMutablePointer<ObjCBool>) -> NSRange) {
        var attributeEnumerationRange = AttributeEnumerationRange(range: enumerationRange, reversed: reversed)
        while attributeEnumerationRange.hasMore {
            var stop: ObjCBool = false
            let oldLength = self.length
            let effectiveRange = block(attributeEnumerationRange.currentIndex, attributeEnumerationRange.range, &stop)
            attributeEnumerationRange.advance(range: effectiveRange, oldLength: oldLength, newLength: self.length)
            if stop.boolValue {
                break
            }
        }
    }
}

extension NSAttributedString {

    public struct EnumerationOptions: OptionSet, Sendable {
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
        contents.characters.replaceSubrange(Range(range, in: contents), with: str)
    }
    
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        let range = Range(range, in: contents)
        if let attrs, !attrs.isEmpty {
            contents[range].nsAttributes = attrs.mapValues { _AttributeValue(value: $0) }
        } else {
            contents[range].nsAttributes = nil
        }
    }
    
    open var mutableString: NSMutableString {
        // Note: this does not provide a reference to the underlying storage that can be mutated in-place like on Darwin
        // This has historically not worked on non-Darwin, instead we make a copy
        return (String(contents.characters) as NSString).mutableCopy() as! NSMutableString
    }

    open func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
        for run in contents[Range(range, in: contents)].runs {
            var container = run.nsAttributes ?? [:]
            container[name] = _AttributeValue(value: value)
            contents[run.range].nsAttributes = container
        }
    }

    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        for run in contents[Range(range, in: contents)].runs {
            var container = run.nsAttributes ?? [:]
            for (key, value) in attrs {
                container[key] = _AttributeValue(value: value)
            }
            contents[run.range].nsAttributes = container
        }
    }
    
    open func removeAttribute(_ name: NSAttributedString.Key, range: NSRange) {
        for run in contents[Range(range, in: contents)].runs {
            guard var container = run.nsAttributes else { continue }
            if container.removeValue(forKey: name) != nil {
                contents[run.range].nsAttributes = container.isEmpty ? nil : container
            }
        }
    }
    
    open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        contents.replaceSubrange(Range(range, in: contents), with: attrString.contents)
    }
    
    open func insert(_ attrString: NSAttributedString, at loc: Int) {
        let offset = contents.utf16.index(contents.utf16.startIndex, offsetBy: loc)
        contents.insert(attrString.contents, at: offset)
    }
    
    open func append(_ attrString: NSAttributedString) {
        contents.append(attrString.contents)
    }
    
    open func deleteCharacters(in range: NSRange) {
        contents.characters.removeSubrange(Range(range, in: contents))
    }
    
    open func setAttributedString(_ attrString: NSAttributedString) {
        contents = attrString.contents
    }
    
    open func beginEditing() {

    }
    
    open func endEditing() {

    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return NSAttributedString(attributedString: self)
    }
    
    public override init(string: String) {
        super.init(string: string)
    }
    
    public override init(string: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) {
        super.init(string: string, attributes: attrs)
    }
    
    public override init(attributedString: NSAttributedString) {
        super.init(attributedString: attributedString)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        let mutableAttributedString = NSMutableAttributedString(string: "")
        guard _NSReadMutableAttributedStringWithCoder(aDecoder, mutableAttributedString: mutableAttributedString) else {
            return nil
        }
        
        super.init(attributedString: mutableAttributedString)
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

    return withExtendedLifetime(data) { _ -> (Int, Int)? in
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
