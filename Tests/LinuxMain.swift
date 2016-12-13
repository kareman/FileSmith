
import XCTest

@testable import FileSmithTests

let tests: [XCTestCaseEntry] = [
	testCase(PathTests.allTests),
	testCase(DirectoryTests.allTests),
	]

XCTMain(tests)
