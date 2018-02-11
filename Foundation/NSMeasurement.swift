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
    
    open func canBeConverted(to otherUnit: Unit) -> Bool {
        #if DEPLOYMENT_RUNTIME_OBJC //|| os(Linux)
            return otherUnit.isKind(of: type(of: unit))
        #else
            // just check conversion
            if unit is Dimension && otherUnit is Dimension {
                return true
            } else {
                return unit.isEqual(otherUnit)
            }
        #endif
    }
    
    open func converting(to otherUnit: Unit) -> Measurement<Unit> {
        if canBeConverted(to: otherUnit) {
            if unit.isEqual(otherUnit) {
                return Measurement(value: doubleValue, unit: otherUnit)
            } else {
                guard let dimension = unit as? Dimension,
                    let otherDimension = otherUnit as? Dimension else {
                        fatalError("Cannot convert differing units that are non-dimensional! lhs: \(type(of: unit)) rhs: \(type(of: otherUnit))")
                }
                let valueInTermsOfBase = dimension.converter.baseUnitValue(fromValue: doubleValue)
                if otherDimension.isEqual(type(of: dimension).baseUnit()) {
                    return Measurement(value: valueInTermsOfBase, unit: otherDimension)
                } else {
                    let otherValueFromTermsOfBase = otherDimension.converter.value(fromBaseUnitValue: valueInTermsOfBase)
                    return Measurement(value: otherValueFromTermsOfBase, unit: otherDimension)
                }
            }
        } else {
            fatalError("Cannot convert measurements of differing unit types! self: \(type(of: unit)) unit: \(type(of: otherUnit))")
        }
    }
    
    open func adding(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
        if self.unit.isEqual(rhs.unit) {
            return Measurement(value: self.doubleValue + rhs.value, unit: self.unit)
        } else {
            guard let dimension = unit as? Dimension,
                    let otherDimension = rhs.unit as? Dimension else {
                        fatalError("Cannot convert differing units that are non-dimensional! lhs: \(type(of: unit)) rhs: \(type(of: rhs.unit))")
                }
            let selfValueInTermsOfBase = dimension.converter.baseUnitValue(fromValue: self.doubleValue)
            let rhsValueInTermsOfBase = otherDimension.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: selfValueInTermsOfBase + rhsValueInTermsOfBase, unit: type(of: dimension).baseUnit())
        }
    }
    
    open func subtracting(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
        if self.unit.isEqual(rhs.unit) {
            return Measurement(value: self.doubleValue - rhs.value, unit: self.unit)
        } else {
            guard let dimension = unit as? Dimension,
                    let otherDimension = rhs.unit as? Dimension else {
                        fatalError("Cannot convert differing units that are non-dimensional! lhs: \(type(of: unit)) rhs: \(type(of: rhs.unit))")
                }
            let selfValueInTermsOfBase = dimension.converter.baseUnitValue(fromValue: self.doubleValue)
            let rhsValueInTermsOfBase = otherDimension.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: selfValueInTermsOfBase - rhsValueInTermsOfBase, unit: type(of: dimension).baseUnit())
        }
    }
    
    open func copy(with zone: NSZone? = nil) -> Any { return self }
    
    open class var supportsSecureCoding: Bool { return true }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.doubleValue, forKey:"NS.value")
        aCoder.encode(self.unit, forKey:"NS.unit")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let doubleValue = aDecoder.decodeDouble(forKey: "NS.value")
        let possibleUnit = aDecoder.decodeObject(forKey: "NS.unit")
        guard let unit = possibleUnit as? Unit else {
            return nil // or should we `fatalError()`?
        }
        self.doubleValue = doubleValue
        self.unit = unit
    }
}

extension NSMeasurement : _StructTypeBridgeable {
    public typealias _StructType = Measurement<Unit>
    
    public func _bridgeToSwift() -> Measurement<Unit> {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
