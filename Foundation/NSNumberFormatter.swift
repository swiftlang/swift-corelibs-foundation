// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



public class NSNumberFormatter : NSFormatter {
    
    public override init() { NSUnimplemented() }
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    // this is for NSUnitFormatter
    
    public var formattingContext: NSFormattingContext // default is NSFormattingContextUnknown
    
    // Report the used range of the string and an NSError, in addition to the usual stuff from NSFormatter
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func objectValue(string: String, inout range: NSRange) throws -> AnyObject? { NSUnimplemented() }
    
    // Even though NSNumberFormatter responds to the usual NSFormatter methods,
    //   here are some convenience methods which are a little more obvious.
    
    public func stringFromNumber(number: NSNumber) -> String? { NSUnimplemented() }
    public func numberFromString(string: String) -> NSNumber? { NSUnimplemented() }
    
    public class func localizedStringFromNumber(num: NSNumber, numberStyle nstyle: NSNumberFormatterStyle) -> String { NSUnimplemented() }
    
    // Attributes of an NSNumberFormatter
    
    public var numberStyle: NSNumberFormatterStyle
    /*@NSCopying*/ public var locale: NSLocale!
    public var generatesDecimalNumbers: Bool
    
    public var negativeFormat: String!
    public var textAttributesForNegativeValues: [String : AnyObject]?
    public var positiveFormat: String!
    public var textAttributesForPositiveValues: [String : AnyObject]?
    public var allowsFloats: Bool
    public var decimalSeparator: String!
    public var alwaysShowsDecimalSeparator: Bool
    public var currencyDecimalSeparator: String!
    public var usesGroupingSeparator: Bool
    public var groupingSeparator: String!
    
    public var zeroSymbol: String?
    public var textAttributesForZero: [String : AnyObject]?
    public var nilSymbol: String
    public var textAttributesForNil: [String : AnyObject]?
    public var notANumberSymbol: String!
    public var textAttributesForNotANumber: [String : AnyObject]?
    public var positiveInfinitySymbol: String
    public var textAttributesForPositiveInfinity: [String : AnyObject]?
    public var negativeInfinitySymbol: String
    public var textAttributesForNegativeInfinity: [String : AnyObject]?
    
    public var positivePrefix: String!
    public var positiveSuffix: String!
    public var negativePrefix: String!
    public var negativeSuffix: String!
    public var currencyCode: String!
    public var currencySymbol: String!
    public var internationalCurrencySymbol: String!
    public var percentSymbol: String!
    public var perMillSymbol: String!
    public var minusSign: String!
    public var plusSign: String!
    public var exponentSymbol: String!
    
    public var groupingSize: Int
    public var secondaryGroupingSize: Int
    /*@NSCopying*/ public var multiplier: NSNumber?
    public var formatWidth: Int
    public var paddingCharacter: String!
    
    public var paddingPosition: NSNumberFormatterPadPosition
    public var roundingMode: NSNumberFormatterRoundingMode
    /*@NSCopying*/ public var roundingIncrement: NSNumber!
    public var minimumIntegerDigits: Int
    public var maximumIntegerDigits: Int
    public var minimumFractionDigits: Int
    public var maximumFractionDigits: Int
    /*@NSCopying*/ public var minimum: NSNumber?
    /*@NSCopying*/ public var maximum: NSNumber?
    public var currencyGroupingSeparator: String!
    public var lenient: Bool
    public var usesSignificantDigits: Bool
    public var minimumSignificantDigits: Int
    public var maximumSignificantDigits: Int
    public var partialStringValidationEnabled: Bool
    
    public var hasThousandSeparators: Bool
    public var thousandSeparator: String!
    
    public var localizesFormat: Bool
    
    public var format: String
    
    /*@NSCopying*/ public var attributedStringForZero: NSAttributedString
    /*@NSCopying*/ public var attributedStringForNil: NSAttributedString
    /*@NSCopying*/ public var attributedStringForNotANumber: NSAttributedString
    
    /*@NSCopying*/ public var roundingBehavior: NSDecimalNumberHandler
}

public enum NSNumberFormatterStyle : UInt {
    case NoStyle
    case DecimalStyle
    case CurrencyStyle
    case PercentStyle
    case ScientificStyle
    case SpellOutStyle
    case OrdinalStyle
    case CurrencyISOCodeStyle
    case CurrencyPluralStyle
    case CurrencyAccountingStyle
}

public enum NSNumberFormatterPadPosition : UInt {
    case BeforePrefix
    case AfterPrefix
    case BeforeSuffix
    case AfterSuffix
}

public enum NSNumberFormatterRoundingMode : UInt {
    case RoundCeiling
    case RoundFloor
    case RoundDown
    case RoundUp
    case RoundHalfEven
    case RoundHalfDown
    case RoundHalfUp
}


