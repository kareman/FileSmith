//
//  Directory.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 29/11/2016.
//
//

import Foundation

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
		self.path = DirectoryPath(stringpath)
	}
}

extension Directory {
	public func subDirectoryPaths() throws -> [DirectoryPath] {
		return try Files
			.contentsOfDirectory(atPath: path.string)
			.filter { URL(fileURLWithPath:$0, relativeTo: path.url).hasDirectoryPath }
			.map { path + DirectoryPath($0) }
	}
}

enum FileSystemError: Error {
	case notFound(path: String)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String)
}
