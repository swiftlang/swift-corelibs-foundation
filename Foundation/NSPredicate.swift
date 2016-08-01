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
        case block((AnyObject?, [String : AnyObject]?) -> Bool)
        // TODO: case for init(format:argumentArray:)
        // TODO: case for init(fromMetadataQueryString:)
    }

    private let kind: PredicateKind

    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }
    
    // Parse predicateFormat and return an appropriate predicate
    public init(format predicateFormat: String, argumentArray arguments: [AnyObject]?) { NSUnimplemented() }
    
    public init?(fromMetadataQueryString queryString: String) { NSUnimplemented() }
    
    public init(value: Bool) {
        kind = .boolean(value)
        super.init()
    } // return predicates that always evaluate to true/false

    public init(block: @escaping (AnyObject?, [String : AnyObject]?) -> Bool) {
        kind = .block(block)
        super.init()
    }
    
    open var predicateFormat: String  { NSUnimplemented() } // returns the format string of the predicate
    
    open func withSubstitutionVariables(_ variables: [String : AnyObject]) -> Self { NSUnimplemented() } // substitute constant values for variables
    
    open func evaluate(with object: AnyObject?) -> Bool {
        return evaluate(with: object, substitutionVariables: nil)
    } // evaluate a predicate against a single object
    
    open func evaluate(with object: AnyObject?, substitutionVariables bindings: [String : AnyObject]?) -> Bool {
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
    public func filteredArrayUsingPredicate(_ predicate: Predicate) -> [AnyObject] {
        return bridge().filter({ object in
            return predicate.evaluate(with: object)
        })
    } // evaluate a predicate against an array of objects and return a filtered array
}

extension NSMutableArray {
    public func filterUsingPredicate(_ predicate: Predicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjectsAtIndexes(indexesToRemove)
    } // evaluate a predicate against an array of objects and filter the mutable array directly
}

extension NSSet {
    public func filteredSetUsingPredicate(_ predicate: Predicate) -> Set<NSObject> {
        return Set(bridge().filter({ object in
            return predicate.evaluate(with: object)
        }))
    } // evaluate a predicate against a set of objects and return a filtered set
}

extension NSMutableSet {
    public func filterUsingPredicate(_ predicate: Predicate) {
        for object in self {
            if !predicate.evaluate(with: object) {
                self.remove(object)
            }
        }
    } // evaluate a predicate against a set of objects and filter the mutable set directly
}

extension NSOrderedSet {
    public func filteredOrderedSetUsingPredicate(_ predicate: Predicate) -> NSOrderedSet {
        return NSOrderedSet(array: self._orderedStorage.bridge().filter({ object in
            return predicate.evaluate(with: object)
        }))
    } // evaluate a predicate against an ordered set of objects and return a filtered ordered set
}

extension NSMutableOrderedSet {
    public func filterUsingPredicate(_ predicate: Predicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjectsAtIndexes(indexesToRemove)
    } // evaluate a predicate against an ordered set of objects and filter the mutable ordered set directly
}
