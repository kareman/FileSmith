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
	case isDirectory(path: DirectoryPath)
	case notDirectory(path: FilePath)
	case invalidAccess(path: Path, writing: Bool)
	case couldNotCreate(path: Path)
	case outsideSandbox(path: Path)
}

extension Path {
	fileprivate var locationDescription: String {
		return string + (base.map {" in " + $0.string} ?? "")
	}

	fileprivate var typeDescription: String {
		switch self {
		case is DirectoryPath: return "Directory "
		case is FilePath:      return "File "
		default:               return ""
		}
	}
}

extension FileSystemError: CustomStringConvertible {
	public var description: String {
		switch self {
		case .alreadyExists(path: let path):
			return path.locationDescription + " already exists."
		case .notFound(path: let path):
			return path.typeDescription + path.locationDescription + " does not exist."
		case .isDirectory(path: let path):
			return path.locationDescription + " is a directory. Expected a file."
		case .notDirectory(path: let path):
			return path.locationDescription + " is not a directory."
		case .invalidAccess(path: let path, writing: let writing):
			return "Could not access \(path.locationDescription)" + (writing ? " for writing." : ".")
		case .couldNotCreate(path: let path):
			return "Could not create \(path.typeDescription)in \(path.locationDescription)."
		case .outsideSandbox(path: let path):
			return FilePath(absolute: path.components).locationDescription + " is not in the current working directory \(DirectoryPath.current.string). Set Directory.sandbox to 'false' if you want to change the file system outside of the current working directory."
		}
	}
}
