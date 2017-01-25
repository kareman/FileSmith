//
//  File.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 03/12/2016.
//

import Foundation

public protocol File {
	var path: FilePath { get }
	var encoding: String.Encoding { get set }
	var type: FileType { get }

	init(open stringpath: String) throws
	init(open path: FilePath) throws
}

extension File {
	public init(open stringpath: String) throws {
		try self.init(open: FilePath(stringpath))
	}

	fileprivate static func errorForFile(at stringpath: String, writing: Bool) throws {
		guard let type = FileType(stringpath) else {
			throw FileSystemError.notFound(path: FilePath(stringpath))
		}
		if type == .directory {
			throw FileSystemError.isDirectory(path: DirectoryPath(stringpath))
		}
		throw FileSystemError.invalidAccess(path: FilePath(stringpath), writing: writing)
	}
}


public final class ReadableFile: File, ReadableStream {
	public let path: FilePath
	public var encoding: String.Encoding = .utf8
	public let type: FileType
	internal let filehandle: FileHandle

	public required init(path: FilePath, filehandle: FileHandle) {
		self.filehandle = filehandle
		self.path = path
		self.type = FileType(fileDescriptor: filehandle.fileDescriptor)
	}

	public convenience init(open path: FilePath) throws {
		guard let filehandle = FileHandle(forReadingAtPath: path.absoluteString) else {
			try ReadableFile.errorForFile(at: path.absoluteString, writing: false)
			fatalError("Should have thrown error when opening \(path.absoluteString)")
		}
		self.init(path: path, filehandle: filehandle)
	}

	public func read() -> String {
		return filehandle.read(encoding: encoding)
	}

	public func readSome() -> String? {
		return filehandle.readSome(encoding: encoding)
	}

	public func close() {
		filehandle.closeFile()
	}
}

#if os(macOS)
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
	public func open() throws -> ReadableFile {
		return try ReadableFile(open: self)
	}
}


public final class WriteableFile: File, WriteableStream {
	public let path: FilePath
	public var encoding: String.Encoding = .utf8
	public let type: FileType
	internal let filehandle: FileHandle

	public init(path: FilePath, filehandle: FileHandle) {
		self.filehandle = filehandle
		self.filehandle.seekToEndOfFile()
		self.path = path
		self.type = FileType(fileDescriptor: filehandle.fileDescriptor)
	}

	public convenience init(open path: FilePath) throws {
		try path.verifyIsInSandbox()
		guard let filehandle = FileHandle(forWritingAtPath: path.absoluteString) else {
			try WriteableFile.errorForFile(at: path.absoluteString, writing: true)
			fatalError("Should have thrown error when opening \(path.absoluteString)")
		}
		self.init(path: path, filehandle: filehandle)
	}

	fileprivate static func createFile(path: FilePath, ifExists: AlreadyExistsOptions) throws {
		let stringpath = path.absoluteString

		if let type = FileType(stringpath) {
			guard type != .directory else {
				throw FileSystemError.isDirectory(path: DirectoryPath(stringpath))
			}
			switch ifExists {
			case .throwError:	throw FileSystemError.alreadyExists(path: path)
			case .open: return
			case .replace: break
			}
		} else {
			try path.verifyIsInSandbox()
			try path.parent().create(ifExists: .open)
		}
		try path.verifyIsInSandbox()
		guard FileManager().createFile(atPath: stringpath, contents: Data(), attributes: nil) else {
			throw FileSystemError.couldNotCreate(path: FilePath(stringpath))
		}
	}

	public convenience init(create path: FilePath, ifExists: AlreadyExistsOptions) throws {
		try WriteableFile.createFile(path: path, ifExists: ifExists)
		try self.init(open: path)
	}

	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: FilePath(stringpath), ifExists: ifExists)
	}

	public func delete() throws {
		try FileManager().removeItem(atPath: path.absoluteString)
	}

	/// Appends the string to the file.
	/// Nothing is overwritten, just added to the end of the file.
	public func write(_ string: String) {
		filehandle.write(string, encoding: encoding)
	}

	public func close() {
		filehandle.closeFile()
	}
}

extension FilePath {
	public func edit() throws -> WriteableFile {
		return try WriteableFile(open: self)
	}

	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> WriteableFile {
		return try WriteableFile(create: self, ifExists: ifExists)
	}
}
