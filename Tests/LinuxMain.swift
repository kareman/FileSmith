
import XCTest

@testable import SwiftyPathTests

let tests: [XCTestCaseEntry] = [
	testCase(SwiftyPathTests.allTests),
	testCase(DirectoryTests.allTests),
	]

XCTMain(tests)
