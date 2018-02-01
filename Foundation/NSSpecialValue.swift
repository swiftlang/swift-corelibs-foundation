// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal protocol NSSpecialValueCoding {
    static func objCType() -> String
    
    init(bytes value: UnsafeRawPointer)
    func encodeWithCoder(_ aCoder: NSCoder)
    init?(coder aDecoder: NSCoder)
    func getValue(_ value: UnsafeMutableRawPointer)
    
    // Ideally we would make NSSpecialValue a generic class and specialise it for
    // NSPoint, etc, but then we couldn't implement NSValue.init?(coder:) because 
    // it's not yet possible to specialise classes with a type determined at runtime.
    //
    // Nor can we make NSSpecialValueCoding conform to Equatable because it has associated
    // type requirements.
    //
    // So in order to implement equality and hash we have the hack below.
    func isEqual(_ value: Any) -> Bool
    var hash: Int { get }
    var description: String { get }
}

internal class NSSpecialValue : NSValue {

    // Originally these were functions in NSSpecialValueCoding but it's probably
    // more convenient to keep it as a table here as nothing else really needs to
    // know about them
    private static let _specialTypes : Dictionary<Int, NSSpecialValueCoding.Type> = [
        1   : NSPoint.self,
        2   : NSSize.self,
        3   : NSRect.self,
        4   : NSRange.self,
        12  : NSEdgeInsets.self
    ]
    
    private static func _typeFromFlags(_ flags: Int) -> NSSpecialValueCoding.Type? {
        return _specialTypes[flags]
    }
    
    private static func _flagsFromType(_ type: NSSpecialValueCoding.Type) -> Int {
        for (F, T) in _specialTypes {
            if T == type {
                return F
            }
        }
        return 0
    }
    
    private static func _objCTypeFromType(_ type: NSSpecialValueCoding.Type) -> String? {
        for (_, T) in _specialTypes {
            if T == type {
                return T.objCType()
            }
        }
        return nil
    }
    
    internal static func _typeFromObjCType(_ type: UnsafePointer<Int8>) -> NSSpecialValueCoding.Type? {
        let objCType = String(cString: type)
        
        for (_, T) in _specialTypes {
            if T.objCType() == objCType {
                return T
            }
        }
        
        return nil
    }
    
    internal var _value : NSSpecialValueCoding
    
    init(_ value: NSSpecialValueCoding) {
        self._value = value
    }
    
    required init(bytes value: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        guard let specialType = NSSpecialValue._typeFromObjCType(type) else {
            NSUnimplemented()
        }
    
        self._value = specialType.init(bytes: value)
    }

    override func getValue(_ value: UnsafeMutableRawPointer) {
        self._value.getValue(value)
    }

    convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let specialFlags = aDecoder.decodeInteger(forKey: "NS.special")
        guard let specialType = NSSpecialValue._typeFromFlags(specialFlags) else {
            return nil
        }
        guard let specialValue = specialType.init(coder: aDecoder) else {
            return nil
        }
        self.init(specialValue)
    }
    
    override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(NSSpecialValue._flagsFromType(type(of: _value)), forKey: "NS.special")
        _value.encodeWithCoder(aCoder)
    }
    
    override var objCType : UnsafePointer<Int8> {
        let typeName = NSSpecialValue._objCTypeFromType(type(of: _value))
        return typeName!._bridgeToObjectiveC().utf8String! // leaky
    }
    
    override var classForCoder: AnyClass {
        // for some day when we support class clusters
        return NSValue.self
    }
    
    override var description : String {
        let desc = _value.description
        if desc.isEmpty {
            return super.description
        }
        return desc
    }
    
    override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as NSSpecialValue:
            return _value.isEqual(other._value)
        case let other as NSObject:
            return self === other
        default:
            return false
        }
    }
    
    override var hash: Int {
        return _value.hash
    }
}
