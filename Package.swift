import PackageDescription

let package = Package(
    name: "FileSmith"
)

package.dependencies.append(.Package(url: "https://github.com/kareman/SwiftShell.git", majorVersion: 3))
