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


public class NSMeasurement : NSObject, NSCopying, NSSecureCoding {
    public private(set) var unit: Unit
    public private(set) var doubleValue: Double
    
    @available(*, unavailable)
    public convenience override init() { fatalError("Measurements must be constructed with a value and unit") }
    
    public init(doubleValue: Double, unit: Unit) {
        self.doubleValue = doubleValue
        self.unit = unit
    }
    
    public func canBeConverted(to unit: Unit) -> Bool { NSUnimplemented() }
    
    public func converting(to unit: Unit) -> Measurement<Unit> { NSUnimplemented() }
    
    public func adding(_ measurement: Measurement<Unit>) -> Measurement<Unit> { NSUnimplemented() }
    
    public func subtracting(_ measurement: Measurement<Unit>) -> Measurement<Unit> { NSUnimplemented() }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject { NSUnimplemented() }
    
    public class func supportsSecureCoding() -> Bool { return true }
    
    public func encode(with aCoder: NSCoder) { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
}
