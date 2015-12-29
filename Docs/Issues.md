# Known Issues

* We're not yet finished implementing all of the core functionality of Foundation.

* NSDictionary, NSArray, NSSet and NSString are not yet implicitly convertible to Dictionary, Array, Set, and String. In order to translate between these types, we have temporarily added a protocol to these types that allows them to be converted. There is one method called `bridge()`.

```swift
let myArray: NSArray = ["foo", "bar", "baz"].bridge()
```

This also means that functions like map or reduce are currently unavailable on NSDictionary and NSArray.

These limitations should hopefully be very short-term.

A fix in the compiler is needed to split out the concept of "bridgeable to Objective-C" from "bridgeable to AnyObject". In the meantime, we have added the implementation of the `_ObjectiveCBridgeable` protocol to Foundation on Linux (normally it is part of the standard library).

In short: users or implementers should be careful about the implicit conversions that may be inserted automatically by the compiler. Be sure to compile and test changes on both Darwin and Linux.

* The `AutoreleasingUnsafeMutablePointer` type is not available on Linux because it requires autorelease logic provided by the Objective-C runtime. Most often this is not needed, but does create a divergence in some APIs like `NSFormatter` or the funnel methods of NSDictionary, NSArray and others. In these areas, we have proposed new API (marked with `Experiment:`) to work around use of the type. This proposed API is subject to change as the project progresses and should not yet be considered stable.

* `swiftc` does not order include paths. This means that build artifact `module.modulemap` and the installed `module.modulemap` will conflict with each other. To work around the issue while developing Foundation, remove `/usr/local/include/CoreFoundation/module.modulemap` before building.

* The python & ninja build system in place is a medium-term solution. We believe a long-term building solution will come from the Swift Package Manager. However, it can not yet build dynamic libraries nor build mixed-source (C and Swift) projects.

* Data pointers that are normally autoreleased such as fileSystemRepresentationWithPath or UTF8String will leak when the data is not returned from an inner value.
