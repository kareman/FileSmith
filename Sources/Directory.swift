//
//  Directory.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 29/11/2016.
//

import Foundation

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

public class Directory {
	public static var sandbox = true

	public let path: DirectoryPath

	public init(open path: DirectoryPath) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		guard let type = FileType(stringpath) else {
			throw FileSystemError.notFound(path: path)
		}
		guard type == .directory else {
			throw FileSystemError.notDirectory(path: FilePath(stringpath))
		}
		guard FileManager().isReadableFile(atPath: stringpath) else {
			throw FileSystemError.invalidAccess(path: path, writing: false)
		}
	}

	public convenience init(open stringpath: String) throws {
		try self.init(open: DirectoryPath(stringpath))
	}

	public init(create path: DirectoryPath, ifExists: AlreadyExistsOptions) throws {
		self.path = path.absolute
		let stringpath = self.path.string

		if let type = FileType(stringpath) {
			guard type == .directory else {
				throw FileSystemError.notDirectory(path: FilePath(stringpath))
			}
			switch ifExists {
			case .throwError:	throw FileSystemError.alreadyExists(path: path)
			case .open: return
			case .replace:
				try self.path.verifyIsInSandbox()
				try FileManager().removeItem(atPath: stringpath)
			}
		}
		try self.path.verifyIsInSandbox()
		try FileManager().createDirectory(atPath: stringpath, withIntermediateDirectories: true, attributes: nil)
	}

	public convenience init(create stringpath: String, ifExists: AlreadyExistsOptions) throws {
		try self.init(create: DirectoryPath(stringpath), ifExists: ifExists)
	}
}

extension DirectoryPath {
	public func open() throws -> Directory {
		return try Directory(open: self)
	}

	@discardableResult
	public func create(ifExists: AlreadyExistsOptions) throws -> Directory {
		return try Directory(create: self, ifExists: ifExists)
	}
}

extension Directory {
	public func directories(_ pattern: String = "*/") -> [DirectoryPath] {
		let pathprefix = path.absoluteString + pathseparator
		let pathprefixcount = pathprefix.utf8.count - 1
		return filterFiles(glob: pathprefix + pattern)
			.filter { $0.hasSuffix(pathseparator) }
			.map { DirectoryPath(base: path.components,
			                     relative: parseComponents(String($0.utf8.dropFirst(pathprefixcount))!).components) }
	}

	public func directories(_ pattern: String = "*/", recursive: Bool) -> [DirectoryPath] {
		guard recursive else { return directories(pattern) }
		return (subdirectoriesRecursively(at: path.absoluteString) + [""])
			.flatMap { directories($0 + pathseparator + pattern) }
	}

	public func files(_ pattern: String = "*") -> [FilePath] {
		let pathprefix = path.absoluteString + pathseparator
		let pathprefixcount = pathprefix.utf8.count - 1
		return filterFiles(glob: pathprefix + pattern)
			.filter { !$0.hasSuffix(pathseparator) }
			.map { FilePath(base: path.components,
			                relative: parseComponents(String($0.utf8.dropFirst(pathprefixcount))!).components) }
	}

	public func files(_ pattern: String = "*", recursive: Bool) -> [FilePath] {
		guard recursive else { return files(pattern) }
		return (subdirectoriesRecursively(at: path.absoluteString) + [""])
			.flatMap { files($0 + pathseparator + pattern) }
	}

	public func contains(_ stringpath: String) -> Bool {
		return FileManager().fileExists(atPath: path.string + pathseparator + stringpath)
	}

	public func verifyContains(_ stringpath: String) throws {
		guard self.contains(stringpath) else {
			throw FileSystemError.notFound(path: AnyPath(base: path.absoluteString, relative: stringpath))
		}
	}

	@discardableResult
	public func create(file stringpath: String, ifExists: AlreadyExistsOptions) throws -> EditableFile {
		let newpath = self.path.append(file: stringpath)
		return try EditableFile(create: newpath, ifExists: ifExists)
	}

	@discardableResult
	public func create(directory stringpath: String, ifExists: AlreadyExistsOptions) throws -> Directory {
		let newpath = self.path.append(directory: stringpath)
		return try Directory(create: newpath, ifExists: ifExists)
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
