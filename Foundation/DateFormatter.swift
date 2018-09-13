// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class DateFormatter : Formatter {
    typealias CFType = CFDateFormatter
    private var __cfObject: CFType?
    private var _cfObject: CFType {
        guard let obj = __cfObject else {
            #if os(macOS) || os(iOS)
            let dateStyle = CFDateFormatterStyle(rawValue: CFIndex(self.dateStyle.rawValue))!
            let timeStyle = CFDateFormatterStyle(rawValue: CFIndex(self.timeStyle.rawValue))!
            #else
            let dateStyle = CFDateFormatterStyle(self.dateStyle.rawValue)
            let timeStyle = CFDateFormatterStyle(self.timeStyle.rawValue)
            #endif
            
            let obj = CFDateFormatterCreate(kCFAllocatorSystemDefault, locale._cfObject, dateStyle, timeStyle)!
            _setFormatterAttributes(obj)
            if let dateFormat = _dateFormat {
                CFDateFormatterSetFormat(obj, dateFormat._cfObject)
            }
            __cfObject = obj
            return obj
        }
        return obj
    }
    
    private var attributes: [String: Any] {
        get {
            var result = [String: Any]()
            
            result[AttributeKey.dateFormat] = _dateFormat
            result[AttributeKey.timeZone] = _timeZone
            result[AttributeKey.calendar] = _calendar
            result[AttributeKey.locale] = _locale
            result[AttributeKey.amSymbol] = _amSymbol
            result[AttributeKey.pmSymbol] = _pmSymbol
            result[AttributeKey.eraSymbols] = _eraSymbols
            result[AttributeKey.longEraSymbols] = _longEraSymbols
            result[AttributeKey.veryShortWeekdaySymbols] = _veryShortWeekdaySymbols
            result[AttributeKey.shortWeekdaySymbols] = _shortWeekdaySymbols
            result[AttributeKey.weekdaySymbols] = _weekdaySymbols
            result[AttributeKey.veryShortStandaloneWeekdaySymbols] = _veryShortStandaloneWeekdaySymbols
            result[AttributeKey.shortStandaloneWeekdaySymbols] = _shortStandaloneWeekdaySymbols
            result[AttributeKey.standaloneWeekdaySymbols] = _standaloneWeekdaySymbols
            result[AttributeKey.veryShortMonthSymbols] = _veryShortMonthSymbols
            result[AttributeKey.shortMonthSymbols] = _shortMonthSymbols
            result[AttributeKey.monthSymbols] = _monthSymbols
            result[AttributeKey.veryShortStandaloneMonthSymbols] = _veryShortStandaloneMonthSymbols
            result[AttributeKey.shortStandaloneMonthSymbols] = _shortStandaloneMonthSymbols
            result[AttributeKey.standaloneMonthSymbols] = _standaloneMonthSymbols
            result[AttributeKey.shortQuarterSymbols] = _shortQuarterSymbols
            result[AttributeKey.quarterSymbols] = _quarterSymbols
            result[AttributeKey.shortStandaloneQuarterSymbols] = _shortStandaloneQuarterSymbols
            result[AttributeKey.standaloneQuarterSymbols] = _standaloneQuarterSymbols
            if doesRelativeDateFormatting {
                result[AttributeKey.doesRelativeDateFormatting] = true
            }
            if generatesCalendarDates {
                result[AttributeKey.generatesCalendarDates] = true
            }
            if isLenient {
                result[AttributeKey.isLenient] = true
            }
            result[AttributeKey.twoDigitStartDate] = _twoDigitStartDate
            result[AttributeKey.gregorianStartDate] = _gregorianStartDate
            result[AttributeKey.defaultDate] = defaultDate
            return result
        }
        set {
            _dateFormat = newValue[AttributeKey.dateFormat] as? String
            _timeZone = newValue[AttributeKey.timeZone] as? TimeZone
            _calendar = newValue[AttributeKey.calendar] as? Calendar
            _locale = newValue[AttributeKey.locale] as? Locale
            _amSymbol = newValue[AttributeKey.amSymbol] as? String
            _pmSymbol = newValue[AttributeKey.pmSymbol] as? String
            _eraSymbols = newValue[AttributeKey.eraSymbols] as? [String]
            _longEraSymbols = newValue[AttributeKey.longEraSymbols] as? [String]
            _veryShortWeekdaySymbols = newValue[AttributeKey.veryShortWeekdaySymbols] as? [String]
            _shortWeekdaySymbols = newValue[AttributeKey.shortWeekdaySymbols] as? [String]
            _weekdaySymbols = newValue[AttributeKey.weekdaySymbols] as? [String]
            _veryShortStandaloneWeekdaySymbols = newValue[AttributeKey.veryShortStandaloneWeekdaySymbols] as? [String]
            _shortStandaloneWeekdaySymbols = newValue[AttributeKey.shortStandaloneWeekdaySymbols] as? [String]
            _standaloneWeekdaySymbols = newValue[AttributeKey.standaloneWeekdaySymbols] as? [String]
            _veryShortMonthSymbols = newValue[AttributeKey.veryShortMonthSymbols] as? [String]
            _shortMonthSymbols = newValue[AttributeKey.shortMonthSymbols] as? [String]
            _monthSymbols = newValue[AttributeKey.monthSymbols] as? [String]
            _veryShortStandaloneMonthSymbols = newValue[AttributeKey.veryShortStandaloneMonthSymbols] as? [String]
            _shortStandaloneMonthSymbols = newValue[AttributeKey.shortStandaloneMonthSymbols] as? [String]
            _standaloneMonthSymbols = newValue[AttributeKey.standaloneMonthSymbols] as? [String]
            _shortQuarterSymbols = newValue[AttributeKey.shortQuarterSymbols] as? [String]
            _quarterSymbols = newValue[AttributeKey.quarterSymbols] as? [String]
            _shortStandaloneQuarterSymbols = newValue[AttributeKey.shortStandaloneQuarterSymbols] as? [String]
            _standaloneQuarterSymbols = newValue[AttributeKey.standaloneQuarterSymbols] as? [String]
            doesRelativeDateFormatting = newValue[AttributeKey.doesRelativeDateFormatting] as? Bool ?? false
            generatesCalendarDates = newValue[AttributeKey.generatesCalendarDates] as? Bool ?? false
            isLenient = newValue[AttributeKey.isLenient] as? Bool ?? false
            _twoDigitStartDate = newValue[AttributeKey.twoDigitStartDate] as? Date
            _gregorianStartDate = newValue[AttributeKey.gregorianStartDate] as? Date
            defaultDate = newValue[AttributeKey.defaultDate] as? Date
        }
    }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        super.init(coder: aDecoder)
        let attributes = aDecoder.decodeObject(forKey: "NS.attributes") as? NSMutableDictionary
        attributes?.removeObject(forKey: "formatterBehavior")
        if let attributes = attributes?._swiftObject as? [String: Any] {
            self.attributes = attributes
        }
    }
    
    open override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        let attributes = NSMutableDictionary(dictionary: self.attributes)
        attributes.setObject(NSNumber(value: 1040), forKey: "formatterBehavior")
        aCoder.encode(attributes, forKey: "NS.attributes")
    }
    
    open var formattingContext: Context = .unknown // default is NSFormattingContextUnknown
    
    open func objectValue(_ string: String, range rangep: UnsafeMutablePointer<NSRange>) throws -> AnyObject? { NSUnimplemented() }
    
    open override func string(for obj: Any) -> String? {
        guard let date = obj as? Date else { return nil }
        return string(from: date)
    }
    
    open func string(from date: Date) -> String {
        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, _cfObject, date._cfObject)._swiftObject
    }
    
    open func date(from string: String) -> Date? {
        var range = CFRange(location: 0, length: string.length)
        let date = withUnsafeMutablePointer(to: &range) { (rangep: UnsafeMutablePointer<CFRange>) -> Date? in
            guard let res = CFDateFormatterCreateDateFromString(kCFAllocatorSystemDefault, _cfObject, string._cfObject, rangep) else {
                return nil
            }
            return res._swiftObject
        }
        return date
    }
    
    open class func localizedString(from date: Date, dateStyle dstyle: Style, timeStyle tstyle: Style) -> String {
        let df = DateFormatter()
        df.dateStyle = dstyle
        df.timeStyle = tstyle
        return df.string(for: date._nsObject)!
    }
    
    open class func dateFormat(fromTemplate tmplate: String, options opts: Int, locale: Locale?) -> String? {
        guard let res = CFDateFormatterCreateDateFormatFromTemplate(kCFAllocatorSystemDefault, tmplate._cfObject, CFOptionFlags(opts), locale?._cfObject) else {
            return nil
        }
        return res._swiftObject
    }
    
    open func setLocalizedDateFormatFromTemplate(_ dateFormatTemplate: String) {
        if let format = DateFormatter.dateFormat(fromTemplate: dateFormatTemplate, options: 0, locale: locale) {
            dateFormat = format
        }
    }
    
    private func _reset() {
        __cfObject = nil
    }
    
    internal func _setFormatterAttributes(_ formatter: CFDateFormatter) {
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterIsLenient, value: isLenient._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterTimeZone, value: _timeZone?._cfObject)
        if let ident = _calendar?.identifier {
            _setFormatterAttribute(formatter, attributeName: kCFDateFormatterCalendarName, value: Calendar._toNSCalendarIdentifier(ident).rawValue._cfObject)
        } else {
            _setFormatterAttribute(formatter, attributeName: kCFDateFormatterCalendarName, value: nil)
        }
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterTwoDigitStartDate, value: _twoDigitStartDate?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterDefaultDate, value: defaultDate?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterCalendar, value: _calendar?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterEraSymbols, value: _eraSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterMonthSymbols, value: _monthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortMonthSymbols, value: _shortMonthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterWeekdaySymbols, value: _weekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortWeekdaySymbols, value: _shortWeekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterAMSymbol, value: _amSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterPMSymbol, value: _pmSymbol?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterLongEraSymbols, value: _longEraSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterVeryShortMonthSymbols, value: _veryShortMonthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterStandaloneMonthSymbols, value: _standaloneMonthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortStandaloneMonthSymbols, value: _shortStandaloneMonthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterVeryShortStandaloneMonthSymbols, value: _veryShortStandaloneMonthSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterVeryShortWeekdaySymbols, value: _veryShortWeekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterStandaloneWeekdaySymbols, value: _standaloneWeekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortStandaloneWeekdaySymbols, value: _shortStandaloneWeekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterVeryShortStandaloneWeekdaySymbols, value: _veryShortStandaloneWeekdaySymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterQuarterSymbols, value: _quarterSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortQuarterSymbols, value: _shortQuarterSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterStandaloneQuarterSymbols, value: _standaloneQuarterSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterShortStandaloneQuarterSymbols, value: _shortStandaloneQuarterSymbols?._cfObject)
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterGregorianStartDate, value: _gregorianStartDate?._cfObject)
    }
    
    internal func _setFormatterAttribute(_ formatter: CFDateFormatter, attributeName: CFString, value: AnyObject?) {
        if let value = value {
            CFDateFormatterSetProperty(formatter, attributeName, value)
        }
    }
    
    private var _dateFormat: String? { willSet { _reset() } }
    open var dateFormat: String! {
        get {
            guard let format = _dateFormat else {
                return __cfObject.map { CFDateFormatterGetFormat($0)._swiftObject } ?? ""
            }
            return format
        }
        set {
            _dateFormat = newValue
        }
    }
    
    open var dateStyle: Style = .none {
        willSet {
            _dateFormat = nil
        }
        didSet {
            _dateFormat = CFDateFormatterGetFormat(_cfObject)._swiftObject
        }
    }
    
    open var timeStyle: Style = .none {
        willSet {
            _dateFormat = nil
        }
        didSet {
            _dateFormat = CFDateFormatterGetFormat(_cfObject)._swiftObject
        }
    }
    
    /*@NSCopying*/ internal var _locale: Locale? { willSet { _reset() } }
    open var locale: Locale! {
        get {
            guard let locale = _locale else { return .current }
            return locale
        }
        set {
            _locale = newValue
        }
    }
    
    open var generatesCalendarDates = false { willSet { _reset() } }
    
    /*@NSCopying*/ internal var _timeZone: TimeZone? { willSet { _reset() } }
    open var timeZone: TimeZone! {
        get {
            guard let timeZone = _timeZone else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterTimeZone) as! NSTimeZone)._swiftObject
            }
            return timeZone
        }
        set {
            _timeZone = timeZone
        }
    }
    
    /*@NSCopying*/ internal var _calendar: Calendar! { willSet { _reset() } }
    open var calendar: Calendar! {
        get {
            guard let calendar = _calendar else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterCalendar) as! NSCalendar)._swiftObject
            }
            return calendar
        }
        set {
            _calendar = newValue
        }
    }
    
    open var isLenient = false { willSet { _reset() } }
    
    /*@NSCopying*/ internal var _twoDigitStartDate: Date? { willSet { _reset() } }
    open var twoDigitStartDate: Date? {
        get {
            guard let startDate = _twoDigitStartDate else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterTwoDigitStartDate) as? NSDate)?._swiftObject
            }
            return startDate
        }
        set {
            _twoDigitStartDate = newValue
        }
    }
    
    /*@NSCopying*/ open var defaultDate: Date? { willSet { _reset() } }
    
    internal var _eraSymbols: [String]! { willSet { _reset() } }
    open var eraSymbols: [String]! {
        get {
            guard let symbols = _eraSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterEraSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _eraSymbols = newValue
        }
    }
    
    internal var _monthSymbols: [String]! { willSet { _reset() } }
    open var monthSymbols: [String]! {
        get {
            guard let symbols = _monthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _monthSymbols = newValue
        }
    }
    
    internal var _shortMonthSymbols: [String]! { willSet { _reset() } }
    open var shortMonthSymbols: [String]! {
        get {
            guard let symbols = _shortMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortMonthSymbols = newValue
        }
    }
    
    
    internal var _weekdaySymbols: [String]! { willSet { _reset() } }
    open var weekdaySymbols: [String]! {
        get {
            guard let symbols = _weekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _weekdaySymbols = newValue
        }
    }
    
    internal var _shortWeekdaySymbols: [String]! { willSet { _reset() } }
    open var shortWeekdaySymbols: [String]! {
        get {
            guard let symbols = _shortWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortWeekdaySymbols = newValue
        }
    }
    
    internal var _amSymbol: String! { willSet { _reset() } }
    open var amSymbol: String! {
        get {
            guard let symbol = _amSymbol else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterAMSymbol) as! NSString)._swiftObject
            }
            return symbol
        }
        set {
            _amSymbol = newValue
        }
    }
    
    internal var _pmSymbol: String! { willSet { _reset() } }
    open var pmSymbol: String! {
        get {
            guard let symbol = _pmSymbol else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterPMSymbol) as! NSString)._swiftObject
            }
            return symbol
        }
        set {
            _pmSymbol = newValue
        }
    }
    
    internal var _longEraSymbols: [String]! { willSet { _reset() } }
    open var longEraSymbols: [String]! {
        get {
            guard let symbols = _longEraSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterLongEraSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _longEraSymbols = newValue
        }
    }
    
    internal var _veryShortMonthSymbols: [String]! { willSet { _reset() } }
    open var veryShortMonthSymbols: [String]! {
        get {
            guard let symbols = _veryShortMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _veryShortMonthSymbols = newValue
        }
    }
    
    internal var _standaloneMonthSymbols: [String]! { willSet { _reset() } }
    open var standaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _standaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _standaloneMonthSymbols = newValue
        }
    }
    
    internal var _shortStandaloneMonthSymbols: [String]! { willSet { _reset() } }
    open var shortStandaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortStandaloneMonthSymbols = newValue
        }
    }
    
    internal var _veryShortStandaloneMonthSymbols: [String]! { willSet { _reset() } }
    open var veryShortStandaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _veryShortStandaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _veryShortStandaloneMonthSymbols = newValue
        }
    }
    
    internal var _veryShortWeekdaySymbols: [String]! { willSet { _reset() } }
    open var veryShortWeekdaySymbols: [String]! {
        get {
            guard let symbols = _veryShortWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _veryShortWeekdaySymbols = newValue
        }
    }
    
    internal var _standaloneWeekdaySymbols: [String]! { willSet { _reset() } }
    open var standaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _standaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _standaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _shortStandaloneWeekdaySymbols: [String]! { willSet { _reset() } }
    open var shortStandaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortStandaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _veryShortStandaloneWeekdaySymbols: [String]! { willSet { _reset() } }
    open var veryShortStandaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _veryShortStandaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _veryShortStandaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _quarterSymbols: [String]! { willSet { _reset() } }
    open var quarterSymbols: [String]! {
        get {
            guard let symbols = _quarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _quarterSymbols = newValue
        }
    }
    
    internal var _shortQuarterSymbols: [String]! { willSet { _reset() } }
    open var shortQuarterSymbols: [String]! {
        get {
            guard let symbols = _shortQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortQuarterSymbols = newValue
        }
    }
    
    internal var _standaloneQuarterSymbols: [String]! { willSet { _reset() } }
    open var standaloneQuarterSymbols: [String]! {
        get {
            guard let symbols = _standaloneQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _standaloneQuarterSymbols = newValue
        }
    }
    
    internal var _shortStandaloneQuarterSymbols: [String]! { willSet { _reset() } }
    open var shortStandaloneQuarterSymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _shortStandaloneQuarterSymbols = newValue
        }
    }
    
    internal var _gregorianStartDate: Date? { willSet { _reset() } }
    open var gregorianStartDate: Date? {
        get {
            guard let startDate = _gregorianStartDate else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterGregorianStartDate) as? NSDate)?._swiftObject
            }
            return startDate
        }
        set {
            _gregorianStartDate = newValue
        }
    }
    
    open var doesRelativeDateFormatting = false { willSet { _reset() } }
}

extension DateFormatter {
    public enum Style : UInt {
        case none
        case short
        case medium
        case long
        case full
    }
}

extension DateFormatter {
    internal struct AttributeKey: Equatable, Hashable {
        static let dateFormat = "dateFormat"
        static let timeZone = "timeZone"
        static let calendar = "calendar"
        static let locale = "locale"
        static let amSymbol = "AMSymbol"
        static let pmSymbol = "PMSymbol"
        static let eraSymbols = "eraSymbols"
        static let longEraSymbols = "longEraSymbols"
        static let veryShortWeekdaySymbols = "veryShortWeekdaySymbols"
        static let shortWeekdaySymbols = "shortWeekdaySymbols"
        static let weekdaySymbols = "weekdaySymbols"
        static let veryShortStandaloneWeekdaySymbols = "veryShortStandaloneWeekdaySymbols"
        static let shortStandaloneWeekdaySymbols = "shortStandaloneWeekdaySymbols"
        static let standaloneWeekdaySymbols = "standaloneWeekdaySymbols"
        static let veryShortMonthSymbols = "veryShortMonthSymbols"
        static let shortMonthSymbols = "shortMonthSymbols"
        static let monthSymbols = "monthSymbols"
        static let veryShortStandaloneMonthSymbols = "veryShortStandaloneMonthSymbols"
        static let shortStandaloneMonthSymbols = "shortStandaloneMonthSymbols"
        static let standaloneMonthSymbols = "standaloneMonthSymbols"
        static let shortQuarterSymbols = "shortQuarterSymbols"
        static let quarterSymbols = "quarterSymbols"
        static let shortStandaloneQuarterSymbols = "shortStandaloneQuarterSymbols"
        static let standaloneQuarterSymbols = "standaloneQuarterSymbols"
        static let doesRelativeDateFormatting = "doesRelativeDateFormatting"
        static let generatesCalendarDates = "generatesCalendarDates"
        static let isLenient = "lenient"
        static let twoDigitStartDate = "twoDigitStartDate"
        static let gregorianStartDate = "gregorianStartDate"
        static let defaultDate = "defaultDate"
    }
}

