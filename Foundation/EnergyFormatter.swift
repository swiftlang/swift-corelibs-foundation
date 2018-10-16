// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension EnergyFormatter {
    public enum Unit: Int {

        case joule = 11
        case kilojoule = 14
        case calorie = 1793 // chemistry "calories", abbr "cal"
        case kilocalorie = 1794 // kilocalories in general, abbr “kcal”, or “C” in some locales (e.g. US) when usesFoodEnergy is set to YES

        // Map Unit to UnitEnergy class to aid with conversions
        fileprivate var unitEnergy: UnitEnergy {
            switch self {
            case .joule:
                return .joules
            case .kilojoule:
                return .kilojoules
            case .calorie:
                return .calories
            case .kilocalorie:
                return .kilocalories
            }
        }

        // Reuse symbols defined in UnitEnergy, except for kilocalories, which is defined as "kCal"
        fileprivate var symbol: String {
            switch self {
            case .kilocalorie:
                return "kcal"
            default:
                return unitEnergy.symbol
            }
        }

        // Return singular, full string representation of the energy unit
        fileprivate var singularString: String {
            switch self {
            case .joule:
                return "joule"
            case .kilojoule:
                return "kilojoule"
            case .calorie:
                return "calorie"
            case .kilocalorie:
                return "kilocalorie"
            }
        }
        
        // Return plural, full string representation of the energy unit
        fileprivate var pluralString: String {
            return "\(self.singularString)s"
        }
    }
}

open class EnergyFormatter: Formatter {

    public override init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForFoodEnergyUse = false
        super.init()
    }

    public required init?(coder: NSCoder) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForFoodEnergyUse = false
        super.init()
    }

    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NumberFormatter with NumberFormatter.Style.decimal
    open var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    open var isForFoodEnergyUse: Bool // default is NO; if it is set to YES, EnergyFormatter.Unit.kilocalorie may be “C” instead of “kcal"

    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: Unit) -> String {
        guard let formattedValue = numberFormatter.string(from:NSNumber(value: value)) else {
            fatalError("Cannot format \(value) as string")
        }
        
        let separator = unitStyle == .short ? "" : " "
        return "\(formattedValue)\(separator)\(unitString(fromValue: value, unit: unit))"
    }

    // Format a number in joules to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 10.3J = 2.46cal in the US locale).
    open func string(fromJoules numberInJoules: Double) -> String {

        //Convert to the locale-appropriate unit
        var unitFromJoules: EnergyFormatter.Unit = .joule
        _ = self.unitString(fromJoules: numberInJoules, usedUnit: &unitFromJoules)

        //Map the unit to UnitLength type for conversion later
        let unitEnergyFromJoules = unitFromJoules.unitEnergy

        //Create a measurement object based on the value in joules
        let joulesMeasurement = Measurement<UnitEnergy>(value:numberInJoules, unit: .joules)

        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = joulesMeasurement.converted(to: unitEnergyFromJoules)

        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value

        return string(fromValue: numberInUnit, unit: unitFromJoules)
    }

    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    open func unitString(fromValue value: Double, unit: Unit) -> String {
        
        //Special case when isForFoodEnergyUse is true
        if isForFoodEnergyUse && unit == .kilocalorie {
            if unitStyle == .short {
                return "C"
            } else if unitStyle == .medium {
                return "Cal"
            } else {
                return "Calories"
            }
        }
        
        if unitStyle == .short || unitStyle == .medium {
            return unit.symbol
        } else if value == 1.0 {
            return unit.singularString
        } else {
            return unit.pluralString
        }
    }

    // Return the locale-appropriate unit, the same unit used by -stringFromJoules:.
    open func unitString(fromJoules numberInJoules: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String {

        //Convert to the locale-appropriate unit
        let unitFromJoules: Unit

        if self.usesCalories {
            if numberInJoules > 0 && numberInJoules <= 4184 {
                unitFromJoules = .calorie
            } else {
                unitFromJoules = .kilocalorie
            }
        } else {
            if numberInJoules > 0 && numberInJoules <= 1000 {
                unitFromJoules = .joule
            } else {
                unitFromJoules = .kilojoule
            }
        }
        unitp?.pointee = unitFromJoules

        //Map the unit to UnitEnergy type for conversion later
        let unitEnergyFromJoules = unitFromJoules.unitEnergy

        //Create a measurement object based on the value in joules
        let joulesMeasurement = Measurement<UnitEnergy>(value:numberInJoules, unit: .joules)

        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = joulesMeasurement.converted(to: unitEnergyFromJoules)

        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value

        //Return the appropriate representation of the unit based on the selected unit style
        return unitString(fromValue: numberInUnit, unit: unitFromJoules)
    }

    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> Any? { return nil }
    
    /// Regions that use calories
    private static let caloriesRegions: Set<String> = ["en_US", "en_US_POSIX", "haw_US", "es_US", "chr_US", "en_GB", "kw_GB", "cy_GB", "gv_GB"]
    
    /// Whether the region uses calories
    private var usesCalories: Bool {
        return EnergyFormatter.caloriesRegions.contains(numberFormatter.locale.identifier)
    }
    
}
