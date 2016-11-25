
import Foundation

let Files = FileManager.default

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
		return DirectoryPath.separator + components.joined(separator: DirectoryPath.separator)
	}

	public var description: String {
		return string
	}

	public var baseString: String? {
		return _relativestart.map { DirectoryPath.separator +
			components[components.startIndex..<$0].joined(separator: DirectoryPath.separator)
		}
	}

	public var baseURL: URL? {
		return baseString.map { URL(fileURLWithPath: $0, isDirectory: true) }
	}

	public var relativeString: String? {
		return _relativestart.map {
			components[$0..<components.endIndex].joined(separator: DirectoryPath.separator)
		}
	}

	public var relativeURL: URL? {
		return relativeString.map { URL(fileURLWithPath: $0, isDirectory: isDirectory) }
	}

	public var url: URL {
		return URL(fileURLWithPath: relativeString ?? string, isDirectory: isDirectory, relativeTo: baseURL)
	}

	func exists() -> Bool {
		return Files.fileExists(atPath: string)
	}
}

func initPath <C: Collection>(_ c: C) -> ([String], Array<String>.Index?)
	where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {

	let components: [String]
	let relativestart: Array<String>.Index?
	if c.first == "~" {
		components = DirectoryPath.home.components + c.dropFirst()
		relativestart = DirectoryPath.home.components.count
	} else if c.first != "/" { // relative path
		components = DirectoryPath.current.components + c
		relativestart = DirectoryPath.current.components.count
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
	return initPath(components)
}


public struct DirectoryPath: Path {
	public let components: [String]
	public let _relativestart: Array<String>.Index?

	public init <C: Collection>(_ c: C)
		where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
		(components, _relativestart) = initPath(c)
	}

	public init(_ string: String) {
		(components, _relativestart) = initPath(string)
	}
}

public struct FilePath: Path {
	public let components: [String]
	public let _relativestart: Array<String>.Index?

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

extension DirectoryPath {
	public static func +(dir: DirectoryPath, file: FilePath) -> FilePath {
		return FilePath([DirectoryPath.separator] + dir.components
			+ file.components.suffix(from: file._relativestart ?? file.components.startIndex))
	}

	public static func +(leftdir: DirectoryPath, rightdir: DirectoryPath) -> DirectoryPath {
		return DirectoryPath([DirectoryPath.separator] + leftdir.components
			+ rightdir.components.suffix(from: rightdir._relativestart ?? rightdir.components.startIndex))
	}

	public func exists(filepath: FilePath) -> Bool {
		return Files.fileExists(atPath: (self + filepath).string)
	}

	public func exists(filepath: String) -> Bool {
		return Files.fileExists(atPath: (self + FilePath(string)).string)
	}
}
