
import XCTest
import SwiftyPath

class SwiftyPathTests: XCTestCase {
	func testExample() {
		let folder: DirectoryPath = "/tmp"
		print(folder)
		XCTAssertEqual(String(describing: folder + "file"), "/tmp/file")
	}


	static var allTests : [(String, (SwiftyPathTests) -> () throws -> Void)] {
		return [
			("testExample", testExample),
		]
	}
}
