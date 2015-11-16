# Foundation

The Foundation framework defines a base layer of functionality that is required for almost all applications. It provides primitive classes and introduces several paradigms that define functionality not provided by either the Objective-C runtime and language or Swift standard library and language.

It is designed with these goals in mind:
* Provide a small set of basic utility classes.
* Make software development easier by introducing consistent conventions.
* Support internationalization and localization, to make software accessible to users around the world.
* Provide a level of OS independence, to enhance portability.

There is more information on the Foundation framework [here](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/ObjC_classic/).

> Important: This project is in the early stages of development. It is not yet ready for production use, but it is ready for contributions. It is scheduled to be part of the Swift 3 release.

This project provides an implementation of the Foundation API for platforms where there is no Objective-C runtime. On OS X, iOS, and other Apple platforms, apps should use the Foundation that comes with the operating system. Our goal is to abstract away the exact underlying platform as much as possible.

## Using Foundation

Here is a simple `main.swift` file which uses Foundation. This guide assumes you have already installed a version of the latest [Swift binary distribution](https://oss.apple.com/downloads#latest).

```
import Foundation

// Make an URLComponents instance
let swifty = NSURLComponents(string: "http://swift.org")!

// Print something useful about the URL
print("\(swifty.host!)")

// Output: "swift.org"
```

## Working on Foundation

Please see [Getting Started](Docs/GettingStarted.md).
