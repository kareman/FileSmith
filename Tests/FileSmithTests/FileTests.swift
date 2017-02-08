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

			XCTAssertEqual(DirectoryPath.current, current.path)
			XCTAssertTrue(current.path.exists())
			XCTAssertEqual(current.directories().count, 0)
			XCTAssertEqual(current.files().count, 0)

			let path_file1 = FilePath("file1.txt")
			var write_file1 = try path_file1.create(ifExists: .throwError)
			XCTAssertThrowsError(try path_file1.create(ifExists: .throwError))
			write_file1 = try path_file1.edit()
			write_file1.write("line 1 of file1.txt\n")

			XCTAssertEqual(try ReadableFile(open: path_file1).read(), "line 1 of file1.txt\n")

			let read_file1 = try path_file1.open()
			XCTAssertEqual(read_file1.readSome(), "line 1 of file1.txt\n")
			write_file1.write("line 2 of file1.txt\n")
			XCTAssertEqual(read_file1.readSome(), "line 2 of file1.txt\n")

			var contents = ""
			try ReadableFile(open: "file1.txt").write(to: &contents)
			XCTAssertEqual(contents, "line 1 of file1.txt\nline 2 of file1.txt\n")
			XCTAssertEqual(try ReadableFile(open: "file1.txt").lines().array, ["line 1 of file1.txt","line 2 of file1.txt",""])

			XCTAssertThrowsError(try ReadableFile(open: "doesntexist.txt"))
			XCTAssertThrowsError(try WritableFile(open: "doesntexist.txt"))
			XCTAssertThrowsError(try WritableFile(create: "file1.txt", ifExists: .throwError))
			XCTAssertThrowsError(try WritableFile(createSymbolicLink: "file1.txt", to: write_file1, ifExists: .throwError))

			let read_link: ReadableFile = try current.create(symbolicLink: "link_to_file1.txt", to: write_file1, ifExists: .throwError)
			XCTAssertEqual(FileType("link_to_file1.txt"), .regularFile)
			XCTAssertNil(FileType("doesntexist.txt"))
			XCTAssertEqual(FileType.isSymbolicLink("link_to_file1.txt"), true)
			XCTAssertEqual(FileType.isSymbolicLink("file1.txt"), false)
			XCTAssertNil(FileType.isSymbolicLink("doesntexist.txt"))
			XCTAssertEqual(read_link.readSome(), "line 1 of file1.txt\nline 2 of file1.txt\n")

			let write_link = try WritableFile(createSymbolicLink: "link_to_file1.txt", to: write_file1, ifExists: .open)
			write_link.write("line 3 of file1.txt\n")
			XCTAssertEqual(try String(contentsOfFile: path_file1.absoluteString, encoding: .utf8), "line 1 of file1.txt\nline 2 of file1.txt\nline 3 of file1.txt\n")

			XCTAssertEqual(read_link.path.resolvingSymlinks(), write_file1.path.absolute.resolvingSymlinks())
			XCTAssertEqual(FilePath("/doesntexist/doesntexist.txt").resolvingSymlinks().absoluteString, "/doesntexist/doesntexist.txt")

			try write_file1.delete()
			XCTAssertFalse(write_file1.path.exists())
			XCTAssertFalse(write_link.path.exists())
			XCTAssertEqual(FileType(write_link.path), .brokenSymbolicLink)

			// link is broken, so this presumably works because it is cached.
			write_link.write("will be written.")
			XCTAssertEqual(read_link.read(), "line 3 of file1.txt\nwill be written.")

			let dirpath = DirectoryPath("dir")
			try dirpath.create(ifExists: .throwError)
			XCTAssertThrowsError(try ReadableFile(open: "dir"))
			XCTAssertThrowsError(try WritableFile(open: "dir"))
			XCTAssertThrowsError(try WritableFile(create: "dir", ifExists: .open))

			write_link.close()
			read_link.close()
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testOverwrite() {
		do {
			Directory.current = Directory.createTempDirectory()
			let file = try WritableFile(create: "file.txt", ifExists: .throwError)
			file.print("line 1")
			XCTAssertEqual(try String(contentsOfFile: "file.txt", encoding: .utf8), "line 1\n")
			file.overwrite("something else than line 1\n")
			XCTAssertEqual(try String(contentsOfFile: "file.txt", encoding: .utf8), "something else than line 1\n")
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testStandardInOut() {
		_ = ReadableFile.stdin
		WritableFile.stdout.print(2, "words")
		_ = WritableFile.stderror
	}

	func testStreamsPrint() {
		let (input,output) = streams()

		XCTAssert(input.path.exists())
		XCTAssert(output.path.exists())

		input.print("Write",3,"words")
		XCTAssertEqual(output.readSome(), "Write 3 words\n")
		input.print("No","spaces", separator: "", terminator:"theend")
		XCTAssertEqual(output.readSome(), "Nospacestheend")

		input.close()
		XCTAssertEqual(output.read(), "")
	}
}

extension FileTests {
	public static var allTests = [
		//("testFiles", testFiles),
		("testOverwrite", testOverwrite),
		("testStandardInOut", testStandardInOut),
		("testStreamsPrint", testStreamsPrint),
		]
}
