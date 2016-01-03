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
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal class NSConcreteValue : NSValue {
    
    struct TypeInfo : Equatable {
        let size : Int
        let name : String
        
        init?(objCType spec: String) {
            var size: Int = 0
            var align: Int = 0
            var count : Int = 0
            
            var type = _NSSimpleObjCType(spec)
            guard type != nil else {
                print("NSConcreteValue.TypeInfo: unsupported type encoding spec '\(spec)'")
                return nil
            }
            
            if type == .StructBegin {
                fatalError("NSConcreteValue.TypeInfo: cannot encode structs")
            } else if type == .ArrayBegin {
                let scanner = NSScanner(string: spec)
                
                scanner.scanLocation = 1
                
                guard scanner.scanInteger(&count) && count > 0 else {
                    print("NSConcreteValue.TypeInfo: array count is missing or zero")
                    return nil
                }
                
                guard let elementType = _NSSimpleObjCType(scanner.scanUpToString(String(_NSSimpleObjCType.ArrayEnd))) else {
                    print("NSConcreteValue.TypeInfo: array type is missing")
                    return nil
                }
                
                guard _NSGetSizeAndAlignment(elementType, &size, &align) else {
                    print("NSConcreteValue.TypeInfo: unsupported type encoding spec '\(spec)'")
                    return nil
                }
                
                type = elementType
            }
            
            guard _NSGetSizeAndAlignment(type!, &size, &align) else {
                print("NSConcreteValue.TypeInfo: unsupported type encoding spec '\(spec)'")
                return nil
            }
            
            self.size = count != 0 ? size * count : size
            self.name = spec
        }
    }
    
    private static var _cachedTypeInfo = Dictionary<String, TypeInfo>()
    private static var _cachedTypeInfoLock = NSLock()
    
    private var _typeInfo : TypeInfo
    private var _storage : UnsafeMutablePointer<UInt8>
      
    required init(bytes value: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        let spec = String.fromCString(type)!
        var typeInfo : TypeInfo? = nil

        NSConcreteValue._cachedTypeInfoLock.synchronized {
            typeInfo = NSConcreteValue._cachedTypeInfo[spec]
            if typeInfo == nil {
                typeInfo = TypeInfo(objCType: spec)
                NSConcreteValue._cachedTypeInfo[spec] = typeInfo
            }
        }
        
        guard typeInfo != nil else {
            fatalError("NSConcreteValue.init: failed to initialize from type encoding spec '\(spec)'")
        }

        self._typeInfo = typeInfo!

        self._storage = UnsafeMutablePointer<UInt8>.alloc(self._typeInfo.size)
        if value != nil {
            self._storage.initializeFrom(unsafeBitCast(value, UnsafeMutablePointer<UInt8>.self), count: self._typeInfo.size)
        }
    }

    deinit {
        self._storage.destroy(self._size)
        self._storage.dealloc(self._size)
    }
    
    override func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<UInt8>(value).moveInitializeFrom(unsafeBitCast(self._storage, UnsafeMutablePointer<UInt8>.self), count: self._size)
    }
    
    override var objCType : UnsafePointer<Int8> {
        return NSString(self._typeInfo.name).UTF8String // XXX leaky
    }
    
    override var classForCoder: AnyClass {
        return NSValue.self
    }
    
    override var description : String {
        return NSData.init(bytes: self.value, length: self._size).description
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            NSUnimplemented()
        } else {
            guard let type = aDecoder.decodeObject() as? NSString else {
                return nil
            }
            
            let typep = type._swiftObject
            
            self.init(bytes: nil, objCType: typep)
            aDecoder.decodeValueOfObjCType(typep, at: self.value)
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        if !aCoder.allowsKeyedCoding {
            NSUnimplemented()
        } else {
            aCoder.encodeObject(String.fromCString(self.objCType)!.bridge())
            aCoder.encodeValueOfObjCType(self.objCType, at: self.value)
        }
    }
    
    private var _size : Int {
        return self._typeInfo.size
    }
    
    private var value : UnsafeMutablePointer<Void> {
        return unsafeBitCast(self._storage, UnsafeMutablePointer<Void>.self)
    }
    
    private func _isEqualToValue(other: NSConcreteValue) -> Bool {
        if self === other {
            return true
        }
        
        if self._size != other._size {
            return false
        }
        
        let bytes1 = self.value
        let bytes2 = other.value
        if bytes1 == bytes2 {
            return true
        }
        
        return memcmp(bytes1, bytes2, self._size) == 0
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? NSConcreteValue {
            return self._typeInfo == other._typeInfo &&
                   self._isEqualToValue(other)
        } else {
            return false
        }
    }

    override var hash: Int {
        return self._typeInfo.name.hashValue &+
            Int(bitPattern: CFHashBytes(unsafeBitCast(self.value, UnsafeMutablePointer<UInt8>.self), self._size))
    }
}

internal func ==(x : NSConcreteValue.TypeInfo, y : NSConcreteValue.TypeInfo) -> Bool {
    return x.name == y.name && x.size == y.size
}
