//
//  NSCFCharacterSet.swift
//  Foundation
//
//  Created by Philippe Hausler on 6/3/16.
//  Copyright © 2016 Apple. All rights reserved.
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

internal class _NSCFCharacterSet : NSMutableCharacterSet {
    
    required init(coder aDecoder: NSCoder) {
        fatalError("Coding is not supported for bridge classes")
    }
    
    override func characterIsMember(_ aCharacter: unichar) -> Bool {
        return CFCharacterSetIsCharacterMember(unsafeBitCast(self, to: CFCharacterSet.self), UniChar(aCharacter))
    }
    
    override var bitmapRepresentation: Data {
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, unsafeBitCast(self, to: CFCharacterSet.self))._swiftObject
    }
    
    override var inverted: CharacterSet {
        return CFCharacterSetCreateInvertedSet(kCFAllocatorSystemDefault, unsafeBitCast(self, to: CFCharacterSet.self))._swiftObject
    }
    
    override func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        return CFCharacterSetIsLongCharacterMember(unsafeBitCast(self, to: CFCharacterSet.self), theLongChar)
    }
    
    override func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        return CFCharacterSetIsSupersetOfSet(unsafeBitCast(self, to: CFCharacterSet.self), theOtherSet._cfObject)
    }
    
    override func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        return CFCharacterSetHasMemberInPlane(unsafeBitCast(self, to: CFCharacterSet.self), CFIndex(thePlane))
    }
    
    override func copy() -> Any {
        return copy(with: nil)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        return CFCharacterSetCreateCopy(kCFAllocatorSystemDefault, unsafeBitCast(self, to: CFCharacterSet.self))
    }
    
    override func mutableCopy(with zone: NSZone? = nil) -> Any {
        return CFCharacterSetCreateMutableCopy(kCFAllocatorSystemDefault, unsafeBitCast(self, to: CFCharacterSet.self))._nsObject
    }
    
    
    override func addCharacters(in aRange: NSRange) {
        CFCharacterSetAddCharactersInRange(unsafeBitCast(self, to: CFMutableCharacterSet.self) , CFRangeMake(aRange.location, aRange.length))
    }
    
    override func removeCharacters(in aRange: NSRange) {
        CFCharacterSetRemoveCharactersInRange(unsafeBitCast(self, to: CFMutableCharacterSet.self) , CFRangeMake(aRange.location, aRange.length))
    }
    
    override func addCharacters(in aString: String) {
        CFCharacterSetAddCharactersInString(unsafeBitCast(self, to: CFMutableCharacterSet.self), aString._cfObject)
    }
    
    override func removeCharacters(in aString: String) {
        CFCharacterSetRemoveCharactersInString(unsafeBitCast(self, to: CFMutableCharacterSet.self), aString._cfObject)
    }
    
    override func formUnion(with otherSet: CharacterSet) {
        CFCharacterSetUnion(unsafeBitCast(self, to: CFMutableCharacterSet.self), unsafeBitCast(otherSet._bridgeToObjectiveC(), to: CFCharacterSet.self))
    }
    
    override func formIntersection(with otherSet: CharacterSet) {
        CFCharacterSetIntersect(unsafeBitCast(self, to: CFMutableCharacterSet.self), unsafeBitCast(otherSet._bridgeToObjectiveC(), to: CFCharacterSet.self))
    }
    
    override func invert() {
        CFCharacterSetInvert(unsafeBitCast(self, to: CFMutableCharacterSet.self))
    }
}

internal  func _CFSwiftCharacterSetExpandedCFCharacterSet(_ cset: CFTypeRef) -> Unmanaged<CFCharacterSet>? {
    return nil
}

internal  func _CFSwiftCharacterSetRetainedBitmapRepresentation(_ cset: CFTypeRef) -> Unmanaged<CFData> {
    NSUnimplemented()
}

internal  func _CFSwiftCharacterSetCharacterIsMember(_ cset: CFTypeRef, _ ch: UniChar) -> Bool {
    return (cset as! NSCharacterSet).characterIsMember(ch)
}

internal  func _CFSwiftCharacterSetMutableCopy(_ cset: CFTypeRef) -> Unmanaged<CFMutableCharacterSet> {
    return Unmanaged.passRetained((cset as! NSCharacterSet).mutableCopy() as! CFMutableCharacterSet)
}

internal  func _CFSwiftCharacterSetLongCharacterIsMember(_ cset: CFTypeRef, _ ch:UInt32) -> Bool {
    return (cset as! NSCharacterSet).longCharacterIsMember(ch)
}

internal  func _CFSwiftCharacterSetHasMemberInPlane(_ cset: CFTypeRef, _ plane: UInt8) -> Bool {
    return (cset as! NSCharacterSet).hasMemberInPlane(plane)
}

internal  func _CFSwiftCharacterSetCreateInverted(_ cset: CFTypeRef) -> Unmanaged<CFCharacterSet> {
    return Unmanaged.passRetained((cset as! NSCharacterSet).inverted._cfObject)
}

internal func _CFSwiftMutableSetAddCharactersInRange(_ characterSet: CFTypeRef, _ range: CFRange) -> Void {
    (characterSet as! NSMutableCharacterSet).addCharacters(in: NSRange(location: range.location, length: range.length))
}

internal func _CFSwiftMutableSetRemoveCharactersInRange(_ characterSet: CFTypeRef, _ range: CFRange) -> Void {
    (characterSet as! NSMutableCharacterSet).removeCharacters(in: NSRange(location: range.location, length: range.length))
}

internal func _CFSwiftMutableSetAddCharactersInString(_ characterSet: CFTypeRef, _ string: CFString) -> Void {
    (characterSet as! NSMutableCharacterSet).addCharacters(in: string._swiftObject)
}

internal func _CFSwiftMutableSetRemoveCharactersInString(_ characterSet: CFTypeRef, _ string: CFString) -> Void {
    (characterSet as! NSMutableCharacterSet).removeCharacters(in: string._swiftObject)
}

internal func _CFSwiftMutableSetFormUnionWithCharacterSet(_ characterSet: CFTypeRef, _ other: CFTypeRef) -> Void {
    (characterSet as! NSMutableCharacterSet).formUnion(with: (other as! NSCharacterSet)._swiftObject)
}

internal func _CFSwiftMutableSetFormIntersectionWithCharacterSet(_ characterSet: CFTypeRef, _ other: CFTypeRef) -> Void {
    (characterSet as! NSMutableCharacterSet).formIntersection(with: (other as! NSCharacterSet)._swiftObject)
}

internal func _CFSwiftMutableSetInvert(_ characterSet: CFTypeRef) -> Void {
    (characterSet as! NSMutableCharacterSet).invert()
}

