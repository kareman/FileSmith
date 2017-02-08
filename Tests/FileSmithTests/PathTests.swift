//
//  PathTests.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 29/11/2016.
//

import XCTest
import FileSmith
import Foundation

class PathTests: XCTestCase {

	func testAddPaths() {
		let absolutedir: DirectoryPath = "/tmp"
		let relativedir: DirectoryPath = "relativedir"
		let file: FilePath = "file"

		XCTAssertEqual(String(describing: absolutedir + file), "/tmp/file")
		XCTAssertEqual((relativedir + file).string, "relativedir/file")

		let _: DirectoryPath = DirectoryPath.home + "something"
		let _: FilePath = DirectoryPath.home + "something"
		// let _ = DirectoryPath.home + "dir" // Will not and should not compile.
	}

	func testRelativeFilePath() {
		let filepath = FilePath("folder1/file1.txt")

		XCTAssertEqual(filepath.base?.absoluteString, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(filepath.base?.url, DirectoryPath.current.url)
		XCTAssertEqual(filepath.relativeString, "folder1/file1.txt")
		XCTAssertEqual(filepath.relativeURL, URL(fileURLWithPath: "folder1/file1.txt"))
		XCTAssertEqual(filepath.string, "folder1/file1.txt")
	}

	func testRelativeDirectoryPath() {
		var directorypath: DirectoryPath = "directory1/directory2"

		XCTAssertEqual(directorypath.base?.absoluteString, FileManager.default.currentDirectoryPath)
		XCTAssertEqual(directorypath.base?.url, DirectoryPath.current.url)
		XCTAssertEqual(directorypath.relativeString, "directory1/directory2")
		XCTAssertEqual(directorypath.relativeURL, URL(fileURLWithPath: "directory1/directory2"))
		XCTAssertEqual(directorypath.string, "directory1/directory2")

		directorypath = "."
		XCTAssertEqual(directorypath.string, ".")
		XCTAssertEqual(directorypath.relativeComponents!, [])
		XCTAssertEqual(directorypath.base?.absoluteString, FileManager.default.currentDirectoryPath)
	}

	func testAbsoluteFilePath() {
		let filepath = FilePath("/tmp/folder1/file1.txt")

		XCTAssertNil(filepath.base)
		XCTAssertNil(filepath.relativeString)
		XCTAssertNil(filepath.relativeURL)
		XCTAssertEqual(filepath.string, "/tmp/folder1/file1.txt")
	}

	func testAbsoluteDirectoryPath() {
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
			DirectoryPath(URL(fileURLWithPath:"/tmp/directory1/directory2/"))?.string,
			"/tmp/directory1/directory2")

		XCTAssertNil(FilePath(URL(string:"http://blog.nottoobadsoftware.com/tag/swift/")!))
		XCTAssertNil(AnyPath(URL(string:"http://blog.nottoobadsoftware.com/tag/swift/")!))
		XCTAssertNil(DirectoryPath(URL(string:"http://blog.nottoobadsoftware.com/tag/swift/")!))
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

		let relative = FilePath(base: "/base1/../base2", relative: "rel1/..")
		XCTAssertEqual(relative.relativeString, ".")
		XCTAssertEqual(relative.base?.string, "/base2")
		XCTAssertEqual(relative.absoluteString, "/base2")

		var relativedir = DirectoryPath(base: "/base1/../", relative: "/rel1/../rel2")
		XCTAssertEqual(relativedir.relativeString, "rel2")
		XCTAssertEqual(relativedir.base?.string, "/")
		XCTAssertEqual(relativedir.absoluteString, "/rel2")

		relativedir = DirectoryPath(base: "/../base1", relative: "../rel1")
		XCTAssertEqual(relativedir.relativeString, "../rel1")
		XCTAssertEqual(relativedir.base?.string, "/../base1")
		XCTAssertEqual(relativedir.absoluteString, "/../rel1")

		XCTAssertEqual(relativedir.absolute.parent().string, "/..")
		XCTAssertEqual(relativedir.parent().string, "..")
		XCTAssertEqual(relativedir.parent(nr: 2).string, "/")
		XCTAssertEqual(relativedir.parent().parent().string, "/")

		XCTAssertEqual(relativedir.name, "rel1")
		XCTAssertEqual(relativedir.parent().name, "..")
		XCTAssertEqual(FilePath("/../dir1/dir2/..").name, "dir1")
	}

	func testCertainCharactersAtBeginningOfPath() {
		XCTAssertEqual(DirectoryPath("~/").absoluteString, NSHomeDirectoryForUser(NSUserName())!)
		XCTAssertEqual(DirectoryPath(".").absolute, DirectoryPath.current)
		XCTAssertEqual(DirectoryPath("./"), DirectoryPath(""))
	}

	func testIsAParentOf() {
		XCTAssertTrue(DirectoryPath("/a/b/").isAParentOf(AnyPath("/a/b/c")))
		XCTAssertFalse(DirectoryPath("/a/b/").isAParentOf(AnyPath("/c/b/c")))
		XCTAssertFalse(DirectoryPath("/a/b/").isAParentOf(AnyPath("/a/")))
		XCTAssertFalse(DirectoryPath("/a/b/").isAParentOf(DirectoryPath("/a/b/")))
	}
}

extension PathTests {
	public static var allTests = [
		("testAddPaths", testAddPaths),
		("testRelativeFilePath", testRelativeFilePath),
		("testRelativeDirectoryPath", testRelativeDirectoryPath),
		("testAbsoluteFilePath", testAbsoluteFilePath),
		("testAbsoluteDirectoryPath", testAbsoluteDirectoryPath),
		("testName", testName),
		("testURL", testURL),
		("testPathTypeDetection", testPathTypeDetection),
		("testDotDot", testDotDot),
		("testCertainCharactersAtBeginningOfPath", testCertainCharactersAtBeginningOfPath),
		("testIsAParentOf", testIsAParentOf),
		]
}
