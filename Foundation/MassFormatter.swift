// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension MassFormatter {
    public enum Unit : Int {
        case gram
        case kilogram
        case ounce
        case pound
        case stone
    }
}
    
open class MassFormatter : Formatter {
    
    public override init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonMassUse = false
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonMassUse = false
        super.init(coder:coder)
    }
    
    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NumberFormatter with NumberFormatter.Style.decimal
    open var unitStyle: UnitStyle // default is Formatting.UnitStyle.medium
    
    open var isForPersonMassUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromKilograms: and -unitStringFromKilograms: is considered as a person’s mass
    
    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: Unit) -> String {
        // special case: stone shows fractional values in pounds
        if unit == .stone {
            let stone = value.rounded(.towardZero)
            let stoneString = singlePartString(fromValue: stone, unit: unit) // calling `string(fromValue: stone, unit: .stone)` would infinitely recur
            let pounds = abs(value.truncatingRemainder(dividingBy: 1.0)) * MassFormatter.poundsPerStone
            
            // if we don't have any fractional component, don't append anything
            if pounds == 0 {
                return stoneString
            } else {
                let poundsString = string(fromValue: pounds, unit: .pound)
                let separator = unitStyle == .short ? " " : ", "
                
                return ("\(stoneString)\(separator)\(poundsString)")
            }
        }
        
        // normal case: kilograms and pounds
        return singlePartString(fromValue: value, unit: unit)
    }
    
    // Format a number in kilograms to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 1.2kg = 2.64lb in the US locale).
    open func string(fromKilograms numberInKilograms: Double) -> String {
        //Convert to the locale-appropriate unit
        let unitFromKilograms = convertedUnit(fromKilograms: numberInKilograms)
        
        //Map the unit to UnitMass type for conversion later
        let unitMassFromKilograms = MassFormatter.unitMass[unitFromKilograms]!
        
        //Create a measurement object based on the value in kilograms
        let kilogramMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)
        
        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = kilogramMeasurement.converted(to: unitMassFromKilograms)
        
        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value
        
        return string(fromValue: numberInUnit, unit: unitFromKilograms)
    }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    open func unitString(fromValue value: Double, unit: Unit) -> String {
        if unitStyle == .short {
            return MassFormatter.shortSymbol[unit]!
        } else if unitStyle == .medium {
            return MassFormatter.mediumSymbol[unit]!
        } else if unit == .stone { // special case, see `unitStringDisplayedAdjacent(toValue:, unit:)`
            return MassFormatter.largeSingularSymbol[unit]!
        } else if value == 1.0 {
            return MassFormatter.largeSingularSymbol[unit]!
        } else {
            return MassFormatter.largePluralSymbol[unit]!
        }
    }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromKilograms:.
    open func unitString(fromKilograms numberInKilograms: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String {
        //Convert to the locale-appropriate unit
        let unitFromKilograms = convertedUnit(fromKilograms: numberInKilograms)
        unitp?.pointee = unitFromKilograms
        
        //Map the unit to UnitMass type for conversion later
        let unitMassFromKilograms = MassFormatter.unitMass[unitFromKilograms]!
        
        //Create a measurement object based on the value in kilograms
        let kilogramMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)
        
        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = kilogramMeasurement.converted(to: unitMassFromKilograms)
        
        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value
        
        //Return the appropriate representation of the unit based on the selected unit style
        return unitString(fromValue: numberInUnit, unit: unitFromKilograms)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> Any? { return nil }
    
    
    // MARK: - Private
    
    /// This method selects the appropriate unit based on the formatter’s locale,
    /// the magnitude of the value, and isForPersonMassUse property.
    ///
    /// - Parameter numberInKilograms: the magnitude in terms of kilograms
    /// - Returns: Returns the appropriate unit
    private func convertedUnit(fromKilograms numberInKilograms: Double) -> Unit {
        if numberFormatter.locale.usesMetricSystem {
            if numberInKilograms > 1.0 || numberInKilograms <= 0.0 {
                return .kilogram
            } else {
                return .gram
            }
        } else {
            let metricMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)
            let imperialMeasurement = metricMeasurement.converted(to: .pounds)
            let numberInPounds = imperialMeasurement.value
            
            if numberInPounds >= 1.0 || numberInPounds <= 0.0  {
                return .pound
            } else {
                return .ounce
            }
        }
    }
    
    /// Formats the given value and unit into a string containing one logical 
    /// value. This is intended for units like kilogram and pound where 
    /// fractional values are represented as a decimal instead of converted 
    /// values in another unit.
    ///
    /// - Parameter value: The mass's value in the given unit.
    /// - Parameter unit: The unit used in the resulting mass string.
    /// - Returns: A properly formatted mass string for the given value and unit.
    private func singlePartString(fromValue value: Double, unit: Unit) -> String {
        guard let formattedValue = numberFormatter.string(from:NSNumber(value: value)) else {
            fatalError("Cannot format \(value) as string")
        }
        
        let separator = unitStyle == .short ? "" : " "
        
        return "\(formattedValue)\(separator)\(unitStringDisplayedAdjacent(toValue: value, unit: unit))"
    }
    
    /// Return the locale-appropriate unit to be shown adjacent to the given
    /// value.  In most cases this will match `unitStringDisplayedAdjacent(toValue:, unit:)` 
    /// however there are a few special cases:
    ///     - Imperial pounds with a short representation use "lb" in the
    ///       abstract and "#" only when shown with a numeral.
    ///     - Stones are are singular in the abstract and only plural when 
    ///       shown with a numeral.
    ///
    /// - Parameter value: The mass's value in the given unit.
    /// - Parameter unit: The unit used in the resulting mass string.
    /// - Returns: The locale-appropriate unit
    open func unitStringDisplayedAdjacent(toValue value: Double, unit: Unit) -> String {
        if unit == .pound && unitStyle == .short {
            return "#"
        } else if unit == .stone && unitStyle == .long {
            if value == 1.0 {
                return MassFormatter.largeSingularSymbol[unit]!
            } else {
                return MassFormatter.largePluralSymbol[unit]!
            }
        } else {
            return unitString(fromValue: value, unit: unit)
        }
    }
    

    
    /// The number of pounds in 1 stone
    private static let poundsPerStone = 14.0
    
    /// Maps MassFormatter.Unit enum to UnitMass class. Used for measurement conversion.
    private static let unitMass: [Unit: UnitMass] = [.gram: .grams,
                                                     .kilogram: .kilograms,
                                                     .ounce: .ounces,
                                                     .pound: .pounds,
                                                     .stone: .stones]
    
    /// Maps a unit to its short symbol. Reuses strings from UnitMass.
    private static let shortSymbol: [Unit: String] = [.gram: UnitMass.grams.symbol,
                                                      .kilogram: UnitMass.kilograms.symbol,
                                                      .ounce: UnitMass.ounces.symbol,
                                                      .pound: UnitMass.pounds.symbol, // see `unitStringDisplayedAdjacent(toValue:, unit:)`
                                                      .stone: UnitMass.stones.symbol]
    
    /// Maps a unit to its medium symbol. Reuses strings from UnitMass.
    private static let mediumSymbol: [Unit: String] = [.gram: UnitMass.grams.symbol,
                                                       .kilogram: UnitMass.kilograms.symbol,
                                                       .ounce: UnitMass.ounces.symbol,
                                                       .pound: UnitMass.pounds.symbol,
                                                       .stone: UnitMass.stones.symbol]
    
    /// Maps a unit to its large, singular symbol.
    private static let largeSingularSymbol: [Unit: String] = [.gram: "gram",
                                                              .kilogram: "kilogram",
                                                              .ounce: "ounce",
                                                              .pound: "pound",
                                                              .stone: "stone"]
    
    /// Maps a unit to its large, plural symbol.
    private static let largePluralSymbol: [Unit: String] = [.gram: "grams",
                                                            .kilogram: "kilograms",
                                                            .ounce: "ounces",
                                                            .pound: "pounds",
                                                            .stone: "stones"]
}
