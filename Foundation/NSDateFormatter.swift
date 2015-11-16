// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class NSDateFormatter : NSFormatter {
    typealias CFType = CFDateFormatterRef
    internal var __cfObject: CFType?
    internal var _cfObject: CFType {
        get {
            if let obj = __cfObject {
                return obj
            } else {
#if os(OSX) || os(iOS)
                let dateStyle = CFDateFormatterStyle(rawValue: CFIndex(self.dateStyle.rawValue))!
                let timeStyle = CFDateFormatterStyle(rawValue: CFIndex(self.timeStyle.rawValue))!
#else
                let dateStyle = CFDateFormatterStyle(self.dateStyle.rawValue)
                let timeStyle = CFDateFormatterStyle(self.timeStyle.rawValue)
#endif
                let obj = CFDateFormatterCreate(kCFAllocatorSystemDefault, locale._cfObject, dateStyle, timeStyle)
                // TODO: Set up attributes here
                __cfObject = obj
                return obj
            }
        }
    }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var formattingContext: NSFormattingContext = .Unknown

    public func objectValue(string: String, range rangep: UnsafeMutablePointer<NSRange>) throws -> AnyObject? { NSUnimplemented() }
    
    public override func stringForObjectValue(obj: AnyObject) -> String? {
        if let date = obj as? NSDate {
            return stringFromDate(date)
        }
        return nil
    }
    
    public func stringFromDate(date: NSDate) -> String {
        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, _cfObject, date._cfObject)._swiftObject
    }
    
    public func dateFromString(string: String) -> NSDate? {
        var range = CFRange()
        let date = withUnsafeMutablePointer(&range) { (rangep: UnsafeMutablePointer<CFRange>) -> NSDate? in
            if let res = CFDateFormatterCreateDateFromString(kCFAllocatorSystemDefault, _cfObject, string._cfObject, rangep) {
                return res._nsObject
            }
            return nil
        }
        return date
    }

    public class func localizedStringFromDate(date: NSDate, dateStyle dstyle: NSDateFormatterStyle, timeStyle tstyle: NSDateFormatterStyle) -> String {
        let df = NSDateFormatter()
        df.dateStyle = dstyle
        df.timeStyle = tstyle
        return df.stringForObjectValue(date)!

    }
    
    public class func dateFormatFromTemplate(tmplate: String, options opts: Int, locale: NSLocale?) -> String? {
        if let res = CFDateFormatterCreateDateFormatFromTemplate(kCFAllocatorSystemDefault, tmplate._cfObject, CFOptionFlags(opts), locale?._cfObject) {
            return res._swiftObject
        } else {
            return nil
        }
    }
    
    public func setLocalizedDateFormatFromTemplate(dateFormatTemplate: String) {
        NSUnimplemented()
    }
    
    internal func _reset() {
        __cfObject = nil
    }
    
    internal var _dateFormat: String?
    public var dateFormat: String! {
        get {
            if let format = _dateFormat {
                return format
            } else {
                if let obj = __cfObject {
                    return CFDateFormatterGetFormat(obj)._swiftObject
                } else {
                    return ""
                }
            }
        }
        set {
            _reset()
            _dateFormat = newValue
        }
    }
    
    internal var _dateStyle: NSDateFormatterStyle = .NoStyle
    public var dateStyle: NSDateFormatterStyle {
        get {
            return _dateStyle
        }
        set {
            _reset()
            _dateStyle = newValue
        }
    }
    
    internal var _timeStyle: NSDateFormatterStyle = .NoStyle
    public var timeStyle: NSDateFormatterStyle {
        get {
            return _timeStyle
        }
        set {
            _reset()
            _timeStyle = newValue
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
    
    internal var _generatesCalendarDates: Bool = false
    public var generatesCalendarDates: Bool {
        get {
            return _generatesCalendarDates
        }
        set {
            _reset()
            _generatesCalendarDates = newValue
        }
    }
    
    internal var _timeZone: NSTimeZone = NSTimeZone.systemTimeZone()
    /*@NSCopying*/ public var timeZone: NSTimeZone! {
        get {
            return _timeZone
        }
        set {
            _reset()
            _timeZone = newValue
        }
    }
    
    internal var _calendar: NSCalendar!
    /*@NSCopying*/ public var calendar: NSCalendar! {
        get {
            return _calendar
        }
        set {
            _reset()
            _calendar = newValue
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
    
    internal var _twoDigitStartDate: NSDate?
    /*@NSCopying*/ public var twoDigitStartDate: NSDate? {
        get {
            return _twoDigitStartDate
        }
        set {
            _reset()
            _twoDigitStartDate = newValue
        }
    }
    
    internal var _defaultDate: NSDate?
    /*@NSCopying*/ public var defaultDate: NSDate? {
        get {
            return _defaultDate
        }
        set {
            _reset()
            _defaultDate = newValue
        }
    }
    
    internal var _eraSymbols: [String]!
    public var eraSymbols: [String]! {
        get {
            return _eraSymbols
        }
        set {
            _reset()
            _eraSymbols = newValue
        }
    }
    
    internal var _monthSymbols: [String]!
    public var monthSymbols: [String]! {
        get {
            return _monthSymbols
        }
        set {
            _reset()
            _monthSymbols = newValue
        }
    }
    
    internal var _shortMonthSymbols: [String]!
    public var shortMonthSymbols: [String]! {
        get {
            return _shortMonthSymbols
        }
        set {
            _reset()
            _shortMonthSymbols = newValue
        }
    }
    
    internal var _weekdaySymbols: [String]!
    public var weekdaySymbols: [String]! {
        get {
            return _weekdaySymbols
        }
        set {
            _reset()
            _weekdaySymbols = newValue
        }
    }
    
    internal var _shortWeekdaySymbols: [String]!
    public var shortWeekdaySymbols: [String]! {
        get {
            return _shortWeekdaySymbols
        }
        set {
            _reset()
            _shortWeekdaySymbols = newValue
        }
    }
    
    internal var _AMSymbol: String!
    public var AMSymbol: String! {
        get {
            return _AMSymbol
        }
        set {
            _reset()
            _AMSymbol = newValue
        }
    }
    
    internal var _PMSymbol: String!
    public var PMSymbol: String! {
        get {
            return _PMSymbol
        }
        set {
            _reset()
            _PMSymbol = newValue
        }
    }
    
    internal var _longEraSymbols: [String]!
    public var longEraSymbols: [String]! {
        get {
            return _longEraSymbols
        }
        set {
            _reset()
            _longEraSymbols = newValue
        }
    }
    
    internal var _veryShortMonthSymbols: [String]!
    public var veryShortMonthSymbols: [String]! {
        get {
            return _veryShortMonthSymbols
        }
        set {
            _reset()
            _veryShortMonthSymbols = newValue
        }
    }
    
    internal var _standaloneMonthSymbols: [String]!
    public var standaloneMonthSymbols: [String]! {
        get {
            return _standaloneMonthSymbols
        }
        set {
            _reset()
            _standaloneMonthSymbols = newValue
        }
    }
    
    internal var _shortStandaloneMonthSymbols: [String]!
    public var shortStandaloneMonthSymbols: [String]! {
        get {
            return _shortStandaloneMonthSymbols
        }
        set {
            _reset()
            _shortStandaloneMonthSymbols = newValue
        }
    }
    
    internal var _veryShortStandaloneMonthSymbols: [String]!
    public var veryShortStandaloneMonthSymbols: [String]! {
        get {
            return _veryShortStandaloneMonthSymbols
        }
        set {
            _reset()
            _veryShortStandaloneMonthSymbols = newValue
        }
    }
    
    internal var _veryShortWeekdaySymbols: [String]!
    public var veryShortWeekdaySymbols: [String]! {
        get {
            return _veryShortWeekdaySymbols
        }
        set {
            _reset()
            _veryShortWeekdaySymbols = newValue
        }
    }
    
    internal var _standaloneWeekdaySymbols: [String]!
    public var standaloneWeekdaySymbols: [String]! {
        get {
            return _standaloneWeekdaySymbols
        }
        set {
            _reset()
            _standaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _shortStandaloneWeekdaySymbols: [String]!
    public var shortStandaloneWeekdaySymbols: [String]! {
        get {
            return _shortStandaloneWeekdaySymbols
        }
        set {
            _reset()
            _shortStandaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _veryShortStandaloneWeekdaySymbols: [String]!
    public var veryShortStandaloneWeekdaySymbols: [String]! {
        get {
            return _veryShortStandaloneWeekdaySymbols
        }
        set {
            _reset()
            _veryShortStandaloneWeekdaySymbols = newValue
        }
    }
    
    internal var _quarterSymbols: [String]!
    public var quarterSymbols: [String]! {
        get {
            return _quarterSymbols
        }
        set {
            _reset()
            _quarterSymbols = newValue
        }
    }
    
    internal var _shortQuarterSymbols: [String]!
    public var shortQuarterSymbols: [String]! {
        get {
            return _shortQuarterSymbols
        }
        set {
            _reset()
            _shortQuarterSymbols = newValue
        }
    }
    
    internal var _standaloneQuarterSymbols: [String]!
    public var standaloneQuarterSymbols: [String]! {
        get {
            return _standaloneQuarterSymbols
        }
        set {
            _reset()
            _standaloneQuarterSymbols = newValue
        }
    }
    
    internal var _shortStandaloneQuarterSymbols: [String]!
    public var shortStandaloneQuarterSymbols: [String]! {
        get {
            return _shortStandaloneQuarterSymbols
        }
        set {
            _reset()
            _shortStandaloneQuarterSymbols = newValue
        }
    }
    
    internal var _gregorianStartDate: NSDate?
    public var gregorianStartDate: NSDate? {
        get {
            return _gregorianStartDate
        }
        set {
            _reset()
            _gregorianStartDate = newValue
        }
    }
    
    internal var _doesRelativeDateFormatting: Bool = false
    public var doesRelativeDateFormatting: Bool {
        get {
            return _doesRelativeDateFormatting
        }
        set {
            _reset()
            _doesRelativeDateFormatting = newValue
        }
    }
}

public enum NSDateFormatterStyle : UInt {
    case NoStyle
    case ShortStyle
    case MediumStyle
    case LongStyle
    case FullStyle
}

