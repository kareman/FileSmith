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

			let edit_file1 = try EditableFile(create: "file1.txt", ifExists: .throwError)
			edit_file1.write("line 1 of file1.txt\n")

			let read_file1 = try File(open: "file1.txt")
			XCTAssertEqual(read_file1.read(), "line 1 of file1.txt\n")
			edit_file1.write("line 2 of file1.txt\n")
			XCTAssertEqual(read_file1.read(), "line 2 of file1.txt\n")

			XCTAssertThrowsError(try File(open: "doesntexist.txt"))
			XCTAssertThrowsError(try EditableFile(open: "doesntexist.txt"))
			XCTAssertThrowsError(try EditableFile(create: "file1.txt", ifExists: .throwError))
			XCTAssertThrowsError(try File(createSymbolicLink: "file1.txt", to: edit_file1, ifExists: .throwError))
			XCTAssertThrowsError(try EditableFile(createSymbolicLink: "file1.txt", to: edit_file1, ifExists: .throwError))

			let read_link = try File(createSymbolicLink: "link_to_file1.txt", to: edit_file1, ifExists: .throwError)
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

			//create dir
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
