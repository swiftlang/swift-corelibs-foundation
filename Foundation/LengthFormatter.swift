// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension LengthFormatter {
    public enum Unit: Int {
        case millimeter = 8
        case centimeter = 9
        case meter = 11
        case kilometer = 14
        case inch = 1281
        case foot = 1282
        case yard = 1283
        case mile = 1284
    }
}

open class LengthFormatter : Formatter {
    
    public override init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonHeightUse = false
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonHeightUse = false
        super.init(coder:coder)
    }
    
    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NumberFormatter with NumberFormatter.Style.decimal
    open var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    
    open var isForPersonHeightUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromMeters: and -unitStringFromMeters: is considered as a person's height
    
    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: LengthFormatter.Unit) -> String {
        guard let formattedValue = numberFormatter.string(from:NSNumber(value: value)) else {
            fatalError("Cannot format \(value) as string")
        }
        let separator = unitStyle == .short ? "" : " "
        return "\(formattedValue)\(separator)\(unitString(fromValue: value, unit: unit))"
    }
    
    // Format a number in meters to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 4.3m = 14.1ft in the US locale).
    open func string(fromMeters numberInMeters: Double) -> String {
        //Convert to the locale-appropriate unit
        let unitFromMeters = unit(fromMeters: numberInMeters)
        
        //Map the unit to UnitLength type for conversion later
        let unitLengthFromMeters = LengthFormatter.unitLength[unitFromMeters]!
        
        //Create a measurement object based on the value in meters
        let meterMeasurement = Measurement<UnitLength>(value:numberInMeters, unit: .meters)
        
        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = meterMeasurement.converted(to: unitLengthFromMeters)
        
        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value
        
        if isForPersonHeightUse && !numberFormatter.locale.usesMetricSystem {
            let feet = numberInUnit.rounded(.towardZero)
            let feetString = string(fromValue: feet, unit: .foot)
            
            let inches = abs(numberInUnit.truncatingRemainder(dividingBy: 1.0)) * 12
            let inchesString = string(fromValue: inches, unit: .inch)
            
            return ("\(feetString), \(inchesString)")
        }
        return string(fromValue: numberInUnit, unit: unitFromMeters)
    }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    open func unitString(fromValue value: Double, unit: Unit) -> String {
        if unitStyle == .short {
            return LengthFormatter.shortSymbol[unit]!
        } else if unitStyle == .medium {
            return LengthFormatter.mediumSymbol[unit]!
        } else if value == 1.0 {
            return LengthFormatter.largeSingularSymbol[unit]!
        } else {
            return LengthFormatter.largePluralSymbol[unit]!
        }
    }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromMeters:.
    open func unitString(fromMeters numberInMeters: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String {
        
        //Convert to the locale-appropriate unit
        let unitFromMeters = unit(fromMeters: numberInMeters)
        unitp?.pointee = unitFromMeters
        
        //Map the unit to UnitLength type for conversion later
        let unitLengthFromMeters = LengthFormatter.unitLength[unitFromMeters]!
        
        //Create a measurement object based on the value in meters
        let meterMeasurement = Measurement<UnitLength>(value:numberInMeters, unit: .meters)
        
        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = meterMeasurement.converted(to: unitLengthFromMeters)
        
        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value
        
        //Return the appropriate representation of the unit based on the selected unit style
        return unitString(fromValue: numberInUnit, unit: unitFromMeters)
    }
    
    /// This method selects the appropriate unit based on the formatter’s locale,
    /// the magnitude of the value, and isForPersonHeightUse property.
    ///
    /// - Parameter numberInMeters: the magnitude in terms of meters
    /// - Returns: Returns the appropriate unit
    private func unit(fromMeters numberInMeters: Double) -> Unit {
        if numberFormatter.locale.usesMetricSystem {
            //Person height is always returned in cm for metric system
            if isForPersonHeightUse { return .centimeter }
            
            if numberInMeters > 1000 || numberInMeters < 0.0 {
                return .kilometer
            } else if numberInMeters > 1.0 {
                return .meter
            } else if numberInMeters > 0.01 {
                return .centimeter
            } else { return .millimeter }
        } else {
            //Person height is always returned in ft for U.S. system
            if isForPersonHeightUse { return .foot }
            
            let metricMeasurement = Measurement<UnitLength>(value:numberInMeters, unit: .meters)
            let usMeasurement = metricMeasurement.converted(to: .feet)
            let numberInFeet = usMeasurement.value
            
            if numberInFeet < 0.0 || numberInFeet > 5280 {
                return .mile
            } else if numberInFeet > 3 || numberInFeet == 0.0 {
                return .yard
            } else if numberInFeet >= 1.0 {
                return .foot
            } else { return .inch }
        }
    }
    
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> Any? { return nil }
    
    
    /// Maps LengthFormatter.Unit enum to UnitLength class. Used for measurement conversion.
    private static let unitLength: [Unit:UnitLength] = [.millimeter:.millimeters,
                                                 .centimeter:.centimeters,
                                                 .meter:.meters,
                                                 .kilometer:.kilometers,
                                                 .inch:.inches,
                                                 .foot:.feet,
                                                 .yard:.yards,
                                                 .mile:.miles]

    /// Maps a unit to its short symbol. Reuses strings from UnitLength wherever possible.
    private static let shortSymbol: [Unit: String] = [.millimeter:UnitLength.millimeters.symbol,
                                                   .centimeter:UnitLength.centimeters.symbol,
                                                   .meter:UnitLength.meters.symbol,
                                                   .kilometer:UnitLength.kilometers.symbol,
                                                   .inch:"″",
                                                   .foot:"′",
                                                   .yard:UnitLength.yards.symbol,
                                                   .mile:UnitLength.miles.symbol]
    
    /// Maps a unit to its medium symbol. Reuses strings from UnitLength.
    private static let mediumSymbol: [Unit: String] = [.millimeter:UnitLength.millimeters.symbol,
                                                    .centimeter:UnitLength.centimeters.symbol,
                                                    .meter:UnitLength.meters.symbol,
                                                    .kilometer:UnitLength.kilometers.symbol,
                                                    .inch:UnitLength.inches.symbol,
                                                    .foot:UnitLength.feet.symbol,
                                                    .yard:UnitLength.yards.symbol,
                                                    .mile:UnitLength.miles.symbol]
    
    /// Maps a unit to its large, singular symbol.
    private static let largeSingularSymbol: [Unit: String] = [.millimeter:"millimeter",
                                                           .centimeter:"centimeter",
                                                           .meter:"meter",
                                                           .kilometer:"kilometer",
                                                           .inch:"inch",
                                                           .foot:"foot",
                                                           .yard:"yard",
                                                           .mile:"mile"]
    
    /// Maps a unit to its large, plural symbol.
    private static let largePluralSymbol: [Unit: String] = [.millimeter:"millimeters",
                                                         .centimeter:"centimeters",
                                                         .meter:"meters",
                                                         .kilometer:"kilometers",
                                                         .inch:"inches",
                                                         .foot:"feet",
                                                         .yard:"yards",
                                                         .mile:"miles"]
}
