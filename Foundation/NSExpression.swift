// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Expressions are the core of the predicate implementation. When expressionValueWithObject: is called, the expression is evaluated, and a value returned which can then be handled by an operator. Expressions can be anything from constants to method invocations. Scalars should be wrapped in appropriate NSValue classes.

public enum NSExpressionType : UInt {

    case ConstantValueExpressionType // Expression that always returns the same value
    case EvaluatedObjectExpressionType // Expression that always returns the parameter object itself
    case VariableExpressionType // Expression that always returns whatever is stored at 'variable' in the bindings dictionary
    case KeyPathExpressionType // Expression that returns something that can be used as a key path
    case FunctionExpressionType // Expression that returns the result of evaluating a symbol
    case UnionSetExpressionType // Expression that returns the result of doing a unionSet: on two expressions that evaluate to flat collections (arrays or sets)
    case IntersectSetExpressionType // Expression that returns the result of doing an intersectSet: on two expressions that evaluate to flat collections (arrays or sets)
    case MinusSetExpressionType // Expression that returns the result of doing a minusSet: on two expressions that evaluate to flat collections (arrays or sets)
    case SubqueryExpressionType
    case AggregateExpressionType
    case AnyKeyExpressionType
    case BlockExpressionType
    case ConditionalExpressionType
}

public class NSExpression : NSObject, NSSecureCoding, NSCopying {
    public typealias ExpressionBlockType = (AnyObject?, [AnyObject], NSMutableDictionary?) -> AnyObject?
    internal typealias EvaluateBlockType = (AnyObject?, NSMutableDictionary?) -> AnyObject?
    internal typealias SubstituteBlockType = (NSMutableDictionary) -> NSExpression
    
    internal var _evaluationBlock:EvaluateBlockType
    internal var _substitutionVariablesBlock:SubstituteBlockType?
    internal var _constantValue:AnyObject?
    internal var _keyPath: String?
    internal var _function: String?
    internal var _variable: String?
    internal var _operand: NSExpression?
    internal var _arguments: [NSExpression]?
    internal var _collection: [NSExpression]?
    internal var _predicate: NSPredicate?
    internal var _leftExpression: NSExpression?
    internal var _rightExpression: NSExpression?
    internal var _trueExpression: NSExpression?
    internal var _falseExpression: NSExpression?
    internal var _expressionBlock: ExpressionBlockType?

    public var expressionType:NSExpressionType

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

    public /*not inherited*/ init(format expressionFormat: String, argumentArray arguments: [AnyObject]) {
        NSUnimplemented()
    }

    private init(type:NSExpressionType, evaluation:EvaluateBlockType, substitution:SubstituteBlockType?=nil) {
        expressionType = type
        _evaluationBlock = evaluation
        _substitutionVariablesBlock = substitution

        super.init()
    }

    public convenience init(forConstantValue value: AnyObject?) {
        self.init(type:.ConstantValueExpressionType, evaluation:{_,_ in return value})

        _constantValue = value
    } // Expression that returns a constant value

    public class func expressionForEvaluatedObject() -> NSExpression {
        return NSExpression(type:.EvaluatedObjectExpressionType, evaluation:{o,_ in return o})
    } // Expression that returns the object being evaluated

    public convenience init(forVariable aVariable: String) {
        let evaluationBlock:EvaluateBlockType = {obj,bindings in
            guard let exp = bindings?.objectForKey(aVariable.bridge()) as? NSExpression else {
                preconditionFailure("Cannot find variable \(aVariable) in \(bindings)")
            }

            return exp.expressionValueWithObject(obj, context: bindings)
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            guard let exp = bindings.objectForKey(aVariable.bridge()) as? NSExpression else {
                preconditionFailure("Cannot find variable in \(bindings)")
            }

            return exp
        }

        self.init(type:.VariableExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        self._variable = aVariable
    } // Expression that pulls a value from the variable bindings dictionary

    public convenience init(forKeyPath keyPath: String) {
        let evaluationBlock:EvaluateBlockType = {obj,_ in
            // TODO: Change NSObjectProtocol to whatever protocol -valueForKeyPath() belongs to.
            guard let o = obj where o is NSObjectProtocol else {
                return nil
            }

            // TODO: depends on NSObject -valueForKeyPath implementation
            //return o.valueForKeyPath(keyPath)
            NSUnimplemented()
        }

        self.init(type:.KeyPathExpressionType, evaluation:evaluationBlock)

        _keyPath = keyPath

    } // Expression that invokes valueForKeyPath with keyPath

    public convenience init?(forFunction name: String, arguments parameters: [NSExpression]) {

        guard let fn = _NSExpressionFunctions[name] else {
            // TODO: failable init. Decide if we should throw instead. (Apple Foundation throws an Exception)
            print("\(name) is not a supported method")
            return nil
        }

        let evaluationBlock:EvaluateBlockType = {obj, bindings in
            var result:AnyObject?
            let args = parameters.expressionValueWithObject(obj, context: bindings)

            do {
                 result = try _invokeFunction(fn, with:args)
            } catch let NSExpressionError.InvalidArgumentType(expected: type){
                // TODO: Decide if we should throw instead. (Apple Foundation throws an Exception)
                print("InvalidArgumentType \(args.dynamicType), function \(name) expects \(type)")
                result = nil
            } catch {

            }

            return result
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let subst = parameters.map{$0.expressionWithSubstitutionVariables(bindings)}

            return NSExpression(forFunction: name, arguments: subst)!
        }

        self.init(type:.FunctionExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _function = name
        _arguments = parameters

    } // Expression that invokes one of the predefined functions. Will throw immediately if the selector is bad; will throw at runtime if the parameters are incorrect.
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
    // uppercase:	     one NSExpression instance representing a string	NSString
    // lowercase:	     one NSExpression instance representing a string	NSString
    // random            none							                    NSNumber (integer)
    // randomn:          one NSExpression instance representing a number	NSNumber (integer) such that 0 <= rand < param
    // now               none							                    [NSDate now]
    // bitwiseAnd:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // bitwiseOr:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // bitwiseXor:with:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // leftshift:by:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // rightshift:by:	 two NSExpression instances representing numbers	NSNumber    (numbers will be treated as NSInteger)
    // onesComplement:	 one NSExpression instance representing a numbers	NSNumber    (numbers will be treated as NSInteger)
    // noindex:		     an NSExpression parameter (used by CoreData to indicate that an index should be dropped)
    // distanceToLocation:fromLocation:
    //                   two NSExpression instances representing CLLocations    NSNumber
    // length:           an NSExpression instance representing a string         NSNumber

    public convenience init(forAggregate subexpressions: [NSExpression]) {
        let evaluationBlock:EvaluateBlockType = {object, bindings in
            return subexpressions.expressionValueWithObject(object, context: bindings).bridge()
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let subst = subexpressions.map{$0.expressionWithSubstitutionVariables(bindings)}
            return NSExpression(forAggregate: subst)
        }

        self.init(type:.AggregateExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _collection = subexpressions
    } // Expression that returns a collection containing the results of other expressions

    internal typealias SetFunctionType = Set<NSObject> -> (Set<NSObject>) -> Set<NSObject>

    internal convenience init(forSet type: NSExpressionType, left: NSExpression, with right: NSExpression, function:SetFunctionType, operation:String) {
        let evaluationBlock:EvaluateBlockType = {obj,bindings in
            guard let left_set = left.expressionValueWithObject(obj, context: bindings) as? NSSet else {
                return nil
            }

            guard let right_set = right.expressionValueWithObject(obj, context: bindings) as? NSSet else {
                // TODO: convert NSOrderedSet, NSDictionary, NSArray to (NS)Set
                return nil
            }

            return function(left_set.bridge())(right_set.bridge()).bridge()
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let l = left.expressionWithSubstitutionVariables(bindings),
                r = right.expressionWithSubstitutionVariables(bindings)

            return NSExpression(forSet: type, left: l, with: r, function: function, operation: operation)
        }

        self.init(type:type, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _leftExpression = left
        _rightExpression = right
    }

    public convenience init(forUnionSet left: NSExpression, with right: NSExpression) {
        self.init(forSet:.UnionSetExpressionType, left:left, with:right, function:Set.union, operation:"UNION")
    } // return an expression that will return the union of the collections expressed by left and right
    public convenience init(forIntersectSet left: NSExpression, with right: NSExpression) {
        self.init(forSet:.IntersectSetExpressionType, left:left, with:right, function:Set.intersect, operation:"INTERSECT")
    } // return an expression that will return the intersection of the collections expressed by left and right
    public convenience init(forMinusSet left: NSExpression, with right: NSExpression) {
        self.init(forSet:.MinusSetExpressionType, left:left, with:right, function:Set.subtract, operation:"MINUS")
    } // return an expression that will return the disjunction of the collections expressed by left and right

    // TODO: Subquery expression depends on NSPredicate implementation
    public convenience init(forSubquery expression: NSExpression, usingIteratorVariable variable: String, predicate: NSPredicate) {
        let evaluationBlock:EvaluateBlockType = {object, context in
            guard let collection = expression.expressionValueWithObject(object, context: context) as? Array<AnyObject> else {
                return nil
            }

            var context_dict:[String:AnyObject]

            if let unwrapped = context {
                context_dict = unwrapped as! Dictionary<String, AnyObject>
                if context_dict[variable] == nil{
                    context_dict[variable] = NSExpression.expressionForEvaluatedObject()
                }
            }else{
                context_dict = [variable:NSExpression.expressionForEvaluatedObject()]
            }

            let result = collection.filter{predicate.evaluateWithObject($0, substitutionVariables:context_dict)}

            return result.bridge()
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let exp = expression.expressionWithSubstitutionVariables(bindings)
            let p = predicate.predicateWithSubstitutionVariables(bindings as! Dictionary<String,AnyObject>)

            return NSExpression(forSubquery: exp, usingIteratorVariable: variable, predicate: p)
        }

        self.init(type:.SubqueryExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _variable = variable
        _predicate = predicate
        _collection = [expression]
    } // Expression that filters a collection by storing elements in the collection in the variable variable and keeping the elements for which qualifer returns true; variable is used as a local variable, and will shadow any instances of variable in the bindings dictionary, the variable is removed or the old value replaced once evaluation completes
    public /*not inherited*/ init(forFunction target: NSExpression, selectorName name: String, arguments parameters: [NSExpression]?) {
        NSUnimplemented()
    } // Expression that invokes the selector on target with parameters. Will throw at runtime if target does not implement selector or if parameters are wrong.
    public class func expressionForAnyKey() -> NSExpression { NSUnimplemented() }

    public convenience init(forBlock block: ExpressionBlockType, arguments: [NSExpression]?) {
        let evaluationBlock:EvaluateBlockType = {object, context in
            let args = arguments?.expressionValueWithObject(object, context: context) ?? []
            return block(object, args, context)
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let subst = arguments?.map{$0.expressionWithSubstitutionVariables(bindings)}
            return NSExpression(forBlock:block, arguments:subst)
        }

        self.init(type:.BlockExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _expressionBlock = block
        _arguments = arguments
    } // Expression that invokes the block with the parameters; note that block expressions are not encodable or representable as parseable strings.

    // TODO: Conditional Expression depends on NSPredicate implementation
    public convenience init(forConditional predicate: NSPredicate, trueExpression: NSExpression, falseExpression: NSExpression) {
        let evaluationBlock:EvaluateBlockType = {object, context in
            let eval:Bool = predicate.evaluateWithObject(object, substitutionVariables: context as? Dictionary<String,AnyObject>)
            let exp = eval ? trueExpression : falseExpression
            return exp.expressionValueWithObject(object, context: context)
        }

        let substitutionVariablesBlock:SubstituteBlockType = {bindings in
            let p = predicate.predicateWithSubstitutionVariables(bindings as! Dictionary<String,AnyObject>),
                te = trueExpression.expressionWithSubstitutionVariables(bindings),
                fe = falseExpression.expressionWithSubstitutionVariables(bindings)

            return NSExpression(forConditional: p, trueExpression: te, falseExpression: fe)
        }

        self.init(type:.ConditionalExpressionType, evaluation:evaluationBlock, substitution:substitutionVariablesBlock)

        _trueExpression = trueExpression
        _falseExpression = falseExpression
        _predicate = predicate
    } // Expression that will return the result of trueExpression or falseExpression depending on the value of predicate

    //MARK - accessors for individual parameters - raise if not applicable

    public var constantValue: AnyObject? {
        guard self.expressionType == .ConstantValueExpressionType else {
            preconditionFailure()
        }

        return self._constantValue
    }

    public var keyPath: String {
        guard expressionType == .KeyPathExpressionType else {
            preconditionFailure()
        }

        return _keyPath!
    }

    public var function: String {
        guard expressionType == .FunctionExpressionType else {
            preconditionFailure()
        }

        return self._function!
    }

    public var variable: String {
        guard expressionType == .VariableExpressionType else {
            preconditionFailure()
        }

        return self._variable!
    }

    public var operand: NSExpression? {
        NSUnimplemented()
    }
    // the object on which the selector will be invoked (the result of evaluating a key path or one of the defined functions)

    public var arguments: [NSExpression] {
        guard expressionType == .FunctionExpressionType || expressionType == .BlockExpressionType else {
            preconditionFailure()
        }

        // BlockExpressionType accepts nil arguments, we return an empty array in this case.
        guard let args = self._arguments else {
            return []
        }

        return args
    } // array of expressions which will be passed as parameters during invocation of the selector on the operand of a function expression

    public var collection: [NSExpression] {
        guard expressionType == .AggregateExpressionType else {
            preconditionFailure()
        }

        return self._collection!
    }

    public var predicate: NSPredicate {
        guard expressionType == .SubqueryExpressionType || expressionType == .ConditionalExpressionType else {
            preconditionFailure()
        }

        return self._predicate!
    }

    public var leftExpression: NSExpression {
        guard expressionType == .IntersectSetExpressionType || expressionType == .MinusSetExpressionType || expressionType == .UnionSetExpressionType else {
            preconditionFailure()
        }

        return self._leftExpression!
    }// expression which represents the left side of a set expression

    public var rightExpression: NSExpression {
        guard expressionType == .IntersectSetExpressionType || expressionType == .MinusSetExpressionType || expressionType == .UnionSetExpressionType else {
            preconditionFailure()
        }

        return self._rightExpression!
    }// expression which represents the right side of a set expression

    public var trueExpression: NSExpression? {
        guard expressionType == .ConditionalExpressionType else {
            preconditionFailure()
        }

        return self._trueExpression
    }// expression which will be evaluated if a conditional expression's predicate evaluates to true

    public var falseExpression: NSExpression? {
        guard expressionType == .ConditionalExpressionType else {
            preconditionFailure()
        }

        return self._falseExpression
    }// expression which will be evaluated if a conditional expression's predicate evaluates to false

    public var expressionBlock: ExpressionBlockType {
        guard expressionType == .BlockExpressionType else {
            preconditionFailure()
        }

        return self._expressionBlock!
    }

    // evaluate the expression using the object and bindings- note that context is mutable here and can be used by expressions to store temporary state for one predicate evaluation
    public func expressionValueWithObject(object: AnyObject?, context: NSMutableDictionary?) -> AnyObject? {
        return self._evaluationBlock(object, context)
    }

    public func allowEvaluation() { NSUnimplemented() } // Force an expression which was securely decoded to allow evaluation

    override public var description: String {
        return self.predicateFormat
    }

    // Used by NSPredicate -predicateWithSubstitutionVariables
    private func expressionWithSubstitutionVariables(bindings:NSMutableDictionary?) -> NSExpression {
        // nil bindings -> crash ?
        guard let b = bindings, let block = self._substitutionVariablesBlock else {
            return self
        }

        return block(b)
    }

    internal var predicateFormat:String {
        switch expressionType {
        case .ConstantValueExpressionType :
            if let string = self.constantValue as? NSString {
                return "'\(string)'"
            } else if let convertible = self.constantValue as? CustomStringConvertible{
                return "\(convertible.description)"
            } else if let non_nil = self.constantValue {
                return "\(non_nil)"
            } else {
                return "nil"
            }
        case .EvaluatedObjectExpressionType : return "SELF"
        case .VariableExpressionType : return "$\(self.variable)"
        case .KeyPathExpressionType : return ".\(self.keyPath)"
        case .FunctionExpressionType : return "\(self.function)(\(self.arguments.predicateFormat))"
        case .IntersectSetExpressionType : return "\(self.leftExpression) INTERSECT \(self.rightExpression)"
        case .MinusSetExpressionType : return "\(self.leftExpression.predicateFormat) MINUS \(self.rightExpression.predicateFormat)"
        case .UnionSetExpressionType : return "\(self.leftExpression) UNION \(self.rightExpression)"
        case .SubqueryExpressionType : return "SUBQUERY(\(self.collection.first), \(self.variable), \(self.predicate))"
        case .AggregateExpressionType : return "{\(self.collection.predicateFormat)}"
        case .BlockExpressionType : return "BLOCK(\(self.expressionBlock), \(self.arguments.predicateFormat))"
        case .ConditionalExpressionType : return "TERNARY(\(self.predicate), \(self.trueExpression), \(self.falseExpression))"
        case .AnyKeyExpressionType : return "UNIMPLEMENTED"
        }
    }
}

internal extension SequenceType where Generator.Element == NSExpression {
    internal func expressionValueWithObject(object: AnyObject?, context: NSMutableDictionary?) -> [AnyObject] {
        return self.map{expression in
            return expression.expressionValueWithObject(object, context: context) ?? NSNull()
        }
    }
    
    internal var predicateFormat:String {
        return self.map{$0.description}.joinWithSeparator(", ")
    }
}


//MARK - Predefined functions and function utilities
// TODO: implement all pre-defined functions which can have to following types :
//([NSNumber]) -> NSNumber
//(NSNumber) -> NSNumber
//(NSNumber) -> NSString
//(NSString) -> NSString
//() -> NSDate
//() -> NSNumber
//([CLLocation]) -> NSNumber

internal enum NSExpressionError : ErrorType {
    case InvalidArgumentType(expected:Any)
}

internal func _invokeFunction<T ,U, V>(function:(Array<T>) -> U, with arguments:Array<V>) throws -> U? {
    guard let args = arguments.map({ $0 as? T }) as? Array<T> else {
        throw NSExpressionError.InvalidArgumentType(expected:Array<T>.self)
    }

    return function(args)
}

internal typealias NSExpressionFunctionType = ([NSNumber]) -> AnyObject
internal let _NSExpressionFunctions:[String:NSExpressionFunctionType] = [
    "sum:":sum,
    "now":now]

internal func sum(args:[NSNumber]) -> NSNumber {
    return args.reduce(0, combine: {NSNumber(double:$0.doubleValue + $1.doubleValue)}) as NSNumber
}

internal func now(_:[NSNumber]) -> NSDate {
    return NSDate()
}
