// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class NSArray : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFArrayGetTypeID())
    internal var _storage = [AnyObject]()
    
    open var count: Int {
        guard type(of: self) === NSArray.self || type(of: self) === NSMutableArray.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage.count
    }
    
    open func object(at index: Int) -> Any {
        guard type(of: self) === NSArray.self || type(of: self) === NSMutableArray.self else {
           NSRequiresConcreteImplementation()
        }
        return _SwiftValue.fetch(_storage[index])
    }
    
    public convenience override init() {
        self.init(objects: [], count:0)
    }
    
    public required init(objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        _storage.reserveCapacity(cnt)
        for idx in 0..<cnt {
            _storage.append(objects[idx])
        }
    }
    
    required public convenience init(arrayLiteral elements: Any...) {
        self.init(array: elements)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            var cnt: UInt32 = 0
            // We're stuck with (int) here (rather than unsigned int)
            // because that's the way the code was originally written, unless
            // we go to a new version of the class, which has its own problems.
            withUnsafeMutablePointer(to: &cnt) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
                aDecoder.decodeValue(ofObjCType: "i", at: UnsafeMutableRawPointer(ptr))
            }
            let objects = UnsafeMutablePointer<AnyObject>.allocate(capacity: Int(cnt))
            for idx in 0..<cnt {
                // If conversion to NSObject fails then we really can't hold it anyway
                objects.advanced(by: Int(idx)).initialize(to: aDecoder.decodeObject() as! NSObject)
            }
            self.init(objects: UnsafePointer<AnyObject>(objects), count: Int(cnt))
            objects.deinitialize(count: Int(cnt))
            objects.deallocate(capacity: Int(cnt))
        } else if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.objects") {
            let objects = aDecoder._decodeArrayOfObjectsForKey("NS.objects")
            self.init(array: objects as! [NSObject])
        } else {
            var objects = [AnyObject]()
            var count = 0
            while let object = aDecoder.decodeObject(forKey: "NS.object.\(count)") {
                objects.append(object as! NSObject)
                count += 1
            }
            self.init(array: objects)
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        if let keyedArchiver = aCoder as? NSKeyedArchiver {
            keyedArchiver._encodeArrayOfObjects(self, forKey:"NS.objects")
        } else {
            for object in self {
                if let codable = object as? NSCoding {
                    codable.encode(with: aCoder)
                }
            }
        }
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSArray.self {
            // return self for immutable type
            return self
        } else if type(of: self) === NSMutableArray.self {
            let array = NSArray()
            array._storage = self._storage
            return array
        }
        return NSArray(array: self.allObjects)
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSArray.self || type(of: self) === NSMutableArray.self {
            // always create and return an NSMutableArray
            let mutableArray = NSMutableArray()
            mutableArray._storage = self._storage
            return mutableArray
        }
        return NSMutableArray(array: self.allObjects)
    }

    public convenience init(object anObject: Any) {
        self.init(array: [anObject])
    }
    
    public convenience init(array: [Any]) {
        self.init(array: array, copyItems: false)
    }
    
    public convenience init(array: [Any], copyItems: Bool) {
        
        let optionalArray : [AnyObject] =
            copyItems ?
                array.map { return _SwiftValue.store($0).copy() as! NSObject } :
                array.map { return _SwiftValue.store($0) }
        
        // This would have been nice, but "initializer delegation cannot be nested in another expression"
//        optionalArray.withUnsafeBufferPointer { ptr in
//            self.init(objects: ptr.baseAddress, count: array.count)
//        }
        let cnt = array.count
        let buffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: cnt)
        buffer.initialize(from: optionalArray)
        self.init(objects: buffer, count: cnt)
        buffer.deinitialize(count: cnt)
        buffer.deallocate(capacity: cnt)
    }

    open override func isEqual(_ object: AnyObject?) -> Bool {
        guard let otherObject = object, otherObject is NSArray else {
            return false
        }
        let otherArray = otherObject as! NSArray
        return self.isEqual(to: otherArray.allObjects)
    }

    open override var hash: Int {
        return self.count
    }

    internal var allObjects: [Any] {
        if type(of: self) === NSArray.self || type(of: self) === NSMutableArray.self {
            return _storage.map { _SwiftValue.fetch($0) }
        } else {
            return (0..<count).map { idx in
                return self[idx]
            }
        }
    }
    
    open func adding(_ anObject: Any) -> [Any] {
        return allObjects + [anObject]
    }
    
    open func addingObjects(from otherArray: [Any]) -> [Any] {
        return allObjects + otherArray
    }
    
    open func componentsJoined(by separator: String) -> String {
        // make certain to call NSObject's description rather than asking the string interpolator for the swift description
        return allObjects.map { "\($0)" }.joined(separator: separator)
    }

    open func contains(_ anObject: Any) -> Bool {
        guard let other = anObject as? AnyHashable else {
            return false
        }

        for idx in 0..<count {
            if let obj = self[idx] as? AnyHashable {
                if obj == other {
                    return true
                }
            }
        }
        return false
    }
    
    open func description(withLocale locale: Locale?) -> String { return description(withLocale: locale, indent: 0) }
    open func description(withLocale locale: Locale?, indent level: Int) -> String {
        var descriptions = [String]()
        let cnt = count
        for idx in 0..<cnt {
            let obj = self[idx]
            if let string = obj as? String {
                descriptions.append(string)
            } else if let array = obj as? [Any] {
                descriptions.append(NSArray(array: array).description(withLocale: locale, indent: level + 1))
            } else if let dict = obj as? [AnyHashable : Any] {
                descriptions.append(dict._bridgeToObjectiveC().description(withLocale: locale, indent: level + 1))
            } else {
                descriptions.append("\(obj)")
            }
        }
        var indent = ""
        for _ in 0..<level {
            indent += "    "
        }
        var result = indent + "(\n"
        for idx in 0..<cnt {
            result += indent + "    " + descriptions[idx]
            if idx + 1 < cnt {
                result += ",\n"
            } else {
                result += "\n"
            }
        }
        result += indent + ")"
        return result
    }
    
    open func firstObjectCommon(with otherArray: [Any]) -> Any? {
        let set = otherArray.map { _SwiftValue.store($0) }

        for idx in 0..<count {
            let item = _SwiftValue.store(self[idx])
            if set.contains(item) {
                return _SwiftValue.fetch(item)
            }
        }
        return nil
    }

    internal func getObjects(_ objects: inout [Any], range: NSRange) {
        objects.reserveCapacity(objects.count + range.length)

        if type(of: self) === NSArray.self || type(of: self) === NSMutableArray.self {
            objects += _storage[range.toRange()!].map { _SwiftValue.fetch($0) }
            return
        }
        
        objects += range.toCountableRange()!.map { self[$0] }
    }
    
    open func index(of anObject: Any) -> Int {
        guard let val = anObject as? AnyHashable else {
            return NSNotFound
        }
        for idx in 0..<count {
            if let obj = object(at: idx) as? AnyHashable {
                if val == obj {
                    return idx
                }
            }
        }
        return NSNotFound
    }
    
    open func index(of anObject: Any, in range: NSRange) -> Int {
        guard let val = anObject as? AnyHashable else {
            return NSNotFound
        }
        for idx in 0..<range.length {
            if let obj = object(at: idx + range.location) as? AnyHashable {
                if val == obj {
                    return idx
                }
            }
        }
        return NSNotFound
    }
    
    open func indexOfObjectIdentical(to anObject: Any) -> Int {
        guard let val = anObject as? NSObject else {
            return NSNotFound
        }
        for idx in 0..<count {
            if let obj = object(at: idx) as? NSObject {
                if val === obj {
                    return idx
                }
            }
        }
        return NSNotFound
    }
    
    open func indexOfObjectIdentical(to anObject: Any, in range: NSRange) -> Int {
        guard let val = anObject as? NSObject else {
            return NSNotFound
        }
        for idx in 0..<range.length {
            if let obj = object(at: idx + range.location) as? NSObject {
                if val === obj {
                    return idx
                }
            }
        }
        return NSNotFound
    }
    
    open func isEqual(to otherArray: [Any]) -> Bool {
        if count != otherArray.count {
            return false
        }
        
        for idx in 0..<count {
            if let val1 = object(at: idx) as? AnyHashable,
               let val2 = otherArray[idx] as? AnyHashable {
                if val1 != val2 {
                    return false
                }
            }
        }
        
        return true
    }

    open var firstObject: Any? {
        if count > 0 {
            return object(at: 0)
        } else {
            return nil
        }
    }
    
    open var lastObject: Any? {
        if count > 0 {
            return object(at: count - 1)
        } else {
            return nil
        }
    }
    
    public struct Iterator : IteratorProtocol {
        // TODO: Detect mutations
        // TODO: Use IndexingGenerator instead?
        let array : NSArray
        let sentinel : Int
        let reverse : Bool
        var idx : Int
        public mutating func next() -> Any? {
            guard idx != sentinel else {
                return nil
            }
            let result = array.object(at: reverse ? idx - 1 : idx)
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
    open func objectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Iterator(self))
    }
    
    open func reverseObjectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Iterator(self, reverse: true))
    }
    
    /*@NSCopying*/ open var sortedArrayHint: Data {
        let size = count
        let buffer = UnsafeMutablePointer<Int32>.allocate(capacity: size)
        for idx in 0..<count {
            let item = object(at: idx) as! NSObject
            let hash = item.hash
            buffer.advanced(by: idx).pointee = Int32(hash).littleEndian
        }
        return Data(bytesNoCopy: unsafeBitCast(buffer, to: UnsafeMutablePointer<UInt8>.self), count: count * MemoryLayout<Int>.size, deallocator: .custom({ _ in
            buffer.deallocate(capacity: size)
            buffer.deinitialize(count: size)
        }))
    }
    
    open func sortedArray(_ comparator: (Any, Any, UnsafeMutableRawPointer?) -> Int, context: UnsafeMutableRawPointer?) -> [Any] {
        return sortedArray([]) { lhs, rhs in
            return ComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }
    
    open func sortedArray(_ comparator: (Any, Any, UnsafeMutableRawPointer?) -> Int, context: UnsafeMutableRawPointer?, hint: Data?) -> [Any] {
        return sortedArray([]) { lhs, rhs in
            return ComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }

    open func subarray(with range: NSRange) -> [Any] {
        if range.length == 0 {
            return []
        }
        var objects = [Any]()
        getObjects(&objects, range: range)
        return objects
    }
    
    open func write(toFile path: String, atomically useAuxiliaryFile: Bool) -> Bool { NSUnimplemented() }
    open func write(to url: URL, atomically: Bool) -> Bool { NSUnimplemented() }
    
    open func objects(at indexes: IndexSet) -> [Any] {
        var objs = [Any]()
        indexes.rangeView.forEach {
            objs.append(contentsOf: self.subarray(with: NSRange(location: $0.lowerBound, length: $0.upperBound - $0.lowerBound)))
        }
        
        return objs
    }
    
    open subscript (idx: Int) -> Any {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }
        
        return object(at: idx)
    }
    
    public func enumerateObjects(_ block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateObjects([], using: block)
    }
    public func enumerateObjects(_ opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        self.enumerateObjects(at: IndexSet(integersIn: 0..<count), options: opts, using: block)
    }
    public func enumerateObjects(at s: IndexSet, options opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard !opts.contains(.concurrent) else {
            NSUnimplemented()
        }
        s._bridgeToObjectiveC().enumerate(options: opts) { (idx, stop) in
            block(self.object(at: idx), idx, stop)
        }
    }
    
    open func indexOfObject(passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObject([], passingTest: predicate)
    }
    open func indexOfObject(_ opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObject(at: IndexSet(integersIn: 0..<count), options: opts, passingTest: predicate)
    }
    open func indexOfObject(at s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        var result = NSNotFound
        enumerateObjects(at: s, options: opts) { (obj, idx, stop) -> Void in
            if predicate(obj, idx, stop) {
                result = idx
                stop.pointee = true
            }
        }
        return result
    }
    
    open func indexesOfObjects(passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexesOfObjects([], passingTest: predicate)
    }
    open func indexesOfObjects(_ opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return indexesOfObjects(at: IndexSet(integersIn: 0..<count), options: opts, passingTest: predicate)
    }
    open func indexesOfObjects(at s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        var result = IndexSet()
        enumerateObjects(at: s, options: opts) { (obj, idx, stop) in
            if predicate(obj, idx, stop) {
                result.insert(idx)
            }
        }
        return result
    }

    internal func sortedArrayFromRange(_ range: NSRange, options: SortOptions, usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        // The sort options are not available. We use the Array's sorting algorithm. It is not stable neither concurrent.
        guard options.isEmpty else {
            NSUnimplemented()
        }

        let count = self.count
        if range.length == 0 || count == 0 {
            return []
        }

        let swiftRange = range.toRange()!
        return allObjects[swiftRange].sorted { lhs, rhs in
            return cmptr(lhs, rhs) == .orderedAscending
        }
    }
    
    open func sortedArray(comparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    open func sortedArray(_ opts: SortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    open func index(of obj: Any, inSortedRange r: NSRange, options opts: NSBinarySearchingOptions = [], usingComparator cmp: (Any, Any) -> ComparisonResult) -> Int {
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
        
        let leastObj = object(at: r.location)
        if cmp(obj, leastObj) == .orderedAscending {
            return searchForInsertionIndex ? r.location : NSNotFound
        }
        
        let greatestObj = object(at: lastIndex)
        if cmp(obj, greatestObj) == .orderedDescending {
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
            let item = object(at: middle)
            
            switch cmp(item, obj) {
                
            case .orderedSame where anyEqual:
                result = middle
                break loop
                
            case .orderedSame where lastEqual:
                result = middle
                fallthrough
                
            case .orderedAscending:
                start = middle + 1
                
            case .orderedSame where firstEqual:
                result = middle
                fallthrough
                
            case .orderedDescending:
                indexOfLeastGreaterThanObj = middle
                end = middle - 1
                
            default:
                fatalError("Implementation error.")
            }
        }
        
        if !searchForInsertionIndex {
            return result
        }
        
        if result == NSNotFound {
            return indexOfLeastGreaterThanObj
        }
        
        return lastEqual ? result + 1 : result
    }
    
    
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: URL) { NSUnimplemented() }
    
    override open var _cfTypeID: CFTypeID {
        return CFArrayGetTypeID()
    }
}

extension NSArray : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFArray { return unsafeBitCast(self, to: CFArray.self) }
    internal var _swiftObject: [AnyObject] { return Array._unconditionallyBridgeFromObjectiveC(self) }
}

extension NSMutableArray {
    internal var _cfMutableObject: CFMutableArray { return unsafeBitCast(self, to: CFMutableArray.self) }
}

extension CFArray : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSArray { return unsafeBitCast(self, to: NSArray.self) }
    internal var _swiftObject: Array<Any> { return _nsObject._swiftObject }
}

extension CFArray {
    /// Bridge something returned from CF to an Array<T>. Useful when we already know that a CFArray contains objects that are toll-free bridged with Swift objects, e.g. CFArray<CFURLRef>.
    /// - Note: This bridging operation is unfortunately still O(n), but it only traverses the NSArray once, creating the Swift array and casting at the same time.
    func _unsafeTypedBridge<T : _CFBridgable>() -> Array<T> {
        var result = Array<T>()
        let count = CFArrayGetCount(self)
        result.reserveCapacity(count)
        for i in 0..<count {
            result.append(unsafeBitCast(CFArrayGetValueAtIndex(self, i), to: T.self))
        }
        return result
    }
}

extension Array : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSArray { return _bridgeToObjectiveC() }
    internal var _cfObject: CFArray { return _nsObject._cfObject }
}

public struct NSBinarySearchingOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let FirstEqual = NSBinarySearchingOptions(rawValue: 1 << 8)
    public static let LastEqual = NSBinarySearchingOptions(rawValue: 1 << 9)
    public static let InsertionIndex = NSBinarySearchingOptions(rawValue: 1 << 10)
}

open class NSMutableArray : NSArray {
    
    open func add(_ anObject: Any) {
        insert(anObject, at: count)
    }
    
    open func insert(_ anObject: Any, at index: Int) {
        guard type(of: self) === NSMutableArray.self else {
            NSRequiresConcreteImplementation()
        }
        _storage.insert(_SwiftValue.store(anObject), at: index)
    }
    
    open func removeLastObject() {
        if count > 0 {
            removeObject(at: count - 1)
        }
    }
    
    open func removeObject(at index: Int) {
        guard type(of: self) === NSMutableArray.self else {
            NSRequiresConcreteImplementation()
        }
        _storage.remove(at: index)
    }
    
    open func replaceObject(at index: Int, with anObject: Any) {
        guard type(of: self) === NSMutableArray.self else {
            NSRequiresConcreteImplementation()
        }
        let min = index
        let max = index + 1
        _storage.replaceSubrange(min..<max, with: [_SwiftValue.store(anObject) as AnyObject])
    }
    
    public convenience init() {
        self.init(capacity: 0)
    }
    
    public init(capacity numItems: Int) {
        super.init(objects: [], count: 0)

        if type(of: self) === NSMutableArray.self {
            _storage.reserveCapacity(numItems)
        }
    }
    
    public required convenience init(objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        self.init(capacity: cnt)
        for idx in 0..<cnt {
            _storage.append(objects[idx])
        }
    }
    
    open override subscript (idx: Int) -> Any {
        get {
            return object(at: idx)
        }
        set(newObject) {
            self.replaceObject(at: idx, with: newObject)
        }
    }
    
    open func addObjectsFromArray(_ otherArray: [Any]) {
        if type(of: self) === NSMutableArray.self {
            _storage += otherArray.map { _SwiftValue.store($0) as AnyObject }
        } else {
            for obj in otherArray {
                add(obj)
            }
        }
    }
    
    open func exchangeObject(at idx1: Int, withObjectAt idx2: Int) {
        if type(of: self) === NSMutableArray.self {
            swap(&_storage[idx1], &_storage[idx2])
        } else {
            NSUnimplemented()
        }
    }
    
    open func removeAllObjects() {
        if type(of: self) === NSMutableArray.self {
            _storage.removeAll()
        } else {
            while count > 0 {
                removeObject(at: 0)
            }
        }
    }
    
    open func removeObject(_ anObject: Any, inRange range: NSRange) {
        let idx = index(of: anObject, in: range)
        if idx != NSNotFound {
            removeObject(at: idx)
        }
    }
    
    open func removeObject(_ anObject: Any) {
        let idx = index(of: anObject)
        if idx != NSNotFound {
            removeObject(at: idx)
        }
    }
    
    open func removeObjectIdenticalTo(_ anObject: Any, inRange range: NSRange) {
        let idx = indexOfObjectIdentical(to: anObject, in: range)
        if idx != NSNotFound {
            removeObject(at: idx)
        }
    }
    
    open func removeObjectIdenticalTo(_ anObject: Any) {
        let idx = indexOfObjectIdentical(to: anObject)
        if idx != NSNotFound {
            removeObject(at: idx)
        }
    }
    
    open func removeObjects(in otherArray: [Any]) {
        let set = Set(otherArray.map { $0 as! AnyHashable } )
        for idx in (0..<count).reversed() {
            if let value = object(at: idx) as? AnyHashable {
                if set.contains(value) {
                    removeObject(at: idx)
                }
            }
        }
    }
    
    open func removeObjects(in range: NSRange) {
        if type(of: self) === NSMutableArray.self {
            _storage.removeSubrange(range.toRange()!)
        } else {
            for idx in range.toCountableRange()!.reversed() {
                removeObject(at: idx)
            }
        }
    }
    open func replaceObjects(in range: NSRange, withObjectsFrom otherArray: [Any], range otherRange: NSRange) {
        var list = [Any]()
        otherArray._bridgeToObjectiveC().getObjects(&list, range:otherRange)
        replaceObjectsInRange(range, withObjectsFromArray:list)
    }
    
    open func replaceObjectsInRange(_ range: NSRange, withObjectsFromArray otherArray: [Any]) {
        if type(of: self) === NSMutableArray.self {
            _storage.reserveCapacity(count - range.length + otherArray.count)
            for idx in 0..<range.length {
                _storage[idx + range.location] = _SwiftValue.store(otherArray[idx])
            }
            for idx in range.length..<otherArray.count {
                _storage.insert(_SwiftValue.store(otherArray[idx]), at: idx + range.location)
            }
        } else {
            NSUnimplemented()
        }
    }
    
    open func setArray(_ otherArray: [Any]) {
        if type(of: self) === NSMutableArray.self {
            _storage = otherArray.map { _SwiftValue.store($0) }
        } else {
            replaceObjectsInRange(NSMakeRange(0, count), withObjectsFromArray: otherArray)
        }
    }
    
    open func insertObjects(_ objects: [Any], atIndexes indexes: IndexSet) {
        precondition(objects.count == indexes.count)
        
        if type(of: self) === NSMutableArray.self {
            _storage.reserveCapacity(count + indexes.count)
        }

        var objectIdx = 0
        for insertionIndex in indexes {
            self.insert(objects[objectIdx], at: insertionIndex)
            objectIdx += 1
        }
    }
    
    open func removeObjectsAtIndexes(_ indexes: IndexSet) {
        for range in indexes.rangeView.reversed() {
            self.removeObjects(in: NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound))
        }
    }
    
    open func replaceObjectsAtIndexes(_ indexes: IndexSet, withObjects objects: [Any]) {
        var objectIndex = 0
        for countedRange in indexes.rangeView {
            let range = NSMakeRange(countedRange.lowerBound, countedRange.upperBound - countedRange.lowerBound)
            let subObjects = objects[objectIndex..<objectIndex + range.length]
            self.replaceObjectsInRange(range, withObjectsFromArray: Array(subObjects))
            objectIndex += range.length
        }
    }

    open func sortUsingFunction(_ compare: (Any, Any, UnsafeMutableRawPointer?) -> Int, context: UnsafeMutableRawPointer?) {
        self.setArray(self.sortedArray(compare, context: context))
    }

    open func sortUsingComparator(_ cmptr: Comparator) {
        self.sortWithOptions([], usingComparator: cmptr)
    }

    open func sortWithOptions(_ opts: SortOptions, usingComparator cmptr: Comparator) {
        self.setArray(self.sortedArray(opts, usingComparator: cmptr))
    }
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: URL) { NSUnimplemented() }
}

extension NSArray : Sequence {
    final public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}

extension NSArray : ExpressibleByArrayLiteral {
    
    /// Create an instance initialized with `elements`.
//    required public convenience init(arrayLiteral elements: Any...) {
//        
//    }
}

extension NSArray : _StructTypeBridgeable {
    public typealias _StructType = Array<Any>
    
    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
