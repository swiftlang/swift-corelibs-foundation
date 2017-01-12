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

        fileprivate var unitEnergy: UnitEnergy {
            switch self {
            case .joule:
                return UnitEnergy.joules
            case .kilojoule:
                return UnitEnergy.kilojoules
            case .calorie:
                return UnitEnergy.calories
            case .kilocalorie:
                return UnitEnergy.kilocalories
            }
        }

        fileprivate var symbol: String {
            return unitEnergy.symbol

        }

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

    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
    open var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    open var isForFoodEnergyUse: Bool // default is NO; if it is set to YES, NSEnergyFormatterUnitKilocalorie may be “C” instead of “kcal"

    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: Unit) -> String {
        guard let formattedValue = numberFormatter.string(from:NSNumber(value: value)) else {
            fatalError("Cannot format \(value) as string")
        }
        let separator = unitStyle == EnergyFormatter.UnitStyle.short ? "" : " "
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
        if isForFoodEnergyUse && unit == .kilocalorie {
            if unitStyle == .short || unitStyle == .medium {
                return Unit.calorie.symbol
            } else if value == 1.0 {
                return Unit.calorie.singularString
            } else {
                return Unit.calorie.pluralString
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

        if numberFormatter.locale.usesCalories {
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
}

/// TODO: Replace calls to the below function to use Locale.regionCode
/// Temporary workaround due to unpopulated Locale attributes
/// See https://bugs.swift.org/browse/SR-3202
extension Locale {
    public var usesCalories: Bool {

        switch self.identifier {
        case "en_US": return true
        case "en_US_POSIX": return true
        case "haw_US": return true
        case "es_US": return true
        case "chr_US": return true
        case "en_GB": return true
        case "kw_GB": return true
        case "cy_GB": return true
        case "gv_GB": return true
        default: return false
        }
    }
}
