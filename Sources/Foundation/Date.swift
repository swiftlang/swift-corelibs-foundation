// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import _CoreFoundation

extension Date : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDate {
        return NSDate(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSDate, result: inout Date?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(NSDate.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSDate, result: inout Date?) -> Bool {
        result = Date(timeIntervalSinceReferenceDate: x.timeIntervalSinceReferenceDate)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDate?) -> Date {
        var result: Date? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension Date : CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: self)
    }
}
