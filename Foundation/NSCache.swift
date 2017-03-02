// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

private class NSCacheEntry<KeyType : AnyObject, ObjectType : AnyObject> {
    var key: KeyType
    var value: ObjectType
    var cost: Int
    var prevByCost: NSCacheEntry?
    var nextByCost: NSCacheEntry?
    init(key: KeyType, value: ObjectType, cost: Int) {
        self.key = key
        self.value = value
        self.cost = cost
    }
}

fileprivate class NSCacheKey: NSObject {
    
    var value: AnyObject
    
    init(_ value: AnyObject) {
        self.value = value
        super.init()
    }
    
    override var hashValue: Int {
        switch self.value {
        case let nsObject as NSObject:
            return nsObject.hashValue
        case let hashable as Hashable:
            return hashable.hashValue
        default: return 0
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = (object as? NSCacheKey) else { return false }
        
        if self.value === other.value {
            return true
        } else {
            guard let left = self.value as? NSObject,
                let right = other.value as? NSObject else { return false }
            
            return left.isEqual(right)
        }
    }
}

open class NSCache<KeyType : AnyObject, ObjectType : AnyObject> : NSObject {
    
    private var _entries = Dictionary<NSCacheKey, NSCacheEntry<KeyType, ObjectType>>()
    private let _lock = NSLock()
    private var _totalCost = 0
    private var _byCost: NSCacheEntry<KeyType, ObjectType>?
    
    open var name: String = ""
    open var totalCostLimit: Int = 0 // limits are imprecise/not strict
    open var countLimit: Int = 0 // limits are imprecise/not strict
    open var evictsObjectsWithDiscardedContent: Bool = false

    public override init() {}
    
    open weak var delegate: NSCacheDelegate?
    
    open func object(forKey key: KeyType) -> ObjectType? {
        var object: ObjectType?
        
        let key = NSCacheKey(key)
        
        _lock.lock()
        if let entry = _entries[key] {
            object = entry.value
        }
        _lock.unlock()
        
        return object
    }
    
    open func setObject(_ obj: ObjectType, forKey key: KeyType) {
        setObject(obj, forKey: key, cost: 0)
    }
    
    private func remove(_ entry: NSCacheEntry<KeyType, ObjectType>) {
        let oldPrev = entry.prevByCost
        let oldNext = entry.nextByCost
        oldPrev?.nextByCost = oldNext
        oldNext?.prevByCost = oldPrev
        if entry === _byCost {
            _byCost = entry.nextByCost
        }
    }
   
    private func insert(_ entry: NSCacheEntry<KeyType, ObjectType>) {
        if _byCost == nil {
            _byCost = entry
        } else {
            var element = _byCost
            while let e = element {
                if e.cost > entry.cost {
                    let newPrev = e.prevByCost
                    entry.prevByCost = newPrev
                    entry.nextByCost = e
                    break
                }
                element = e.nextByCost
            }
        }
    }
    
    open func setObject(_ obj: ObjectType, forKey key: KeyType, cost g: Int) {
        let keyRef = NSCacheKey(key)
        
        _lock.lock()
        _totalCost += g
        
        var purgeAmount = 0
        if totalCostLimit > 0 {
            purgeAmount = (_totalCost + g) - totalCostLimit
        }
        
        var purgeCount = 0
        if countLimit > 0 {
            purgeCount = (_entries.count + 1) - countLimit
        }
        
        if let entry = _entries[keyRef] {
            entry.value = obj
            if entry.cost != g {
                entry.cost = g
                remove(entry)
                insert(entry)
            }
        } else {
            let entry = NSCacheEntry(key: key, value: obj, cost: g)
            _entries[keyRef] = entry
            insert(entry)
        }
        _lock.unlock()
        
        var toRemove = [NSCacheEntry<KeyType, ObjectType>]()
        
        if purgeAmount > 0 {
            _lock.lock()
            while _totalCost - totalCostLimit > 0 {
                if let entry = _byCost {
                    _totalCost -= entry.cost
                    toRemove.append(entry)
                    remove(entry)
                } else {
                    break
                }
            }
            if countLimit > 0 {
                purgeCount = (_entries.count - toRemove.count) - countLimit
            }
            _lock.unlock()
        }
        
        if purgeCount > 0 {
            _lock.lock()
            while (_entries.count - toRemove.count) - countLimit > 0 {
                if let entry = _byCost {
                    _totalCost -= entry.cost
                    toRemove.append(entry)
                    remove(entry)
                } else {
                    break
                }
            }
            _lock.unlock()
        }
        
        if let del = delegate {
            for entry in toRemove {
                del.cache(unsafeDowncast(self, to:NSCache<AnyObject, AnyObject>.self), willEvictObject: entry.value)
            }
        }
        
        _lock.lock()
        for entry in toRemove {
            _entries.removeValue(forKey: NSCacheKey(entry.key)) // the cost list is already fixed up in the purge routines
        }
        _lock.unlock()
    }
    
    open func removeObject(forKey key: KeyType) {
        let keyRef = NSCacheKey(key)
        
        _lock.lock()
        if let entry = _entries.removeValue(forKey: keyRef) {
            _totalCost -= entry.cost
            remove(entry)
        }
        _lock.unlock()
    }
    
    open func removeAllObjects() {
        _lock.lock()
        _entries.removeAll()
        _byCost = nil
        _totalCost = 0
        _lock.unlock()
    }    
}

public protocol NSCacheDelegate : NSObjectProtocol {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any)
}

extension NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        // Default implementation does nothing
    }
}
