// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Expressions are the core of the predicate implementation. When expressionValueWithObject: is called, the expression is evaluated, and a value returned which can then be handled by an operator. Expressions can be anything from constants to method invocations. Scalars should be wrapped in appropriate NSValue classes.
extension NSExpression {
    public enum ExpressionType : UInt {
        
        case constantValue // Expression that always returns the same value
        case evaluatedObject // Expression that always returns the parameter object itself
        case variable // Expression that always returns whatever is stored at 'variable' in the bindings dictionary
        case keyPath // Expression that returns something that can be used as a key path
        case function // Expression that returns the result of evaluating a symbol
        case unionSet // Expression that returns the result of doing a unionSet: on two expressions that evaluate to flat collections (arrays or sets)
        case intersectSet // Expression that returns the result of doing an intersectSet: on two expressions that evaluate to flat collections (arrays or sets)
        case minusSet // Expression that returns the result of doing a minusSet: on two expressions that evaluate to flat collections (arrays or sets)
        case subquery
        case aggregate
        case anyKey
        case block
        case conditional
    }
}

open class NSExpression : NSObject, NSSecureCoding, NSCopying {
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }

    public /*not inherited*/ init(format expressionFormat: String, argumentArray arguments: [Any]) { NSUnimplemented() }
    public /*not inherited*/ init(format expressionFormat: String, arguments argList: CVaListPointer) { NSUnimplemented() }
    
    public /*not inherited*/ init(forConstantValue obj: Any?) { NSUnimplemented() } // Expression that returns a constant value
    open class func expressionForEvaluatedObject() -> NSExpression { NSUnimplemented() } // Expression that returns the object being evaluated
    public /*not inherited*/ init(forVariable string: String) { NSUnimplemented() } // Expression that pulls a value from the variable bindings dictionary
    public /*not inherited*/ init(forKeyPath keyPath: String) { NSUnimplemented() } // Expression that invokes valueForKeyPath with keyPath
    public /*not inherited*/ init(forFunction name: String, arguments parameters: [Any]) { NSUnimplemented() } // Expression that invokes one of the predefined functions. Will throw immediately if the selector is bad; will throw at runtime if the parameters are incorrect.
    // Predefined functions are:
    // name              parameter array contents				returns
    //-------------------------------------------------------------------------------------------------------------------------------------
    // sum:              NSExpression instances representing numbers		NSNumber 
    // count:            NSExpression instances representing numbers		NSNumber 
    // min:              NSExpression instances representing numbers		NSNumber  
    // max:              NSExpression instances representing numbers		NSNumber
    // average:          NSExpression instances representing numbers		NSNumber
    // median:           NSExpression instances representing numbers		NSNumber
    // mode:             NSExpression instances representing numbers		NSArray	    (returned array will contain all occurrences of the mode)
    // stddev:           NSExpression instances representing numbers		NSNumber
    // add:to:           NSExpression instances representing numbers		NSNumber
    // from:subtract:    two NSExpression instances representing numbers	NSNumber
    // multiply:by:      two NSExpression instances representing numbers	NSNumber
    // divide:by:        two NSExpression instances representing numbers	NSNumber
    // modulus:by:       two NSExpression instances representing numbers	NSNumber
    // sqrt:             one NSExpression instance representing numbers		NSNumber
    // log:              one NSExpression instance representing a number	NSNumber
    // ln:               one NSExpression instance representing a number	NSNumber
    // raise:toPower:    one NSExpression instance representing a number	NSNumber
    // exp:              one NSExpression instance representing a number	NSNumber
    // floor:            one NSExpression instance representing a number	NSNumber
    // ceiling:          one NSExpression instance representing a number	NSNumber
    // abs:              one NSExpression instance representing a number	NSNumber
    // trunc:            one NSExpression instance representing a number	NSNumber
    // uppercase:	 one NSExpression instance representing a string	NSString
    // lowercase:	 one NSExpression instance representing a string	NSString
    // random            none							NSNumber (integer) 
    // randomn:          one NSExpression instance representing a number	NSNumber (integer) such that 0 <= rand < param
    // now               none							[NSDate now]
    // bitwiseAnd:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // bitwiseOr:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // bitwiseXor:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // leftshift:by:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // rightshift:by:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // onesComplement:	 one NSExpression instance representing a numbers	NSNumber    (numbers will be treated as NSInteger)
    // noindex:		 an NSExpression					parameter   (used by CoreData to indicate that an index should be dropped)
    // distanceToLocation:fromLocation:
    //                   two NSExpression instances representing CLLocations    NSNumber
    // length:           an NSExpression instance representing a string         NSNumber
    
    public /*not inherited*/ init(forAggregate subexpressions: [Any]) { NSUnimplemented() } // Expression that returns a collection containing the results of other expressions
    public /*not inherited*/ init(forUnionSet left: NSExpression, with right: NSExpression) { NSUnimplemented() } // return an expression that will return the union of the collections expressed by left and right
    public /*not inherited*/ init(forIntersectSet left: NSExpression, with right: NSExpression) { NSUnimplemented() } // return an expression that will return the intersection of the collections expressed by left and right
    public /*not inherited*/ init(forMinusSet left: NSExpression, with right: NSExpression) { NSUnimplemented() } // return an expression that will return the disjunction of the collections expressed by left and right
    public /*not inherited*/ init(forSubquery expression: NSExpression, usingIteratorVariable variable: String, predicate: Any) { NSUnimplemented() } // Expression that filters a collection by storing elements in the collection in the variable variable and keeping the elements for which qualifer returns true; variable is used as a local variable, and will shadow any instances of variable in the bindings dictionary, the variable is removed or the old value replaced once evaluation completes
    public /*not inherited*/ init(forFunction target: NSExpression, selectorName name: String, arguments parameters: [Any]?) { NSUnimplemented() } // Expression that invokes the selector on target with parameters. Will throw at runtime if target does not implement selector or if parameters are wrong.
    open class func expressionForAnyKey() -> NSExpression { NSUnimplemented() }
    public /*not inherited*/ init(block: @escaping (Any?, [Any], NSMutableDictionary?) -> Any, arguments: [NSExpression]?) { NSUnimplemented() } // Expression that invokes the block with the parameters; note that block expressions are not encodable or representable as parseable strings.
    public /*not inherited*/ init(forConditional predicate: Any, trueExpression: NSExpression, falseExpression: NSExpression) { NSUnimplemented() } // Expression that will return the result of trueExpression or falseExpression depending on the value of predicate
    
    public init(expressionType type: ExpressionType) { NSUnimplemented() }
    
    // accessors for individual parameters - raise if not applicable
    open var expressionType: ExpressionType { NSUnimplemented() }
    open var constantValue: Any { NSUnimplemented() }
    open var keyPath: String { NSUnimplemented() }
    open var function: String { NSUnimplemented() }
    open var variable: String { NSUnimplemented() }
    /*@NSCopying*/ open var operand: NSExpression { NSUnimplemented() } // the object on which the selector will be invoked (the result of evaluating a key path or one of the defined functions)
    open var arguments: [NSExpression]? { NSUnimplemented() } // array of expressions which will be passed as parameters during invocation of the selector on the operand of a function expression
    
    open var collection: Any { NSUnimplemented() }
    /*@NSCopying*/ open var predicate: NSPredicate { NSUnimplemented() }
    /*@NSCopying*/ open var left: NSExpression { NSUnimplemented() } // expression which represents the left side of a set expression
    /*@NSCopying*/ open var right: NSExpression { NSUnimplemented() } // expression which represents the right side of a set expression
    
    /*@NSCopying*/ open var `true`: NSExpression { NSUnimplemented() } // expression which will be evaluated if a conditional expression's predicate evaluates to true
    /*@NSCopying*/ open var `false`: NSExpression { NSUnimplemented() } // expression which will be evaluated if a conditional expression's predicate evaluates to false
    
    open var expressionBlock: (Any?, [Any], NSMutableDictionary?) -> Any { NSUnimplemented() }
    
    // evaluate the expression using the object and bindings- note that context is mutable here and can be used by expressions to store temporary state for one predicate evaluation
    open func expressionValue(with object: Any?, context: NSMutableDictionary?) -> Any? { NSUnimplemented() }
    
    open func allowEvaluation() { NSUnimplemented() } // Force an expression which was securely decoded to allow evaluation
}

extension NSExpression {
    public convenience init(format expressionFormat: String, _ args: CVarArg...) { NSUnimplemented() }
}
