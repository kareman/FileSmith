//
//  DirectoryTests.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 29/11/2016.
//

import XCTest
import FileSmith
import Foundation

class DirectoryTests: XCTestCase {

	func testSubDirectories() {
		do {
			let dir = try Directory(open: "/")
			let subdirs = dir.directories()
			XCTAssert(subdirs.contains(DirectoryPath(base: "/", relative: "tmp")))
			XCTAssert(subdirs.contains(DirectoryPath(base: "/", relative: "bin")))
			XCTAssert(subdirs.contains(DirectoryPath(base: "/", relative: "usr")))
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testSandboxMode() {
		Directory.sandbox = true
		Directory.current = Directory.createTempDirectory()
		let trespassingfolder = "/tmp/"+ProcessInfo.processInfo.globallyUniqueString

		do {
			_ = try Directory(create: trespassingfolder, ifExists: .throwError)
			XCTFail("Should not be able to create folder outside of current folder \(DirectoryPath.current)")
		} catch FileSystemError.outsideSandbox {
		} catch {
			XCTFail(String(describing: error))
		}

		do {
			try Directory.current.create(directory: "newdir", ifExists: .throwError)

			Directory.sandbox = false
			_ = try Directory(create: trespassingfolder, ifExists: .throwError)
		} catch {
			XCTFail(String(describing: error))
		}
		Directory.sandbox = true
	}

	func testStandardDirectories() {
		XCTAssertNil(Directory.home.path.relativeComponents)
		XCTAssertEqual(Directory.root.path.absoluteString, "/")
	}

	func testDontDeleteTheCurrentWorkDirectory() {
		Directory.current = Directory.createTempDirectory()
		XCTAssertThrowsError(try Directory.current.delete())
	}

	func testOpenDirectory() {
		Directory.current = Directory.createTempDirectory()
		let name = "newthing"

		AssertThrows(FileSystemError.notFound(path: DirectoryPath(name))) {
			_ = try Directory(open: name)
		}
		AssertThrows(FileSystemError.notDirectory(path: FilePath(name))) {
			_ = try WritableFile(create: name, ifExists: .throwError)
			_ = try Directory(open: name)
		}
		AssertDoesNotThrow {
			try FileManager().removeItem(atPath: name)
			try FileManager().createDirectory(atPath: name, withIntermediateDirectories: false)
			let dir = try Directory(open: name)
			XCTAssert(dir.path.exists())
		}
	}

	func testCreateDirectory() {
		Directory.current = Directory.createTempDirectory()
		let name = "newthing"

		AssertThrows(FileSystemError.notDirectory(path: FilePath(name))) {
			_ = try WritableFile(create: name, ifExists: .throwError)
			_ = try Directory(create: name, ifExists: .open)
		}
		AssertThrows(FileSystemError.alreadyExists(path: DirectoryPath(name))) {
			try FileManager().removeItem(atPath: name)
			try FileManager().createDirectory(atPath: name, withIntermediateDirectories: false)
			_ = try Directory(create: name, ifExists: .throwError)
		}
		AssertDoesNotThrow {
			try FileManager().removeItem(atPath: name)
			var dir = try Directory(create: name, ifExists: .throwError)
			dir = try Directory(create: name, ifExists: .open)
			try dir.create(file: "file", ifExists: .throwError)
			XCTAssertTrue(FileManager().fileExists(atPath: name+"/file"))
			dir = try Directory(create: name, ifExists: .replace)
			XCTAssertFalse(FileManager().fileExists(atPath: name+"/file"))
		}
	}

	func testMoveDirectory() {
		Directory.current = Directory.createTempDirectory()
		AssertDoesNotThrow {
			var dir = try Directory(create: "testdir/dir", ifExists: .throwError)
			XCTAssertEqual(dir.path.relativeString, "testdir/dir")

			try dir.move(toDirectory: ".")

			XCTAssertEqual(dir.path.relativeString, "dir")
			XCTAssertTrue(Directory.current.contains("dir"))
			XCTAssertFalse(Directory.current.contains("testdir/dir"))
		}
	}

	func testCopyDirectory() {
		Directory.current = Directory.createTempDirectory()
		AssertDoesNotThrow {
			let dir = try Directory(create: "testdir/dir", ifExists: .throwError)
			XCTAssertEqual(dir.path.relativeString, "testdir/dir")

			let newdir = try dir.copy(toDirectory: ".")

			XCTAssertEqual(dir.path.relativeString, "testdir/dir")
			XCTAssertEqual(newdir.path.relativeString, "dir")
			XCTAssertTrue(Directory.current.contains("dir"))
			XCTAssertTrue(Directory.current.contains("testdir/dir"))
		}
	}

	func testDirectoryInAMultitudeOfWays() {
		do {
			Directory.current = Directory.createTempDirectory()
			let current = Directory.current

			XCTAssertTrue(current.path.exists())
			let testdir = try current.create(directory: "testdir", ifExists: .throwError)

			XCTAssertFalse(testdir.contains("file.txt"))
			let file = try testdir.create(file: "file.txt", ifExists: .throwError)
			XCTAssertTrue(testdir.contains("file.txt"))
			try testdir.verifyContains("file.txt")
			XCTAssertThrowsError(try testdir.verifyContains("This does not exist.txt"))
			XCTAssertThrowsError(try testdir.create(file: "file.txt", ifExists: .throwError))
			try testdir.create(file: "file.txt", ifExists: .open)
			XCTAssertTrue(file.path.exists())

			XCTAssertFalse(testdir.contains("dir"))
			let dir = try testdir.create(directory: "dir", ifExists: .throwError)
			try testdir.create(directory: "dir", ifExists: .replace)
			XCTAssertTrue(testdir.contains("dir"))
			XCTAssertThrowsError(_ = try testdir.create(directory: "dir", ifExists: .throwError))
			try testdir.create(directory: "dir", ifExists: .open)
			XCTAssertTrue(dir.path.exists())

			let newerdirpath = DirectoryPath("testdir/dir/newerdir")
			XCTAssertFalse(newerdirpath.exists())
			XCTAssertFalse(testdir.contains("dir/newerdir"))
			XCTAssertFalse(dir.contains("newerdir"))
			let newerdir = try newerdirpath.create(ifExists: .throwError)
			XCTAssertTrue(testdir.contains("dir/newerdir"))
			XCTAssertTrue(dir.contains("newerdir"))
			let newerdir2 = try newerdirpath.create(ifExists: .open)
			XCTAssertEqual(newerdir.path, newerdir2.path)

			try testdir.create(file: "file2.txt", ifExists: .throwError)
			try testdir.create(file: "file2.txt", ifExists: .replace)
			try testdir.create(file: "dir/file.txt", ifExists: .throwError)
			XCTAssertEqual(testdir.files().map {$0.string}, ["file.txt", "file2.txt"])
			XCTAssertEqual(testdir.files("file?.*").map {$0.string}, ["file2.txt"])
			XCTAssertEqual(testdir.directories().map {$0.string}, ["dir"])

			let link_to_dir = try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .throwError)
			XCTAssertThrowsError(try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .throwError))
			XCTAssertThrowsError(try testdir.create(symbolicLink: "file.txt", to: dir, ifExists: .throwError))
			XCTAssertTrue(link_to_dir.path.exists())
			XCTAssertTrue(link_to_dir.contains("newerdir"))
			try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .replace)
			try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .open)
			XCTAssertThrowsError(try testdir.create(symbolicLink: "link_to_dir", to: newerdir, ifExists: .open))
			XCTAssertEqual(testdir.directories().map {$0.string}, ["dir", "link_to_dir"])

			XCTAssertEqual(Set(testdir.directories(recursive: true).map(String.init(describing: ))), Set(["link_to_dir", "dir", "dir/newerdir", "link_to_dir/newerdir"]))
			XCTAssertEqual(Set(testdir.files(recursive: true).map(String.init(describing: ))), Set(["file.txt", "file2.txt", "dir/file.txt", "link_to_dir/file.txt"]))

			XCTAssertEqual(testdir.directories("dir/*").map {$0.string}, ["dir/newerdir"])
			try testdir.create(directory: "dir", ifExists: .replace)
			XCTAssertEqual(testdir.directories("dir/*"), [])

		} catch {
			XCTFail(String(describing: error))
		}
	}
}

extension DirectoryTests {
	public static var allTests = [
		("testSubDirectories", testSubDirectories),
		("testSandboxMode", testSandboxMode),
		("testStandardDirectories", testStandardDirectories),
		("testDontDeleteTheCurrentWorkDirectory", testDontDeleteTheCurrentWorkDirectory),
		("testOpenDirectory", testOpenDirectory),
		("testCreateDirectory", testCreateDirectory),
		("testDirectoryInAMultitudeOfWays", testDirectoryInAMultitudeOfWays),
		]
}
