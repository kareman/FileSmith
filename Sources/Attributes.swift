//
//  Attributes.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 05/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

#if os(macOS) || os(iOS)
	import Darwin
#else
	import Glibc
#endif

/// The file type of an item in the local file system.
public enum FileType: Equatable {
	case regular
	case directory
	case characterSpecial
	case blockSpecial
	case socket
	case unknown

	init(_ fileinfo: stat) {
		switch fileinfo.st_mode & S_IFMT {
		case S_IFREG:  self = .regular
		case S_IFDIR:  self = .directory
		case S_IFCHR:  self = .characterSpecial
		case S_IFBLK:  self = .blockSpecial
		case S_IFSOCK: self = .socket
		default:       self = .unknown
		}
	}

	/// Returns the file type of the item at the path. Follows symbolic links, so the type is never 'symbolicLink'.
	/// - returns: The file type, or nil if the item does not exist or is a symbolic link to something that does not exist.
	public init?(path: String) {
		var fileinfo = stat()
		guard stat(path, &fileinfo) >= 0 else { return nil }
		self.init(fileinfo)
	}
}
