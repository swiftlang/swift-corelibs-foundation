// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

open class NSValue : NSObject, NSCopying, NSSecureCoding, NSCoding {
    
    open func getValue(_ value: UnsafeMutableRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    open var objCType: UnsafePointer<Int8> {
        NSRequiresConcreteImplementation()
    }
    
    private static func _isSpecialObjCType(_ type: UnsafePointer<Int8>) -> Bool {
        return NSSpecialValue._typeFromObjCType(type) != nil
    }
    
    public convenience required init(bytes value: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        if Swift.type(of: self) == NSValue.self {
            let concreteValue : NSValue

            if NSValue._isSpecialObjCType(type) {
                concreteValue = NSSpecialValue(bytes: value.assumingMemoryBound(to: UInt8.self), objCType: type)
            } else {
                concreteValue = NSConcreteValue(bytes: value.assumingMemoryBound(to: UInt8.self), objCType: type)
            }
            
            self.init { concreteValue as! Self }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if type(of: self) == NSValue.self {
            let concreteValue : NSValue?
            
            if aDecoder.containsValue(forKey: "NS.special") {
                concreteValue = NSSpecialValue(coder: aDecoder)
            } else {
                concreteValue = NSConcreteValue(coder: aDecoder)
            }
            
            guard concreteValue != nil else {
                return nil
            }
            
            self.init { concreteValue as! Self }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
        
    open func encode(with aCoder: NSCoder) {
        NSRequiresConcreteImplementation()
    }
    
    open class var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

extension NSValue : _Factory {}

internal protocol _Factory {
    init(factory: () -> Self)
}

extension _Factory {
    init(factory: () -> Self) {
        self = factory()
    }
}
