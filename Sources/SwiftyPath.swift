
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

func fixDotDots(_ components: [String]) -> [String] {
	guard let firstdotdot = components.index(of: "..") else { return components }
	var components = components
	var i = max(1,firstdotdot)
	while i < components.endIndex {
		if i > 0 && components[i] == ".." && components[i-1] != ".." {
			components.removeSubrange((i-1)...i)
			i -= 1
		} else {
			i += 1
		}
	}
	return components
}

func prepareComponents<C: Collection>(_ components: C) -> [String]
	where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {

		return fixDotDots(components.filter { $0 != "" && $0 != "." })
}

extension Path {
	public init(_ stringpath: String, relativeTo base: String) {
		let rel = Self(stringpath)
		let base = DirectoryPath(base)
		self.init(base: base.components, relative: rel.relativeComponents ?? rel.components)
	}

	public init(_ stringpath: String) {
		precondition(stringpath != "", "The path cannot be empty.")
		let components = stringpath.components(separatedBy: pathseparator)
		if components.first == "" {
			self.init(absolute: prepareComponents(components))
		} else if components.first == "~" {
			self.init(absolute: homedircomponents + prepareComponents(components.dropFirst()))
		} else {
			let current = Array(Files.currentDirectoryPath.components(separatedBy: pathseparator).dropFirst())
			self.init(base: current, relative: prepareComponents(components))
		}
		if self is FilePath {
			precondition(!stringpath.hasSuffix(pathseparator),
				"Trying to create a FilePath with a directory path (ending in '\(pathseparator)'). Use DirectoryPath instead.")
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
		guard let lastdot = name.characters.lastIndex(of: "."),
			lastdot != name.startIndex,
			lastdot != name.index(before: name.endIndex)
			else { return nil	}
		return name.substring(from: name.index(after: lastdot))
	}

	public var nameWithoutExtension: String {
		if let lastdot = name.characters.lastIndex(of: "."), lastdot != name.startIndex {
			return name.substring(to: lastdot)
		} else {
			return name
		}
	}

	public var absolute: Self {
		return Self(absolute: relativeComponents?.first == ".." ? fixDotDots(components) : components)
	}

	/// - bug: Doesn't work with .. in the path.
	public func parent(levels: Int = 1) -> DirectoryPath {
		precondition(levels > 0, "Cannot go up less than one level of parent directories")
		if let relative = relativeComponents, levels < relative.count {
			return DirectoryPath(base: baseComponents!, relative: Array(relative.dropLast(levels)))
		} else {
			let parentcomponents = components.dropLast(levels)
			return DirectoryPath(absolute: Array(parentcomponents))
		}
	}

	public var hashValue: Int {
		return string.hashValue
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

extension FilePath: Equatable, Hashable {
	public static func ==(left: FilePath, right: FilePath) -> Bool {
		if let l = left.relativeComponents, let r = right.relativeComponents {
			return l == r
		} else {
			return left.components == right.components
		}
	}
}

extension DirectoryPath: Equatable, Hashable {
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
		get {
			return DirectoryPath(Files.currentDirectoryPath)
		}
		set {
			Files.changeCurrentDirectoryPath(newValue.absolute.string)
		}
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

	func isAParentOf(_ path: Path) -> Bool {
		return path.components.starts(with: self.components)
	}

	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL and has a directory path. Otherwise nil.
	public init?(_ url: URL) {
		guard url.isFileURL && url.hasDirectoryPath else { return nil }
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}

extension FilePath {
	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL and does not have a directory path. Otherwise nil.
	public init?(_ url: URL) {
		guard url.isFileURL && !url.hasDirectoryPath else { return nil }
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}
