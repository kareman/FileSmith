import PackageDescription

let package = Package(
    name: "FileSmith"
)

package.dependencies.append(.Package(url: "https://github.com/kareman/SwiftShell", "3.0.0-beta.14"))
