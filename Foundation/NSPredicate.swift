// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Predicates wrap some combination of expressions and operators and when evaluated return a BOOL.

open class NSPredicate : NSObject, NSSecureCoding, NSCopying {

    private enum PredicateKind {
        case boolean(Bool)
        case block((Any?, [String : Any]?) -> Bool)
        case format(String)
        case metadataQuery(String)
    }

    private let kind: PredicateKind

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        let encodedBool = aDecoder.decodeBool(forKey: "NS.boolean.value")
        self.kind = .boolean(encodedBool)
        
        super.init()
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        //TODO: store kind key for .boolean, .format, .metadataQuery
        
        switch self.kind {
        case .boolean(let value):
            aCoder.encode(value, forKey: "NS.boolean.value")
        case .block:
            preconditionFailure("NSBlockPredicate cannot be encoded or decoded.")
        case .format:
            NSUnimplemented()
        case .metadataQuery:
            NSUnimplemented()
        }
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        switch self.kind {
        case .boolean(let value):
            return NSPredicate(value: value)
        case .block(let block):
            return NSPredicate(block: block)
        case .format:
            NSUnimplemented()
        case .metadataQuery:
            NSUnimplemented()
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
            case (.format, .format):
                NSUnimplemented()
            case (.metadataQuery, .metadataQuery):
                NSUnimplemented()
            default:
                // NSBlockPredicate returns false even for copy
                return false
            }
        }
    }
    
    // Parse predicateFormat and return an appropriate predicate
    public init(format predicateFormat: String, argumentArray arguments: [Any]?) { NSUnimplemented() }
    
    public init(format predicateFormat: String, arguments argList: CVaListPointer) { NSUnimplemented() }

    public init?(fromMetadataQueryString queryString: String) { NSUnimplemented() }
    
    public init(value: Bool) {
        kind = .boolean(value)
        super.init()
    } // return predicates that always evaluate to true/false

    public init(block: @escaping (Any?, [String : Any]?) -> Bool) {
        kind = .block(block)
        super.init()
    }
    
    open var predicateFormat: String {
        switch self.kind {
        case .boolean(let value):
            return value ? "TRUEPREDICATE" : "FALSEPREDICATE"
        case .block:
            // TODO: Bring NSBlockPredicate's predicateFormat to macOS's Foundation version
            // let address = unsafeBitCast(block, to: Int.self)
            // return String(format:"BLOCKPREDICATE(%2X)", address)
            return "BLOCKPREDICATE"
        case .format:
            NSUnimplemented()
        case .metadataQuery:
            NSUnimplemented()
        }
    }
    
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
        case .format:
            NSUnimplemented()
        case .metadataQuery:
            NSUnimplemented()
        }
    } // single pass evaluation substituting variables from the bindings dictionary for any variable expressions encountered
    
    open func allowEvaluation() { NSUnimplemented() } // Force a predicate which was securely decoded to allow evaluation
}

extension NSPredicate {
    public convenience init(format predicateFormat: String, _ args: CVarArg...) { NSUnimplemented() }
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
