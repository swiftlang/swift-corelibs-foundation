// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFNumberFormatterNoStyle = CFNumberFormatterStyle.NoStyle
internal let kCFNumberFormatterDecimalStyle = CFNumberFormatterStyle.DecimalStyle
internal let kCFNumberFormatterCurrencyStyle = CFNumberFormatterStyle.CurrencyStyle
internal let kCFNumberFormatterPercentStyle = CFNumberFormatterStyle.PercentStyle
internal let kCFNumberFormatterScientificStyle = CFNumberFormatterStyle.ScientificStyle
internal let kCFNumberFormatterSpellOutStyle = CFNumberFormatterStyle.SpellOutStyle
internal let kCFNumberFormatterOrdinalStyle = CFNumberFormatterStyle.OrdinalStyle
internal let kCFNumberFormatterCurrencyISOCodeStyle = CFNumberFormatterStyle.CurrencyISOCodeStyle
internal let kCFNumberFormatterCurrencyPluralStyle = CFNumberFormatterStyle.CurrencyPluralStyle
internal let kCFNumberFormatterCurrencyAccountingStyle = CFNumberFormatterStyle.CurrencyAccountingStyle
#endif

public class NSNumberFormatter : NSFormatter {
    
    typealias CFType = CFNumberFormatterRef
    private var _currentCfFormatter: CFType?
    private var _cfFormatter: CFType {
        if let obj = _currentCfFormatter {
            return obj
        } else {
            #if os(OSX) || os(iOS)
                let numberStyle = CFNumberFormatterStyle(rawValue: CFIndex(self.numberStyle.rawValue))!
            #else
                let numberStyle = CFNumberFormatterStyle(self.numberStyle.rawValue)
            #endif
            
            let obj = CFNumberFormatterCreate(kCFAllocatorSystemDefault, locale._cfObject, numberStyle)
            _setFormatterAttributes(obj)
            _currentCfFormatter = obj
            return obj
        }
    }
    
    // this is for NSUnitFormatter
    
    public var formattingContext: NSFormattingContext = .Unknown // default is NSFormattingContextUnknown
    
    // Report the used range of the string and an NSError, in addition to the usual stuff from NSFormatter
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func objectValue(string: String, inout range: NSRange) throws -> AnyObject? { NSUnimplemented() }
    
    // Even though NSNumberFormatter responds to the usual NSFormatter methods,
    //   here are some convenience methods which are a little more obvious.
    public func stringFromNumber(number: NSNumber) -> String? {
        return CFNumberFormatterCreateStringWithNumber(kCFAllocatorSystemDefault, _cfFormatter, number._cfObject)._swiftObject
    }
    
    public func numberFromString(string: String) -> NSNumber? {
        var range = CFRange()
        let number = withUnsafeMutablePointer(&range) { (rangePointer: UnsafeMutablePointer<CFRange>) -> NSNumber? in
            
            #if os(OSX) || os(iOS)
                let result = CFNumberFormatterCreateNumberFromString(kCFAllocatorSystemDefault, _cfFormatter, string._cfObject, rangePointer, CFNumberFormatterOptionFlags.ParseIntegersOnly.rawValue)
            #else
                let result = CFNumberFormatterCreateNumberFromString(kCFAllocatorSystemDefault, _cfFormatter, string._cfObject, rangePointer, CFOptionFlags(kCFNumberFormatterParseIntegersOnly))
            #endif

            return result?._nsObject
        }
        return number
    }
    
    public class func localizedStringFromNumber(num: NSNumber, numberStyle nstyle: NSNumberFormatterStyle) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = nstyle
        return numberFormatter.stringForObjectValue(num)!
    }
    
    internal func _reset() {
        _currentCfFormatter = nil
    }
    
    internal func _setFormatterAttributes(formatter: CFNumberFormatterRef) {
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyCode, value: _currencyCode?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterDecimalSeparator, value: _decimalSeparator?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyDecimalSeparator, value: _currencyDecimalSeparator?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterAlwaysShowDecimalSeparator, value: _alwaysShowsDecimalSeparator._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterGroupingSeparator, value: _groupingSeparator?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterUseGroupingSeparator, value: _usesGroupingSeparator._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPercentSymbol, value: _percentSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterZeroSymbol, value: _zeroSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNaNSymbol, value: _notANumberSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterInfinitySymbol, value: _positiveInfinitySymbol._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinusSign, value: _minusSign?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPlusSign, value: _plusSign?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencySymbol, value: _currencySymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterExponentSymbol, value: _exponentSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinIntegerDigits, value: _minimumIntegerDigits._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxIntegerDigits, value: _maximumIntegerDigits._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinFractionDigits, value: _minimumFractionDigits._bridgeToObject()._cfObject)
        if _minimumFractionDigits <= 0 {
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxFractionDigits, value: _maximumFractionDigits._bridgeToObject()._cfObject)
        }
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterGroupingSize, value: _groupingSize._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterSecondaryGroupingSize, value: _secondaryGroupingSize._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingMode, value: _roundingMode.rawValue._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingIncrement, value: _roundingIncrement?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterFormatWidth, value: _formatWidth._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingCharacter, value: _paddingCharacter?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingPosition, value: _paddingPosition.rawValue._bridgeToObject()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMultiplier, value: _multiplier?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositivePrefix, value: _positivePrefix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositiveSuffix, value: _positiveSuffix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativePrefix, value: _negativePrefix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativeSuffix, value: _negativeSuffix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPerMillSymbol, value: _percentSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterInternationalCurrencySymbol, value: _internationalCurrencySymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyGroupingSeparator, value: _currencyGroupingSeparator?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterIsLenient, value: kCFBooleanTrue)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterUseSignificantDigits, value: _usesSignificantDigits._cfObject)
        if _usesSignificantDigits {
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinSignificantDigits, value: _minimumSignificantDigits._bridgeToObject()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxSignificantDigits, value: _maximumSignificantDigits._bridgeToObject()._cfObject)
        }
    }
    
    internal func _setFormatterAttribute(formatter: CFNumberFormatterRef, attributeName: CFString, value: AnyObject?) {
        if let value = value {
            CFNumberFormatterSetProperty(formatter, attributeName, value)
        }
    }
    
    // Attributes of an NSNumberFormatter
    internal var _numberStyle: NSNumberFormatterStyle = .NoStyle
    public var numberStyle: NSNumberFormatterStyle {
        get {
            return _numberStyle
        }
        
        set {
            switch newValue {
            case .NoStyle, .OrdinalStyle, .SpellOutStyle:
                _usesSignificantDigits = false
                
            case .CurrencyStyle, .CurrencyPluralStyle, .CurrencyISOCodeStyle, .CurrencyAccountingStyle:
                _usesSignificantDigits = false
                _usesGroupingSeparator = true
                _minimumFractionDigits = 2
                
            default:
                _usesSignificantDigits = true
                _usesGroupingSeparator = true
            }
            _reset()
            _numberStyle = newValue
        }
    }
    
    internal var _locale: NSLocale = NSLocale.currentLocale()
    /*@NSCopying*/ public var locale: NSLocale! {
        get {
            return _locale
        }
        set {
            _reset()
            _locale = newValue
        }
    }
    
    internal var _generatesDecimalNumbers: Bool = false
    public var generatesDecimalNumbers: Bool {
        get {
            return _generatesDecimalNumbers
        }
        set {
            _reset()
            _generatesDecimalNumbers = newValue
        }
    }
    
    internal var _negativeFormat: String!
    public var negativeFormat: String! {
        get {
            return _negativeFormat
        }
        set {
            _reset()
            _negativeFormat = newValue
        }
    }
    
    internal var _textAttributesForNegativeValues: [String : AnyObject]?
    public var textAttributesForNegativeValues: [String : AnyObject]? {
        get {
            return _textAttributesForNegativeValues
        }
        set {
            _reset()
            _textAttributesForNegativeValues = newValue
        }
    }
    
    internal var _positiveFormat: String!
    public var positiveFormat: String! {
        get {
            return _positiveFormat
        }
        set {
            _reset()
            _positiveFormat = newValue
        }
    }
    
    internal var _textAttributesForPositiveValues: [String : AnyObject]?
    public var textAttributesForPositiveValues: [String : AnyObject]? {
        get {
            return _textAttributesForPositiveValues
        }
        set {
            _reset()
            _textAttributesForPositiveValues = newValue
        }
    }
    
    internal var _allowsFloats: Bool = true
    public var allowsFloats: Bool {
        get {
            return _allowsFloats
        }
        set {
            _reset()
            _allowsFloats = newValue
        }
    }

    internal var _decimalSeparator: String!
    public var decimalSeparator: String! {
        get {
            return _decimalSeparator
        }
        set {
            _reset()
            _decimalSeparator = newValue
        }
    }
    
    internal var _alwaysShowsDecimalSeparator: Bool = false
    public var alwaysShowsDecimalSeparator: Bool {
        get {
            return _alwaysShowsDecimalSeparator
        }
        set {
            _reset()
            _alwaysShowsDecimalSeparator = newValue
        }
    }
    
    internal var _currencyDecimalSeparator: String!
    public var currencyDecimalSeparator: String! {
        get {
            return _currencyDecimalSeparator
        }
        set {
            _reset()
            _currencyDecimalSeparator = newValue
        }
    }
    
    internal var _usesGroupingSeparator: Bool = false
    public var usesGroupingSeparator: Bool {
        get {
            return _usesGroupingSeparator
        }
        set {
            _reset()
            _usesGroupingSeparator = newValue
        }
    }
    
    internal var _groupingSeparator: String!
    public var groupingSeparator: String! {
        get {
            return _groupingSeparator
        }
        set {
            _reset()
            _groupingSeparator = newValue
        }
    }
    
    //
    
    internal var _zeroSymbol: String?
    public var zeroSymbol: String? {
        get {
            return _zeroSymbol
        }
        set {
            _reset()
            _zeroSymbol = newValue
        }
    }
    
    internal var _textAttributesForZero: [String : AnyObject]?
    public var textAttributesForZero: [String : AnyObject]? {
        get {
            return _textAttributesForZero
        }
        set {
            _reset()
            _textAttributesForZero = newValue
        }
    }
    
    internal var _nilSymbol: String = ""
    public var nilSymbol: String {
        get {
            return _nilSymbol
        }
        set {
            _reset()
            _nilSymbol = newValue
        }
    }
    
    internal var _textAttributesForNil: [String : AnyObject]?
    public var textAttributesForNil: [String : AnyObject]? {
        get {
            return _textAttributesForNil
        }
        set {
            _reset()
            _textAttributesForNil = newValue
        }
    }
    
    internal var _notANumberSymbol: String!
    public var notANumberSymbol: String! {
        get {
            return _notANumberSymbol
        }
        set {
            _reset()
            _notANumberSymbol = newValue
        }
    }
    
    internal var _textAttributesForNotANumber: [String : AnyObject]?
    public var textAttributesForNotANumber: [String : AnyObject]? {
        get {
            return _textAttributesForNotANumber
        }
        set {
            _reset()
            _textAttributesForNotANumber = newValue
        }
    }
    
    internal var _positiveInfinitySymbol: String = "+∞"
    public var positiveInfinitySymbol: String {
        get {
            return _positiveInfinitySymbol
        }
        set {
            _reset()
            _positiveInfinitySymbol = newValue
        }
    }
    
    internal var _textAttributesForPositiveInfinity: [String : AnyObject]?
    public var textAttributesForPositiveInfinity: [String : AnyObject]? {
        get {
            return _textAttributesForPositiveInfinity
        }
        set {
            _reset()
            _textAttributesForPositiveInfinity = newValue
        }
    }
    
    internal var _negativeInfinitySymbol: String = "-∞"
    public var negativeInfinitySymbol: String {
        get {
            return _negativeInfinitySymbol
        }
        set {
            _reset()
            _negativeInfinitySymbol = newValue
        }
    }
    
    internal var _textAttributesForNegativeInfinity: [String : AnyObject]?
    public var textAttributesForNegativeInfinity: [String : AnyObject]? {
        get {
            return _textAttributesForNegativeInfinity
        }
        set {
            _reset()
            _textAttributesForNegativeInfinity = newValue
        }
    }
    
    //
    
    internal var _positivePrefix: String!
    public var positivePrefix: String! {
        get {
            return _positivePrefix
        }
        set {
            _reset()
            _positivePrefix = newValue
        }
    }
    
    internal var _positiveSuffix: String!
    public var positiveSuffix: String! {
        get {
            return _positiveSuffix
        }
        set {
            _reset()
            _positiveSuffix = newValue
        }
    }
    
    internal var _negativePrefix: String!
    public var negativePrefix: String! {
        get {
            return _negativePrefix
        }
        set {
            _reset()
            _negativePrefix = newValue
        }
    }
    
    internal var _negativeSuffix: String!
    public var negativeSuffix: String! {
        get {
            return _negativeSuffix
        }
        set {
            _reset()
            _negativeSuffix = newValue
        }
    }
    
    internal var _currencyCode: String!
    public var currencyCode: String! {
        get {
            return _currencyCode
        }
        set {
            _reset()
            _currencyCode = newValue
        }
    }
    
    internal var _currencySymbol: String!
    public var currencySymbol: String! {
        get {
            return _currencySymbol
        }
        set {
            _reset()
            _currencySymbol = newValue
        }
    }
    
    internal var _internationalCurrencySymbol: String!
    public var internationalCurrencySymbol: String! {
        get {
            return _internationalCurrencySymbol
        }
        set {
            _reset()
            _internationalCurrencySymbol = newValue
        }
    }
    
    internal var _percentSymbol: String!
    public var percentSymbol: String! {
        get {
            return _percentSymbol
        }
        set {
            _reset()
            _percentSymbol = newValue
        }
    }
    
    internal var _perMillSymbol: String!
    public var perMillSymbol: String! {
        get {
            return _perMillSymbol
        }
        set {
            _reset()
            _perMillSymbol = newValue
        }
    }
    
    internal var _minusSign: String!
    public var minusSign: String! {
        get {
            return _minusSign
        }
        set {
            _reset()
            _minusSign = newValue
        }
    }
    
    internal var _plusSign: String!
    public var plusSign: String! {
        get {
            return _plusSign
        }
        set {
            _reset()
            _plusSign = newValue
        }
    }
    
    public var _exponentSymbol: String!
    public var exponentSymbol: String! {
        get {
            return _exponentSymbol
        }
        set {
            _reset()
            _exponentSymbol = newValue
        }
    }
    
    //
    
    internal var _groupingSize: Int = 3
    public var groupingSize: Int {
        get {
            return _groupingSize
        }
        set {
            _reset()
            _groupingSize = newValue
        }
    }
    
    internal var _secondaryGroupingSize: Int = 0
    public var secondaryGroupingSize: Int {
        get {
            return _secondaryGroupingSize
        }
        set {
            _reset()
            _secondaryGroupingSize = newValue
        }
    }
    
    internal var _multiplier: NSNumber?
    /*@NSCopying*/ public var multiplier: NSNumber? {
        get {
            return _multiplier
        }
        set {
            _reset()
            _multiplier = newValue
        }
    }
    
    internal var _formatWidth: Int = 0
    public var formatWidth: Int {
        get {
            return _formatWidth
        }
        set {
            _reset()
            _formatWidth = newValue
        }
    }
    
    internal var _paddingCharacter: String!
    public var paddingCharacter: String! {
        get {
            return _paddingCharacter
        }
        set {
            _reset()
            _paddingCharacter = newValue
        }
    }
    
    //
    
    internal var _paddingPosition: NSNumberFormatterPadPosition = .BeforePrefix
    public var paddingPosition: NSNumberFormatterPadPosition {
        get {
            return _paddingPosition
        }
        set {
            _reset()
            _paddingPosition = newValue
        }
    }
    
    internal var _roundingMode: NSNumberFormatterRoundingMode = .RoundHalfEven
    public var roundingMode: NSNumberFormatterRoundingMode {
        get {
            return _roundingMode
        }
        set {
            _reset()
            _roundingMode = newValue
        }
    }
    
    internal var _roundingIncrement: NSNumber! = 0
    /*@NSCopying*/ public var roundingIncrement: NSNumber! {
        get {
            return _roundingIncrement
        }
        set {
            _reset()
            _roundingIncrement = newValue
        }
    }
    
    internal var _minimumIntegerDigits: Int = 0
    public var minimumIntegerDigits: Int {
        get {
            return _minimumIntegerDigits
        }
        set {
            _reset()
            _minimumIntegerDigits = newValue
        }
    }
    
    internal var _maximumIntegerDigits: Int = 42
    public var maximumIntegerDigits: Int {
        get {
            return _maximumIntegerDigits
        }
        set {
            _reset()
            _maximumIntegerDigits = newValue
        }
    }
    
    internal var _minimumFractionDigits: Int = 0
    public var minimumFractionDigits: Int {
        get {
            return _minimumFractionDigits
        }
        set {
            _reset()
            _minimumFractionDigits = newValue
        }
    }
    
    internal var _maximumFractionDigits: Int = 0
    public var maximumFractionDigits: Int {
        get {
            return _maximumFractionDigits
        }
        set {
            _reset()
            _maximumFractionDigits = newValue
        }
    }
    
    internal var _minimum: NSNumber?
    /*@NSCopying*/ public var minimum: NSNumber? {
        get {
            return _minimum
        }
        set {
            _reset()
            _minimum = newValue
        }
    }
    
    internal var _maximum: NSNumber?
    /*@NSCopying*/ public var maximum: NSNumber? {
        get {
            return _maximum
        }
        set {
            _reset()
            _maximum = newValue
        }
    }
    
    internal var _currencyGroupingSeparator: String!
    public var currencyGroupingSeparator: String! {
        get {
            return _currencyGroupingSeparator
        }
        set {
            _reset()
            _currencyGroupingSeparator = newValue
        }
    }
    
    internal var _lenient: Bool = false
    public var lenient: Bool {
        get {
            return _lenient
        }
        set {
            _reset()
            _lenient = newValue
        }
    }
    
    internal var _usesSignificantDigits: Bool = false
    public var usesSignificantDigits: Bool {
        get {
            return _usesSignificantDigits
        }
        set {
            _reset()
            _usesSignificantDigits = newValue
        }
    }
    
    internal var _minimumSignificantDigits: Int = 1
    public var minimumSignificantDigits: Int {
        get {
            return _minimumSignificantDigits
        }
        set {
            _reset()
            _minimumSignificantDigits = newValue
        }
    }
    
    internal var _maximumSignificantDigits: Int = 6
    public var maximumSignificantDigits: Int {
        get {
            return _maximumSignificantDigits
        }
        set {
            _reset()
            _maximumSignificantDigits = newValue
        }
    }
    
    internal var _partialStringValidationEnabled: Bool = false
    public var partialStringValidationEnabled: Bool {
        get {
            return _partialStringValidationEnabled
        }
        set {
            _reset()
            _partialStringValidationEnabled = newValue
        }
    }
    
    //
    
    internal var _hasThousandSeparators: Bool = false
    public var hasThousandSeparators: Bool {
        get {
            return _hasThousandSeparators
        }
        set {
            _reset()
            _hasThousandSeparators = newValue
        }
    }
    
    internal var _thousandSeparator: String!
    public var thousandSeparator: String! {
        get {
            return _thousandSeparator
        }
        set {
            _reset()
            _thousandSeparator = newValue
        }
    }
    
    //
    
    internal var _localizesFormat: Bool = true
    public var localizesFormat: Bool {
        get {
            return _localizesFormat
        }
        set {
            _reset()
            _localizesFormat = newValue
        }
    }
    
    //
    
    internal var _format: String = "#;0;#"
    public var format: String {
        get {
            return _format
        }
        set {
            _reset()
            _format = newValue
        }
    }
    
    //
    
    //FIXME: Uncomment these when NSAttributedString get rid of NSUnimplementend(), 
    // this is currently commented out so that NSNumberFormatter instances can be tested
    
//    internal var _attributedStringForZero: NSAttributedString = NSAttributedString(string: "0")
//    /*@NSCopying*/ public var attributedStringForZero: NSAttributedString {
//        get {
//            return _attributedStringForZero
//        }
//        set {
//            _reset()
//            _attributedStringForZero = newValue
//        }
//    }
//    
//    internal var _attributedStringForNil: NSAttributedString = NSAttributedString(string: "")
//    /*@NSCopying*/ public var attributedStringForNil: NSAttributedString {
//        get {
//            return _attributedStringForNil
//        }
//        set {
//            _reset()
//            _attributedStringForNil = newValue
//        }
//    }
//    
//    internal var _attributedStringForNotANumber: NSAttributedString = NSAttributedString(string: "NaN")
//    /*@NSCopying*/ public var attributedStringForNotANumber: NSAttributedString {
//        get {
//            return _attributedStringForNotANumber
//        }
//        set {
//            _reset()
//            _attributedStringForNotANumber = newValue
//        }
//    }
    
    //
    
//    internal var _roundingBehavior: NSDecimalNumberHandler = .defaultDecimalNumberHandler()
//    /*@NSCopying*/ public var roundingBehavior: NSDecimalNumberHandler {
//        get {
//            return _roundingBehavior
//        }
//        set {
//            _reset()
//            _roundingBehavior = newValue
//        }
//    }
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
