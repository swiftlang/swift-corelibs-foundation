// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSLengthFormatterUnit : Int {
    
    case Millimeter
    case Centimeter
    case Meter
    case Kilometer
    case Inch
    case Foot
    case Yard
    case Mile
}

public class NSLengthFormatter : NSFormatter {
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ public var numberFormatter: NSNumberFormatter! // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
    public var unitStyle: NSFormattingUnitStyle // default is NSFormattingUnitStyleMedium
    
    public var forPersonHeightUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromMeters: and -unitStringFromMeters: is considered as a person's height
    
    // Format a combination of a number and an unit to a localized string.
    public func stringFromValue(_ value: Double, unit: NSLengthFormatterUnit) -> String { NSUnimplemented() }
    
    // Format a number in meters to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 4.3m = 14.1ft in the US locale).
    public func stringFromMeters(_ numberInMeters: Double) -> String { NSUnimplemented() }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    public func unitStringFromValue(_ value: Double, unit: NSLengthFormatterUnit) -> String { NSUnimplemented() }
    
    // Return the locale-appropriate unit, the same unit used by -stringFromMeters:.
    public func unitStringFromMeters(_ numberInMeters: Double, usedUnit unitp: UnsafeMutablePointer<NSLengthFormatterUnit>) -> String { NSUnimplemented() }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public override func objectValue(_ string: String) throws -> AnyObject? { return nil }
}


