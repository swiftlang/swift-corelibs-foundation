// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class NSSortDescriptor: NSObject, NSSecureCoding, NSCopying {
    
    private var _ascending: Bool
    private var _key: String?
    private var _comparator: Comparator?
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        let ascending = aDecoder.decodeBool(forKey: "NSAscending")
        let key = aDecoder.decodeObject(of: NSString.self, forKey: "NSKey")
        
        self.init(key: key == nil ? nil : String._unconditionallyBridgeFromObjectiveC(key),
                  ascending: ascending)
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard _comparator == nil else {
            fatalError("NSSortDescriptor object that has been initialized with init(key:ascending:comparator:) cannot be encoded.")
        }
        
        aCoder.encode(_ascending, forKey: "NSAscending")
        aCoder.encode(_key, forKey: "NSKey")
        aCoder.encode("compare:", forKey: "NSSelector") // — to match the Darwin version
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    // keys may be key paths
    public init(key: String?, ascending: Bool) {
        
        // In the Objective-C version of Foundation if no Comparator is set, NSSortDescriptor relies on performing
        // a `compare:` selector. Obviously, it is currently impossible to implement such a behaviour
        // in Swift due to its limited dynamism.
        NSUnimplemented()
    }
    
    open var key: String? {
        return _key
    }
    
    open var ascending: Bool {
        return _ascending
    }
    
    // Force a sort descriptor which was securely decoded to allow evaluation
    open func allowEvaluation() {
        // Do nothing since in Objective-C Foundation invoking this method makes no change.
    }

    public init(key: String?, ascending: Bool, comparator cmptr: @escaping Comparator) {
        
        if key != nil {
            fatalError("Key-value coding is not supported.")
        }
        
        _ascending = ascending
        _key = key
        _comparator = cmptr
    }
    
    open var comparator: Comparator {
        return _comparator ?? { _, _ in
            fatalError("A comparator can only be called if NSSortDescriptor object has been initialized with init(key:ascending:comparator:).")
        }
    }
    
    // primitive - override this method if you want to perform comparisons differently (not key based for example)
    open func compare(_ object1: Any, to object2: Any) -> ComparisonResult {
        
        if let comparator = _comparator {
            if ascending {
                return comparator(object1, object2)
            } else {
                return ComparisonResult(rawValue: -1 * comparator(object1, object2).rawValue)!
            }
        } else {
            NSUnimplemented()
        }
    }
    
    // primitive - override this method to return a sort descriptor instance with reversed sort order
    open var reversedSortDescriptor: Any {
        
        if let comparator = _comparator {
            return NSSortDescriptor(key: _key, ascending: !_ascending, comparator: comparator)
        } else {
            return NSSortDescriptor(key: _key, ascending: !_ascending)
        }
    }
}

extension NSSet {
    
    // returns a new array by sorting the objects of the receiver
    open func sortedArray(using sortDescriptors: [NSSortDescriptor]) -> [Any] {
        let array = allObjects._bridgeToObjectiveC()
        return array.sortedArray(using: sortDescriptors)
    }
}

extension NSArray {
    
    // returns a new array by sorting the objects of the receiver
    open func sortedArray(using sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return sortedArray(options: [], usingComparator: _makeComparator(sortDescriptors))
    }
}

extension NSMutableArray {
    
    // sorts the array itself
    open func sort(using sortDescriptors: [NSSortDescriptor]) {
        sort(options: [], usingComparator: _makeComparator(sortDescriptors))
    }
}

extension NSOrderedSet {
    
    // returns a new array by sorting the objects of the receiver
    open func sortedArray(using sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return sortedArray(options: [], usingComparator: _makeComparator(sortDescriptors))
    }
}

extension NSMutableOrderedSet {
    
    // sorts the ordered set itself
    open func sort(using sortDescriptors: [NSSortDescriptor]) {
        sort(options: [], usingComparator: _makeComparator(sortDescriptors))
    }
}

private func _makeComparator(_ sortDescriptors: [NSSortDescriptor]) -> Comparator {
    
    return { (_ object1: Any, _ object2: Any) -> ComparisonResult in
        var comparisonResult = ComparisonResult.orderedSame
        
        for descriptor in sortDescriptors {
            comparisonResult = descriptor.compare(object1, to: object2)
            if comparisonResult != .orderedSame {
                break
            }
        }
        
        return comparisonResult
    }
}
