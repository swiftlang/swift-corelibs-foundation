// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSCache : NSObject {
    private class NSCacheEntry {
        var key: AnyObject
        var value: AnyObject
        var cost: Int
        var prevByCost: NSCacheEntry?
        var nextByCost: NSCacheEntry?
        init(key: AnyObject, value: AnyObject, cost: Int) {
            self.key = key
            self.value = value
            self.cost = cost
        }
    }
    
    private var _entries = Dictionary<UnsafePointer<Void>, NSCacheEntry>()
    private let _lock = NSLock()
    private var _totalCost = 0
    private var _byCost: NSCacheEntry?
    
    public var name: String = ""
    public var totalCostLimit: Int = -1 // limits are imprecise/not strict
    public var countLimit: Int = -1 // limits are imprecise/not strict
    public var evictsObjectsWithDiscardedContent: Bool = false

    public override init() {
        
    }
    
    public weak var delegate: NSCacheDelegate?
    
    public func objectForKey(key: AnyObject) -> AnyObject? {
        var object: AnyObject?
        
        let keyRef = unsafeBitCast(key, UnsafePointer<Void>.self)
        
        _lock.lock()
        if let entry = _entries[keyRef] {
            object = entry.value
        }
        _lock.unlock()
        
        return object
    }
    
    public func setObject(obj: AnyObject, forKey key: AnyObject) {
        setObject(obj, forKey: key, cost: 0)
    }
    
    private func remove(entry: NSCacheEntry) {
        let oldPrev = entry.prevByCost
        let oldNext = entry.nextByCost
        oldPrev?.nextByCost = oldNext
        oldNext?.prevByCost = oldPrev
        if entry === _byCost {
            _byCost = entry.nextByCost
        }
    }
   
    private func insert(entry: NSCacheEntry) {
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
    
    public func setObject(obj: AnyObject, forKey key: AnyObject, cost g: Int) {
        let keyRef = unsafeBitCast(key, UnsafePointer<Void>.self)
        
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
            _entries[keyRef] = NSCacheEntry(key: key, value: obj, cost: g)
        }
        _lock.unlock()
        
        var toRemove = [NSCacheEntry]()
        
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
                del.cache(self, willEvictObject: entry.value)
            }
        }
        
        _lock.lock()
        for entry in toRemove {
            _entries.removeValueForKey(unsafeBitCast(entry.key, UnsafePointer<Void>.self)) // the cost list is already fixed up in the purge routines
        }
        _lock.unlock()
    }
    
    public func removeObjectForKey(key: AnyObject) {
        let keyRef = unsafeBitCast(key, UnsafePointer<Void>.self)
        
        _lock.lock()
        if let entry = _entries.removeValueForKey(keyRef) {
            _totalCost -= entry.cost
            remove(entry)
        }
        _lock.unlock()
    }
    
    public func removeAllObjects() {
        _lock.lock()
        _entries.removeAll()
        _byCost = nil
        _totalCost = 0
        _lock.unlock()
    }    
}

public protocol NSCacheDelegate : class {
    func cache(cache: NSCache, willEvictObject obj: AnyObject)
}

extension NSCacheDelegate {
    func cache(cache: NSCache, willEvictObject obj: AnyObject) {
        // Default implementation does nothing
    }
}
