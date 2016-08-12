import XCTest
@testable import swift_corelibs_foundation

class swift_corelibs_foundationTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(swift_corelibs_foundation().text, "Hello, World!")
    }


    static var allTests : [(String, (swift_corelibs_foundationTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
