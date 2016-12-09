
import XCTest
import SwiftyPath
import Foundation

class SwiftyPathTests: XCTestCase {
	func testAddURLs() {
		let absolutedir: DirectoryPath = "/tmp"
		let relativedir: DirectoryPath = "relativedir"
		let file: FilePath = "file"

		XCTAssertEqual(String(describing: absolutedir + file), "/tmp/file")
		XCTAssertEqual((relativedir + file).string, "relativedir/file")
	}

	func testRelativeFileURL() {
		let filepath = FilePath("folder1/file1.txt")

		XCTAssertEqual(filepath.base?.string, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(filepath.base?.url, DirectoryPath.current.url)
		XCTAssertEqual(filepath.relativeString, "folder1/file1.txt")
		XCTAssertEqual(filepath.relativeURL, URL(fileURLWithPath: "folder1/file1.txt", isDirectory: false))
		XCTAssertEqual(filepath.string, "folder1/file1.txt")
	}

	func testRelativeDirectoryURL() {
		var directorypath: DirectoryPath = "directory1/directory2"

		XCTAssertEqual(directorypath.base?.string, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(directorypath.base?.url, DirectoryPath.current.url)
		XCTAssertEqual(directorypath.relativeString, "directory1/directory2")
		XCTAssertEqual(directorypath.relativeURL, URL(fileURLWithPath: "directory1/directory2", isDirectory: true))
		XCTAssertEqual(directorypath.string, "directory1/directory2")

		directorypath = "."
		XCTAssertEqual(directorypath.string, "")
		XCTAssertEqual((directorypath.relativeComponents)!, [])
		XCTAssertEqual(directorypath.base?.string, FileManager.default.currentDirectoryPath)
	}

	func testAbsoluteFileURL() {
		let filepath = FilePath("/tmp/folder1/file1.txt")

		XCTAssertNil(filepath.base)
		XCTAssertNil(filepath.relativeString)
		XCTAssertNil(filepath.relativeURL)
		XCTAssertEqual(filepath.string, "/tmp/folder1/file1.txt")
	}

	func testAbsoluteDirectoryURL() {
		let directorypath = DirectoryPath("/tmp/directory1/directory2/")

		XCTAssertNil(directorypath.base)
		XCTAssertNil(directorypath.relativeString)
		XCTAssertNil(directorypath.relativeURL)
		XCTAssertEqual(directorypath.string, "/tmp/directory1/directory2")
	}

	func testName() {
		XCTAssertEqual(FilePath("/file.txt").name, "file.txt")
		XCTAssertEqual(FilePath("file.txt").extension, "txt")
		XCTAssertEqual(FilePath("dir/file.txt").nameWithoutExtension, "file")
		XCTAssertEqual(FilePath(".file.txt").name, ".file.txt")
		XCTAssertEqual(FilePath("/dir/.file.txt").extension, "txt")
		XCTAssertEqual(FilePath(".file.txt").nameWithoutExtension, ".file")
		XCTAssertEqual(FilePath(".file").name, ".file")
		XCTAssertEqual(FilePath(".file").extension, nil)
		XCTAssertEqual(FilePath(".file").nameWithoutExtension, ".file")
		XCTAssertEqual(FilePath("file.txt.").name, "file.txt.")
		XCTAssertEqual(FilePath("file.txt.").extension, nil)
		XCTAssertEqual(FilePath("file.txt.").nameWithoutExtension, "file.txt")
		XCTAssertEqual(FilePath("file").name, "file")
		XCTAssertEqual(FilePath("file").extension, nil)
		XCTAssertEqual(FilePath("file").nameWithoutExtension, "file")
		XCTAssertEqual(DirectoryPath(".").name, DirectoryPath.current.name)
		XCTAssertEqual(DirectoryPath("/").name, "/")
	}

	func testURL() {
		XCTAssertEqual(
			DirectoryPath(URL(fileURLWithPath:"/tmp/directory1/directory2/"))?.string,
			"/tmp/directory1/directory2")
		XCTAssertEqual(FilePath(URL(fileURLWithPath:"/tmp/directory1/file2"))?.string, "/tmp/directory1/file2")
		XCTAssertEqual(
			DirectoryPath(URL(fileURLWithPath:"/tmp/directory1/directory2/", isDirectory: true))?.string,
			"/tmp/directory1/directory2")
	}

	func testPathTypeDetection() {
		XCTAssertNil(path(detectTypeOf:"sdfsf/ljljlk"))
		XCTAssert(path(detectTypeOf:"sdfsf/ljljlk/") is DirectoryPath)
		XCTAssert(path(detectTypeOf:"/tmp") is DirectoryPath)
		XCTAssert(path(detectTypeOf:#file) is FilePath)
	}

	func testDotDot() {
		XCTAssertEqual(FilePath("/dir1/dir2/..").string, "/dir1")
		XCTAssertEqual(FilePath("/../dir1/dir2/..").string, "/../dir1")
		XCTAssertEqual(FilePath("/dir/dir/../../dir2").string, "/dir2")
		XCTAssertEqual(FilePath("/dir/../dir/../../dir2").string, "/../dir2")
		XCTAssertEqual(FilePath("/dir/dir/../../../dir2").string, "/../dir2")
		XCTAssertEqual(FilePath("/../dir1/dir2/..").string, "/../dir1")
		XCTAssertEqual(FilePath("/../dir1/../dir2/..").string, "/..")

		let relative = FilePath("rel1/..", relativeTo: "/base1/../base2")
		XCTAssertEqual(relative.relativeString, "")
		XCTAssertEqual(relative.base?.string, "/base2")
		XCTAssertEqual(relative.absolute.string, "/base2")

		var relativedir = DirectoryPath("/rel1/../rel2", relativeTo: "/base1/../")
		XCTAssertEqual(relativedir.relativeString, "rel2")
		XCTAssertEqual(relativedir.base?.string, "/")
		XCTAssertEqual(relativedir.absolute.string, "/rel2")

		relativedir = DirectoryPath("../rel1", relativeTo: "/../base1")
		XCTAssertEqual(relativedir.relativeString, "../rel1")
		XCTAssertEqual(relativedir.base?.string, "/../base1")
		XCTAssertEqual(relativedir.absolute.string, "/../rel1")

		XCTAssertEqual(relativedir.absolute.parent().string, "/..")
		XCTAssertEqual(relativedir.parent().string, "..")
		XCTAssertEqual(relativedir.parent(nr: 2).string, "/")
		XCTAssertEqual(relativedir.parent().parent().string, "/")

		XCTAssertEqual(relativedir.name, "rel1")
		XCTAssertEqual(relativedir.parent().name, "..")
		XCTAssertEqual(FilePath("/../dir1/dir2/..").name, "dir1")
	}

	func testSymbolicLink() {
		XCTAssertEqual(DirectoryPath("/tmp").symbolicLinkPointsTo, "/private/tmp")
	}
}

extension SwiftyPathTests {
	public static var allTests = [
		("testAddURLs", testAddURLs),
		("testRelativeFileURL", testRelativeFileURL),
		("testRelativeDirectoryURL", testRelativeDirectoryURL),
		("testAbsoluteFileURL", testAbsoluteFileURL),
		("testAbsoluteDirectoryURL", testAbsoluteDirectoryURL),
		("testName", testName),
		("testURL", testURL),
		("testPathTypeDetection", testPathTypeDetection),
		("testDotDot", testDotDot),
		("testSymbolicLink", testSymbolicLink),
		]
}
