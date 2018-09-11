// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(macOS) || os(iOS)
let kCFCharacterSetControl = CFCharacterSetPredefinedSet.control
let kCFCharacterSetWhitespace = CFCharacterSetPredefinedSet.whitespace
let kCFCharacterSetWhitespaceAndNewline = CFCharacterSetPredefinedSet.whitespaceAndNewline
let kCFCharacterSetDecimalDigit = CFCharacterSetPredefinedSet.decimalDigit
let kCFCharacterSetLetter = CFCharacterSetPredefinedSet.letter
let kCFCharacterSetLowercaseLetter = CFCharacterSetPredefinedSet.lowercaseLetter
let kCFCharacterSetUppercaseLetter = CFCharacterSetPredefinedSet.uppercaseLetter
let kCFCharacterSetNonBase = CFCharacterSetPredefinedSet.nonBase
let kCFCharacterSetDecomposable = CFCharacterSetPredefinedSet.decomposable
let kCFCharacterSetAlphaNumeric = CFCharacterSetPredefinedSet.alphaNumeric
let kCFCharacterSetPunctuation = CFCharacterSetPredefinedSet.punctuation
let kCFCharacterSetCapitalizedLetter = CFCharacterSetPredefinedSet.capitalizedLetter
let kCFCharacterSetSymbol = CFCharacterSetPredefinedSet.symbol
let kCFCharacterSetNewline = CFCharacterSetPredefinedSet.newline
let kCFCharacterSetIllegal = CFCharacterSetPredefinedSet.illegal
#endif


open class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    typealias CFType = CFCharacterSet
    private var _base = _CFInfo(typeID: CFCharacterSetGetTypeID())
    private var _hashValue = CFHashCode(0)
    private var _buffer: UnsafeMutableRawPointer? = nil
    private var _length = CFIndex(0)
    private var _annex: UnsafeMutableRawPointer? = nil
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    internal var _cfMutableObject: CFMutableCharacterSet {
        return unsafeBitCast(self, to: CFMutableCharacterSet.self)
    }
    
    // Disabled due to recursion
    /*open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }*/
    
    open override func isEqual(_ value: Any?) -> Bool {
        guard let runtimeClass = _CFRuntimeGetClassWithTypeID(CFCharacterSetGetTypeID()) else {
            fatalError("Could not obtain CFRuntimeClass of CFCharacterSet")
        }

        guard let equalFunction = runtimeClass.pointee.equal else {
            fatalError("Could not obtain equal function from CFRuntimeClass of CFCharacterSet")
        }

        switch value {
        case let other as CharacterSet: return equalFunction(self._cfObject, other._cfObject) == true
        case let other as NSCharacterSet: return equalFunction(self._cfObject, other._cfObject) == true
        default: return false
        }
    }
    
    open override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }
    
    public override init() {
        super.init()
        _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(0, 0));
    }

    deinit {
        _CFDeinit(self)
    }
    
    open class var controlCharacters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetControl)._swiftObject
    }
    
    open class var whitespaces: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)._swiftObject
    }

    open class var whitespacesAndNewlines: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)._swiftObject
    }
    
    open class var decimalDigits: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)._swiftObject
    }
    
    public class var letters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLetter)._swiftObject
    }
    
    open class var lowercaseLetters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)._swiftObject
    }
    
    open class var uppercaseLetters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)._swiftObject
    }
    
    open class var nonBaseCharacters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNonBase)._swiftObject
    }
    
    open class var alphanumerics: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)._swiftObject
    }
    
    open class var decomposables: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)._swiftObject
    }
    
    open class var illegalCharacters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetIllegal)._swiftObject
    }
    
    open class var punctuationCharacters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)._swiftObject
    }
    
    open class var capitalizedLetters: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)._swiftObject
    }
    
    open class var symbols: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetSymbol)._swiftObject
    }
    
    open class var newlines: CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNewline)._swiftObject
    }

    public init(range aRange: NSRange) {
        super.init()
        _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(aRange.location, aRange.length))
    }
    
    public init(charactersIn aString: String) {
        super.init()
        _CFCharacterSetInitWithCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public init(bitmapRepresentation data: Data) {
        super.init()
        _CFCharacterSetInitWithBitmapRepresentation(_cfMutableObject, data._cfObject)
    }
    
    public convenience init?(contentsOfFile fName: String) {
        do {
           let data = try Data(contentsOf: URL(fileURLWithPath: fName))
            self.init(bitmapRepresentation: data)
        } catch {
            return nil
        }
    }
    
    public required init(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        super.init()
        if aDecoder.containsValue(forKey: "NSBuiltinID") {
            let setId = aDecoder.decodeInteger(forKey: "NSBuiltinID")
            self._base.info = 2 // kCFCharacterSetKeyedCodingTypeBuiltin
            self._buffer = UnsafeMutableRawPointer(bitPattern: setId)
        } else if aDecoder.containsValue(forKey: "NSRange") {
            let value = aDecoder.decodeInt64(forKey: "NSRange")
            let loc = Int(value >> 32)
            let len = Int(value & 0xffffffff)
            _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(loc, len))
        } else if let aDecoder = aDecoder as? NSKeyedUnarchiver,
            aDecoder.containsValue(forKey: "NSString"),
            let aString = aDecoder._decodePropertyListForKey("NSString") as? NSString {
            _CFCharacterSetInitWithCharactersInString(_cfMutableObject, aString._cfObject)
        } else if aDecoder.containsValue(forKey: "NSStringObject"),
            let aString = aDecoder.decodeObject(of: NSString.self, forKey: "NSStringObject") {
            _CFCharacterSetInitWithCharactersInString(_cfMutableObject, aString._cfObject)
        } else if let aDecoder = aDecoder as? NSKeyedUnarchiver,
            aDecoder.containsValue(forKey: "NSBitmap"),
            let representation = aDecoder._decodePropertyListForKey("NSBitmap") as? NSData {
            _CFCharacterSetInitWithBitmapRepresentation(_cfMutableObject, representation._cfObject)
        } else if aDecoder.containsValue(forKey: "NSBitmapObject"),
            let representation = aDecoder.decodeObject(of: NSData.self, forKey: "NSBitmapObject") {
            _CFCharacterSetInitWithBitmapRepresentation(_cfMutableObject, representation._cfObject)
        } else {
            NSRequiresConcreteImplementation()
        }
        
        if aDecoder.decodeBool(forKey: "NSIsInverted") {
            CFCharacterSetInvert(_cfMutableObject)
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        switch CFIndex(_CFCharacterSetGetKeyedCodingType(_cfObject)) {
        case 2: // kCFCharacterSetKeyedCodingTypeBuiltin
            let type = CFIndex(_CFCharacterSetGetKeyedCodingBuiltinType(_cfObject))
            aCoder.encode(type, forKey: "NSBuiltinID")
        case 4: // kCFCharacterSetKeyedCodingTypeString
            let str = _CFCharacterSetCreateKeyedCodingString(_cfObject)!.takeRetainedValue()._nsObject
            if let aCoder = aCoder as? NSKeyedArchiver {
                aCoder._encodePropertyList(str, forKey: "NSString")
            } else {
                aCoder.encode(str, forKey: "NSStringObject")
            }
        case 3: // kCFCharacterSetKeyedCodingTypeRange
            let range = NSRange(_CFCharacterSetGetKeyedCodingRange(_cfObject))
            if range.length > 0 {
                let value = Int64(range.location) << 32 + Int64(range.length)
                aCoder.encode(value, forKey: "NSRange")
            } else {
                fallthrough
            }
        case 1, 5: // kCFCharacterSetKeyedCodingTypeBitmap, kCFCharacterSetKeyedCodingTypeBuiltinAndBitmap
            if let aCoder = aCoder as? NSKeyedArchiver {
                aCoder._encodePropertyList(bitmapRepresentation._nsObject, forKey: "NSBitmap")
            } else {
                aCoder.encode(bitmapRepresentation._nsObject, forKey: "NSBitmapObject")
            }
        default:
            fatalError("Unknown CFCharacterSet keyed coding type.")
        }
        
        if _CFCharacterSetIsInverted(_cfObject) {
            aCoder.encode(true, forKey: "NSIsInverted")
        }
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open func characterIsMember(_ aCharacter: unichar) -> Bool {
        return longCharacterIsMember(UInt32(aCharacter))
    }
    
    open var bitmapRepresentation: Data {
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, _cfObject)._swiftObject
    }
    
    open var inverted: CharacterSet {
        let copy = mutableCopy() as! NSMutableCharacterSet
        copy.invert()
        return copy._swiftObject
    }
    
    open func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        if type(of: self) == NSCharacterSet.self || type(of: self) == NSMutableCharacterSet.self {
            return _CFCharacterSetIsLongCharacterMember(unsafeBitCast(self, to: CFType.self), theLongChar)
        } else if type(of: self) == _NSCFCharacterSet.self {
            return CFCharacterSetIsLongCharacterMember(_cfObject, theLongChar)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        return CFCharacterSetIsSupersetOfSet(_cfObject, theOtherSet._cfObject)
    }
    
    open func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(_cfObject, CFIndex(thePlane))
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) == NSCharacterSet.self || type(of: self) == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else if type(of: self) == _NSCFCharacterSet.self {
            return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        if type(of: self) == NSCharacterSet.self || type(of: self) == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else if type(of: self) == _NSCFCharacterSet.self {
            return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
}

open class NSMutableCharacterSet : NSCharacterSet {

    open func addCharacters(in aRange: NSRange) {
        CFCharacterSetAddCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    open func removeCharacters(in aRange: NSRange) {
        CFCharacterSetRemoveCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    open func addCharacters(in aString: String) {
        CFCharacterSetAddCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    open func removeCharacters(in aString: String) {
        CFCharacterSetRemoveCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    open func formUnion(with otherSet: CharacterSet) {
        CFCharacterSetUnion(_cfMutableObject, otherSet._cfObject)
    }
    
    open func formIntersection(with otherSet: CharacterSet) {
        CFCharacterSetIntersect(_cfMutableObject, otherSet._cfObject)
    }
    
    open func invert() {
        CFCharacterSetInvert(_cfMutableObject)
    }

    open class func control() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetControl)), to: NSMutableCharacterSet.self)
    }
    
    open class func whitespace() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)), to: NSMutableCharacterSet.self)
    }
    
    open class func whitespaceAndNewline() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)), to: NSMutableCharacterSet.self)
    }
    
    open class func decimalDigit() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)), to: NSMutableCharacterSet.self)
    }
    
    public class func letter() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func lowercaseLetter() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func uppercaseLetter() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func nonBase() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetNonBase)), to: NSMutableCharacterSet.self)
    }
    
    open class func alphanumeric() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)), to: NSMutableCharacterSet.self)
    }
    
    open class func decomposable() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)), to: NSMutableCharacterSet.self)
    }
    
    open class func illegal() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetIllegal)), to: NSMutableCharacterSet.self)
    }
    
    open class func punctuation() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)), to: NSMutableCharacterSet.self)
    }
    
    open class func capitalizedLetter() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func symbol() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetSymbol)), to: NSMutableCharacterSet.self)
    }
    
    open class func newline() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetNewline)), to: NSMutableCharacterSet.self)
    }
}

extension CharacterSet : _CFBridgeable, _NSBridgeable {
    typealias CFType = CFCharacterSet
    typealias NSType = NSCharacterSet
    internal var _cfObject: CFType {
        return _nsObject._cfObject
    }
    internal var _nsObject: NSType {
        return _bridgeToObjectiveC()
    }
}

extension CFCharacterSet : _NSBridgeable, _SwiftBridgeable {
    typealias NSType = NSCharacterSet
    typealias SwiftType = CharacterSet
    internal var _nsObject: NSType {
        return unsafeBitCast(self, to: NSType.self)
    }
    internal var _swiftObject: SwiftType {
        return _nsObject._swiftObject
    }
}

extension NSCharacterSet : _SwiftBridgeable {
    typealias SwiftType = CharacterSet
    internal var _swiftObject: SwiftType {
        return CharacterSet(_bridged: self)
    }
}

extension NSCharacterSet : _StructTypeBridgeable {
    public typealias _StructType = CharacterSet
    public func _bridgeToSwift() -> CharacterSet {
        return CharacterSet._unconditionallyBridgeFromObjectiveC(self)
    }
}

#if os(macOS) || os(iOS) || os(tvOS)
internal extension CFIndex {
    init(_ set: CFCharacterSetPredefinedSet) {
        self.init(set.rawValue)
    }
    
    init(_ type: CFCharacterSetKeyedCodingType) {
        self.init(type.rawValue)
    }
}
#endif
