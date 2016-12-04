//
//  File.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 03/12/2016.
//
//

import Foundation

public class File {
	let path: FilePath

	public convenience init(open stringpath: String) throws {
		try self.init(open: FilePath(stringpath))
	}

	public init(open path: FilePath) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		var isdirectory: ObjCBool = true
		guard Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
			throw FileSystemError.notFound(path: stringpath, base: nil)
		}
		guard !isdirectory.boolValue else {
			throw FileSystemError.isDirectory(path: stringpath)
		}
		guard Files.isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: stringpath)
		}
	}

	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: FilePath(stringpath), ifExists: ifExists)
	}

	public init(create path: FilePath, ifExists: AlreadyExistsOptions) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		var isdirectory: ObjCBool = true
		if Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) {
			guard !isdirectory.boolValue else {
				throw FileSystemError.isDirectory(path: stringpath)
			}
			switch ifExists {
			case .throwError:	throw FileSystemError.alreadyExists(path: stringpath)
			case .open: return
			case .replace:	break
			}
		} else {
			try path.parent().create(ifExists: .open)
		}
		try self.path.verifyIsInSandbox()
		guard Files.createFile(atPath: stringpath, contents: Data(), attributes: nil) else {
			throw FileSystemError.couldNotCreate(path: stringpath)
		}
	}
}

extension FilePath {
	public func open() throws -> File {
		return try File(open: self)
	}

	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> File {
		return try File(create: self, ifExists: ifExists)
	}
}
