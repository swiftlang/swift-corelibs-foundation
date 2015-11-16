# Getting Started

## On OS X

Although OS X is not a deployment platform for Swift Foundation, it is useful for development and test purposes.

In order to build on OS X, you will need:

* The latest version of Xcode
* The latest version of the OS X SDK (at this time: 10.11)

Build steps:

0. Open `Foundation.xcodeproj`
0. Build the _Foundation_ target

Testing steps:

0. Create a new Xcode workspace that includes both `Foundation.xcodeproj` and `XCTest.xcodeproj` (from the swift-corelibs-xctest repository). The Swift Core Libraries XCTest project is not the same as the one that comes with Xcode itself.
0. Run (Cmd-R) the _TestFoundation_ target

## On Linux

You will need:

* A supported distribution of Linux. At this time, we only support [Ubuntu 15.10](http://www.ubuntu.com).
* A recent version of the clang compiler and swiftc compiler. _**TODO**_: Instructions on how to get this from github.
* Some additional tools and libraries:
 * `sudo apt-get install ninja`
 * `sudo apt-get install libicu-dev`
 * `sudo apt-get install icu-devtools`

Build steps:

0. `cd Foundation`
0. `./configure debug` - This runs a python configuration script, and produces `build.ninja` for building a debug version of Foundation.
0. `ninja` - This builds Foundation

Testing steps:

0. `ninja TestFoundation` - This builds the TestFoundation executable.
0. `LD_LIBRARY_PATH=Build/Foundation ./Build/TestFoundation/TestFoundation` - Run the new TestFoundation executable against the Foundation you just built.
