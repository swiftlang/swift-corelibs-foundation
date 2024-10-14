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

internal import CoreFoundation

extension DateInterval : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSDateInterval.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDateInterval {
        return NSDateInterval(start: start, duration: duration)
    }
    
    public static func _forceBridgeFromObjectiveC(_ dateInterval: NSDateInterval, result: inout DateInterval?) {
        if !_conditionallyBridgeFromObjectiveC(dateInterval, result: &result) {
            fatalError("Unable to bridge \(NSDateInterval.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ dateInterval : NSDateInterval, result: inout DateInterval?) -> Bool {
        result = DateInterval(start: dateInterval.startDate, duration: dateInterval.duration)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDateInterval?) -> DateInterval {
        var result: DateInterval? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}
