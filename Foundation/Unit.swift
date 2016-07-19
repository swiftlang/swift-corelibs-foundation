/*
 NSUnitConverter describes how to convert a unit to and from the base unit of its dimension.  Use the NSUnitConverter protocol to implement new ways of converting a unit.
 */

public class UnitConverter : NSObject {
    
    
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
    public func baseUnitValue(fromValue value: Double) -> Double { NSUnimplemented() }
    
    
    /*
     This method takes in a value in terms of the base unit of a unit's dimension and returns the equivalent value in terms of the unit.
     @param baseUnitValue Value in terms of the base unit
     @return Value in terms of the unit class
     */
    public func value(fromBaseUnitValue baseUnitValue: Double) -> Double { NSUnimplemented() }
}

public class UnitConverterLinear : UnitConverter, NSSecureCoding {
    
    
    public var coefficient: Double { get { NSUnimplemented() } }
    
    public var constant: Double { get { NSUnimplemented() } }
    
    
    public convenience init(coefficient: Double) { NSUnimplemented() }
    
    
    public init(coefficient: Double, constant: Double) { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public func encode(with aCoder: NSCoder) { NSUnimplemented() }
    public static func supportsSecureCoding() -> Bool { return true }
}

/*
 NSUnit is the base class for all unit types (dimensional and dimensionless).
 */

public class Unit : NSObject, NSCopying, NSSecureCoding {
    
    
    public private(set) var symbol: String
    
    
    public init(symbol: String) {
        self.symbol = symbol
    }
    
    public func copy(with zone: NSZone?) -> AnyObject {
        return self
    }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public func encode(with aCoder: NSCoder) { NSUnimplemented() }
    public static func supportsSecureCoding() -> Bool { return true }
}

public class Dimension : Unit {
    
    
    public var converter: UnitConverter { get { NSUnimplemented() } }
    
    
    public init(symbol: String, converter: UnitConverter) { NSUnimplemented() }
    
    /*
     This class method returns an instance of the dimension class that represents the base unit of that dimension.
     e.g.
     NSUnitSpeed *metersPerSecond = [NSUnitSpeed baseUnit];
     */
    public class func baseUnit() -> Self { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitAcceleration : Dimension {
    
    
    public class var metersPerSecondSquared: UnitAcceleration { get { NSUnimplemented() } }
    
    public class var gravity: UnitAcceleration { get { NSUnimplemented() } }

    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitAngle : Dimension {
    
    
    public class var degrees: UnitAngle { get { NSUnimplemented() } }
    
    public class var arcMinutes: UnitAngle { get { NSUnimplemented() } }
    
    public class var arcSeconds: UnitAngle { get { NSUnimplemented() } }
    
    public class var radians: UnitAngle { get { NSUnimplemented() } }
    
    public class var gradians: UnitAngle { get { NSUnimplemented() } }
    
    public class var revolutions: UnitAngle { get { NSUnimplemented() } }
    
    

    public class var degree: UnitAngle { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitArea : Dimension {
    
    /*
     Base unit - squareMeters
     */
    
    public class var squareMegameters: UnitArea { get { NSUnimplemented() } }
    
    public class var squareKilometers: UnitArea { get { NSUnimplemented() } }
    
    public class var squareMeters: UnitArea { get { NSUnimplemented() } }
    
    public class var squareCentimeters: UnitArea { get { NSUnimplemented() } }
    
    public class var squareMillimeters: UnitArea { get { NSUnimplemented() } }
    
    public class var squareMicrometers: UnitArea { get { NSUnimplemented() } }
    
    public class var squareNanometers: UnitArea { get { NSUnimplemented() } }
    
    public class var squareInches: UnitArea { get { NSUnimplemented() } }
    
    public class var squareFeet: UnitArea { get { NSUnimplemented() } }
    
    public class var squareYards: UnitArea { get { NSUnimplemented() } }
    
    public class var squareMiles: UnitArea { get { NSUnimplemented() } }
    
    public class var acres: UnitArea { get { NSUnimplemented() } }
    
    public class var ares: UnitArea { get { NSUnimplemented() } }
    
    public class var hectares: UnitArea { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitConcentrationMass : Dimension {
    
    
    public class var gramsPerLiter: UnitConcentrationMass { get { NSUnimplemented() } }
    
    public class var milligramsPerDeciliter: UnitConcentrationMass { get { NSUnimplemented() } }
    
    
    public class func millimolesPerLiter(withGramsPerMole gramsPerMole: Double) -> UnitConcentrationMass { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitDispersion : Dimension {
    
    /*
     Base unit - partsPerMillion
     */
    public class var partsPerMillion: UnitDispersion { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitDuration : Dimension {
    
    /*
     Base unit - seconds
     */
    
    public class var seconds: UnitDuration { get { NSUnimplemented() } }
    
    public class var minutes: UnitDuration { get { NSUnimplemented() } }
    
    public class var hours: UnitDuration { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitElectricCharge : Dimension {
    
    
    public class var coulombs: UnitElectricCharge { get { NSUnimplemented() } }
    
    public class var megaampereHours: UnitElectricCharge { get { NSUnimplemented() } }
    
    public class var kiloampereHours: UnitElectricCharge { get { NSUnimplemented() } }
    
    public class var ampereHours: UnitElectricCharge { get { NSUnimplemented() } }
    
    public class var milliampereHours: UnitElectricCharge { get { NSUnimplemented() } }
    
    public class var microampereHours: UnitElectricCharge { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitElectricCurrent : Dimension {
    
    /*
     Base unit - amperes
     */
    
    public class var megaamperes: UnitElectricCurrent { get { NSUnimplemented() } }
    
    public class var kiloamperes: UnitElectricCurrent { get { NSUnimplemented() } }
    
    public class var amperes: UnitElectricCurrent { get { NSUnimplemented() } }
    
    public class var milliamperes: UnitElectricCurrent { get { NSUnimplemented() } }
    
    public class var microamperes: UnitElectricCurrent { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitElectricPotentialDifference : Dimension {
    
    /*
     Base unit - volts
     */
    
    public class var megavolts: UnitElectricPotentialDifference { get { NSUnimplemented() } }
    
    public class var kilovolts: UnitElectricPotentialDifference { get { NSUnimplemented() } }
    
    public class var volts: UnitElectricPotentialDifference { get { NSUnimplemented() } }
    
    public class var millivolts: UnitElectricPotentialDifference { get { NSUnimplemented() } }
    
    public class var microvolts: UnitElectricPotentialDifference { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitElectricResistance : Dimension {
    
    /*
     Base unit - ohms
     */
    
    public class var megaohms: UnitElectricResistance { get { NSUnimplemented() } }
    
    public class var kiloohms: UnitElectricResistance { get { NSUnimplemented() } }
    
    public class var ohms: UnitElectricResistance { get { NSUnimplemented() } }
    
    public class var milliohms: UnitElectricResistance { get { NSUnimplemented() } }
    
    public class var microohms: UnitElectricResistance { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitEnergy : Dimension {
    
    /*
     Base unit - joules
     */
    
    public class var kilojoules: UnitEnergy { get { NSUnimplemented() } }
    
    public class var joules: UnitEnergy { get { NSUnimplemented() } }
    
    public class var kilocalories: UnitEnergy { get { NSUnimplemented() } }
    
    public class var calories: UnitEnergy { get { NSUnimplemented() } }
    
    public class var kilowattHours: UnitEnergy { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitFrequency : Dimension {
    
    
    public class var terahertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var gigahertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var megahertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var kilohertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var hertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var millihertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var microhertz: UnitFrequency { get { NSUnimplemented() } }
    
    public class var nanohertz: UnitFrequency { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitFuelEfficiency : Dimension {
    
    /*
     Base unit - litersPer100Kilometers
     */
    
    public class var litersPer100Kilometers: UnitFuelEfficiency { get { NSUnimplemented() } }
    
    public class var milesPerImperialGallon: UnitFuelEfficiency { get { NSUnimplemented() } }
    
    public class var milesPerGallon: UnitFuelEfficiency { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitLength : Dimension {
    
    /*
     Base unit - meters
     */
    
    public class var megameters: UnitLength { get { NSUnimplemented() } }
    
    public class var kilometers: UnitLength { get { NSUnimplemented() } }
    
    public class var hectometers: UnitLength { get { NSUnimplemented() } }
    
    public class var decameters: UnitLength { get { NSUnimplemented() } }
    
    public class var meters: UnitLength { get { NSUnimplemented() } }
    
    public class var decimeters: UnitLength { get { NSUnimplemented() } }
    
    public class var centimeters: UnitLength { get { NSUnimplemented() } }
    
    public class var millimeters: UnitLength { get { NSUnimplemented() } }
    
    public class var micrometers: UnitLength { get { NSUnimplemented() } }
    
    public class var nanometers: UnitLength { get { NSUnimplemented() } }
    
    public class var picometers: UnitLength { get { NSUnimplemented() } }
    
    public class var inches: UnitLength { get { NSUnimplemented() } }
    
    public class var feet: UnitLength { get { NSUnimplemented() } }
    
    public class var yards: UnitLength { get { NSUnimplemented() } }
    
    public class var miles: UnitLength { get { NSUnimplemented() } }
    
    public class var scandinavianMiles: UnitLength { get { NSUnimplemented() } }
    
    public class var lightyears: UnitLength { get { NSUnimplemented() } }
    
    public class var nauticalMiles: UnitLength { get { NSUnimplemented() } }
    
    public class var fathoms: UnitLength { get { NSUnimplemented() } }
    
    public class var furlongs: UnitLength { get { NSUnimplemented() } }
    
    public class var astronomicalUnits: UnitLength { get { NSUnimplemented() } }
    
    public class var parsecs: UnitLength { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitIlluminance : Dimension {
    
    /*
     Base unit - lux
     */
    
    public class var lux: UnitIlluminance { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitMass : Dimension {
    
    
    public class var kilograms: UnitMass { get { NSUnimplemented() } }
    
    public class var grams: UnitMass { get { NSUnimplemented() } }
    
    public class var decigrams: UnitMass { get { NSUnimplemented() } }
    
    public class var centigrams: UnitMass { get { NSUnimplemented() } }
    
    public class var milligrams: UnitMass { get { NSUnimplemented() } }
    
    public class var micrograms: UnitMass { get { NSUnimplemented() } }
    
    public class var nanograms: UnitMass { get { NSUnimplemented() } }
    
    public class var picograms: UnitMass { get { NSUnimplemented() } }
    
    public class var ounces: UnitMass { get { NSUnimplemented() } }
    
    public class var pounds: UnitMass { get { NSUnimplemented() } }
    
    public class var stones: UnitMass { get { NSUnimplemented() } }
    
    public class var metricTons: UnitMass { get { NSUnimplemented() } }
    
    public class var shortTons: UnitMass { get { NSUnimplemented() } }
    
    public class var carats: UnitMass { get { NSUnimplemented() } }
    
    public class var ouncesTroy: UnitMass { get { NSUnimplemented() } }
    
    public class var slugs: UnitMass { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitPower : Dimension {
    
    /*
     Base unit - watts
     */
    
    public class var terawatts: UnitPower { get { NSUnimplemented() } }
    
    public class var gigawatts: UnitPower { get { NSUnimplemented() } }
    
    public class var megawatts: UnitPower { get { NSUnimplemented() } }
    
    public class var kilowatts: UnitPower { get { NSUnimplemented() } }
    
    public class var watts: UnitPower { get { NSUnimplemented() } }
    
    public class var milliwatts: UnitPower { get { NSUnimplemented() } }
    
    public class var microwatts: UnitPower { get { NSUnimplemented() } }
    
    public class var nanowatts: UnitPower { get { NSUnimplemented() } }
    
    public class var picowatts: UnitPower { get { NSUnimplemented() } }
    
    public class var femtowatts: UnitPower { get { NSUnimplemented() } }
    
    public class var horsepower: UnitPower { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitPressure : Dimension {
    
    /*
     Base unit - newtonsPerMetersSquared (equivalent to 1 pascal)
     */
    
    public class var newtonsPerMetersSquared: UnitPressure { get { NSUnimplemented() } }
    
    public class var gigapascals: UnitPressure { get { NSUnimplemented() } }
    
    public class var megapascals: UnitPressure { get { NSUnimplemented() } }
    
    public class var kilopascals: UnitPressure { get { NSUnimplemented() } }
    
    public class var hectopascals: UnitPressure { get { NSUnimplemented() } }
    
    public class var inchesOfMercury: UnitPressure { get { NSUnimplemented() } }
    
    public class var bars: UnitPressure { get { NSUnimplemented() } }
    
    public class var millibars: UnitPressure { get { NSUnimplemented() } }
    
    public class var millimetersOfMercury: UnitPressure { get { NSUnimplemented() } }
    
    public class var poundsForcePerSquareInch: UnitPressure { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitSpeed : Dimension {
    
    /*
     Base unit - metersPerSecond
     */
    
    public class var metersPerSecond: UnitSpeed { get { NSUnimplemented() } }
    
    public class var kilometersPerHour: UnitSpeed { get { NSUnimplemented() } }
    
    public class var milesPerHour: UnitSpeed { get { NSUnimplemented() } }
    
    public class var knots: UnitSpeed { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitTemperature : Dimension {
    
    /*
     Base unit - kelvin
     */
    public class var kelvin: UnitTemperature { get { NSUnimplemented() } }
    
    public class var celsius: UnitTemperature { get { NSUnimplemented() } }
    
    public class var fahrenheit: UnitTemperature { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}

public class UnitVolume : Dimension {
    
    
    public class var megaliters: UnitVolume { get { NSUnimplemented() } }
    
    public class var kiloliters: UnitVolume { get { NSUnimplemented() } }
    
    public class var liters: UnitVolume { get { NSUnimplemented() } }
    
    public class var deciliters: UnitVolume { get { NSUnimplemented() } }
    
    public class var centiliters: UnitVolume { get { NSUnimplemented() } }
    
    public class var milliliters: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicKilometers: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicMeters: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicDecimeters: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicCentimeters: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicMillimeters: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicInches: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicFeet: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicYards: UnitVolume { get { NSUnimplemented() } }
    
    public class var cubicMiles: UnitVolume { get { NSUnimplemented() } }
    
    public class var acreFeet: UnitVolume { get { NSUnimplemented() } }
    
    public class var bushels: UnitVolume { get { NSUnimplemented() } }
    
    public class var teaspoons: UnitVolume { get { NSUnimplemented() } }
    
    public class var tablespoons: UnitVolume { get { NSUnimplemented() } }
    
    public class var fluidOunces: UnitVolume { get { NSUnimplemented() } }
    
    public class var cups: UnitVolume { get { NSUnimplemented() } }
    
    public class var pints: UnitVolume { get { NSUnimplemented() } }
    
    public class var quarts: UnitVolume { get { NSUnimplemented() } }
    
    public class var gallons: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialTeaspoons: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialTablespoons: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialFluidOunces: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialPints: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialQuarts: UnitVolume { get { NSUnimplemented() } }
    
    public class var imperialGallons: UnitVolume { get { NSUnimplemented() } }
    
    public class var metricCups: UnitVolume { get { NSUnimplemented() } }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    public override func encode(with aCoder: NSCoder) { NSUnimplemented() }
}
