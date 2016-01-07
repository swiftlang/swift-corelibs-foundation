// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSExpression: XCTestCase {
    
    var allTests : [(String, () -> Void)] {
        return [
            //("test_keyPathExpression", test_keyPathExpression),
            //("test_ConditionalExpression", test_ConditionalExpression),
            //("test_SubqueryExpression", test_SubqueryExpression),
            ("test_ConstantExpression", test_ConstantExpression),
            ("test_SelfExpression", test_SelfExpression),
            ("test_VariableExpression", test_VariableExpression),
            ("test_FunctionExpression", test_FunctionExpression),
            ("test_AggregateExpression", test_AggregateExpression),
            ("test_SetExpresssion", test_SetExpresssion),
            ("test_blockExpression", test_blockExpression)
        ]
    }

    func setUp() {

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func tearDown() {

        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ConstantExpression() {
        let exp = NSExpression(forConstantValue: "a".bridge())
        XCTAssertEqual(exp.expressionValueWithObject(nil, context: nil) as? NSString , "a".bridge())
        XCTAssertEqual(exp.expressionValueWithObject("o".bridge(), context: nil) as? NSString, "a".bridge())

        let exp2 = NSExpression(forConstantValue: nil)
        XCTAssertNil(exp2.expressionValueWithObject(nil, context: nil))
        XCTAssertEqual(exp.description, "'a'", "Expected 'a', got \(exp.description)")
    }

    func test_SelfExpression() {
        let exp = NSExpression.expressionForEvaluatedObject()
        XCTAssertNil(exp.expressionValueWithObject(nil, context: nil))
        XCTAssertEqual(exp.expressionValueWithObject("o".bridge(), context: nil) as? NSString, "o".bridge())
        XCTAssertEqual(exp.expressionValueWithObject(1 as NSNumber, context: nil) as? NSNumber, 1 as NSNumber)
        XCTAssertEqual(exp.description, "SELF", "Expected SELF")
    }

    func test_keyPathExpression() {
        let value = "VALUE".bridge()
        let obj = NSDictionary(object: value, forKey: "prop".bridge())

        let exp = NSExpression(forKeyPath: "prop")
        XCTAssertEqual(exp.expressionValueWithObject(obj, context: nil) as? NSString, value)
        XCTAssertNil(exp.expressionValueWithObject(nil, context: nil))
        XCTAssertEqual(exp.description, "Expected .prop, got \(exp.description)")
    }

    func test_VariableExpression() {
        let bindings = ["variable".bridge():NSExpression(forConstantValue:"c".bridge())] as NSMutableDictionary

        let exp = NSExpression(forVariable: "variable")
        XCTAssertEqual(exp.expressionValueWithObject(nil, context: bindings) as? NSString, "c".bridge())
        XCTAssertEqual(exp.description, "$variable", "Expected $variable, got \(exp.description)")
    }

    func test_FunctionExpression() {
        let exp = NSExpression(forFunction: "sum:", arguments: [NSExpression(forConstantValue:1 as NSNumber), NSExpression(forConstantValue:2 as NSNumber)])
        let result = exp?.expressionValueWithObject(nil, context: nil) as? NSNumber
        XCTAssertEqual(result, 3 as NSNumber, "Result should be 3, was \(result)")
        XCTAssertEqual(exp?.description, "sum:(1, 2)", "Expected sum:(1, 2) was \(exp?.description)")

        let exp2 = NSExpression(forFunction: "sum:", arguments: [NSExpression(forConstantValue:"s".bridge())])
        XCTAssertNil(exp2?.expressionValueWithObject(nil, context: nil), "Wrong arguments type, expression result should be nil")

        let exp3 = NSExpression(forFunction: "sum", arguments:[NSExpression(forConstantValue:1 as NSNumber)])
        XCTAssertNil(exp3, "Wrong function name, expression result should be nil")
    }

    func test_AggregateExpression() {
        let exp = NSExpression(forAggregate: [NSExpression(forConstantValue:1 as NSNumber), NSExpression(forConstantValue:"c".bridge())])
        XCTAssertEqual(exp.expressionValueWithObject(nil, context: nil) as? NSArray , [1 as NSNumber, "c".bridge()].bridge())
        XCTAssertEqual(exp.description, "{1, 'c'}", "Expected {1, 'c'} was \(exp.description)")
    }

    func test_SetExpresssion() {
        let left:NSSet = ([1,2] as Set).bridge(),
            right:NSSet = ([2,3] as Set).bridge()

        let exp_intersect = NSExpression(forIntersectSet: NSExpression(forConstantValue:left), with: NSExpression(forConstantValue:right))
        XCTAssertEqual(exp_intersect.expressionValueWithObject(nil, context: nil) as? NSSet , ([2] as Set).bridge())
        XCTAssertEqual(exp_intersect.description, "\(left.description) INTERSECT \(right.description)", "Expects \(left.description) ,was \(exp_intersect.description)")

        let exp_minus = NSExpression(forMinusSet: NSExpression(forConstantValue:left), with: NSExpression(forConstantValue:right))
        XCTAssertEqual(exp_minus.expressionValueWithObject(nil, context: nil) as? NSSet , ([1] as Set).bridge())
        XCTAssertEqual(exp_minus.description, "\(left.description) MINUS \(right.description)")

        let exp_union = NSExpression(forUnionSet: NSExpression(forConstantValue:left), with: NSExpression(forConstantValue:right))
        XCTAssertEqual(exp_union.expressionValueWithObject(nil, context: nil) as? NSSet , ([1,2,3] as Set).bridge())
        XCTAssertEqual(exp_union.description, "\(left.description) UNION \(right.description)")
    }

    func test_blockExpression() {
        let obj = "o".bridge()
        let exp = NSExpression(forBlock: {obj,_,_ in return obj}, arguments: nil)
        XCTAssertEqual(exp.expressionValueWithObject(obj, context: nil) as? NSString, obj)

        let exp_with_args = NSExpression(forBlock: {_,args,_ in return args[0]}, arguments: [NSExpression(forConstantValue:1 as NSNumber), NSExpression(forConstantValue:"c".bridge())])
        XCTAssertEqual(exp_with_args.expressionValueWithObject(nil, context: nil) as? NSNumber, 1 as NSNumber)

        let bindings = ["variable".bridge():NSExpression(forConstantValue:obj)] as NSMutableDictionary
        let exp_with_args_and_bindings = NSExpression(forBlock: {_,args,_ in return args[0]}, arguments: [NSExpression(forVariable:"variable")])
        XCTAssertEqual(exp_with_args_and_bindings.expressionValueWithObject(nil, context: bindings) as? NSString, obj)
    }

    func test_ConditionalExpression() {
        let t = "true".bridge()
        let f = "false".bridge()
        let bindings = ["variable1".bridge():NSExpression(forConstantValue:t),
                        "variable2".bridge():NSExpression(forConstantValue:f)] as NSMutableDictionary
        let p = NSPredicate(value: true)

        let exp = NSExpression(forConditional: p, trueExpression: NSExpression(forVariable:"variable1") , falseExpression: NSExpression(forVariable:"variable2"))
        XCTAssertEqual(exp.expressionValueWithObject(nil, context: bindings) as? NSString, "true".bridge())
        XCTAssertEqual(exp.description, "TERNARY(TRUEPREDICATE, $variable1, $variable2)")
    }

    func test_SubqueryExpression() {
        let object:Dictionary<String,Dictionary<String,Any>> =
            ["Record1":
                      ["Name":"John", "Age":34 as NSNumber, "Children":
                                                                      ["Kid1", "Kid2"]],
             "Record2":
                      ["Name":"Mary", "Age":30 as NSNumber, "Children":
                                                                      ["Kid1", "Girl1"]]]

        let collection = NSExpression(forKeyPath: "Record1.Children")
        let predicate = NSPredicate(format:"%K BEGINSWITH %K", argumentArray:["x".bridge(), "KidVariable".bridge()])
        let bindings = NSMutableDictionary(object: NSExpression(forConstantValue:"Kid".bridge()), forKey: "KidVariable".bridge())
        let exp = NSExpression(forSubquery: collection, usingIteratorVariable: "x", predicate: predicate)
        let eval = exp.expressionValueWithObject(object.bridge(), context: bindings)
        let expected = ["Kid1", "Kid2"].bridge()
        XCTAssertEqual(eval as? NSArray, expected, "\(exp.description) : result is \(eval), should be \(expected)")
    }
}
