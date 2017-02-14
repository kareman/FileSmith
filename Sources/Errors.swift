//
//  Errors.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 04/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

public enum FileSystemError: Error, Equatable {
	case alreadyExists(path: Path)
	case notFound(path: Path)
	case isDirectory(path: Path)
	case notDirectory(path: Path)
	case invalidAccess(path: Path, writing: Bool)
	case couldNotCreate(path: Path)
	case outsideSandbox(path: Path)

	/// Determines if two FileSystemErrors are equal.
	/// Does not check the types of the paths, just that they are equal in content.
	/// - Returns: True iff the two FileSystemErrors are of the same type, and the paths have the same content. Otherwise False.
	public static func == (left: FileSystemError, right: FileSystemError) -> Bool {
		switch (left, right) {
		case (.alreadyExists(path: let l), .alreadyExists(path: let r)):
			return AnyPath(l) == AnyPath(r)
		case (.notFound(path: let l), .notFound(path: let r)):
			return AnyPath(l) == AnyPath(r)
		case (.isDirectory(path: let l), .isDirectory(path: let r)):
			return AnyPath(l) == AnyPath(r)
		case (.notDirectory(path: let l), .notDirectory(path: let r)):
			return AnyPath(l) == AnyPath(r)
		case (.invalidAccess(path: let l, writing: let lw), .invalidAccess(path: let r, writing: let rw)):
			return (AnyPath(l) == AnyPath(r)) && (lw == rw)
		case (.couldNotCreate(path: let l), .couldNotCreate(path: let r)):
			return AnyPath(l) == AnyPath(r)
		case (.outsideSandbox(path: let l), .outsideSandbox(path: let r)):
			return AnyPath(l) == AnyPath(r)
		default:
			return false
		}
	}
}

extension Path {
	fileprivate var locationDescription: String {
		return string + (base.map {" in " + $0.absoluteString} ?? "")
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
			return "\(path.typeDescription)'\(path.string)' could not be found\((path.base.map {" in " + $0.absoluteString} ?? ""))."
		case .isDirectory(path: let path):
			return path.locationDescription + " is a directory. Expected a file."
		case .notDirectory(path: let path):
			return path.locationDescription + " is not a directory."
		case .invalidAccess(path: let path, writing: let writing):
			return "Could not access \(path.locationDescription)" + (writing ? " for writing." : ".")
		case .couldNotCreate(path: let path):
			return "Could not create \(path.typeDescription)in \(path.locationDescription)."
		case .outsideSandbox(path: let path):
			return FilePath(absolute: path.components).locationDescription + " is not in the current working directory \(DirectoryPath.current.absoluteString). Set FileSmith.sandbox to 'false' if you want to change the file system outside of the current working directory."
		}
	}
}
