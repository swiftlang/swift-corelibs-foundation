# swift-corelibs-foundation Release Notes for Swift 5.x

swift-corelibs-foundation contains new features and API in the Swift 5.x family of releases. These release notes complement the [Foundation release notes](https://developer.apple.com/documentation/ios_release_notes/ios_12_release_notes/foundation_release_notes) with information that is specific to swift-corelibs-foundation. Check both documents for a full overview.

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
