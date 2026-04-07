// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation

extension Bundle {
    /// Creates an instance of `Bundle` from the current value for `#dsohandle`.
    ///
    /// - warning: Don't call this method directly, and use `#bundle` instead.
    ///
    /// In the context of a Swift Package or other static library,
    /// the result is the bundle that contains the produced binary, which may be
    /// different from where resources are stored.
    ///
    /// - Parameter dsoHandle: `dsohandle` of the current binary.
    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    public convenience init?(_dsoHandle: UnsafeRawPointer) {
        let cfBundle = Self.cfBundle(forImageContaining: _dsoHandle) ?? CFBundleGetMainBundle()!
        self.init(cfBundle: cfBundle)
    }
}

/// Expands to a bundle instance that's most likely to contain resources for the calling code.
///
/// Use the `#bundle` macro when you want to load resources like localized strings, images, or other items in a bundle regardless of whether your code executes in an app, a framework, or a Swift package.
/// When invoked from an app, app extension, framework, or similar context, the expanded macro instantiates the bundle associated with that target.
/// For code in a Swift package target, the macro provides the resource bundle associated with that target.
///
/// For example, the following code sets the localized text of a UIKit `UILabel` by explicitly loading the bundle associated with one of the app's view controllers:
///
/// ```swift
/// label.text = String(localized:"Game Over.",
///                     bundle: Bundle(for: MyViewController.self),
///                     comment: "Text for game over banner.")
/// ```
/// You can simplify the `bundle:` parameter by invoking the `#bundle` macro instead, like this:
///
/// ```swift
/// label.text = String(localized:"Game Over.",
///                     bundle: #bundle,
///                     comment: "Text for game over banner.")
/// ```
///
/// The `#bundle` macro back-deploys to earlier versions of the OS, as indicated by the macro's availability.
@freestanding(expression)
public macro bundle() -> Bundle = #externalMacro(module: "FoundationMacros", type: "BundleMacro")
