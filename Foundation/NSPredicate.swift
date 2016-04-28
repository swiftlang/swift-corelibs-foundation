// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Predicates wrap some combination of expressions and operators and when evaluated return a BOOL.

public class NSPredicate : NSObject, NSSecureCoding, NSCopying {

    private enum PredicateKind {
        case Boolean(Bool)
        case Block((AnyObject?, [String : AnyObject]?) -> Bool)
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
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    // Parse predicateFormat and return an appropriate predicate
    public init(format predicateFormat: String, argumentArray arguments: [AnyObject]?) { NSUnimplemented() }
    
    public init?(fromMetadataQueryString queryString: String) { NSUnimplemented() }
    
    public init(value: Bool) {
        kind = .Boolean(value)
        super.init()
    } // return predicates that always evaluate to true/false

    public init(block: (AnyObject?, [String : AnyObject]?) -> Bool) {
        kind = .Block(block)
        super.init()
    }
    
    public var predicateFormat: String  { NSUnimplemented() } // returns the format string of the predicate
    
    public func predicateWithSubstitutionVariables(_ variables: [String : AnyObject]) -> Self { NSUnimplemented() } // substitute constant values for variables
    
    public func evaluateWithObject(_ object: AnyObject?) -> Bool {
        return evaluateWithObject(object, substitutionVariables: nil)
    } // evaluate a predicate against a single object
    
    public func evaluateWithObject(_ object: AnyObject?, substitutionVariables bindings: [String : AnyObject]?) -> Bool {
        if bindings != nil {
            NSUnimplemented()
        }

        switch kind {
        case let .Boolean(value):
            return value
        case let .Block(block):
            return block(object, bindings)
        }
    } // single pass evaluation substituting variables from the bindings dictionary for any variable expressions encountered
    
    public func allowEvaluation() { NSUnimplemented() } // Force a predicate which was securely decoded to allow evaluation
}

extension NSArray {
    public func filteredArrayUsingPredicate(_ predicate: NSPredicate) -> [AnyObject] {
        return bridge().filter({ object in
            return predicate.evaluateWithObject(object)
        })
    } // evaluate a predicate against an array of objects and return a filtered array
}

extension NSMutableArray {
    public func filterUsingPredicate(_ predicate: NSPredicate) {
        let indexesToRemove = NSMutableIndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluateWithObject(object) {
                indexesToRemove.addIndex(index)
            }
        }
        self.removeObjectsAtIndexes(indexesToRemove)
    } // evaluate a predicate against an array of objects and filter the mutable array directly
}

extension NSSet {
    public func filteredSetUsingPredicate(_ predicate: NSPredicate) -> Set<NSObject> {
        return Set(bridge().filter({ object in
            return predicate.evaluateWithObject(object)
        }))
    } // evaluate a predicate against a set of objects and return a filtered set
}

extension NSMutableSet {
    public func filterUsingPredicate(_ predicate: NSPredicate) {
        for object in self {
            if !predicate.evaluateWithObject(object) {
                self.removeObject(object)
            }
        }
    } // evaluate a predicate against a set of objects and filter the mutable set directly
}

extension NSOrderedSet {
    public func filteredOrderedSetUsingPredicate(_ predicate: NSPredicate) -> NSOrderedSet {
        return NSOrderedSet(array: self._orderedStorage.bridge().filter({ object in
            return predicate.evaluateWithObject(object)
        }))
    } // evaluate a predicate against an ordered set of objects and return a filtered ordered set
}

extension NSMutableOrderedSet {
    public func filterUsingPredicate(_ predicate: NSPredicate) {
        let indexesToRemove = NSMutableIndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluateWithObject(object) {
                indexesToRemove.addIndex(index)
            }
        }
        self.removeObjectsAtIndexes(indexesToRemove)
    } // evaluate a predicate against an ordered set of objects and filter the mutable ordered set directly
}
