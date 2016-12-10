
import Foundation

let Files = FileManager()
let pathseparator = "/"
let homedir = NSHomeDirectoryForUser(NSUserName())!
let homedircomponents = homedir.components(separatedBy: pathseparator)

/// The location of an item _which may not exist_ in the local file system.
/// It is either a DirectoryPath or a FilePath.
public protocol Path: CustomStringConvertible {

	/// The individual parts of the absolute version of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	var components: [String] { get }
	var relativeComponents: [String]? { get }
	var baseComponents: [String]? { get }
	init(absolute components: [String])
	init(base: [String], relative: [String])
	init(_ stringpath: String)
}

// MARK: Structs.

/// The path to either a directory or the symbolic link to a directory.
public struct DirectoryPath: Path {
	private let _components: [String]
	private let _relativestart: Array<String>.Index?

	public init(absolute components: [String]) {
		self._components = components
		_relativestart = nil
	}

	public init(base: [String], relative: [String]) {
		_components = base + relative
		_relativestart = base.endIndex
	}

	public var relativeComponents: [String]? {
		return _relativestart.map { Array(_components.suffix(from: $0)) }
	}

	public var baseComponents: [String]? {
		return _relativestart.map { Array(_components.prefix(upTo: $0)) }
	}

	public var components: [String] {
		if let rel = _relativestart, rel != _components.endIndex, _components[rel] == ".." {
			return fixDotDots(_components)
		} else {
			return _components
		}
	}
}

/// The path to a file system item which is not a directory or the symbolic link to a directory.
public struct FilePath: Path {
	private let _components: [String]
	private let _relativestart: Array<String>.Index?

	public init(absolute components: [String]) {
		self._components = components
		_relativestart = nil
	}

	public init(base: [String], relative: [String]) {
		_components = base + relative
		_relativestart = base.endIndex
	}

	public var relativeComponents: [String]? {
		return _relativestart.map { Array(_components.suffix(from: $0)) }
	}

	public var baseComponents: [String]? {
		return _relativestart.map { Array(_components.prefix(upTo: $0)) }
	}

	public var components: [String] {
		if let rel = _relativestart, rel != _components.endIndex, _components[rel] == ".." {
			return fixDotDots(_components)
		} else {
			return _components
		}
	}
}

// MARK: Initialise from String.

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

func parseComponents(_ stringpath: String) -> (components: [String], isRelative: Bool) {
	func prepareComponents<C: Collection>(_ components: C) -> [String]
		where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
			return fixDotDots(components.filter { $0 != "" && $0 != "." })
	}

	let stringpath = stringpath.isEmpty ? "." : stringpath
	let components = stringpath.components(separatedBy: pathseparator)
	if components.first == "" {
		return (prepareComponents(components), false)
	} else if components.first == "~" {
		return (homedircomponents + prepareComponents(components.dropFirst()), false)
	} else {
		return (prepareComponents(components), true)
	}
}

extension Path {
	public init(_ stringpath: String, relativeTo base: String) {
		let rel = Self(stringpath)
		let base = DirectoryPath(base)
		self.init(base: base.components, relative: rel.relativeComponents ?? rel.components)
	}

	public init(_ stringpath: String) {
		let (components, isrelative) = parseComponents(stringpath)
		if isrelative {
			let current = Files.currentDirectoryPath.components(separatedBy: pathseparator).dropFirst().array
			self.init(base: current, relative: components)
		} else {
			self.init(absolute: components)
		}

		if self is FilePath {
			precondition(!stringpath.hasSuffix(pathseparator),
				"Trying to create a FilePath with a directory path (ending in '\(pathseparator)'). Use DirectoryPath instead.")
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

/// Tries to create a new Path by detecting if it is a directory or a file.
///
/// If the path ends in a '/', it is a directory.
/// If the path exists, check in the file system.
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

// MARK: Common methods.

extension Path {

	internal var isDirectory: Bool {
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
		let result = relativeComponents?.joined(separator: pathseparator)
		return result?.isEmpty == true ? "." : result
	}

	public func exists() -> Bool {
		return Files.fileExists(atPath: string)
	}

	public var name: String {
		return components.last ?? "/"
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
		return Self(absolute: components)
	}

	/// Go up `nr` directories.
	/// - parameter nr: How many directories to go up the file tree. Defaults to 1.
	public func parent(nr levels: Int = 1) -> DirectoryPath {
		precondition(levels > 0, "Cannot go up less than one level of parent directories")
		if let relative = relativeComponents, levels < relative.count, relative[relative.count - levels] != ".." {
			return DirectoryPath(base: baseComponents!, relative: Array(relative.dropLast(levels)))
		} else {
			return DirectoryPath(absolute: Array(self.components.dropLast(levels)))
		}
	}

	public var symbolicLinkPointsTo: Self? {
		return (try? Files.destinationOfSymbolicLink(atPath: absolute.string)).map { Self.init("/"+$0) }
	}

	public var hashValue: Int {
		return string.hashValue
	}
}

// MARK: DirectoryPath methods.

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

	internal func appendComponents<P: Path>(_ newcomponents: [String]) -> P {
		if let relativeComponents = self.relativeComponents {
			return P(base: self.baseComponents!, relative: fixDotDots(relativeComponents + newcomponents))
		} else {
			return P(absolute: fixDotDots(self.components + newcomponents))
		}
	}

	public func append(file stringpath: String) -> FilePath {
		let (newcomponents, _) = parseComponents(stringpath)
		return appendComponents(newcomponents)
	}

	public func append(directory stringpath: String) -> DirectoryPath {
		let (newcomponents, _) = parseComponents(stringpath)
		return appendComponents(newcomponents)
	}

	public static func +<P: Path>(leftdir: DirectoryPath, rightpath: P) -> P {
		let rightcomponents = rightpath.relativeComponents ?? rightpath.components
		return leftdir.appendComponents(rightcomponents)
	}

	public static func +(dir: DirectoryPath, file: String) -> FilePath {
		return dir.append(file: file)
	}

	public static func +(leftdir: DirectoryPath, rightdir: String) -> DirectoryPath {
		return leftdir.append(directory: rightdir)
	}

	/// Checks if the absolute version of the provided path begins with the absolute version of this path.
	func isAParentOf<P: Path>(_ path: P) -> Bool {
		return path.absolute.components.starts(with: self.absolute.components)
	}
}

// MARK: Equatable

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

// MARK: URL

extension Path {
	public var relativeURL: URL? {
		return relativeString.map { URL(fileURLWithPath: $0, isDirectory: isDirectory) }
	}

	public var url: URL {
		return URL(fileURLWithPath: absolute.string, isDirectory: isDirectory)
	}
}

extension DirectoryPath {
	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL and has a directory path. Otherwise nil.
	public init?(_ url: URL) {
		if #available(OSX 10.11, *) {
			guard url.isFileURL && url.hasDirectoryPath else { return nil }
		} else {
			guard url.isFileURL else { return nil }
		}
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}

extension FilePath {
	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL and does not have a directory path. Otherwise nil.
	public init?(_ url: URL) {
		if #available(OSX 10.11, *) {
			guard url.isFileURL && !url.hasDirectoryPath else { return nil }
		} else {
			guard url.isFileURL else { return nil }
		}
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}
