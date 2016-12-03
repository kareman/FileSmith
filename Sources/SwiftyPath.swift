
import Foundation

let Files = FileManager()
let pathseparator = "/"
let homedir = NSHomeDirectoryForUser(NSUserName())!
let homedircomponents = homedir.components(separatedBy: pathseparator)

public protocol Path: CustomStringConvertible {
	var components: [String] { get }
	var relativeComponents: [String]? { get }
	var baseComponents: [String]? { get }
	init(absolute components: [String])
	init(base: [String], relative: [String])
	init(_ stringpath: String)
}

extension Path {
	private static func prepareComponents<C: Collection>(_ components: C) -> [String]
		where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
			return components.filter { $0 != "" && $0 != "." }
	}

	public init(_ stringpath: String) {
		precondition(stringpath != "", "The path cannot be empty.")
		let components = stringpath.components(separatedBy: pathseparator)
		if components.first == "" {
			self.init(absolute: Self.prepareComponents(components))
		} else if components.first == "~" {
			self.init(absolute: homedircomponents + Self.prepareComponents(components.dropFirst()))
		} else {
			let current = Array(Files.currentDirectoryPath.components(separatedBy: pathseparator).dropFirst())
			self.init(base: current, relative: Self.prepareComponents(components))
		}
		if self is FilePath {
			precondition(!stringpath.hasSuffix(pathseparator),
				"Trying to create a FilePath with a directory path (ending in '\(pathseparator)'). Use DirectoryPath instead.")
		}
	}

	/// Creates a path from a URL.
	///
	/// - warning: Will crash if URL is not a file URL or does not have a directory path.
	/// - bug: If the URL has a relative path and it uses .. to refer to its parent directories,
	/// the behaviour is undefined. Things may not end well.
	public init(_ url: URL) {
		precondition(url.isFileURL && url.hasDirectoryPath, "The URL does not point to a directory.")
		if let base = url.baseURL?.pathComponents {
			self.init(base: Array(base.dropFirst()), relative: Array(url.pathComponents.suffix(from: base.count)))
		} else {
			self.init(absolute: Array(url.pathComponents.dropFirst()))
		}
	}
}

/// Tries to create a new Path by detecting if it is a directory or a file.
///
/// If the path ends in a '/', it is a directory.
/// If the path is valid, check in the file system.
/// Otherwise return nil.
public func path(detectTypeOf stringpath: String) -> Path? {
	guard !stringpath.hasSuffix(pathseparator) else {
		return DirectoryPath(stringpath)
	}

	var isdirectory: ObjCBool = false
	guard Files.fileExists(atPath: stringpath, isDirectory: &isdirectory) else {
		return nil
	}
	return isdirectory.boolValue ? DirectoryPath(stringpath) : FilePath(stringpath)
}

extension Path {

	public var isDirectory: Bool {
		return self is DirectoryPath
	}

	public var string: String {
		return relativeString ?? (pathseparator + components.joined(separator: pathseparator))
	}

	public var description: String {
		return string
	}

	public var base: DirectoryPath? {
		return baseComponents.map { DirectoryPath(absolute: $0) }
	}

	public var relativeString: String? {
		return relativeComponents?.joined(separator: pathseparator)
	}

	public var relativeURL: URL? {
		return relativeString.map { URL(fileURLWithPath: $0, isDirectory: isDirectory) }
	}

	public var url: URL {
		return URL(fileURLWithPath: relativeString ?? string, isDirectory: isDirectory, relativeTo: base?.url)
	}

	public func exists() -> Bool {
		return Files.fileExists(atPath: string)
	}

	public var name: String {
		return components.last!
	}

	public var `extension`: String? {
		let nameparts = name.components(separatedBy: ".")
		return (nameparts.count == 1) || (nameparts.count == 2 && nameparts.first == "") ? nil : nameparts.last
	}

	public var absolute: Self {
		return Self(absolute: components)
	}
}


public struct DirectoryPath: Path {
	public let components: [String]
	let _relativestart: Array<String>.Index?

	public init(absolute components: [String]) {
		self.components = components
		_relativestart = nil
	}

	public init(base: [String], relative: [String]) {
		components = base + relative
		_relativestart = base.endIndex
	}

	public var relativeComponents: [String]? {
		return _relativestart.map { Array(components.suffix(from: $0)) }
	}

	public var baseComponents: [String]? {
		return _relativestart.map { Array(components.prefix(upTo: $0)) }
	}
}

public struct FilePath: Path {
	public let components: [String]
	let _relativestart: Array<String>.Index?

	public init(absolute components: [String]) {
		self.components = components
		_relativestart = nil
	}

	public init(base: [String], relative: [String]) {
		components = base + relative
		_relativestart = base.endIndex
	}

	public var relativeComponents: [String]? {
		return _relativestart.map { Array(components.suffix(from: $0)) }
	}

	public var baseComponents: [String]? {
		return _relativestart.map { Array(components.prefix(upTo: $0)) }
	}
}


public func ==<P:Path>(left: P, right: P) -> Bool where P:Equatable {
	return left == right
}

extension FilePath: Equatable {
	public static func ==(left: FilePath, right: FilePath) -> Bool {
		if let l = left.relativeComponents, let r = right.relativeComponents {
			return l == r
		} else {
			return left.components == right.components
		}
	}
}

extension DirectoryPath: Equatable {
	public static func ==(left: DirectoryPath, right: DirectoryPath) -> Bool {
		if let l = left.relativeComponents, let r = right.relativeComponents {
			return l == r
		} else {
			return left.components == right.components
		}
	}
}

extension FilePath: ExpressibleByStringLiteral {
	public init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
	public init(stringLiteral value: String) {
		self.init(value)
	}
	public init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension DirectoryPath: ExpressibleByStringLiteral {
	public init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
	public init(stringLiteral value: String) {
		self.init(value)
	}
	public init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}


extension DirectoryPath {

	public static var current: DirectoryPath {
		return DirectoryPath(Files.currentDirectoryPath)
	}

	public static var home: DirectoryPath {
		return DirectoryPath(NSHomeDirectoryForUser(NSUserName())!)
	}

	public static var root: DirectoryPath {
		return DirectoryPath(pathseparator)
	}

	public static func +(dir: DirectoryPath, file: FilePath) -> FilePath {
		return FilePath(base: dir.components, relative: file.relativeComponents ?? file.components)
	}

	public static func +(leftdir: DirectoryPath, rightdir: DirectoryPath) -> DirectoryPath {
		return DirectoryPath(base: leftdir.components, relative: rightdir.relativeComponents ?? rightdir.components)
	}

	public static func +(dir: DirectoryPath, file: String) -> FilePath {
		let file = FilePath(file)
		return FilePath(base: dir.components, relative: file.relativeComponents ?? file.components)
	}

	public static func +(leftdir: DirectoryPath, rightdir: String) -> DirectoryPath {
		let rightdir = DirectoryPath(rightdir)
		return DirectoryPath(base: leftdir.components, relative: rightdir.relativeComponents ?? rightdir.components)
	}
}
