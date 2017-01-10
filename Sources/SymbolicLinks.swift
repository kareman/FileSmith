//
//  SymbolicLinks.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 10/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

import Foundation

extension File {
	public convenience init(createSymbolicLink newlink: FilePath, to target: File, ifExists: AlreadyExistsOptions) throws {
		if let newlinktype = FileType(newlink) {
			guard newlinktype != .directory else { throw FileSystemError.isDirectory(path: newlink) }
			switch ifExists {
			case .throwError:
				throw FileSystemError.alreadyExists(path: newlink)
			case .replace:
				try newlink.verifyIsInSandbox()
				try FileManager().removeItem(atPath: newlink.absoluteString)
			case .open:
				let currenttarget = try FilePath(FileManager().destinationOfSymbolicLink(atPath: newlink.absoluteString))
				// if currenttarget is relative, its base is the directory of newlink.
				let currenttargetabsolutepath = currenttarget.relativeComponents.map(newlink.parent().append) ?? currenttarget
				guard target.path == currenttargetabsolutepath else {
					throw FileSystemError.invalidAccess(path: newlink, writing: true)
				}
				try self.init(open: newlink)
				return
			}
		}
		try newlink.verifyIsInSandbox()
		try FileManager().createSymbolicLink(atPath: newlink.absoluteString, withDestinationPath: target.path.absoluteString)
		try self.init(open: newlink)
	}
}

extension Directory {
	public convenience init(createSymbolicLink newlink: DirectoryPath, to target: Directory, ifExists: AlreadyExistsOptions) throws {
		if let newlinktype = FileType(newlink) {
			guard newlinktype == .directory else { throw FileSystemError.notDirectory(path: newlink) }
			switch ifExists {
			case .throwError:
				throw FileSystemError.alreadyExists(path: newlink)
			case .replace:
				try newlink.verifyIsInSandbox()
				try FileManager().removeItem(atPath: newlink.absoluteString)
			case .open:
				let currenttarget = try DirectoryPath(FileManager().destinationOfSymbolicLink(atPath: newlink.absoluteString))
				// if currenttarget is relative, its base is the directory of newlink.
				let currenttargetabsolutepath = currenttarget.relativeComponents.map(newlink.parent().append) ?? currenttarget
				guard target.path == currenttargetabsolutepath else {
					throw FileSystemError.invalidAccess(path: newlink, writing: true)
				}
				try self.init(open: newlink)
				return
			}
		}
		try newlink.verifyIsInSandbox()
		try FileManager().createSymbolicLink(atPath: newlink.absoluteString, withDestinationPath: target.path.absoluteString)
		try self.init(open: newlink)
	}
}

extension Directory {
	@discardableResult
	public func create(symbolicLink newlink: String, to target: Directory, ifExists: AlreadyExistsOptions) throws -> Directory {
		let newpath = self.path.append(directory: newlink)
		return try Directory(create: newpath, ifExists: ifExists)
	}

	@discardableResult
	public func create(symbolicLink newlink: String, to target: File, ifExists: AlreadyExistsOptions) throws -> File {
		let newpath = self.path.append(file: newlink)
		return try File(create: newpath, ifExists: ifExists)
	}
}
