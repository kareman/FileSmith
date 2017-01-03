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
				try FileManager().removeItem(atPath: stringpath)
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
		let pathprefix = path.absolute.string + pathseparator
		let pathprefixcount = pathprefix.utf8.count - 1
		return filterFiles(glob: pathprefix + pattern)
			.filter { $0.hasSuffix(pathseparator) }
			.map { DirectoryPath(base: path.components,
			                     relative: parseComponents(String($0.utf8.dropFirst(pathprefixcount))!).components) }
	}

	public func directories(_ pattern: String = "*/", recursive: Bool) -> [DirectoryPath] {
		guard recursive else { return directories(pattern) }
		return (subdirectoriesRecursively(at: path.absolute.string) + [""])
			.flatMap { directories($0 + pathseparator + pattern) }
	}

	public func files(_ pattern: String = "*") -> [FilePath] {
		let pathprefix = path.absolute.string + pathseparator
		let pathprefixcount = pathprefix.utf8.count - 1
		return filterFiles(glob: pathprefix + pattern)
			.filter { !$0.hasSuffix(pathseparator) }
			.map { FilePath(base: path.components,
			                relative: parseComponents(String($0.utf8.dropFirst(pathprefixcount))!).components) }
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
	public func create(file stringpath: String, ifExists: AlreadyExistsOptions) throws -> EditableFile {
		let newpath = self.path + FilePath(stringpath)
		return try EditableFile(create: newpath, ifExists: ifExists)
	}

	@discardableResult
	public func create(directory stringpath: String, ifExists: AlreadyExistsOptions) throws -> Directory {
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
