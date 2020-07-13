// swift-tools-version:5.0

import PackageDescription

let package = Package(
	name: "FileSmith",
	products: [
		.library(name: "FileSmith", targets: ["FileSmith"])
	],
	dependencies: [
		.package(url: "https://github.com/kareman/SwiftShell.git", .exact("5.0.1"))
	],
	targets: [
		.target(
			name: "FileSmith",
			dependencies: ["SwiftShell"]),
		.testTarget(
			name: "FileSmithTests",
			dependencies: ["FileSmith"]),
	]
)
