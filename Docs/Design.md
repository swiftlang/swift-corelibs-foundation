
# Design Principles

## Portability

This version of Foundation is designed to support the same API as the Foundation that ships with Apple operating systems. A key difference is that the distribution of Swift open source does not include the Objective-C runtime. This means that the source code of Foundation from OS X and iOS could not be simply reused on other platforms. However, we believe that the vast majority of the core API concepts presented in Foundation are themselves portable and are useful on all platforms.

It is not a goal of this project to create new API that extends beyond the API provided on Apple operating systems, as that would hamper the goal of portability.

Some Foundation API exists on Apple platforms but is very OS-specific. In those cases, we choose to omit that API from this project. We also omit API that is either deprecated or discouraged from use.

In a very limited number of cases, key Foundation API as it exists on Apple platforms is not portable to Linux without the Objective-C runtime. One example is API which makes use of `AutoreleasingUnsafeMutablePointer`. In these cases, we have put in temporary API to replace it on Linux. All proposed API is marked with `Experiment:` in the documentation for the method. This API is subject to change before final release.

A significant portion of the implementation of Foundation on Apple platforms is provided by another framework called CoreFoundation (a.k.a. CF). CF is written primarily in C and is very portable. Therefore we have chosen to use it for the internal implementation of Swift Foundation where possible. As CF is present on all platforms, we can use it to provide a common implementation everywhere.

Another aspect of portability is keeping dependencies to an absolute minimum. With fewer dependencies to port, it is more likely that Foundation will be able to easily compile and run on new platforms. Therefore, we will prefer solutions that are implemented in Foundation itself. Exceptions can be made for major functionality (for example, `ICU`, `libdispatch`, and `libxml2`).

## A Taxonomy of Types

A key to the internal design of the framework is the split between the CF implementation and Swift implementation of the Foundation classes. They can be organized into several categories.

### Swift-only

These types have implementations that are written only in Swift. They have no CF counterpart. For example, `NSJSONSerialization`.

### CF-only

These types are not exposed via the public interface of Foundation, but are used internally by CoreFoundation itself. No CF type can be exposed to a user of Foundation; it is an internal implementation detail only.

Note that under the Swift runtime, all CoreFoundation objects are instances of the Swift object `__NSCFType`. This allows us to use the native Swift reference counting semantics for all CF types.

### Has-a relationship

This is the most common kind of type when implementation is shared between CoreFoundation and Foundation. In this case, a Swift class exists in Foundation that contains a `CFTypeRef` as an ivar. For example, `NSRunLoop` has-a `CFRunLoopRef`.
```swift
public class NSRunLoop : NSObject {
    private var _cfRunLoop : CFRunLoopRef
    // ...
}
```

It is very common inside the implementation of Foundation to receive a result from calling into CF that needs to be returned to the caller as a Foundation object. For this reason, has-a classes must provide an internal constructor of the following form:
```swift
internal init(cfObject : CFRunLoopRef) {
    _cfRunLoop = cfObject
}
```

### Is-a relationship (toll-free-bridged)

A smaller number of classes have a special relationship with each other called *toll-free-bridging*. When a CFTypeRef is toll-free-bridged with a Foundation class, its pointer can simply be cast to the appropriate type (in either direction) and it can be passed to functions or methods which expect this type.

In order for toll-free bridging to work, the Swift class and the CF struct must share the exact same memory layout. Additionally, each CF function that operates on an instance of the class has to first check to see if needs to call out to Swift first. This complexity adds a maintenance cost, so we choose to limit the number of toll-free-bridged classes to a few key places:

* `NSNumber` and `CFNumberRef`
* `NSData` and `CFDataRef`
* `NSDate` and `CFDateRef`
* `NSURL` and `CFURLRef`
* `NSCalendar` and `CFCalendarRef`
* `NSTimeZone` and `CFTimeZoneRef`
* `NSLocale` and `CFLocaleRef`
* `NSCharacterSet` and `CFCharacterSetRef`

Additionally, some classes share the same memory layout in CF, Foundation, and the Swift standard library.

* `NSString`, `CFStringRef`, and `String`
* `NSArray`, `CFArrayRef`, and `Array`
* `NSDictionary`, `CFDictionaryRef`, and `Dictionary`
* `NSSet`, `CFSetRef`, and `Set`

> Important: There is currently a limitation in the Swift compiler on Linux that prevents bridging to and from Swift types from working correctly. In places where we return Swift types from Foundation APIs, we must manually convert the output to the native Swift types.

## Platform-specific code

In general, avoid platform-specific code if possible. When it is required, try to put it in a few key funnel points.

When different logic is required for the Swift runtime in CF, use the following macro:
```c
#if DEPLOYMENT_RUNTIME_SWIFT
// Swift Open Source Stack
#else
// Objective-C Stack
#endif
```

In Swift, the OS-check macro is also available:
```swift
#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif
```

# Testing

The Swift Core Libraries project includes XCTest. Foundation uses XCTest for its unit tests.

The Foundation Xcode project includes a test target called `TestFoundation`. Run this target (Cmd-R) to build an executable which loads the Swift XCTest library and Swift Foundation library, then runs a set of tests.

# Foundation Coding Style

In general, follow the Swift Standard Library naming conventions. This project has some additional guidelines.

## Public vs Private

One of the main challenges of developing and maintaining a widely used library is keeping effective separation between public API and private implementation details. We want to maintain both source and binary compatibility in as many cases as possible.

* Every software change that affects the public API will receive extra scrutiny from code review. Always be aware of the boundary between public and private when making changes.
* It is also important to hide private implementation details of one Foundation class from other Foundation classes. Of course, it is still possible to add internal functions to Foundation to enable library-wide features.
* Prefix private or internal functions, ivars, and types with an underscore (in addition to either the private or internal qualifier). This makes it very obvious if something is public or private in places where the function or ivar is used.
* Include documentation with each public API, following the standards set out in the Swift Naming Conventions.

## Keeping Organized

Parts of the CoreFoundation and Foundation libraries are as old as OS X (or older). In order to support long-term maintainability, it is important to keep our source code organized.

* If it helps keep an effective separation of concerns, feel free to split up functionality of one class over several files.
* If appropriate, use `// MARK - Topic` to split up sections of a file.
* Try to keep declarations of ivars and init methods near the tops of the classes

## Working in CoreFoundation

There are some additional considerations when working on the CoreFoundation part of our code, both because it is written in C and also because it is shared amongst platforms.

* Surround Swift-runtime-specific code with the standard macro `#if DEPLOYMENT_RUNTIME_SWIFT`.
* Surround platform-specific code with our standard macros `DEPLOYMENT_TARGET_MACOSX`, `DEPLOYMENT_TARGET_EMBEDDED` (all iOS platforms and derivatives), `DEPLOYMENT_TARGET_LINUX`.
* Follow the coding style of the .c file that you are working in.
