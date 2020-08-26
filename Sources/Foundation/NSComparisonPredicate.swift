// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Comparison predicates are predicates which do some form of comparison between the results of two expressions and return a BOOL. They take an operator, a left expression, and a right expression, and return the result of invoking the operator with the results of evaluating the expressions.
@available(*, deprecated, message: "NSExpression and classes that rely on its functionality are unsupported in swift-corelibs-foundation: NSComparisonPredicate is unavailable.")
open class NSComparisonPredicate : NSPredicate {
    
    @available(*, unavailable, message: "NSComparisonPredicate is unsupported in swift-corelibs-foundation. Use a closure-based NSPredicate instead if possible.")
    public init(leftExpression lhs: NSExpression, rightExpression rhs: NSExpression, modifier: Modifier, type: Operator, options: Options) { NSUnsupported() }
    
    @available(*, unavailable, message: "NSComparisonPredicate is unavailable.")
    open var predicateOperatorType: Operator { NSUnsupported() }

    @available(*, unavailable, message: "NSComparisonPredicate is unavailable.")
    open var comparisonPredicateModifier: Modifier { NSUnsupported() }

    @available(*, unavailable, message: "NSComparisonPredicate is unavailable.")
    open var leftExpression: NSExpression { NSUnsupported() }

    @available(*, unavailable, message: "NSComparisonPredicate is unavailable.")
    open var rightExpression: NSExpression { NSUnsupported() }

    @available(*, unavailable, message: "NSComparisonPredicate is unavailable.")
    open var options: Options { NSUnsupported() }

    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let caseInsensitive = Options(rawValue : 0x1)
        public static let diacriticInsensitive = Options(rawValue : 0x2)
        public static let normalized = Options(rawValue : 0x4) /* Indicate that the strings to be compared have been preprocessed; this supersedes other options and is intended as a performance optimization option */
    }
    
    // Describes how the operator is modified: can be direct, ALL, or ANY
    public enum Modifier : UInt {
        case direct // Do a direct comparison
        case all // ALL toMany.x = y
        case any // ANY toMany.x = y
    }
    
    // Type basic set of operators defined. Most are obvious
    public enum Operator : UInt {
        case lessThan // compare: returns NSOrderedAscending
        case lessThanOrEqualTo // compare: returns NSOrderedAscending || NSOrderedSame
        case greaterThan // compare: returns NSOrderedDescending
        case greaterThanOrEqualTo // compare: returns NSOrderedDescending || NSOrderedSame
        case equalTo // isEqual: returns true
        case notEqualTo // isEqual: returns false
        case matches
        case like
        case beginsWith
        case endsWith
        case `in` // rhs contains lhs returns true
        case contains // lhs contains rhs returns true
        case between
    }
}

