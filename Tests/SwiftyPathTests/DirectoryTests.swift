//
//  DirectoryTests.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import XCTest
import SwiftyPath

let Files = FileManager.default

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
}
