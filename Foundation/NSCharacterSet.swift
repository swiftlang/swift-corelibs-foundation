// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
let kCFCharacterSetControl = CFCharacterSetPredefinedSet.Control
let kCFCharacterSetWhitespace = CFCharacterSetPredefinedSet.Whitespace
let kCFCharacterSetWhitespaceAndNewline = CFCharacterSetPredefinedSet.WhitespaceAndNewline
let kCFCharacterSetDecimalDigit = CFCharacterSetPredefinedSet.DecimalDigit
let kCFCharacterSetLetter = CFCharacterSetPredefinedSet.Letter
let kCFCharacterSetLowercaseLetter = CFCharacterSetPredefinedSet.LowercaseLetter
let kCFCharacterSetUppercaseLetter = CFCharacterSetPredefinedSet.UppercaseLetter
let kCFCharacterSetNonBase = CFCharacterSetPredefinedSet.NonBase
let kCFCharacterSetDecomposable = CFCharacterSetPredefinedSet.Decomposable
let kCFCharacterSetAlphaNumeric = CFCharacterSetPredefinedSet.AlphaNumeric
let kCFCharacterSetPunctuation = CFCharacterSetPredefinedSet.Punctuation
let kCFCharacterSetCapitalizedLetter = CFCharacterSetPredefinedSet.CapitalizedLetter
let kCFCharacterSetSymbol = CFCharacterSetPredefinedSet.Symbol
let kCFCharacterSetNewline = CFCharacterSetPredefinedSet.Newline
let kCFCharacterSetIllegal = CFCharacterSetPredefinedSet.Illegal
#endif


public class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSCoding {
    typealias CFType = CFCharacterSetRef
    private var _base = _CFInfo(typeID: CFCharacterSetGetTypeID())
    private var _hashValue = CFHashCode(0)
    private var _buffer = UnsafeMutablePointer<Void>()
    private var _length = CFIndex(0)
    private var _annex = UnsafeMutablePointer<Void>()
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    internal var _cfMutableObject: CFMutableCharacterSetRef {
        return unsafeBitCast(self, CFMutableCharacterSetRef.self)
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
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
    
    public class func controlCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetControl)._nsObject
    }
    
    public class func whitespaceCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespace)._nsObject
    }

    public class func whitespaceAndNewlineCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline)._nsObject
    }
    
    public class func decimalDigitCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit)._nsObject
    }
    
    public class func letterCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLetter)._nsObject
    }
    
    public class func lowercaseLetterCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetLowercaseLetter)._nsObject
    }
    
    public class func uppercaseLetterCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter)._nsObject
    }
    
    public class func nonBaseCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNonBase)._nsObject
    }
    
    public class func alphanumericCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric)._nsObject
    }
    
    public class func decomposableCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetDecomposable)._nsObject
    }
    
    public class func illegalCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetIllegal)._nsObject
    }
    
    public class func punctuationCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetPunctuation)._nsObject
    }
    
    public class func capitalizedLetterCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetCapitalizedLetter)._nsObject
    }
    
    public class func symbolCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetSymbol)._nsObject
    }
    
    public class func newlineCharacterSet() -> NSCharacterSet {
        return CFCharacterSetGetPredefined(kCFCharacterSetNewline)._nsObject
    }

    public init(range aRange: NSRange) {
        super.init()
        _CFCharacterSetInitWithCharactersInRange(_cfMutableObject, CFRangeMake(aRange.location, aRange.length))
    }
    
    public init(charactersInString aString: String) {
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
        self.init(charactersInString: "")
    }
    
    public func characterIsMember(aCharacter: unichar) -> Bool {
        return CFCharacterSetIsCharacterMember(_cfObject, UniChar(aCharacter))
    }
    
    public var bitmapRepresentation: NSData {
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public var invertedSet: NSCharacterSet {
        return CFCharacterSetCreateInvertedSet(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public func longCharacterIsMember(theLongChar: UTF32Char) -> Bool {
        return CFCharacterSetIsLongCharacterMember(_cfObject, theLongChar)
    }
    
    public func isSupersetOfSet(theOtherSet: NSCharacterSet) -> Bool {
        return CFCharacterSetIsSupersetOfSet(_cfObject, theOtherSet._cfObject)
    }
    
    public func hasMemberInPlane(thePlane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(_cfObject, CFIndex(thePlane))
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, self._cfObject)
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, _cfObject)._nsObject
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
    }
}

public class NSMutableCharacterSet : NSCharacterSet {

    public convenience required init(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func addCharactersInRange(aRange: NSRange) {
        CFCharacterSetAddCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    public func removeCharactersInRange(aRange: NSRange) {
        CFCharacterSetRemoveCharactersInRange(_cfMutableObject , CFRangeMake(aRange.location, aRange.length))
    }
    
    public func addCharactersInString(aString: String) {
        CFCharacterSetAddCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public func removeCharactersInString(aString: String) {
        CFCharacterSetRemoveCharactersInString(_cfMutableObject, aString._cfObject)
    }
    
    public func formUnionWithCharacterSet(otherSet: NSCharacterSet) {
        CFCharacterSetUnion(_cfMutableObject, otherSet._cfObject)
    }
    
    public func formIntersectionWithCharacterSet(otherSet: NSCharacterSet) {
        CFCharacterSetIntersect(_cfMutableObject, otherSet._cfObject)
    }
    
    public func invert() {
        CFCharacterSetInvert(_cfMutableObject)
    }

    public override class func controlCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.controlCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func whitespaceCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.whitespaceCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func whitespaceAndNewlineCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func decimalDigitCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.decimalDigitCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func letterCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.letterCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func lowercaseLetterCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.lowercaseLetterCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func uppercaseLetterCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.uppercaseLetterCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func nonBaseCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.nonBaseCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func alphanumericCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.alphanumericCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func decomposableCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.decomposableCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func illegalCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.illegalCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func punctuationCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.punctuationCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func capitalizedLetterCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.capitalizedLetterCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func symbolCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.symbolCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
    
    public override class func newlineCharacterSet() -> NSMutableCharacterSet {
        return NSCharacterSet.newlineCharacterSet().mutableCopy() as! NSMutableCharacterSet
    }
}

extension CFCharacterSetRef : _NSBridgable {
    typealias NSType = NSCharacterSet
    internal var _nsObject: NSType {
        return unsafeBitCast(self, NSType.self)
    }
}
