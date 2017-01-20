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
A regular file or something _file-like_ which you can read from and/or write to, like streams, pipes or sockets. Or symbolic links to any of these.

**Directory:**
A directory or a symbolic link to a directory. Basically anything you can `cd` into in the terminal.

## Usage

#### Directories

```swift
let dir = try Directory(open: "dir") 
let dir2 = try directorypath.open()

```

#### Miscellaneous niceties

```swift
// change to a new temporary directory
Directory.current = Directory.createTempDirectory()

```



## License

Released under the MIT License (MIT), http://opensource.org/licenses/MIT

Kåre Morstøl, [NotTooBad Software](http://nottoobadsoftware.com)

