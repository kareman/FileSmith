//
//  Errors.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 04/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

public enum FileSystemError: Error {
	case alreadyExists(path: Path)
	case notFound(path: Path)
	case notFoundOfUnknownType(stringpath: String, base: DirectoryPath?)
	case isDirectory(path: DirectoryPath)
	case notDirectory(path: FilePath)
	case invalidAccess(path: Path, writing: Bool)
	case couldNotCreate(path: Path)
	case outsideSandbox(path: Path)
}
