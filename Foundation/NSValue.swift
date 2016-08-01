// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

open class NSValue : NSObject, NSCopying, NSSecureCoding, NSCoding {

    private static var SideTable = [ObjectIdentifier : NSValue]()
    private static var SideTableLock = Lock()

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
        if type(of: self) == NSValue.self {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)] = nil
            }
        }
    }
    
    open override var hash: Int {
        get {
            if type(of: self) == NSValue.self {
                return _concreteValue.hash
            } else {
                return super.hash
            }
        }
    }
    
    open override func isEqual(_ object: AnyObject?) -> Bool {
        if self === object {
            return true
        } else if let o = object, type(of: self) == NSValue.self && type(of: o) == NSValue.self {
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
    
    open override var description : String {
        get {
            if type(of: self) == NSValue.self {
                return _concreteValue.description
            } else {
                return super.description
            }
        }
    }
    
    open func getValue(_ value: UnsafeMutableRawPointer) {
        if type(of: self) == NSValue.self {
            return _concreteValue.getValue(value)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open var objCType: UnsafePointer<Int8> {
        if type(of: self) == NSValue.self {
            return _concreteValue.objCType
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    private static func _isSpecialObjCType(_ type: UnsafePointer<Int8>) -> Bool {
        return NSSpecialValue._typeFromObjCType(type) != nil
    }
    
    public convenience required init(bytes value: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        if type(of: self) == NSValue.self {
            self.init()
            if NSValue._isSpecialObjCType(type) {
                self._concreteValue = NSSpecialValue(bytes: unsafeBitCast(value, to: UnsafePointer<UInt8>.self), objCType: type)
            } else {
                self._concreteValue = NSConcreteValue(bytes: unsafeBitCast(value, to: UnsafePointer<UInt8>.self), objCType: type)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if type(of: self) == NSValue.self {
            self.init()
            
            var concreteValue : NSValue? = nil
            
            if aDecoder.containsValue(forKey: "NS.special") {
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
        
    open func encode(with aCoder: NSCoder) {
        if type(of: self) == NSValue.self {
            _concreteValue.encode(with: aCoder)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    open class func supportsSecureCoding() -> Bool {
        return true
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        return self
    }
}

