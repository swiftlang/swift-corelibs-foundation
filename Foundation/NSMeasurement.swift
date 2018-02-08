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
      return otherUnit.isKind(of: type(of: unit))
    }
    
    open func converting(to otherUnit: Unit) -> Measurement<Unit> { 
      if canBeConverted(to: otherUnit) {
        if unit.isEqual(otherUnit) {
          return Measurement(value: doubleValue, unit: otherUnit)
        } else {
          guard let sdim = unit as? Dimension,
                let udim = otherUnit as? Dimension else {
            fatalError("Cannot convert differing units that are non-dimensional! lhs: \(type(of: unit)) rhs: \(type(of: otherUnit))")
          }
          let valueInTermsOfBase = unit.converter.baseUnitValue(fromValue: value)
            if otherUnit.isEqual(type(of: unit).baseUnit()) {
                return Measurement(value: valueInTermsOfBase, unit: otherUnit)
            } else {
                let otherValueFromTermsOfBase = otherUnit.converter.value(fromBaseUnitValue: valueInTermsOfBase)
                return Measurement(value: otherValueFromTermsOfBase, unit: otherUnit)
            }
        }
      } else {
        fatalError("Cannot convert measurements of differing unit types! self: \(type(of: unit)) unit: \(type(of: otherUnit))")
      }
    }
    
    open func adding(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
      if self.unit.isEqual(rhs.unit) {
            return Measurement(value: self.doubleValue + rhs.doubleValue, unit: self.unit)
        } else {
            let selfValueInTermsOfBase = self.unit.converter.baseUnitValue(fromValue: self.doubleValue)
            let rhsValueInTermsOfBase = rhs.unit.converter.baseUnitValue(fromValue: rhs.doubleValue)
            return Measurement(value: selfValueInTermsOfBase + rhsValueInTermsOfBase, unit: type(of: self.unit).baseUnit())
        }
    }
    
    open func subtracting(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
      if self.unit.isEqual(rhs.unit) {
            return Measurement(value: self.doubleValue - rhs.doubleValue, unit: self.unit)
        } else {
            let selfValueInTermsOfBase = self.unit.converter.baseUnitValue(fromValue: self.doubleValue)
            let rhsValueInTermsOfBase = rhs.unit.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: selfValueInTermsOfBase - rhsValueInTermsOfBase, unit: type(of: self.unit).baseUnit())
        }
    }
    
    open func copy(with zone: NSZone? = nil) -> Any { NSUnimplemented() }
    
    open class var supportsSecureCoding: Bool { return true }
    
    open func encode(with aCoder: NSCoder) { 
      guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.doubleValue, forKey:"NS.dblval")
        aCoder.encode(self.unit, forKey:"NS.unit")
    }
    
    public required init?(coder aDecoder: NSCoder) { 
      guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let doubleValue = aDecoder.decodeDouble(forKey: "NS.dblval")
        let unit = aDecoder.decodeObject(forKey: "NS.unit")
        self.init(coefficient: coefficient, constant: constant)
    }
}

extension NSMeasurement : _StructTypeBridgeable {
    public typealias _StructType = Measurement<Unit>
    
    public func _bridgeToSwift() -> Measurement<Unit> {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
