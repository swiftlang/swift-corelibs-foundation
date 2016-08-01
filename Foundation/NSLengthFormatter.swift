// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension LengthFormatter {
    public enum Unit : Int {
        
        case millimeter
        case centimeter
        case meter
        case kilometer
        case inch
        case foot
        case yard
        case mile
    }
}

open class LengthFormatter : Formatter {
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
    open var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    
    open var isForPersonHeightUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromMeters: and -unitStringFromMeters: is considered as a person's height
    
    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: LengthFormatter.Unit) -> String { NSUnimplemented() }
    
    // Format a number in meters to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 4.3m = 14.1ft in the US locale).
    open func string(fromMeters numberInMeters: Double) -> String { NSUnimplemented() }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    open func unitString(fromValue value: Double, unit: Unit) -> String { NSUnimplemented() }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromMeters:.
    open func unitString(fromMeters numberInMeters: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String { NSUnimplemented() }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> AnyObject? { return nil }
}


