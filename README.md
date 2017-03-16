[Run shell commands](https://github.com/kareman/SwiftShell) | [Parse command line arguments](https://github.com/kareman/Moderator) | Handle files and directories

---

[![Build Status](https://travis-ci.org/kareman/FileSmith.svg?branch=master)](https://travis-ci.org/kareman/FileSmith) ![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20WatchOS%20%7C%20Linux-lightgrey.svg)

# FileSmith

A strongly typed Swift library for working with local files and directories.

It differentiates between file paths and directory paths, and between paths and actual files and directories, because the programmer knows which are which and when the compiler knows it too it can be much more helpful. 

See also:

- [API documentation](https://kareman.github.io/FileSmith/)
- [Why FileSmith was created](http://blog.nottoobadsoftware.com/swift/filesmith-type-safe-file-handling-in-swift)

## Features

- [x] Separate types for file paths, directory paths, reading files, writing files, and directories.
- [x] Use Swifts native error handling.
- [x] List the contents of directories (recursively if needed).
- [x] Filter with glob wildcard patterns.
- [x] Sandbox mode prohibits changes outside of the current working directory.
- [x] Write text to files the same way you use Swift's `print` function.

## Terms

**Path:**  
The location of an item _which may or may not exist_ in the local file system. It is either a [DirectoryPath](https://kareman.github.io/FileSmith/Structs/DirectoryPath.html), [FilePath](https://kareman.github.io/FileSmith/Structs/FilePath.html) or [AnyPath](https://kareman.github.io/FileSmith/Structs/AnyPath.html).

**File:**  
An existing regular file or something _file-like_ which you can read from and/or write to, like streams, pipes or sockets. Or symbolic links to any of these.

**Directory:**  
An existing directory or a symbolic link to a directory. Basically anything you can `cd` into in the terminal.

**Item:**  
(for lack of a better term)  
A file or a directory. Anything with a path in the file system.

## Safety first

When `Directory.sandbox == true` (and it is by default) you can only change files or create new files and directories if they are under the current working directory. Trying to make changes elsewhere throws an error.

## Usage

#### Change current working directory

```swift
DirectoryPath.current = "/tmp"
Directory.current = Directory.createTempDirectory()
```

#### [Paths](https://kareman.github.io/FileSmith/Protocols/Path.html)

```swift
// common functionality
let dirpath = DirectoryPath("dir/dir1")
var filepath: FilePath = "file.txt"
filepath = FilePath(base: "dir", relative: "file.txt")
filepath = FilePath("dir/file.txt")

filepath.relativeString
filepath.base?.string
filepath.absoluteString
filepath.string // relativeString ?? absoluteString
filepath.name
filepath.nameWithoutExtension
filepath.extension

// DirectoryPath only
dirpath.append(file: "file.txt")  // FilePath("dir/dir1/file.txt")
dirpath.append(directory: "dir2") // DirectoryPath("dir/dir1/dir2")
dirpath.isAParentOf(filepath)
```

#### Create

```swift
var dir1 = try dirpath.create(ifExists: .replace)
var dir2 = try Directory(create: "dir/dir2", ifExists: .throwError)
var dir3 = try dir2.create(directory: "dir3", ifExists: .open) // dir/dir2/dir3

var file1_edit = try filepath.create(ifExists: .open)
let file2_edit = try WritableFile(create: "file2.txt", ifExists: .open)
let file3_edit = try dir1.create(file: "file3.txt", ifExists: .open) // dir/dir1/file3
```

#### Open

```swift
dir1 = try dirpath.open()
dir2 = try Directory(open: "dir/dir2")
dir3 = try dir2.open(directory: "dir3")

let file1 = try filepath.open()
let file2 = try ReadableFile(open: "file2.txt")
let file3 = try dir1.open(file: "file3.txt")
```

#### Read/Write

```swift
file1_edit.encoding = .utf16 // .utf8 by default
file1_edit.write("some text...")
file1_edit.print("Just like Swift's own 'print' function.")
file1_edit.print(2, "words", separator: "-", terminator: "")
file2.write(to: &file1_edit)

let contents: String = file3.read()
for line in file3.lines() { // a lazy sequence
	// ...
}
while let text = file3.readSome() {
	// read pipes etc. piece by piece, instead of waiting until they are closed.
}
```

#### Search/Filter

```swift
Directory.current.files(recursive: true)       // [file2.txt, dir/file1.txt, dir/dir1/file3.txt]
dir1.files("*3.*", recursive: true)            // [file3.txt]
Directory.current.directories(recursive: true) // [dir, dir/dir1, dir/dir2, dir/dir2/dir3]
```

#### Symbolic links

```swift
let dir1_link = try Directory(createSymbolicLink: "dir1_link", to: dir1, ifExists: .open)
let dir2_link = try dir1.create(symbolicLink: "dir2_link", to: dir2, ifExists: .open)
let file1_link = try ReadableFile(createSymbolicLink: "file1_link", to: file1, ifExists: .open)
let file2_link = try dir2.create(symbolicLink: "file2_link", to: file2, ifExists: .open) as ReadableFile
```

#### Misc

```swift
// the path of a file or directory
file1.path // FilePath
dir1.path  // DirectoryPath

// remove files and directories
try file1_edit.delete()
try dir1.delete()
```

## Types

When opening files symbolic links are always followed, so the type of a file is never .symbolicLink, but can be .brokenSymbolicLink for symbolic links whose targets do not exist.

```swift
FileType("file.txt")
FileType(filepath)

public enum FileType: Equatable, Hashable {
	case regularFile
	case directory
	case characterSpecial
	case blockSpecial
	case socket
	case brokenSymbolicLink
	case namedPipe
	case unknown
}
```

## Installation

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

Add `.Package(url: "https://github.com/kareman/FileSmith", "0.1.0")` to your Package.swift:

```swift
import PackageDescription

let package = Package(
	name: "somename",
	dependencies: [
		.Package(url: "https://github.com/kareman/FileSmith", "0.1.0")
		 ]
	)
```

and run `swift build`.

### [CocoaPods](https://cocoapods.org/)

Add `FileSmith` to your `Podfile`.

```Ruby
pod "FileSmith", git: "https://github.com/kareman/FileSmith.git"
```

Then run `pod install` to install it.

## License

Released under the MIT License (MIT), http://opensource.org/licenses/MIT

Kåre Morstøl, [NotTooBad Software](http://nottoobadsoftware.com)

