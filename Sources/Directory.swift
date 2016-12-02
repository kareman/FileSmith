//
//  Directory.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import Foundation
import Glob

public class Directory {
	let path: DirectoryPath

	public init(open stringpath: String) throws {
		var isdirectory: ObjCBool = false
		guard Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
			throw FileSystemError.notFound(path: stringpath)
		}
		guard isdirectory.boolValue else {
			throw FileSystemError.notDirectory(path: stringpath)
		}
		guard Files.isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: stringpath)
		}
		self.path = DirectoryPath(stringpath).absolute
	}
}

extension Directory {
	public func subDirectoryPaths() throws -> [DirectoryPath] {
		let curdir = DirectoryPath.current
		Files.changeCurrentDirectoryPath(path.string)
		defer { Files.changeCurrentDirectoryPath(curdir.string) }

		return Glob(pattern: "*/", behavior: GlobBehaviorBashV3).map(DirectoryPath.init(_:))
	}
}

enum FileSystemError: Error {
	case notFound(path: String)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String)
}
