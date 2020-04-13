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
    
    fileprivate enum NSCodingKeys {
        static let lengthKey = "NSIndexPathLength"
        static let singleValueKey = "NSIndexPathValue"
        static let dataKey = "NSIndexPathData"
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            aCoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Cannot be serialized with a coder that does not support keyed archives"]))
            return
        }
        
        let length = self.length
        aCoder.encode(length, forKey: NSCodingKeys.lengthKey)
        switch length {
        case 0:
            break
        case 1:
            aCoder.encode(index(atPosition: 0), forKey: NSCodingKeys.singleValueKey)
        default:
            var sequence = PackedUIntSequence(data: Data(capacity: length * 2 + 16))
            for position in 0 ..< length {
                sequence.append(UInt(index(atPosition: position)))
            }
            aCoder.encode(sequence.data, forKey: NSCodingKeys.dataKey)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Cannot be deserialized with a coder that does not support keyed archives"]))
            return nil
        }
        
        guard aDecoder.containsValue(forKey: NSCodingKeys.lengthKey) else {
            aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Decoder did not provide a length value for the indexPath."]))
            return nil
        }
        
        let len = aDecoder.decodeInteger(forKey: NSCodingKeys.lengthKey)
        guard len > 0 else {
            self.init()
            return
        }
        
        switch len {
        case 0:
            self.init()
            return
            
        case 1:
            guard aDecoder.containsValue(forKey: NSCodingKeys.singleValueKey) else {
                aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Decoder did not provide indexPath data."]))
                return nil
            }
            
            let index = aDecoder.decodeInteger(forKey: NSCodingKeys.singleValueKey)
            self.init(index: index)
            return
            
        default:
            guard let bytes = aDecoder.decodeObject(of: NSData.self, forKey: NSCodingKeys.dataKey) else {
                aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Range data missing."]))
                return nil
            }
            
            let sequence = PackedUIntSequence(data: bytes._swiftObject)
            guard sequence.count == len else {
                aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: [NSLocalizedDescriptionKey: "Range data did not match expected length."]))
                return nil
            }
            
            self.init(indexes: sequence.integers)
        }
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
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
    
    open override var hash: Int {
        var hasher = Hasher()
        for i in 0 ..< length {
            hasher.combine(index(atPosition: i))
        }
        return hasher.finalize()
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let indexPath = object as? NSIndexPath,
              indexPath.length == self.length else { return false }
        
        let length = self.length
        for i in 0 ..< length {
            if index(atPosition: i) != indexPath.index(atPosition: i) {
                return false
            }
        }
        
        return true
    }
}


extension NSIndexPath : _StructTypeBridgeable {
    public typealias _StructType = IndexPath
    
    public func _bridgeToSwift() -> IndexPath {
        return IndexPath._unconditionallyBridgeFromObjectiveC(self)
    }
}

extension NSIndexPath : _SwiftBridgeable {
    var _swiftObject: IndexPath {
        return _bridgeToSwift()
    }
}

