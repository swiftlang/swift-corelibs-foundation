# swift-corelibs-foundation Release Notes for Swift 5.x

swift-corelibs-foundation contains new features and API in the Swift 5.x family of releases. These release notes complement the [Foundation release notes](https://developer.apple.com/documentation/ios_release_notes/ios_12_release_notes/foundation_release_notes) with information that is specific to swift-corelibs-foundation. Check both documents for a full overview.

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
