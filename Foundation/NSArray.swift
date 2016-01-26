// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension Array : _ObjectTypeBridgeable {
    public func _bridgeToObject() -> NSArray {
        return NSArray(array: map {
            return _NSObjectRepresentableBridge($0)
        })
    }
    
    public static func _forceBridgeFromObject(x: NSArray, inout result: Array?) {
        var array = [Element]()
        for value in x.allObjects {
            if let v = value as? Element {
                array.append(v)
            } else {
                return
            }
        }
        result = array
    }
    
    public static func _conditionallyBridgeFromObject(x: NSArray, inout result: Array?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

public class NSArray : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFArrayGetTypeID())
    internal var _storage = [AnyObject]()
    
    public var count: Int {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
            return _storage.count
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func objectAtIndex(index: Int) -> AnyObject {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
           return _storage[index]
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience override init() {
        self.init(objects: nil, count:0)
    }
    
    public required init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _storage.reserveCapacity(cnt)
        for idx in 0..<cnt {
            _storage.append(objects[idx]!)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            var cnt: UInt32 = 0
            // We're stuck with (int) here (rather than unsigned int)
            // because that's the way the code was originally written, unless
            // we go to a new version of the class, which has its own problems.
            withUnsafeMutablePointer(&cnt) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
                aDecoder.decodeValueOfObjCType("i", at: UnsafeMutablePointer<Void>(ptr))
            }
            let objects = UnsafeMutablePointer<AnyObject?>.alloc(Int(cnt))
            for idx in 0..<cnt {
                objects.advancedBy(Int(idx)).initialize(aDecoder.decodeObject())
            }
            self.init(objects: UnsafePointer<AnyObject?>(objects), count: Int(cnt))
            objects.destroy(Int(cnt))
            objects.dealloc(Int(cnt))
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.objects") {
            let objects = aDecoder._decodeArrayOfObjectsForKey("NS.objects")
            self.init(array: objects)
        } else {
            var objects = [AnyObject]()
            var count = 0
            while let object = aDecoder.decodeObjectForKey("NS.object.\(count)") {
                objects.append(object)
                count += 1
            }
            self.init(array: objects)
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if let keyedArchiver = aCoder as? NSKeyedArchiver {
            keyedArchiver._encodeArrayOfObjects(self, forKey:"NS.objects")
        } else {
            for object in self {
                if let codable = object as? NSCoding {
                    codable.encodeWithCoder(aCoder)
                }
            }
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        if self.dynamicType === NSArray.self {
            // return self for immutable type
            return self
        } else if self.dynamicType === NSMutableArray.self {
            let array = NSArray()
            array._storage = self._storage
            return array
        }
        return NSArray(array: self.allObjects)
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
            // always create and return an NSMutableArray
            let mutableArray = NSMutableArray()
            mutableArray._storage = self._storage
            return mutableArray
        }
        return NSMutableArray(array: self.allObjects)
    }

    public convenience init(object anObject: AnyObject) {
        self.init(array: [anObject])
    }
    
    public convenience init(array: [AnyObject]) {
        self.init(array: array, copyItems: false)
    }
    
    public convenience init(array: [AnyObject], copyItems: Bool) {
        let optionalArray : [AnyObject?] =
            copyItems ?
                array.map { return Optional<AnyObject>(($0 as! NSObject).copy()) } :
                array.map { return Optional<AnyObject>($0) }
        
        // This would have been nice, but "initializer delegation cannot be nested in another expression"
//        optionalArray.withUnsafeBufferPointer { ptr in
//            self.init(objects: ptr.baseAddress, count: array.count)
//        }
        let cnt = array.count
        let buffer = UnsafeMutablePointer<AnyObject?>.alloc(cnt)
        buffer.initializeFrom(optionalArray)
        self.init(objects: buffer, count: cnt)
        buffer.destroy(cnt)
        buffer.dealloc(cnt)
    }

    public override func isEqual(object: AnyObject?) -> Bool {
        guard let otherObject = object where otherObject is NSArray else {
            return false
        }
        let otherArray = otherObject as! NSArray
        return self.isEqualToArray(otherArray.bridge())
    }

    public override var hash: Int {
        return self.count
    }

    internal var allObjects: [AnyObject] {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
            return _storage
        } else {
            return (0..<count).map { idx in
                return self[idx]
            }
        }
    }
    
    public func arrayByAddingObject(anObject: AnyObject) -> [AnyObject] {
        return allObjects + [anObject]
    }
    
    public func arrayByAddingObjectsFromArray(otherArray: [AnyObject]) -> [AnyObject] {
        return allObjects + otherArray
    }
    
    public func componentsJoinedByString(separator: String) -> String {
        // make certain to call NSObject's description rather than asking the string interpolator for the swift description
        return bridge().map() { ($0 as! NSObject).description }.joinWithSeparator(separator)
    }

    public func containsObject(anObject: AnyObject) -> Bool {
        let other = anObject as! NSObject

        for idx in 0..<count {
            let obj = self[idx] as! NSObject

            if obj === other || obj.isEqual(other) {
                return true
            }
        }
        return false
    }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String { NSUnimplemented() }
    public func descriptionWithLocale(locale: AnyObject?, indent level: Int) -> String { NSUnimplemented() }
    
    public func firstObjectCommonWithArray(otherArray: [AnyObject]) -> AnyObject? {
        let set = NSSet(array: otherArray)

        for idx in 0..<count {
            let item = self[idx]
            if set.containsObject(item) {
                return item
            }
        }
        return nil
    }

    /// Alternative pseudo funnel method for fastpath fetches from arrays
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func getObjects(inout objects: [AnyObject], range: NSRange) {
        objects.reserveCapacity(objects.count + range.length)

        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
            objects += _storage[range.toRange()!]
            return
        }

        objects += range.toRange()!.map { self[$0] }
    }
    
    public func indexOfObject(anObject: AnyObject) -> Int {
        for idx in 0..<count {
            let obj = objectAtIndex(idx) as! NSObject
            if anObject === obj || obj.isEqual(anObject) {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObject(anObject: AnyObject, inRange range: NSRange) -> Int {
        for idx in 0..<range.length {
            let obj = objectAtIndex(idx + range.location) as! NSObject
            if anObject === obj || obj.isEqual(anObject) {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObjectIdenticalTo(anObject: AnyObject) -> Int {
        for idx in 0..<count {
            let obj = objectAtIndex(idx) as! NSObject
            if anObject === obj {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObjectIdenticalTo(anObject: AnyObject, inRange range: NSRange) -> Int {
        for idx in 0..<range.length {
            let obj = objectAtIndex(idx + range.location) as! NSObject
            if anObject === obj {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func isEqualToArray(otherArray: [AnyObject]) -> Bool {
        if count != otherArray.count {
            return false
        }
        
        for idx in 0..<count {
            let obj1 = objectAtIndex(idx) as! NSObject
            let obj2 = otherArray[idx] as! NSObject
            if obj1 === obj2 {
                continue
            }
            if !obj1.isEqual(obj2) {
                return false
            }
        }
        
        return true
    }

    public var firstObject: AnyObject? {
        if count > 0 {
            return objectAtIndex(0)
        } else {
            return nil
        }
    }
    
    public var lastObject: AnyObject? {
        if count > 0 {
            return objectAtIndex(count - 1)
        } else {
            return nil
        }
    }
    
    public struct Generator : GeneratorType {
        // TODO: Detect mutations
        // TODO: Use IndexingGenerator instead?
        let array : NSArray
        let sentinel : Int
        let reverse : Bool
        var idx : Int
        public mutating func next() -> AnyObject? {
            guard idx != sentinel else {
                return nil
            }
            let result = array.objectAtIndex(reverse ? idx - 1 : idx)
            idx += reverse ? -1 : 1
            return result
        }
        init(_ array : NSArray, reverse : Bool = false) {
            self.array = array
            self.sentinel = reverse ? 0 : array.count
            self.idx = reverse ? array.count : 0
            self.reverse = reverse
        }
    }
    public func objectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Generator(self))
    }
    
    public func reverseObjectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Generator(self, reverse: true))
    }
    
    /*@NSCopying*/ public var sortedArrayHint: NSData {
        let buffer = UnsafeMutablePointer<Int32>.alloc(count)
        for idx in 0..<count {
            let item = objectAtIndex(idx) as! NSObject
            let hash = item.hash
            buffer.advancedBy(idx).memory = Int32(hash).littleEndian
        }
        return NSData(bytesNoCopy: unsafeBitCast(buffer, UnsafeMutablePointer<Void>.self), length: count * sizeof(Int), freeWhenDone: true)
    }
    
    public func sortedArrayUsingFunction(comparator: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>) -> [AnyObject] {
        return sortedArrayWithOptions([]) { lhs, rhs in
            return NSComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }
    
    public func sortedArrayUsingFunction(comparator: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>, hint: NSData?) -> [AnyObject] {
        return sortedArrayWithOptions([]) { lhs, rhs in
            return NSComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }

    public func subarrayWithRange(range: NSRange) -> [AnyObject] {
        if range.length == 0 {
            return []
        }
        var objects = [AnyObject]()
        getObjects(&objects, range: range)
        return objects
    }
    
    public func writeToFile(path: String, atomically useAuxiliaryFile: Bool) -> Bool { NSUnimplemented() }
    public func writeToURL(url: NSURL, atomically: Bool) -> Bool { NSUnimplemented() }
    
    public func objectsAtIndexes(indexes: NSIndexSet) -> [AnyObject] {
        var objs = [AnyObject]()
        indexes.enumerateRangesUsingBlock { (range, _) in
            objs.appendContentsOf(self.subarrayWithRange(range))
        }
        return objs
    }
    
    public subscript (idx: Int) -> AnyObject {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }
        
        return objectAtIndex(idx)
    }
    
    public func enumerateObjectsUsingBlock(block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateObjectsWithOptions([], usingBlock: block)
    }
    public func enumerateObjectsWithOptions(opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateObjectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, usingBlock: block)
    }
    public func enumerateObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard !opts.contains(.Concurrent) else {
            NSUnimplemented()
        }
        
        s.enumerateIndexesWithOptions(opts) { (idx, stop) in
            block(self.objectAtIndex(idx), idx, stop)
        }
    }
    
    public func indexOfObjectPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObjectWithOptions([], passingTest: predicate)
    }
    public func indexOfObjectWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObjectAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, passingTest: predicate)
    }
    public func indexOfObjectAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        var result = NSNotFound
        enumerateObjectsAtIndexes(s, options: opts) { (obj, idx, stop) -> Void in
            if predicate(obj, idx, stop) {
                result = idx
                stop.memory = true
            }
        }
        return result
    }
    
    public func indexesOfObjectsPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return indexesOfObjectsWithOptions([], passingTest: predicate)
    }
    public func indexesOfObjectsWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return indexesOfObjectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, passingTest: predicate)
    }
    public func indexesOfObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        let result = NSMutableIndexSet()
        enumerateObjectsAtIndexes(s, options: opts) { (obj, idx, stop) in
            if predicate(obj, idx, stop) {
                result.addIndex(idx)
            }
        }
        return result
    }

    internal func sortedArrayFromRange(range: NSRange, options: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        // The sort options are not available. We use the Array's sorting algorithm. It is not stable neither concurrent.
        guard options.isEmpty else {
            NSUnimplemented()
        }

        let count = self.count
        if range.length == 0 || count == 0 {
            return []
        }

        let swiftRange = range.toRange()!
        return allObjects[swiftRange].sort { lhs, rhs in
            return cmptr(lhs, rhs) == .OrderedAscending
        }
    }
    
    public func sortedArrayUsingComparator(cmptr: NSComparator) -> [AnyObject] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    public func sortedArrayWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    public func indexOfObject(obj: AnyObject, inSortedRange r: NSRange, options opts: NSBinarySearchingOptions, usingComparator cmp: NSComparator) -> Int {
        let lastIndex = r.location + r.length - 1
        
        // argument validation
        guard lastIndex < count else {
            let bounds = count == 0 ? "for empty array" : "[0 .. \(count - 1)]"
            NSInvalidArgument("range \(r) extends beyond bounds \(bounds)")
        }
        
        if opts.contains(.FirstEqual) && opts.contains(.LastEqual) {
            NSInvalidArgument("both NSBinarySearching.FirstEqual and NSBinarySearching.LastEqual options cannot be specified")
        }
        
        let searchForInsertionIndex = opts.contains(.InsertionIndex)
        
        // fringe cases
        if r.length == 0 {
            return  searchForInsertionIndex ? r.location : NSNotFound
        }
        
        let leastObj = objectAtIndex(r.location)
        if cmp(obj, leastObj) == .OrderedAscending {
            return searchForInsertionIndex ? r.location : NSNotFound
        }
        
        let greatestObj = objectAtIndex(lastIndex)
        if cmp(obj, greatestObj) == .OrderedDescending {
            return searchForInsertionIndex ? lastIndex + 1 : NSNotFound
        }
        
        // common processing
        let firstEqual = opts.contains(.FirstEqual)
        let lastEqual = opts.contains(.LastEqual)
        let anyEqual = !(firstEqual || lastEqual)
        
        var result = NSNotFound
        var indexOfLeastGreaterThanObj = NSNotFound
        var start = r.location
        var end = lastIndex
        
        loop: while start <= end {
            let middle = start + (end - start) / 2
            let item = objectAtIndex(middle)
            
            switch cmp(item, obj) {
                
            case .OrderedSame where anyEqual:
                result = middle
                break loop
                
            case .OrderedSame where lastEqual:
                result = middle
                fallthrough
                
            case .OrderedAscending:
                start = middle + 1
                
            case .OrderedSame where firstEqual:
                result = middle
                fallthrough
                
            case .OrderedDescending:
                indexOfLeastGreaterThanObj = middle
                end = middle - 1
                
            default:
                fatalError("Implementation error.")
            }
        }
        
        guard searchForInsertionIndex && lastEqual else {
            return result
        }
        
        guard result == NSNotFound else {
            return result + 1
        }
        
        return indexOfLeastGreaterThanObj
    }
    
    
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }
    
    override public var _cfTypeID: CFTypeID {
        return CFArrayGetTypeID()
    }
}

extension NSArray : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFArrayRef { return unsafeBitCast(self, CFArrayRef.self) }
    internal var _swiftObject: [AnyObject] {
        var array: [AnyObject]?
        Array._forceBridgeFromObject(self, result: &array)
        return array!
    }
}

extension NSMutableArray {
    internal var _cfMutableObject: CFMutableArrayRef { return unsafeBitCast(self, CFMutableArrayRef.self) }
}

extension CFArrayRef : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSArray { return unsafeBitCast(self, NSArray.self) }
    internal var _swiftObject: Array<AnyObject> { return _nsObject._swiftObject }
}

extension CFArrayRef {
    /// Bridge something returned from CF to an Array<T>. Useful when we already know that a CFArray contains objects that are toll-free bridged with Swift objects, e.g. CFArray<CFURLRef>.
    /// - Note: This bridging operation is unfortunately still O(n), but it only traverses the NSArray once, creating the Swift array and casting at the same time.
    func _unsafeTypedBridge<T : AnyObject>() -> Array<T> {
        var result = Array<T>()
        let count = CFArrayGetCount(self)
        result.reserveCapacity(count)
        for i in 0..<count {
            result.append(unsafeBitCast(CFArrayGetValueAtIndex(self, i), T.self))
        }
        return result
    }
}

extension Array : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSArray { return _bridgeToObject() }
    internal var _cfObject: CFArrayRef { return _nsObject._cfObject }
}

public struct NSBinarySearchingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let FirstEqual = NSBinarySearchingOptions(rawValue: 1 << 8)
    public static let LastEqual = NSBinarySearchingOptions(rawValue: 1 << 9)
    public static let InsertionIndex = NSBinarySearchingOptions(rawValue: 1 << 10)
}

public class NSMutableArray : NSArray {
    
    public func addObject(anObject: AnyObject) {
        insertObject(anObject, atIndex: count)
    }
    
    public func insertObject(anObject: AnyObject, atIndex index: Int) {
        if self.dynamicType === NSMutableArray.self {
            _storage.insert(anObject, atIndex: index)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func removeLastObject() {
        if count > 0 {
            removeObjectAtIndex(count - 1)
        }
    }
    
    public func removeObjectAtIndex(index: Int) {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeAtIndex(index)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func replaceObjectAtIndex(index: Int, withObject anObject: AnyObject) {
        if self.dynamicType === NSMutableArray.self {
            _storage.replaceRange(Range<Int>(start: index, end: index + 1), with: [anObject])
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init() {
        self.init(capacity: 0)
    }
    
    public init(capacity numItems: Int) {
        super.init(objects: nil, count: 0)

        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(numItems)
        }
    }
    
    public required convenience init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        self.init(capacity: cnt)
        for idx in 0..<cnt {
            _storage.append(objects[idx]!)
        }
    }
    
    public override subscript (idx: Int) -> AnyObject {
        get {
            return objectAtIndex(idx)
        }
        set(newObject) {
            self.replaceObjectAtIndex(idx, withObject: newObject)
        }
    }
    
    public func addObjectsFromArray(otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage += otherArray
        } else {
            for obj in otherArray {
                addObject(obj)
            }
        }
    }
    
    public func exchangeObjectAtIndex(idx1: Int, withObjectAtIndex idx2: Int) {
        if self.dynamicType === NSMutableArray.self {
            swap(&_storage[idx1], &_storage[idx2])
        } else {
            NSUnimplemented()
        }
    }
    
    public func removeAllObjects() {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeAll()
        } else {
            while count > 0 {
                removeObjectAtIndex(0)
            }
        }
    }
    
    public func removeObject(anObject: AnyObject, inRange range: NSRange) {
        let idx = indexOfObject(anObject, inRange: range)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObject(anObject: AnyObject) {
        let idx = indexOfObject(anObject)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectIdenticalTo(anObject: AnyObject, inRange range: NSRange) {
        let idx = indexOfObjectIdenticalTo(anObject, inRange: range)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectIdenticalTo(anObject: AnyObject) {
        let idx = indexOfObjectIdenticalTo(anObject)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectsInArray(otherArray: [AnyObject]) {
        let set = NSSet(array : otherArray)
        for idx in (0..<count).reverse() {
            if set.containsObject(objectAtIndex(idx)) {
                removeObjectAtIndex(idx)
            }
        }
    }
    
    public func removeObjectsInRange(range: NSRange) {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeRange(range.toRange()!)
        } else {
            for idx in range.toRange()!.reverse() {
                removeObjectAtIndex(idx)
            }
        }
    }
    public func replaceObjectsInRange(range: NSRange, withObjectsFromArray otherArray: [AnyObject], range otherRange: NSRange) {
        var list = [AnyObject]()
        otherArray.bridge().getObjects(&list, range:otherRange)
        replaceObjectsInRange(range, withObjectsFromArray:list)
    }
    
    public func replaceObjectsInRange(range: NSRange, withObjectsFromArray otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(count - range.length + otherArray.count)
            for idx in 0..<range.length {
                _storage[idx + range.location] = otherArray[idx]
            }
            for idx in range.length..<otherArray.count {
                _storage.insert(otherArray[idx], atIndex: idx + range.location)
            }
        } else {
            NSUnimplemented()
        }
    }
    
    public func setArray(otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage = otherArray
        } else {
            replaceObjectsInRange(NSMakeRange(0, count), withObjectsFromArray: otherArray)
        }
    }
    
    public func insertObjects(objects: [AnyObject], atIndexes indexes: NSIndexSet) {
        precondition(objects.count == indexes.count)
        
        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(count + indexes.count)
        }

        var objectIdx = 0
        indexes.enumerateIndexesUsingBlock() { (insertionIndex, _) in
            self.insertObject(objects[objectIdx], atIndex: insertionIndex)
            objectIdx += 1
        }
    }
    
    public func removeObjectsAtIndexes(indexes: NSIndexSet) {
        indexes.enumerateRangesWithOptions(.Reverse) { (range, _) in
            self.removeObjectsInRange(range)
        }
    }
    
    public func replaceObjectsAtIndexes(indexes: NSIndexSet, withObjects objects: [AnyObject]) {
        var objectIndex = 0
        indexes.enumerateRangesUsingBlock { (range, _) in
            let subObjects = objects[objectIndex..<objectIndex + range.length]
            self.replaceObjectsInRange(range, withObjectsFromArray: Array(subObjects))
            objectIndex += range.length
        }
    }

    public func sortUsingFunction(compare: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>) {
        self.setArray(self.sortedArrayUsingFunction(compare, context: context))
    }

    public func sortUsingComparator(cmptr: NSComparator) {
        self.sortWithOptions([], usingComparator: cmptr)
    }

    public func sortWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) {
        self.setArray(self.sortedArrayWithOptions(opts, usingComparator: cmptr))
    }
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }
}

extension NSArray : SequenceType {
    final public func generate() -> Generator {
        return Generator(self)
    }
}

extension Array : Bridgeable {
    public func bridge() -> NSArray { return _nsObject }
}

extension NSArray : Bridgeable {
    public func bridge() -> Array<AnyObject> { return _swiftObject }
}
