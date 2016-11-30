
import Foundation

let Files = FileManager()

public protocol Path: CustomStringConvertible {
	var components: [String] { get }
	var _relativestart: Array<String>.Index? { get }
	static var separator: String { get }
	static var home: DirectoryPath { get }
}

extension Path {
	public static var separator: String { return "/" }

	public static var current: DirectoryPath {
		return DirectoryPath(Files.currentDirectoryPath)
	}

	public static var home: DirectoryPath {
		return DirectoryPath(NSHomeDirectoryForUser(NSUserName())!)
	}

	public static var root: DirectoryPath {
		return DirectoryPath(DirectoryPath.separator)
	}

	public var isDirectory: Bool {
		return self is DirectoryPath
	}

	public var string: String {
		return relativeString ?? (DirectoryPath.separator + components.joined(separator: DirectoryPath.separator))
	}

	public var description: String {
		return string
	}

	public var base: DirectoryPath? {
		return _relativestart.map { DirectoryPath(absolute: Array(self.components.prefix(upTo: $0))) }
	}

	public var relativeString: String? {
		return _relativestart.map {
			components[$0..<components.endIndex].joined(separator: DirectoryPath.separator)
		}
	}

	public var relativeURL: URL? {
		return relativeString.map { URL(fileURLWithPath: $0, isDirectory: isDirectory) }
	}

	var relativeComponents: [String]? {
		return _relativestart.map { Array(components.suffix(from: $0)) }
	}

	var baseComponents: [String]? {
		return _relativestart.map { Array(components.prefix(upTo: $0)) }
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
}

func initPath <C: Collection>(_ c: C) -> ([String], Array<String>.Index?)
	where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {

	let components: [String]
	let relativestart: Array<String>.Index?
	if c.first == "~" {
		components = DirectoryPath.home.components + c.dropFirst()
		relativestart = nil
	} else if c.first != "/" { // relative path
		let base = DirectoryPath.current.components
		components = base + c
		relativestart = base.count
	} else {
		components = Array(c.dropFirst())
		relativestart = nil
	}
	return (components, relativestart)
}

func initPath(_ string: String) -> ([String], Array<String>.Index?) {
	var components = string.components(separatedBy: FilePath.separator)
	if components.first == "" {
		components[0] = "/"
	}
	if components.last == "" {
		components.removeLast()
	}
	return initPath(components)
}


public struct DirectoryPath: Path {
	public let components: [String]
	public let _relativestart: Array<String>.Index?

	init(absolute components: [String]) {
		self.components = components
		_relativestart = nil
	}

	init(base: [String], relative: [String]) {
		components = base + relative
		_relativestart = base.endIndex
	}

	public init <C: Collection>(_ c: C)
		where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
		(components, _relativestart) = initPath(c)
	}

	public init(_ string: String) {
		(components, _relativestart) = initPath(string)
	}

	public init(_ url: URL) {
		precondition(url.isFileURL && url.hasDirectoryPath, "The provided URL does not point to a directory.")
		components = (url.baseURL?.pathComponents ?? []) + url.pathComponents
		_relativestart = components.index(components.startIndex, offsetBy: url.baseURL?.pathComponents.count ?? 0 )
	}
}

public struct FilePath: Path {
	public let components: [String]
	public let _relativestart: Array<String>.Index?

	init(absolute components: [String]) {
		self.components = components
		_relativestart = nil
	}

	init(base: [String], relative: [String]) {
		components = base + relative
		_relativestart = base.endIndex
	}
	
	public init <C: Collection>(_ c: C)
		where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
		precondition(c.count > 0)
		(components, _relativestart) = initPath(c)
		precondition(components.last != "/", "A file path cannot end in a /. Use DirectoryPath for directories.")
	}

	public init(_ string: String) {
		precondition(string.characters.last != "/", "A file path cannot end in a /. Use DirectoryPath for directories.")
		(components, _relativestart) = initPath(string)
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


extension String {

	// This is never called by Swift, 'func +(leftdir: DirectoryPath, rightdir: DirectoryPath)' is called instead.
	public static func +(dir: DirectoryPath, file: String) -> DirectoryPath {
		fatalError("String literals used with the + operator after a DirectoryPath are always interpreted by Swift as a DirectoryPath, and never a FilePath. Use DirectoryPath/FilePath initialisers directly for clarity.")
	}
}

extension DirectoryPath {

	public static func +(dir: DirectoryPath, file: FilePath) -> FilePath {
		// FIXME: Make result relative, just swap out the base of the right side.
		return FilePath(base: dir.components, relative: file.relativeComponents ?? file.components)
	}

	public static func +(leftdir: DirectoryPath, rightdir: DirectoryPath) -> DirectoryPath {
		// FIXME: Make result relative, just swap out the base of the right side.
		return DirectoryPath(base: leftdir.components, relative: rightdir.relativeComponents ?? rightdir.components)

			//DirectoryPath([DirectoryPath.separator] + leftdir.components
		//+ rightdir.components.suffix(from: rightdir._relativestart ?? rightdir.components.startIndex))
	}

	public func exists(filepath: FilePath) -> Bool {
		return Files.fileExists(atPath: (self + filepath).string)
	}

	public func exists(filepath: String) -> Bool {
		return Files.fileExists(atPath: (self + FilePath(string)).string)
	}

	public var absolute: DirectoryPath {
		return DirectoryPath(absolute: components)
	}
}

extension FilePath {
	public var absolute: FilePath {
		return FilePath(absolute: components)
	}
}
