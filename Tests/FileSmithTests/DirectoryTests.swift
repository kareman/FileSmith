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
			let subdirs = try dir.subDirectoryPaths()

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
			_ = try DirectoryPath.current.open().add(directory: "newdir", ifExists: .throwError)
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testDirectory() {
		do {
			DirectoryPath.current = DirectoryPath(createTempdirectory())
			let current = try DirectoryPath.current.open()
			//current.content().isEmpty
			XCTAssertTrue(current.path.exists())

			XCTAssertFalse(current.contains("newfile.txt"))
			let newfile = try current.add(file: "newfile.txt", ifExists: .throwError)
			XCTAssertTrue(current.contains("newfile.txt"))
			XCTAssertThrowsError(_ = try current.add(file: "newfile.txt", ifExists: .throwError))
			XCTAssertTrue(newfile.path.exists())

			XCTAssertFalse(current.contains("newdir"))
			let newdir = try current.add(directory: "newdir", ifExists: .throwError)
			XCTAssertTrue(current.contains("newdir"))
			XCTAssertThrowsError(_ = try current.add(directory: "newdir", ifExists: .throwError))
			XCTAssertTrue(newdir.path.exists())

			let newerdirpath = DirectoryPath("newdir/newerdir")
			XCTAssertFalse(newerdirpath.exists())
			XCTAssertFalse(current.contains("newdir/newerdir"))
			XCTAssertFalse(newdir.contains("newerdir"))
			let newerdir = try newerdirpath.create(ifExists: .throwError)
			XCTAssertTrue(current.contains("newdir/newerdir"))
			XCTAssertTrue(newdir.contains("newerdir"))
			let newerdir2 = try newerdirpath.create(ifExists: .open)
			XCTAssertEqual(newerdir.path, newerdir2.path)

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
