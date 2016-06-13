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
    
public class MassFormatter : Formatter {
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ public var numberFormatter: NumberFormatter! // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
    public var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    public var isForPersonMassUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromKilograms: and -unitStringFromKilograms: is considered as a person’s mass
    
    // Format a combination of a number and an unit to a localized string.
    public func string(fromValue value: Double, unit: Unit) -> String { NSUnimplemented() }
    
    // Format a number in kilograms to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 1.2kg = 2.64lb in the US locale).
    public func string(fromKilograms numberInKilograms: Double) -> String { NSUnimplemented() }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    public func unitString(fromValue value: Double, unit: Unit) -> String { NSUnimplemented() }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromKilograms:.
    public func unitString(fromKilograms numberInKilograms: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String { NSUnimplemented() }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public override func objectValue(_ string: String) throws -> AnyObject? { return nil }
}

