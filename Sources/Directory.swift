//
//  Directory.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 29/11/2016.
//

import Foundation


/// What to do if trying to create a file or directory that already exists.
public enum AlreadyExistsOptions {
	case open, throwError, replace
}

extension Path {
	internal func verifyIsInSandbox() throws {
		if !Directory.sandbox { return }
		if DirectoryPath.current.isAParentOf(self) { return }
		if DirectoryPath.current.isAParentOf(resolvingSymlinks()) { return }
		throw FileSystemError.outsideSandbox(path: self)
	}
}

/// A directory which exists in the local filesystem (at least at the time of initialisation).
public class Directory {
	
	/// If true, then you can only make changes to the file system in the current working directory, or any of its subdirectories.
	public static var sandbox = true
				
	/// The path to this directory.
	public let path: DirectoryPath

	/// Opens an already existing directory.
	///
	/// - Parameter path: The path to the directory.
	/// - Throws: FileSystemError.notFound, .notDirectory, .invalidAccess.
	public init(open path: DirectoryPath) throws {
		self.path = path
		let stringpath = self.path.absoluteString

		guard let type = FileType(stringpath) else {
			throw FileSystemError.notFound(path: path)
		}
		guard type == .directory else {
			throw FileSystemError.notDirectory(path: FilePath(path))
		}
		guard FileManager().isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: path, writing: false)
		}
	}

	/// Opens an already existing directory.
	///
	/// - Parameter stringpath: The string path to the directory.
	/// - Throws: FileSystemError.notFound, .notDirectory, .invalidAccess.
	public convenience init(open stringpath: String) throws {
		try self.init(open: DirectoryPath(stringpath))
	}


	/// Creates a new directory.
	///
	/// - Parameters:
	///   - path: The path where the new directory should be created. 
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox.
	public init(create path: DirectoryPath, ifExists: AlreadyExistsOptions) throws {
		self.path = path
		let stringpath = self.path.absoluteString

		if let type = FileType(stringpath) {
			guard type == .directory else {
				throw FileSystemError.notDirectory(path: FilePath(path))
			}
			switch ifExists {
			case .throwError: throw FileSystemError.alreadyExists(path: path)
			case .open:       return
			case .replace:
				try self.path.verifyIsInSandbox()
				try FileManager().removeItem(atPath: stringpath)
			}
		}
		try self.path.verifyIsInSandbox()
		try FileManager().createDirectory(atPath: stringpath, withIntermediateDirectories: true, attributes: nil)
	}

	/// Creates a new directory.
	///
	/// - Parameters:
	///   - path: The string path where the new directory should be created.
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox.
	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: DirectoryPath(stringpath), ifExists: ifExists)
	}
}

extension DirectoryPath {

	/// Returns a Directory object if there is a directory at this path.
	///
	/// - Throws: FileSystemError.notFound, .notDirectory, .invalidAccess.
	public func open() throws -> Directory {
		return try Directory(open: self)
	}

	/// Creates a new directory at this path.
	///
	/// - Parameter ifExists: What to do if it already exists: open, throw error or replace.
	/// - Returns: A Directory object with this path. 
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox.
	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> Directory {
		return try Directory(create: self, ifExists: ifExists)
	}
}

extension Directory {

	static func filter<P: Path>(pattern: String, relativeTo path: DirectoryPath) -> [P] {
		let pathprefixcount = path.components.count
		return filterFiles(glob: pattern)
			.flatMap(FileSmith.path(detectTypeOf:))
			.flatMap { ($0 as? P) }
			.map { P(base: path.components,
			     relative: Array($0.components.dropFirst(pathprefixcount)))
			}
	}

	func filesOrDirectories<P: Path>(_ pattern: String, recursive: Bool = false) -> [P] {
		return Directory.filter(pattern: path.absoluteString + pathseparator + pattern, relativeTo: path)
			+ (!recursive ? [] : (contentsOfDirectory(at: path.absoluteString, recursive: true))
			.flatMap(FileSmith.path(detectTypeOf:))
			.flatMap { $0 as? DirectoryPath }
			.flatMap { Directory.filter(pattern: $0.absoluteString + pathseparator + pattern, relativeTo: path) })
	}

	/// Lists all directories under this directory matching the pattern.
	///
	/// - Parameters:
	///   - pattern: A glob pattern, supporting wilcards "*" and "?". The default is "*", matching everything.
	///   - recursive: If true, searches all subdirectories and their subdirectories etc. The default is `false`.
	/// - Returns: An array of DirectoryPath.
	public func directories(_ pattern: String = "*", recursive: Bool = false) -> [DirectoryPath] {
		return filesOrDirectories(pattern, recursive: recursive)
	}

	/// Lists all files under this directory matching the pattern.
	///
	/// - Parameters:
	///   - pattern: A glob pattern, supporting wilcards "*" and "?". The default is "*", matching everything.
	///   - recursive: If true, searches all subdirectories and their subdirectories etc. The default is `false`.
	/// - Returns: An array of FilePath.
	public func files(_ pattern: String = "*", recursive: Bool = false) -> [FilePath] {
		return filesOrDirectories(pattern, recursive: recursive)
	}

	/// Returns true if there is a file or directory at 'stringpath' relative to this directory.
	public func contains(_ stringpath: String) -> Bool {
		return FileManager().fileExists(atPath: path.absoluteString + pathseparator + stringpath)
	}

	/// Throws an error if there is not a file or directory at 'stringpath' relative to this directory.
	/// - Throws: FileSystemError.notFound.
	public func verifyContains(_ stringpath: String) throws {
		guard self.contains(stringpath) else {
			throw FileSystemError.notFound(path: AnyPath(base: path.absoluteString, relative: stringpath))
		}
	}

	/// Creates a new file at 'stringpath', relative to this directory.
	///
	/// - Parameters:
	///   - stringpath: The path where the new file should be created.
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Returns: A WritableFile ready to write to the new file.
	/// - Throws: FileSystemError.isDirectory, .couldNotCreate, .alreadyExists, .outsideSandbox.
	@discardableResult
	public func create(file stringpath: String, ifExists: AlreadyExistsOptions) throws -> WritableFile {
		let newpath = self.path.append(file: stringpath)
		return try WritableFile(create: newpath, ifExists: ifExists)
	}

	/// Creates a new directory at 'stringpath', relative to this directory.
	///
	/// - Parameters:
	///   - stringpath: The path where the new directory should be created.
	///   - ifExists: What to do if it already exists: open, throw error or replace.
	/// - Returns: A WritableFile ready to write to the new file.
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox.
	@discardableResult
	public func create(directory stringpath: String, ifExists: AlreadyExistsOptions) throws -> Directory {
		let newpath = self.path.append(directory: stringpath)
		return try Directory(create: newpath, ifExists: ifExists)
	}

	/// Opens for reading the file at 'stringpath', relative to this directory.
	///
	/// - Parameter stringpath: the path to the file, relative to this directory.
	/// - Returns: A ReadableFile ready to read from the file. 
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess.
	public func open(file stringpath: String) throws -> ReadableFile {
		let newpath = self.path.append(file: stringpath)
		return try ReadableFile(open: newpath)
	}

	/// Opens for writing the file at 'stringpath', relative to this directory.
	///
	/// - Parameter stringpath: the path to the file, relative to this directory.
	/// - Returns: A WritableFile ready to write to the file.
	/// - Throws: FileSystemError.notFound, .isDirectory, .invalidAccess, .outsideSandbox.
	public func edit(file stringpath: String) throws -> WritableFile {
		let newpath = self.path.append(file: stringpath)
		return try WritableFile(open: newpath)
	}

	/// Opens the directory at 'stringpath', relative to this directory.
	///
	/// - Parameter stringpath: the path to the directory, relative to this directory.
	/// - Returns: A Directory object.
	/// - Throws: FileSystemError.notFound, .notDirectory, .invalidAccess.
	public func open(directory stringpath: String) throws -> Directory {
		let newpath = self.path.append(directory: stringpath)
		return try Directory(open: newpath)
	}

	/// Deletes this directory. For ever.
	///
	/// - Throws: FileSystemError.outsideSandbox, NSError.
	public func delete() throws {
		try path.verifyIsInSandbox()
		try FileManager().removeItem(atPath: path.absoluteString)
	}
}

extension Directory {

	/// The current working directory.
	public static var current: Directory {
		get {
			do {
				return try DirectoryPath.current.open()
			} catch {
				fatalError("Could not open current directory '\(DirectoryPath.current)':\n\(error)")
			}
		}
		set {
			guard FileManager().changeCurrentDirectoryPath(newValue.path.absoluteString) else {
				fatalError("Could not change current directory to \(newValue.path.absoluteString)")
			}
		}
	}

	/// The current user's home directory.
	public static var home: Directory {
		do {
			return try DirectoryPath.home.open()
		} catch {
			fatalError("Could not open home directory '\(DirectoryPath.home)':\n\(error)")
		}
	}

	/// The root directory in the local file system.
	public static var root: Directory {
		do {
			return try DirectoryPath.root.open()
		} catch {
			fatalError("Could not open root directory '\(DirectoryPath.root)':\n\(error)")
		}
	}

	/// Creates a new empty temporary directory, guaranteed to be unique every time.
	public static func createTempDirectory() -> Directory {
		let name = ProcessInfo.processInfo.processName
		let tempdirectory = NSTemporaryDirectory() + "/" + name + "-" + ProcessInfo.processInfo.globallyUniqueString
		do {
			try FileManager().createDirectory(atPath: tempdirectory, withIntermediateDirectories: true, attributes: nil)
			return try Directory(open: tempdirectory)
		} catch let error as NSError {
			fatalError("Could not create new temporary directory '\(tempdirectory)':\n\(error.localizedDescription)")
		}
	}
}
