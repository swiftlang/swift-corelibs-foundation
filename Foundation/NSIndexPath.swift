// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSIndexPath : NSObject, NSCopying, NSSecureCoding {
    
    internal var _indexes : [Int]
    override public init() {
        _indexes = []
    }
    public init(indexes: UnsafePointer<Int>, length: Int) {
        _indexes = Array(UnsafeBufferPointer(start: indexes, count: length))
    }
    
    private init(indexes: [Int]) {
        _indexes = indexes
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject { NSUnimplemented() }
    public convenience init(index: Int) {
        self.init(indexes: [index])
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public static func supportsSecureCoding() -> Bool { return true }
    
    public func indexPathByAddingIndex(index: Int) -> NSIndexPath {
        return NSIndexPath(indexes: _indexes + [index])
    }
    public func indexPathByRemovingLastIndex() -> NSIndexPath {
        if _indexes.count <= 1 {
            return NSIndexPath(indexes: [])
        } else {
            return NSIndexPath(indexes: [Int](_indexes[0..<_indexes.count - 1]))
        }
    }
    
    public func indexAtPosition(position: Int) -> Int {
        return _indexes[position]
    }
    public var length: Int  {
        return _indexes.count
    }
    
    /*!
     @abstract Copies the indexes stored in this index path from the positions specified by positionRange into indexes.
     @param indexes Buffer of at least as many NSUIntegers as specified by the length of positionRange. On return, this memory will hold the index path's indexes.
     @param positionRange A range of valid positions within this index path.  If the location plus the length of positionRange is greater than the length of this index path, this method raises an NSRangeException.
     @discussion
        It is the developer’s responsibility to allocate the memory for the C array.
     */
    public func getIndexes(indexes: UnsafeMutablePointer<Int>, range positionRange: NSRange) {
        for (pos, idx) in _indexes[positionRange.location ..< NSMaxRange(positionRange)].enumerate() {
            indexes.advancedBy(pos).memory = idx
        }
    }
    
    // comparison support
    // sorting an array of indexPaths using this comparison results in an array representing nodes in depth-first traversal order
    public func compare(otherObject: NSIndexPath) -> NSComparisonResult {
        let thisLength = length
        let otherLength = otherObject.length
        let minLength = thisLength >= otherLength ? otherLength : thisLength
        for pos in 0..<minLength {
            let otherValue = otherObject.indexAtPosition(pos)
            let thisValue = indexAtPosition(pos)
            if thisValue < otherValue {
                return .OrderedAscending
            } else if thisValue > otherValue {
                return .OrderedDescending
            }
        }
        if thisLength > otherLength {
            return .OrderedDescending
        } else if thisLength < otherLength {
            return .OrderedAscending
        }
        return .OrderedSame
    }
}
