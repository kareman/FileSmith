//
//  DirectoryTests.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import XCTest
import FileSmith
import Foundation

class DirectoryTests: XCTestCase {

	func testSubDirectories() {
		do {
			let dir = try Directory(open: "/")
			let subdirs = dir.directories()
			XCTAssert(subdirs.contains(DirectoryPath("tmp")))
			XCTAssert(subdirs.contains(DirectoryPath("bin")))
			XCTAssert(subdirs.contains(DirectoryPath("usr")))
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testSandboxMode() {
		Directory.sandbox = true
		DirectoryPath.current = DirectoryPath(createTempdirectory())
		do {
			let trespassingfolder = "/tmp/"+ProcessInfo.processInfo.globallyUniqueString
			_ = try Directory(create: trespassingfolder, ifExists: .throwError)
			XCTFail("Should not be able to create folder outside of current folder \(DirectoryPath.current)")
		} catch FileSystemError.outsideSandbox {
		} catch {
			XCTFail(String(describing: error))
		}

		do {
			try DirectoryPath.current.open().create(directory: "newdir", ifExists: .throwError)
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testDirectory() {
		do {
			DirectoryPath.current = DirectoryPath(createTempdirectory())
			let current = try DirectoryPath.current.open()
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
			XCTAssertEqual(testdir.files().map {$0.string}, ["file.txt", "file2.txt"])
			XCTAssertEqual(testdir.files("file?.*").map {$0.string}, ["file2.txt"])
			XCTAssertEqual(testdir.directories().map {$0.string}, ["dir"])

			XCTAssertEqual(testdir.directories("dir/*").map {$0.string}, ["dir/newerdir"])
			try testdir.create(directory: "dir", ifExists: .replace)
			XCTAssertEqual(testdir.directories("dir/*"), [])

		} catch {
			XCTFail(String(describing: error))
		}
	}
}

private func createTempdirectory () -> String {
	let name = ProcessInfo.processInfo.processName
	let tempdirectory = NSTemporaryDirectory() + "/" + (name + "-" + ProcessInfo.processInfo.globallyUniqueString)
	do {
		try FileManager().createDirectory(atPath: tempdirectory, withIntermediateDirectories: true, attributes: nil)
		return tempdirectory + "/"
	} catch let error as NSError {
		fatalError("Could not create new temporary directory '\(tempdirectory)':\n\(error.localizedDescription)")
	} catch {
		fatalError("Unexpected error: \(error)")
	}
}

extension DirectoryTests {
	public static var allTests = [
		("testSubDirectories", testSubDirectories),
		("testSandboxMode", testSandboxMode),
		("testDirectory", testDirectory),
		]
}
