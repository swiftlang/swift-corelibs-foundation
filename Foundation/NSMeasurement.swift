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


open class NSMeasurement : NSObject, NSCopying, NSSecureCoding {
    open private(set) var unit: Unit
    open private(set) var doubleValue: Double
    
    @available(*, unavailable)
    public convenience override init() { fatalError("Measurements must be constructed with a value and unit") }
    
    public init(doubleValue: Double, unit: Unit) {
        self.doubleValue = doubleValue
        self.unit = unit
    }
    
    open func canBeConverted(to unit: Unit) -> Bool { NSUnimplemented() }
    
    open func converting(to unit: Unit) -> Measurement<Unit> { NSUnimplemented() }
    
    open func adding(_ measurement: Measurement<Unit>) -> Measurement<Unit> { NSUnimplemented() }
    
    open func subtracting(_ measurement: Measurement<Unit>) -> Measurement<Unit> { NSUnimplemented() }
    
    open func copy(with zone: NSZone? = nil) -> Any { NSUnimplemented() }
    
    open class var supportsSecureCoding: Bool { return true }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        aCoder.encode(doubleValue, forKey: "NS.value")
        aCoder.encode(unit, forKey: "NS.unit")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        self.doubleValue = aDecoder.decodeDouble(forKey: "NS.value")
        guard let unit = aDecoder.decodeObject(of: Unit.self, forKey: "NS.unit") else {
            let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.coderReadCorrupt.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "Unit class object has been corrupted!"._nsObject])
            aDecoder.failWithError(error)
            return nil
        }
        self.unit = unit
    }
}

extension NSMeasurement : _StructTypeBridgeable {
    public typealias _StructType = Measurement<Unit>
    
    public func _bridgeToSwift() -> Measurement<Unit> {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
