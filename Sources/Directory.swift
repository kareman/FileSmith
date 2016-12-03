//
//  Directory.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import Foundation
import Glob

let defaultGlobBehavior = GlobBehaviorBashV3

public class Directory {
	let path: DirectoryPath

	public convenience init(open stringpath: String) throws {
		try self.init(open: DirectoryPath(stringpath))
	}

	public init(open path: DirectoryPath) throws {
		var isdirectory: ObjCBool = false
		let stringpath = path.string
		guard Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
			throw FileSystemError.notFound(path: stringpath, base: nil)
		}
		guard isdirectory.boolValue else {
			throw FileSystemError.notDirectory(path: stringpath)
		}
		guard Files.isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: stringpath)
		}
		self.path = path.absolute
	}
}

extension Directory {
	public func subDirectoryPaths() throws -> [DirectoryPath] {
		let curdir = DirectoryPath.current
		Files.changeCurrentDirectoryPath(path.string)
		defer { Files.changeCurrentDirectoryPath(curdir.string) }
		
		return Glob(pattern: "*/", behavior: defaultGlobBehavior).map(DirectoryPath.init(_:))
	}

	public func contains(_ stringpath: String) -> Bool {
		return Files.fileExists(atPath: path.string + pathseparator + stringpath)
	}

	public func ensureContains(_ stringpath: String) throws {
		guard self.contains(stringpath) else {
			throw FileSystemError.notFound(path: stringpath, base: path.string)
		}
	}

	//	public func contents(

}

extension DirectoryPath {
	public func open() throws -> Directory {
		return try Directory(open: self)
	}
}

enum FileSystemError: Error {
	case notFound(path: String, base: String?)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String)
}
