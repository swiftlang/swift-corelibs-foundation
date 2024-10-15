// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal import CoreFoundation
internal import Synchronization

extension NumberFormatter {
    public enum Style : UInt, Sendable {
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

    public enum PadPosition : UInt, Sendable {
        case beforePrefix
        case afterPrefix
        case beforeSuffix
        case afterSuffix
    }

    public enum RoundingMode : UInt, Sendable {
        case ceiling
        case floor
        case down
        case up
        case halfEven
        case halfDown
        case halfUp
    }
}

open class NumberFormatter : Formatter, @unchecked Sendable {
    private let _lock: Mutex<State> = .init(.init())
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private convenience init(state: State) {
        self.init()
        _lock.withLock {
            $0 = state
        }
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return _lock.withLock { state in
            // Zone is not Sendable, so just ignore it here
            let copy = state.copy()
            return NumberFormatter(state: copy)
        }
    }
    
    open class func localizedString(from num: NSNumber, number nstyle: Style) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = nstyle
        return numberFormatter.string(for: num)!
    }

    // This class is not Sendable, but marking it as such was the only way to work around compiler crashes while attempting to use `~Copyable` like `DateFormatter` does.
    final class State : @unchecked Sendable {
        class Box {
            var formatter: CFNumberFormatter?
            init() {}
        }
        
        private var _formatter = Box()
        
        // MARK: -
        
        func copy(with zone: NSZone? = nil) -> State {
            let copied = State()
                        
            copied.formattingContext = formattingContext
            copied._numberStyle = _numberStyle
            copied._locale = _locale
            copied._generatesDecimalNumbers = _generatesDecimalNumbers
            copied._textAttributesForNegativeValues = _textAttributesForNegativeValues
            copied._textAttributesForPositiveValues = _textAttributesForPositiveValues
            copied._allowsFloats = _allowsFloats
            copied._decimalSeparator = _decimalSeparator
            copied._alwaysShowsDecimalSeparator = _alwaysShowsDecimalSeparator
            copied._currencyDecimalSeparator = _currencyDecimalSeparator
            copied._usesGroupingSeparator = _usesGroupingSeparator
            copied._groupingSeparator = _groupingSeparator
            copied._zeroSymbol = _zeroSymbol
            copied._textAttributesForZero = _textAttributesForZero
            copied._nilSymbol = _nilSymbol
            copied._textAttributesForNil = _textAttributesForNil
            copied._notANumberSymbol = _notANumberSymbol
            copied._textAttributesForNotANumber = _textAttributesForNotANumber
            copied._positiveInfinitySymbol = _positiveInfinitySymbol
            copied._textAttributesForPositiveInfinity = _textAttributesForPositiveInfinity
            copied._negativeInfinitySymbol = _negativeInfinitySymbol
            copied._textAttributesForNegativeInfinity = _textAttributesForNegativeInfinity
            copied._positivePrefix = _positivePrefix
            copied._positiveSuffix = _positiveSuffix
            copied._negativePrefix = _negativePrefix
            copied._negativeSuffix = _negativeSuffix
            copied._currencyCode = _currencyCode
            copied._currencySymbol = _currencySymbol
            copied._internationalCurrencySymbol = _internationalCurrencySymbol
            copied._percentSymbol = _percentSymbol
            copied._perMillSymbol = _perMillSymbol
            copied._minusSign = _minusSign
            copied._plusSign = _plusSign
            copied._exponentSymbol = _exponentSymbol
            copied._groupingSize = _groupingSize
            copied._secondaryGroupingSize = _secondaryGroupingSize
            copied._multiplier = _multiplier
            copied._formatWidth = _formatWidth
            copied._paddingCharacter = _paddingCharacter
            copied._paddingPosition = _paddingPosition
            copied._roundingMode = _roundingMode
            copied._roundingIncrement = _roundingIncrement
            copied._minimumIntegerDigits = _minimumIntegerDigits
            copied._maximumIntegerDigits = _maximumIntegerDigits
            copied._minimumFractionDigits = _minimumFractionDigits
            copied._maximumFractionDigits = _maximumFractionDigits
            copied._minimum = _minimum
            copied._maximum = _maximum
            copied._currencyGroupingSeparator = _currencyGroupingSeparator
            copied._lenient = _lenient
            copied._usesSignificantDigits = _usesSignificantDigits
            copied._minimumSignificantDigits = _minimumSignificantDigits
            copied._maximumSignificantDigits = _maximumSignificantDigits
            copied._partialStringValidationEnabled = _partialStringValidationEnabled
            copied._hasThousandSeparators = _hasThousandSeparators
            copied._thousandSeparator = _thousandSeparator
            copied._localizesFormat = _localizesFormat
            copied._positiveFormat = _positiveFormat
            copied._negativeFormat = _negativeFormat
            copied._roundingBehavior = _roundingBehavior
            
            return copied
        }

        // MARK: -
        
        func _reset() {
            _formatter.formatter = nil
        }
        
        func formatter() -> CFNumberFormatter {
            if let obj = _formatter.formatter {
                return obj
            } else {
                let numberStyle = CFNumberFormatterStyle(rawValue: CFIndex(_numberStyle.rawValue))!
                
                let obj = CFNumberFormatterCreate(kCFAllocatorSystemDefault, locale._cfObject, numberStyle)!
                _setFormatterAttributes(obj)
                if _positiveFormat != nil  || _negativeFormat != nil {
                    var format = _positiveFormat ?? "#"
                    if let negative = _negativeFormat {
                        format.append(";")
                        format.append(negative)
                    }
                    CFNumberFormatterSetFormat(obj, format._cfObject)
                }
                _formatter.formatter = obj
                return obj
            }
        }
        
        private func _setFormatterAttributes(_ formatter: CFNumberFormatter) {
            if numberStyle == .currency {
                // Prefer currencySymbol, then currencyCode then locale.currencySymbol
                if let symbol = _currencySymbol {
                    _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencySymbol, value: symbol._cfObject)
                } else if let code = _currencyCode, code.count == 3 {
                    _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyCode, value: code._cfObject)
                } else {
                    _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencySymbol, value: locale.currencySymbol?._cfObject)
                }
            }
            if numberStyle == .currencyISOCode {
                let code = _currencyCode ?? _currencySymbol ?? locale.currencyCode ?? locale.currencySymbol
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyCode, value: code?._cfObject)
            }
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterDecimalSeparator, value: _decimalSeparator?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyDecimalSeparator, value: _currencyDecimalSeparator?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterAlwaysShowDecimalSeparator, value: _alwaysShowsDecimalSeparator._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterGroupingSeparator, value: _groupingSeparator?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterUseGroupingSeparator, value: usesGroupingSeparator._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPercentSymbol, value: _percentSymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterZeroSymbol, value: _zeroSymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNaNSymbol, value: _notANumberSymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterInfinitySymbol, value: _positiveInfinitySymbol._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinusSign, value: _minusSign?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPlusSign, value: _plusSign?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterExponentSymbol, value: _exponentSymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinIntegerDigits, value: _minimumIntegerDigits?._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxIntegerDigits, value: _maximumIntegerDigits?._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinFractionDigits, value: _minimumFractionDigits?._bridgeToObjectiveC()._cfObject)
            if minimumFractionDigits <= 0 {
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxFractionDigits, value: maximumFractionDigits._bridgeToObjectiveC()._cfObject)
            }
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterGroupingSize, value: groupingSize._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterSecondaryGroupingSize, value: _secondaryGroupingSize._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingMode, value: _roundingMode.rawValue._bridgeToObjectiveC()._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterRoundingIncrement, value: _roundingIncrement?._cfObject)
            
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterFormatWidth, value: _formatWidth?._bridgeToObjectiveC()._cfObject)
            if self.formatWidth > 0 {
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingCharacter, value: _paddingCharacter?._cfObject)
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingPosition, value: _paddingPosition.rawValue._bridgeToObjectiveC()._cfObject)
            } else {
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPaddingCharacter, value: ""._cfObject)
            }
            
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMultiplier, value: multiplier?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositivePrefix, value: _positivePrefix?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPositiveSuffix, value: _positiveSuffix?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativePrefix, value: _negativePrefix?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterNegativeSuffix, value: _negativeSuffix?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterPerMillSymbol, value: _percentSymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterInternationalCurrencySymbol, value: _internationalCurrencySymbol?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterCurrencyGroupingSeparator, value: _currencyGroupingSeparator?._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterIsLenient, value: _lenient._cfObject)
            _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterUseSignificantDigits, value: usesSignificantDigits._cfObject)
            if usesSignificantDigits {
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMinSignificantDigits, value: minimumSignificantDigits._bridgeToObjectiveC()._cfObject)
                _setFormatterAttribute(formatter, attributeName: kCFNumberFormatterMaxSignificantDigits, value: maximumSignificantDigits._bridgeToObjectiveC()._cfObject)
            }
        }
        
        private func _setFormatterAttribute(_ formatter: CFNumberFormatter, attributeName: CFString, value: AnyObject?) {
            if let value = value {
                CFNumberFormatterSetProperty(formatter, attributeName, value)
            }
        }
        
        private func _getFormatterAttribute(attributeName: CFString) -> String? {
            // This will only be a constant CFString
            nonisolated(unsafe) let nonisolatedAttributeName = attributeName
            return CFNumberFormatterCopyProperty(formatter(), nonisolatedAttributeName) as? String
        }

        private func getFormatterComponents() -> (String?, String?) {
            guard let format = CFNumberFormatterGetFormat(formatter())?._swiftObject else {
                return (nil, nil)
            }
            let components = format.components(separatedBy: ";")
            let positive = _positiveFormat ?? components.first ?? "#"
            let negative = _negativeFormat ?? components.last ?? "#"
            return (positive, negative)
        }

        // MARK: - Properties
        
        private var _numberStyle: Style = .none
        var numberStyle: Style {
            get {
                return _numberStyle
            }
            
            set {
                _reset()
                _numberStyle = newValue
            }
        }
        
        private var _locale: Locale = Locale.current
        var locale: Locale! {
            get {
                return _locale
            }
            set {
                _reset()
                _locale = newValue
            }
        }
        
        private var _generatesDecimalNumbers: Bool = false
        var generatesDecimalNumbers: Bool {
            get {
                return _generatesDecimalNumbers
            }
            set {
                _reset()
                _generatesDecimalNumbers = newValue
            }
        }
        
        private var _textAttributesForNegativeValues: [String : (Any & Sendable)]?
        var textAttributesForNegativeValues: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForNegativeValues
            }
            set {
                _reset()
                _textAttributesForNegativeValues = newValue
            }
        }
        
        private var _textAttributesForPositiveValues: [String : (Any & Sendable)]?
        var textAttributesForPositiveValues: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForPositiveValues
            }
            set {
                _reset()
                _textAttributesForPositiveValues = newValue
            }
        }
        
        private var _allowsFloats: Bool = true
        var allowsFloats: Bool {
            get {
                return _allowsFloats
            }
            set {
                _reset()
                _allowsFloats = newValue
            }
        }
        
        private var _decimalSeparator: String!
        var decimalSeparator: String! {
            get {
                return _decimalSeparator ?? _getFormatterAttribute(attributeName: kCFNumberFormatterDecimalSeparator)
            }
            set {
                _reset()
                _decimalSeparator = newValue
            }
        }
        
        private var _alwaysShowsDecimalSeparator: Bool = false
        var alwaysShowsDecimalSeparator: Bool {
            get {
                return _alwaysShowsDecimalSeparator
            }
            set {
                _reset()
                _alwaysShowsDecimalSeparator = newValue
            }
        }
        
        private var _currencyDecimalSeparator: String!
        var currencyDecimalSeparator: String! {
            get {
                return _currencyDecimalSeparator ?? _getFormatterAttribute(attributeName: kCFNumberFormatterCurrencyDecimalSeparator)
            }
            set {
                _reset()
                _currencyDecimalSeparator = newValue
            }
        }
        
        private var _usesGroupingSeparator: Bool?
        var usesGroupingSeparator: Bool {
            get {
                return _usesGroupingSeparator ?? defaultUsesGroupingSeparator()
            }
            set {
                _reset()
                _usesGroupingSeparator = newValue
            }
        }
        
        private var _groupingSeparator: String!
        var groupingSeparator: String! {
            get {
                return _groupingSeparator ?? _getFormatterAttribute(attributeName: kCFNumberFormatterGroupingSeparator)
            }
            set {
                _reset()
                _groupingSeparator = newValue
            }
        }
        
        private var _zeroSymbol: String?
        var zeroSymbol: String? {
            get {
                return _zeroSymbol
            }
            set {
                _reset()
                _zeroSymbol = newValue
            }
        }
        
        private var _textAttributesForZero: [String : (Any & Sendable)]?
        var textAttributesForZero: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForZero
            }
            set {
                _reset()
                _textAttributesForZero = newValue
            }
        }
        
        private var _nilSymbol: String = ""
        var nilSymbol: String {
            get {
                return _nilSymbol
            }
            set {
                _reset()
                _nilSymbol = newValue
            }
        }
        
        private var _textAttributesForNil: [String : (Any & Sendable)]?
        var textAttributesForNil: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForNil
            }
            set {
                _reset()
                _textAttributesForNil = newValue
            }
        }
        
        private var _notANumberSymbol: String!
        var notANumberSymbol: String! {
            get {
                return _notANumberSymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterNaNSymbol)
            }
            set {
                _reset()
                _notANumberSymbol = newValue
            }
        }
        
        private var _textAttributesForNotANumber: [String : (Any & Sendable)]?
        var textAttributesForNotANumber: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForNotANumber
            }
            set {
                _reset()
                _textAttributesForNotANumber = newValue
            }
        }
        
        private var _positiveInfinitySymbol: String = "+∞"
        var positiveInfinitySymbol: String {
            get {
                return _positiveInfinitySymbol
            }
            set {
                _reset()
                _positiveInfinitySymbol = newValue
            }
        }
        
        private var _textAttributesForPositiveInfinity: [String : (Any & Sendable)]?
        var textAttributesForPositiveInfinity: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForPositiveInfinity
            }
            set {
                _reset()
                _textAttributesForPositiveInfinity = newValue
            }
        }
        
        private var _negativeInfinitySymbol: String = "-∞"
        var negativeInfinitySymbol: String {
            get {
                return _negativeInfinitySymbol
            }
            set {
                _reset()
                _negativeInfinitySymbol = newValue
            }
        }
        
        private var _textAttributesForNegativeInfinity: [String : (Any & Sendable)]?
        var textAttributesForNegativeInfinity: [String : (Any & Sendable)]? {
            get {
                return _textAttributesForNegativeInfinity
            }
            set {
                _reset()
                _textAttributesForNegativeInfinity = newValue
            }
        }
        
        private var _positivePrefix: String!
        var positivePrefix: String! {
            get {
                return _positivePrefix ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPositivePrefix)
            }
            set {
                _reset()
                _positivePrefix = newValue
            }
        }
        
        private var _positiveSuffix: String!
        var positiveSuffix: String! {
            get {
                return _positiveSuffix ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPositiveSuffix)
            }
            set {
                _reset()
                _positiveSuffix = newValue
            }
        }
        
        private var _negativePrefix: String!
        var negativePrefix: String! {
            get {
                return _negativePrefix ?? _getFormatterAttribute(attributeName: kCFNumberFormatterNegativePrefix)
            }
            set {
                _reset()
                _negativePrefix = newValue
            }
        }
        
        private var _negativeSuffix: String!
        var negativeSuffix: String! {
            get {
                return _negativeSuffix ?? _getFormatterAttribute(attributeName: kCFNumberFormatterNegativeSuffix)
            }
            set {
                _reset()
                _negativeSuffix = newValue
            }
        }
        
        private var _currencyCode: String!
        var currencyCode: String! {
            get {
                return _currencyCode ?? _getFormatterAttribute(attributeName: kCFNumberFormatterCurrencyCode)
            }
            set {
                _reset()
                _currencyCode = newValue
            }
        }
        
        private var _currencySymbol: String!
        var currencySymbol: String! {
            get {
                return _currencySymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterCurrencySymbol)
            }
            set {
                _reset()
                _currencySymbol = newValue
            }
        }
        
        private var _internationalCurrencySymbol: String!
        var internationalCurrencySymbol: String! {
            get {
                return _internationalCurrencySymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterInternationalCurrencySymbol)
            }
            set {
                _reset()
                _internationalCurrencySymbol = newValue
            }
        }
        
        private var _percentSymbol: String!
        var percentSymbol: String! {
            get {
                return _percentSymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPercentSymbol) ?? "%"
            }
            set {
                _reset()
                _percentSymbol = newValue
            }
        }
        
        private var _perMillSymbol: String!
        var perMillSymbol: String! {
            get {
                return _perMillSymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPerMillSymbol)
            }
            set {
                _reset()
                _perMillSymbol = newValue
            }
        }
        
        private var _minusSign: String!
        var minusSign: String! {
            get {
                return _minusSign ?? _getFormatterAttribute(attributeName: kCFNumberFormatterMinusSign)
            }
            set {
                _reset()
                _minusSign = newValue
            }
        }
        
        private var _plusSign: String!
        var plusSign: String! {
            get {
                return _plusSign ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPlusSign)
            }
            set {
                _reset()
                _plusSign = newValue
            }
        }
        
        private var _exponentSymbol: String!
        var exponentSymbol: String! {
            get {
                return _exponentSymbol ?? _getFormatterAttribute(attributeName: kCFNumberFormatterExponentSymbol)
            }
            set {
                _reset()
                _exponentSymbol = newValue
            }
        }
        
        private var _groupingSize: Int?
        var groupingSize: Int {
            get {
                return _groupingSize ?? defaultGroupingSize()
            }
            set {
                _reset()
                _groupingSize = newValue
            }
        }
        
        private var _secondaryGroupingSize: Int = 0
        var secondaryGroupingSize: Int {
            get {
                return _secondaryGroupingSize
            }
            set {
                _reset()
                _secondaryGroupingSize = newValue
            }
        }
        
        private var _multiplier: NSNumber?
        var multiplier: NSNumber? {
            get {
                return _multiplier ?? defaultMultiplier()
            }
            set {
                _reset()
                _multiplier = newValue
            }
        }
        
        private var _formatWidth: Int?
        var formatWidth: Int {
            get {
                return _formatWidth ?? defaultFormatWidth()
            }
            set {
                _reset()
                _formatWidth = newValue
            }
        }
        
        private var _paddingCharacter: String! = " "
        var paddingCharacter: String! {
            get {
                return _paddingCharacter ?? _getFormatterAttribute(attributeName: kCFNumberFormatterPaddingCharacter)
            }
            set {
                _reset()
                _paddingCharacter = newValue
            }
        }
        
        private var _paddingPosition: PadPosition = .beforePrefix
        var paddingPosition: PadPosition {
            get {
                return _paddingPosition
            }
            set {
                _reset()
                _paddingPosition = newValue
            }
        }
        
        private var _roundingMode: RoundingMode = .halfEven
        var roundingMode: RoundingMode {
            get {
                return _roundingMode
            }
            set {
                _reset()
                _roundingMode = newValue
            }
        }
        
        private var _roundingIncrement: NSNumber! = 0
        var roundingIncrement: NSNumber! {
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
        private var _minimumIntegerDigits: Int?
        var minimumIntegerDigits: Int {
            get {
                return _minimumIntegerDigits ?? defaultMinimumIntegerDigits()
            }
            set {
                _reset()
                _minimumIntegerDigits = newValue
            }
        }
        
        private var _maximumIntegerDigits: Int?
        var maximumIntegerDigits: Int {
            get {
                return _maximumIntegerDigits ?? defaultMaximumIntegerDigits()
            }
            set {
                _reset()
                _maximumIntegerDigits = newValue
            }
        }
        
        private var _minimumFractionDigits: Int?
        var minimumFractionDigits: Int {
            get {
                return _minimumFractionDigits ?? defaultMinimumFractionDigits()
            }
            set {
                _reset()
                _minimumFractionDigits = newValue
            }
        }
        
        private var _maximumFractionDigits: Int?
        var maximumFractionDigits: Int {
            get {
                return _maximumFractionDigits ?? defaultMaximumFractionDigits()
            }
            set {
                _reset()
                _maximumFractionDigits = newValue
            }
        }
        
        private var _minimum: NSNumber?
        var minimum: NSNumber? {
            get {
                return _minimum
            }
            set {
                _reset()
                _minimum = newValue
            }
        }
        
        private var _maximum: NSNumber?
        var maximum: NSNumber? {
            get {
                return _maximum
            }
            set {
                _reset()
                _maximum = newValue
            }
        }
        
        private var _currencyGroupingSeparator: String!
        var currencyGroupingSeparator: String! {
            get {
                return _currencyGroupingSeparator ?? _getFormatterAttribute(attributeName: kCFNumberFormatterCurrencyGroupingSeparator)
            }
            set {
                _reset()
                _currencyGroupingSeparator = newValue
            }
        }
        
        private var _lenient: Bool = false
        var isLenient: Bool {
            get {
                return _lenient
            }
            set {
                _reset()
                _lenient = newValue
            }
        }
        
        private var _usesSignificantDigits: Bool?
        var usesSignificantDigits: Bool {
            get {
                return _usesSignificantDigits ?? false
            }
            set {
                _reset()
                _usesSignificantDigits = newValue
            }
        }
        
        private var _minimumSignificantDigits: Int?
        var minimumSignificantDigits: Int {
            get {
                return _minimumSignificantDigits ?? defaultMinimumSignificantDigits()
            }
            set {
                _reset()
                _usesSignificantDigits = true
                _minimumSignificantDigits = newValue
                if _maximumSignificantDigits == nil && newValue > defaultMinimumSignificantDigits() {
                    _maximumSignificantDigits = (newValue < 1000) ? 999 : newValue
                }
            }
        }
        
        private var _maximumSignificantDigits: Int?
        var maximumSignificantDigits: Int {
            get {
                return _maximumSignificantDigits ?? defaultMaximumSignificantDigits()
            }
            set {
                _reset()
                _usesSignificantDigits = true
                _maximumSignificantDigits = newValue
            }
        }
        
        private var _partialStringValidationEnabled: Bool = false
        var isPartialStringValidationEnabled: Bool {
            get {
                return _partialStringValidationEnabled
            }
            set {
                _reset()
                _partialStringValidationEnabled = newValue
            }
        }
        
        private var _hasThousandSeparators: Bool = false
        var hasThousandSeparators: Bool {
            get {
                return _hasThousandSeparators
            }
            set {
                _reset()
                _hasThousandSeparators = newValue
            }
        }
        
        private var _thousandSeparator: String!
        var thousandSeparator: String! {
            get {
                return _thousandSeparator
            }
            set {
                _reset()
                _thousandSeparator = newValue
            }
        }
        
        private var _localizesFormat: Bool = true
        var localizesFormat: Bool {
            get {
                return _localizesFormat
            }
            set {
                _reset()
                _localizesFormat = newValue
            }
        }
        
        private var _positiveFormat: String!
        var positiveFormat: String! {
            get {
                return getFormatterComponents().0
            }
            set {
                _reset()
                _positiveFormat = newValue
            }
        }

        private var _negativeFormat: String!
        var negativeFormat: String! {
            get {
                return getFormatterComponents().1
            }
            set {
                _reset()
                _negativeFormat = newValue
            }
        }

        private var _roundingBehavior: NSDecimalNumberHandler = NSDecimalNumberHandler.default
        var roundingBehavior: NSDecimalNumberHandler {
            get {
                return _roundingBehavior
            }
            set {
                _reset()
                _roundingBehavior = newValue
            }
        }
        
        private func getZeroFormat() -> String {
            return string(from: 0) ?? "0"
        }

        var format: String {
            get {
                let (p, n) = getFormatterComponents()
                let z = _zeroSymbol ?? getZeroFormat()
                return "\(p ?? "(null)");\(z);\(n ?? "(null)")"
            }
            set {
                // Special case empty string
                if newValue == "" {
                    _positiveFormat = ""
                    _negativeFormat = "-"
                    _zeroSymbol = "0"
                    _reset()
                } else {
                    let components = newValue.components(separatedBy: ";")
                    let count = components.count
                    guard count <= 3 else { return }
                    _reset()

                    _positiveFormat = components.first ?? ""
                    if count == 1 {
                        _negativeFormat = "-\(_positiveFormat ?? "")"
                    }
                    else if count == 2 {
                        _negativeFormat = components[1]
                        _zeroSymbol = getZeroFormat()
                    }
                    else if count == 3 {
                        _zeroSymbol = components[1]
                        _negativeFormat = components[2]
                    }

                    if _negativeFormat == nil {
                        _negativeFormat = getFormatterComponents().1
                    }

                    if _zeroSymbol == nil {
                        _zeroSymbol = getZeroFormat()
                    }
                }
            }
        }

        // this is for NSUnitFormatter
        
        var formattingContext: Context = .unknown // default is NSFormattingContextUnknown
            
        func string(for obj: Any) -> String? {
            //we need to allow Swift's numeric types here - Int, Double et al.
            guard let number = __SwiftValue.store(obj) as? NSNumber else { return nil }
            return string(from: number)
        }
        
        // Even though NumberFormatter responds to the usual Formatter methods,
        //   here are some convenience methods which are a little more obvious.
        func string(from number: NSNumber) -> String? {
            return CFNumberFormatterCreateStringWithNumber(kCFAllocatorSystemDefault, formatter(), number._cfObject)._swiftObject
        }
        
        func number(from string: String) -> NSNumber? {
            var range = CFRange(location: 0, length: string.length)
            let number = withUnsafeMutablePointer(to: &range) { (rangePointer: UnsafeMutablePointer<CFRange>) -> NSNumber? in
                
                let parseOption = allowsFloats ? 0 : CFNumberFormatterOptionFlags.parseIntegersOnly.rawValue
                let result = CFNumberFormatterCreateNumberFromString(kCFAllocatorSystemDefault, formatter(), string._cfObject, rangePointer, parseOption)
                
                return result?._nsObject
            }
            return number
        }
                    
        // Attributes of a NumberFormatter. Many attributes have default values but if they are set by the caller
        // the new value needs to be retained even if the .numberStyle is changed. Attributes are backed by an optional
        // to indicate to use the default value (if nil) or the caller-supplied value (if not nil).
        private func defaultMinimumIntegerDigits() -> Int {
            switch numberStyle {
            case .ordinal, .spellOut, .currencyPlural:
                return 0
                
            case .none, .currency, .currencyISOCode, .currencyAccounting, .decimal, .percent, .scientific:
                return 1
            }
        }
        
        private func defaultMaximumIntegerDigits() -> Int {
            switch numberStyle {
            case .none:
                return 42
                
            case .ordinal, .spellOut, .currencyPlural:
                return 0
                
            case .currency, .currencyISOCode, .currencyAccounting, .decimal, .percent:
                return 2_000_000_000
                
            case .scientific:
                return 1
            }
        }
        
        private func defaultMinimumFractionDigits() -> Int {
            switch numberStyle {
            case .none, .ordinal, .spellOut, .currencyPlural, .decimal, .percent, .scientific:
                return 0
                
            case .currency, .currencyISOCode, .currencyAccounting:
                return 2
            }
        }
        
        private func defaultMaximumFractionDigits() -> Int {
            switch numberStyle {
            case .none, .ordinal, .spellOut, .currencyPlural, .percent, .scientific:
                return 0
                
            case .currency, .currencyISOCode, .currencyAccounting:
                return 2
                
            case .decimal:
                return 3
            }
        }
        
        private func defaultMinimumSignificantDigits() -> Int {
            switch numberStyle {
            case .ordinal, .spellOut, .currencyPlural:
                return 0
                
            case .currency, .none, .currencyISOCode, .currencyAccounting, .decimal, .percent, .scientific:
                return -1
            }
        }
        
        private func defaultMaximumSignificantDigits() -> Int {
            switch numberStyle {
            case .none, .currency, .currencyISOCode, .currencyAccounting, .decimal, .percent, .scientific:
                return -1
                
            case .ordinal, .spellOut, .currencyPlural:
                return 0
            }
        }
        
        private func defaultUsesGroupingSeparator() -> Bool {
            switch numberStyle {
            case .none, .scientific, .spellOut, .ordinal, .currencyPlural:
                return false
                
            case .decimal, .currency, .percent, .currencyAccounting, .currencyISOCode:
                return true
            }
        }
        
        private func defaultGroupingSize() -> Int {
            switch numberStyle {
            case .none, .ordinal, .spellOut, .currencyPlural, .scientific:
                return 0
                
            case .currency, .currencyISOCode, .currencyAccounting, .decimal, .percent:
                return 3
            }
        }
        
        private func defaultMultiplier() -> NSNumber? {
            switch numberStyle {
            case .percent:  return NSNumber(100)
            default:        return nil
            }
        }
        
        private func defaultFormatWidth() -> Int {
            switch numberStyle {
            case .ordinal, .spellOut, .currencyPlural:
                return 0
                
            case .none, .decimal, .currency, .percent, .scientific, .currencyISOCode, .currencyAccounting:
                return -1
            }
        }
    }
    
    // MARK: -
    
    open func string(from number: NSNumber) -> String? {
        _lock.withLock { $0.string(from: number) }
    }

    open func number(from string: String) -> NSNumber? {
        _lock.withLock { $0.number(from: string) }
    }
    
    open override func string(for obj: Any) -> String? {
        //we need to allow Swift's numeric types here - Int, Double et al.
        guard let number = __SwiftValue.store(obj) as? NSNumber else { return nil }
        return string(from: number)
    }
    
    open var numberStyle: Style {
        get { _lock.withLock { $0.numberStyle } }
        set { _lock.withLock { $0.numberStyle = newValue } }
    }

    open var locale: Locale! {
        get { _lock.withLock { $0.locale } }
        set { _lock.withLock { $0.locale = newValue } }
    }

    open var generatesDecimalNumbers: Bool {
        get { _lock.withLock { $0.generatesDecimalNumbers } }
        set { _lock.withLock { $0.generatesDecimalNumbers = newValue } }
    }

    open var textAttributesForNegativeValues: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForNegativeValues } }
        set { _lock.withLock { $0.textAttributesForNegativeValues = newValue } }
    }

    open var textAttributesForPositiveValues: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForPositiveValues } }
        set { _lock.withLock { $0.textAttributesForPositiveValues = newValue } }
    }

    open var allowsFloats: Bool {
        get { _lock.withLock { $0.allowsFloats } }
        set { _lock.withLock { $0.allowsFloats = newValue } }
    }

    open var decimalSeparator: String! {
        get { _lock.withLock { $0.decimalSeparator } }
        set { _lock.withLock { $0.decimalSeparator = newValue } }
    }

    open var alwaysShowsDecimalSeparator: Bool {
        get { _lock.withLock { $0.alwaysShowsDecimalSeparator } }
        set { _lock.withLock { $0.alwaysShowsDecimalSeparator = newValue } }
    }

    open var currencyDecimalSeparator: String! {
        get { _lock.withLock { $0.currencyDecimalSeparator } }
        set { _lock.withLock { $0.currencyDecimalSeparator = newValue } }
    }

    open var usesGroupingSeparator: Bool {
        get { _lock.withLock { $0.usesGroupingSeparator } }
        set { _lock.withLock { $0.usesGroupingSeparator = newValue } }
    }

    open var groupingSeparator: String! {
        get { _lock.withLock { $0.groupingSeparator } }
        set { _lock.withLock { $0.groupingSeparator = newValue } }
    }

    open var zeroSymbol: String? {
        get { _lock.withLock { $0.zeroSymbol } }
        set { _lock.withLock { $0.zeroSymbol = newValue } }
    }

    open var textAttributesForZero: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForZero } }
        set { _lock.withLock { $0.textAttributesForZero = newValue } }
    }

    open var nilSymbol: String {
        get { _lock.withLock { $0.nilSymbol } }
        set { _lock.withLock { $0.nilSymbol = newValue } }
    }

    open var textAttributesForNil: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForNil } }
        set { _lock.withLock { $0.textAttributesForNil = newValue } }
    }

    open var notANumberSymbol: String! {
        get { _lock.withLock { $0.notANumberSymbol } }
        set { _lock.withLock { $0.notANumberSymbol = newValue } }
    }

    open var textAttributesForNotANumber: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForNotANumber } }
        set { _lock.withLock { $0.textAttributesForNotANumber = newValue } }
    }

    open var positiveInfinitySymbol: String {
        get { _lock.withLock { $0.positiveInfinitySymbol } }
        set { _lock.withLock { $0.positiveInfinitySymbol = newValue } }
    }

    open var textAttributesForPositiveInfinity: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForPositiveInfinity } }
        set { _lock.withLock { $0.textAttributesForPositiveInfinity = newValue } }
    }

    open var negativeInfinitySymbol: String {
        get { _lock.withLock { $0.negativeInfinitySymbol } }
        set { _lock.withLock { $0.negativeInfinitySymbol = newValue } }
    }

    open var textAttributesForNegativeInfinity: [String : (Any & Sendable)]? {
        get { _lock.withLock { $0.textAttributesForNegativeInfinity } }
        set { _lock.withLock { $0.textAttributesForNegativeInfinity = newValue } }
    }

    open var positivePrefix: String! {
        get { _lock.withLock { $0.positivePrefix } }
        set { _lock.withLock { $0.positivePrefix = newValue } }
    }

    open var positiveSuffix: String! {
        get { _lock.withLock { $0.positiveSuffix } }
        set { _lock.withLock { $0.positiveSuffix = newValue } }
    }

    open var negativePrefix: String! {
        get { _lock.withLock { $0.negativePrefix } }
        set { _lock.withLock { $0.negativePrefix = newValue } }
    }

    open var negativeSuffix: String! {
        get { _lock.withLock { $0.negativeSuffix } }
        set { _lock.withLock { $0.negativeSuffix = newValue } }
    }

    open var currencyCode: String! {
        get { _lock.withLock { $0.currencyCode } }
        set { _lock.withLock { $0.currencyCode = newValue } }
    }

    open var currencySymbol: String! {
        get { _lock.withLock { $0.currencySymbol } }
        set { _lock.withLock { $0.currencySymbol = newValue } }
    }

    open var internationalCurrencySymbol: String! {
        get { _lock.withLock { $0.internationalCurrencySymbol } }
        set { _lock.withLock { $0.internationalCurrencySymbol = newValue } }
    }

    open var percentSymbol: String! {
        get { _lock.withLock { $0.percentSymbol } }
        set { _lock.withLock { $0.percentSymbol = newValue } }
    }

    open var perMillSymbol: String! {
        get { _lock.withLock { $0.perMillSymbol } }
        set { _lock.withLock { $0.perMillSymbol = newValue } }
    }

    open var minusSign: String! {
        get { _lock.withLock { $0.minusSign } }
        set { _lock.withLock { $0.minusSign = newValue } }
    }

    open var plusSign: String! {
        get { _lock.withLock { $0.plusSign } }
        set { _lock.withLock { $0.plusSign = newValue } }
    }

    open var exponentSymbol: String! {
        get { _lock.withLock { $0.exponentSymbol } }
        set { _lock.withLock { $0.exponentSymbol = newValue } }
    }

    open var groupingSize: Int {
        get { _lock.withLock { $0.groupingSize } }
        set { _lock.withLock { $0.groupingSize = newValue } }
    }

    open var secondaryGroupingSize: Int {
        get { _lock.withLock { $0.secondaryGroupingSize } }
        set { _lock.withLock { $0.secondaryGroupingSize = newValue } }
    }

    open var multiplier: NSNumber? {
        get { _lock.withLock { $0.multiplier } }
        set { _lock.withLock { $0.multiplier = newValue } }
    }

    open var formatWidth: Int {
        get { _lock.withLock { $0.formatWidth } }
        set { _lock.withLock { $0.formatWidth = newValue } }
    }

    open var paddingCharacter: String! {
        get { _lock.withLock { $0.paddingCharacter } }
        set { _lock.withLock { $0.paddingCharacter = newValue } }
    }

    open var paddingPosition: PadPosition {
        get { _lock.withLock { $0.paddingPosition } }
        set { _lock.withLock { $0.paddingPosition = newValue } }
    }

    open var roundingMode: RoundingMode {
        get { _lock.withLock { $0.roundingMode } }
        set { _lock.withLock { $0.roundingMode = newValue } }
    }

    open var roundingIncrement: NSNumber! {
        get { _lock.withLock { $0.roundingIncrement } }
        set { _lock.withLock { $0.roundingIncrement = newValue } }
    }

    open var minimumIntegerDigits: Int {
        get { _lock.withLock { $0.minimumIntegerDigits } }
        set { _lock.withLock { $0.minimumIntegerDigits = newValue } }
    }

    open var maximumIntegerDigits: Int {
        get { _lock.withLock { $0.maximumIntegerDigits } }
        set { _lock.withLock { $0.maximumIntegerDigits = newValue } }
    }

    open var minimumFractionDigits: Int {
        get { _lock.withLock { $0.minimumFractionDigits } }
        set { _lock.withLock { $0.minimumFractionDigits = newValue } }
    }

    open var maximumFractionDigits: Int {
        get { _lock.withLock { $0.maximumFractionDigits } }
        set { _lock.withLock { $0.maximumFractionDigits = newValue } }
    }

    open var minimum: NSNumber? {
        get { _lock.withLock { $0.minimum } }
        set { _lock.withLock { $0.minimum = newValue } }
    }

    open var maximum: NSNumber? {
        get { _lock.withLock { $0.maximum } }
        set { _lock.withLock { $0.maximum = newValue } }
    }

    open var currencyGroupingSeparator: String! {
        get { _lock.withLock { $0.currencyGroupingSeparator } }
        set { _lock.withLock { $0.currencyGroupingSeparator = newValue } }
    }

    open var isLenient: Bool {
        get { _lock.withLock { $0.isLenient } }
        set { _lock.withLock { $0.isLenient = newValue } }
    }

    open var usesSignificantDigits: Bool {
        get { _lock.withLock { $0.usesSignificantDigits } }
        set { _lock.withLock { $0.usesSignificantDigits = newValue } }
    }

    open var minimumSignificantDigits: Int {
        get { _lock.withLock { $0.minimumSignificantDigits } }
        set { _lock.withLock { $0.minimumSignificantDigits = newValue } }
    }

    open var maximumSignificantDigits: Int {
        get { _lock.withLock { $0.maximumSignificantDigits } }
        set { _lock.withLock { $0.maximumSignificantDigits = newValue } }
    }

    open var isPartialStringValidationEnabled: Bool {
        get { _lock.withLock { $0.isPartialStringValidationEnabled } }
        set { _lock.withLock { $0.isPartialStringValidationEnabled = newValue } }
    }

    open var hasThousandSeparators: Bool {
        get { _lock.withLock { $0.hasThousandSeparators } }
        set { _lock.withLock { $0.hasThousandSeparators = newValue } }
    }

    open var thousandSeparator: String! {
        get { _lock.withLock { $0.thousandSeparator } }
        set { _lock.withLock { $0.thousandSeparator = newValue } }
    }

    open var localizesFormat: Bool {
        get { _lock.withLock { $0.localizesFormat } }
        set { _lock.withLock { $0.localizesFormat = newValue } }
    }

    open var format: String {
        get { _lock.withLock { $0.format } }
        set { _lock.withLock { $0.format = newValue } }
    }

    open var positiveFormat: String! {
        get { _lock.withLock { $0.positiveFormat } }
        set { _lock.withLock { $0.positiveFormat = newValue } }
    }

    open var negativeFormat: String! {
        get { _lock.withLock { $0.negativeFormat } }
        set { _lock.withLock { $0.negativeFormat = newValue } }
    }

    open var roundingBehavior: NSDecimalNumberHandler {
        get { _lock.withLock { $0.roundingBehavior } }
        set { _lock.withLock { $0.roundingBehavior = newValue } }
    }
}
