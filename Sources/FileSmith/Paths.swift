//
//  Paths.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 29/11/2016.
//

import Foundation

public let pathseparator = "/"
let homedir = NSHomeDirectoryForUser(NSUserName())!
let homedircomponents = homedir.components(separatedBy: pathseparator)

/// The location of an item _which may or may not exist_ in the local file system.
/// It is either a DirectoryPath or a FilePath.
public protocol Path: CustomStringConvertible {

	/// The individual parts of the absolute version of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	var components: [String] { get }

	/// The individual parts of the relative part (if any) of this path.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do baseComponents.
	var relativeComponents: [String]? { get }

	/// The individual parts of the base part (if any) of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do relativeComponents.
	var baseComponents: [String]? { get }

	init(absolute components: [String])
	init(base: [String], relative: [String])
	init(_ stringpath: String)
	init?(_ url: URL)
}

// MARK: Structs.

/// The path to a file system item of unknown type.
public struct AnyPath: Path {
	private let _components: [String]
	private let _relativestart: Array<String>.Index?

	/// Creates an absolute path to an item from (but not including) the root folder through all the
	/// directories listed in the array.
	/// - Parameter components: The names of the directories in the path, ending with the item name. Each name must not be empty or contain only a '.', and any '..' must be at the beginning. Cannot be empty.
	public init(absolute components: [String]) {
		self._components = components
		_relativestart = nil
	}

	/// Creates a relative path to an item, from the provided base.
	/// Each name in the parameter arrays must not be empty or contain only a '.', and any '..' must be at the beginning.
	/// - Parameter base: The names of the directories in the base, in order.
	/// - Parameter relative: The names of the directories in the relative part, ending with the item name. Cannot be empty.
	public init(base: [String], relative: [String]) {
		_components = base + relative
		_relativestart = base.endIndex
	}

	/// The individual parts of the relative part (if any) of this path.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do baseComponents.
	public var relativeComponents: [String]? {
		return _relativestart.map { Array(_components.suffix(from: $0)) }
	}

	/// The individual parts of the base part (if any) of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do relativeComponents.
	public var baseComponents: [String]? {
		return _relativestart.map { Array(_components.prefix(upTo: $0)) }
	}

	/// The individual parts of the absolute version of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	public var components: [String] {
		if let rel = _relativestart, rel != _components.endIndex, _components[rel] == ".." {
			return fixDotDots(_components)
		}
		return _components
	}
}

/// The path to either a directory or the symbolic link to a directory.
public struct DirectoryPath: Path {
	private let _path: AnyPath

	/// Creates an absolute path to a directory from (but not including) the root folder through all the 
	/// directories listed in the array.
	/// - Parameter components: The names of the directories in the path, in order. Each name must not be empty or contain only a '.', and any '..' must be at the beginning.
	public init(absolute components: [String]) {
		_path = AnyPath(absolute: components)
	}

	/// Creates a relative path to a directory, from the provided base.
	/// Each name in the parameter arrays must not be empty or contain only a '.', and any '..' must be at the beginning.
	/// - Parameter base: The names of the directories in the base, in order.
	/// - Parameter relative: The names of the directories in the relative part, in order. If empty the path refers to the base directory.
	public init(base: [String], relative: [String]) {
		_path = AnyPath(base: base, relative: relative)
	}

	/// The individual parts of the relative part (if any) of this path.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do baseComponents.
	public var relativeComponents: [String]? {
		return _path.relativeComponents
	}

	/// The individual parts of the base part (if any) of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do relativeComponents.
	public var baseComponents: [String]? {
		return _path.baseComponents
	}

	/// The individual parts of the absolute version of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	public var components: [String] {
		return _path.components
	}
}

/// The path to a file system item which is not a directory or the symbolic link to a directory.
public struct FilePath: Path {
	private let _path: AnyPath

	/// Creates an absolute path to a file from (but not including) the root folder through all the 
	/// directories listed in the array.
	/// - Parameter components: The names of the directories in the path, ending with the file name. Each name must not be empty or contain only a '.', and any '..' must be at the beginning. Cannot be empty.
	public init(absolute components: [String]) {
		_path = AnyPath(absolute: components)
	}

	/// Creates a relative path to a file, from the provided base.
	/// Each name in the parameter arrays must not be empty or contain only a '.', and any '..' must be at the beginning.
	/// - Parameter base: The names of the directories in the base, in order.
	/// - Parameter relative: The names of the directories in the relative part, ending with the file name. Cannot be empty.
	public init(base: [String], relative: [String]) {
		_path = AnyPath(base: base, relative: relative)
	}

	/// The individual parts of the relative part (if any) of this path.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do baseComponents.
	public var relativeComponents: [String]? {
		return _path.relativeComponents
	}

	/// The individual parts of the base part (if any) of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	/// If this exists, then so do relativeComponents.
	public var baseComponents: [String]? {
		return _path.baseComponents
	}

	/// The individual parts of the absolute version of this path, from (but not including) the root folder.
	/// Any '..' not at the beginning have been resolved, and there are no empty parts or only '.'.
	public var components: [String] {
		return _path.components
	}
}


// MARK: Initialise from String.

/// Removes any pair of [<directory name>, '..'].
/// - Returns: an array where any '..' are only at the beginning. 
func fixDotDots(_ components: [String]) -> [String] {
	guard let firstdotdot = components.firstIndex(of: "..") else { return components }
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

/// Creates an array of path components from a string.
func parseComponents(_ stringpath: String) -> (components: [String], isRelative: Bool) {
	func prepareComponents<C: Collection>(_ components: C) -> [String]
		where C.Element == String {
			return fixDotDots(components.filter { !$0.isEmpty && $0 != "." })
	}

	let stringpath = stringpath.isEmpty ? "." : stringpath
	let components = stringpath.components(separatedBy: pathseparator)
	if components.first == "" {
		return (prepareComponents(components), false)
	} else if components.first == "~" {
		return (prepareComponents(homedircomponents + components.dropFirst()), false)
	}
	return (prepareComponents(components), true)
}

extension Path {

	/// Creates a relative path from two strings.
	///
	/// - Parameters:
	///   - base: The path to the directory this path is relative to. If it does not begin with a '/' it will be appended to the current working directory.
	///   - relative: The relative path. It doesn't matter if this begins with a '/'.
	public init(base: String, relative: String) {
		let rel = Self("/"+relative)
		let base = DirectoryPath(base)
		self.init(base: base.components, relative: rel.components)
	}

	/// Creates a path from a string. 
	/// If the string begins with a '/' it is absolute, otherwise it is relative to the current working directory.
	public init(_ stringpath: String) {
		let (components, isrelative) = parseComponents(stringpath)
		if isrelative {
			let current = FileManager().currentDirectoryPath.components(separatedBy: pathseparator).dropFirst().array
			self.init(base: current, relative: components)
		} else {
			self.init(absolute: components)
		}

		if self is FilePath {
			precondition(!stringpath.hasSuffix(pathseparator),
				"Trying to create a FilePath from \(stringpath) (ending in '\(pathseparator)'). If this is a directory, use DirectoryPath instead. If it is a file, remove the trailing \(pathseparator). If it is unknown, use AnyPath")
		}
	}
}

extension AnyPath: ExpressibleByStringLiteral {
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
	guard let type = FileType(stringpath) else {
		return nil
	}
	return type == .directory ? DirectoryPath(stringpath) : FilePath(stringpath)
}

// MARK: Common methods.

extension Path {
	/// Creates a new path from another path.
	public init(_ inpath: Path) {
		if let base = inpath.baseComponents, let rel = inpath.relativeComponents {
			self.init(base: base, relative: rel)
		} else {
			self.init(absolute: inpath.components)
		}
	}

	/// The relative or absolute string representation of this path.
	public var string: String {
		return relativeString ?? absoluteString
	}

	/// The relative or absolute string representation of this path.
	public var description: String {
		return string
	}

	/// The base of this path, if it is relative. Otherwise nil.
	public var base: DirectoryPath? {
		return baseComponents.map { DirectoryPath(absolute: $0) }
	}

	/// The string representation of the relative part of this path, if any.
	public var relativeString: String? {
		let result = relativeComponents?.joined(separator: pathseparator)
		return result?.isEmpty == true ? "." : result
	}

	/// The string representation of the absolute version of this path.
	public var absoluteString: String {
		return pathseparator + components.joined(separator: pathseparator)
	}

	/// The main part of this path (the last component).
	public var name: String {
		return components.last ?? "/"
	}

	/// The extension of the name (as in "file.extension").
	public var `extension`: String? {
		guard let lastdot = name.lastIndex(of: "."),
			lastdot != name.startIndex,
			lastdot != name.index(before: name.endIndex)
			else { return nil	}
		return String(name[name.index(after: lastdot)...])
	}

	/// The name without any extension.
	public var nameWithoutExtension: String {
		if let lastdot = name.lastIndex(of: "."), lastdot != name.startIndex {
			return String(name[..<lastdot])
		}
		return name
	}

	/// If relative, joins base and relative together. Otherwise returns self.
	public var absolute: Self {
		return Self(absolute: components)
	}

	/// Go up `nr` directories.
	/// - parameter nr: How many directories to go up the file tree. Defaults to 1.
	public func parent(nr levels: Int = 1) -> DirectoryPath {
		precondition(levels > 0, "Cannot go up less than one level of parent directories")
		if let relative = relativeComponents, levels < relative.count, relative[relative.count - levels] != ".." {
			return DirectoryPath(base: baseComponents!, relative: Array(relative.dropLast(levels)))
		}
		return DirectoryPath(absolute: Array(self.components.dropLast(levels)))
	}

	/// A new path pointing to the same item as this path, and whose base path is `base`.
	///
	/// - Parameter base: The base of the new path.
	public func relativeTo(_ base: DirectoryPath) -> Self {
		let i = components.indexOfFirstDifference(base.components)
		let nrofdotdots = base.components.count - (i ?? components.count)
		return Self(base: base.components, relative: Array(repeating: "..", count: nrofdotdots) + components.suffix(from: i ?? components.endIndex))
	}

	// MARK: Accesses the filesystem.

	/// Checks if this path points to an existing item in the local filesystem.
	/// - Note: Does not check if this path points to the correct type of item (file or directory).
	///
	/// If this is a symbolic link which points to a non-existing path, then the result is false.
	public func exists() -> Bool {
		return FileManager().fileExists(atPath: absoluteString)
	}

	/// A path referring to the same item in the file system, where all symbolic links have been resolved.
	/// Components of this path which do not exist are returned unchanged.
	public func resolvingSymlinks() -> Self {
		return Self(self.url.resolvingSymlinksInPath())!
	}
}

// MARK: DirectoryPath methods.

extension DirectoryPath {

	/// The path to the current working directory.
	public static var current: DirectoryPath {
		get {
			return DirectoryPath(FileManager().currentDirectoryPath)
		}
		set {
			guard FileManager().changeCurrentDirectoryPath(newValue.absoluteString) else {
				fatalError("Could not change current directory to \(newValue.absoluteString)")
			}
		}
	}

	/// The path to the current user's home directory.
	public static var home: DirectoryPath {
		return DirectoryPath(NSHomeDirectoryForUser(NSUserName())!)
	}

	/// The path to the root directory in the local file system.
	public static var root: DirectoryPath {
		return DirectoryPath(absolute:[])
	}

	internal func append<P: Path>(_ newcomponents: [String]) -> P {
		if let relativeComponents = self.relativeComponents {
			return P(base: self.baseComponents!, relative: fixDotDots(relativeComponents + newcomponents))
		}
		return P(absolute: fixDotDots(self.components + newcomponents))
	}

	internal func append<P: Path>(_ appendix: String, relative: Bool = false) -> P {
		let (newcomponents, _) = parseComponents(appendix)
		return relative ? P(base: components, relative: newcomponents) : append(newcomponents)
	}

	/// Creates a new path by adding a file path to the end of this directory path.
	///
	/// - Parameters:
	///   - stringpath: The path to add.
	///   - relative: If true, this path will be the base, and `stringpath` will be the relative part.
	///               If false and this path is relative, the new path will be relative too. Otherwise it is absolute.
	///               The default is false.
	public func append(file stringpath: String, relative: Bool = false) -> FilePath {
		return append(stringpath, relative: relative)
	}

	/// Creates a new path by adding a directory path to the end of this directory path.
	///
	/// - Parameters:
	///   - stringpath: The path to add.
	///   - relative: If true, this path will be the base, and `stringpath` will be the relative part.
	///               If false and this path is relative, the new path will be relative too. Otherwise it is absolute.
	///               The default is false.
	public func append(directory stringpath: String, relative: Bool = false) -> DirectoryPath {
		return append(stringpath, relative: relative)
	}

	public static func + <P: Path>(leftdir: DirectoryPath, rightpath: P) -> P {
		let rightcomponents = rightpath.relativeComponents ?? rightpath.components
		return leftdir.append(rightcomponents)
	}

	/// Checks if the absolute version of the provided path begins with the absolute version of this path.
	public func isAParentOf<P: Path>(_ path: P) -> Bool {
		return path.absolute.components.starts(with: self.absolute.components) && path.components.count != self.components.count
	}
}

// MARK: Equatable

public func == <P:Path>(left: P, right: P) -> Bool where P:Equatable {
	return left == right
}

extension AnyPath: Equatable, Hashable {
	public static func == (left: AnyPath, right: AnyPath) -> Bool {
		guard (left.relativeComponents == nil) == (right.relativeComponents == nil) else {
			return false
		}
		if let leftrel = left.relativeComponents, let rightrel = right.relativeComponents {
			return (leftrel == rightrel) && (left.baseComponents! == right.baseComponents!)
		}
		return left.components == right.components
	}
}

extension FilePath: Equatable, Hashable {
	public static func ==(left: FilePath, right: FilePath) -> Bool {
		return AnyPath(left) == AnyPath(right)
	}
}

extension DirectoryPath: Equatable, Hashable {
	public static func ==(left: DirectoryPath, right: DirectoryPath) -> Bool {
		return AnyPath(left) == AnyPath(right)
	}
}

// MARK: URL

extension Path {

	/// If relative, converts this path to a Foundation.URL.
	public var relativeURL: URL? {
		return relativeString.map { URL(fileURLWithPath: $0) }
	}

	/// Converts this path to a Foundation.URL.
	public var url: URL {
		return URL(fileURLWithPath: absoluteString)
	}

	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL. Otherwise nil.
	public init?(_ url: URL) {
		guard url.isFileURL else { return nil }
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}

extension FilePath {
	/// Creates a path from a URL.
	///
	/// - returns: Path if URL is a file URL and does not have a directory path. Otherwise nil.
	public init?(_ url: URL) {
		if #available(OSX 10.11, iOS 9.0, tvOS 10.0, watchOS 3.0, *) {
			guard url.isFileURL && !url.hasDirectoryPath else { return nil }
		} else {
			guard url.isFileURL && !url.path.hasSuffix(pathseparator) else { return nil }
		}
		self.init(absolute: url.standardizedFileURL.pathComponents.dropFirst().array)
	}
}
