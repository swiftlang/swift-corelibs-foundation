// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

open class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSCoding {
    typealias CFType = CFCharacterSet
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    open override var hash: Int {
        return bitmapRepresentation.hashValue
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        guard let other = value else { return false }
        if let cset = other as? CharacterSet {
            return bitmapRepresentation == cset._bridgeToObjectiveC().bitmapRepresentation
        } else if let cset = other as? NSCharacterSet {
            return bitmapRepresentation == cset.bitmapRepresentation
        }
        return false
    }
    
    internal init(placeholder: ()) {
        super.init()
    }
    
    public convenience override init() {
        if type(of: self) == NSCharacterSet.self {
            let cf = CFCharacterSetCreateWithCharactersInRange(kCFAllocatorSystemDefault, CFRangeMake(0, 0))
            self.init(factory: _unsafeReferenceCast(cf, to: NSCharacterSet.self))
        } else {
            self.init(placeholder: ())
        }
        
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

    public convenience init(range aRange: NSRange) {
        let cf = CFCharacterSetCreateWithCharactersInRange(kCFAllocatorSystemDefault, CFRangeMake(0, 0))
        self.init(factory: _unsafeReferenceCast(cf, to: NSCharacterSet.self))
    }
    
    public convenience init(charactersIn aString: String) {
        let cf = CFCharacterSetCreateWithCharactersInString(kCFAllocatorSystemDefault, aString._cfObject)
        self.init(factory: _unsafeReferenceCast(cf, to: NSCharacterSet.self))
    }
    
    public convenience init(bitmapRepresentation data: Data) {
        let cf = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorSystemDefault, data._cfObject)
        self.init(factory: _unsafeReferenceCast(cf, to: NSCharacterSet.self))
    }
    
    public convenience init?(contentsOfFile fName: String) {
        do {
           let data = try Data(contentsOf: URL(fileURLWithPath: fName))
            self.init(bitmapRepresentation: data)
        } catch {
            return nil
        }
    }
    
    public convenience required init(coder aDecoder: NSCoder) {
        self.init(charactersIn: "")
        NSUnimplemented()
    }
    
    open func characterIsMember(_ aCharacter: unichar) -> Bool {
        return longCharacterIsMember(UInt32(aCharacter))
    }
    
    /* This abstract implementation of bitmapRepresentation, in terms of characterIsMember:, is probably too slow to be useful except for debugging...  However, it does make all character sets "work" if they implement only characterIsMember:.
     */
    open var bitmapRepresentation: Data {
        let numCharacters = 65536
        let bitsPerByte = 8
        let logBPB = 3
        let bitmapRepSize = numCharacters / bitsPerByte
        var data = Data(count: bitmapRepSize)
        for ch in 0..<65535 {
            if characterIsMember(unichar(ch)) {
                data.withUnsafeMutableBytes { map in
                    map.advanced(by: ch >> logBPB).pointee |= UInt8(truncatingIfNeeded: 1 << (ch & (bitsPerByte - 1)))
                }
            }
        }
        return data
    }
    
    open var inverted: CharacterSet {
        return _NSPlaceholderCharacterSet.__new(self, options: .inverted)._swiftObject
    }
    
    open func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    open func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    open func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSRequiresConcreteImplementation()
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    internal var isMutable: Bool { return false }
    
    internal func makeImmutable() { }
    
    internal func _expandedCFCharacterSet() -> CFCharacterSet? { return nil }
}

open class NSMutableCharacterSet : NSCharacterSet {
    
    internal override init(placeholder: ()) {
        super.init(placeholder: ())
    }
    
    public convenience init() {
        if type(of: self) == NSMutableCharacterSet.self {
            self.init(factory: _unsafeReferenceCast(CFCharacterSetCreateMutable(nil), to: NSMutableCharacterSet.self))
        } else {
            self.init(placeholder: ())
        }
    }
    
    public convenience required init(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func addCharacters(in aRange: NSRange) {
        NSRequiresConcreteImplementation()
    }
    
    open func removeCharacters(in aRange: NSRange) {
        NSRequiresConcreteImplementation()
    }
    
    open func addCharacters(in aString: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func removeCharacters(in aString: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func formUnion(with otherSet: CharacterSet) {
        NSRequiresConcreteImplementation()
    }
    
    open func formIntersection(with otherSet: CharacterSet) {
        NSRequiresConcreteImplementation()
    }
    
    open func invert() {
        NSRequiresConcreteImplementation()
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
    
    internal override var isMutable: Bool { return true }
    
    internal override func makeImmutable() { }
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

extension NSCharacterSet : _NSFactory { }
