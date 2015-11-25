# Getting Started

## On OS X

Although OS X is not a deployment platform for Swift Foundation, it is useful for development and test purposes. The repository includes an Xcode project file as well as an Xcode workspace. The workspace includes both Foundation and XCTest, which makes it easy to build and run everything together.

In order to build on OS X, you will need:

* The latest version of Xcode
* The latest version of the OS X SDK (at this time: 10.11)

The Xcode workspace assumes that Foundation and XCTest are checked out from GitHub in peer directories, and with those exact names.

Build steps:

0. Open `Foundation.xcworkspace`.
0. Build the _Foundation_ target. This builds CoreFoundation and Foundation.

Testing steps:

0. Open `Foundation.xcworkspace`.
0. Run (Cmd-R) the _TestFoundation_ target. This builds CoreFoundation, Foundation, XCTest, and TestFoundation.

## On Linux

You will need:

* A supported distribution of Linux. At this time, we support [Ubuntu 14.04 and Ubuntu 15.10](http://www.ubuntu.com).

To get started, follow the instructions on how to [build Swift](https://github.com/apple/swift#building-swift). Foundation requires use of the version of `swiftc` and `clang` built with the overall project.

The default build script does not include Foundation. To build Foundation as well, pass `--foundation` to the build script.

```
swift/utils/build-script --foundation -t
```

This will build and run the Foundation tests.

After the complete Swift build has finished, you can iterate quickly on Foundation itself by simply invoking `ninja` in the Foundation directory.

```
cd Foundation
ninja
```

This will build Foundation. To build and run the tests, use the `test` target:

```
ninja test
```

The script will also output some help on how to run the tests under the debugger. The exact library path to use will depend on how Foundation itself was configured.
