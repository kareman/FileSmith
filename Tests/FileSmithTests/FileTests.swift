//
//  FileTests.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 08/12/2016.
//

import XCTest
import FileSmith
import Foundation

class FileTests: XCTestCase {
	func testFiles() {
		do {
			Directory.current = Directory.createTempDirectory()
			let current = Directory.current
			print(current.path)

			XCTAssertEqual(DirectoryPath.current, current.path)
			XCTAssertTrue(current.path.exists())
			XCTAssertEqual(current.directories().count, 0)
			XCTAssertEqual(current.files().count, 0)

			let path_file1 = FilePath("file1.txt")
			let edit_file1 = try path_file1.create(ifExists: .throwError)
			XCTAssertThrowsError(try path_file1.create(ifExists: .throwError))
			edit_file1.write("line 1 of file1.txt\n")

			XCTAssertEqual(try EditableFile(create: path_file1, ifExists: .open).read(), "line 1 of file1.txt\n")

			let read_file1 = try path_file1.open()
			XCTAssertEqual(read_file1.readSome(), "line 1 of file1.txt\n")
			try path_file1.edit().write("line 2 of file1.txt\n")
			XCTAssertEqual(read_file1.read(), "line 2 of file1.txt\n")

			var contents = ""
			try File(open: "file1.txt").write(to: &contents)
			XCTAssertEqual(contents, "line 1 of file1.txt\nline 2 of file1.txt\n")
			XCTAssertEqual(try File(open: "file1.txt").lines().array, ["line 1 of file1.txt","line 2 of file1.txt",""])

			XCTAssertThrowsError(try File(open: "doesntexist.txt"))
			XCTAssertThrowsError(try EditableFile(open: "doesntexist.txt"))
			XCTAssertThrowsError(try EditableFile(create: "file1.txt", ifExists: .throwError))
			XCTAssertThrowsError(try File(createSymbolicLink: "file1.txt", to: edit_file1, ifExists: .throwError))
			XCTAssertThrowsError(try EditableFile(createSymbolicLink: "file1.txt", to: edit_file1, ifExists: .throwError))

			let read_link = try current.create(symbolicLink: "link_to_file1.txt", to: edit_file1, ifExists: .throwError)
			XCTAssertEqual(FileType("link_to_file1.txt"), .regularFile)
			XCTAssertNil(FileType("doesntexist.txt"))
			XCTAssertEqual(FileType.isSymbolicLink("link_to_file1.txt"), true)
			XCTAssertEqual(FileType.isSymbolicLink("file1.txt"), false)
			XCTAssertNil(FileType.isSymbolicLink("doesntexist.txt"))
			XCTAssertEqual(read_link.read(), "line 1 of file1.txt\nline 2 of file1.txt\n")

			let edit_link = try EditableFile(createSymbolicLink: "link_to_file1.txt", to: edit_file1, ifExists: .open)
			edit_link.write("line 3 of file1.txt\n")
			XCTAssertEqual(edit_link.read(), "")
			XCTAssertEqual(read_link.read(), "line 3 of file1.txt\n")

			XCTAssertEqual(try EditableFile(create: path_file1, ifExists: .replace).read(), "")

			XCTAssertEqual(read_link.path.resolvingSymlinks(), edit_file1.path.absolute.resolvingSymlinks())
			XCTAssertEqual(FilePath("/doesntexist/doesntexist.txt").resolvingSymlinks().string, "/doesntexist/doesntexist.txt")

			try edit_file1.delete()
			XCTAssertFalse(edit_file1.path.exists())
			XCTAssertFalse(edit_link.path.exists())
			XCTAssertEqual(FileType(edit_link.path), .brokenSymbolicLink)

			// these succeed, but I don't think they should.
			edit_link.write("won't be written.")
			XCTAssertEqual(edit_link.read(), "")

			let dirpath = DirectoryPath("dir")
			try dirpath.create(ifExists: .throwError)
			XCTAssertThrowsError(try File(open: "dir"))
			XCTAssertThrowsError(try EditableFile(open: "dir"))
			XCTAssertThrowsError(try EditableFile(create: "dir", ifExists: .open))

			edit_link.close()
		} catch {
			XCTFail(String(describing: error))
		}
	}
}

extension FileTests {
	public static var allTests = [
		("testFiles", testFiles),
		]
}
