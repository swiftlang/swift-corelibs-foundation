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
    
    public init(doubleValue: Double, unit: Unit) {
        self.unit = unit
        self.doubleValue = doubleValue
    }
    
    open func canBeConverted(to unit: Unit) -> Bool {
        return self.unit is Dimension && unit is Dimension && type(of: unit).isSubclass(of: type(of: self.unit))
    }
    
    open func converting(to otherUnit: Unit) -> Measurement<Unit> {
        precondition(canBeConverted(to: otherUnit))
        
        if unit.isEqual(otherUnit) {
            return Measurement(value: doubleValue, unit: otherUnit)
        } else {
            let dimensionUnit = unit as! Dimension
            
            let valueInTermsOfBase = dimensionUnit.converter.baseUnitValue(fromValue: doubleValue)
            if otherUnit.isEqual(type(of: dimensionUnit).baseUnit()) {
                return Measurement(value: valueInTermsOfBase, unit: otherUnit)
            } else {
                let otherDimensionUnit = otherUnit as! Dimension
                
                let otherValueFromTermsOfBase = otherDimensionUnit.converter.value(fromBaseUnitValue: valueInTermsOfBase)
                return Measurement(value: otherValueFromTermsOfBase, unit: otherUnit)
            }
        }
    }
    
    open func adding(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
        precondition(unit is Dimension)
        precondition(rhs.unit is Dimension)
        
        let dimensionUnit = unit as! Dimension
        let rhsDimensionUnit = rhs.unit as! Dimension
        
        if unit.isEqual(rhs.unit) {
            return Measurement(value: doubleValue + rhs.value, unit: unit)
        } else {
            let lhsValueInTermsOfBase = dimensionUnit.converter.baseUnitValue(fromValue: doubleValue)
            let rhsValueInTermsOfBase = rhsDimensionUnit.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: lhsValueInTermsOfBase + rhsValueInTermsOfBase, unit: type(of: dimensionUnit).baseUnit())
        }
    }
    
    open func subtracting(_ rhs: Measurement<Unit>) -> Measurement<Unit> {
        precondition(unit is Dimension)
        precondition(rhs.unit is Dimension)
        
        let dimensionUnit = unit as! Dimension
        let rhsDimensionUnit = rhs.unit as! Dimension
        
        if unit.isEqual(rhs.unit) {
            return Measurement(value: doubleValue - rhs.value, unit: unit)
        } else {
            let lhsValueInTermsOfBase = dimensionUnit.converter.baseUnitValue(fromValue: doubleValue)
            let rhsValueInTermsOfBase = rhsDimensionUnit.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: lhsValueInTermsOfBase - rhsValueInTermsOfBase, unit: type(of: dimensionUnit).baseUnit())
        }
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    open class var supportsSecureCoding: Bool { return true }
    
    private enum NSCodingKeys {
        static let value = "NS.value"
        static let unit = "NS.unit"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        let value = aDecoder.decodeDouble(forKey: NSCodingKeys.value)
        guard let unit = aDecoder.decodeObject(of: Unit.self, forKey: NSCodingKeys.unit) else {
            aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: CocoaError.coderReadCorrupt.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unit class object has been corrupted!"]))
            return nil
        }
        
        self.doubleValue = value
        self.unit = unit
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            fatalError("NSMeasurement cannot be encoded by non-keyed archivers")
        }
        
        aCoder.encode(doubleValue, forKey: "NS.value")
        aCoder.encode(unit, forKey: "NS.unit")
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let measurement = object as? NSMeasurement else { return false }
        return measurement.unit.isEqual(self.unit) && doubleValue == measurement.doubleValue
    }
    
    open override var hash: Int {
        return Int(doubleValue) ^ unit.hash
    }
}

extension NSMeasurement : _StructTypeBridgeable {
    public typealias _StructType = Measurement<Unit>
    
    public func _bridgeToSwift() -> Measurement<Unit> {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
