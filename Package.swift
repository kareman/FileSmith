import PackageDescription

let package = Package(
    name: "SwiftyPath"
)

package.dependencies.append(.Package(url: "https://github.com/Bouke/Glob.git", majorVersion: 1))
