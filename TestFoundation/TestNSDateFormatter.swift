//
//  TestNSDateFormatter.swift
//  Foundation
//
//  Created by Taylor Franklin on 2/19/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSDateFormatter: XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_customDateFormat", test_customDateFormat)
        ]
    }
    
    func test_BasicConstruction() {
        let f = NSDateFormatter()
        XCTAssertNotNil(f)
    }
    
    func test_customDateFormat() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = String("dd-MM-yyyy")
        let dateStr = dateFormatter.stringFromDate(NSDate())
        
        print("With dateFormat '\(dateFormatter.dateFormat)':  '\(dateStr)'")
        
//        dateFormatter.dateStyle = .MediumStyle
//        dateFormatter.timeStyle = .MediumStyle
//        var dateStr = dateFormatter.stringFromDate(NSDate())
//        print("With dateStyle and timeStyle set to .MediumStyle:  '\(dateStr)'")
        
    }
    
}
