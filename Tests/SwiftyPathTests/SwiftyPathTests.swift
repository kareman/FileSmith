
import XCTest
import SwiftyPath
import Foundation

class SwiftyPathTests: XCTestCase {
	func testAddURLs() {
		let folder: DirectoryPath = "/tmp"
		XCTAssertEqual(String(describing: folder + FilePath("file")), "/tmp/file")
	}

	func testRelativeFileURL() {
		let filepath = FilePath("folder1/file1.txt")

		XCTAssertFalse(filepath.isDirectory)
		XCTAssertEqual(filepath.baseString, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(filepath.baseURL, FilePath.current.url)
		XCTAssertEqual(filepath.relativeString, "folder1/file1.txt")
		XCTAssertEqual(filepath.relativeURL, URL(fileURLWithPath: "folder1/file1.txt", isDirectory: false))
		XCTAssertEqual(filepath.string, FileManager.default.currentDirectoryPath + "/folder1/file1.txt")
	}

	func testRelativeDirectoryURL() {
		let directorypath = DirectoryPath("directory1/directory2")

		XCTAssertTrue(directorypath.isDirectory)
		XCTAssertEqual(directorypath.baseString, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(directorypath.baseURL, FilePath.current.url)
		XCTAssertEqual(directorypath.relativeString, "directory1/directory2")
		XCTAssertEqual(directorypath.relativeURL, URL(fileURLWithPath: "directory1/directory2", isDirectory: true))
		XCTAssertEqual(directorypath.string, FileManager.default.currentDirectoryPath + "/directory1/directory2")
	}

	static var allTests : [(String, (SwiftyPathTests) -> () throws -> Void)] {
		return [
			("testAddURLs", testAddURLs),
		]
	}
}
