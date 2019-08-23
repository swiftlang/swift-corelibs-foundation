# Testing swift-corelibs-foundation

swift-corelibs-foundation uses XCTest for its own test suite. This document explains how we use it and how we organize certain kinds of specialized testing. This is both different from the Swift compiler and standard library, which use `lit.py`, and from destkop testing, since the version of XCTest we use is not the Darwin one, but the Swift core library implementation in `swift-corelibs-xctest`, which is pretty close to the original with some significant differences.

## Tests Should Fail, Not Crash

### In brief

* Tests should fail rather than crashing; swift-corelibs-xctest does not implement any crash recovery
* You should avoid forced optional unwrapping (e.g.: `aValue!`). Use `try XCTUnwrap(aValue)` instead
* You can test code that is expected to crash; you must mark the whole body of the test method with `assertCrashes(within:)`
* If a test or a portion of a test is giving the build trouble, use `testExpectedToFail` and write a bug

### Why and How

XCTest on Darwin can implement a multiprocess setup that allows a test run to continue if the test process crashes. On Darwin, code is built into a bundle, and a specialized tool called `xctest` runs the test by loading the bundle; the Xcode infrastructure can detect the crash and restart the tool from where it left off. For swift-corelibs-xctest, instead, the Foundation test code is compiled into a single executable and that executable is run by the Swift build process; if it crashes, subsequent tests aren't run, which can mask regressions that are merged while the crash is unaddressed.

Due to this, it is important to avoid crashing in test code, and to properly handle tests that do. Every API is unique in this regard, but some situations are common across tests.

#### Avoiding Forced Unwrapping

Forced unwrapping is easily the easiest way to crash the test process, and should be avoided. XCTest have an ergonomic replacement in the form of the `XCTUnwrap()` function.

The following code is a liability and code review should flag it:

```swift
func testSomeInterestingAPI() {
	let x = interestingAPI.someOptionalProperty! // <<< Incorrect!
	
	XCTAssertEqual(x, 42, "The correct answer is present")
}
```

Instead:

1. Change the test method to throw errors by adding the `throws` clause. Tests that throw errors will fail and stop the first time an error is thrown, so plan accordingly, but a thrown error will not stop the test run, merely fail this test.
2. Change the forced unwrapping to `try XCTUnwrap(…)`.

For example, the code above can be fixed as follows:

```swift
func testSomeInterestingAPI() throws { // Step 1: Add 'throws'
	// Step 2: Replace the unwrap.
	let x = try XCTUnwrap(interestingAPI.someOptionalProperty)
	
	XCTAssertEqual(x, 42, "The correct answer is present")
}
```

#### Asserting That Code Crashes

Some API, like `NSCoder`'s `raiseException` failure policy, are _supposed_ to crash the process when faced with edge conditions. Since tests should fail and not crash, we have been unable to test this behavior for the longest time.

Starting in swift-corelibs-foundation in Swift 5.1, we have a new utility function called `assertCrashes(within:)` that can be used to indicate that a test crashes. It will respawn a process behind the scene, and fail the test if the second process doesn't crash. That process will re-execute the current test, _including_ the contents of the closure, up to the point where the first crash occurs.

To write a test function that asserts some code crashes, wrap its **entire body** as in this example:

```swift
func testRandomClassDoesNotDeserialize() {
	assertCrashes {
		let coder = NSKeyedUnarchiver(requiresSecureCoding: false)
		coder.requiresSecureCoding = true
		coder.decodeObject(of: [AClassThatIsntSecureEncodable.self], forKey: …)
		…
	}
}
```

Since the closure will only execute to the first crash, ensure you do not use multiple `assertCrashes…` markers in the same test method, that you do _not_ mix crash tests with regular test code, and that if you want to test multiple crashes you do so with separate test methods. Wrapping the entire method body is an easy way to ensure that at least some of these objectives are met.

#### Stopping Flaky or Crashing Tests

A test that crashes or fails multiple times can jeopardize patch testing and regression reporting. If a test is flaky or outright failing or crashing, it should be marked as expected to fail ASAP using the appropriate Foundation test utilities.

Let's say a test of this form is committed:

```swift
func testNothingUseful() {
	fatalError() // Smash the machine!
}
```

A test fix commit should be introduced that does the following:

* Write a bug to investigate and re-enable the test on [the Swift Jira instance](https://bugs.swift.org/). Have the link to the bug handy (e.g.: `http://bugs.swift.org/browse/SR-999999`).

* Find the `allTests` entry for the offending test. For example:

```swift
var allTests: […] {
	return [
		// …
		("testNothingUseful", testNothingUseful),
		// …
	]
```

* Replace the method reference with a call to `testExpectedToFail` that includes the reason and the bug link. Mark that location with a `/* ⚠️ */` comment. For example:

```swift
var allTests: […] {
	return [
		// …
		// Add the prefix warning sign and the call:
		/* ⚠️ */ ("testNothingUseful", testExpectedToFail(testNothingUseful,
			"This test crashes for no clear reason. http://bugs.swift.org/browse/SR-999999")),
		// …
	]
```

Alternately, let's say only a portion of a test is problematic. For example:

```swift
func testAllMannersOfIO() throws {
	try runSomeRockSolidIOTests()
	try runSomeFlakyIOTests() // These fail pretty often.
	try runSomeMoreRockSOlidIOTests()
}
```

In this case, file a bug as per above, then wrap the offending portion as follows:

```swift
func testAllMannersOfIO() throws {
	try runSomeRockSolidIOTests()
	
	/* ⚠️ */
	if shouldAttemptXFailTests("These fail pretty often. http://bugs.swift.org/browse/SR-999999") {
		try runSomeFlakyIOTests()
	}
	/* ⚠️ */
	
	try runSomeMoreRockSOlidIOTests()
}
```

Unlike XFAIL tests in `lit.py`, tests that are expected to fail will _not_ execute during the build. If your test is disabled in this manner, you should investigate the bug by running the test suite locally; you can do so without changing the source code by setting the `NS_FOUNDATION_ATTEMPT_XFAIL_TESTS` environment variable set to the string `YES`, which will cause tests that were disabled this way to attempt to execute anyway.

## Test Internal Behavior Carefully: `@testable import`

### In brief

* Prefer black box (contract-based) testing to white box testing wherever possible
* Some contracts cannot be tested or cannot be tested reliably (for instance, per-platform fallback paths); it is appropriate to use `@testable import` to test their component parts instead
* Ensure your test wraps any reference to `internal` functionality with `#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT`
* Ensure the file you are using this in adds a `@testable import` prologue
* Run with this enabled _and_ disabled prior to PR

### Why and How

In general, we want to ensure that tests are written to check the _contract_ of the API, [as documented for each class](https://developer.apple.com/). It is of course acceptable to have the test implementation be informed by the implementation, but we want to make sure that tests still make sense if we replace an implementation entirely, [as we sometimes do](https://github.com/apple/swift-corelibs-foundation/pull/2331).

This doesn't always work. Sometimes the contract specifies that a certain _result_ will occur, and that result may be platform-specific or trigger in multiple ways, all of which we'd like to test (for example, different file operation paths for volumes with different capabilities). In this case, we can reach into Foundation's `internal` methods by using `@testable import` and test the component parts or invoke private API ("SPI") to alter the behavior so that all paths are taken.

If you think this is the case, you must be careful. We run tests both against a debug version of Foundation, which supports `@testable import`, and the release library, which does not. Your tests using `internal` code must be correctly marked so that tests don't succeed in one configuration but fail in the other.

To mark those tests:

* Wrap code using internal features with `#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT`:

```swift
func testSomeFeature() {
#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
	try Date._someInternalTestModifierMethod {
		// …
	}
#endif
}
```

* In the file you're adding the test, if not present, add the appropriate `@testable import` import prologue at the top. It will look like the one below, but **do not** copy and paste this — instead, search the codebase for `@testable import` for the latest version:

```swift
// It will look something like this:

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
	…
```

* Run your tests both against a debug Foundation (which has testing enabled) and a release Foundation (which does not). If you're using `build-script` to build, you can produce the first by using the `--debug-foundation` flag and the latter with the regular `--foundation` flag. **Do this before creating a PR.** Currently the pipeline checks both versions only outside PR testing, and we want to be sure that the code compiles in both modes before accepting a patch like this. (Automatic testing and dual-mode PR testing are forthcoming.)

## Testing NSCoding: Don't Write This From Scratch; Use Fixtures

### In brief

* We want `NSCoding` to work with archives produced by _both_ Darwin Foundation and swift-corelibs-foundation
* Where possible, _do not_ write your own coding test code — use the fixture infrastructure instead
* Fixture tests will both test roundtrip coding (reading back what swift-corelibs-foundation produces), and archive coding (with archives produced by Darwin Foundation)
* Add a fixture test by adding fixtures to `FixtureValues.swift`
* Use `assertValueRoundtripsInCoder(…)` and `assertLoadedValuesMatch(…)` in your test methods
* Use the `GenerateTestFixtures` project in the `Tools` directory to generate archives for `assertLoadedValuesMatch(…)`, and commit them in `TestFoundation/Fixtures`.
* Please generate your fixtures on the latest released (non-beta) macOS.

### Why and How

`NSCoding` in swift-corelibs-foundation has a slightly more expansive contract than other portions of the library; while the rest need to be _consistent_ with the behavior of the Darwin Foundation library, but not necessarily identical, `NSCoding` implementations in s-c-f must as far as possible be able to both decode Darwin Foundation archives and encode archives that Darwin Foundation can decode. Thus, simple roundtrip tests aren't sufficient.

We have an infrastructure in place for this kind of test. We produce values (called _fixtures_) from closures specified in the file `FixtureValues.swift`. We can both test for in-memory roundtrips (ensuring that the data produced by swift-corelibs-foundation is also decodable with swift-corelibs-foundation), and run those closures using Darwin Foundation to produce archives that we then try to read with swift-corelibs-foundation (and, in the future, expand this to multiple sources).

If you want to add a fixture to test, follow these steps:

* Add the fixture or fixtures as static properties on the Fixture enum. For example:

```swift
static let defaultBeverage = TypedFixture<NSBeverage>("NSBeverage-Default") {
	return NSBeverage()
}

static let fancyBeverage = TypedFixture<NSBeverage>("NSBeverage-Fancy") {
	var options: NSBeverage.Options = .defaultForFancyDrinks
	options.insert(.shaken)
	options.remove(.stirren)
	return NSBeverage(named: "The Fancy Brand", options: options)
}
```

The string you pass to the constructor is an identifier for that particular fixture kind, and is used as the filename for the archive you will produce below.

* Add them to the `_listOfAllFixtures` in the same file, wrapping them in the type eraser `AnyFixture`:

```swift
// Search for this:
static let _listOfAllFixtures: [AnyFixture] = [
	…
	// And insert them here:
	AnyFixture(Fixtures.defaultBeverage),
	AnyFixture(Fixtures.fancyBeverage),
]
```

* Add tests to the appropriate class that invoke the `assertValueRoundtripsInCoder` and `assertLoadedValuesMatch` methods. For example:

```swift
class TestNSBeverage {
	…
	
	let fixtures = [
		Fixtures.defaultBeverage,
		Fixtures.fancyBeverage,
	]
	
	func testCodingRoundtrip() throws {
        for fixture in fixtures {
            try fixture.assertValueRoundtripsInCoder()
        }
    }
    
    func testLoadingFixtures() throws {
        for fixture in fixtures {
            try fixture.assertLoadedValuesMatch()
        }
    }
    
	// Make sure the tests above are added to allTests, as usual!
}
```

These calls assume your objects override `isEqual(_:)` to be something other than object identity, and that it will return `true` for comparing the freshly-decoded objects to their originals. If that's not the case, you'll have to write a function that compares the old and new object for your use case:

```swift
	func areEqual(_ lhs: NSBeverage, _ rhs: NSBeverage) -> Bool {
		return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame && 
			lhs.options == rhs.options
	}

	func testCodingRoundtrip() throws {
        for fixture in fixtures {
            try fixture.assertValueRoundtripsInCoder(matchingWith: areEqual(_:_:))
        }
    }
    
    func testLoadingFixtures() throws {
        for fixture in fixtures {
            try fixture.assertLoadedValuesMatch(areEqual(_:_:))
        }
    }
```

* Open the `GenerateTestFixtures` project from the `Tools/GenerateTestFixtures` directory of the repository, and build the executable the eponymous target produces; then, run it. It will produce archives for all fixtures, and print their paths to the console. **Please run this step on the latest released version of macOS.** Do not run this step on newer beta versions, even if they're available. For example, at the time of writing, the most recently released version of macOS is macOS Mojave (10.14), and beta versions of macOS Catalina (10.15) are available; you'd need to run this step on a Mac running macOS Mojave.

* Copy the new archives for your data from the location printed in the console to the `TestFoundation/Fixtures` directory of the repository. This will allow `assertLoadedValuesMatch` to find them.

* Run your new tests and make sure they pass!

The archive will be encoded using secure coding, if your class conforms to it and returns `true` from `supportsSecureCoding`.
