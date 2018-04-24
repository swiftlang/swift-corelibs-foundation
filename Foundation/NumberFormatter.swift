// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(macOS) || os(iOS)
internal let kCFNumberFormatterNoStyle = CFNumberFormatterStyle.noStyle
internal let kCFNumberFormatterDecimalStyle = CFNumberFormatterStyle.decimalStyle
internal let kCFNumberFormatterCurrencyStyle = CFNumberFormatterStyle.currencyStyle
internal let kCFNumberFormatterPercentStyle = CFNumberFormatterStyle.percentStyle
internal let kCFNumberFormatterScientificStyle = CFNumberFormatterStyle.scientificStyle
internal let kCFNumberFormatterSpellOutStyle = CFNumberFormatterStyle.spellOutStyle
internal let kCFNumberFormatterOrdinalStyle = CFNumberFormatterStyle.ordinalStyle
internal let kCFNumberFormatterCurrencyISOCodeStyle = CFNumberFormatterStyle.currencyISOCodeStyle
internal let kCFNumberFormatterCurrencyPluralStyle = CFNumberFormatterStyle.currencyPluralStyle
internal let kCFNumberFormatterCurrencyAccountingStyle = CFNumberFormatterStyle.currencyAccountingStyle
#endif

extension NumberFormatter {
    public enum Style : UInt {
        case none               = 0
        case decimal            = 1
        case currency           = 2
        case percent            = 3
        case scientific         = 4
        case spellOut           = 5
        case ordinal            = 6
        case currencyISOCode    = 8     // 7 is not used
        case currencyPlural     = 9
        case currencyAccounting = 10
    }

    public enum PadPosition : UInt {
        case beforePrefix
        case afterPrefix
        case beforeSuffix
        case afterSuffix
    }

    public enum RoundingMode : UInt {
        case ceiling
        case floor
        case down
        case up
        case halfEven
        case halfDown
        case halfUp
    }
}

open class NumberFormatter : Formatter {
    
    typealias CFType = CFNumberFormatter
    private var _currentCfFormatter: CFType?
    private var _cfFormatter: CFType {
        if let obj = _currentCfFormatter {
            return obj
        } else {
            #if os(macOS) || os(iOS)
                let numberStyle = CFNumberFormatterStyle(rawValue: CFIndex(self.numberStyle.rawValue))!
            #else
                let numberStyle = CFNumberFormatterStyle(self.numberStyle.rawValue)
            #endif
            
            let obj = CFNumberFormatterCreate(kCFAllocatorSystemDefault, locale._cfObject, numberStyle)!
            _setFormatterAttributes(obj)
            if let format = _format {
                CFNumberFormatterSetFormat(obj, format._cfObject)
            }
            _currentCfFormatter = obj
            return obj
        }
    }
    
    // this is for NSUnitFormatter
    
    open var formattingContext: Context = .unknown // default is NSFormattingContextUnknown
    
    // Report the used range of the string and an NSError, in addition to the usual stuff from Formatter
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func objectValue(_ string: String, range: inout NSRange) throws -> Any? { NSUnimplemented() }
    
    open override func string(for obj: Any) -> String? {
        //we need to allow Swift's numeric types here - Int, Double et al.
        guard let number = _SwiftValue.store(obj) as? NSNumber else { return nil }
        return string(from: number)
    }
    
    // Even though NumberFormatter responds to the usual Formatter methods,
    //   here are some convenience methods which are a little more obvious.
    open func string(from number: NSNumber) -> String? {
        return CFNumberFormatterCreateStringWithNumber(kCFAllocatorSystemDefault, _cfFormatter, number._cfObject)._swiftObject
    }
    
    open func number(from string: String) -> NSNumber? {
        var range = CFRange(location: 0, length: string.length)
        let number = withUnsafeMutablePointer(to: &range) { (rangePointer: UnsafeMutablePointer<CFRange>) -> NSNumber? in

            #if os(macOS) || os(iOS)
                let parseOption = allowsFloats ? 0 : CFNumberFormatterOptionFlags.parseIntegersOnly.rawValue
            #else
                let parseOption = allowsFloats ? 0 : CFOptionFlags(kCFNumberFormatterParseIntegersOnly)
            #endif
            let result = CFNumberFormatterCreateNumberFromString(kCFAllocatorSystemDefault, _cfFormatter, string._cfObject, rangePointer, parseOption)

            return result?._nsObject
        }
        return number
    }
    
    open class func localizedString(from num: NSNumber, number nstyle: Style) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = nstyle
        return numberFormatter.string(for: num)!
    }
    
    internal func _reset() {
        _currentCfFormatter = nil
    }
    
    internal func _setFormatterAttributes(_ formatter: CFNumberFormatter) {
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
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinIntegerDigits, value: minimumIntegerDigits._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxIntegerDigits, value: _maximumIntegerDigits._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinFractionDigits, value: _minimumFractionDigits._bridgeToObjectiveC()._cfObject)
        if _minimumFractionDigits <= 0 {
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxFractionDigits, value: _maximumFractionDigits._bridgeToObjectiveC()._cfObject)
        }
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterGroupingSize, value: _groupingSize._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterSecondaryGroupingSize, value: _secondaryGroupingSize._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingMode, value: _roundingMode.rawValue._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingIncrement, value: _roundingIncrement?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterFormatWidth, value: _formatWidth._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingCharacter, value: _paddingCharacter?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingPosition, value: _paddingPosition.rawValue._bridgeToObjectiveC()._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMultiplier, value: _multiplier?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositivePrefix, value: _positivePrefix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositiveSuffix, value: _positiveSuffix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativePrefix, value: _negativePrefix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativeSuffix, value: _negativeSuffix?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPerMillSymbol, value: _percentSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterInternationalCurrencySymbol, value: _internationalCurrencySymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyGroupingSeparator, value: _currencyGroupingSeparator?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterIsLenient, value: _lenient._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterUseSignificantDigits, value: _usesSignificantDigits._cfObject)
        if _usesSignificantDigits {
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinSignificantDigits, value: _minimumSignificantDigits._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxSignificantDigits, value: _maximumSignificantDigits._bridgeToObjectiveC()._cfObject)
        }
    }
    
    internal func _setFormatterAttribute(_ formatter: CFNumberFormatter, attributeName: CFString, value: AnyObject?) {
        if let value = value {
            CFNumberFormatterSetProperty(formatter, attributeName, value)
        }
    }
    
    // Attributes of a NumberFormatter
    internal var _numberStyle: Style = .none
    open var numberStyle: Style {
        get {
            return _numberStyle
        }
        
        set {
            switch newValue {
            case .none, .ordinal, .spellOut:
                _usesSignificantDigits = false

            case .currency, .currencyISOCode, .currencyAccounting:
                _usesSignificantDigits = false
                _usesGroupingSeparator = true
                if _minimumIntegerDigits == nil {
                    _minimumIntegerDigits = 1
                }
                if _groupingSize == 0 {
                    _groupingSize = 3
                }
                _minimumFractionDigits = 2

            case .currencyPlural:
                _usesSignificantDigits = false
                _usesGroupingSeparator = true
                if _minimumIntegerDigits == nil {
                    _minimumIntegerDigits = 0
                }
                _minimumFractionDigits = 2

            case .decimal:
                _usesGroupingSeparator = true
                _maximumFractionDigits = 3
                if _minimumIntegerDigits == nil {
                    _minimumIntegerDigits = 1
                }
                if _groupingSize == 0 {
                    _groupingSize = 3
                }
                
            case .percent:
                _usesSignificantDigits = false
                _usesGroupingSeparator = true
                if _minimumIntegerDigits == nil {
                    _minimumIntegerDigits = 1
                }
                if _groupingSize == 0 {
                    _groupingSize = 3
                }
                _minimumFractionDigits = 0
                _maximumFractionDigits = 0

            case .scientific:
                _usesSignificantDigits = false
                _usesGroupingSeparator = false
                if _minimumIntegerDigits == nil {
                    _minimumIntegerDigits = 0
                }
            }
            _reset()
            _numberStyle = newValue
        }
    }
    
    internal var _locale: Locale = Locale.current
    /*@NSCopying*/ open var locale: Locale! {
        get {
            return _locale
        }
        set {
            _reset()
            _locale = newValue
        }
    }
    
    internal var _generatesDecimalNumbers: Bool = false
    open var generatesDecimalNumbers: Bool {
        get {
            return _generatesDecimalNumbers
        }
        set {
            _reset()
            _generatesDecimalNumbers = newValue
        }
    }
    
    internal var _negativeFormat: String!
    open var negativeFormat: String! {
        get {
            return _negativeFormat
        }
        set {
            _reset()
            _negativeFormat = newValue
        }
    }
    
    internal var _textAttributesForNegativeValues: [String : Any]?
    open var textAttributesForNegativeValues: [String : Any]? {
        get {
            return _textAttributesForNegativeValues
        }
        set {
            _reset()
            _textAttributesForNegativeValues = newValue
        }
    }
    
    internal var _positiveFormat: String!
    open var positiveFormat: String! {
        get {
            return _positiveFormat
        }
        set {
            _reset()
            _positiveFormat = newValue
        }
    }
    
    internal var _textAttributesForPositiveValues: [String : Any]?
    open var textAttributesForPositiveValues: [String : Any]? {
        get {
            return _textAttributesForPositiveValues
        }
        set {
            _reset()
            _textAttributesForPositiveValues = newValue
        }
    }
    
    internal var _allowsFloats: Bool = true
    open var allowsFloats: Bool {
        get {
            return _allowsFloats
        }
        set {
            _reset()
            _allowsFloats = newValue
        }
    }

    internal var _decimalSeparator: String!
    open var decimalSeparator: String! {
        get {
            return _decimalSeparator
        }
        set {
            _reset()
            _decimalSeparator = newValue
        }
    }
    
    internal var _alwaysShowsDecimalSeparator: Bool = false
    open var alwaysShowsDecimalSeparator: Bool {
        get {
            return _alwaysShowsDecimalSeparator
        }
        set {
            _reset()
            _alwaysShowsDecimalSeparator = newValue
        }
    }
    
    internal var _currencyDecimalSeparator: String!
    open var currencyDecimalSeparator: String! {
        get {
            return _currencyDecimalSeparator
        }
        set {
            _reset()
            _currencyDecimalSeparator = newValue
        }
    }
    
    internal var _usesGroupingSeparator: Bool = false
    open var usesGroupingSeparator: Bool {
        get {
            return _usesGroupingSeparator
        }
        set {
            _reset()
            _usesGroupingSeparator = newValue
        }
    }
    
    internal var _groupingSeparator: String!
    open var groupingSeparator: String! {
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
    open var zeroSymbol: String? {
        get {
            return _zeroSymbol
        }
        set {
            _reset()
            _zeroSymbol = newValue
        }
    }
    
    internal var _textAttributesForZero: [String : Any]?
    open var textAttributesForZero: [String : Any]? {
        get {
            return _textAttributesForZero
        }
        set {
            _reset()
            _textAttributesForZero = newValue
        }
    }
    
    internal var _nilSymbol: String = ""
    open var nilSymbol: String {
        get {
            return _nilSymbol
        }
        set {
            _reset()
            _nilSymbol = newValue
        }
    }
    
    internal var _textAttributesForNil: [String : Any]?
    open var textAttributesForNil: [String : Any]? {
        get {
            return _textAttributesForNil
        }
        set {
            _reset()
            _textAttributesForNil = newValue
        }
    }
    
    internal var _notANumberSymbol: String!
    open var notANumberSymbol: String! {
        get {
            return _notANumberSymbol
        }
        set {
            _reset()
            _notANumberSymbol = newValue
        }
    }
    
    internal var _textAttributesForNotANumber: [String : Any]?
    open var textAttributesForNotANumber: [String : Any]? {
        get {
            return _textAttributesForNotANumber
        }
        set {
            _reset()
            _textAttributesForNotANumber = newValue
        }
    }
    
    internal var _positiveInfinitySymbol: String = "+∞"
    open var positiveInfinitySymbol: String {
        get {
            return _positiveInfinitySymbol
        }
        set {
            _reset()
            _positiveInfinitySymbol = newValue
        }
    }
    
    internal var _textAttributesForPositiveInfinity: [String : Any]?
    open var textAttributesForPositiveInfinity: [String : Any]? {
        get {
            return _textAttributesForPositiveInfinity
        }
        set {
            _reset()
            _textAttributesForPositiveInfinity = newValue
        }
    }
    
    internal var _negativeInfinitySymbol: String = "-∞"
    open var negativeInfinitySymbol: String {
        get {
            return _negativeInfinitySymbol
        }
        set {
            _reset()
            _negativeInfinitySymbol = newValue
        }
    }
    
    internal var _textAttributesForNegativeInfinity: [String : Any]?
    open var textAttributesForNegativeInfinity: [String : Any]? {
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
    open var positivePrefix: String! {
        get {
            return _positivePrefix
        }
        set {
            _reset()
            _positivePrefix = newValue
        }
    }
    
    internal var _positiveSuffix: String!
    open var positiveSuffix: String! {
        get {
            return _positiveSuffix
        }
        set {
            _reset()
            _positiveSuffix = newValue
        }
    }
    
    internal var _negativePrefix: String!
    open var negativePrefix: String! {
        get {
            return _negativePrefix
        }
        set {
            _reset()
            _negativePrefix = newValue
        }
    }
    
    internal var _negativeSuffix: String!
    open var negativeSuffix: String! {
        get {
            return _negativeSuffix
        }
        set {
            _reset()
            _negativeSuffix = newValue
        }
    }
    
    internal var _currencyCode: String!
    open var currencyCode: String! {
        get {
            return _currencyCode
        }
        set {
            _reset()
            _currencyCode = newValue
        }
    }
    
    internal var _currencySymbol: String!
    open var currencySymbol: String! {
        get {
            return _currencySymbol
        }
        set {
            _reset()
            _currencySymbol = newValue
        }
    }
    
    internal var _internationalCurrencySymbol: String!
    open var internationalCurrencySymbol: String! {
        get {
            return _internationalCurrencySymbol
        }
        set {
            _reset()
            _internationalCurrencySymbol = newValue
        }
    }
    
    internal var _percentSymbol: String!
    open var percentSymbol: String! {
        get {
            return _percentSymbol
        }
        set {
            _reset()
            _percentSymbol = newValue
        }
    }
    
    internal var _perMillSymbol: String!
    open var perMillSymbol: String! {
        get {
            return _perMillSymbol
        }
        set {
            _reset()
            _perMillSymbol = newValue
        }
    }
    
    internal var _minusSign: String!
    open var minusSign: String! {
        get {
            return _minusSign
        }
        set {
            _reset()
            _minusSign = newValue
        }
    }
    
    internal var _plusSign: String!
    open var plusSign: String! {
        get {
            return _plusSign
        }
        set {
            _reset()
            _plusSign = newValue
        }
    }
    
    internal var _exponentSymbol: String!
    open var exponentSymbol: String! {
        get {
            return _exponentSymbol
        }
        set {
            _reset()
            _exponentSymbol = newValue
        }
    }
    
    //
    
    internal var _groupingSize: Int = 0
    open var groupingSize: Int {
        get {
            return _groupingSize
        }
        set {
            _reset()
            _groupingSize = newValue
        }
    }
    
    internal var _secondaryGroupingSize: Int = 0
    open var secondaryGroupingSize: Int {
        get {
            return _secondaryGroupingSize
        }
        set {
            _reset()
            _secondaryGroupingSize = newValue
        }
    }
    
    internal var _multiplier: NSNumber?
    /*@NSCopying*/ open var multiplier: NSNumber? {
        get {
            return _multiplier
        }
        set {
            _reset()
            _multiplier = newValue
        }
    }
    
    internal var _formatWidth: Int = 0
    open var formatWidth: Int {
        get {
            return _formatWidth
        }
        set {
            _reset()
            _formatWidth = newValue
        }
    }
    
    internal var _paddingCharacter: String!
    open var paddingCharacter: String! {
        get {
            return _paddingCharacter
        }
        set {
            _reset()
            _paddingCharacter = newValue
        }
    }
    
    //
    
    internal var _paddingPosition: PadPosition = .beforePrefix
    open var paddingPosition: PadPosition {
        get {
            return _paddingPosition
        }
        set {
            _reset()
            _paddingPosition = newValue
        }
    }
    
    internal var _roundingMode: RoundingMode = .halfEven
    open var roundingMode: RoundingMode {
        get {
            return _roundingMode
        }
        set {
            _reset()
            _roundingMode = newValue
        }
    }
    
    internal var _roundingIncrement: NSNumber! = 0
    /*@NSCopying*/ open var roundingIncrement: NSNumber! {
        get {
            return _roundingIncrement
        }
        set {
            _reset()
            _roundingIncrement = newValue
        }
    }

    // Use an optional for _minimumIntegerDigits to track if the value is
    // set BEFORE the .numberStyle is changed. This allows preserving a setting
    // of 0.
    internal var _minimumIntegerDigits: Int?
    open var minimumIntegerDigits: Int {
        get {
            return _minimumIntegerDigits ?? 0
        }
        set {
            _reset()
            _minimumIntegerDigits = newValue
        }
    }
    
    internal var _maximumIntegerDigits: Int = 42
    open var maximumIntegerDigits: Int {
        get {
            return _maximumIntegerDigits
        }
        set {
            _reset()
            _maximumIntegerDigits = newValue
        }
    }
    
    internal var _minimumFractionDigits: Int = 0
    open var minimumFractionDigits: Int {
        get {
            return _minimumFractionDigits
        }
        set {
            _reset()
            _minimumFractionDigits = newValue
        }
    }
    
    internal var _maximumFractionDigits: Int = 0
    open var maximumFractionDigits: Int {
        get {
            return _maximumFractionDigits
        }
        set {
            _reset()
            _maximumFractionDigits = newValue
        }
    }
    
    internal var _minimum: NSNumber?
    /*@NSCopying*/ open var minimum: NSNumber? {
        get {
            return _minimum
        }
        set {
            _reset()
            _minimum = newValue
        }
    }
    
    internal var _maximum: NSNumber?
    /*@NSCopying*/ open var maximum: NSNumber? {
        get {
            return _maximum
        }
        set {
            _reset()
            _maximum = newValue
        }
    }
    
    internal var _currencyGroupingSeparator: String!
    open var currencyGroupingSeparator: String! {
        get {
            return _currencyGroupingSeparator
        }
        set {
            _reset()
            _currencyGroupingSeparator = newValue
        }
    }
    
    internal var _lenient: Bool = false
    open var isLenient: Bool {
        get {
            return _lenient
        }
        set {
            _reset()
            _lenient = newValue
        }
    }
    
    internal var _usesSignificantDigits: Bool = false
    open var usesSignificantDigits: Bool {
        get {
            return _usesSignificantDigits
        }
        set {
            _reset()
            _usesSignificantDigits = newValue
        }
    }
    
    internal var _minimumSignificantDigits: Int = 1
    open var minimumSignificantDigits: Int {
        get {
            return _minimumSignificantDigits
        }
        set {
            _reset()
            _usesSignificantDigits = true
            _minimumSignificantDigits = newValue
        }
    }
    
    internal var _maximumSignificantDigits: Int = 6
    open var maximumSignificantDigits: Int {
        get {
            return _maximumSignificantDigits
        }
        set {
            _reset()
            _usesSignificantDigits = true
            _maximumSignificantDigits = newValue
        }
    }
    
    internal var _partialStringValidationEnabled: Bool = false
    open var isPartialStringValidationEnabled: Bool {
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
    open var hasThousandSeparators: Bool {
        get {
            return _hasThousandSeparators
        }
        set {
            _reset()
            _hasThousandSeparators = newValue
        }
    }
    
    internal var _thousandSeparator: String!
    open var thousandSeparator: String! {
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
    open var localizesFormat: Bool {
        get {
            return _localizesFormat
        }
        set {
            _reset()
            _localizesFormat = newValue
        }
    }
    
    //
    
    internal var _format: String?
    open var format: String {
        get {
            return _format ?? "#;0;#"
        }
        set {
            _reset()
            _format = newValue
        }
    }
    
    //
    
    internal var _attributedStringForZero: NSAttributedString = NSAttributedString(string: "0")
    /*@NSCopying*/ open var attributedStringForZero: NSAttributedString {
        get {
            return _attributedStringForZero
        }
        set {
            _reset()
            _attributedStringForZero = newValue
        }
    }
    
    internal var _attributedStringForNil: NSAttributedString = NSAttributedString(string: "")
    /*@NSCopying*/ open var attributedStringForNil: NSAttributedString {
        get {
            return _attributedStringForNil
        }
        set {
            _reset()
            _attributedStringForNil = newValue
        }
    }
    
    internal var _attributedStringForNotANumber: NSAttributedString = NSAttributedString(string: "NaN")
    /*@NSCopying*/ open var attributedStringForNotANumber: NSAttributedString {
        get {
            return _attributedStringForNotANumber
        }
        set {
            _reset()
            _attributedStringForNotANumber = newValue
        }
    }
    
    internal var _roundingBehavior: NSDecimalNumberHandler = NSDecimalNumberHandler.default
    /*@NSCopying*/ open var roundingBehavior: NSDecimalNumberHandler {
        get {
            return _roundingBehavior
        }
        set {
            _reset()
            _roundingBehavior = newValue
        }
    }
}
