// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class NSIndexPath : NSObject, NSCopying, NSSecureCoding {
    
    private var _indexes : [Int]

    override public init() {
        _indexes = []
    }

    public init(indexes: UnsafePointer<Int>?, length: Int) {
        if length == 0 {
            _indexes = []
        } else {
            _indexes = Array(UnsafeBufferPointer(start: indexes!, count: length))
        }
    }
    
    private init(indexes: [Int]) {
        _indexes = indexes
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    public convenience init(index: Int) {
        self.init(indexes: [index])
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        func readElement(_ data: inout Data, from byteIdx: inout Int) -> Int {
            var result: UInt = 0
            while data[byteIdx] > 127 {
                result = result << 7 + UInt(data[byteIdx])
                byteIdx += 1
            }
            result = result << 7 + UInt(data[byteIdx])
            byteIdx += 1
            return Int(bitPattern: result)
        }
        
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        guard aDecoder.containsValue(forKey: "NSIndexPathLength") else {
            let error = CocoaError.error(.coderReadCorrupt, userInfo: [NSLocalizedDescriptionKey:
                                            "-[NSIndexPath initWithCoder:] decoder did not provide a length value for the indexPath."])
            aDecoder.failWithError(error)
            return nil
        }
        let length = aDecoder.decodeInteger(forKey: "NSIndexPathLength")
        
        if length == 0 {
            _indexes = []
            return
        }
        
        if length > 1, var data = aDecoder.decodeObject(of: NSData.self, forKey: "NSIndexPathData")?._swiftObject {
            _indexes = []
            var byteIdx = 0
            while byteIdx < data.count {
                let element = readElement(&data, from: &byteIdx)
                _indexes.append(element)
            }
        } else if length == 1 && aDecoder.containsValue(forKey: "NSIndexPathValue") {
            _indexes = [aDecoder.decodeInteger(forKey: "NSIndexPathValue")]
        } else {
            let error = CocoaError.error(.coderReadCorrupt, userInfo: [NSLocalizedDescriptionKey:
                                            "-[NSIndexPath initWithCoder:] decoder did not provide indexPath data."])
            aDecoder.failWithError(error)
            return nil
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        func appendUInt(_ value: UInt, data: inout Data) {
            var value = value
            while value >= 128 {
                let byte = UInt8(value & 0x7f + 128)
                data.append(byte)
                value /= 128
            }
            data.append(UInt8(value))
        }
        
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        aCoder.encode(length, forKey: "NSIndexPathLength")
        switch length {
        case 0:
            break
        case 1:
            aCoder.encode(_indexes[0], forKey: "NSIndexPathValue")
        default:
            var data = Data()
            for index in _indexes {
                appendUInt(UInt(bitPattern: index), data: &data)
            }
            aCoder.encode(data._bridgeToObjectiveC().mutableCopy(), forKey: "NSIndexPathData")
        }
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NSIndexPath {
            return self._indexes == object._indexes
        }
        return false
    }
    
    open func adding(_ index: Int) -> IndexPath {
        return IndexPath(indexes: _indexes + [index])
    }

    open func removingLastIndex() -> IndexPath {
        if _indexes.count <= 1 {
            return IndexPath(indexes: [])
        } else {
            return IndexPath(indexes: [Int](_indexes[0..<_indexes.count - 1]))
        }
    }
    
    open func index(atPosition position: Int) -> Int {
        return _indexes[position]
    }

    open var length: Int {
        return _indexes.count
    }
    
    /*!
     @abstract Copies the indexes stored in this index path from the positions specified by positionRange into indexes.
     @param indexes Buffer of at least as many NSUIntegers as specified by the length of positionRange. On return, this memory will hold the index path's indexes.
     @param positionRange A range of valid positions within this index path.  If the location plus the length of positionRange is greater than the length of this index path, this method raises an NSRangeException.
     @discussion
        It is the developer’s responsibility to allocate the memory for the C array.
     */
    open func getIndexes(_ indexes: UnsafeMutablePointer<Int>, range positionRange: NSRange) {
        for (pos, idx) in _indexes[positionRange.location ..< NSMaxRange(positionRange)].enumerated() {
            indexes.advanced(by: pos).pointee = idx
        }
    }

    @available(*, unavailable, renamed: "getIndex(_:range:)")
    open func getIndexes(_ indexes: UnsafeMutablePointer<Int>) {
        NSUnsupported()
    }

    // comparison support
    // sorting an array of indexPaths using this comparison results in an array representing nodes in depth-first traversal order
    open func compare(_ otherObject: IndexPath) -> ComparisonResult {
        let thisLength = length
        let otherLength = otherObject.count
        let minLength = thisLength >= otherLength ? otherLength : thisLength
        for pos in 0..<minLength {
            let otherValue = otherObject[pos]
            let thisValue = index(atPosition: pos)
            if thisValue < otherValue {
                return .orderedAscending
            } else if thisValue > otherValue {
                return .orderedDescending
            }
        }
        if thisLength > otherLength {
            return .orderedDescending
        } else if thisLength < otherLength {
            return .orderedAscending
        }
        return .orderedSame
    }
}


extension NSIndexPath : _StructTypeBridgeable {
    public typealias _StructType = IndexPath
    
    public func _bridgeToSwift() -> IndexPath {
        return IndexPath._unconditionallyBridgeFromObjectiveC(self)
    }
}
