// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// URLQueryItem is defined in FoundationEssentials
@_exported import FoundationEssentials

extension URLQueryItem: _NSBridgeable {
    typealias NSType = NSURLQueryItem
    internal var _nsObject: NSType { return NSURLQueryItem(name: self.name, value: self.value) }
}

extension URLQueryItem: _ObjectiveCBridgeable {
    public typealias _ObjectType = NSURLQueryItem

    public static func _getObjectiveCType() -> Any.Type {
        return NSURLQueryItem.self
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURLQueryItem {
        return NSURLQueryItem(name: self.name, value: self.value)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSURLQueryItem, result: inout URLQueryItem?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSURLQueryItem, result: inout URLQueryItem?) -> Bool {
        result = URLQueryItem(name: x.name, value: x.value)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSURLQueryItem?) -> URLQueryItem {
        var result: URLQueryItem? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension NSURLQueryItem: _SwiftBridgeable {
    typealias SwiftType = URLQueryItem
    internal var _swiftObject: SwiftType { return URLQueryItem(name: self.name, value: self.value) }
}
