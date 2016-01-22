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
    private var __cfObject: CFType?
    private var _cfObject: CFType {
        guard let obj = __cfObject else {
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
        return obj
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
        guard let date = obj as? NSDate else { return nil }
        return stringFromDate(date)
    }

    public func stringFromDate(date: NSDate) -> String {
        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, _cfObject, date._cfObject)._swiftObject
    }

    public func dateFromString(string: String) -> NSDate? {
        var range = CFRange()
        let date = withUnsafeMutablePointer(&range) { (rangep: UnsafeMutablePointer<CFRange>) -> NSDate? in
            guard let res = CFDateFormatterCreateDateFromString(kCFAllocatorSystemDefault, _cfObject, string._cfObject, rangep) else {
                return nil
            }
            return res._nsObject
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
        guard let res = CFDateFormatterCreateDateFormatFromTemplate(kCFAllocatorSystemDefault, tmplate._cfObject, CFOptionFlags(opts), locale?._cfObject) else {
            return nil
        }
        return res._swiftObject
    }

    public func setLocalizedDateFormatFromTemplate(dateFormatTemplate: String) {
        NSUnimplemented()
    }

    private func _reset() {
        __cfObject = nil
    }

    public var dateFormat: String! {
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
    private var _dateFormat: String? { willSet { _reset() } }

    public var dateStyle: NSDateFormatterStyle = .NoStyle { willSet { _reset() } }

    public var timeStyle: NSDateFormatterStyle = .NoStyle { willSet { _reset() } }

    /*@NSCopying*/ public var locale: NSLocale! { willSet { _reset() } }

    public var generatesCalendarDates = false { willSet { _reset() } }

    /*@NSCopying*/ public var timeZone: NSTimeZone! = .systemTimeZone() { willSet { _reset() } }

    /*@NSCopying*/ public var calendar: NSCalendar! { willSet { _reset() } }

    public var lenient = false { willSet { _reset() } }

    /*@NSCopying*/ public var twoDigitStartDate: NSDate? { willSet { _reset() } }

    /*@NSCopying*/ public var defaultDate: NSDate? { willSet { _reset() } }

    public var eraSymbols: [String]! { willSet { _reset() } }

    public var monthSymbols: [String]! { willSet { _reset() } }

    public var shortMonthSymbols: [String]! { willSet { _reset() } }

    public var weekdaySymbols: [String]! { willSet { _reset() } }

    public var shortWeekdaySymbols: [String]! { willSet { _reset() } }

    public var AMSymbol: String! { willSet { _reset() } }

    public var PMSymbol: String! { willSet { _reset() } }

    public var longEraSymbols: [String]! { willSet { _reset() } }

    public var veryShortMonthSymbols: [String]! { willSet { _reset() } }

    public var standaloneMonthSymbols: [String]! { willSet { _reset() } }

    public var shortStandaloneMonthSymbols: [String]! { willSet { _reset() } }

    public var veryShortStandaloneMonthSymbols: [String]! { willSet { _reset() } }

    public var veryShortWeekdaySymbols: [String]! { willSet { _reset() } }

    public var standaloneWeekdaySymbols: [String]! { willSet { _reset() } }

    public var shortStandaloneWeekdaySymbols: [String]! { willSet { _reset() } }

    public var veryShortStandaloneWeekdaySymbols: [String]! { willSet { _reset() } }

    public var quarterSymbols: [String]! { willSet { _reset() } }

    public var shortQuarterSymbols: [String]! { willSet { _reset() } }

    public var standaloneQuarterSymbols: [String]! { willSet { _reset() } }

    public var shortStandaloneQuarterSymbols: [String]! { willSet { _reset() } }

    public var gregorianStartDate: NSDate? { willSet { _reset() } }

    public var doesRelativeDateFormatting = false { willSet { _reset() } }
}

public enum NSDateFormatterStyle : UInt {
    case NoStyle
    case ShortStyle
    case MediumStyle
    case LongStyle
    case FullStyle
}
