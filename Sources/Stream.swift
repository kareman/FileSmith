//
//  Stream.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 24/01/2017.
//

import Foundation

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
		#if !(os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
			guard !string.isEmpty else {return}
		#endif
		guard let data = string.data(using: encoding, allowLossyConversion: false) else {
			fatalError("Could not convert text to binary data.")
		}
		self.write(data)
	}
}


/// A stream of text. Does as much as possible lazily.
public protocol ReadableStream : class, TextOutputStreamable {

	var encoding: String.Encoding {get set}

	/// Whatever amount of text the stream feels like providing.
	/// If the source is a file this will read everything at once.
	/// - returns: more text from the stream, or nil if we have reached the end.
	func readSome () -> String?

	/// Read everything at once.
	func read () -> String
}

extension ReadableStream {

	/// Split stream lazily into lines.
	public func lines () -> LazySequence<AnySequence<String>> {
		return AnySequence(PartialSourceLazySplitSequence({self.readSome()?.characters}, separator: "\n").map { String($0) }).lazy
	}

	/// Writes the text in this file to the given TextOutputStream.
	public func write<Target : TextOutputStream>(to target: inout Target) {
		while let text = self.readSome() { target.write(text) }
	}
}

/// An output stream, like standard output or a writeable file.
public protocol WritableStream : class, TextOutputStream {

	var encoding: String.Encoding {get set}

	/// Write the textual representation of `x` to the stream.
	func write(_ x: String)

	/// Close the stream. Must be called on local streams when finished writing.
	func close()
}

extension WritableStream {

	/// Writes the textual representations of the given items into the stream.
	/// Works exactly the same way as the built-in `print`.
	public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
		var iterator = items.lazy.map(String.init(describing:)).makeIterator()
		iterator.next().map(write)
		while let item = iterator.next() {
			write(separator)
			write(item)
		}
		write(terminator)
	}
}

/// Singleton WritableStream used only for `print`ing to stdout.
internal class StdoutStream: WritableStream {
	public var encoding: String.Encoding = .utf8

	private init () { }

	static var `default`: StdoutStream { return StdoutStream() }

	public func write <T> (_ x: T) {
		print(x, terminator: "")
	}

	public func close () {}
}
