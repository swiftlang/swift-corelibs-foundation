// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Compound predicates are predicates which act on the results of evaluating other operators. We provide the basic boolean operators: AND, OR, and NOT.

extension CompoundPredicate {
    public enum LogicalType : UInt {
        
        case not
        case and
        case or
    }
}

open class CompoundPredicate : Predicate {
    
    public init(type: LogicalType, subpredicates: [Predicate]) {
        if type == .not && subpredicates.count == 0 {
            preconditionFailure("Unsupported predicate count of \(subpredicates.count) for \(type)")
        }
        self.compoundPredicateType = type
        self.subpredicates = subpredicates
        super.init(value: false)
    }
    public required init?(coder: NSCoder) { NSUnimplemented() }
    
    public let compoundPredicateType: LogicalType
    public let subpredicates: [Predicate]

    /*** Convenience Methods ***/
    public convenience init(andPredicateWithSubpredicates subpredicates: [Predicate]) {
        self.init(type: .and, subpredicates: subpredicates)
    }
    public convenience init(orPredicateWithSubpredicates subpredicates: [Predicate]) {
        self.init(type: .or, subpredicates: subpredicates)
    }
    public convenience init(notPredicateWithSubpredicate predicate: Predicate) {
        self.init(type: .not, subpredicates: [predicate])
    }

    override open func evaluate(with object: Any?, substitutionVariables bindings: [String : Any]?) -> Bool {
        switch compoundPredicateType {
        case .and:
            return subpredicates.reduce(true, {
                $0 && $1.evaluate(with: object, substitutionVariables: bindings)
            })
        case .or:
            return subpredicates.reduce(false, {
                $0 || $1.evaluate(with: object, substitutionVariables: bindings)
            })
        case .not:
            // safe to get the 0th item here since we trap if there's not at least one on init
            return !(subpredicates[0].evaluate(with: object, substitutionVariables: bindings))
        }
    }
}
