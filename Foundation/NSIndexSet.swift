// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch

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

internal func __NSIndexSetRangeCount(_ indexSet: NSIndexSet) -> Int {
    return indexSet._ranges.count
}

internal func __NSIndexSetRangeAtIndex(_ indexSet: NSIndexSet, _ index: Int, _ location : UnsafeMutablePointer<Int>, _ length : UnsafeMutablePointer<Int>) {
//    if Int(index) >= indexSet._ranges.count {
//        location.pointee = UInt(bitPattern: NSNotFound)
//        length.pointee = UInt(0)
//        return
//    }
    let range = indexSet._ranges[Int(index)]
    location.pointee = range.location
    length.pointee = range.length
}

internal func __NSIndexSetIndexOfRangeContainingIndex(_ indexSet: NSIndexSet, _ index: Int) -> Int {
    var idx = 0
    while idx < indexSet._ranges.count {
        let range = indexSet._ranges[idx]
        if range.location <= index && index <= range.location + range.length {
            return idx
        }
        idx += 1
    }
    return NSNotFound
}

open class NSIndexSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
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
        _ranges = indexSet.rangeView.map { NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound) }
        _count = indexSet.count
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSIndexSet.self {
            // return self for immutable type
            return self
        }
        return NSIndexSet(indexSet: self._bridgeToSwift())
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        let set = NSMutableIndexSet()
        enumerateRanges(options: []) { (range, _) in
            set.add(in: range)
        }
        return set
    }

    public static var supportsSecureCoding: Bool { return true }

    public required init?(coder aDecoder: NSCoder)  { NSUnimplemented() }
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public convenience init(index value: Int) {
        self.init(indexesIn: NSRange(location: value, length: 1))
    }
    
    open func isEqual(to indexSet: IndexSet) -> Bool {
        
        let otherRanges = indexSet.rangeView.map { NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound) }
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
    
    open var count: Int {
        return _count
    }
    
    /* The following six methods will return NSNotFound if there is no index in the set satisfying the query. 
    */
    open var firstIndex: Int {
        return _ranges.first?.location ?? NSNotFound
    }
    open var lastIndex: Int {
        guard !_ranges.isEmpty else {
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
    
    internal func _indexOfRangeContainingIndex(_ idx : Int) -> Int? {
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
    
    open func indexGreaterThanIndex(_ value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: false, following: true) ?? NSNotFound
    }
    open func indexLessThanIndex(_ value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: false, following: false) ?? NSNotFound
    }
    open func indexGreaterThanOrEqual(to value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: true, following: true) ?? NSNotFound
    }
    open func indexLessThanOrEqual(to value: Int) -> Int {
        return _indexClosestToIndex(value, equalAllowed: true, following: false) ?? NSNotFound
    }
    
    /* Fills up to bufferSize indexes in the specified range into the buffer and returns the number of indexes actually placed in the buffer; also modifies the optional range passed in by pointer to be "positioned" after the last index filled into the buffer.Example: if the index set contains the indexes 0, 2, 4, ..., 98, 100, for a buffer of size 10 and the range (20, 80) the buffer would contain 20, 22, ..., 38 and the range would be modified to (40, 60).
    */
    open func getIndexes(_ indexBuffer: UnsafeMutablePointer<Int>, maxCount bufferSize: Int, inIndexRange range: NSRangePointer?) -> Int {
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
    
    open func countOfIndexes(in range: NSRange) -> Int {
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
    
    open func contains(_ value: Int) -> Bool {
        return _indexOfRangeContainingIndex(value) != nil
    }
    open func contains(in range: NSRange) -> Bool {
        guard range.length > 0 else {
            return false
        }
        if let rIdx = self._indexOfRangeContainingIndex(range.location) {
            return NSMaxRange(_ranges[rIdx]) >= NSMaxRange(range)
        } else {
            return false
        }
    }
    open func contains(_ indexSet: IndexSet) -> Bool {
        var result = true
        let nsIndexSet = indexSet._bridgeToObjectiveC()
        nsIndexSet.enumerateRanges(options: []) { range, stop in
            if !self.contains(in: range) {
                result = false
                stop.pointee = true
            }
        }
        return result
    }
    
    open func intersects(in range: NSRange) -> Bool {
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
    
    internal func _enumerateWithOptions<P, R>(_ opts : NSEnumerationOptions, range: NSRange, paramType: P.Type, returnType: R.Type, block: (P, UnsafeMutablePointer<ObjCBool>) -> R) -> Int? {
        guard let startRangeIndex = self._indexOfRangeAfterOrContainingIndex(range.location), let endRangeIndex = _indexOfRangeBeforeOrContainingIndex(NSMaxRange(range) - 1) else {
            return nil
        }

        var result : Int? = nil
        let reverse = opts.contains(.reverse)
        let passRanges = paramType == NSRange.self
        let findIndex = returnType == Bool.self
        var sharedStop = false
        let lock = NSLock()
        let ranges = _ranges[startRangeIndex...endRangeIndex]
        let rangeSequence = (reverse ? AnyCollection(ranges.reversed()) : AnyCollection(ranges))
        withoutActuallyEscaping(block) { (closure: @escaping (P, UnsafeMutablePointer<ObjCBool>) -> R) -> () in
            let iteration : (Int) -> Void = { (rangeIdx) in
                lock.lock()
                var stop = ObjCBool(sharedStop)
                lock.unlock()
                if stop.boolValue { return }
                
                let idx = rangeSequence.index(rangeSequence.startIndex, offsetBy: rangeIdx)
                let curRange = rangeSequence[idx]
                let intersection = NSIntersectionRange(curRange, range)
                if passRanges {
                    if intersection.length > 0 {
                        let _ = closure(intersection as! P, &stop)
                    }
                    if stop.boolValue {
                        lock.lock()
                        sharedStop = stop.boolValue
                        lock.unlock()
                        return
                    }
                } else if intersection.length > 0 {
                    let maxIndex = NSMaxRange(intersection) - 1
                    let indexes = reverse ? stride(from: maxIndex, through: intersection.location, by: -1) : stride(from: intersection.location, through: maxIndex, by: 1)
                    for idx in indexes {
                        if findIndex {
                            let found : Bool = closure(idx as! P, &stop) as! Bool
                            if found {
                                result = idx
                                stop = true
                            }
                        } else {
                            let _ = closure(idx as! P, &stop)
                        }
                        if stop.boolValue {
                            lock.lock()
                            sharedStop = stop.boolValue
                            lock.unlock()
                            return
                        }
                    }
                }
            }
            if opts.contains(.concurrent) {
                DispatchQueue.concurrentPerform(iterations: Int(rangeSequence.count), execute: iteration)
            } else {
                for idx in 0..<Int(rangeSequence.count) {
                    iteration(idx)
                }
            }
        }
        
        return result
    }

    open func enumerate(_ block: (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerate(options: [], using: block)
    }
    open func enumerate(options opts: NSEnumerationOptions = [], using block: (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: NSRange(location: 0, length: Int.max), paramType: Int.self, returnType: Void.self, block: block)
    }
    open func enumerate(in range: NSRange, options opts: NSEnumerationOptions = [], using block: (Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: range, paramType: Int.self, returnType: Void.self, block: block)
    }

    open func index(passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return index(options: [], passingTest: predicate)
    }
    open func index(options opts: NSEnumerationOptions = [], passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _enumerateWithOptions(opts, range: NSRange(location: 0, length: Int.max), paramType: Int.self, returnType: Bool.self, block: predicate) ?? NSNotFound
    }
    open func index(in range: NSRange, options opts: NSEnumerationOptions = [], passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _enumerateWithOptions(opts, range: range, paramType: Int.self, returnType: Bool.self, block: predicate) ?? NSNotFound
    }
    
    open func indexes(passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexes(in: NSRange(location: 0, length: Int.max), options: [], passingTest: predicate)
    }
    open func indexes(options opts: NSEnumerationOptions = [], passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexes(in: NSRange(location: 0, length: Int.max), options: opts, passingTest: predicate)
    }
    open func indexes(in range: NSRange, options opts: NSEnumerationOptions = [], passingTest predicate: (Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
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
    open func enumerateRanges(_ block: (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateRanges(options: [], using: block)
    }
    open func enumerateRanges(options opts: NSEnumerationOptions = [], using block: (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: NSRange(location: 0, length: Int.max), paramType: NSRange.self, returnType: Void.self, block: block)
    }
    open func enumerateRanges(in range: NSRange, options opts: NSEnumerationOptions = [], using block: (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let _ = _enumerateWithOptions(opts, range: range, paramType: NSRange.self, returnType: Void.self, block: block)
    }
}

public struct NSIndexSetIterator : IteratorProtocol {
    public typealias Element = Int
    internal let _set: NSIndexSet
    internal var _first: Bool = true
    internal var _current: Element?
    
    internal init(_ set: NSIndexSet) {
        self._set = set
        self._current = nil
    }
    
    public mutating func next() -> Element? {
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

extension NSIndexSet : Sequence {
    public func makeIterator() -> NSIndexSetIterator {
        return NSIndexSetIterator(self)
    }
}

open class NSMutableIndexSet : NSIndexSet {
    
    open func add(_ indexSet: IndexSet) {
        indexSet.rangeView.forEach { add(in: NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound)) }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSMutableIndexSet.self {
            let indexSet = NSMutableIndexSet()
            indexSet._ranges = self._ranges
            indexSet._count = self._count
            return indexSet
        }
        return NSMutableIndexSet(indexSet: self._bridgeToSwift())
    }
    
    open func remove(_ indexSet: IndexSet) {
        indexSet.rangeView.forEach { remove(in: NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound)) }
    }
    
    open func removeAllIndexes() {
        _ranges = []
        _count = 0
    }
    
    open func add(_ value: Int) {
        add(in: NSRange(location: value, length: 1))
    }
    
    open func remove(_ value: Int) {
        remove(in: NSRange(location: value, length: 1))
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
    
    internal func _removeRangeAtIndex(_ index: Int) {
        let range = _ranges.remove(at: index)
        _count -= range.length
    }
    
    internal func _mergeOverlappingRangesStartingAtIndex(_ index: Int) {
        var rangeIndex = index
        
        while _ranges.count > 0 && rangeIndex < _ranges.count - 1 {
            var currentRange = _ranges[rangeIndex]
            let nextRange = _ranges[rangeIndex + 1]
            let currentEnd = currentRange.location + currentRange.length
            let nextEnd = nextRange.location + nextRange.length
            if currentEnd >= nextRange.location {
                // overlaps
                if currentEnd < nextEnd {
                    // next range extends beyond current range
                    currentRange.length = nextEnd - currentRange.location
                    _replaceRangeAtIndex(rangeIndex, withRange: currentRange)
                    _removeRangeAtIndex(rangeIndex + 1)
                } else {
                    _replaceRangeAtIndex(rangeIndex + 1, withRange: nil)
                    continue
                }
            } else {
                break
            }
            rangeIndex += 1
        }
    }
    
    open func add(in r: NSRange) {
        var range = r
        guard range.length > 0 else {
            return
        }
        let addEnd = range.location + range.length
        let startRangeIndex = _indexOfRangeBeforeOrContainingIndex(range.location) ?? 0
        var rangeIndex = startRangeIndex
        while rangeIndex < _ranges.count {
            var currentRange = _ranges[rangeIndex]
            let currentEnd = currentRange.location + currentRange.length
            if addEnd < currentRange.location {
                // new separate range
                _insertRange(range, atIndex: rangeIndex)
                return
            } else if (range.location < currentRange.location) && (addEnd >= currentRange.location) {
                if addEnd > currentEnd {
                    // add range contains range in array
                    _replaceRangeAtIndex(rangeIndex, withRange: range)
                } else {
                    // overlaps at start, add range ends within range in array
                    range.length = currentEnd - range.location
                    _replaceRangeAtIndex(rangeIndex, withRange: range)
                }
                break
            } else if (range.location >= currentRange.location) && (addEnd <= currentEnd) {
                // Nothing to add
                return
            } else if (range.location >= currentRange.location) && (range.location <= currentEnd) && (addEnd > currentEnd) {
                // overlaps at end (extends)
                currentRange.length = addEnd - currentRange.location
                _replaceRangeAtIndex(rangeIndex, withRange: currentRange)
                break
            }
            rangeIndex += 1
        }
        if rangeIndex == _ranges.count {
            _insertRange(range, atIndex: _ranges.count)
        }
        
        _mergeOverlappingRangesStartingAtIndex(rangeIndex)
    }
    
    open func remove(in range: NSRange) {
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
                    self._replaceRangeAtIndex(rangeIndex, withRange: NSRange(location: removeEnd, length: curEnd - removeEnd))
                    return
                }
            } else if range.location > curRange.location && removeEnd < curEnd {
                let firstPiece = NSRange(location: curRange.location, length: range.location - curRange.location)
                let secondPiece = NSRange(location: removeEnd, length: curEnd - removeEnd)
                _replaceRangeAtIndex(rangeIndex, withRange: secondPiece)
                _insertRange(firstPiece, atIndex: rangeIndex)
            } else if range.location > curRange.location && range.location < curEnd && removeEnd >= curEnd {
                _replaceRangeAtIndex(rangeIndex, withRange: NSRange(location: curRange.location, length: range.location - curRange.location))
            }
            rangeIndex += 1
        }
        
    }
    
    internal func _increment(by amount: Int, startingAt value: Int) {
        var range: NSRange
        var newRange: NSRange?
        if amount > 0 {
            if let rIdx = _indexOfRangeAfterOrContainingIndex(value) {
                var rangeIndex = rIdx
                
                range = _ranges[rangeIndex]
                if value > range.location {
                    
                    let newLength = range.location + range.length - value
                    let newLocation = value + amount
                    newRange = NSRange(location: newLocation, length: newLength) // new second piece
                    
                    range.length = value - range.location
                    _replaceRangeAtIndex(rangeIndex, withRange: range) // new first piece
                    rangeIndex += 1
                }
                
                while rangeIndex < _ranges.count {
                    range = _ranges[rangeIndex]
                    range.location += amount
                    _replaceRangeAtIndex(rangeIndex, withRange: range)
                    rangeIndex += 1
                }
                
                // add newly created range (second piece) if necessary
                if let range = newRange {
                    add(in: range)
                }
            }
            
        }
    }
    
    internal func _removeAndDecrement(by amount: Int, startingAt value: Int) {
        if amount > 0 {
            if let rIdx = _indexOfRangeAfterOrContainingIndex(value) {
                var rangeIndex = rIdx
                let firstRangeToMerge = rangeIndex > 0 ? rangeIndex - 1 : rangeIndex
                let removeEnd = value + amount - 1
                while rangeIndex < _ranges.count {
                    var range = _ranges[rangeIndex]
                    let rangeEnd = range.location + range.length - 1
                    if removeEnd < range.location {
                        // removal occurs before range -> reduce location of range
                        range.location -= amount
                        _replaceRangeAtIndex(rangeIndex, withRange: range)
                    } else if (range.location >= value) && (rangeEnd <= removeEnd) {
                        // removal encompasses entire range -> remove range
                        _removeRangeAtIndex(rangeIndex)
                        continue // do not increase rangeIndex
                    } else if (value >= range.location) && (removeEnd <= rangeEnd) {
                        // removal occurs completely within range -> reduce length of range
                        range.length -= amount
                        _replaceRangeAtIndex(rangeIndex, withRange: range)
                    } else if (removeEnd >= range.location) && (removeEnd <= rangeEnd) {
                        // removal occurs within part of range, beginning of range removed -> reduce location and length
                        let reduction = removeEnd - range.location + 1
                        range.length -= reduction
                        if range.length > 0 {
                            range.location -= amount - reduction
                            _replaceRangeAtIndex(rangeIndex, withRange: range)
                        } else {
                            _removeRangeAtIndex(rangeIndex)
                            continue // do not increase rangeIndex
                        }
                    } else if (value >= range.location) && (value <= rangeEnd) {
                        // removal occurs within part of range, end of range removed -> reduce length
                        let reduction = rangeEnd - value + 1
                        if reduction > 0 {
                            range.length -= reduction
                            _replaceRangeAtIndex(rangeIndex, withRange: range)
                        }
                    }
                    rangeIndex += 1
                }
                _mergeOverlappingRangesStartingAtIndex(firstRangeToMerge)
            }
        }
    }
    
    /* For a positive delta, shifts the indexes in [index, INT_MAX] to the right, thereby inserting an "empty space" [index, delta], for a negative delta, shifts the indexes in [index, INT_MAX] to the left, thereby deleting the indexes in the range [index - delta, delta].
    */
    open func shiftIndexesStarting(at index: Int, by delta: Int) {
        if delta > 0 {
            _increment(by: delta, startingAt: index)
        } else {
            let positiveDelta = -delta
            let idx = positiveDelta > index ? positiveDelta : index
            _removeAndDecrement(by: positiveDelta, startingAt: idx - positiveDelta)
        }
    }
}

extension NSIndexSet : _StructTypeBridgeable {
    public typealias _StructType = IndexSet
    
    public func _bridgeToSwift() -> IndexSet {
        return IndexSet._unconditionallyBridgeFromObjectiveC(self)
    }
}
