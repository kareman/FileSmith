//
//  General.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 03/12/2016.
//

extension BidirectionalCollection where Iterator.Element: Equatable {
	func lastIndex(of element: Iterator.Element) -> Index? {
		var idx = index(before: endIndex)
		while idx > startIndex {
			if self[idx] == element {
				return idx
			}
			formIndex(before: &idx)
		}
		// idx == startIndex
		return self[startIndex] == element ? idx : nil
	}
}

extension Sequence {
	public var array: [Iterator.Element] {
		return Array(self)
	}
}

import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
#else
	import Glibc
#endif

func filterFiles(glob pattern: String) -> [String] {
	#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
		let pattern = pattern.hasPrefix("//") ? String(pattern.characters.dropFirst()) : pattern
	#endif
	var globresult = glob_t()
	let cpattern = strdup(pattern)
	defer {
		globfree(&globresult)
		free(cpattern)
	}

	let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
	if glob(cpattern, flags, nil, &globresult) == 0 {
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
			let matchc = globresult.gl_matchc
		#else
			let matchc = globresult.gl_pathc
		#endif
		return (0..<Int(matchc)).flatMap { index in
			return String(validatingUTF8: globresult.gl_pathv[index]!)
		}
	}
	return []
}

/// Lists the contents of a directory.
/// - note: Does not traverse symbolic links to directories.
/// - returns: Lazy sequence of string paths. Directories end in '/', symbolic links to directories do not.
func contentsOfDirectory(at dirpath: String, recursive: Bool) -> LazyMapSequence<FileManager.DirectoryEnumerator, String> {
	let options: FileManager.DirectoryEnumerationOptions = (recursive ? [] : .skipsSubdirectoryDescendants)
	let directoryEnumerator = FileManager().enumerator(at: URL(fileURLWithPath: dirpath), includingPropertiesForKeys: [], options: options)!

	return directoryEnumerator.lazy.map {
		// URL.path drops the / at the end. And absoluteString begins with "file://".
		let filepath = ($0 as! URL).absoluteString.characters
		return String(filepath.dropFirst(+7))
	}
}

open class FixedFileManager: FileManager {
	#if !(os(macOS) || os(iOS) || os(tvOS) || os(watchOS))

	// Not implemented in swift 3.0.2, nor is it in the swift3.1 branch as of 2017–02–26, but it is in the master branch.
	// Copied from https://github.com/apple/swift-corelibs-foundation/commit/f57ff6d1132c599c55bf3834159b2bff28ef455e
	open override func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
		guard
			let attrs = try? attributesOfItem(atPath: srcPath),
			let fileType = attrs[.type] as? FileAttributeType
			else {
				return
		}
		if fileType == .typeDirectory {
			try createDirectory(atPath: dstPath, withIntermediateDirectories: false, attributes: nil)
			let subpaths = try subpathsOfDirectory(atPath: srcPath)
			for subpath in subpaths {
				try copyItem(atPath: srcPath + "/" + subpath, toPath: dstPath + "/" + subpath)
			}
		} else {
			if createFile(atPath: dstPath, contents: contents(atPath: srcPath), attributes: nil) == false {
				throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue, userInfo: [NSFilePathErrorKey : NSString(string: dstPath)])
			}
		}
	}
	#endif
}
