// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSValue : NSObject, NSCopying, NSSecureCoding, NSCoding {

    private static var SideTable = [ObjectIdentifier : NSValue]()
    private static var SideTableLock = NSLock()

    internal override init() {
        super.init()
        // on Darwin [NSValue new] returns nil
    }
    
    // because we cannot support the class cluster pattern owing to a lack of
    // factory initialization methods, we maintain a sidetable mapping instances
    // of NSValue to NSConcreteValue
    internal var _concreteValue: NSValue {
        get {
            return NSValue.SideTableLock.synchronized {
                return NSValue.SideTable[ObjectIdentifier(self)]!
            }
        }
        set {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)] = newValue
            }
        }
    }
    
    deinit {
        if self.dynamicType == NSValue.self {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)] = nil
            }
        }
    }
    
    public override var hash: Int {
        get {
            if self.dynamicType == NSValue.self {
                return _concreteValue.hash
            } else {
                return super.hash
            }
        }
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if self === object {
            return true
        } else if self.dynamicType == NSValue.self && object?.dynamicType == NSValue.self {
            // bypass _concreteValue accessor in order to avoid acquiring lock twice
            let (lhs, rhs) = NSValue.SideTableLock.synchronized {
                return (NSValue.SideTable[ObjectIdentifier(self)]!,
                        NSValue.SideTable[ObjectIdentifier(object!)]!)
            }
            return lhs.isEqual(rhs)
        } else {
            return super.isEqual(object)
        }
    }
    
    public override var description : String {
        get {
            if self.dynamicType == NSValue.self {
                return _concreteValue.description
            } else {
                return super.description
            }
        }
    }
    
    public func getValue(value: UnsafeMutablePointer<Void>) {
        if self.dynamicType == NSValue.self {
            return _concreteValue.getValue(value)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public var objCType: UnsafePointer<Int8> {
        if self.dynamicType == NSValue.self {
            return _concreteValue.objCType
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    private static func _isSpecialObjCType(type: UnsafePointer<Int8>) -> Bool {
        return NSSpecialValue._typeFromObjCType(type) != nil
    }
    
    public convenience required init(bytes value: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        if self.dynamicType == NSValue.self {
            self.init()
            if NSValue._isSpecialObjCType(type) {
                self._concreteValue = NSSpecialValue(bytes: unsafeBitCast(value, UnsafePointer<UInt8>.self), objCType: type)
            } else {
                self._concreteValue = NSConcreteValue(bytes: unsafeBitCast(value, UnsafePointer<UInt8>.self), objCType: type)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if self.dynamicType == NSValue.self {
            self.init()
            
            var concreteValue : NSValue? = nil
            
            if aDecoder.containsValueForKey("NS.special") {
                // It's unfortunate that we can't specialise types at runtime
                concreteValue = NSSpecialValue(coder: aDecoder)
            } else {
                concreteValue = NSConcreteValue(coder: aDecoder)
            }
            
            guard concreteValue != nil else {
                return nil
            }
            
            self._concreteValue = concreteValue!
        } else {
            NSRequiresConcreteImplementation()
        }
    }
        
    public func encodeWithCoder(aCoder: NSCoder) {
        if self.dynamicType == NSValue.self {
            _concreteValue.encodeWithCoder(aCoder)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public class func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
}

