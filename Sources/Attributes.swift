//
//  Attributes.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 05/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
#else
	import Glibc
#endif

/// The file type of an item in the local file system.
public enum FileType: Equatable, Hashable {
	case regularFile
	case directory
	case characterSpecial
	case blockSpecial
	case socket
	case brokenSymbolicLink
	case namedPipe
	case unknown

	fileprivate init(_ fileinfo: stat) {
		switch fileinfo.st_mode & S_IFMT {
		case S_IFREG:  self = .regularFile
		case S_IFDIR:  self = .directory
		case S_IFCHR:  self = .characterSpecial
		case S_IFBLK:  self = .blockSpecial
		case S_IFSOCK: self = .socket
		case S_IFLNK:  self = .brokenSymbolicLink
		case S_IFIFO:  self = .namedPipe
		default:       self = .unknown
		}
	}

	/// Returns the file type of the item at the path. Follows symbolic links, so the type is never 'symbolicLink'.
	/// - returns: The file type, or nil if the item does not exist.
	public init?(_ path: String) {
		var fileinfo = stat()
		if stat(path, &fileinfo) < 0 && lstat(path, &fileinfo) < 0 {
			return nil
		}
		self.init(fileinfo)
	}

	/// Returns the file type of the item at the path. Follows symbolic links, so the type is never 'symbolicLink'.
	/// - returns: The file type, or nil if the item does not exist.
	public init?(_ path: Path) {
		self.init(path.absoluteString)
	}

	/// Returns the file type of the item referenced by the provided file descriptor. Crashes if the file descriptor is invalid.
	public init(fileDescriptor: Int32) {
		var fileinfo = stat()
		guard fstat(fileDescriptor, &fileinfo) >= 0 else { fatalError("File descriptor \(fileDescriptor) is invalid.") }
		self.init(fileinfo)
	}

	/// Checks if the file item referenced by `path` is a symbolic link. Returns nil if `path` could not be accessed.
	public static func isSymbolicLink(_ path: String) -> Bool? {
		var fileinfo = stat()
		guard lstat(path, &fileinfo) >= 0 else { return nil }
		return (fileinfo.st_mode & S_IFMT) == S_IFLNK
	}
}
