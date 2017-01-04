//
//  Errors.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 04/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

public enum FileSystemError: Error {
	case alreadyExists(path: String)
	case notFound(path: String, base: String?)
	case isDirectory(path: String)
	case notDirectory(path: String)
	case invalidAccess(path: String, writing: Bool)
	case couldNotCreate(path: String)
	case outsideSandbox(path: String)
}
