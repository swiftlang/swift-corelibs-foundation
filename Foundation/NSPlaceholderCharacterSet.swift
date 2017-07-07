//
//  NSPlaceholderCharacterSet.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 7/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import CoreFoundation

internal final class _NSPlaceholderCharacterSet : NSCharacterSet {
    var _original: NSCharacterSet
    var _invertedSet: NSCharacterSet?
    var _inverted: Bool
    var _builtin: Bool
    var _isCF: Bool
    var _lock = NSLock()
    
    struct Options : OptionSet {
        var rawValue: Int
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let inverted = Options(rawValue: 1 << 0)
        static let builtin = Options(rawValue: 1 << 1)
    }
    
    static func __new(_ other: NSCharacterSet, options: Options) -> NSCharacterSet {
        if other.isMutable {
            let mset = other.mutableCopy() as! NSMutableCharacterSet
            mset.invert()
            mset.makeImmutable()
            return mset
        } else {
            return _NSPlaceholderCharacterSet(other, options: options)
        }
    }
    
    fileprivate init(_ other: NSCharacterSet, options: Options) {
        _inverted = options.contains(.inverted)
        _builtin = options.contains(.builtin)
        _isCF = type(of: other) == _NSCFCharacterSet.self
        _original = other
        super.init(placeholder: ())
    }
    
    func _expandInverted() {
        if _inverted && _invertedSet == nil {
            let mset = _original.mutableCopy() as! NSMutableCharacterSet
            mset.invert()
            _lock.synchronized {
                if _invertedSet == nil {
                    _invertedSet = mset
                }
            }
        }
    }
    
    public convenience required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mutableCopy(with zone: NSZone?) -> Any {
        if let inverted = _invertedSet {
            return inverted.mutableCopy(with: zone)
        } else {
            let mset = _original.mutableCopy() as! NSMutableCharacterSet
            if _inverted { mset.invert() }
            return mset
        }
    }
    
    override func characterIsMember(_ aCharacter: unichar) -> Bool {
        return longCharacterIsMember(UInt32(aCharacter))
    }
    
    override func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        let res = CFCharacterSetIsLongCharacterMember(_unsafeReferenceCast(_original, to: CFCharacterSet.self), theLongChar)
        return _inverted ? !res : res
    }
    
    override func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        let other = _unsafeReferenceCast(theOtherSet._bridgeToObjectiveC(), to: CFCharacterSet.self)
        if let inverted = _invertedSet {
            return CFCharacterSetIsSupersetOfSet(_unsafeReferenceCast(inverted, to: CFCharacterSet.self), other)
        } else {
            var result = CFCharacterSetIsSupersetOfSet(_unsafeReferenceCast(_original, to: CFCharacterSet.self), other)
            if _inverted {
                if result {
                    result = false
                } else {
                    _expandInverted()
                    return CFCharacterSetIsSupersetOfSet(_unsafeReferenceCast(_invertedSet!, to: CFCharacterSet.self), other)
                }
            }
            return result
        }
    }
    
    override func hasMemberInPlane(_ plane: UInt8) -> Bool {
        var set = _original
        if _inverted {
            _expandInverted()
            set = _invertedSet!
        }
        return CFCharacterSetHasMemberInPlane(_unsafeReferenceCast(set, to: CFCharacterSet.self), CFIndex(plane))
    }
    
    override func isEqual(_ value: Any?) -> Bool {
        guard let other = value else { return false }
        var otherSet: NSCharacterSet
        if let cset = other as? CharacterSet {
            otherSet = cset._bridgeToObjectiveC()
        } else if let cset = other as? NSCharacterSet {
            otherSet = cset
        } else {
            return false
        }
        
        var set = _original
        if otherSet === self { return true }
        if _isCF && otherSet._expandedCFCharacterSet() === _unsafeReferenceCast(_original, to: CFCharacterSet.self) {
            return true
        }
        
        if _inverted {
            _expandInverted()
            set = _invertedSet!
        }
        
        return CFEqual(set, otherSet)
    }
    
    override var bitmapRepresentation: Data {
        var set = _original
        if _inverted {
            _expandInverted()
            set = _invertedSet!
        }
        return CFCharacterSetCreateBitmapRepresentation(kCFAllocatorSystemDefault, _unsafeReferenceCast(set, to: CFCharacterSet.self))._swiftObject
    }
    
    override func replacementObject(for aCoder: NSCoder) -> Any? {
        if _inverted {
            _expandInverted()
            return _invertedSet
        } else {
            return _original
        }
    }
    
    override func replacementObject(for archiver: NSKeyedArchiver) -> Any? {
        if _inverted {
            _expandInverted()
            return _invertedSet
        } else {
            return _original
        }
    }
}
