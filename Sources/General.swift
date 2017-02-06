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
func contentsOfDirectory(at dirpath: String, recursive: Bool) -> LazyMapSequence<FileManager.DirectoryEnumerator,String> {
	let options: FileManager.DirectoryEnumerationOptions = (recursive ? [] : .skipsSubdirectoryDescendants)
	let directoryEnumerator = FileManager().enumerator(at: URL(fileURLWithPath: dirpath), includingPropertiesForKeys: [], options: options)!

	return directoryEnumerator.lazy.map {
		// URL.path drops the / at the end. And absoluteString begins with "file://".
		let filepath = ($0 as! URL).absoluteString.characters
		return String(filepath.dropFirst(+7))
	}
}
