//
//  General.swift
//  SwiftyPath
//
//  Created by Kåre Morstøl on 03/12/2016.
//
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
	var array: [Iterator.Element] {
		return Array(self)
	}
}

#if os(Linux)
	import Foundation

	extension ObjCBool {
		var boolValue: Bool { return self }
	}
#endif

#if os(Linux)
	import Glibc
#else
	import Darwin
#endif

func filterFiles(glob pattern: String) -> [String] {
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
