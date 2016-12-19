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

	func testSubDirectoryPaths() {
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

			XCTAssertFalse(current.contains("file.txt"))
			let file = try current.create(file: "file.txt", ifExists: .throwError)
			XCTAssertTrue(current.contains("file.txt"))
			try current.verifyContains("file.txt")
			XCTAssertThrowsError(try current.verifyContains("This does not exist.txt"))
			XCTAssertThrowsError(try current.create(file: "file.txt", ifExists: .throwError))
			try current.create(file: "file.txt", ifExists: .open)
			XCTAssertTrue(file.path.exists())

			XCTAssertFalse(current.contains("dir"))
			let dir = try current.create(directory: "dir", ifExists: .throwError)
			try current.create(directory: "dir", ifExists: .replace)
			XCTAssertTrue(current.contains("dir"))
			XCTAssertThrowsError(_ = try current.create(directory: "dir", ifExists: .throwError))
			try current.create(directory: "dir", ifExists: .open)
			XCTAssertTrue(dir.path.exists())

			let newerdirpath = DirectoryPath("dir/newerdir")
			XCTAssertFalse(newerdirpath.exists())
			XCTAssertFalse(current.contains("dir/newerdir"))
			XCTAssertFalse(dir.contains("newerdir"))
			let newerdir = try newerdirpath.create(ifExists: .throwError)
			XCTAssertTrue(current.contains("dir/newerdir"))
			XCTAssertTrue(dir.contains("newerdir"))
			let newerdir2 = try newerdirpath.create(ifExists: .open)
			XCTAssertEqual(newerdir.path, newerdir2.path)

			try current.create(file: "file2.txt", ifExists: .throwError)
			try current.create(file: "file2.txt", ifExists: .replace)
			XCTAssertEqual(current.files().map {$0.string}, ["file.txt", "file2.txt"])
			XCTAssertEqual(current.files("file?.*").map {$0.string}, ["file2.txt"])
			XCTAssertEqual(current.directories().map {$0.string}, ["dir"])

			XCTAssertEqual(current.directories("dir/*").map {$0.string}, ["dir/newerdir"])
			try current.create(directory: "dir", ifExists: .replace)
			XCTAssertEqual(current.directories("dir/*"), [])

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
		("testSubDirectoryPaths", testSubDirectoryPaths),
		("testSandboxMode", testSandboxMode),
		("testDirectory", testDirectory),
		]
}
