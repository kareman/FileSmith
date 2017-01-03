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
	public var array: [Iterator.Element] {
		return Array(self)
	}
}

import Foundation

#if os(Linux)
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

func subdirectoriesRecursively(at stringpath: String) -> [String] {
	let stringpathlength = stringpath.characters.count + 1
	let directoryEnumerator = FileManager().enumerator(at: URL(fileURLWithPath: stringpath), includingPropertiesForKeys: [])!

	return directoryEnumerator.flatMap {
		let fileURL = $0 as! URL
		return fileURL.hasDirectoryPath ? String(fileURL.path.characters.dropFirst(stringpathlength)) : nil
	}
}

extension FileHandle {

	func readSome(encoding: String.Encoding = .utf8) -> String? {
		let data = self.availableData

		guard data.count > 0 else { return nil }
		guard let result = String(data: data, encoding: encoding) else {
			fatalError("Could not convert binary data to text.")
		}

		return result
	}

	func read(encoding: String.Encoding = .utf8) -> String {
		let data = self.readDataToEndOfFile()

		guard let result = String(data: data, encoding: encoding) else {
			fatalError("Could not convert binary data to text.")
		}

		return result
	}
}

extension FileHandle {

	func write(_ string: String, encoding: String.Encoding = .utf8) {
		#if os(Linux)
			guard !string.isEmpty else {return}
		#endif
		guard let data = string.data(using: encoding, allowLossyConversion: false) else {
			fatalError("Could not convert text to binary data.")
		}
		self.write(data)
	}
}
