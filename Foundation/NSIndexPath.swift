// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class NSIndexPath : NSObject, NSCopying, NSSecureCoding {
    
    internal var _indexes : [Int]
    override public init() {
        _indexes = []
    }
    public init(indexes: UnsafePointer<Int>!, length: Int) {
        _indexes = Array(UnsafeBufferPointer(start: indexes, count: length))
    }
    
    private init(indexes: [Int]) {
        _indexes = indexes
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any { NSUnimplemented() }
    public convenience init(index: Int) {
        self.init(indexes: [index])
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
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

extension NSIndexPath {
    open func getIndexes(_ indexes: UnsafeMutablePointer<Int>) { NSUnimplemented() }
}


extension NSIndexPath : _StructTypeBridgeable {
    public typealias _StructType = IndexPath
    
    public func _bridgeToSwift() -> IndexPath {
        return IndexPath._unconditionallyBridgeFromObjectiveC(self)
    }
}
