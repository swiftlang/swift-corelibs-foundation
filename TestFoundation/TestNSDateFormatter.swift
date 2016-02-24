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

// TODO: create dictionary of test data [timestamp : stringFromDateVal]
// get default styles working first .MediumStyle

class TestNSDateFormatter: XCTestCase {
    
    let DEFAULT_LOCALE = "en_US"
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
//            ("test_customDateFormat", test_customDateFormat),
            ("test_dateStyleShort",    test_dateStyleShort)
//            ("test_dateStyleMedium",   test_dateStyleMedium),
//            ("test_dateStyleLong",     test_dateStyleLong),
//            ("test_dateStyleFull",     test_dateStyleFull),
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
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        let updatedDateStr = dateFormatter.stringFromDate(NSDate())
        print("With dateStyle and timeStyle set to .MediumStyle:  '\(updatedDateStr)'")
        
    }
    
    // ShortStyle
    // locale  stringFromDate  example
    // ------  --------------  --------
    // en_US   %m/%d/%y        12/25/15
    func test_dateStyleShort() {
        
        let timestamps = [
            -31536000 : "1/1/69" , 0.0 : "1/1/70", 31536000 : "1/1/71",
            2145916800 : "1/1/38", 1456272000 : "2/24/16", 1456358399 : "2/24/16",
            1452574638 : "1/12/16", 1455685038 : "2/17/16", 1458622638 : "3/22/16",
            1459745838 : "4/4/16", 1462597038 : "5/7/16", 1465534638 : "6/10/16",
            1469854638 : "7/30/16", 1470718638 : "8/9/16", 1473915438 : "9/15/16",
            1477285038 : "10/24/16", 1478062638 : "11/2/16", 1482641838 : "12/25/16"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .ShortStyle
        // change to fixed time zone instead of system defined time zone
        // replace with setting f.timeZone when that property is fully functional
        let tz = NSTimeZone(name: "GMT")!
        NSTimeZone.setDefaultTimeZone(tz)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
}
