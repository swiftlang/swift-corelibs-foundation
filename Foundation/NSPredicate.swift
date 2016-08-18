// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Predicates wrap some combination of expressions and operators and when evaluated return a BOOL.

open class Predicate : NSObject, NSSecureCoding, NSCopying {

    private enum PredicateKind {
        case boolean(Bool)
        case block((Any?, [String : Any]?) -> Bool)
        // TODO: case for init(format:argumentArray:)
        // TODO: case for init(fromMetadataQueryString:)
    }

    private let kind: PredicateKind

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }
    
    // Parse predicateFormat and return an appropriate predicate
    public init(format predicateFormat: String, argumentArray arguments: [Any]?) { NSUnimplemented() }
    
    public init?(fromMetadataQueryString queryString: String) { NSUnimplemented() }
    
    public init(value: Bool) {
        kind = .boolean(value)
        super.init()
    } // return predicates that always evaluate to true/false

    public init(block: @escaping (Any?, [String : Any]?) -> Bool) {
        kind = .block(block)
        super.init()
    }
    
    open var predicateFormat: String  { NSUnimplemented() } // returns the format string of the predicate
    
    open func withSubstitutionVariables(_ variables: [String : Any]) -> Self { NSUnimplemented() } // substitute constant values for variables
    
    open func evaluate(with object: Any?) -> Bool {
        return evaluate(with: object, substitutionVariables: nil)
    } // evaluate a predicate against a single object
    
    open func evaluate(with object: Any?, substitutionVariables bindings: [String : Any]?) -> Bool {
        if bindings != nil {
            NSUnimplemented()
        }

        switch kind {
        case let .boolean(value):
            return value
        case let .block(block):
            return block(object, bindings)
        }
    } // single pass evaluation substituting variables from the bindings dictionary for any variable expressions encountered
    
    open func allowEvaluation() { NSUnimplemented() } // Force a predicate which was securely decoded to allow evaluation
}


extension NSArray {
     // evaluate a predicate against an array of objects and return a filtered array
    open func filtered(using predicate: Predicate) -> [Any] {
        return allObjects.filter({ object in
            return predicate.evaluate(with: object)
        })
    }
}

extension NSMutableArray {
    // evaluate a predicate against an array of objects and filter the mutable array directly
    open func filter(using predicate: Predicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjectsAtIndexes(indexesToRemove)
    }
}

extension NSSet {
    // evaluate a predicate against a set of objects and return a filtered set
    open func filtered(using predicate: Predicate) -> Set<AnyHashable> {
        let objs = allObjects.filter { (object) -> Bool in
            return predicate.evaluate(with: object)
        }
        return Set(objs.map { $0 as! AnyHashable })
    }
}

extension NSMutableSet {
    // evaluate a predicate against a set of objects and filter the mutable set directly
    open func filter(using predicate: Predicate) {
        for object in self {
            if !predicate.evaluate(with: object) {
                self.remove(object)
            }
        }
    }
}

extension NSOrderedSet {
    // evaluate a predicate against an ordered set of objects and return a filtered ordered set
    open func filtered(using p: Predicate) -> NSOrderedSet {
        return NSOrderedSet(array: self._orderedStorage.filter({ object in
            return p.evaluate(with: object)
        }))
    }
}

extension NSMutableOrderedSet {
    // evaluate a predicate against an ordered set of objects and filter the mutable ordered set directly
    open func filter(using p: Predicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !p.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjects(at: indexesToRemove)
    }
}
