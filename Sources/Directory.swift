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

public enum AlreadyExistsOptions {
	case open, throwError, replace
}

public class Directory {
	let path: DirectoryPath

	public convenience init(open stringpath: String) throws {
		try self.init(open: DirectoryPath(stringpath))
	}

	public init(open path: DirectoryPath) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		var isdirectory: ObjCBool = false
		guard Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
			throw FileSystemError.notFound(path: stringpath, base: nil)
		}
		guard isdirectory.boolValue else {
			throw FileSystemError.notDirectory(path: stringpath)
		}
		guard Files.isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: stringpath)
		}
	}

	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions = .throwError) throws {
		try self.init(create: DirectoryPath(stringpath), ifExists: ifExists)
	}

	public init(create path: DirectoryPath, ifExists: AlreadyExistsOptions = .throwError) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		var isdirectory: ObjCBool = false
		if Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) {
			guard isdirectory.boolValue else {
				throw FileSystemError.notDirectory(path: stringpath)
			}
			switch ifExists {
			case .throwError:	throw FileSystemError.alreadyExists(path: stringpath)
			case .open: return
			case .replace:	break
			}
		}
		try Files.createDirectory(atPath: stringpath, withIntermediateDirectories: true, attributes: nil)
	}
}

extension DirectoryPath {
	public func open() throws -> Directory {
		return try Directory(open: self)
	}

	public func create() throws -> Directory {
		return try Directory(create: self)
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

	public func add(file stringpath: String) throws -> File {
		let newpath = self.path + FilePath(stringpath)
		return try File(create: newpath)
	}

	public func add(directory stringpath: String) throws -> Directory {
		let newpath = self.path + DirectoryPath(stringpath)
		return try Directory(create: newpath)
	}

}

enum FileSystemError: Error {
	case alreadyExists(path: String)
	case notFound(path: String, base: String?)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String)
	case couldNotCreate(path: String)
}
