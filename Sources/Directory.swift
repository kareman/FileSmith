//
//  Directory.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import Foundation

public enum AlreadyExistsOptions {
	case open, throwError, replace
}

extension Path {
	internal func verifyIsInSandbox() throws {
		if Directory.sandbox && !DirectoryPath.current.isAParentOf(self) {
			throw FileSystemError.outsideSandbox(path: self.string)
		}
	}
}

public class Directory {
	public static var sandbox = true

	public let path: DirectoryPath

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
			throw FileSystemError.invalidAccess(path: stringpath, writing: false)
		}
	}

	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: DirectoryPath(stringpath), ifExists: ifExists)
	}

	public init(create path: DirectoryPath, ifExists: AlreadyExistsOptions) throws {
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
		try self.path.verifyIsInSandbox()
		try Files.createDirectory(atPath: stringpath, withIntermediateDirectories: true, attributes: nil)
	}
}

extension DirectoryPath {
	public func open() throws -> Directory {
		return try Directory(open: self)
	}

	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> Directory {
		return try Directory(create: self, ifExists: ifExists)
	}
}

extension Directory {
	public func subDirectoryPaths() throws -> [DirectoryPath] {
		let curdir = DirectoryPath.current
		Files.changeCurrentDirectoryPath(path.string)
		defer { Files.changeCurrentDirectoryPath(curdir.string) }
		
		return filterFiles(glob: "*/").filter { $0.hasSuffix(pathseparator) }.map(DirectoryPath.init(_:))
	}

	public func contains(_ stringpath: String) -> Bool {
		return Files.fileExists(atPath: path.string + pathseparator + stringpath)
	}

	public func ensureContains(_ stringpath: String) throws {
		guard self.contains(stringpath) else {
			throw FileSystemError.notFound(path: stringpath, base: path.string)
		}
	}

	public func add(file stringpath: String, ifExists: AlreadyExistsOptions) throws -> File {
		let newpath = self.path + FilePath(stringpath)
		return try File(create: newpath, ifExists: ifExists)
	}

	public func add(directory stringpath: String, ifExists: AlreadyExistsOptions) throws -> Directory {
		let newpath = self.path + DirectoryPath(stringpath)
		return try Directory(create: newpath, ifExists: ifExists)
	}
}

public enum FileSystemError: Error {
	case alreadyExists(path: String)
	case notFound(path: String, base: String?)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String, writing: Bool)
	case couldNotCreate(path: String)
	case outsideSandbox(path: String)
}
