[![Build Status](https://travis-ci.org/kareman/FileSmith.svg?branch=master)](https://travis-ci.org/kareman/FileSmith) ![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20WatchOS%20%7C%20Linux-lightgrey.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# FileSmith

A strongly typed Swift library for working with local files and directories.

Still a work in progress and has not been properly tested, so use at your own risk. This readme is also clearly far from finished.

[API documentation](https://kareman.github.io/FileSmith/)

## Safety first

Handling files in code can feel a bit risky sometimes (especially when you're using a brand-new library) so FileSmith has a built in safety feature: when `Directory.sandbox == true` (and it is by default) you can only change files or create new files and directories if they are under the current working directory. Trying to make changes elsewhere throws an error.

## Terms

**Path:**
The location of an item _which may or may not exist_ in the local file system. It is either a [DirectoryPath](https://kareman.github.io/FileSmith/Structs/DirectoryPath.html), [FilePath](https://kareman.github.io/FileSmith/Structs/FilePath.html) or [AnyPath](https://kareman.github.io/FileSmith/Structs/AnyPath.html).

**File:**
An existing regular file or something _file-like_ which you can read from and/or write to, like streams, pipes or sockets. Or symbolic links to any of these.

**Directory:**
An existing directory or a symbolic link to a directory. Basically anything you can `cd` into in the terminal.

## Usage

#### Create

```swift
let dirpath = DirectoryPath("dir/dir1")
let dir1 = try dirpath.create(ifExists: .replace)
let dir2 = try Directory(create: "dir/dir2", ifExists: .throwError)
let dir3 = try dir2.create(directory: "dir3", ifExists: .open) // dir/dir2/dir3
let dir1_link = try Directory(createSymbolicLink: "dir1_link", to: dir1, ifExists: .open)
let dir2_link = try dir1.create(symbolicLink: "dir2_link", to: dir2, ifExists: .open)

let filepath = FilePath("dir/file1.txt")
let file1 = try filepath.create(ifExists: .open)
let file2 = try EditableFile(create: "file2.txt", ifExists: .open)
let file3 = try dir1.create(file: "file3.txt", ifExists: .open) // dir/dir1/file3
let file1_link = try File(createSymbolicLink: "file1_link", to: file1, ifExists: .open)
let file2_link = try dir2.create(symbolicLink: "file2_link", to: file2, ifExists: .open)
```

#### Miscellaneous niceties

```swift
// change to a new temporary directory
Directory.current = Directory.createTempDirectory()

```



## License

Released under the MIT License (MIT), http://opensource.org/licenses/MIT

Kåre Morstøl, [NotTooBad Software](http://nottoobadsoftware.com)

