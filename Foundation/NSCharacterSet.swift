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
    private var _buffer: UnsafeMutablePointer<Void>? = nil
    private var _length = CFIndex(0)
    private var _annex: UnsafeMutablePointer<Void>? = nil
    
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

    deinit {
        _CFDeinit(self)
    }
    
    public class func controlCharacters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetControl)._nsObject
    }
    
    public class func whitespaces() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)._nsObject
    }

    public class func whitespacesAndNewlines() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)._nsObject
    }
    
    public class func decimalDigits() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)._nsObject
    }
    
    public class func letters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLetter)._nsObject
    }
    
    public class func lowercaseLetters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)._nsObject
    }
    
    public class func uppercaseLetters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)._nsObject
    }
    
    public class func nonBaseCharacters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNonBase)._nsObject
    }
    
    public class func alphanumerics() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)._nsObject
    }
    
    public class func decomposables() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)._nsObject
    }
    
    public class func illegalCharacters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetIllegal)._nsObject
    }
    
    public class func punctuation() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)._nsObject
    }
    
    public class func capitalizedLetters() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)._nsObject
    }
    
    public class func symbols() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetSymbol)._nsObject
    }
    
    public class func newlines() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNewline)._nsObject
    }

    public init(range aRange: NSRange) {
        super.init()
        _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(aRange.location, aRange.length))
    }
    
    public init(charactersIn aString: String) {
        super.init()
        _CFCharacterSetInitWithCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public init(bitmapRepresentation data: NSData) {
        super.init()
        _CFCharacterSetInitWithBitmapRepresentation(_cfMutableObject, data._cfObject)
    }
    
    public convenience init?(contentsOfFile fName: String) {
        if let data = NSData(contentsOfFile: fName) {
            self.init(bitmapRepresentation: data)
        } else {
            return nil
        }
    }
    
    public convenience required init(coder aDecoder: NSCoder) {
        self.init(charactersIn: "")
    }
    
    public func characterIsMember(_ aCharacter: unichar) -> Bool {
        return CFCharacterSetIsCharacterMember(_cfObject, UniChar(aCharacter))
    }
    
    public var bitmapRepresentation: NSData {
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public var inverted: NSCharacterSet {
        return CFCharacterSetCreateInvertedSet(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public func longCharacterIsMember(_ theLongChar: UTF32Char) -> Bool {
        return CFCharacterSetIsLongCharacterMember(_cfObject, theLongChar)
    }
    
    public func isSuperset(of theOtherSet: NSCharacterSet) -> Bool {
        return CFCharacterSetIsSupersetOfSet(_cfObject, theOtherSet._cfObject)
    }
    
    public func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(_cfObject, CFIndex(thePlane))
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        
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
    
    public func formUnion(with otherSet: NSCharacterSet) {
        CFCharacterSetUnion(_cfMutableObject, otherSet._cfObject)
    }
    
    public func formIntersection(with otherSet: NSCharacterSet) {
        CFCharacterSetIntersect(_cfMutableObject, otherSet._cfObject)
    }
    
    public func invert() {
        CFCharacterSetInvert(_cfMutableObject)
    }

    public override class func controlCharacters() -> NSMutableCharacterSet {
        return NSCharacterSet.controlCharacters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func whitespaces() -> NSMutableCharacterSet {
        return NSCharacterSet.whitespaces().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func whitespacesAndNewlines() -> NSMutableCharacterSet {
        return NSCharacterSet.whitespacesAndNewlines().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func decimalDigits() -> NSMutableCharacterSet {
        return NSCharacterSet.decimalDigits().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func letters() -> NSMutableCharacterSet {
        return NSCharacterSet.letters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func lowercaseLetters() -> NSMutableCharacterSet {
        return NSCharacterSet.lowercaseLetters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func uppercaseLetters() -> NSMutableCharacterSet {
        return NSCharacterSet.uppercaseLetters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func nonBaseCharacters() -> NSMutableCharacterSet {
        return NSCharacterSet.nonBaseCharacters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func alphanumerics() -> NSMutableCharacterSet {
        return NSCharacterSet.alphanumerics().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func decomposables() -> NSMutableCharacterSet {
        return NSCharacterSet.decomposables().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func illegalCharacters() -> NSMutableCharacterSet {
        return NSCharacterSet.illegalCharacters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func punctuation() -> NSMutableCharacterSet {
        return NSCharacterSet.punctuation().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func capitalizedLetters() -> NSMutableCharacterSet {
        return NSCharacterSet.capitalizedLetters().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func symbols() -> NSMutableCharacterSet {
        return NSCharacterSet.symbols().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func newlines() -> NSMutableCharacterSet {
        return NSCharacterSet.newlines().mutableCopy() as! NSMutableCharacterSet
    }
}

extension CFCharacterSet : _NSBridgable {
    typealias NSType = NSCharacterSet
    internal var _nsObject: NSType {
        return unsafeBitCast(self, to: NSType.self)
    }
}
