/*
 NSUnitConverter describes how to convert a unit to and from the base unit of its dimension.  Use the NSUnitConverter protocol to implement new ways of converting a unit.
 */

import CoreFoundation

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
    
    
    private var reciprocal: Double
    
    
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

    // Supported units (ex. UnitAcceleration.kilograms) will be created once and handed off to Unit's ObjectStore for future access
    // Not all units correlate with CFMeasureUnit/ICU units
    fileprivate enum StoreIndex: Int {
        case gForce
        case meterPerSecondSquared
        case arcMinute
        case arcSecond
        case degree
        case radian
        case revolution
        case are
        case acre
        case hectare
        case squareCentimeter
        case squareFoot
        case squareInch
        case squareMegameter
        case squareKilometer
        case squareMeter
        case squareMillimeter
        case squareMicrometer
        case squareNanometer
        case squareMile
        case squareYard
        case karat
        case gramPerLiter
        case milligramPerDeciliter
        case millimolePerLiter
        case partPerMillion
        case literPer100kilometers
        case literPerKilometer
        case milePerGallon
        case milePerGallonImperial
        case bit
        case byte
        case gigabit
        case gigabyte
        case kilobit
        case kilobyte
        case megabit
        case megabyte
        case terabit
        case terabyte
        case century
        case day
        case hour
        case microsecond
        case millisecond
        case minute
        case month
        case nanosecond
        case second
        case week
        case year


        case coulomb
        case megaampereHour
        case kiloampereHour
        case ampereHour
        case milliampereHour
        case microampereHour

        case megaampere
        case kiloampere
        case ampere
        case milliampere
        case microampere

        case megaohm
        case kiloohm
        case ohm
        case milliohm
        case microohm

        case megavolt
        case kilovolt
        case volt
        case millivolt
        case microvolt

        case calorie
        case foodcalorie
        case joule
        case kilocalorie
        case kilojoule
        case kilowattHour

        case terahertz
        case gigahertz
        case megahertz
        case kilohertz
        case hertz
        case millihertz
        case microhertz
        case nanohertz

        case parasec
        case astronomicalUnit
        case centimeter
        case decimeter
        case fathom
        case foot
        case furlong
        case inch
        case megameter
        case kilometer
        case hectometer
        case decameter
        case meter
        case millimeter
        case micrometer
        case lightYear
        case mile
        case mileScandinavian
        case nanometer
        case nauticalMile
        case parsec
        case picometer
        case point
        case yard

        case lux

        case carat
        case kilogram
        case gram
        case decigram
        case centigram
        case milligram
        case microgram
        case nanogram
        case picogram
        case metricTon
        case shortTon
        case ton
        case ounce
        case ounceTroy
        case pound
        case stone
        case slug

        case percent
        case permille

        case terawatt
        case gigawatt
        case megawatt
        case kilowatt
        case watt
        case milliwatt
        case microwatt
        case nanowatt
        case picowatt
        case femtowatt
        case horsepower

        case gigapascal
        case megapascal
        case kilopascal
        case hectopascal
        case pascal
        case inchHg
        case bar
        case millibar
        case millimeterOfMercury
        case poundPerSquareInch

        case kilometerPerHour
        case knot
        case meterPerSecond
        case milePerHour
        case celsius
        case fahrenheit
        case generic
        case kelvin
        case acreFoot
        case bushel
        case centiliter
        case cubicCentimeter
        case cubicFoot
        case cubicInch
        case cubicKilometer
        case cubicMeter
        case cubicMile
        case cubicYard
        case cup
        case cupMetric
        case deciliter
        case fluidOunce
        case gallon
        case gallonImperial
        case hectoliter
        case liter
        case megaliter
        case milliliter
        case pint
        case pintMetric
        case quart
        case tablespoon
        case teaspoon

        static let max = teaspoon.rawValue + 1
    }

    // Store is private, access members by `stored(at:)`
    // Set members by `stored(_,at:)`
    private static var ObjectStore = [Unit?](repeating: nil, count: StoreIndex.max)

    fileprivate static func stored(at index: StoreIndex) -> Unit? {
        return ObjectStore[index.rawValue]
    }

    fileprivate static func store(_ unit: Unit, at index: StoreIndex) {
        ObjectStore[index.rawValue] = unit
    }

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
        aCoder.encode(self.converter, forKey:"NS.converter")
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

extension Dimension {
    /// Efficiently store a dimension
    /// - Parameter index: A new unit to be stored if it does not exist
    /// - Parameter newUnit: A new unit to be stored if it does not exist
    fileprivate static func stored<T: Unit>(at index: StoreIndex, newUnit: @autoclosure () -> T) -> T {
        // If unit exists, return it
        if let unit = stored(at: index) {
            return unit as! T
        }
        // Store new unit
        let unit = newUnit()
        store(unit, at: index)
        return unit
    }

    fileprivate convenience init(symbol: String, coefficient: Double, storeIndex: StoreIndex? = nil) {
        let converter = UnitConverterLinear(coefficient: coefficient)
        self.init(symbol: symbol, converter: converter)
    }

    fileprivate convenience init(symbol: String, reciprocal: Double, storeIndex: StoreIndex? = nil) {
        let converter = UnitConverterReciprocal(reciprocal: reciprocal)
        self.init(symbol: symbol, converter: converter)
    }
}

public final class UnitAcceleration : Dimension {
    
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

    public class var metersPerSecondSquared: UnitAcceleration {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAcceleration(symbol: Symbol.metersPerSecondSquared, coefficient: Coefficient.metersPerSecondSquared, storeIndex: .meterPerSecondSquared))
        }
    }
    
    public class var gravity: UnitAcceleration {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAcceleration(symbol: Symbol.gravity, coefficient: Coefficient.gravity, storeIndex: .gForce))
        }
    }
    
    public override class func baseUnit() -> UnitAcceleration {
        return .metersPerSecondSquared
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitAcceleration else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitAngle : Dimension {
    
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
    
    public class var degrees: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.degrees, coefficient: Coefficient.degrees, storeIndex: .degree))
        }
    }
    
    public class var arcMinutes: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.arcMinutes, coefficient: Coefficient.arcMinutes, storeIndex: .arcMinute))
        }
    }
    
    public class var arcSeconds: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.arcSeconds, coefficient: Coefficient.arcSeconds, storeIndex: .arcSecond))
        }
    }
    
    public class var radians: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.radians, coefficient: Coefficient.radians, storeIndex: .radian))
        }
    }
    
    public class var gradians: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.gradians, coefficient: Coefficient.gradians))
        }
    }
    
    public class var revolutions: UnitAngle {
        get {
            return Dimension.stored(at: .meterPerSecondSquared, newUnit: UnitAngle(symbol: Symbol.revolutions, coefficient: Coefficient.revolutions, storeIndex: .revolution))
        }
    }
    
    public override class func baseUnit() -> UnitAngle {
        return .degrees
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitAngle else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitArea : Dimension {
    
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
    
    public class var squareMegameters: UnitArea {
        get {
            return Dimension.stored(at: .squareMegameter, newUnit: UnitArea(symbol: Symbol.squareMegameters, coefficient: Coefficient.squareMegameters))
        }
    }
    
    public class var squareKilometers: UnitArea {
        get {
            return Dimension.stored(at: .squareKilometer, newUnit: UnitArea(symbol: Symbol.squareKilometers, coefficient: Coefficient.squareKilometers, storeIndex: .squareKilometer))
        }
    }
    
    public class var squareMeters: UnitArea {
        get {
            return Dimension.stored(at: .squareMeter, newUnit: UnitArea(symbol: Symbol.squareMeters, coefficient: Coefficient.squareMeters, storeIndex: .squareMeter))
        }
    }
    
    public class var squareCentimeters: UnitArea {
        get {
            return Dimension.stored(at: .squareCentimeter, newUnit: UnitArea(symbol: Symbol.squareCentimeters, coefficient: Coefficient.squareCentimeters, storeIndex: .squareCentimeter))
        }
    }
    
    public class var squareMillimeters: UnitArea {
        get {
            return Dimension.stored(at: .squareMillimeter, newUnit: UnitArea(symbol: Symbol.squareMillimeters, coefficient: Coefficient.squareMillimeters))
        }
    }
    
    public class var squareMicrometers: UnitArea {
        get {
            return Dimension.stored(at: .squareMicrometer, newUnit: UnitArea(symbol: Symbol.squareMicrometers, coefficient: Coefficient.squareMicrometers))
        }
    }
    
    public class var squareNanometers: UnitArea {
        get {
            return Dimension.stored(at: .squareNanometer, newUnit: UnitArea(symbol: Symbol.squareNanometers, coefficient: Coefficient.squareNanometers, storeIndex: .squareNanometer))
        }
    }
    
    public class var squareInches: UnitArea {
        get {
            return Dimension.stored(at: .squareInch, newUnit: UnitArea(symbol: Symbol.squareInches, coefficient: Coefficient.squareInches, storeIndex: .squareInch))
        }
    }
    
    public class var squareFeet: UnitArea {
        get {
            return Dimension.stored(at: .squareFoot, newUnit: UnitArea(symbol: Symbol.squareFeet, coefficient: Coefficient.squareFeet, storeIndex: .squareFoot))
        }
    }
    
    public class var squareYards: UnitArea {
        get {
            return Dimension.stored(at: .squareYard, newUnit: UnitArea(symbol: Symbol.squareYards, coefficient: Coefficient.squareYards, storeIndex: .squareYard))
        }
    }
    
    public class var squareMiles: UnitArea {
        get {
            return Dimension.stored(at: .squareMile, newUnit: UnitArea(symbol: Symbol.squareMiles, coefficient: Coefficient.squareMiles, storeIndex: .squareMile))
        }
    }
    
    public class var acres: UnitArea {
        get {
            return Dimension.stored(at: .acre, newUnit: UnitArea(symbol: Symbol.acres, coefficient: Coefficient.acres, storeIndex: .acre))
        }
    }
    
    public class var ares: UnitArea {
        get {
            return Dimension.stored(at: .are, newUnit: UnitArea(symbol: Symbol.ares, coefficient: Coefficient.ares))
        }
    }
    
    public class var hectares: UnitArea {
        get {
            return Dimension.stored(at: .hectare, newUnit: UnitArea(symbol: Symbol.hectares, coefficient: Coefficient.hectares, storeIndex: .hectare))
        }
    }
    
    public override class func baseUnit() -> UnitArea {
        return .squareMeters
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitArea else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitConcentrationMass : Dimension {
    
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
    
    public class var gramsPerLiter: UnitConcentrationMass {
        get {
            return Dimension.stored(at: .gramPerLiter, newUnit: UnitConcentrationMass(symbol: Symbol.gramsPerLiter, coefficient: Coefficient.gramsPerLiter))
        }
    }
    
    public class var milligramsPerDeciliter: UnitConcentrationMass {
        get {
            return Dimension.stored(at: .milligramPerDeciliter, newUnit: UnitConcentrationMass(symbol: Symbol.milligramsPerDeciliter, coefficient: Coefficient.milligramsPerDeciliter, storeIndex: .milligramPerDeciliter))
        }
    }
    
    public class func millimolesPerLiter(withGramsPerMole gramsPerMole: Double) -> UnitConcentrationMass {
        return UnitConcentrationMass(symbol: Symbol.millimolesPerLiter, coefficient: Coefficient.millimolesPerLiter * gramsPerMole)
    }
    
    public override class func baseUnit() -> UnitConcentrationMass {
        return UnitConcentrationMass.gramsPerLiter
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitConcentrationMass else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitDispersion : Dimension {
    
    /*
     Base unit - partsPerMillion
     */
    
    private struct Symbol {
        static let partsPerMillion  = "ppm"
    }
    
    private struct Coefficient {
        static let partsPerMillion  = 1.0
    }
    
    public class var partsPerMillion: UnitDispersion {
        get {
            return Dimension.stored(at: .partPerMillion, newUnit: UnitDispersion(symbol: Symbol.partsPerMillion, coefficient: Coefficient.partsPerMillion, storeIndex: .partPerMillion))
        }
    }
    
    public override class func baseUnit() -> UnitDispersion {
        return .partsPerMillion
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitDispersion else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitDuration : Dimension {
    
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
    
    public class var seconds: UnitDuration {
        get {
            return Dimension.stored(at: .second, newUnit: UnitDuration(symbol: Symbol.seconds, coefficient: Coefficient.seconds, storeIndex: .second))
        }
    }
    
    public class var minutes: UnitDuration {
        get {
            return Dimension.stored(at: .minute, newUnit: UnitDuration(symbol: Symbol.minutes, coefficient: Coefficient.minutes, storeIndex: .minute))
        }
    }
    
    public class var hours: UnitDuration {
        get {
            return Dimension.stored(at: .hour, newUnit: UnitDuration(symbol: Symbol.hours, coefficient: Coefficient.hours, storeIndex: .hour))
        }
    }
    
    public override class func baseUnit() -> UnitDuration {
        return .seconds
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitDuration else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitElectricCharge : Dimension {
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
    
    public class var coulombs: UnitElectricCharge {
        get {
            return Dimension.stored(at: .coulomb, newUnit: UnitElectricCharge(symbol: Symbol.coulombs, coefficient: Coefficient.coulombs))
        }
    }
    
    public class var megaampereHours: UnitElectricCharge {
        get {
            return Dimension.stored(at: .megaampereHour, newUnit: UnitElectricCharge(symbol: Symbol.megaampereHours, coefficient: Coefficient.megaampereHours))
        }
    }
    
    public class var kiloampereHours: UnitElectricCharge {
        get {
            return Dimension.stored(at: .kiloampereHour, newUnit: UnitElectricCharge(symbol: Symbol.kiloampereHours, coefficient: Coefficient.kiloampereHours))
        }
    }
    
    public class var ampereHours: UnitElectricCharge {
        get {
            return Dimension.stored(at: .ampereHour, newUnit: UnitElectricCharge(symbol: Symbol.ampereHours, coefficient: Coefficient.ampereHours))
        }
    }
    
    public class var milliampereHours: UnitElectricCharge {
        get {
            return Dimension.stored(at: .milliampereHour, newUnit: UnitElectricCharge(symbol: Symbol.milliampereHours, coefficient: Coefficient.milliampereHours))
        }
    }
    
    public class var microampereHours: UnitElectricCharge {
        get {
            return Dimension.stored(at: .microampereHour, newUnit: UnitElectricCharge(symbol: Symbol.microampereHours, coefficient: Coefficient.microampereHours))
        }
    }
    
    public override class func baseUnit() -> UnitElectricCharge {
        return .coulombs
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricCharge else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitElectricCurrent : Dimension {
    
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

    public class var megaamperes: UnitElectricCurrent {
        get {
            return Dimension.stored(at: .megaampere, newUnit: UnitElectricCurrent(symbol: Symbol.megaamperes, coefficient: Coefficient.megaamperes))
        }
    }
    
    public class var kiloamperes: UnitElectricCurrent {
        get {
            return Dimension.stored(at: .kiloampere, newUnit: UnitElectricCurrent(symbol: Symbol.kiloamperes, coefficient: Coefficient.kiloamperes))
        }
    }
    
    public class var amperes: UnitElectricCurrent {
        get {
            return Dimension.stored(at: .ampere, newUnit: UnitElectricCurrent(symbol: Symbol.amperes, coefficient: Coefficient.amperes, storeIndex: .ampere))
        }
    }
    
    public class var milliamperes: UnitElectricCurrent {
        get {
            return Dimension.stored(at: .milliampere, newUnit: UnitElectricCurrent(symbol: Symbol.milliamperes, coefficient: Coefficient.milliamperes, storeIndex: .milliampere))
        }
    }
    
    public class var microamperes: UnitElectricCurrent {
        get {
            return Dimension.stored(at: .microampere, newUnit: UnitElectricCurrent(symbol: Symbol.microamperes, coefficient: Coefficient.microamperes))
        }
    }
    
    public override class func baseUnit() -> UnitElectricCurrent {
        return .amperes
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricCurrent else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitElectricPotentialDifference : Dimension {
    
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

    public class var megavolts: UnitElectricPotentialDifference {
        get {
            return Dimension.stored(at: .megavolt, newUnit: UnitElectricPotentialDifference(symbol: Symbol.megavolts, coefficient: Coefficient.megavolts))
        }
    }
    
    public class var kilovolts: UnitElectricPotentialDifference {
        get {
            return Dimension.stored(at: .kilovolt, newUnit: UnitElectricPotentialDifference(symbol: Symbol.kilovolts, coefficient: Coefficient.kilovolts))
        }
    }
    
    public class var volts: UnitElectricPotentialDifference {
        get {
            return Dimension.stored(at: .volt, newUnit: UnitElectricPotentialDifference(symbol: Symbol.megavolts, coefficient: Coefficient.volts, storeIndex: .volt))
        }
    }
    
    public class var millivolts: UnitElectricPotentialDifference {
        get {
            return Dimension.stored(at: .millivolt, newUnit: UnitElectricPotentialDifference(symbol: Symbol.millivolts, coefficient: Coefficient.millivolts))
        }
    }
    
    public class var microvolts: UnitElectricPotentialDifference {
        get {
            return Dimension.stored(at: .microvolt, newUnit: UnitElectricPotentialDifference(symbol: Symbol.microvolts, coefficient: Coefficient.microvolts))
        }
    }
    
    public override class func baseUnit() -> UnitElectricPotentialDifference {
        return .volts
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricPotentialDifference else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitElectricResistance : Dimension {
    
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

    public class var megaohms: UnitElectricResistance {
        get {
            return Dimension.stored(at: .megaohm, newUnit: UnitElectricResistance(symbol: Symbol.megaohms, coefficient: Coefficient.megaohms))
        }
    }
    
    public class var kiloohms: UnitElectricResistance {
        get {
            return Dimension.stored(at: .kiloohm, newUnit: UnitElectricResistance(symbol: Symbol.kiloohms, coefficient: Coefficient.kiloohms))
        }
    }
    
    public class var ohms: UnitElectricResistance {
        get {
            return Dimension.stored(at: .ohm, newUnit: UnitElectricResistance(symbol: Symbol.ohms, coefficient: Coefficient.ohms, storeIndex: .ohm))
        }
    }
    
    public class var milliohms: UnitElectricResistance {
        get {
            return Dimension.stored(at: .milliohm, newUnit: UnitElectricResistance(symbol: Symbol.milliohms, coefficient: Coefficient.milliohms))
        }
    }
    
    public class var microohms: UnitElectricResistance {
        get {
            return Dimension.stored(at: .microohm, newUnit: UnitElectricResistance(symbol: Symbol.microohms, coefficient: Coefficient.microohms))
        }
    }
    
    public override class func baseUnit() -> UnitElectricResistance {
        return .ohms
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitElectricResistance else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitEnergy : Dimension {
    
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
    
    public class var kilojoules: UnitEnergy {
        get {
            return Dimension.stored(at: .kilojoule, newUnit: UnitEnergy(symbol: Symbol.kilojoules, coefficient: Coefficient.kilojoules, storeIndex: .kilojoule))
        }
    }
    
    public class var joules: UnitEnergy {
        get {
            return Dimension.stored(at: .joule, newUnit: UnitEnergy(symbol: Symbol.joules, coefficient: Coefficient.joules, storeIndex: .joule))
        }
    }
    
    public class var kilocalories: UnitEnergy {
        get {
            return Dimension.stored(at: .kilocalorie, newUnit: UnitEnergy(symbol: Symbol.kilocalories, coefficient: Coefficient.kilocalories, storeIndex: .kilocalorie))
        }
    }
    
    public class var calories: UnitEnergy {
        get {
            return Dimension.stored(at: .calorie, newUnit: UnitEnergy(symbol: Symbol.calories, coefficient: Coefficient.calories, storeIndex: .calorie))
        }
    }
    
    public class var kilowattHours: UnitEnergy {
        get {
            return Dimension.stored(at: .kilowattHour, newUnit: UnitEnergy(symbol: Symbol.kilowattHours, coefficient: Coefficient.kilowattHours, storeIndex: .kilowattHour))
        }
    }
    
    public override class func baseUnit() -> UnitEnergy {
        return .joules
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitEnergy else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitFrequency : Dimension {
    
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

    public class var terahertz: UnitFrequency {
        get {
            return Dimension.stored(at: .terahertz, newUnit: UnitFrequency(symbol: Symbol.terahertz, coefficient: Coefficient.terahertz))
        }
    }
    
    public class var gigahertz: UnitFrequency {
        get {
            return Dimension.stored(at: .gigahertz, newUnit: UnitFrequency(symbol: Symbol.gigahertz, coefficient: Coefficient.gigahertz, storeIndex: .gigahertz))
        }
    }
    
    public class var megahertz: UnitFrequency {
        get {
            return Dimension.stored(at: .megahertz, newUnit: UnitFrequency(symbol: Symbol.megahertz, coefficient: Coefficient.megahertz, storeIndex: .megahertz))
        }
    }
    
    public class var kilohertz: UnitFrequency {
        get {
            return Dimension.stored(at: .kilohertz, newUnit: UnitFrequency(symbol: Symbol.kilohertz, coefficient: Coefficient.kilohertz, storeIndex: .kilohertz))
        }
    }
    
    public class var hertz: UnitFrequency {
        get {
            return Dimension.stored(at: .hertz, newUnit: UnitFrequency(symbol: Symbol.hertz, coefficient: Coefficient.hertz, storeIndex: .hertz))
        }
    }
    
    public class var millihertz: UnitFrequency {
        get {
            return Dimension.stored(at: .millihertz, newUnit: UnitFrequency(symbol: Symbol.millihertz, coefficient: Coefficient.millihertz))
        }
    }
    
    public class var microhertz: UnitFrequency {
        get {
            return Dimension.stored(at: .microhertz, newUnit: UnitFrequency(symbol: Symbol.microhertz, coefficient: Coefficient.microhertz))
        }
    }
    
    public class var nanohertz: UnitFrequency {
        get {
            return Dimension.stored(at: .nanohertz, newUnit: UnitFrequency(symbol: Symbol.nanohertz, coefficient: Coefficient.nanohertz))
        }
    }
    
    public override class func baseUnit() -> UnitFrequency {
        return .hertz
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitFrequency else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitFuelEfficiency : Dimension {
    
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
    
    public class var litersPer100Kilometers: UnitFuelEfficiency {
        get {
            return Dimension.stored(at: .literPer100kilometers, newUnit: UnitFuelEfficiency(symbol: Symbol.litersPer100Kilometers, reciprocal: Coefficient.litersPer100Kilometers, storeIndex: .literPer100kilometers))
        }
    }
    
    public class var milesPerImperialGallon: UnitFuelEfficiency {
        get {
            return Dimension.stored(at: .milePerGallonImperial, newUnit: UnitFuelEfficiency(symbol: Symbol.milesPerImperialGallon, reciprocal: Coefficient.milesPerImperialGallon, storeIndex: .milePerGallonImperial))
        }
    }
    
    public class var milesPerGallon: UnitFuelEfficiency {
        get {
            return Dimension.stored(at: .milePerGallon, newUnit: UnitFuelEfficiency(symbol: Symbol.milesPerGallon, reciprocal: Coefficient.milesPerGallon, storeIndex: .milePerGallon))
        }
    }
    
    public override class func baseUnit() -> UnitFuelEfficiency {
        return .litersPer100Kilometers
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitFuelEfficiency else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitLength : Dimension {
    
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

    public class var megameters: UnitLength {
        get {
            return Dimension.stored(at: .megameter, newUnit: UnitLength(symbol: Symbol.megameters, reciprocal: Coefficient.megameters))
        }
    }
    
    public class var kilometers: UnitLength {
        get {
            return Dimension.stored(at: .kilometer, newUnit: UnitLength(symbol: Symbol.kilometers, coefficient: Coefficient.kilometers, storeIndex: .kilometer))
        }
    }
    
    public class var hectometers: UnitLength {
        get {
            return Dimension.stored(at: .hectometer, newUnit: UnitLength(symbol: Symbol.hectometers, coefficient: Coefficient.hectometers))
        }
    }
    
    public class var decameters: UnitLength {
        get {
            return Dimension.stored(at: .decameter, newUnit: UnitLength(symbol: Symbol.decameters, coefficient: Coefficient.decameters))
        }
    }
    
    public class var meters: UnitLength {
        get {
            return Dimension.stored(at: .meter, newUnit: UnitLength(symbol: Symbol.meters, coefficient: Coefficient.meters, storeIndex: .meter))
        }
    }
    
    public class var decimeters: UnitLength {
        get {
            return Dimension.stored(at: .decimeter, newUnit: UnitLength(symbol: Symbol.decimeters, coefficient: Coefficient.decimeters, storeIndex: .decimeter))
        }
    }
    
    public class var centimeters: UnitLength {
        get {
            return Dimension.stored(at: .centimeter, newUnit: UnitLength(symbol: Symbol.centimeters, coefficient: Coefficient.centimeters, storeIndex: .centimeter))
        }
    }
    
    public class var millimeters: UnitLength {
        get {
            return Dimension.stored(at: .millimeter, newUnit: UnitLength(symbol: Symbol.millimeters, coefficient: Coefficient.millimeters, storeIndex: .millimeter))
        }
    }
    
    public class var micrometers: UnitLength {
        get {
            return Dimension.stored(at: .micrometer, newUnit: UnitLength(symbol: Symbol.micrometers, coefficient: Coefficient.micrometers, storeIndex: .micrometer))
        }
    }
    
    public class var nanometers: UnitLength {
        get {
            return Dimension.stored(at: .nanometer, newUnit: UnitLength(symbol: Symbol.nanometers, coefficient: Coefficient.nanometers, storeIndex: .nanometer))
        }
    }
    
    public class var picometers: UnitLength {
        get {
            return Dimension.stored(at: .picometer, newUnit: UnitLength(symbol: Symbol.picometers, coefficient: Coefficient.picometers, storeIndex: .picometer))
        }
    }
    
    public class var inches: UnitLength {
        get {
            return Dimension.stored(at: .inch, newUnit: UnitLength(symbol: Symbol.inches, coefficient: Coefficient.inches, storeIndex: .inch))
        }
    }
    
    public class var feet: UnitLength {
        get {
            return Dimension.stored(at: .foot, newUnit: UnitLength(symbol: Symbol.feet, coefficient: Coefficient.feet, storeIndex: .foot))
        }
    }
    
    public class var yards: UnitLength {
        get {
            return Dimension.stored(at: .yard, newUnit: UnitLength(symbol: Symbol.yards, coefficient: Coefficient.yards, storeIndex: .yard))
        }
    }
    
    public class var miles: UnitLength {
        get {
            return Dimension.stored(at: .mile, newUnit: UnitLength(symbol: Symbol.miles, coefficient: Coefficient.miles, storeIndex: .mile))
        }
    }
    
    public class var scandinavianMiles: UnitLength {
        get {
            return Dimension.stored(at: .mileScandinavian, newUnit: UnitLength(symbol: Symbol.scandinavianMiles, coefficient: Coefficient.scandinavianMiles, storeIndex: .mileScandinavian))
        }
    }
    
    public class var lightyears: UnitLength {
        get {
            return Dimension.stored(at: .lightYear, newUnit: UnitLength(symbol: Symbol.lightyears, coefficient: Coefficient.lightyears, storeIndex: .lightYear))
        }
    }
    
    public class var nauticalMiles: UnitLength {
        get {
            return Dimension.stored(at: .nauticalMile, newUnit: UnitLength(symbol: Symbol.nauticalMiles, coefficient: Coefficient.nauticalMiles, storeIndex: .nauticalMile))
        }
    }
    
    public class var fathoms: UnitLength {
        get {
            return Dimension.stored(at: .fathom, newUnit: UnitLength(symbol: Symbol.fathoms, coefficient: Coefficient.fathoms, storeIndex: .fathom))
        }
    }
    
    public class var furlongs: UnitLength {
        get {
            return Dimension.stored(at: .furlong, newUnit: UnitLength(symbol: Symbol.furlongs, coefficient: Coefficient.furlongs, storeIndex: .furlong))
        }
    }
    
    public class var astronomicalUnits: UnitLength {
        get {
            return Dimension.stored(at: .astronomicalUnit, newUnit: UnitLength(symbol: Symbol.astronomicalUnits, coefficient: Coefficient.astronomicalUnits, storeIndex: .astronomicalUnit))
        }
    }
    
    public class var parsecs: UnitLength {
        get {
            return Dimension.stored(at: .parasec, newUnit: UnitLength(symbol: Symbol.parsecs, coefficient: Coefficient.parsecs))
        }
    }
    
    public override class func baseUnit() -> UnitLength {
        return .meters
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitLength else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitIlluminance : Dimension {
    
    /*
     Base unit - lux
     */
    
    private struct Symbol {
        static let lux   = "lx"
    }
    
    private struct Coefficient {
        static let lux   = 1.0
    }

    public class var lux: UnitIlluminance {
        get {
            return Dimension.stored(at: .lux, newUnit: UnitIlluminance(symbol: Symbol.lux, coefficient: Coefficient.lux, storeIndex: .lux))
        }
    }
    
    public override class func baseUnit() -> UnitIlluminance {
        return .lux
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitIlluminance else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitMass : Dimension {
    
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

    public class var kilograms: UnitMass {
        get {
            return Dimension.stored(at: .kilogram, newUnit: UnitMass(symbol: Symbol.kilograms, coefficient: Coefficient.kilograms, storeIndex: .kilogram))
        }
    }
    
    public class var grams: UnitMass {
        get {
            return Dimension.stored(at: .gram, newUnit: UnitMass(symbol: Symbol.grams, coefficient: Coefficient.grams, storeIndex: .gram))
        }
    }
    
    public class var decigrams: UnitMass {
        get {
            return Dimension.stored(at: .decigram, newUnit: UnitMass(symbol: Symbol.decigrams, coefficient: Coefficient.decigrams))
        }
    }
    
    public class var centigrams: UnitMass {
        get {
            return Dimension.stored(at: .centigram, newUnit: UnitMass(symbol: Symbol.centigrams, coefficient: Coefficient.centigrams))
        }
    }
    
    public class var milligrams: UnitMass {
        get {
            return Dimension.stored(at: .milligram, newUnit: UnitMass(symbol: Symbol.milligrams, coefficient: Coefficient.milligrams, storeIndex: .milligram))
        }
    }
    
    public class var micrograms: UnitMass {
        get {
            return Dimension.stored(at: .microgram, newUnit: UnitMass(symbol: Symbol.micrograms, coefficient: Coefficient.micrograms, storeIndex: .microgram))
        }
    }
    
    public class var nanograms: UnitMass {
        get {
            return Dimension.stored(at: .nanogram, newUnit: UnitMass(symbol: Symbol.nanograms, coefficient: Coefficient.nanograms))
        }
    }
    
    public class var picograms: UnitMass {
        get {
            return Dimension.stored(at: .picogram, newUnit: UnitMass(symbol: Symbol.picograms, coefficient: Coefficient.picograms))
        }
    }
    
    public class var ounces: UnitMass {
        get {
            return Dimension.stored(at: .ounce, newUnit: UnitMass(symbol: Symbol.ounces, coefficient: Coefficient.ounces, storeIndex: .ounce))
        }
    }
    
    public class var pounds: UnitMass {
        get {
            return Dimension.stored(at: .pound, newUnit: UnitMass(symbol: Symbol.pounds, coefficient: Coefficient.pounds, storeIndex: .pound))
        }
    }
    
    public class var stones: UnitMass {
        get {
            return Dimension.stored(at: .stone, newUnit: UnitMass(symbol: Symbol.stones, coefficient: Coefficient.stones, storeIndex: .stone))
        }
    }
    
    public class var metricTons: UnitMass {
        get {
            return Dimension.stored(at: .metricTon, newUnit: UnitMass(symbol: Symbol.metricTons, coefficient: Coefficient.metricTons, storeIndex: .metricTon))
        }
    }
    
    public class var shortTons: UnitMass {
        get {
            return Dimension.stored(at: .shortTon, newUnit: UnitMass(symbol: Symbol.shortTons, coefficient: Coefficient.shortTons))
        }
    }
    
    public class var carats: UnitMass {
        get {
            return Dimension.stored(at: .carat, newUnit: UnitMass(symbol: Symbol.carats, coefficient: Coefficient.carats, storeIndex: .carat))
        }
    }
    
    public class var ouncesTroy: UnitMass {
        get {
            return Dimension.stored(at: .ounceTroy, newUnit: UnitMass(symbol: Symbol.ouncesTroy, coefficient: Coefficient.ouncesTroy, storeIndex: .ounceTroy))
        }
    }
    
    public class var slugs: UnitMass {
        get {
            return Dimension.stored(at: .slug, newUnit: UnitMass(symbol: Symbol.slugs, coefficient: Coefficient.slugs))
        }
    }
    
    public override class func baseUnit() -> UnitMass {
        return .kilograms
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitMass else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitPower : Dimension {
    
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

    public class var terawatts: UnitPower {
        get {
            return Dimension.stored(at: .terawatt, newUnit: UnitPower(symbol: Symbol.terawatts, coefficient: Coefficient.terawatts))
        }
    }
    
    public class var gigawatts: UnitPower {
        get {
            return Dimension.stored(at: .gigawatt, newUnit: UnitPower(symbol: Symbol.gigawatts, coefficient: Coefficient.gigawatts, storeIndex: .gigawatt))
        }
    }
    
    public class var megawatts: UnitPower {
        get {
            return Dimension.stored(at: .megawatt, newUnit: UnitPower(symbol: Symbol.megawatts, coefficient: Coefficient.megawatts, storeIndex: .megawatt))
        }
    }
    
    public class var kilowatts: UnitPower {
        get {
            return Dimension.stored(at: .kilowatt, newUnit: UnitPower(symbol: Symbol.kilowatts, coefficient: Coefficient.kilowatts, storeIndex: .kilowatt))
        }
    }
    
    public class var watts: UnitPower {
        get {
            return Dimension.stored(at: .watt, newUnit: UnitPower(symbol: Symbol.watts, coefficient: Coefficient.watts, storeIndex: .watt))
        }
    }
    
    public class var milliwatts: UnitPower {
        get {
            return Dimension.stored(at: .milliwatt, newUnit: UnitPower(symbol: Symbol.milliwatts, coefficient: Coefficient.milliwatts, storeIndex: .milliwatt))
        }
    }
    
    public class var microwatts: UnitPower {
        get {
            return Dimension.stored(at: .microwatt, newUnit: UnitPower(symbol: Symbol.microwatts, coefficient: Coefficient.microwatts))
        }
    }
    
    public class var nanowatts: UnitPower {
        get {
            return Dimension.stored(at: .nanowatt, newUnit: UnitPower(symbol: Symbol.nanowatts, coefficient: Coefficient.nanowatts))
        }
    }
    
    public class var picowatts: UnitPower {
        get {
            return Dimension.stored(at: .picowatt, newUnit: UnitPower(symbol: Symbol.picowatts, coefficient: Coefficient.picowatts))
        }
    }
    
    public class var femtowatts: UnitPower {
        get {
            return Dimension.stored(at: .femtowatt, newUnit: UnitPower(symbol: Symbol.femtowatts, coefficient: Coefficient.femtowatts))
        }
    }
    
    public class var horsepower: UnitPower {
        get {
            return Dimension.stored(at: .horsepower, newUnit: UnitPower(symbol: Symbol.horsepower, coefficient: Coefficient.horsepower, storeIndex: .horsepower))
        }
    }
    
    public override class func baseUnit() -> UnitPower {
        return .watts
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitPower else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitPressure : Dimension {
    
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
    
    public class var newtonsPerMetersSquared: UnitPressure {
        get {
            return Dimension.stored(at: .pascal, newUnit: UnitPressure(symbol: Symbol.newtonsPerMetersSquared, coefficient: Coefficient.newtonsPerMetersSquared))
        }
    }
    
    public class var gigapascals: UnitPressure {
        get {
            return Dimension.stored(at: .gigapascal, newUnit: UnitPressure(symbol: Symbol.gigapascals, coefficient: Coefficient.gigapascals))
        }
    }
    
    public class var megapascals: UnitPressure {
        get {
            return Dimension.stored(at: .megapascal, newUnit: UnitPressure(symbol: Symbol.megapascals, coefficient: Coefficient.megapascals))
        }
    }
    
    public class var kilopascals: UnitPressure {
        get {
            return Dimension.stored(at: .kilopascal, newUnit: UnitPressure(symbol: Symbol.kilopascals, coefficient: Coefficient.kilopascals))
        }
    }
    
    public class var hectopascals: UnitPressure {
        get {
            return Dimension.stored(at: .hectopascal, newUnit: UnitPressure(symbol: Symbol.hectopascals, coefficient: Coefficient.hectopascals, storeIndex: .hectopascal))
        }
    }
    
    public class var inchesOfMercury: UnitPressure {
        get {
            return Dimension.stored(at: .inchHg, newUnit: UnitPressure(symbol: Symbol.inchesOfMercury, coefficient: Coefficient.inchesOfMercury, storeIndex: .inchHg))
        }
    }
    
    public class var bars: UnitPressure {
        get {
            return Dimension.stored(at: .bar, newUnit: UnitPressure(symbol: Symbol.bars, coefficient: Coefficient.bars))
        }
    }
    
    public class var millibars: UnitPressure {
        get {
            return Dimension.stored(at: .millibar, newUnit: UnitPressure(symbol: Symbol.millibars, coefficient: Coefficient.millibars, storeIndex: .millibar))
        }
    }
    
    public class var millimetersOfMercury: UnitPressure {
        get {
            return Dimension.stored(at: .millimeterOfMercury, newUnit: UnitPressure(symbol: Symbol.millimetersOfMercury, coefficient: Coefficient.millimetersOfMercury, storeIndex: .millimeterOfMercury))
        }
    }
    
    public class var poundsForcePerSquareInch: UnitPressure {
        get {
            return Dimension.stored(at: .poundPerSquareInch, newUnit: UnitPressure(symbol: Symbol.poundsForcePerSquareInch, coefficient: Coefficient.poundsForcePerSquareInch, storeIndex: .poundPerSquareInch))
        }
    }
    
    public override class func baseUnit() -> UnitPressure {
        return .newtonsPerMetersSquared
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitPressure else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitSpeed : Dimension {
    
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

    public class var metersPerSecond: UnitSpeed {
        get {
            return Dimension.stored(at: .meterPerSecond, newUnit: UnitSpeed(symbol: Symbol.metersPerSecond, coefficient: Coefficient.metersPerSecond, storeIndex: .meterPerSecond))
        }
    }
    
    public class var kilometersPerHour: UnitSpeed {
        get {
            return Dimension.stored(at: .kilometerPerHour, newUnit: UnitSpeed(symbol: Symbol.kilometersPerHour, coefficient: Coefficient.kilometersPerHour, storeIndex: .kilometerPerHour))
        }
    }
    
    public class var milesPerHour: UnitSpeed {
        get {
            return Dimension.stored(at: .milePerHour, newUnit: UnitSpeed(symbol: Symbol.milesPerHour, coefficient: Coefficient.milesPerHour, storeIndex: .milePerHour))
        }
    }
    
    public class var knots: UnitSpeed {
        get {
            return Dimension.stored(at: .knot, newUnit: UnitSpeed(symbol: Symbol.knots, coefficient: Coefficient.knots, storeIndex: .knot))
        }
    }
    
    public override class func baseUnit() -> UnitSpeed {
        return .metersPerSecond
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitSpeed else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitTemperature : Dimension {
    
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
    
    private convenience init(symbol: String, coefficient: Double, constant: Double, storeIndex: StoreIndex) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient, constant: constant))
    }
    
    public class var kelvin: UnitTemperature {
        get {
            return Dimension.stored(at: .kelvin, newUnit: UnitTemperature(symbol: Symbol.kelvin, coefficient: Coefficient.kelvin, storeIndex: .kelvin))
        }
    }
    
    public class var celsius: UnitTemperature {
        get {
            return Dimension.stored(at: .celsius, newUnit: UnitTemperature(symbol: Symbol.kelvin, coefficient: Coefficient.celsius, constant: Constant.celsius, storeIndex: .celsius))
        }
    }
    
    public class var fahrenheit: UnitTemperature {
        get {
            return Dimension.stored(at: .fahrenheit, newUnit: UnitTemperature(symbol: Symbol.fahrenheit, coefficient: Coefficient.fahrenheit, constant: Constant.fahrenheit, storeIndex: .fahrenheit))
        }
    }
    
    public override class func baseUnit() -> UnitTemperature {
        return .kelvin
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitTemperature else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}

public final class UnitVolume : Dimension {
    
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
    
    public class var megaliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.megaliters, coefficient: Coefficient.megaliters)
        }
    }
    
    public class var kiloliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.kiloliters, coefficient: Coefficient.kiloliters)
        }
    }
    
    public class var liters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.liters, coefficient: Coefficient.liters)
        }
    }
    
    public class var deciliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.deciliters, coefficient: Coefficient.deciliters)
        }
    }
    
    public class var centiliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.centiliters, coefficient: Coefficient.centiliters)
        }
    }
    
    public class var milliliters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.milliliters, coefficient: Coefficient.milliliters)
        }
    }
    
    public class var cubicKilometers: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicKilometers, coefficient: Coefficient.cubicKilometers)
        }
    }
    
    public class var cubicMeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMeters, coefficient: Coefficient.cubicMeters)
        }
    }
    
    public class var cubicDecimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicDecimeters, coefficient: Coefficient.cubicDecimeters)
        }
    }
    
    public class var cubicCentimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicCentimeters, coefficient: Coefficient.cubicCentimeters)
        }
    }
    
    public class var cubicMillimeters: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMillimeters, coefficient: Coefficient.cubicMillimeters)
        }
    }
    
    public class var cubicInches: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicInches, coefficient: Coefficient.cubicInches)
        }
    }
    
    public class var cubicFeet: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicFeet, coefficient: Coefficient.cubicFeet)
        }
    }
    
    public class var cubicYards: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicYards, coefficient: Coefficient.cubicYards)
        }
    }
    
    public class var cubicMiles: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cubicMiles, coefficient: Coefficient.cubicMiles)
        }
    }
    
    public class var acreFeet: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.acreFeet, coefficient: Coefficient.acreFeet)
        }
    }
    
    public class var bushels: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.bushels, coefficient: Coefficient.bushels)
        }
    }
    
    public class var teaspoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.teaspoons, coefficient: Coefficient.teaspoons)
        }
    }
    
    public class var tablespoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.tablespoons, coefficient: Coefficient.tablespoons)
        }
    }
    
    public class var fluidOunces: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.fluidOunces, coefficient: Coefficient.fluidOunces)
        }
    }
    
    public class var cups: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.cups, coefficient: Coefficient.cups)
        }
    }
    
    public class var pints: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.pints, coefficient: Coefficient.pints)
        }
    }
    
    public class var quarts: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.quarts, coefficient: Coefficient.quarts)
        }
    }
    
    public class var gallons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.gallons, coefficient: Coefficient.gallons)
        }
    }
    
    public class var imperialTeaspoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialTeaspoons, coefficient: Coefficient.imperialTeaspoons)
        }
    }
    
    public class var imperialTablespoons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialTablespoons, coefficient: Coefficient.imperialTablespoons)
        }
    }
    
    public class var imperialFluidOunces: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialFluidOunces, coefficient: Coefficient.imperialFluidOunces)
        }
    }
    
    public class var imperialPints: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialPints, coefficient: Coefficient.imperialPints)
        }
    }
    
    public class var imperialQuarts: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialQuarts, coefficient: Coefficient.imperialQuarts)
        }
    }
    
    public class var imperialGallons: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.imperialGallons, coefficient: Coefficient.imperialGallons)
        }
    }
    
    public class var metricCups: UnitVolume {
        get {
            return UnitVolume(symbol: Symbol.metricCups, coefficient: Coefficient.metricCups)
        }
    }
    
    public override class func baseUnit() -> UnitVolume {
        return .liters
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UnitVolume else {
            return false
        }
        
        if self === other {
            return true
        }
        
        return super.isEqual(object)
    }
}
