
import XCTest
import SwiftyPath
import Foundation

class SwiftyPathTests: XCTestCase {
	func testAddURLs() {
		let folder: DirectoryPath = "/tmp"
		let file: FilePath = "file"
		XCTAssertEqual(String(describing: folder + file), "file")
		XCTAssertEqual((folder + file).absolute.string, "/tmp/file")
	}

	func testRelativeFileURL() {
		let filepath = FilePath("folder1/file1.txt")

		XCTAssertFalse(filepath.isDirectory)
		XCTAssertEqual(filepath.base?.string, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(filepath.base?.url, FilePath.current.url)
		XCTAssertEqual(filepath.relativeString, "folder1/file1.txt")
		XCTAssertEqual(filepath.relativeURL, URL(fileURLWithPath: "folder1/file1.txt", isDirectory: false))
		XCTAssertEqual(filepath.string, "folder1/file1.txt")
	}

	func testRelativeDirectoryURL() {
		let directorypath = DirectoryPath("directory1/directory2")

		XCTAssertTrue(directorypath.isDirectory)
		XCTAssertEqual(directorypath.base?.string, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(directorypath.base?.url, FilePath.current.url)
		XCTAssertEqual(directorypath.relativeString, "directory1/directory2")
		XCTAssertEqual(directorypath.relativeURL, URL(fileURLWithPath: "directory1/directory2", isDirectory: true))
		XCTAssertEqual(directorypath.string, "directory1/directory2")
	}

	func testAbsoluteFileURL() {
		let filepath = FilePath("/tmp/folder1/file1.txt")

		XCTAssertFalse(filepath.isDirectory)
		XCTAssertNil(filepath.base)
		XCTAssertNil(filepath.relativeString)
		XCTAssertNil(filepath.relativeURL)
		XCTAssertEqual(filepath.string, "/tmp/folder1/file1.txt")
	}

	func testAbsoluteDirectoryURL() {
		let directorypath = DirectoryPath("/tmp/directory1/directory2/")

		XCTAssertTrue(directorypath.isDirectory)
		XCTAssertNil(directorypath.base)
		XCTAssertNil(directorypath.relativeString)
		XCTAssertNil(directorypath.relativeURL)
		XCTAssertEqual(directorypath.string, "/tmp/directory1/directory2")
	}

	func testName() {
		XCTAssertEqual(FilePath("file.txt").name, "file.txt")
		XCTAssertEqual(FilePath("file.txt").extension, "txt")
		XCTAssertEqual(FilePath(".file.txt").name, ".file.txt")
		XCTAssertEqual(FilePath(".file.txt").extension, "txt")
		XCTAssertEqual(FilePath(".file").name, ".file")
		XCTAssertEqual(FilePath(".file").extension, nil)
		XCTAssertEqual(FilePath("file").name, "file")
		XCTAssertEqual(FilePath("file").extension, nil)
	}

	static var allTests : [(String, (SwiftyPathTests) -> () throws -> Void)] {
		return [
			("testAddURLs", testAddURLs),
		]
	}
}
