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



class TestNSData : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_writeToURLOptions", test_writeToURLOptions)
        ]
    }

    func test_writeToURLOptions() {
        let saveData = NSData(contentsOfURL: NSBundle.mainBundle().URLForResource("Test", withExtension: "plist")!)
        let savePath = "/var/tmp/Test.plist"
        do {
            try saveData!.writeToFile(savePath, options: NSDataWritingOptions.DataWritingAtomic)
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(savePath))
            try! fileManager.removeItemAtPath(savePath)
        } catch let error {
            XCTFail((error as! NSError).localizedDescription)
        }
    }
}










