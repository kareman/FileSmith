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

#if os(Linux)
	import Glibc
#else
	import Darwin
#endif

func filterFiles(glob pattern: String) -> [String] {
	#if !os(Linux)
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
		#if os(Linux)
			let matchc = globresult.gl_pathc
		#else
			let matchc = globresult.gl_matchc
		#endif
		return (0..<Int(matchc)).flatMap { index in
			return String(validatingUTF8: globresult.gl_pathv[index]!)
		}
	}
	return []
}

func subdirectoriesRecursively(at dirpath: String) -> [String] {
	let stringpathlength = dirpath.characters.count + 1
	let directoryEnumerator = FileManager().enumerator(at: URL(fileURLWithPath: dirpath), includingPropertiesForKeys: [])!

	return directoryEnumerator.flatMap {
		// URL.path drops the / at the end. And absoluteString begins with "file://".
		let filepath = ($0 as! URL).absoluteString.characters
		guard filepath.last == Character(pathseparator) else { return nil }
		return String(filepath.dropFirst(stringpathlength+7))
	}
}
