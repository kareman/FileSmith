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
		if !Directory.sandbox { return }
		if DirectoryPath.current.isAParentOf(self) { return }
		if let s = symbolicLinkTo, DirectoryPath.current.isAParentOf(s) { return }
		throw FileSystemError.outsideSandbox(path: self.string)
	}

	internal var symbolicLinkTo: Self? {
		return (try? FileManager().destinationOfSymbolicLink(atPath: absolute.string)).map { Self.init("/"+$0) }
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
		guard FileManager().fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
			throw FileSystemError.notFound(path: stringpath, base: nil)
		}
		guard isdirectory.boolValue else {
			throw FileSystemError.notDirectory(path: stringpath)
		}
		guard FileManager().isReadableFile(atPath: stringpath) else {
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
		if FileManager().fileExists(atPath: stringpath, isDirectory: &isdirectory) {
			guard isdirectory.boolValue else {
				throw FileSystemError.notDirectory(path: stringpath)
			}
			switch ifExists {
			case .throwError:	throw FileSystemError.alreadyExists(path: stringpath)
			case .open: return
			case .replace:
				try self.path.verifyIsInSandbox()
				try FileManager().trashItem(at: self.path.url, resultingItemURL: nil)
			}
		}
		try self.path.verifyIsInSandbox()
		try FileManager().createDirectory(atPath: stringpath, withIntermediateDirectories: true, attributes: nil)
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
	public func directories(_ pattern: String = "*/") -> [DirectoryPath] {
		let curdir = DirectoryPath.current
		DirectoryPath.current = path
		defer { DirectoryPath.current = curdir }

		return filterFiles(glob: pattern).filter { $0.hasSuffix(pathseparator) }.map(DirectoryPath.init(_:))
	}

	public func files(_ pattern: String = "*") -> [FilePath] {
		let curdir = DirectoryPath.current
		DirectoryPath.current = path
		defer { DirectoryPath.current = curdir }

		return filterFiles(glob: pattern).filter { !$0.hasSuffix(pathseparator) }.map(FilePath.init(_:))
	}

	public func contains(_ stringpath: String) -> Bool {
		return FileManager().fileExists(atPath: path.string + pathseparator + stringpath)
	}

	public func verifyContains(_ stringpath: String) throws {
		guard self.contains(stringpath) else {
			throw FileSystemError.notFound(path: stringpath, base: path.string)
		}
	}

	@discardableResult
	public func add(file stringpath: String, ifExists: AlreadyExistsOptions) throws -> File {
		let newpath = self.path + FilePath(stringpath)
		return try File(create: newpath, ifExists: ifExists)
	}

	@discardableResult
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
