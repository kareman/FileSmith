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
			XCTAssert(subdirs.contains(DirectoryPath("tmp")))
			XCTAssert(subdirs.contains(DirectoryPath("bin")))
			XCTAssert(subdirs.contains(DirectoryPath("usr")))
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testSandboxMode() {
		Directory.sandbox = true
		Directory.current = Directory.createTempDirectory()
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

	func testStandardDirectories() {
		XCTAssertNil(Directory.home.path.relativeComponents)
		XCTAssertEqual(Directory.root.path.string, "/")
	}

	func testDirectory() {
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

			XCTAssertEqual(Set(testdir.directories(recursive: true)), Set(["dir", "dir/newerdir"]))
			XCTAssertEqual(Set(testdir.files(recursive: true)), Set(["file.txt", "file2.txt", "dir/file.txt"]))

			let link_to_dir = try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .throwError)
			XCTAssertThrowsError(try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .throwError))
			XCTAssertThrowsError(try testdir.create(symbolicLink: "file.txt", to: dir, ifExists: .throwError))
			XCTAssertTrue(link_to_dir.path.exists())
			XCTAssertTrue(link_to_dir.contains("newerdir"))
			try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .replace)
			try testdir.create(symbolicLink: "link_to_dir", to: dir, ifExists: .open)
			XCTAssertThrowsError(try testdir.create(symbolicLink: "link_to_dir", to: newerdir, ifExists: .open))

			XCTAssertEqual(testdir.directories("dir/*").map {$0.string}, ["dir/newerdir"])
			try testdir.create(directory: "dir", ifExists: .replace)
			XCTAssertEqual(testdir.directories("dir/*"), [])

		} catch {
			XCTFail(String(describing: error))
		}
	}


	/// The code examples under "Usage" in the readme.
	func testReadme() {
		do {
			// #### FilePaths


			// #### Change current working directory
			DirectoryPath.current = "/tmp"
			Directory.current = Directory.createTempDirectory()

			// #### Create
			let dirpath = DirectoryPath("dir/dir1")
			var dir1 = try dirpath.create(ifExists: .replace)
			var dir2 = try Directory(create: "dir/dir2", ifExists: .throwError)
			var dir3 = try dir2.create(directory: "dir3", ifExists: .open) // dir/dir2/dir3

			let filepath = FilePath("dir/file1.txt")
			var file1_edit = try filepath.create(ifExists: .open)
			let file2_edit = try EditableFile(create: "file2.txt", ifExists: .open)
			let file3_edit = try dir1.create(file: "file3.txt", ifExists: .open) // dir/dir1/file3

			// #### Open
			dir1 = try dirpath.open()
			dir2 = try Directory(open: "dir/dir2")
			dir3 = try dir2.open(directory: "dir3")

			let file1 = try filepath.open()
			let file2 = try File(open: "file2.txt")
			let file3 = try dir1.open(file: "file3.txt")

			// #### Read/Write
			file1_edit.encoding = .utf16 // .utf8 by default
			file1_edit.write("some text...")
			file2.write(to: &file1_edit)

			let contents: String = file3.read()
			for line in file3.lines() { // a lazy sequence
				// ...
			}
			while let text = file3.readSome() {
				// read pipes etc. piece by piece, instead of waiting until they are closed.
			}

			// #### Symbolic links
			let dir1_link = try Directory(createSymbolicLink: "dir1_link", to: dir1, ifExists: .open)
			let dir2_link = try dir1.create(symbolicLink: "dir2_link", to: dir2, ifExists: .open)
			let file1_link = try File(createSymbolicLink: "file1_link", to: file1, ifExists: .open)
			let file2_link = try dir2.create(symbolicLink: "file2_link", to: file2, ifExists: .open)

			// #### Misc
			try file1_edit.delete()
			try dir1.delete()

			// Suppress unused variables warning.
			_ = [dir3,file2_edit,file3_edit,contents,dir1_link,dir2_link,file1_link,file2_link]
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
		("testDirectory", testDirectory),
		]
}
