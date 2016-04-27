// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Compound predicates are predicates which act on the results of evaluating other operators. We provide the basic boolean operators: AND, OR, and NOT.

public enum NSCompoundPredicateType : UInt {
    
    case NotPredicateType
    case AndPredicateType
    case OrPredicateType
}

public class NSCompoundPredicate : NSPredicate {
    
    public init(type: NSCompoundPredicateType, subpredicates: [NSPredicate]) {
        if type == .NotPredicateType && subpredicates.count == 0 {
            preconditionFailure("Unsupported predicate count of \(subpredicates.count) for \(type)")
        }
        self.compoundPredicateType = type
        self.subpredicates = subpredicates
        super.init(value: false)
    }
    public required init?(coder: NSCoder) { NSUnimplemented() }
    
    public let compoundPredicateType: NSCompoundPredicateType
    public let subpredicates: [NSPredicate]

    /*** Convenience Methods ***/
    public convenience init(andPredicateWithSubpredicates subpredicates: [NSPredicate]) {
        self.init(type: .AndPredicateType, subpredicates: subpredicates)
    }
    public convenience init(orPredicateWithSubpredicates subpredicates: [NSPredicate]) {
        self.init(type: .OrPredicateType, subpredicates: subpredicates)
    }
    public convenience init(notPredicateWithSubpredicate predicate: NSPredicate) {
        self.init(type: .NotPredicateType, subpredicates: [predicate])
    }

    override public func evaluateWithObject(_ object: AnyObject?, substitutionVariables bindings: [String : AnyObject]?) -> Bool {
        switch compoundPredicateType {
        case .AndPredicateType:
            return subpredicates.reduce(true, combine: {
                $0 && $1.evaluateWithObject(object, substitutionVariables: bindings)
            })
        case .OrPredicateType:
            return subpredicates.reduce(false, combine: {
                $0 || $1.evaluateWithObject(object, substitutionVariables: bindings)
            })
        case .NotPredicateType:
            // safe to get the 0th item here since we trap if there's not at least one on init
            return !(subpredicates[0].evaluateWithObject(object, substitutionVariables: bindings))
        }
    }
}
