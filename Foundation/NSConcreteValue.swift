// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
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
                let scanner = Scanner(string: spec)
                
                scanner.scanLocation = 1
                
                guard scanner.scanInt(&count) && count > 0 else {
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
    private var _storage : UnsafeMutableRawPointer
      
    required init(bytes value: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        let spec = String(cString: type)
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

        self._storage = UnsafeMutableRawPointer.allocate(byteCount: self._typeInfo.size, alignment: 1)
        self._storage.copyMemory(from: value, byteCount: self._typeInfo.size)
    }

    deinit {
        // Cannot deinitialize raw memory.
        self._storage.deallocate()
    }
    
    override func getValue(_ value: UnsafeMutableRawPointer) {
        value.copyMemory(from: self._storage, byteCount: self._size)
    }
    
    override var objCType : UnsafePointer<Int8> {
        return NSString(self._typeInfo.name).utf8String! // XXX leaky
    }
    
    override var classForCoder: AnyClass {
        return NSValue.self
    }
    
    override var description : String {
        let boundBytes = self.value.bindMemory(to: UInt8.self, capacity: self._size)
        return Data(bytes: boundBytes, count: self._size).description
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard let type = aDecoder.decodeObject() as? NSString else {
            return nil
        }

        let typep = type._swiftObject

        // FIXME: This will result in reading garbage memory.
        self.init(bytes: [], objCType: typep)
        aDecoder.decodeValue(ofObjCType: typep, at: self.value)
    }
    
    override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(String(cString: self.objCType)._bridgeToObjectiveC())
        aCoder.encodeValue(ofObjCType: self.objCType, at: self.value)
    }
    
    private var _size : Int {
        return self._typeInfo.size
    }
    
    private var value : UnsafeMutableRawPointer {
        return self._storage
    }
    
    private func _isEqualToValue(_ other: NSConcreteValue) -> Bool {
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
    
    override func isEqual(_ value: Any?) -> Bool {
        guard let other = value as? NSConcreteValue else { return false }
        return self._typeInfo == other._typeInfo && self._isEqualToValue(other)
    }

    override var hash: Int {
        return self._typeInfo.name.hashValue &+
            Int(bitPattern: CFHashBytes(self.value.assumingMemoryBound(to: UInt8.self), self._size))
    }
}

internal func ==(x : NSConcreteValue.TypeInfo, y : NSConcreteValue.TypeInfo) -> Bool {
    return x.name == y.name && x.size == y.size
}
