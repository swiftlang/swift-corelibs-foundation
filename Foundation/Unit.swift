/*
 NSUnitConverter describes how to convert a unit to and from the base unit of its dimension.  Use the NSUnitConverter protocol to implement new ways of converting a unit.
 */

open class UnitConverter : NSObject {
    
    
    /*
     The following methods perform conversions to and from the base unit of a unit class's dimension.  Each unit is defined against the base unit for the dimension to which the unit belongs.
     
     These methods are implemented differently depending on the type of conversion.  The default implementation in NSUnitConverter simply returns the value.
     
     These methods exist for the sole purpose of creating custom conversions for units in order to support converting a value from one kind of unit to another in the same dimension.  NSUnitConverter is an abstract class that is meant to be subclassed.  There is no need to call these methods directly to do a conversion -- the correct way to convert a measurement is to use [NSMeasurement measurementByConvertingToUnit:].  measurementByConvertingToUnit: uses the following 2 methods internally to perform the conversion.
     
     When creating a custom unit converter, you must override these two methods to implement the conversion to and from a value in terms of a unit and the corresponding value in terms of the base unit of that unit's dimension in order for conversion to work correctly.
     */
    
    /*
     This method takes a value in terms of a unit and returns the corresponding value in terms of the base unit of the original unit's dimension.
     @param value Value in terms of the unit class
     @return Value in terms of the base unit
     */
    open func baseUnitValue(fromValue value: Double) -> Double {
        return value
    }
    
    
    /*
     This method takes in a value in terms of the base unit of a unit's dimension and returns the equivalent value in terms of the unit.
     @param baseUnitValue Value in terms of the base unit
     @return Value in terms of the unit class
     */
    open func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        return baseUnitValue
    }
}

open class UnitConverterLinear : UnitConverter, NSSecureCoding {
    
    
    open private(set) var coefficient: Double
    
    open private(set) var constant: Double
    
    
    public convenience init(coefficient: Double) {
        self.init(coefficient: coefficient, constant: 0)
    }
    
    
    public init(coefficient: Double, constant: Double) {
        self.coefficient = coefficient
        self.constant = constant
    }
    
    open override func baseUnitValue(fromValue value: Double) -> Double {
        return value * coefficient + constant
    }
    
    open override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        return (baseUnitValue - constant) / coefficient
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let coefficient = aDecoder.decodeDouble(forKey: "NS.coefficient")
        let constant = aDecoder.decodeDouble(forKey: "NS.constant")
        self.init(coefficient: coefficient, constant: constant)
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.coefficient, forKey:"NS.coefficient")
        aCoder.encode(self.constant, forKey:"NS.constant")
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitConverterLinear else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return self.coefficient == other.coefficient
            && self.constant == other.constant
    }
}

private class UnitConverterReciprocal : UnitConverter, NSSecureCoding {
    
    
    private private(set) var reciprocal: Double
    
    
    fileprivate init(reciprocal: Double) {
        self.reciprocal = reciprocal
    }
    
    fileprivate override func baseUnitValue(fromValue value: Double) -> Double {
        return reciprocal / value
    }
    
    fileprivate override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        return reciprocal / baseUnitValue
    }
    
    fileprivate required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let reciprocal = aDecoder.decodeDouble(forKey: "NS.reciprocal")
        self.init(reciprocal: reciprocal)
    }
    
    fileprivate func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.reciprocal, forKey:"NS.reciprocal")
    }
    
    fileprivate static var supportsSecureCoding: Bool { return true }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitConverterReciprocal else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return self.reciprocal == other.reciprocal
    }
}

/*
 NSUnit is the base class for all unit types (dimensional and dimensionless).
 */

open class Unit : NSObject, NSCopying, NSSecureCoding {
    
    
    open private(set) var symbol: String
    
    
    public required init(symbol: String) {
        self.symbol = symbol
    }
    
    open func copy(with zone: NSZone?) -> Any {
        return self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard let symbol = aDecoder.decodeObject(forKey: "NS.symbol") as? String
            else { return nil }
        self.symbol = symbol
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.symbol._bridgeToObjectiveC(), forKey:"NS.symbol")
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Unit else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return self.symbol == other.symbol
    }
}

open class Dimension : Unit {
    
    
    open private(set) var converter: UnitConverter
    
    public required init(symbol: String, converter: UnitConverter) {
        self.converter = converter
        super.init(symbol: symbol)
    }
    
    /*
     This class method returns an instance of the dimension class that represents the base unit of that dimension.
     e.g.
     NSUnitSpeed *metersPerSecond = [NSUnitSpeed baseUnit];
     */
    open class func baseUnit() -> Self {
        fatalError("*** You must override baseUnit in your class to define its base unit.")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard
            let symbol = aDecoder.decodeObject(forKey: "NS.symbol") as? String,
            let converter = aDecoder.decodeObject(forKey: "NS.converter") as? UnitConverter
            else { return nil }
        self.converter = converter
        super.init(symbol: symbol)
    }
    
    public required init(symbol: String) {
        let T = type(of: self)
        fatalError("\(T) must be initialized with designated initializer \(T).init(symbol: String, converter: UnitConverter)")
    }
    
    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.converter, forKey:"converter")
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Dimension else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object) && self.converter == other.converter
    }
}

open class UnitAcceleration : Dimension {
    
    /*
     Base unit - metersPerSecondSquared
     */
    
    private struct Symbol {
        static let metersPerSecondSquared   = "m/s²"
        static let gravity                  = "g"
    }
    
    private struct Coefficient {
        static let metersPerSecondSquared   = 1.0
        static let gravity                  = 9.81
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var metersPerSecondSquared: UnitAcceleration {
        get {
            return UnitAcceleration(symbol: Symbol.metersPerSecondSquared, coefficient: Coefficient.metersPerSecondSquared)
        }
    }
    
    open class var gravity: UnitAcceleration {
        get {
            return UnitAcceleration(symbol: Symbol.gravity, coefficient: Coefficient.gravity)
        }
    }
    
    open override class func baseUnit() -> UnitAcceleration {
        return .metersPerSecondSquared
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitAcceleration else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitAngle : Dimension {
    
    /*
     Base unit - degrees
     */
    
    private struct Symbol {
        static let degrees      = "°"
        static let arcMinutes   = "ʹ"
        static let arcSeconds   = "ʹʹ"
        static let radians      = "rad"
        static let gradians     = "grad"
        static let revolutions  = "rev"
    }
    
    private struct Coefficient {
        static let degrees      = 1.0
        static let arcMinutes   = 1.0 / 60.0
        static let arcSeconds   = 1.0 / 3600.0
        static let radians      = 180.0 / .pi
        static let gradians     = 0.9
        static let revolutions  = 360.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var degrees: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.degrees, coefficient: Coefficient.degrees)
        }
    }
    
    open class var arcMinutes: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.arcMinutes, coefficient: Coefficient.arcMinutes)
        }
    }
    
    open class var arcSeconds: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.arcSeconds, coefficient: Coefficient.arcSeconds)
        }
    }
    
    open class var radians: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.radians, coefficient: Coefficient.radians)
        }
    }
    
    open class var gradians: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.gradians, coefficient: Coefficient.gradians)
        }
    }
    
    open class var revolutions: UnitAngle {
        get {
            return UnitAngle(symbol: Symbol.revolutions, coefficient: Coefficient.revolutions)
        }
    }
    
    open override class func baseUnit() -> UnitAngle {
        return .degrees
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitAngle else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitArea : Dimension {
    
    /*
     Base unit - squareMeters
     */
    
    private struct Symbol {
        static let squareMegameters     = "Mm²"
        static let squareKilometers     = "km²"
        static let squareMeters         = "m²"
        static let squareCentimeters    = "cm²"
        static let squareMillimeters    = "mm²"
        static let squareMicrometers    = "µm²"
        static let squareNanometers     = "nm²"
        static let squareInches         = "in²"
        static let squareFeet           = "ft²"
        static let squareYards          = "yd²"
        static let squareMiles          = "mi²"
        static let acres                = "ac"
        static let ares                 = "a"
        static let hectares             = "ha"
    }
    
    private struct Coefficient {
        static let squareMegameters     = 1e12
        static let squareKilometers     = 1e6
        static let squareMeters         = 1.0
        static let squareCentimeters    = 1e-4
        static let squareMillimeters    = 1e-6
        static let squareMicrometers    = 1e-12
        static let squareNanometers     = 1e-18
        static let squareInches         = 0.00064516
        static let squareFeet           = 0.092903
        static let squareYards          = 0.836127
        static let squareMiles          = 2.59e+6
        static let acres                = 4046.86
        static let ares                 = 100.0
        static let hectares             = 10000.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var squareMegameters: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareMegameters, coefficient: Coefficient.squareMegameters)
        }
    }
    
    open class var squareKilometers: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareKilometers, coefficient: Coefficient.squareKilometers)
        }
    }
    
    open class var squareMeters: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareMeters, coefficient: Coefficient.squareMeters)
        }
    }
    
    open class var squareCentimeters: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareCentimeters, coefficient: Coefficient.squareCentimeters)
        }
    }
    
    open class var squareMillimeters: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareMillimeters, coefficient: Coefficient.squareMillimeters)
        }
    }
    
    open class var squareMicrometers: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareMicrometers, coefficient: Coefficient.squareMicrometers)
        }
    }
    
    open class var squareNanometers: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareNanometers, coefficient: Coefficient.squareNanometers)
        }
    }
    
    open class var squareInches: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareInches, coefficient: Coefficient.squareInches)
        }
    }
    
    open class var squareFeet: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareFeet, coefficient: Coefficient.squareFeet)
        }
    }
    
    open class var squareYards: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareYards, coefficient: Coefficient.squareYards)
        }
    }
    
    open class var squareMiles: UnitArea {
        get {
            return UnitArea(symbol: Symbol.squareMiles, coefficient: Coefficient.squareMiles)
        }
    }
    
    open class var acres: UnitArea {
        get {
            return UnitArea(symbol: Symbol.acres, coefficient: Coefficient.acres)
        }
    }
    
    open class var ares: UnitArea {
        get {
            return UnitArea(symbol: Symbol.ares, coefficient: Coefficient.ares)
        }
    }
    
    open class var hectares: UnitArea {
        get {
            return UnitArea(symbol: Symbol.hectares, coefficient: Coefficient.hectares)
        }
    }
    
    open override class func baseUnit() -> UnitArea {
        return .squareMeters
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitArea else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitConcentrationMass : Dimension {
    
    /*
     Base unit - gramsPerLiter
     */
    
    private struct Symbol {
        static let gramsPerLiter            = "g/L"
        static let milligramsPerDeciliter   = "mg/dL"
        static let millimolesPerLiter       = "mmol/L"
    }
    
    private struct Coefficient {
        static let gramsPerLiter            = 1.0
        static let milligramsPerDeciliter   = 0.01
        static let millimolesPerLiter       = 18.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var gramsPerLiter: UnitConcentrationMass {
        get {
            return UnitConcentrationMass(symbol: Symbol.gramsPerLiter, coefficient: Coefficient.gramsPerLiter)
        }
    }
    
    open class var milligramsPerDeciliter: UnitConcentrationMass {
        get {
            return UnitConcentrationMass(symbol: Symbol.milligramsPerDeciliter, coefficient: Coefficient.milligramsPerDeciliter)
        }
    }
    
    open class func millimolesPerLiter(withGramsPerMole gramsPerMole: Double) -> UnitConcentrationMass {
        return UnitConcentrationMass(symbol: Symbol.millimolesPerLiter, coefficient: Coefficient.millimolesPerLiter * gramsPerMole)
    }
    
    open override class func baseUnit() -> UnitConcentrationMass {
        return UnitConcentrationMass.gramsPerLiter
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitConcentrationMass else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitDispersion : Dimension {
    
    /*
     Base unit - partsPerMillion
     */
    
    private struct Symbol {
        static let partsPerMillion  = "ppm"
    }
    
    private struct Coefficient {
        static let partsPerMillion  = 1.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var partsPerMillion: UnitDispersion {
        get {
            return UnitDispersion(symbol: Symbol.partsPerMillion, coefficient: Coefficient.partsPerMillion)
        }
    }
    
    open override class func baseUnit() -> UnitDispersion {
        return .partsPerMillion
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitDispersion else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitDuration : Dimension {
    
    /*
     Base unit - seconds
     */
    
    private struct Symbol {
        static let seconds  = "s"
        static let minutes  = "m"
        static let hours    = "h"
    }
    
    private struct Coefficient {
        static let seconds  = 1.0
        static let minutes  = 60.0
        static let hours    = 3600.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var seconds: UnitDuration {
        get {
            return UnitDuration(symbol: Symbol.seconds, coefficient: Coefficient.seconds)
        }
    }
    
    open class var minutes: UnitDuration {
        get {
            return UnitDuration(symbol: Symbol.minutes, coefficient: Coefficient.minutes)
        }
    }
    
    open class var hours: UnitDuration {
        get {
            return UnitDuration(symbol: Symbol.hours, coefficient: Coefficient.hours)
        }
    }
    
    open override class func baseUnit() -> UnitDuration {
        return .seconds
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitDuration else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitElectricCharge : Dimension {
    /*
     Base unit - coulombs
     */
    
    private struct Symbol {
        static let coulombs         = "C"
        static let megaampereHours  = "MAh"
        static let kiloampereHours  = "kAh"
        static let ampereHours      = "Ah"
        static let milliampereHours = "mAh"
        static let microampereHours = "µAh"
    }
    
    private struct Coefficient {
        static let coulombs         = 1.0
        static let megaampereHours  = 3.6e9
        static let kiloampereHours  = 3600000.0
        static let ampereHours      = 3600.0
        static let milliampereHours = 3.6
        static let microampereHours = 0.0036
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var coulombs: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.coulombs, coefficient: Coefficient.coulombs)
        }
    }
    
    open class var megaampereHours: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.megaampereHours, coefficient: Coefficient.megaampereHours)
        }
    }
    
    open class var kiloampereHours: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.kiloampereHours, coefficient: Coefficient.kiloampereHours)
        }
    }
    
    open class var ampereHours: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.ampereHours, coefficient: Coefficient.ampereHours)
        }
    }
    
    open class var milliampereHours: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.milliampereHours, coefficient: Coefficient.milliampereHours)
        }
    }
    
    open class var microampereHours: UnitElectricCharge {
        get {
            return UnitElectricCharge(symbol: Symbol.microampereHours, coefficient: Coefficient.microampereHours)
        }
    }
    
    open override class func baseUnit() -> UnitElectricCharge {
        return .coulombs
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricCharge else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitElectricCurrent : Dimension {
    
    /*
     Base unit - amperes
     */
    
    private struct Symbol {
        static let megaamperes  = "MA"
        static let kiloamperes  = "kA"
        static let amperes      = "A"
        static let milliamperes = "mA"
        static let microamperes = "µA"
    }
    
    private struct Coefficient {
        static let megaamperes  = 1e6
        static let kiloamperes  = 1e3
        static let amperes      = 1.0
        static let milliamperes = 1e-3
        static let microamperes = 1e-6
        
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var megaamperes: UnitElectricCurrent {
        get {
            return UnitElectricCurrent(symbol: Symbol.megaamperes, coefficient: Coefficient.megaamperes)
        }
    }
    
    open class var kiloamperes: UnitElectricCurrent {
        get {
            return UnitElectricCurrent(symbol: Symbol.kiloamperes, coefficient: Coefficient.kiloamperes)
        }
    }
    
    open class var amperes: UnitElectricCurrent {
        get {
            return UnitElectricCurrent(symbol: Symbol.amperes, coefficient: Coefficient.amperes)
        }
    }
    
    open class var milliamperes: UnitElectricCurrent {
        get {
            return UnitElectricCurrent(symbol: Symbol.milliamperes, coefficient: Coefficient.milliamperes)
        }
    }
    
    open class var microamperes: UnitElectricCurrent {
        get {
            return UnitElectricCurrent(symbol: Symbol.microamperes, coefficient: Coefficient.microamperes)
        }
    }
    
    open override class func baseUnit() -> UnitElectricCurrent {
        return .amperes
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricCurrent else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitElectricPotentialDifference : Dimension {
    
    /*
     Base unit - volts
     */
    
    private struct Symbol {
        static let megavolts  = "MV"
        static let kilovolts  = "kV"
        static let volts      = "V"
        static let millivolts = "mV"
        static let microvolts = "µV"
    }
    
    private struct Coefficient {
        static let megavolts  = 1e6
        static let kilovolts  = 1e3
        static let volts      = 1.0
        static let millivolts = 1e-3
        static let microvolts = 1e-6
        
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var megavolts: UnitElectricPotentialDifference {
        get {
            return UnitElectricPotentialDifference(symbol: Symbol.megavolts, coefficient: Coefficient.megavolts)
        }
    }
    
    open class var kilovolts: UnitElectricPotentialDifference {
        get {
            return UnitElectricPotentialDifference(symbol: Symbol.kilovolts, coefficient: Coefficient.kilovolts)
        }
    }
    
    open class var volts: UnitElectricPotentialDifference {
        get {
            return UnitElectricPotentialDifference(symbol: Symbol.volts, coefficient: Coefficient.volts)
        }
    }
    
    open class var millivolts: UnitElectricPotentialDifference {
        get {
            return UnitElectricPotentialDifference(symbol: Symbol.millivolts, coefficient: Coefficient.millivolts)
        }
    }
    
    open class var microvolts: UnitElectricPotentialDifference {
        get {
            return UnitElectricPotentialDifference(symbol: Symbol.microvolts, coefficient: Coefficient.microvolts)
        }
    }
    
    open override class func baseUnit() -> UnitElectricPotentialDifference {
        return .volts
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricPotentialDifference else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitElectricResistance : Dimension {
    
    /*
     Base unit - ohms
     */
    
    private struct Symbol {
        static let megaohms  = "MΩ"
        static let kiloohms  = "kΩ"
        static let ohms      = "Ω"
        static let milliohms = "mΩ"
        static let microohms = "µΩ"
    }
    
    private struct Coefficient {
        static let megaohms  = 1e6
        static let kiloohms  = 1e3
        static let ohms      = 1.0
        static let milliohms = 1e-3
        static let microohms = 1e-6
        
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var megaohms: UnitElectricResistance {
        get {
            return UnitElectricResistance(symbol: Symbol.megaohms, coefficient: Coefficient.megaohms)
        }
    }
    
    open class var kiloohms: UnitElectricResistance {
        get {
            return UnitElectricResistance(symbol: Symbol.kiloohms, coefficient: Coefficient.kiloohms)
        }
    }
    
    open class var ohms: UnitElectricResistance {
        get {
            return UnitElectricResistance(symbol: Symbol.ohms, coefficient: Coefficient.ohms)
        }
    }
    
    open class var milliohms: UnitElectricResistance {
        get {
            return UnitElectricResistance(symbol: Symbol.milliohms, coefficient: Coefficient.milliohms)
        }
    }
    
    open class var microohms: UnitElectricResistance {
        get {
            return UnitElectricResistance(symbol: Symbol.microohms, coefficient: Coefficient.microohms)
        }
    }
    
    open override class func baseUnit() -> UnitElectricResistance {
        return .ohms
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricResistance else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitEnergy : Dimension {
    
    /*
     Base unit - joules
     */
    
    private struct Symbol {
        static let kilojoules       = "kJ"
        static let joules           = "J"
        static let kilocalories     = "kCal"
        static let calories         = "cal"
        static let kilowattHours    = "kWh"
    }
    
    private struct Coefficient {
        static let kilojoules       = 1e3
        static let joules           = 1.0
        static let kilocalories     = 4184.0
        static let calories         = 4.184
        static let kilowattHours    = 3600000.0
        
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var kilojoules: UnitEnergy {
        get {
            return UnitEnergy(symbol: Symbol.kilojoules, coefficient: Coefficient.kilojoules)
        }
    }
    
    open class var joules: UnitEnergy {
        get {
            return UnitEnergy(symbol: Symbol.joules, coefficient: Coefficient.joules)
        }
    }
    
    open class var kilocalories: UnitEnergy {
        get {
            return UnitEnergy(symbol: Symbol.kilocalories, coefficient: Coefficient.kilocalories)
        }
    }
    
    open class var calories: UnitEnergy {
        get {
            return UnitEnergy(symbol: Symbol.calories, coefficient: Coefficient.calories)
        }
    }
    
    open class var kilowattHours: UnitEnergy {
        get {
            return UnitEnergy(symbol: Symbol.kilowattHours, coefficient: Coefficient.kilowattHours)
        }
    }
    
    open override class func baseUnit() -> UnitEnergy {
        return .joules
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitEnergy else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitFrequency : Dimension {
    
    /*
     Base unit - hertz
     */
    
    private struct Symbol {
        static let terahertz    = "THz"
        static let gigahertz    = "GHz"
        static let megahertz    = "MHz"
        static let kilohertz    = "kHz"
        static let hertz        = "Hz"
        static let millihertz   = "mHz"
        static let microhertz   = "µHz"
        static let nanohertz    = "nHz"
    }
    
    private struct Coefficient {
        static let terahertz    = 1e12
        static let gigahertz    = 1e9
        static let megahertz    = 1e6
        static let kilohertz    = 1e3
        static let hertz        = 1.0
        static let millihertz   = 1e-3
        static let microhertz   = 1e-6
        static let nanohertz    = 1e-9
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var terahertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.terahertz, coefficient: Coefficient.terahertz)
        }
    }
    
    open class var gigahertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.gigahertz, coefficient: Coefficient.gigahertz)
        }
    }
    
    open class var megahertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.megahertz, coefficient: Coefficient.megahertz)
        }
    }
    
    open class var kilohertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.kilohertz, coefficient: Coefficient.kilohertz)
        }
    }
    
    open class var hertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.hertz, coefficient: Coefficient.hertz)
        }
    }
    
    open class var millihertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.millihertz, coefficient: Coefficient.millihertz)
        }
    }
    
    open class var microhertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.microhertz, coefficient: Coefficient.microhertz)
        }
    }
    
    open class var nanohertz: UnitFrequency {
        get {
            return UnitFrequency(symbol: Symbol.nanohertz, coefficient: Coefficient.nanohertz)
        }
    }
    
    open override class func baseUnit() -> UnitFrequency {
        return .hertz
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitFrequency else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitFuelEfficiency : Dimension {
    
    /*
     Base unit - litersPer100Kilometers
     */
    
    private struct Symbol {
        static let litersPer100Kilometers   = "L/100km"
        static let milesPerImperialGallon   = "mpg"
        static let milesPerGallon           = "mpg"
    }
    
    private struct Coefficient {
        static let litersPer100Kilometers   = 1.0
        static let milesPerImperialGallon   = 282.481
        static let milesPerGallon           = 235.215
    }
    
    private convenience init(symbol: String, reciprocal: Double) {
        self.init(symbol: symbol, converter: UnitConverterReciprocal(reciprocal: reciprocal))
    }
    
    open class var litersPer100Kilometers: UnitFuelEfficiency {
        get {
            return UnitFuelEfficiency(symbol: Symbol.litersPer100Kilometers, reciprocal: Coefficient.litersPer100Kilometers)
        }
    }
    
    open class var milesPerImperialGallon: UnitFuelEfficiency {
        get {
            return UnitFuelEfficiency(symbol: Symbol.milesPerImperialGallon, reciprocal: Coefficient.milesPerImperialGallon)
        }
    }
    
    open class var milesPerGallon: UnitFuelEfficiency {
        get {
            return UnitFuelEfficiency(symbol: Symbol.milesPerGallon, reciprocal: Coefficient.milesPerGallon)
        }
    }
    
    open override class func baseUnit() -> UnitFuelEfficiency {
        return .litersPer100Kilometers
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitFuelEfficiency else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitLength : Dimension {
    
    /*
     Base unit - meters
     */
    
    private struct Symbol {
        static let megameters           = "Mm"
        static let kilometers           = "km"
        static let hectometers          = "hm"
        static let decameters           = "dam"
        static let meters               = "m"
        static let decimeters           = "dm"
        static let centimeters          = "cm"
        static let millimeters          = "mm"
        static let micrometers          = "µm"
        static let nanometers           = "nm"
        static let picometers           = "pm"
        static let inches               = "in"
        static let feet                 = "ft"
        static let yards                = "yd"
        static let miles                = "mi"
        static let scandinavianMiles    = "smi"
        static let lightyears           = "ly"
        static let nauticalMiles        = "NM"
        static let fathoms              = "ftm"
        static let furlongs             = "fur"
        static let astronomicalUnits    = "ua"
        static let parsecs              = "pc"
    }
    
    private struct Coefficient {
        static let megameters           = 1e6
        static let kilometers           = 1e3
        static let hectometers          = 1e2
        static let decameters           = 1e1
        static let meters               = 1.0
        static let decimeters           = 1e-1
        static let centimeters          = 1e-2
        static let millimeters          = 1e-3
        static let micrometers          = 1e-6
        static let nanometers           = 1e-9
        static let picometers           = 1e-12
        static let inches               = 0.0254
        static let feet                 = 0.3048
        static let yards                = 0.9144
        static let miles                = 1609.34
        static let scandinavianMiles    = 10000.0
        static let lightyears           = 9.461e+15
        static let nauticalMiles        = 1852.0
        static let fathoms              = 1.8288
        static let furlongs             = 201.168
        static let astronomicalUnits    = 1.496e+11
        static let parsecs              = 3.086e+16
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var megameters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.megameters, coefficient: Coefficient.megameters)
        }
    }
    
    open class var kilometers: UnitLength {
        get {
            return UnitLength(symbol: Symbol.kilometers, coefficient: Coefficient.kilometers)
        }
    }
    
    open class var hectometers: UnitLength {
        get {
            return UnitLength(symbol: Symbol.hectometers, coefficient: Coefficient.hectometers)
        }
    }
    
    open class var decameters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.decameters, coefficient: Coefficient.decameters)
        }
    }
    
    open class var meters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.meters, coefficient: Coefficient.meters)
        }
    }
    
    open class var decimeters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.decimeters, coefficient: Coefficient.decimeters)
        }
    }
    
    open class var centimeters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.centimeters, coefficient: Coefficient.centimeters)
        }
    }
    
    open class var millimeters: UnitLength {
        get {
            return UnitLength(symbol: Symbol.millimeters, coefficient: Coefficient.millimeters)
        }
    }
    
    open class var micrometers: UnitLength {
        get {
            return UnitLength(symbol: Symbol.micrometers, coefficient: Coefficient.micrometers)
        }
    }
    
    open class var nanometers: UnitLength {
        get {
            return UnitLength(symbol: Symbol.nanometers, coefficient: Coefficient.nanometers)
        }
    }
    
    open class var picometers: UnitLength {
        get {
            return UnitLength(symbol: Symbol.picometers, coefficient: Coefficient.picometers)
        }
    }
    
    open class var inches: UnitLength {
        get {
            return UnitLength(symbol: Symbol.inches, coefficient: Coefficient.inches)
        }
    }
    
    open class var feet: UnitLength {
        get {
            return UnitLength(symbol: Symbol.feet, coefficient: Coefficient.feet)
        }
    }
    
    open class var yards: UnitLength {
        get {
            return UnitLength(symbol: Symbol.yards, coefficient: Coefficient.yards)
        }
    }
    
    open class var miles: UnitLength {
        get {
            return UnitLength(symbol: Symbol.miles, coefficient: Coefficient.miles)
        }
    }
    
    open class var scandinavianMiles: UnitLength {
        get {
            return UnitLength(symbol: Symbol.scandinavianMiles, coefficient: Coefficient.scandinavianMiles)
        }
    }
    
    open class var lightyears: UnitLength {
        get {
            return UnitLength(symbol: Symbol.lightyears, coefficient: Coefficient.lightyears)
        }
    }
    
    open class var nauticalMiles: UnitLength {
        get {
            return UnitLength(symbol: Symbol.nauticalMiles, coefficient: Coefficient.nauticalMiles)
        }
    }
    
    open class var fathoms: UnitLength {
        get {
            return UnitLength(symbol: Symbol.fathoms, coefficient: Coefficient.fathoms)
        }
    }
    
    open class var furlongs: UnitLength {
        get {
            return UnitLength(symbol: Symbol.furlongs, coefficient: Coefficient.furlongs)
        }
    }
    
    open class var astronomicalUnits: UnitLength {
        get {
            return UnitLength(symbol: Symbol.astronomicalUnits, coefficient: Coefficient.astronomicalUnits)
        }
    }
    
    open class var parsecs: UnitLength {
        get {
            return UnitLength(symbol: Symbol.parsecs, coefficient: Coefficient.parsecs)
        }
    }
    
    open override class func baseUnit() -> UnitLength {
        return .meters
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitLength else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitIlluminance : Dimension {
    
    /*
     Base unit - lux
     */
    
    private struct Symbol {
        static let lux   = "lx"
    }
    
    private struct Coefficient {
        static let lux   = 1.0
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var lux: UnitIlluminance {
        get {
            return UnitIlluminance(symbol: Symbol.lux, coefficient: Coefficient.lux)
        }
    }
    
    open override class func baseUnit() -> UnitIlluminance {
        return .lux
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitIlluminance else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitMass : Dimension {
    
    /*
     Base unit - kilograms
     */
    
    private struct Symbol {
        static let kilograms    = "kg"
        static let grams        = "g"
        static let decigrams    = "dg"
        static let centigrams   = "cg"
        static let milligrams   = "mg"
        static let micrograms   = "µg"
        static let nanograms    = "ng"
        static let picograms    = "pg"
        static let ounces       = "oz"
        static let pounds       = "lb"
        static let stones       = "st"
        static let metricTons   = "t"
        static let shortTons    = "ton"
        static let carats       = "ct"
        static let ouncesTroy   = "oz t"
        static let slugs        = "slug"
    }
    
    private struct Coefficient {
        static let kilograms    = 1.0
        static let grams        = 1e-3
        static let decigrams    = 1e-4
        static let centigrams   = 1e-5
        static let milligrams   = 1e-6
        static let micrograms   = 1e-9
        static let nanograms    = 1e-12
        static let picograms    = 1e-15
        static let ounces       = 0.0283495
        static let pounds       = 0.453592
        static let stones       = 0.157473
        static let metricTons   = 1000.0
        static let shortTons    = 907.185
        static let carats       = 0.0002
        static let ouncesTroy   = 0.03110348
        static let slugs        = 14.5939
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var kilograms: UnitMass {
        get {
            return UnitMass(symbol: Symbol.kilograms, coefficient: Coefficient.kilograms)
        }
    }
    
    open class var grams: UnitMass {
        get {
            return UnitMass(symbol: Symbol.grams, coefficient: Coefficient.grams)
        }
    }
    
    open class var decigrams: UnitMass {
        get {
            return UnitMass(symbol: Symbol.decigrams, coefficient: Coefficient.decigrams)
        }
    }
    
    open class var centigrams: UnitMass {
        get {
            return UnitMass(symbol: Symbol.centigrams, coefficient: Coefficient.centigrams)
        }
    }
    
    open class var milligrams: UnitMass {
        get {
            return UnitMass(symbol: Symbol.milligrams, coefficient: Coefficient.milligrams)
        }
    }
    
    open class var micrograms: UnitMass {
        get {
            return UnitMass(symbol: Symbol.micrograms, coefficient: Coefficient.micrograms)
        }
    }
    
    open class var nanograms: UnitMass {
        get {
            return UnitMass(symbol: Symbol.nanograms, coefficient: Coefficient.nanograms)
        }
    }
    
    open class var picograms: UnitMass {
        get {
            return UnitMass(symbol: Symbol.picograms, coefficient: Coefficient.picograms)
        }
    }
    
    open class var ounces: UnitMass {
        get {
            return UnitMass(symbol: Symbol.ounces, coefficient: Coefficient.ounces)
        }
    }
    
    open class var pounds: UnitMass {
        get {
            return UnitMass(symbol: Symbol.pounds, coefficient: Coefficient.pounds)
        }
    }
    
    open class var stones: UnitMass {
        get {
            return UnitMass(symbol: Symbol.stones, coefficient: Coefficient.stones)
        }
    }
    
    open class var metricTons: UnitMass {
        get {
            return UnitMass(symbol: Symbol.metricTons, coefficient: Coefficient.metricTons)
        }
    }
    
    open class var shortTons: UnitMass {
        get {
            return UnitMass(symbol: Symbol.shortTons, coefficient: Coefficient.shortTons)
        }
    }
    
    open class var carats: UnitMass {
        get {
            return UnitMass(symbol: Symbol.carats, coefficient: Coefficient.carats)
        }
    }
    
    open class var ouncesTroy: UnitMass {
        get {
            return UnitMass(symbol: Symbol.ouncesTroy, coefficient: Coefficient.ouncesTroy)
        }
    }
    
    open class var slugs: UnitMass {
        get {
            return UnitMass(symbol: Symbol.slugs, coefficient: Coefficient.slugs)
        }
    }
    
    open override class func baseUnit() -> UnitMass {
        return .kilograms
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitMass else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitPower : Dimension {
    
    /*
     Base unit - watts
     */
    
    private struct Symbol {
        static let terawatts  = "TW"
        static let gigawatts  = "GW"
        static let megawatts  = "MW"
        static let kilowatts  = "kW"
        static let watts      = "W"
        static let milliwatts = "mW"
        static let microwatts = "µW"
        static let nanowatts  = "nW"
        static let picowatts  = "pW"
        static let femtowatts = "fW"
        static let horsepower = "hp"
    }
    
    private struct Coefficient {
        static let terawatts  = 1e12
        static let gigawatts  = 1e9
        static let megawatts  = 1e6
        static let kilowatts  = 1e3
        static let watts      = 1.0
        static let milliwatts = 1e-3
        static let microwatts = 1e-6
        static let nanowatts  = 1e-9
        static let picowatts  = 1e-12
        static let femtowatts = 1e-15
        static let horsepower = 745.7
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var terawatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.terawatts, coefficient: Coefficient.terawatts)
        }
    }
    
    open class var gigawatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.gigawatts, coefficient: Coefficient.gigawatts)
        }
    }
    
    open class var megawatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.megawatts, coefficient: Coefficient.megawatts)
        }
    }
    
    open class var kilowatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.kilowatts, coefficient: Coefficient.kilowatts)
        }
    }
    
    open class var watts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.watts, coefficient: Coefficient.watts)
        }
    }
    
    open class var milliwatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.milliwatts, coefficient: Coefficient.milliwatts)
        }
    }
    
    open class var microwatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.microwatts, coefficient: Coefficient.microwatts)
        }
    }
    
    open class var nanowatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.nanowatts, coefficient: Coefficient.nanowatts)
        }
    }
    
    open class var picowatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.picowatts, coefficient: Coefficient.picowatts)
        }
    }
    
    open class var femtowatts: UnitPower {
        get {
            return UnitPower(symbol: Symbol.femtowatts, coefficient: Coefficient.femtowatts)
        }
    }
    
    open class var horsepower: UnitPower {
        get {
            return UnitPower(symbol: Symbol.horsepower, coefficient: Coefficient.horsepower)
        }
    }
    
    open override class func baseUnit() -> UnitPower {
        return .watts
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitPower else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitPressure : Dimension {
    
    /*
     Base unit - newtonsPerMetersSquared (equivalent to 1 pascal)
     */
    
    private struct Symbol {
        static let newtonsPerMetersSquared  = "N/m²"
        static let gigapascals              = "GPa"
        static let megapascals              = "MPa"
        static let kilopascals              = "kPa"
        static let hectopascals             = "hPa"
        static let inchesOfMercury          = "inHg"
        static let bars                     = "bar"
        static let millibars                = "mbar"
        static let millimetersOfMercury     = "mmHg"
        static let poundsForcePerSquareInch = "psi"
    }
    
    private struct Coefficient {
        static let newtonsPerMetersSquared  = 1.0
        static let gigapascals              = 1e9
        static let megapascals              = 1e6
        static let kilopascals              = 1e3
        static let hectopascals             = 1e2
        static let inchesOfMercury          = 3386.39
        static let bars                     = 1e5
        static let millibars                = 1e2
        static let millimetersOfMercury     = 133.322
        static let poundsForcePerSquareInch = 6894.76
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var newtonsPerMetersSquared: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.newtonsPerMetersSquared, coefficient: Coefficient.newtonsPerMetersSquared)
        }
    }
    
    open class var gigapascals: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.gigapascals, coefficient: Coefficient.gigapascals)
        }
    }
    
    open class var megapascals: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.megapascals, coefficient: Coefficient.megapascals)
        }
    }
    
    open class var kilopascals: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.kilopascals, coefficient: Coefficient.kilopascals)
        }
    }
    
    open class var hectopascals: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.hectopascals, coefficient: Coefficient.hectopascals)
        }
    }
    
    open class var inchesOfMercury: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.inchesOfMercury, coefficient: Coefficient.inchesOfMercury)
        }
    }
    
    open class var bars: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.bars, coefficient: Coefficient.bars)
        }
    }
    
    open class var millibars: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.millibars, coefficient: Coefficient.millibars)
        }
    }
    
    open class var millimetersOfMercury: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.millimetersOfMercury, coefficient: Coefficient.millimetersOfMercury)
        }
    }
    
    open class var poundsForcePerSquareInch: UnitPressure {
        get {
            return UnitPressure(symbol: Symbol.poundsForcePerSquareInch, coefficient: Coefficient.poundsForcePerSquareInch)
        }
    }
    
    open override class func baseUnit() -> UnitPressure {
        return .newtonsPerMetersSquared
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitPressure else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitSpeed : Dimension {
    
    /*
     Base unit - metersPerSecond
     */
    
    private struct Symbol {
        static let metersPerSecond      = "m/s"
        static let kilometersPerHour    = "km/h"
        static let milesPerHour         = "mph"
        static let knots                = "kn"
    }
    
    private struct Coefficient {
        static let metersPerSecond      = 1.0
        static let kilometersPerHour    = 0.277778
        static let milesPerHour         = 0.44704
        static let knots                = 0.514444
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var metersPerSecond: UnitSpeed {
        get {
            return UnitSpeed(symbol: Symbol.metersPerSecond, coefficient: Coefficient.metersPerSecond)
        }
    }
    
    open class var kilometersPerHour: UnitSpeed {
        get {
            return UnitSpeed(symbol: Symbol.kilometersPerHour, coefficient: Coefficient.kilometersPerHour)
        }
    }
    
    open class var milesPerHour: UnitSpeed {
        get {
            return UnitSpeed(symbol: Symbol.milesPerHour, coefficient: Coefficient.milesPerHour)
        }
    }
    
    open class var knots: UnitSpeed {
        get {
            return UnitSpeed(symbol: Symbol.knots, coefficient: Coefficient.knots)
        }
    }
    
    open override class func baseUnit() -> UnitSpeed {
        return .metersPerSecond
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitSpeed else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitTemperature : Dimension {
    
    /*
     Base unit - kelvin
     */
    
    private struct Symbol {
        static let kelvin     = "K"
        static let celsius    = "°C"
        static let fahrenheit = "°F"
    }
    
    private struct Coefficient {
        static let kelvin     = 1.0
        static let celsius    = 1.0
        static let fahrenheit = 0.55555555555556
    }
    
    private struct Constant {
        static let kelvin     = 0.0
        static let celsius    = 273.15
        static let fahrenheit = 255.37222222222427
    }
    
    private convenience init(symbol: String, coefficient: Double, constant: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient, constant: constant))
    }
    
    open class var kelvin: UnitTemperature {
        get {
            return UnitTemperature(symbol: Symbol.kelvin, coefficient: Coefficient.kelvin, constant: Constant.kelvin)
        }
    }
    
    open class var celsius: UnitTemperature {
        get {
            return UnitTemperature(symbol: Symbol.celsius, coefficient: Coefficient.celsius, constant: Constant.celsius)
        }
    }
    
    open class var fahrenheit: UnitTemperature {
        get {
            return UnitTemperature(symbol: Symbol.fahrenheit, coefficient: Coefficient.fahrenheit, constant: Constant.fahrenheit)
        }
    }
    
    open override class func baseUnit() -> UnitTemperature {
        return .kelvin
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitTemperature else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

open class UnitVolume : Dimension {
    
    /*
     Base unit - liters
     */
    
    private struct Symbol {
        static let megaliters           = "ML"
        static let kiloliters           = "kL"
        static let liters               = "L"
        static let deciliters           = "dl"
        static let centiliters          = "cL"
        static let milliliters          = "mL"
        static let cubicKilometers      = "km³"
        static let cubicMeters          = "m³"
        static let cubicDecimeters      = "dm³"
        static let cubicCentimeters     = "cm³"
        static let cubicMillimeters     = "mm³"
        static let cubicInches          = "in³"
        static let cubicFeet            = "ft³"
        static let cubicYards           = "yd³"
        static let cubicMiles           = "mi³"
        static let acreFeet             = "af"
        static let bushels              = "bsh"
        static let teaspoons            = "tsp"
        static let tablespoons          = "tbsp"
        static let fluidOunces          = "fl oz"
        static let cups                 = "cup"
        static let pints                = "pt"
        static let quarts               = "qt"
        static let gallons              = "gal"
        static let imperialTeaspoons    = "tsp Imperial"
        static let imperialTablespoons  = "tbsp Imperial"
        static let imperialFluidOunces  = "fl oz Imperial"
        static let imperialPints        = "pt Imperial"
        static let imperialQuarts       = "qt Imperial"
        static let imperialGallons      = "gal Imperial"
        static let metricCups           = "metric cup Imperial"
    }
    
    private struct Coefficient {
        static let megaliters           = 1e6
        static let kiloliters           = 1e3
        static let liters               = 1.0
        static let deciliters           = 1e-1
        static let centiliters          = 1e-2
        static let milliliters          = 1e-3
        static let cubicKilometers      = 1e12
        static let cubicMeters          = 1000.0
        static let cubicDecimeters      = 1.0
        static let cubicCentimeters     = 0.01
        static let cubicMillimeters     = 0.001
        static let cubicInches          = 0.0163871
        static let cubicFeet            = 28.3168
        static let cubicYards           = 764.555
        static let cubicMiles           = 4.168e+12
        static let acreFeet             = 1.233e+6
        static let bushels              = 35.2391
        static let teaspoons            = 0.00492892
        static let tablespoons          = 0.0147868
        static let fluidOunces          = 0.0295735
        static let cups                 = 0.24
        static let pints                = 0.473176
        static let quarts               = 0.946353
        static let gallons              = 3.78541
        static let imperialTeaspoons    = 0.00591939
        static let imperialTablespoons  = 0.0177582
        static let imperialFluidOunces  = 0.0284131
        static let imperialPints        = 0.568261
        static let imperialQuarts       = 1.13652
        static let imperialGallons      = 4.54609
        static let metricCups           = 0.25
    }
    
    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }
    
    open class var megaliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.megaliters, coefficient: Coefficient.megaliters)
        }
    }
    
    open class var kiloliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.kiloliters, coefficient: Coefficient.kiloliters)
        }
    }
    
    open class var liters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.liters, coefficient: Coefficient.liters)
        }
    }
    
    open class var deciliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.deciliters, coefficient: Coefficient.deciliters)
        }
    }
    
    open class var centiliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.centiliters, coefficient: Coefficient.centiliters)
        }
    }
    
    open class var milliliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.milliliters, coefficient: Coefficient.milliliters)
        }
    }
    
    open class var cubicKilometers: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicKilometers, coefficient: Coefficient.cubicKilometers)
        }
    }
    
    open class var cubicMeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMeters, coefficient: Coefficient.cubicMeters)
        }
    }
    
    open class var cubicDecimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicDecimeters, coefficient: Coefficient.cubicDecimeters)
        }
    }
    
    open class var cubicCentimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicCentimeters, coefficient: Coefficient.cubicCentimeters)
        }
    }
    
    open class var cubicMillimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMillimeters, coefficient: Coefficient.cubicMillimeters)
        }
    }
    
    open class var cubicInches: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicInches, coefficient: Coefficient.cubicInches)
        }
    }
    
    open class var cubicFeet: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicFeet, coefficient: Coefficient.cubicFeet)
        }
    }
    
    open class var cubicYards: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicYards, coefficient: Coefficient.cubicYards)
        }
    }
    
    open class var cubicMiles: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMiles, coefficient: Coefficient.cubicMiles)
        }
    }
    
    open class var acreFeet: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.acreFeet, coefficient: Coefficient.acreFeet)
        }
    }
    
    open class var bushels: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.bushels, coefficient: Coefficient.bushels)
        }
    }
    
    open class var teaspoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.teaspoons, coefficient: Coefficient.teaspoons)
        }
    }
    
    open class var tablespoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.tablespoons, coefficient: Coefficient.tablespoons)
        }
    }
    
    open class var fluidOunces: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.fluidOunces, coefficient: Coefficient.fluidOunces)
        }
    }
    
    open class var cups: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cups, coefficient: Coefficient.cups)
        }
    }
    
    open class var pints: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.pints, coefficient: Coefficient.pints)
        }
    }
    
    open class var quarts: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.quarts, coefficient: Coefficient.quarts)
        }
    }
    
    open class var gallons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.gallons, coefficient: Coefficient.gallons)
        }
    }
    
    open class var imperialTeaspoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialTeaspoons, coefficient: Coefficient.imperialTeaspoons)
        }
    }
    
    open class var imperialTablespoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialTablespoons, coefficient: Coefficient.imperialTablespoons)
        }
    }
    
    open class var imperialFluidOunces: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialFluidOunces, coefficient: Coefficient.imperialFluidOunces)
        }
    }
    
    open class var imperialPints: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialPints, coefficient: Coefficient.imperialPints)
        }
    }
    
    open class var imperialQuarts: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialQuarts, coefficient: Coefficient.imperialQuarts)
        }
    }
    
    open class var imperialGallons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialGallons, coefficient: Coefficient.imperialGallons)
        }
    }
    
    open class var metricCups: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.metricCups, coefficient: Coefficient.metricCups)
        }
    }
    
    open override class func baseUnit() -> UnitVolume {
        return .liters
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitVolume else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}
