// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
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


open class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSCoding {
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
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    open override func isEqual(_ object: AnyObject?) -> Bool {
        if let cs = object as? NSCharacterSet {
            return CFEqual(_cfObject, cs._cfObject)
        } else {
            return false
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
    
    open class func controlCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetControl)._swiftObject
    }
    
    open class func whitespaces() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)._swiftObject
    }

    open class func whitespacesAndNewlines() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)._swiftObject
    }
    
    open class func decimalDigits() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)._swiftObject
    }
    
    public class func letters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLetter)._swiftObject
    }
    
    open class func lowercaseLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)._swiftObject
    }
    
    open class func uppercaseLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)._swiftObject
    }
    
    open class func nonBaseCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNonBase)._swiftObject
    }
    
    open class func alphanumerics() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)._swiftObject
    }
    
    open class func decomposables() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)._swiftObject
    }
    
    open class func illegalCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetIllegal)._swiftObject
    }
    
    open class func punctuation() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)._swiftObject
    }
    
    open class func capitalizedLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)._swiftObject
    }
    
    open class func symbols() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetSymbol)._swiftObject
    }
    
    open class func newlines() -> CharacterSet {
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
    
    public convenience required init(coder aDecoder: NSCoder) {
        self.init(charactersIn: "")
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
    
    open func hasMember(inPlane plane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(_cfObject, CFIndex(plane))
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        if type(of: self) == NSCharacterSet.self || type(of: self) == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else if type(of: self) == _NSCFCharacterSet.self {
            return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open override func mutableCopy() -> AnyObject {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> AnyObject {
        if type(of: self) == NSCharacterSet.self || type(of: self) == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else if type(of: self) == _NSCFCharacterSet.self {
            return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        
    }
}

open class NSMutableCharacterSet : NSCharacterSet {

    public convenience required init(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
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

    open class func controlCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetControl)), to: NSMutableCharacterSet.self)
    }
    
    open class func whitespaces() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)), to: NSMutableCharacterSet.self)
    }
    
    open class func whitespacesAndNewlines() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)), to: NSMutableCharacterSet.self)
    }
    
    open class func decimalDigits() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)), to: NSMutableCharacterSet.self)
    }
    
    public class func letters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func lowercaseLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func uppercaseLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func nonBaseCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetNonBase)), to: NSMutableCharacterSet.self)
    }
    
    open class func alphanumerics() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)), to: NSMutableCharacterSet.self)
    }
    
    open class func decomposables() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)), to: NSMutableCharacterSet.self)
    }
    
    open class func illegalCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetIllegal)), to: NSMutableCharacterSet.self)
    }
    
    open class func punctuation() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)), to: NSMutableCharacterSet.self)
    }
    
    open class func capitalizedLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)), to: NSMutableCharacterSet.self)
    }
    
    open class func symbols() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetSymbol)), to: NSMutableCharacterSet.self)
    }
    
    open class func newlines() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetNewline)), to: NSMutableCharacterSet.self)
    }
}

extension CharacterSet : _CFBridgable, _NSBridgable {
    typealias CFType = CFCharacterSet
    typealias NSType = NSCharacterSet
    internal var _cfObject: CFType {
        return _nsObject._cfObject
    }
    internal var _nsObject: NSType {
        return _bridgeToObjectiveC()
    }
}

extension CFCharacterSet : _NSBridgable, _SwiftBridgable {
    typealias NSType = NSCharacterSet
    typealias SwiftType = CharacterSet
    internal var _nsObject: NSType {
        return unsafeBitCast(self, to: NSType.self)
    }
    internal var _swiftObject: SwiftType {
        return _nsObject._swiftObject
    }
}

extension NSCharacterSet : _SwiftBridgable {
    typealias SwiftType = CharacterSet
    internal var _swiftObject: SwiftType {
        return CharacterSet(_bridged: self)
    }
}
