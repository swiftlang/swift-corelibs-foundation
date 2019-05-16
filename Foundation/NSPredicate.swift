// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Predicates wrap some combination of expressions and operators and when evaluated return a BOOL.

// NSPredicates are supported only in a limited form in swift-corelibs-foundation:
// - We only support predicates that do not use strings. Metadata queries and format strings are not supported in swift-corelibs-foundation.
// - We do not support archiving predicates. NSPredicate does not conform to NSSecureCoding in swift-corelibs-foundation.
// We support the following features for compatibility with XCTest:
// - Predicates that are always true or false.
// - Predicates built using a closure.
// - Compound predicates that include the two kinds above. Use NSCompoundPredicate to construct these.
open class NSPredicate : NSObject, NSCopying {

    private enum PredicateKind {
        case boolean(Bool)
        case block((Any?, [String : Any]?) -> Bool)
    }

    private let kind: PredicateKind

    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        switch kind {
        case .boolean(let bool):
            return NSPredicate(value: bool)
        case .block(let block):
            return NSPredicate(block: block)
        }
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSPredicate else { return false }
        
        if other === self {
            return true
        } else {
            switch (other.kind, self.kind) {
            case (.boolean(let otherBool), .boolean(let selfBool)):
                return otherBool == selfBool
            default:
                // NSBlockPredicate returns false even for copy
                return false
            }
        }
    }
    
    @available(*, unavailable, message: "Predicate strings and key-value coding are not supported in swift-corelibs-foundation. Use a closure instead if possible.", renamed: "init(block:)")
    public init(format predicateFormat: String, argumentArray arguments: [Any]?) { NSUnsupported() }
    
    @available(*, unavailable, message: "Predicate strings and key-value coding are not supported in swift-corelibs-foundation. Use a closure instead if possible.", renamed: "init(block:)")
    public init(format predicateFormat: String, arguments argList: CVaListPointer) { NSUnsupported() }

    @available(*, unavailable, message: "Spotlight queries are not supported by swift-corelibs-foundation")
    public init?(fromMetadataQueryString queryString: String) { NSUnsupported() }
    
    public init(value: Bool) {
        kind = .boolean(value)
        super.init()
    } // return predicates that always evaluate to true/false

    public init(block: @escaping (Any?, [String : Any]?) -> Bool) {
        kind = .block(block)
        super.init()
    }
    
    @available(*, deprecated, message: "Predicate strings are not supported in swift-corelibs-foundation. The string returned by this method is not useful outside of this process and should not be serialized.")
    open var predicateFormat: String {
        switch self.kind {
        case .boolean(let value):
            return value ? "TRUEPREDICATE" : "FALSEPREDICATE"
        case .block:
            return "BLOCKPREDICATE"
        }
    }
    
    @available(*, unavailable, message: "Predicates with substitution variables are not supported in swift-corelibs-foundation.")
    open func withSubstitutionVariables(_ variables: [String : Any]) -> Self { NSUnsupported() } // substitute constant values for variables
    
    open func evaluate(with object: Any?) -> Bool {
        return evaluate(with: object, substitutionVariables: nil)
    } // evaluate a predicate against a single object
    
    open func evaluate(with object: Any?, substitutionVariables bindings: [String : Any]?) -> Bool {
        switch kind {
        case let .boolean(value):
            return value
        case let .block(block):
            return block(object, bindings)
        }
    } // single pass evaluation substituting variables from the bindings dictionary for any variable expressions encountered
    
    @available(*, unavailable, message: "Archived predicates are not supported in swift-corelibs-foundation.")
    open func allowEvaluation() { NSUnsupported() } // Force a predicate which was securely decoded to allow evaluation
}

extension NSPredicate {
    @available(*, unavailable, message: "Predicate strings and key-value coding are not supported in swift-corelibs-foundation. Use a closure instead if possible.", renamed: "init(block:)")
    public convenience init(format predicateFormat: String, _ args: CVarArg...) { NSUnsupported() }
}

extension NSArray {
    open func filtered(using predicate: NSPredicate) -> [Any] {
        return allObjects.filter({ object in
            return predicate.evaluate(with: object)
        })
    }
}

extension NSMutableArray {
    open func filter(using predicate: NSPredicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjects(at: indexesToRemove)
    }
}

extension NSSet {
    open func filtered(using predicate: NSPredicate) -> Set<AnyHashable> {
        let objs = allObjects.filter { (object) -> Bool in
            return predicate.evaluate(with: object)
        }
        return Set(objs.map { $0 as! AnyHashable })
    }
}

extension NSMutableSet {
    open func filter(using predicate: NSPredicate) {
        for object in self {
            if !predicate.evaluate(with: object) {
                self.remove(object)
            }
        }
    }
}

extension NSOrderedSet {
    open func filtered(using predicate: NSPredicate) -> NSOrderedSet {
        return NSOrderedSet(array: self.allObjects.filter({ object in
            return predicate.evaluate(with: object)
        }))
    }
}

extension NSMutableOrderedSet {
    open func filter(using predicate: NSPredicate) {
        var indexesToRemove = IndexSet()
        for (index, object) in self.enumerated() {
            if !predicate.evaluate(with: object) {
                indexesToRemove.insert(index)
            }
        }
        self.removeObjects(at: indexesToRemove)
    }
}
