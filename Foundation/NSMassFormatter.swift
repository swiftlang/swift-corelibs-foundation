// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSMassFormatterUnit : Int {
    
    case Gram
    case Kilogram
    case Ounce
    case Pound
    case Stone
}

internal let NSMassFormatterScaleKilogram: String = "kg"
internal let NSMassFormatterScaleGram: String = "g"
internal let NSMassFormatterScalePound: String = "lb"
internal let NSMassFormatterScaleOunce: String = "oz"
internal let NSMassFormatterScalePoundStyleShort: String = "#"
internal let NSMassFormatterScaleKilogramStyleLong: String = "kilograms"
internal let NSMassFormatterScaleGramStyleLong: String = "grams"
internal let NSMassFormatterScalePoundStyleLong: String = "pounds"
internal let NSMassFormatterScaleOunceStyleLong: String = "ounces"
internal let NSMassFormatterKgtoLb: Double = 2.2046226218 // 1 kg = 2.2046226218 lb
internal let NSMassFormatterKgtoG: Double = 1000.0 // 1 kg = 1000.0 g
internal let NSMassFormatterLbtoOz: Double = 16.0 // 1 lb = 16.0 oz
internal let NSMassFormatterStoneToKg: Double = 6.35029 // 1 stone = 6.35029 kg


public class NSMassFormatter : NSFormatter {
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /*@NSCopying*/ public var numberFormatter: NSNumberFormatter!  {   // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale.currentLocale()
        numForm.numberStyle = .DecimalStyle
        return numForm
    }
    public var unitStyle: NSFormattingUnitStyle = .Medium // default is NSFormattingUnitStyleMedium
    public var forPersonMassUse: Bool = false // default is NO; if it is set to YES, the number argument for -stringFromKilograms: and -unitStringFromKilograms: is considered as a person’s mass
    
    // Format a combination of a number and an unit to a localized string.
    public func stringFromValue(_ value: Double, unit: NSMassFormatterUnit) -> String { NSUnimplemented() }
    
    // Format a number in kilograms to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 1.2kg = 2.64lb in the US locale).
    public func stringFromKilograms(_ numberInKilograms: Double) -> String {

        var usedUnit = NSMassFormatterUnit.Kilogram
        let kilogramsValues = calculateNumberAndUnitForKilograms(numberInKilograms,usedUnit:&usedUnit)
        return kilogramsValues.formatedNumber + (unitStyle == .Short ? "" : " " ) + kilogramsValues.unitScale
    
    }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    public func unitStringFromValue(_ value: Double, unit: NSMassFormatterUnit) -> String { NSUnimplemented() }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromKilograms:.
    public func unitStringFromKilograms(_ numberInKilograms: Double, usedUnit unitp: UnsafeMutablePointer<NSMassFormatterUnit>) -> String {
    
        return calculateNumberAndUnitForKilograms(numberInKilograms,usedUnit: unitp).unitScale
    
    }
    
    private func calculateNumberAndUnitForKilograms(_ numberToConvertToKG: Double, usedUnit unitp: UnsafeMutablePointer<NSMassFormatterUnit>) -> (formatedNumber:String , unitScale:String) {
        var scale = ""
        var isLessThanOne = false
        var useMetricSystem = true
        var numberInKilograms:Double = 0.0
        
        switch unitp.pointee{
        case .Gram:
            numberInKilograms = numberToConvertToKG / NSMassFormatterKgtoG
        case .Ounce:
            numberInKilograms = (numberToConvertToKG / NSMassFormatterKgtoLb) / NSMassFormatterLbtoOz
        case .Pound:
            numberInKilograms = numberToConvertToKG / NSMassFormatterKgtoLb
        case .Stone:
            numberInKilograms = numberToConvertToKG * NSMassFormatterStoneToKg
        default:
            numberInKilograms = numberToConvertToKG
        }
        
        var numberToFormat = numberInKilograms

        if numberFormatter.locale.objectForKey(NSLocaleLanguageCode) != nil { //Workaround because I'm getting "empty" locale
            guard let useMetricSys = numberFormatter.locale.objectForKey(NSLocaleUsesMetricSystem) as? Bool else {
                return (String(numberToFormat), "")
            }
            useMetricSystem = useMetricSys
        } else {
            useMetricSystem = false // set use metric system to false so I can test like en_US locale
        }
        
        
        if useMetricSystem == true {
            
            if numberToFormat < 1 {
                numberToFormat = numberToFormat * NSMassFormatterKgtoG
                isLessThanOne = true
            }
            
            switch unitStyle {
            case .Short:
                scale = isLessThanOne ? NSMassFormatterScaleGram : NSMassFormatterScaleKilogram
            case .Long:
                scale = isLessThanOne ? NSMassFormatterScaleGramStyleLong : NSMassFormatterScaleKilogramStyleLong
            default:
                scale = isLessThanOne ? NSMassFormatterScaleGram : NSMassFormatterScaleKilogram
            }
            
        } else {
            numberToFormat = numberInKilograms * NSMassFormatterKgtoLb
            
            if numberToFormat < 1 {
                numberToFormat = numberToFormat * NSMassFormatterLbtoOz
                isLessThanOne = true
            }
            
            switch unitStyle {
            case .Short:
                scale = isLessThanOne ? NSMassFormatterScaleOunce : NSMassFormatterScalePoundStyleShort
            case .Long:
                scale = isLessThanOne ? NSMassFormatterScaleOunceStyleLong : NSMassFormatterScalePoundStyleLong
            default:
                scale = isLessThanOne ? NSMassFormatterScaleOunce : NSMassFormatterScalePound
            }
        }
        
        guard let formatedNumber = numberFormatter.stringFromNumber(NSNumber(double:numberToFormat)) else {
            return (String(numberToFormat), "")
        }
        
        
        return (String(formatedNumber),scale)

    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public override func objectValue(_ string: String) throws -> AnyObject? { return nil }
}

