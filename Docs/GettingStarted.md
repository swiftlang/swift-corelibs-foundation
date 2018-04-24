# Getting Started

## On macOS

Although macOS is not a deployment platform for Swift Foundation, it is useful for development and test purposes.

In order to build on macOS, you will need:

* The latest version of Xcode
* The latest version of the macOS SDK (at this time: 10.13.2)
* The [current Swift toolchain](https://swift.org/download/#snapshots).

Foundation is developed at the same time as the rest of Swift, so the most recent version of the compiler is required in order to build it.

The repository includes an Xcode project file as well as an Xcode workspace. The workspace includes both Foundation and XCTest, which makes it easy to build and run everything together. The workspace assumes that Foundation and XCTest are checked out from GitHub in sibling directories. For example:

```
% cd Development
% ls
swift-corelibs-foundation swift-corelibs-xctest
%
```

Build and test steps:

0. Run Xcode with the latest toolchain. Follow [the instructions here](https://swift.org/download/#apple-platforms) to start Xcode with the correct toolchain.
0. Open `Foundation.xcworkspace`.
0. Build the _SwiftFoundation_ target. This builds CoreFoundation and Foundation.
0. Run (Cmd-R) the _TestFoundation_ target. This builds CoreFoundation, Foundation, XCTest, and TestFoundation, then runs the tests.

> Note: If you see the name of the XCTest project file in red in the workspace, then Xcode cannot find the cloned XCTest repository. Make sure that it is located next to the `swift-corelibs-foundation` directory and has the name `swift-corelibs-xctest`.

## On Linux

You will need:

* A supported distribution of Linux. At this time, we support [Ubuntu 14.04, Ubuntu 16.04 and Ubuntu 16.10](http://www.ubuntu.com).

To get started, follow the instructions on how to [build Swift](https://github.com/apple/swift#building-swift). Foundation is developed at the same time as the rest of Swift, so the most recent version of the `clang` and `swift` compilers are required in order to build it. The easiest way to make sure you have all of the correct dependencies is to build everything together.

The default build script does not include Foundation. To build Foundation and XCTest as well, pass `--xctest --foundation` to the build script.

```
swift/utils/build-script --xctest --foundation -t
```

This will build and run the Foundation tests, in the Debug configuration.

After the complete Swift build has finished, you can iterate quickly on Foundation itself by simply invoking `ninja` in the Foundation directory.

```
cd swift-corelibs-foundation
ninja
```

This will build Foundation. To build and run the tests, use the `test` target:

```
ninja test
```

The ninja build script will print the correct command-line invocation for both running the tests and debugging the tests. The exact library path to use will depend on how Foundation itself was configured by the earlier `build-script`. For example:

```
% ninja test
[5/5] Building Tests
**** RUNNING TESTS ****
execute:
LD_LIBRARY_PATH=../build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation/:/home/user/Development/build/Ninja-ReleaseAssert/xctest-linux-x86_64 ../build/Ninja-ReleaseAssert/foundation-linux-x86_64/TestFoundation/TestFoundation
**** DEBUGGING TESTS ****
execute:
LD_LIBRARY_PATH=../build/Ninja-ReleaseAssert/foundation-linux-x86_64/Foundation/:/home/user/Development/build/Ninja-ReleaseAssert/xctest-linux-x86_64 lldb ../build/Ninja-ReleaseAssert/foundation-linux-x86_64/TestFoundation/TestFoundation
%
```

Just copy & paste the correct line.

When new source files or flags are added to the `build.py` script, the project will need to be reconfigured in order for the build system to pick them up. The top-level `swift/utils/build-script` can be used, but for quicker iteration you can use the following command to limit the reconfiguration to just the Foundation project:

```
% ninja reconfigure
% ninja
```
