// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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
    
    public init(type: NSCompoundPredicateType, subpredicates: [NSPredicate]) { NSUnimplemented() }
    public required init?(coder: NSCoder) { NSUnimplemented() }
    
    public var compoundPredicateType: NSCompoundPredicateType { NSUnimplemented() }
    public var subpredicates: [AnyObject] { NSUnimplemented() }
    
    /*** Convenience Methods ***/
    public init(andPredicateWithSubpredicates subpredicates: [NSPredicate]) { NSUnimplemented() }
    public init(orPredicateWithSubpredicates subpredicates: [NSPredicate]) { NSUnimplemented() }
    public init(notPredicateWithSubpredicate predicate: NSPredicate) { NSUnimplemented() }
}
