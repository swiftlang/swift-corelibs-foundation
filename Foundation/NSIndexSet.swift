// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/* Class for managing set of indexes. The set of valid indexes are 0 .. NSNotFound - 1; trying to use indexes outside this range is an error.  NSIndexSet uses NSNotFound as a return value in cases where the queried index doesn't exist in the set; for instance, when you ask firstIndex and there are no indexes; or when you ask for indexGreaterThanIndex: on the last index, and so on.

The following code snippets can be used to enumerate over the indexes in an NSIndexSet:

    // Forward
    var currentIndex = set.firstIndex
    while currentIndex != NSNotFound {
        ...
        currentIndex = set.indexGreaterThanIndex(currentIndex)
    }

    // Backward
    var currentIndex = set.lastIndex
    while currentIndex != NSNotFound {
        ...
        currentIndex = set.indexLessThanIndex(currentIndex)
    }

To enumerate without doing a call per index, you can use the method getIndexes:maxCount:inIndexRange:.
*/

internal func __NSIndexSetRangeCount(_ indexSet: NSIndexSet) -> UInt {
    return UInt(indexSet._ranges.count)
}

internal func __NSIndexSetRangeAtIndex(_ indexSet: NSIndexSet, _ index: UInt, _ location : UnsafeMutablePointer<UInt>, _ length : UnsafeMutablePointer<UInt>) {
//    if Int(index) >= indexSet._ranges.count {
//        location.pointee = UInt(bitPattern: NSNotFound)
//        length.pointee = UInt(0)
//        return
//    }
    let range = indexSet._ranges[Int(index)]
    location.pointee = UInt(range.location)
    length.pointee = UInt(range.length)
}

internal func __NSIndexSetIndexOfRangeContainingIndex(_ indexSet: NSIndexSet, _ index: UInt) -> UInt {
    var idx = 0
    while idx < indexSet._ranges.count {
        let range = indexSet._ranges[idx]
        if range.location <= Int(index) && Int(index) <= range.location + range.length {
            return UInt(idx)
        }
        idx += 1
    }
    return UInt(bitPattern: NSNotFound)
}

public class NSIndexSet: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    // all instance variables are private
    
    internal var _ranges = [NSRange]()
    internal var _count = 0
    override public init() {
        _count = 0
        _ranges = []
    }
    public init(indexesIn range: NSRange) {
        _count = range.length
        _ranges = _count == 0 ? [] : [range]
    }
    public init(indexSet: IndexSet) {
        _ranges = indexSet.rangeView().map { NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound) }
        _count = indexSet.count
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject  { NSUnimplemented() }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopy(with: nil)
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> AnyObject {
        let set = NSMutableIndexSet()
        enumerateRanges([]) {
            set.add(in: $0.0)
        }
        return set
    }
    public static func supportsSecureCoding() -> Bool { return true }
    public required init?(coder aDecoder: NSCoder)  { NSUnimplemented() }
    public func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public convenience init(index value: Int) {
        self.init(indexesIn: NSMakeRange(value, 1))
    }
    
    public func isEqual(to indexSet: IndexSet) -> Bool {
        
        let otherRanges = indexSet.rangeView().map { NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound) }
        if _ranges.count != otherRanges.count {
            return false
        }
        for (r1, r2) in zip(_ranges, otherRanges) {
            if r1.length != r2.length || r1.location != r2.location {
                return false
            }
        }
        return true
    }
    
    public var count: Int {
        return _count
    }
    
    /* The following six methods will return NSNotFound if there is no index in the set satisfying the query. 
    */
    public var firstIndex: Int {
        return _ranges.first?.location ?? NSNotFound
    }
    public var lastIndex: Int {
        guard _ranges.count > 0 else {
            return NSNotFound
        }
        return NSMaxRange(_ranges.last!) - 1
    }
    
    internal func _indexAndRangeAdjacentToOrContainingIndex(_ idx : Int) -> (Int, NSRange)? {
        let count = _ranges.count
        guard count > 0 else {
            return nil
        }
        
        var min = 0
        var max = count - 1
        while min < max {
            let rIdx = (min + max) / 2
            let range = _ranges[rIdx]
            if range.location > idx {
                max = rIdx
            } else if NSMaxRange(range) - 1 < idx {
                min = rIdx + 1
            } else {
                return (rIdx, range)
            }
        }
        return (min, _ranges[min])
    }
    
    internal func _indexOfRangeContainingIndex (_ idx : Int) -> Int? {
        if let (rIdx, range) = _indexAndRangeAdjacentToOrContainingIndex(idx) {
            return NSLocationInRange(idx, range) ? rIdx : nil
        } else {
            return nil
        }
    }
    
    internal func _indexOfRangeBeforeOrContainingIndex(_ idx : Int) -> Int? {
        if let (rIdx, range) = _indexAndRangeAdjacentToOrContainingIndex(idx) {
            if range.location <= idx {
                return rIdx
            } else if rIdx > 0 {
                return rIdx - 1
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    internal func _indexOfRangeAfterOrContainingIndex(_ idx : Int) -> Int? {
        if let (rIdx, range) = _indexAndRangeAdjacentToOrContainingIndex(idx) {
            if NSMaxRange(range) - 1 >= idx {
                return rIdx
            } else if rIdx + 1 < _ranges.count {
                return rIdx + 1
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    internal func _indexClosestToIndex(_ idx: Int, equalAllowed : Bool, following: Bool) -> Int? {
        guard _count > 0 else {
            return nil
        }
        
        if following {
            var result = idx
            if !equalAllowed {
                guard idx < NSNotFound else {
                    return nil
                }
                result += 1
            }
            
            if let rangeIndex = _indexOfRangeAfterOrContainingIndex(result) {
                let range = _ranges[rangeIndex]
                return NSLocationInRange(result, range) ? result : range.location
            }
        } else {
            var result = idx
            if !equalAllowed {
                guard idx > 0 else {
                    return nil
                }
                result -= 1
            }
            
            if let rangeIndex = _indexOfRangeBeforeOrContainingIndex(result) {
                let range = _ranges[rangeIndex]
                return NSLocationInRange(result, range) ? result : (NSMaxRange(range) - 1)
            }
        }
        return nil
    }
    
    public func indexGreaterThanIndex(_ value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: false, following: true) ?? NSNotFound
    }
    public func indexLessThanIndex(_ value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: false, following: false) ?? NSNotFound
    }
    public func indexGreaterThanOrEqual(to value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: true, following: true) ?? NSNotFound
    }
    public func indexLessThanOrEqual(to value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: true, following: false) ?? NSNotFound
    }
    
    /* Fills up to bufferSize indexes in the specified range into the buffer and returns the number of indexes actually placed in the buffer; also modifies the optional range passed in by pointer to be "positioned" after the last index filled into the buffer.Example: if the index set contains the indexes 0, 2, 4, ..., 98, 100, for a buffer of size 10 and the range (20, 80) the buffer would contain 20, 22, ..., 38 and the range would be modified to (40, 60).
    */
    public func getIndexes(_ indexBuffer: UnsafeMutablePointer<Int>, maxCount bufferSize: Int, inIndexRange range: NSRangePointer?) -> Int {
        let minIndex : Int
        let maxIndex : Int
        if let initialRange = range {
            minIndex = initialRange.pointee.location
            maxIndex = NSMaxRange(initialRange.pointee) - 1
        } else {
            minIndex = firstIndex
            maxIndex = lastIndex
        }
        guard minIndex <= maxIndex else {
            return 0
        }
        
        if let initialRangeIndex = self._indexOfRangeAfterOrContainingIndex(minIndex) {
            var rangeIndex = initialRangeIndex
            let rangeCount = _ranges.count
            var counter = 0
            var idx = minIndex
            var offset = 0
            while rangeIndex < rangeCount && idx <= maxIndex && counter < bufferSize {
                let currentRange = _ranges[rangeIndex]
                if currentRange.location <= minIndex {
                    idx = minIndex
                    offset = minIndex - currentRange.location
                } else {
                    idx = currentRange.location
                }
                
                while idx <= maxIndex && counter < bufferSize && offset < currentRange.length {
                    indexBuffer.advanced(by: counter).pointee = idx
                    counter += 1
                    idx += 1
                    offset += 1
                }
                if offset >= currentRange.length {
                    rangeIndex += 1
                    offset = 0
                }
            }
            
            if counter > 0, let resultRange = range {
                let delta = indexBuffer.advanced(by: counter - 1).pointee - minIndex + 1
                resultRange.pointee.location += delta
                resultRange.pointee.length -= delta
            }
            return counter
        } else {
            return 0
        }
    }
    
    public func countOfIndexes(in range: NSRange) -> Int {
        guard _count > 0 && range.length > 0 else {
            return 0
        }
        
        if let initialRangeIndex = self._indexOfRangeAfterOrContainingIndex(range.location) {
            var rangeIndex = initialRangeIndex
            let maxRangeIndex = NSMaxRange(range) - 1
            
            var result = 0
            let firstRange = _ranges[rangeIndex]
            if firstRange.location < range.location {
                if NSMaxRange(firstRange) - 1 >= maxRangeIndex {
                    return range.length
                }
                result = NSMaxRange(firstRange) - range.location
                rangeIndex += 1
            }
            
            for curRange in _ranges.suffix(from: rangeIndex) {
                if NSMaxRange(curRange) - 1 > maxRangeIndex {
                    if curRange.location <= maxRangeIndex {
                        result += maxRangeIndex + 1 - curRange.location
                    }
                    break
                }
                result += curRange.length
            }
            return result
        } else {
            return 0
        }
    }
    
    public func contains(_ value: Int) -> Bool {
        return _indexOfRangeContainingIndex(value) != nil
    }
    public func contains(in range: NSRange) -> Bool {
        guard range.length > 0 else {
            return false
        }
        if let rIdx = self._indexOfRangeContainingIndex(range.location) {
            return NSMaxRange(_ranges[rIdx]) >= NSMaxRange(range)
        } else {
            return false
        }
    }
    public func contains(_ indexSet: IndexSet) -> Bool {
        var result = true
        enumerateRanges([]) { range, stop in
            if !self.contains(in: range) {
                result = false
                stop.pointee = true
            }
        }
        return result
    }
    
    public func intersects(in range: NSRange) -> Bool {
        guard range.length > 0 else {
            return false
        }
        
        if let rIdx = _indexOfRangeBeforeOrContainingIndex(range.location) {
            if NSMaxRange(_ranges[rIdx]) - 1 >= range.location {
                return true
            }
        }
        if let rIdx = _indexOfRangeAfterOrContainingIndex(range.location) {
            if NSMaxRange(range) - 1 >= _ranges[rIdx].location {
                return true
            }
        }
        return false
    }
    
    internal func _enumerateWithOptions<P, R>(_ opts : EnumerationOptions, range: NSRange, paramType: P.Type, returnType: R.Type, block: @noescape (P, UnsafeMutablePointer<ObjCBool>) -> R) -> Int? {
        guard !opts.contains(.concurrent) else {
            NSUnimplemented()
        }
        
        guard let startRangeIndex = self._indexOfRangeAfterOrContainingIndex(range.location), let endRangeIndex = _indexOfRangeBeforeOrContainingIndex(NSMaxRange(range) - 1) else {
            return nil
        }

        var result : Int? = nil
        let reverse = opts.contains(.reverse)
        let passRanges = paramType == NSRange.self
        let findIndex = returnType == Bool.self
        var stop = false
        let ranges = _ranges[startRangeIndex...endRangeIndex]
        let rangeSequence = (reverse ? AnySequence(ranges.reversed()) : AnySequence(ranges))
        outer: for curRange in rangeSequence {
            let intersection = NSIntersectionRange(curRange, range)
            if passRanges {
                if intersection.length > 0 {
                    let _ = block(intersection as! P, &stop)
                }
                if stop {
                    break outer
                }
            } else if intersection.length > 0 {
                let maxIndex = NSMaxRange(intersection) - 1
                let indexes = reverse ? stride(from: maxIndex, through: intersection.location, by: -1) : stride(from: intersection.location, through: maxIndex, by: 1)
                for idx in indexes {
                    if findIndex {
                        let found : Bool = block(idx as! P, &stop) as! Bool
                        if found {
                            result = idx
                            stop = true
                        }
                    } else {
                        let _ = block(idx as! P, &stop)
                    }
                    if stop {
                        break outer
                    }
                }
            } // else, continue
        }
        
        return result
    }

    public func enumerate(_ block: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerate([], using: block)
    }
    public func enumerate(_ opts: EnumerationOptions = [], using block: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: NSMakeRange(0, Int.max), paramType: Int.self, returnType: Void.self, block: block)
    }
    public func enumerate(in range: NSRange, options opts: EnumerationOptions = [], using block: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: range, paramType: Int.self, returnType: Void.self, block: block)
    }

    public func index(passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return index([], passingTest: predicate)
    }
    public func index(_ opts: EnumerationOptions = [], passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _enumerateWithOptions(opts, range: NSMakeRange(0, Int.max), paramType: Int.self, returnType: Bool.self, block: predicate) ?? NSNotFound
    }
    public func index(in range: NSRange, options opts: EnumerationOptions = [], passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _enumerateWithOptions(opts, range: range, paramType: Int.self, returnType: Bool.self, block: predicate) ?? NSNotFound
    }
    
    public func indexes(passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexes(in: NSMakeRange(0, Int.max), options: [], passingTest: predicate)
    }
    public func indexes(_ opts: EnumerationOptions = [], passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexes(in: NSMakeRange(0, Int.max), options: opts, passingTest: predicate)
    }
    public func indexes(in range: NSRange, options opts: EnumerationOptions = [], passingTest predicate: @noescape (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        var result = IndexSet()
        let _ = _enumerateWithOptions(opts, range: range, paramType: Int.self, returnType: Void.self) { idx, stop in
            if predicate(idx, stop) {
                result.insert(idx)
            }
        }
        return result
    }

    /*
     The following three convenience methods allow you to enumerate the indexes in the receiver by ranges of contiguous indexes. The performance of these methods is not guaranteed to be any better than if they were implemented with enumerateIndexesInRange:options:usingBlock:. However, depending on the receiver's implementation, they may perform better than that.

     If the specified range for enumeration intersects a range of contiguous indexes in the receiver, then the block will be invoked with the intersection of those two ranges.
    */
    public func enumerateRanges(_ block: @noescape (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateRanges([], using: block)
    }
    public func enumerateRanges(_ opts: EnumerationOptions = [], using block: @noescape (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: NSMakeRange(0, Int.max), paramType: NSRange.self, returnType: Void.self, block: block)
    }
    public func enumerateRanges(in range: NSRange, options opts: EnumerationOptions = [], using block: @noescape (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: range, paramType: NSRange.self, returnType: Void.self, block: block)
    }
}

extension NSIndexSet: Sequence {

    public struct Iterator : IteratorProtocol {
        internal let _set: NSIndexSet
        internal var _first: Bool = true
        internal var _current: Int?
        
        internal init(_ set: NSIndexSet) {
            self._set = set
            self._current = nil
        }
        
        public mutating func next() -> Int? {
            if _first {
                _current = _set.firstIndex
                _first = false
            } else if let c = _current {
                _current = _set.indexGreaterThanIndex(c)
            }
            if _current == NSNotFound {
                _current = nil
            }
            return _current
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }

}

public class NSMutableIndexSet : NSIndexSet {
    
    public func add(_ indexSet: IndexSet) {
        indexSet.rangeView().forEach { add(in: NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound)) }
    }
    
    public func remove(_ indexSet: IndexSet) {
        indexSet.rangeView().forEach { remove(in: NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound)) }
    }
    
    public func removeAllIndexes() {
        _ranges = []
        _count = 0
    }
    
    public func add(_ value: Int) {
        add(in: NSMakeRange(value, 1))
    }
    
    public func remove(_ value: Int) {
        remove(in: NSMakeRange(value, 1))
    }
    
    internal func _insertRange(_ range: NSRange, atIndex index: Int) {
        _ranges.insert(range, at: index)
        _count += range.length
    }
    
    internal func _replaceRangeAtIndex(_ index: Int, withRange range: NSRange?) {
        let oldRange = _ranges[index]
        if let range = range {
            _ranges[index] = range
            _count += range.length - oldRange.length
        } else {
            _ranges.remove(at: index)
            _count -= oldRange.length
        }
    }
    
    internal func _mergeOverlappingRangesStartingAtIndex(_ index: Int) {
        var rangeIndex = index
        while _ranges.count > 0 && rangeIndex < _ranges.count - 1 {
            let curRange = _ranges[rangeIndex]
            let nextRange = _ranges[rangeIndex + 1]
            let curEnd = NSMaxRange(curRange)
            let nextEnd = NSMaxRange(nextRange)
            if curEnd >= nextRange.location {
                // overlaps
                if curEnd < nextEnd {
                    self._replaceRangeAtIndex(rangeIndex, withRange: NSMakeRange(nextEnd - curRange.location, curRange.length))
                    rangeIndex += 1
                }
                self._replaceRangeAtIndex(rangeIndex + 1, withRange: nil)
            } else {
                break
            }
        }
    }
    
    public func add(in range: NSRange) {
        guard range.length > 0 else {
            return
        }
        let addEnd = NSMaxRange(range)
        let startRangeIndex = _indexOfRangeBeforeOrContainingIndex(range.location) ?? 0
        var replacedRangeIndex : Int?
        var rangeIndex = startRangeIndex
        while rangeIndex < _ranges.count {
            let curRange = _ranges[rangeIndex]
            let curEnd = NSMaxRange(curRange)
            if addEnd < curRange.location {
                _insertRange(range, atIndex: rangeIndex)
                // Done. No need to merge
                return
            } else if range.location < curRange.location && addEnd >= curRange.location {
                if addEnd > curEnd {
                    _replaceRangeAtIndex(rangeIndex, withRange: range)
                } else {
                    _replaceRangeAtIndex(rangeIndex, withRange: NSMakeRange(range.location, curEnd - range.location))
                }
                replacedRangeIndex = rangeIndex
                // Proceed to merging
                break
            } else if range.location >= curRange.location && addEnd < curEnd {
                // Nothing to add
                return
            } else if range.location >= curRange.location && range.location <= curEnd && addEnd > curEnd {
                _replaceRangeAtIndex(rangeIndex, withRange: NSMakeRange(curRange.location, addEnd - curRange.location))
                replacedRangeIndex = rangeIndex
                // Proceed to merging
                break
            }
            rangeIndex += 1
        }
        if let r = replacedRangeIndex {
            _mergeOverlappingRangesStartingAtIndex(r)
        } else {
            _insertRange(range, atIndex: _ranges.count)
        }
    }
    
    public func remove(in range: NSRange) {
        guard range.length > 0 else {
            return
        }
        guard let startRangeIndex = (range.location > 0) ? _indexOfRangeAfterOrContainingIndex(range.location) : 0 else {
            return
        }
        let removeEnd = NSMaxRange(range)
        var rangeIndex = startRangeIndex
        while rangeIndex < _ranges.count {
            let curRange = _ranges[rangeIndex]
            let curEnd = NSMaxRange(curRange)
            
            if removeEnd < curRange.location {
                // Nothing to remove
                return
            } else if range.location <= curRange.location && removeEnd >= curRange.location {
                if removeEnd >= curEnd {
                    _replaceRangeAtIndex(rangeIndex, withRange: nil)
                    // Don't increment rangeIndex
                    continue
                } else {
                    self._replaceRangeAtIndex(rangeIndex, withRange: NSMakeRange(removeEnd, curEnd - removeEnd))
                    return
                }
            } else if range.location > curRange.location && removeEnd < curEnd {
                let firstPiece = NSMakeRange(curRange.location, range.location - curRange.location)
                let secondPiece = NSMakeRange(removeEnd, curEnd - removeEnd)
                _replaceRangeAtIndex(rangeIndex, withRange: secondPiece)
                _insertRange(firstPiece, atIndex: rangeIndex)
            } else if range.location > curRange.location && range.location < curEnd && removeEnd >= curEnd {
                _replaceRangeAtIndex(rangeIndex, withRange: NSMakeRange(curRange.location, range.location - curRange.location))
            }
            rangeIndex += 1
        }
        
    }
    
    /* For a positive delta, shifts the indexes in [index, INT_MAX] to the right, thereby inserting an "empty space" [index, delta], for a negative delta, shifts the indexes in [index, INT_MAX] to the left, thereby deleting the indexes in the range [index - delta, delta].
    */
    public func shiftIndexesStarting(at index: Int, by delta: Int) { NSUnimplemented() }
}

