//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_implementationOnly import _CoreFoundation

internal func __NSLocaleIsAutoupdating(_ locale: NSLocale) -> Bool {
    return false // Auto-updating is only on Darwin
}

internal func __NSLocaleCurrent() -> NSLocale {
    NSLocale(locale: Locale.current)
}

extension Locale : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSLocale {
        return NSLocale(locale: Locale.current)
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSLocale, result: inout Locale?) {
        if !_conditionallyBridgeFromObjectiveC(input, result: &result) {
            fatalError("Unable to bridge \(NSLocale.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSLocale, result: inout Locale?) -> Bool {
        result = input._locale
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSLocale?) -> Locale {
        var result: Locale? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}
