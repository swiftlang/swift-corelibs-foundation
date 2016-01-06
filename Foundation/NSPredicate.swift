// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Predicates wrap some combination of expressions and operators and when evaluated return a BOOL.

public class NSPredicate : NSObject, NSSecureCoding, NSCopying {
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    // Parse predicateFormat and return an appropriate predicate
    public init(format predicateFormat: String, argumentArray arguments: [AnyObject]?) { NSUnimplemented() }
    
    public init?(fromMetadataQueryString queryString: String) { NSUnimplemented() }
    
    public init(value: Bool) { NSUnimplemented() } // return predicates that always evaluate to true/false
    
    public init(block: (AnyObject, [String : AnyObject]?) -> Bool) { NSUnimplemented() }
    
    public var predicateFormat: String  { NSUnimplemented() } // returns the format string of the predicate
    
    public func predicateWithSubstitutionVariables(variables: [String : AnyObject]) -> Self { NSUnimplemented() } // substitute constant values for variables
    
    public func evaluateWithObject(object: AnyObject?) -> Bool { NSUnimplemented() } // evaluate a predicate against a single object
    
    public func evaluateWithObject(object: AnyObject?, substitutionVariables bindings: [String : AnyObject]?) -> Bool { NSUnimplemented() } // single pass evaluation substituting variables from the bindings dictionary for any variable expressions encountered
    
    public func allowEvaluation() { NSUnimplemented() } // Force a predicate which was securely decoded to allow evaluation
}

extension NSArray {
    public func filteredArrayUsingPredicate(predicate: NSPredicate) -> [AnyObject] { NSUnimplemented() } // evaluate a predicate against an array of objects and return a filtered array
}

extension NSMutableArray {
    public func filterUsingPredicate(predicate: NSPredicate) { NSUnimplemented() } // evaluate a predicate against an array of objects and filter the mutable array directly
}

extension NSSet {
    public func filteredSetUsingPredicate(predicate: NSPredicate) -> Set<NSObject> { NSUnimplemented() } // evaluate a predicate against a set of objects and return a filtered set
}

extension NSMutableSet {
    public func filterUsingPredicate(predicate: NSPredicate) { NSUnimplemented() } // evaluate a predicate against a set of objects and filter the mutable set directly
}

extension NSOrderedSet {
    
    public func filteredOrderedSetUsingPredicate(p: NSPredicate) -> NSOrderedSet { NSUnimplemented() } // evaluate a predicate against an ordered set of objects and return a filtered ordered set
}

extension NSMutableOrderedSet {
    
    public func filterUsingPredicate(p: NSPredicate) { NSUnimplemented() } // evaluate a predicate against an ordered set of objects and filter the mutable ordered set directly
}


