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
            if let dateFormat = attributes[AttributeKey.dateFormat] as? String {
                CFDateFormatterSetFormat(obj, dateFormat._cfObject)
            }
            __cfObject = obj
            return obj
        }
        return obj
    }
    
    private var attributes: [String: Any] = [:]

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
        _setFormatterAttribute(formatter, attributeName: kCFDateFormatterTimeZone, value: timeZone?._cfObject)
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
    
    open var dateFormat: String! {
        get {
            guard let format = attributes[AttributeKey.dateFormat] as? String else {
                return __cfObject.map { CFDateFormatterGetFormat($0)._swiftObject } ?? ""
            }
            return format
        }
        set {
            _reset()
            attributes[AttributeKey.dateFormat] = newValue?._nsObject
        }
    }

    open var dateStyle: Style = .none {
        willSet {
            dateFormat = nil
        }
        didSet {
            dateFormat = CFDateFormatterGetFormat(_cfObject)._swiftObject
        }
    }

    open var timeStyle: Style = .none {
        willSet {
            dateFormat = nil
        }
        didSet {
            dateFormat = CFDateFormatterGetFormat(_cfObject)._swiftObject
        }
    }
    
    /*@NSCopying*/ open var locale: Locale! {
        get {
            return (attributes[AttributeKey.locale] as? NSLocale)?._swiftObject ?? .current
        }
        set {
            _reset()
            attributes[AttributeKey.locale] = newValue?._bridgeToObjectiveC()
        }
    }
    
    open var generatesCalendarDates: Bool {
        get {
            return (attributes[AttributeKey.generatesCalendarDates] as? NSNumber)?.boolValue ?? false
        }
        set {
            _reset()
            attributes[AttributeKey.generatesCalendarDates] = NSNumber(value: newValue)
        }
    }

    /*@NSCopying*/ open var timeZone: TimeZone! {
        get {
            return (attributes[AttributeKey.generatesCalendarDates] as? NSTimeZone)?._swiftObject ?? NSTimeZone.system
        }
        set {
            _reset()
            attributes[AttributeKey.generatesCalendarDates] = newValue?._nsObject
        }
    }
    
    private var _calendar: Calendar? {
        return (attributes[AttributeKey.calendar] as? NSCalendar)?._swiftObject
    }
    open var calendar: Calendar! {
        get {
            guard let calendar = _calendar else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterCalendar) as! NSCalendar)._swiftObject
            }
            return calendar
        }
        set {
            _reset()
            attributes[AttributeKey.calendar] = newValue?._nsObject
        }
    }

    open var isLenient: Bool {
        get {
            return (attributes[AttributeKey.isLenient] as? NSNumber)?.boolValue ?? false
        }
        set {
            _reset()
            attributes[AttributeKey.isLenient] = NSNumber(value: newValue)
        }
    }
    
    private var _twoDigitStartDate: Date? {
        return (attributes[AttributeKey.twoDigitStartDate] as? NSDate)?._swiftObject
    }
    /*@NSCopying*/ open var twoDigitStartDate: Date? {
        get {
            guard let startDate = _twoDigitStartDate else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterTwoDigitStartDate) as? NSDate)?._swiftObject
            }
            return startDate
        }
        set {
            _reset()
            attributes[AttributeKey.twoDigitStartDate] = newValue?._nsObject
        }
    }

    /*@NSCopying*/ open var defaultDate: Date? {
        get {
            return (attributes[AttributeKey.defaultDate] as? NSDate)?._swiftObject
        }
        set {
            _reset()
            attributes[AttributeKey.defaultDate] = newValue?._nsObject
        }
    }
    
    internal var _eraSymbols: [String]? {
        return attributes[AttributeKey.eraSymbols] as? [String]
    }
    open var eraSymbols: [String]! {
        get {
            guard let symbols = _eraSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterEraSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.eraSymbols] = newValue?._nsObject
        }
    }
    
    internal var _monthSymbols: [String]? {
        return attributes[AttributeKey.monthSymbols] as? [String]
    }
    open var monthSymbols: [String]! {
        get {
            guard let symbols = _monthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.monthSymbols] = newValue?._nsObject
        }
    }

    internal var _shortMonthSymbols: [String]? {
        return attributes[AttributeKey.shortMonthSymbols] as? [String]
    }
    open var shortMonthSymbols: [String]! {
        get {
            guard let symbols = _shortMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortMonthSymbols] = newValue?._nsObject
        }
    }
    

    internal var _weekdaySymbols: [String]? {
        return attributes[AttributeKey.weekdaySymbols] as? [String]
    }
    open var weekdaySymbols: [String]! {
        get {
            guard let symbols = _weekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.weekdaySymbols] = newValue?._nsObject
        }
    }

    internal var _shortWeekdaySymbols: [String]? {
        return attributes[AttributeKey.shortWeekdaySymbols] as? [String]
    }
    open var shortWeekdaySymbols: [String]! {
        get {
            guard let symbols = _shortWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortWeekdaySymbols] = newValue?._nsObject
        }
    }

    internal var _amSymbol: String? {
        return attributes[AttributeKey.amSymbol] as? String
    }
    open var amSymbol: String! {
        get {
            guard let symbol = _amSymbol else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterAMSymbol) as! NSString)._swiftObject
            }
            return symbol
        }
        set {
            _reset()
            attributes[AttributeKey.amSymbol] = newValue?._nsObject
        }
    }

    internal var _pmSymbol: String! {
        return attributes[AttributeKey.pmSymbol] as? String
    }
    open var pmSymbol: String! {
        get {
            guard let symbol = _pmSymbol else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterPMSymbol) as! NSString)._swiftObject
            }
            return symbol
        }
        set {
            _reset()
            attributes[AttributeKey.pmSymbol] = newValue?._nsObject
        }
    }

    internal var _longEraSymbols: [String]? {
        return attributes[AttributeKey.longEraSymbols] as? [String]
    }
    open var longEraSymbols: [String]! {
        get {
            guard let symbols = _longEraSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterLongEraSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.longEraSymbols] = newValue?._nsObject
        }
    }

    internal var _veryShortMonthSymbols: [String]? {
        return attributes[AttributeKey.veryShortMonthSymbols] as? [String]
    }
    open var veryShortMonthSymbols: [String]! {
        get {
            guard let symbols = _veryShortMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.veryShortMonthSymbols] = newValue?._nsObject
        }
    }

    internal var _standaloneMonthSymbols: [String]? {
        return attributes[AttributeKey.standaloneMonthSymbols] as? [String]
    }
    open var standaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _standaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.standaloneMonthSymbols] = newValue?._nsObject
        }
    }

    internal var _shortStandaloneMonthSymbols: [String]? {
        return attributes[AttributeKey.shortStandaloneMonthSymbols] as? [String]
    }
    open var shortStandaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortStandaloneMonthSymbols] = newValue?._nsObject
        }
    }

    internal var _veryShortStandaloneMonthSymbols: [String]? {
        return attributes[AttributeKey.veryShortStandaloneMonthSymbols] as? [String]
    }
    open var veryShortStandaloneMonthSymbols: [String]! {
        get {
            guard let symbols = _veryShortStandaloneMonthSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortStandaloneMonthSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.veryShortStandaloneMonthSymbols] = newValue?._nsObject
        }
    }

    internal var _veryShortWeekdaySymbols: [String]? {
        return attributes[AttributeKey.veryShortWeekdaySymbols] as? [String]
    }
    open var veryShortWeekdaySymbols: [String]! {
        get {
            guard let symbols = _veryShortWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.veryShortWeekdaySymbols] = newValue?._nsObject
        }
    }

    internal var _standaloneWeekdaySymbols: [String]? {
        return attributes[AttributeKey.standaloneWeekdaySymbols] as? [String]
    }
    open var standaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _standaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.standaloneWeekdaySymbols] = newValue?._nsObject
        }
    }

    internal var _shortStandaloneWeekdaySymbols: [String]? {
        return attributes[AttributeKey.shortStandaloneWeekdaySymbols] as? [String]
    }
    open var shortStandaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortStandaloneWeekdaySymbols] = newValue?._nsObject
        }
    }
    
    internal var _veryShortStandaloneWeekdaySymbols: [String]? {
        return attributes[AttributeKey.veryShortStandaloneWeekdaySymbols] as? [String]
    }
    open var veryShortStandaloneWeekdaySymbols: [String]! {
        get {
            guard let symbols = _veryShortStandaloneWeekdaySymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterVeryShortStandaloneWeekdaySymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.veryShortStandaloneWeekdaySymbols] = newValue?._nsObject
        }
    }

    internal var _quarterSymbols: [String]? {
        return attributes[AttributeKey.quarterSymbols] as? [String]
    }
    open var quarterSymbols: [String]! {
        get {
            guard let symbols = _quarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.quarterSymbols] = newValue?._nsObject
        }
    }
    
    internal var _shortQuarterSymbols: [String]? {
        return attributes[AttributeKey.shortQuarterSymbols] as? [String]
    }
    open var shortQuarterSymbols: [String]! {
        get {
            guard let symbols = _shortQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortQuarterSymbols] = newValue?._nsObject
        }
    }

    internal var _standaloneQuarterSymbols: [String]? {
        return attributes[AttributeKey.standaloneQuarterSymbols] as? [String]
    }
    open var standaloneQuarterSymbols: [String]! {
        get {
            guard let symbols = _standaloneQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterStandaloneQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.standaloneQuarterSymbols] = newValue?._nsObject
        }
    }

    internal var _shortStandaloneQuarterSymbols: [String]? {
        return attributes[AttributeKey.shortStandaloneQuarterSymbols] as? [String]
    }
    open var shortStandaloneQuarterSymbols: [String]! {
        get {
            guard let symbols = _shortStandaloneQuarterSymbols else {
                let cfSymbols = CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterShortStandaloneQuarterSymbols) as! NSArray
                return cfSymbols.allObjects as! [String]
            }
            return symbols
        }
        set {
            _reset()
            attributes[AttributeKey.shortStandaloneQuarterSymbols] = newValue?._nsObject
        }
    }

    internal var _gregorianStartDate: Date? {
         return (attributes[AttributeKey.gregorianStartDate] as? NSDate)?._swiftObject
    }
    open var gregorianStartDate: Date? {
        get {
            guard let startDate = _gregorianStartDate else {
                return (CFDateFormatterCopyProperty(_cfObject, kCFDateFormatterGregorianStartDate) as? NSDate)?._swiftObject
            }
            return startDate
        }
        set {
            _reset()
            attributes[AttributeKey.gregorianStartDate] = newValue?._nsObject
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
    internal struct AttributeKey {
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
