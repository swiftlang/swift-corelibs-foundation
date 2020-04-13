# swift-corelibs-foundation Release Notes for Swift 5.x

swift-corelibs-foundation contains new features and API in the Swift 5.x family of releases. These release notes complement the [Foundation release notes](https://developer.apple.com/documentation/ios_release_notes/ios_12_release_notes/foundation_release_notes) with information that is specific to swift-corelibs-foundation. Check both documents for a full overview.

## Dependency Management

On Darwin, the OS provides prepackaged dependency libraries that allow Foundation to offer a range of disparate functionalities without the need for a developer to fine-tune their dependency usage. Applications that use swift-corelibs-foundation do not have access to this functionality, and thus have to contend with managing additional system dependencies on top of what the Swift runtime and standard library already requires. This hinders packaging Swift applications that port or use Foundation in constrained environments where these dependencies are an issue.

To aid in porting and dependency management, starting in Swift 5.1, some functionality has been moved from Foundation to other related modules. Foundation vends three modules:

 - `Foundation`
 - `FoundationNetworking`
 - `FoundationXML`
 
 On Linux, the `Foundation` module now only has the same set of dependencies as the Swift standard library itself, rather than requiring linking the  `libcurl` and `libxml2` libraries (and their indirect dependencies). The other modules will require additional linking.
 
The following types, and related functionality, are now only offered if you import the `FoundationNetworking` module:

- `CachedURLResponse`
- `HTTPCookie`
- `HTTPCookieStorage`
- `HTTPURLResponse`
- `URLResponse`
- `URLSession`
- `URLSessionConfiguration`
- `URLSessionDataTask`
- `URLSessionDownloadTask`
- `URLSessionStreamTask`
- `URLSessionTask`
- `URLSessionUploadTask`
- `URLAuthenticationChallenge`
- `URLCache`
- `URLCredential`
- `URLCredentialStorage`
- `URLProtectionSpace`
- `URLProtocol`

Using this module will cause you to link the `libcurl` library and its dependencies.  Note that the `URL` structure and the `NSURL` type are still offered by the `Foundation` module, and that, with one exception mentioned below, the full range of functionality related to these types is available without additional imports.

The following types, and related functionality, are now only offered if you import the `FoundationXML` module:

- `XMLDTD`
- `XMLDTDNode`
- `XMLDocument`
- `XMLElement`
- `XMLNode`
- `XMLParser`

Using this module will cause you to link the `libxml2` library and its dependencies. Note that property list functionality is available using the `Foundation` without additional imports, even if they are serialized in the `xml1` format. Only direct use of these types requires importing the `FoundationXML` module.

The recommended way to import these modules in your source file is:
    
    #if canImport(FoundationNetworking)
    import FoundationNetworking
    #endif
    
    #if canImport(FoundationXML)
    import FoundationXML
    #endif
    
This allows source that runs on Darwin and on previous versions of Swift to transition to Swift 5.1 correctly.

There are two consequences of this new organization that may affect your code:

 - The module-qualified name for the classes mentioned above has changed. For example, the `URLSession` class's module-qualified name was `Foundation.URLSession` in Swift 5.0 and earlier, and `FoundationNetworking.URLSession` in Swift 5.1. This may affect your use of `NSClassFromString`, `import class…` statements and module-name disambiguation in existing source code. See the 'Objective-C Runtime Simulation' section below for more information.

- `Foundation` provides `Data(contentsOf:)`, `String(contentsOf:…)`, `Dictionary(contentsOf:…)` and other initializers on model classes that take `URL` arguments. These continue to work with no further dependencies for URLs that have the `file` scheme (i.e., for which `.isFileURL` returns `true`). If you used other URL schemes, these methods would previously cause a download to occur, blocking the current thread until the download finished. If you require this functionality to work in Swift 5.1, your application must link or dynamically load the `FoundationNetworking` module, or the process will stop with an error message to this effect. **Please avoid this usage of the methods.** These methods block a thread in your application while networking occurs, which may cause performance degradation and unexpected threading issues if used in concert with the `Dispatch` module or from the callbacks of a `URLSessionTask`. Instead, where possible, please migrate to using a `URLSession` directly.

## Objective-C Runtime Simulation

Foundation provides facilities that simulate certain Objective-C features in Swift for Linux, such as the `NSClassFromString` and `NSStringFromClass` functions. Starting in Swift 5.1, these functions now more accurately reflect the behavior of their Darwin counterparts by allowing you to use Objective-C names for Foundation classes. Code such as the following now will now behave in the same way on both Darwin and Swift for Linux:

    let someClass = NSClassFromString("NSTask")
    assert(someClass == Process.self)
    let someName = NSStringFromClass(someClass)
    assert(someName == "NSTask")
    
It is recommended that you use Objective-C names for Foundation classes in your code. Starting from Swift 5.1, these names will work, and will be treated as the canonical names for classes originating from any of the Foundation modules. This may affect `NSCoding` archives you created in Swift for Linux 5.0 and later; you may have to recreate these archives with Darwin or with Swift for Linux 5.1 for forward compatibility. See 'Improvements to NSCoder' below for more information.

While the use of module-qualified names is still supported for classes in the `Foundation` module, e.g. `"Foundation.Process"`, it is now heavily discouraged:

- Please use the Objective-C name instead wherever possible, e.g. `"NSTask"`;
- Classes moved to the `FoundationNetworking` and `FoundationXML` modules have new module-qualified names, e.g. `"FoundationNetworking.URLSession"` (which used to be `"Foundation.URLSession"` in Swift 5.0). You should use the Objective-C names instead, e.g. `"NSURLSession"`; both module-qualified and Objective-C names will work if your application links the appropriate modules, or will return `nil` if you do not.

## Improvements to NSCoder

In this release, the implementation of `NSCoder` and related classes has been brought closer to the behavior of their Darwin counterparts. There are a number of differences from previous versions of swift-corelibs-foundation that you should keep in mind while writing code that uses `NSKeyedArchiver` and `NSKeyedUnarchiver`:

* In previous versions of swift-corelibs-foundation, the `decodingFailurePolicy` setting was hardcoded to `.setAndReturnError`; however, failure in decoding would crash the process (matching the behavior of the `.raiseException` policy). This has been corrected; you can now set the `decodingFailurePolicy` to either policy. To match Darwin, the default behavior has been changed to `.raiseException`.

* On Darwin, in certain rare cases, invoking `failWithError(_:)` could stop execution of an initializer or `encode(with:)` method and unwind the stack, while still continuing program execution (by translating the exception to a `NSError` to a top-level caller). Swift does not support this. The `NSCoder` API documented to do this (`decodeTopLevelObject…`) is not available on swift-corelibs-foundation, and it has been annotated with diagnostics pointing you to cross-platform replacements.

* The following Foundation classes that conform to `NSCoding` and/or `NSSecureCoding` now correctly implement archiving in a way that is compatible with archives produced by their Darwin counterparts:

  - `NSCharacterSet`
  - `NSOrderedSet`
  - `NSSet`
  - `NSIndexSet`
  - `NSTextCheckingResult` (only for results whose type is `.regularExpression`)
  - `ISO8601DateFormatter`
  - `DateIntervalFormatter`
  
* The following Foundation classes require features not available in swift-corelibs-foundation. Therefore, they do not conform to `NSCoding` and/or `NSSecureCoding` in swift-corelibs-foundation. These classes may have conformed to `NSCoding` or `NSSecureCoding` in prior versions of swift-corelibs-foundation, even though they weren't complete prior to this release.

  - `NSSortDescriptor` (requires key-value coding)
  - `NSPredicate` (requires key-value coding)
  - `NSExpression` (requires key-value coding)
  - `NSFileHandle` (requires `NSXPCConnection` and related subclasses, which are not available outside of Darwin)
  
  While the type system may help you find occurrences of usage of these classes in a `NSCoding` context, they can still be, incorrectly, passed to the `decodeObjects(of:…)` method that takes a `[AnyClass]` argument. You will need to audit your code to ensure you are not attempting to decode these objects; if you need to decode an archive that contains these objects from Darwin, you should skip decoding of the associated keys in your swift-corelibs-foundation implementation.
  
## NSSortDescriptor Changes

swift-corelibs-foundation now contains an implementation of `NSSortDescriptor` that is partially compatible with its Objective-C counterpart. You may need to alter existing code that makes use of the following:

- Initializers that use string keys or key paths (e.g.: `init(key:…)`) are not available in swift-corelibs-foundation. You should migrate to initializers that take a Swift key path instead (`init(keyPath:…)`).

- Initializers that take or invoke an Objective-C selector are not available in swift-corelibs-foundation. If your class implemented a `compare(_:)` method for use with the `init(keyPath:ascending:)` initializer, you should add a `Swift.Comparable` conformance to it, which will be used in swift-corelibs-foundation in place of the method. The conformance can invoke the method, like so:

```swift
extension MyCustomClass: Comparable {
    public static func <(_ lhs: MyCustomClass, _ rhs: MyCustomClass) {
        return lhs.compare(rhs) == .orderedAscending
    }
}
```

Note that swift-corelibs-foundation's version of `init(keyPath:ascending:)` is annotated with diagnostics that will cause your code to fail to compile if your custom type isn't `Comparable`; code that uses that constructor with Foundation types that implement a `compare(_:)` method, like `NSString`, `NSNumber`, etc., should still compile and work correctly.

If you were using a selector other than `compare(_:)`, you should migrate to passing a closure to `init(keyPath:ascending:comparator:)` instead. That closure can invoke the desired method. For example:

```swift
let descriptor = NSSortDescriptor(keyPath: \Person.name, ascending: true, comparator: { (lhs, rhs) in
    return (lhs as! NSString).localizedCompare(rhs as! String) 
})
```

 - Archived sort descriptors make use of string keys and key paths, and Swift key paths cannot be serialized outside of Darwin.  `NSSortDescriptor` does not conform to `NSSecureCoding` in swift-corelibs-foundation as a result. See the section on `NSCoding` for more information on coding differences in this release.

## Improved Scanner API

The `Scanner` class now has additional API that is more idiomatic for use by Swift code, and doesn't require casting or using by-reference arguments. Several of the new methods have the same name as existing ones, except without the `into:` parameter: `scanInt32()`, `scanString(_:)`, `scanUpToCharacters(from:)`, etc. These invocations will return `nil` if scanning fails, where previous methods would return `false`.

Some of this API existed already in previous releases of swift-corelibs-foundation as experimental. While some of the experimental methods have been promoted, most have been deprecated or obsoleted, and the semantics have changed slightly. The previous methods would match the semantics of `NSString`; 'long characters' could sometimes be scanned only partially, causing scanning to end up in the middle of a grapheme. This made interoperation with the Swift `String` and `Character` types onerous in cases where graphemes with multiple code points were involved. The new methods will instead always preserve full graphemes in the scanned string when invoked, and will not match a grapheme unless all of its unicode scalars are contained in whatever `CharacterSet` is passed in.

If your `Scanner` is used by legacy code, you can freely mix deprecated method invocations and calls to the new API. If you invoke new API while the `scanLocation` is in the middle of a grapheme, the new API will first move to the first next full grapheme before performing any scanning. `scanLocation` itself is deprecated in favor of `currentIndex`, which is a `String.Index` in keeping with Swift string conventions.

## Improved FileHandle API

Several releases ago, Foundation and higher-level frameworks adopted usage of `NSError` to signal errors that can normally occur as part of application execution, as opposed to `NSException`s, which are used to signal programmer errors. Swift's error handling system is also designed to interoperate with `NSError`, and has no provisions for catching exceptions. `FileHandle`'s API was designed before this change, and uses exceptions to indicate issues with the underlying I/O and file descriptor handling operations. This made using the class an issue, especially from Swift code that can't handle these conditions; for full compatibility, the swift-corelibs-foundation version of the class used `fatalError()` liberally. This release introduces new API that can throw an error instead of crashing, plus some additional refinements.

A few notes:

* The Swift refinement allows the new writing method, `write(contentsOf:)`, to work with arbitrary `DataProtocol` objects efficiently, including non-contiguous-bytes objects that span multiple regions.

* The exception-throwing API will be deprecated in a future release. It is now marked as `@available(…, deprecated: 100000, …)`, which matches what you would see if `API_TO_BE_DEPRECATED` was used in a Objective-C header.

* Subclassing `NSFileHandle` is strongly discouraged. Many of the new methods are `public` and cannot be overridden.

## `NSString(bytesNoCopy:length:encoding:freeWhenDone:)` deviations from reference implementation

On Windows, `NSString(bytesNoCopy:length:encoding:freeWhenDone:)` deviates from
the behaviour on Darwin and uses the buffer's `deallocate` routine rather than
`free`.  This is done to ensure that the correct routine is invoked for
releasing the resources acquired through `UnsafeMutablePointer.allocate` or
`UnsafeMutableRawPointer.allocate`.
