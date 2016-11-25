
import Foundation

let Files = FileManager.default

public protocol Path: CustomStringConvertible {
	var components: [String] { get }
	var relativestart: Array<String>.Index? { get }
	static var separator: String { get }
}

extension Path {
	public static var separator: String { return "/" }

	static var current: DirectoryPath {
		return DirectoryPath(Files.currentDirectoryPath)
	}

	static var home: DirectoryPath {
		return DirectoryPath(NSHomeDirectoryForUser(NSUserName())!)
	}

	public var root: DirectoryPath {
		return DirectoryPath("/")
	}

	public var description: String {
		return DirectoryPath.separator + components.dropFirst().joined(separator: DirectoryPath.separator)
	}
}

func initPath <C: Collection>(_ c: C) -> ([String], Array<String>.Index?) where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
	let components: [String]
	let relativestart: Array<String>.Index?
	if c.first == "~" {
		components = DirectoryPath.home.components + c.dropFirst()
		relativestart = DirectoryPath.home.components.count
	} else if c.first != "/" { // relative path
		components = DirectoryPath.current.components + c
		relativestart = DirectoryPath.current.components.count
	} else {
		components = Array(c)
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
	public let relativestart: Array<String>.Index?

	public init <C: Collection>(_ c: C) where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
		(components, relativestart) = initPath(c)
	}

	public init(_ string: String) {
		(components, relativestart) = initPath(string)
	}
}

public struct FilePath: Path {
	public let components: [String]
	public let relativestart: Array<String>.Index?

	public init <C: Collection>(_ c: C) where C.Iterator.Element == String, C.SubSequence: Collection, C.SubSequence.Iterator.Element == String {
		precondition(c.count > 0)
		(components, relativestart) = initPath(c)
	}

	public init(_ string: String) {
		(components, relativestart) = initPath(string)
	}
}

extension FilePath: ExpressibleByStringLiteral {
	public init(extendedGraphemeClusterLiteral value: String) {
		self = FilePath(value)
	}
	public init(stringLiteral value: String) {
		self = FilePath(value)
	}
	public init(unicodeScalarLiteral value: String) {
		self = FilePath(value)
	}
}

extension DirectoryPath: ExpressibleByStringLiteral {
	public init(extendedGraphemeClusterLiteral value: String) {
		self = DirectoryPath(value)
	}
	public init(stringLiteral value: String) {
		self = DirectoryPath(value)
	}
	public init(unicodeScalarLiteral value: String) {
		self = DirectoryPath(value)
	}
}

extension DirectoryPath {
	public static func +(dir: DirectoryPath, file: FilePath) -> FilePath {
		return FilePath(dir.components + file.components.suffix(from: file.relativestart ?? file.components.startIndex))
	}

	public static func +(dir: DirectoryPath, file: DirectoryPath) -> DirectoryPath {
		return DirectoryPath(dir.components + file.components.suffix(from: file.relativestart ?? file.components.startIndex))
	}
}
