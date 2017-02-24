//
//  File.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 03/12/2016.
//

import Foundation

public protocol File {

	/// The path to the file
	var path: FilePath { get }

	/// The encoding for the text, if any, in the file.
	var encoding: String.Encoding { get set }

	/// The type of file or file-like item this is.
	var type: FileType { get }

	/// Opens the file at ‘stringpath’.
	init(open stringpath: String) throws

	/// Opens the file at ‘path’.
	init(open path: FilePath) throws
}

extension File {
	/// Opens the file at ‘stringpath’.
	///
	/// - Parameter stringpath: the path to the file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public init(open stringpath: String) throws {
		try self.init(open: FilePath(stringpath))
	}

	fileprivate static func errorForFile(at path: FilePath, writing: Bool) throws {
		guard let type = FileType(path) else {
			throw FileSystemError.notFound(path: path)
		}
		if type == .directory {
			throw FileSystemError.isDirectory(path: DirectoryPath(path))
		}
		throw FileSystemError.invalidAccess(path: path, writing: writing)
	}
}

/// A class for reading text from a file.
public final class ReadableFile: File, ReadableStream {

	/// The path to the file
	public let path: FilePath

	/// The encoding for the text in the file.
	public var encoding: String.Encoding = .utf8

	/// The type of file or file-like item this is.
	public let type: FileType

	internal let filehandle: FileHandle

	private init(path: FilePath, filehandle: FileHandle) {
		self.filehandle = filehandle
		self.path = path
		self.type = FileType(fileDescriptor: filehandle.fileDescriptor)
	}

	/// Opens the file at ‘path’ for reading.
	///
	/// - Parameter path: the path to the file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public convenience init(open path: FilePath) throws {
		guard let filehandle = FileHandle(forReadingAtPath: path.absoluteString) else {
			try ReadableFile.errorForFile(at: path, writing: false)
			fatalError("Should have thrown error when opening \(path.absoluteString)")
		}
		self.init(path: path, filehandle: filehandle)
	}

	/// Creates a new ReadableFile which reads from the provided file handle.
	/// The path is "/dev/fd/" + the file handle's filedescriptor.
	public convenience init(_ filehandle: FileHandle) {
		self.init(path: FilePath("/dev/fd/\(filehandle.fileDescriptor)"), filehandle: filehandle)
	}

	/// Reads everything.
	public func read() -> String {
		return filehandle.read(encoding: encoding)
	}

	/// Reads whatever amount of text the source feels like providing.
	/// If this is a regular file it will read everything at once.
	/// - Returns: more text, or nil if we have reached the end.
	public func readSome() -> String? {
		return filehandle.readSome(encoding: encoding)
	}

	/// Closes the source. If it is not a regular file it must be closed when finished writing,
	/// to prevent deadlock when reading.
	public func close() {
		filehandle.closeFile()
	}

	/// A ReadableStream which reads from standard input.
	static public var stdin: ReadableStream = {
		ReadableFile(path: "/dev/stdin", filehandle: FileHandle.standardInput)
	}()
}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	extension ReadableFile {

		/// `handler` will be called whenever there is new text output available.
		/// Pass `nil` to remove any preexisting handlers.
		public func onOutput(handler: ((String) -> ())? ) {
			guard let h = handler else { filehandle.readabilityHandler = nil; return }

			filehandle.readabilityHandler = { fh in
				if let output = fh.readSome() {
					h(output)
				}
			}
		}
	}
#endif

extension FilePath {

	/// Opens the file at ‘path’ for reading.
	///
	/// - Returns: A ReadableFile ready to read from the file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public func open() throws -> ReadableFile {
		return try ReadableFile(open: self)
	}
}

/// A class for writing text to a file.
public final class WritableFile: File, WritableStream, FileSystemItem {

	/// The path to the file
	public internal(set) var path: FilePath

	/// The encoding for the text in the file.
	public var encoding: String.Encoding = .utf8

	/// The type of file or file-like item this is.
	public let type: FileType

	internal let filehandle: FileHandle

	private init(path: FilePath, filehandle: FileHandle) {
		self.filehandle = filehandle
		self.path = path
		self.type = FileType(fileDescriptor: filehandle.fileDescriptor)
		if self.type == .regularFile { _ = self.filehandle.seekToEndOfFile() }
	}

	/// Opens the file at ‘path’ for writing.
	///
	/// - Parameter path: the path to the file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public convenience init(open path: FilePath) throws {
		try path.verifyIsInSandbox()
		guard let filehandle = FileHandle(forWritingAtPath: path.absoluteString) else {
			try WritableFile.errorForFile(at: path, writing: true)
			fatalError("Should have thrown error when opening \(path.absoluteString)")
		}
		self.init(path: path, filehandle: filehandle)
	}

	/// Creates a new WritableFile which writes to the provided file handle.
	/// The path is "/dev/fd/" + the file handle's filedescriptor.
	public convenience init(_ filehandle: FileHandle) {
		self.init(path: FilePath("/dev/fd/\(filehandle.fileDescriptor)"), filehandle: filehandle)
	}

	fileprivate static func createFile(path: FilePath, ifExists: AlreadyExistsOptions) throws {
		if let type = FileType(path) {
			guard type != .directory else {
				throw FileSystemError.isDirectory(path: DirectoryPath(path))
			}
			switch ifExists {
			case .throwError: throw FileSystemError.alreadyExists(path: path)
			case .open:       return
			case .replace:    break
			}
		} else {
			try path.verifyIsInSandbox()
			try path.parent().create(ifExists: .open)
		}
		try path.verifyIsInSandbox()
		guard FileManager().createFile(atPath: path.absoluteString, contents: Data(), attributes: nil) else {
			throw FileSystemError.couldNotCreate(path: path)
		}
	}

	/// Creates a new file at 'path' for writing.
	///
	/// - Parameters:
	///   - path: The path where the new file should be created.
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Throws: FileSystemError.isDirectory, .couldNotCreate, .alreadyExists, .outsideSandbox.
	public convenience init(create path: FilePath, ifExists: AlreadyExistsOptions) throws {
		try WritableFile.createFile(path: path, ifExists: ifExists)
		try self.init(open: path)
	}

	/// Creates a new file at 'stringpath' for writing.
	///
	/// - Parameters:
	///   - stringpath: The path where the new file should be created.
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Throws: FileSystemError.isDirectory, .couldNotCreate, .alreadyExists, .outsideSandbox.
	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: FilePath(stringpath), ifExists: ifExists)
	}

	/// Deletes this file. For ever.
	public func delete() throws {
		try FileManager().removeItem(atPath: path.absoluteString)
	}

	/// Appends the string to the file.
	/// Nothing is overwritten, just added to the end of the file.
	public func write(_ string: String) {
		filehandle.write(string, encoding: encoding)
	}

	/// Closes the file. No more writing.
	public func close() {
		filehandle.closeFile()
	}

	/// Replaces the entire contents of the file with the string.
	/// - warning: The current contents of the file will be lost.
	/// - warning: Will crash if this is not a regular file.
	public func overwrite(_ string: String) {
		filehandle.seek(toFileOffset: 0)
		filehandle.write(string, encoding: encoding)
		filehandle.truncateFile(atOffset: filehandle.offsetInFile)
		filehandle.synchronizeFile()
	}

	/// A WritableStream which writes to standard output.
	static public var stdout: WritableStream = StdoutStream.default

	/// A WritableStream which writes to standard error.
	static public var stderror: WritableStream = {
		WritableFile(path: "/dev/stderr", filehandle: FileHandle.standardError)
	}()
}

extension FilePath {

	/// Opens the file at this path for writing.
	/// - Returns: A WritableFile for writing to the new file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public func edit() throws -> WritableFile {
		return try WritableFile(open: self)
	}

	/// Creates a new file at this path for writing.
	/// - Parameters:
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Throws: FileSystemError.isDirectory, .couldNotCreate, .alreadyExists, .outsideSandbox.
	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> WritableFile {
		return try WritableFile(create: self, ifExists: ifExists)
	}
}

/// Creates and returns 2 connected streams. Whatever you write into the first one you can read from the second.
public func streams() -> (WritableStream,ReadableStream) {
	let pipe = Pipe()
	return (WritableFile(pipe.fileHandleForWriting), ReadableFile(pipe.fileHandleForReading))
}
