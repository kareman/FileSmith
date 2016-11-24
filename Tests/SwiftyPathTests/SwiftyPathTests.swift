import XCTest
@testable import SwiftyPath

class SwiftyPathTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftyPath().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftyPathTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
