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


public class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSCoding {
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
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let cs = object as? NSCharacterSet {
            return CFEqual(_cfObject, cs._cfObject)
        } else {
            return false
        }
    }
    
    public override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }
    
    public override init() {
        super.init()
        _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(0, 0));
    }

    deinit {
        _CFDeinit(self)
    }
    
    public class func controlCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetControl)._swiftObject
    }
    
    public class func whitespaces() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)._swiftObject
    }

    public class func whitespacesAndNewlines() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)._swiftObject
    }
    
    public class func decimalDigits() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)._swiftObject
    }
    
    public class func letters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLetter)._swiftObject
    }
    
    public class func lowercaseLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)._swiftObject
    }
    
    public class func uppercaseLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)._swiftObject
    }
    
    public class func nonBaseCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNonBase)._swiftObject
    }
    
    public class func alphanumerics() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)._swiftObject
    }
    
    public class func decomposables() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)._swiftObject
    }
    
    public class func illegalCharacters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetIllegal)._swiftObject
    }
    
    public class func punctuation() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)._swiftObject
    }
    
    public class func capitalizedLetters() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)._swiftObject
    }
    
    public class func symbols() -> CharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetSymbol)._swiftObject
    }
    
    public class func newlines() -> CharacterSet {
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
    
    public func characterIsMember(_ aCharacter: unichar) -> Bool {
        return longCharacterIsMember(UInt32(aCharacter))
    }
    
    public var bitmapRepresentation: Data {
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, _cfObject)._swiftObject
    }
    
    public var inverted: CharacterSet {
        let copy = mutableCopy() as! NSMutableCharacterSet
        copy.invert()
        return copy._swiftObject
    }
    
    public func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        if self.dynamicType == NSCharacterSet.self || self.dynamicType == NSMutableCharacterSet.self {
            return _CFCharacterSetIsLongCharacterMember(unsafeBitCast(self, to: CFType.self), theLongChar)
        } else if self.dynamicType == _NSCFCharacterSet.self {
            return CFCharacterSetIsLongCharacterMember(_cfObject, theLongChar)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        return CFCharacterSetIsSupersetOfSet(_cfObject, theOtherSet._cfObject)
    }
    
    public func hasMember(inPlane plane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(_cfObject, CFIndex(plane))
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject {
        if self.dynamicType == NSCharacterSet.self || self.dynamicType == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else if self.dynamicType == _NSCFCharacterSet.self {
            return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopy(with: nil)
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> AnyObject {
        if self.dynamicType == NSCharacterSet.self || self.dynamicType == NSMutableCharacterSet.self {
            return _CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else if self.dynamicType == _NSCFCharacterSet.self {
            return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        
    }
}

public class NSMutableCharacterSet : NSCharacterSet {

    public convenience required init(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func addCharacters(in aRange: NSRange) {
        CFCharacterSetAddCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    public func removeCharacters(in aRange: NSRange) {
        CFCharacterSetRemoveCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    public func addCharacters(in aString: String) {
        CFCharacterSetAddCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public func removeCharacters(in aString: String) {
        CFCharacterSetRemoveCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public func formUnion(with otherSet: CharacterSet) {
        CFCharacterSetUnion(_cfMutableObject, otherSet._cfObject)
    }
    
    public func formIntersection(with otherSet: CharacterSet) {
        CFCharacterSetIntersect(_cfMutableObject, otherSet._cfObject)
    }
    
    public func invert() {
        CFCharacterSetInvert(_cfMutableObject)
    }

    public class func controlCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetControl)), to: NSMutableCharacterSet.self)
    }
    
    public class func whitespaces() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)), to: NSMutableCharacterSet.self)
    }
    
    public class func whitespacesAndNewlines() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)), to: NSMutableCharacterSet.self)
    }
    
    public class func decimalDigits() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)), to: NSMutableCharacterSet.self)
    }
    
    public class func letters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLetter)), to: NSMutableCharacterSet.self)
    }
    
    public class func lowercaseLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    public class func uppercaseLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)), to: NSMutableCharacterSet.self)
    }
    
    public class func nonBaseCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetNonBase)), to: NSMutableCharacterSet.self)
    }
    
    public class func alphanumerics() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)), to: NSMutableCharacterSet.self)
    }
    
    public class func decomposables() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)), to: NSMutableCharacterSet.self)
    }
    
    public class func illegalCharacters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetIllegal)), to: NSMutableCharacterSet.self)
    }
    
    public class func punctuation() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)), to: NSMutableCharacterSet.self)
    }
    
    public class func capitalizedLetters() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)), to: NSMutableCharacterSet.self)
    }
    
    public class func symbols() -> NSMutableCharacterSet {
        return unsafeBitCast(CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, CFCharacterSetGetPredefined(kCFCharacterSetSymbol)), to: NSMutableCharacterSet.self)
    }
    
    public class func newlines() -> NSMutableCharacterSet {
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
