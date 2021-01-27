// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/// A single name-value pair, for use with `URLComponents`.
public struct URLQueryItem: ReferenceConvertible, Hashable, Equatable {
    public typealias ReferenceType = NSURLQueryItem

    fileprivate var _queryItem: NSURLQueryItem

    public init(name: String, value: String?) {
        _queryItem = NSURLQueryItem(name: name, value: value)
    }

    fileprivate init(reference: NSURLQueryItem) { _queryItem = reference.copy() as! NSURLQueryItem }
    fileprivate var reference: NSURLQueryItem { return _queryItem }

    public var name: String {
        get { return _queryItem.name }
        set { _queryItem = NSURLQueryItem(name: newValue, value: value) }
    }

    public var value: String? {
        get { return _queryItem.value }
        set { _queryItem = NSURLQueryItem(name: name, value: newValue) }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_queryItem)
    }

    public static func ==(lhs: URLQueryItem, rhs: URLQueryItem) -> Bool {
        return lhs._queryItem.isEqual(rhs._queryItem)
    }
}

extension URLQueryItem: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        if let v = value {
            return "\(name)=\(v)"
        } else {
            return name
        }
    }

    public var debugDescription: String {
        return self.description
    }

    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        c.append((label: "name", value: name))
        c.append((label: "value", value: value as Any))
        return Mirror(self, children: c, displayStyle: .struct)
    }
}

extension URLQueryItem: _NSBridgeable {
    typealias NSType = NSURLQueryItem
    internal var _nsObject: NSType { return _queryItem }
}

extension URLQueryItem: _ObjectiveCBridgeable {
    public typealias _ObjectType = NSURLQueryItem

    public static func _getObjectiveCType() -> Any.Type {
        return NSURLQueryItem.self
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURLQueryItem {
        return _queryItem
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSURLQueryItem, result: inout URLQueryItem?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSURLQueryItem, result: inout URLQueryItem?) -> Bool {
        result = URLQueryItem(reference: x)
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
    internal var _swiftObject: SwiftType { return URLQueryItem(reference: self) }
}
