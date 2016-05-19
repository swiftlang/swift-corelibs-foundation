// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Flags(s) that can be passed to the factory to indicate that a operator operating on strings should do so in a case insensitive fashion.
public struct NSComparisonPredicateOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let CaseInsensitivePredicateOption = NSComparisonPredicateOptions(rawValue : 0x1)
    public static let DiacriticInsensitivePredicateOption = NSComparisonPredicateOptions(rawValue : 0x2)
    public static let NormalizedPredicateOption = NSComparisonPredicateOptions(rawValue : 0x4) /* Indicate that the strings to be compared have been preprocessed; this supersedes other options and is intended as a performance optimization option */
}

// Describes how the operator is modified: can be direct, ALL, or ANY
public enum NSComparisonPredicateModifier : UInt {
    
    case directPredicateModifier // Do a direct comparison
    case allPredicateModifier // ALL toMany.x = y
    case anyPredicateModifier // ANY toMany.x = y
}

// Type basic set of operators defined. Most are obvious
public enum NSPredicateOperatorType : UInt {
    
    case lessThanPredicateOperatorType // compare: returns NSOrderedAscending
    case lessThanOrEqualToPredicateOperatorType // compare: returns NSOrderedAscending || NSOrderedSame
    case greaterThanPredicateOperatorType // compare: returns NSOrderedDescending
    case greaterThanOrEqualToPredicateOperatorType // compare: returns NSOrderedDescending || NSOrderedSame
    case equalToPredicateOperatorType // isEqual: returns true
    case notEqualToPredicateOperatorType // isEqual: returns false
    case matchesPredicateOperatorType
    case likePredicateOperatorType
    case beginsWithPredicateOperatorType
    case endsWithPredicateOperatorType
    case inPredicateOperatorType // rhs contains lhs returns true
    case containsPredicateOperatorType // lhs contains rhs returns true
    case betweenPredicateOperatorType
}

// Comparison predicates are predicates which do some form of comparison between the results of two expressions and return a BOOL. They take an operator, a left expression, and a right expression, and return the result of invoking the operator with the results of evaluating the expressions.

public class NSComparisonPredicate : NSPredicate {
    
    public init(leftExpression lhs: NSExpression, rightExpression rhs: NSExpression, modifier: NSComparisonPredicateModifier, type: NSPredicateOperatorType, options: NSComparisonPredicateOptions) { NSUnimplemented() }
    public required init?(coder: NSCoder) { NSUnimplemented() }
    
    public var predicateOperatorType: NSPredicateOperatorType { NSUnimplemented() }
    public var comparisonPredicateModifier: NSComparisonPredicateModifier { NSUnimplemented() }
    public var leftExpression: NSExpression { NSUnimplemented() }
    public var rightExpression: NSExpression { NSUnimplemented() }
    public var options: NSComparisonPredicateOptions { NSUnimplemented() }
}

