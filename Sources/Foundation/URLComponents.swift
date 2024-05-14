// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension URLComponents : ReferenceConvertible {
    public typealias ReferenceType = NSURLComponents
}

extension NSURLComponents : _SwiftBridgeable {
    typealias SwiftType = URLComponents
    internal var _swiftObject: SwiftType { return URLComponents(string: self.string!)! }
}

extension URLComponents : _NSBridgeable {
    typealias NSType = NSURLComponents
    internal var _nsObject: NSType { return NSURLComponents(string: self.string!)! }
}

extension URLComponents : _ObjectiveCBridgeable {
    public typealias _ObjectType = NSURLComponents
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSURLComponents.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURLComponents {
        return _nsObject
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSURLComponents, result: inout URLComponents?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectType.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSURLComponents, result: inout URLComponents?) -> Bool {
        result = x._swiftObject
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSURLComponents?) -> URLComponents {
        var result: URLComponents? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}
