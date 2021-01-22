// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation


// This is a just used as an extensible struct, basically;
// note that there are two uses: one for specifying a date
// via components (some components may be missing, making the
// specific date ambiguous), and the other for specifying a
// set of component quantities (like, 3 months and 5 hours).
// Undefined fields have (or fields can be set to) the value
// NSDateComponentUndefined.

// NSDateComponents is not responsible for answering questions
// about a date beyond the information it has been initialized
// with; for example, if you initialize one with May 6, 2004,
// and then ask for the weekday, you'll get Undefined, not Thurs.
// A NSDateComponents is meaningless in itself, because you need
// to know what calendar it is interpreted against, and you need
// to know whether the values are absolute values of the units,
// or quantities of the units.
// When you create a new one of these, all values begin Undefined.

public var NSDateComponentUndefined: Int = Int.max

open class NSDateComponents: NSObject, NSCopying, NSSecureCoding {
    internal var _calendar: Calendar?
    internal var _timeZone: TimeZone?
    internal var _values = [Int](repeating: NSDateComponentUndefined, count: 19)
    public override init() {
        super.init()
    }

    open override var hash: Int {
        var hasher = Hasher()
        var mask = 0
        // The list of fields fed to the hasher here must be exactly
        // the same as the ones compared in isEqual(_:) (modulo
        // ordering).
        //
        // Given that NSDateComponents instances usually only have a
        // few fields present, it makes sense to only hash those, as
        // an optimization. We keep track of the fields hashed in the
        // mask value, which we also feed to the hasher to make sure
        // any two unequal values produce different hash encodings.
        //
        // FIXME: Why not just feed _values, calendar & timeZone to
        // the hasher?
        if let calendar = calendar {
            hasher.combine(calendar)
            mask |= 1 << 0
        }
        if let timeZone = timeZone {
            hasher.combine(timeZone)
            mask |= 1 << 1
        }
        if era != NSDateComponentUndefined {
            hasher.combine(era)
            mask |= 1 << 2
        }
        if year != NSDateComponentUndefined {
            hasher.combine(year)
            mask |= 1 << 3
        }
        if quarter != NSDateComponentUndefined {
            hasher.combine(quarter)
            mask |= 1 << 4
        }
        if month != NSDateComponentUndefined {
            hasher.combine(month)
            mask |= 1 << 5
        }
        if day != NSDateComponentUndefined {
            hasher.combine(day)
            mask |= 1 << 6
        }
        if hour != NSDateComponentUndefined {
            hasher.combine(hour)
            mask |= 1 << 7
        }
        if minute != NSDateComponentUndefined {
            hasher.combine(minute)
            mask |= 1 << 8
        }
        if second != NSDateComponentUndefined {
            hasher.combine(second)
            mask |= 1 << 9
        }
        if nanosecond != NSDateComponentUndefined {
            hasher.combine(nanosecond)
            mask |= 1 << 10
        }
        if weekOfYear != NSDateComponentUndefined {
            hasher.combine(weekOfYear)
            mask |= 1 << 11
        }
        if weekOfMonth != NSDateComponentUndefined {
            hasher.combine(weekOfMonth)
            mask |= 1 << 12
        }
        if yearForWeekOfYear != NSDateComponentUndefined {
            hasher.combine(yearForWeekOfYear)
            mask |= 1 << 13
        }
        if weekday != NSDateComponentUndefined {
            hasher.combine(weekday)
            mask |= 1 << 14
        }
        if weekdayOrdinal != NSDateComponentUndefined {
            hasher.combine(weekdayOrdinal)
            mask |= 1 << 15
        }
        hasher.combine(isLeapMonth)
        hasher.combine(mask)
        return hasher.finalize()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSDateComponents else { return false }
        // FIXME: Why not just compare _values, calendar & timeZone?
        return self === other
            || (era == other.era
                && year == other.year
                && quarter == other.quarter
                && month == other.month
                && day == other.day
                && hour == other.hour
                && minute == other.minute
                && second == other.second
                && nanosecond == other.nanosecond
                && weekOfYear == other.weekOfYear
                && weekOfMonth == other.weekOfMonth
                && yearForWeekOfYear == other.yearForWeekOfYear
                && weekday == other.weekday
                && weekdayOrdinal == other.weekdayOrdinal
                && isLeapMonth == other.isLeapMonth
                && calendar == other.calendar
                && timeZone == other.timeZone)
    }

    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }

        self.init()

        self.era = aDecoder.decodeInteger(forKey: "NS.era")
        self.year = aDecoder.decodeInteger(forKey: "NS.year")
        self.quarter = aDecoder.decodeInteger(forKey: "NS.quarter")
        self.month = aDecoder.decodeInteger(forKey: "NS.month")
        self.day = aDecoder.decodeInteger(forKey: "NS.day")
        self.hour = aDecoder.decodeInteger(forKey: "NS.hour")
        self.minute = aDecoder.decodeInteger(forKey: "NS.minute")
        self.second = aDecoder.decodeInteger(forKey: "NS.second")
        self.nanosecond = aDecoder.decodeInteger(forKey: "NS.nanosec")
        self.weekOfYear = aDecoder.decodeInteger(forKey: "NS.weekOfYear")
        self.weekOfMonth = aDecoder.decodeInteger(forKey: "NS.weekOfMonth")
        self.yearForWeekOfYear = aDecoder.decodeInteger(forKey: "NS.yearForWOY")
        self.weekday = aDecoder.decodeInteger(forKey: "NS.weekday")
        self.weekdayOrdinal = aDecoder.decodeInteger(forKey: "NS.weekdayOrdinal")
        self.isLeapMonth = aDecoder.decodeBool(forKey: "NS.isLeapMonth")
        self.calendar = aDecoder.decodeObject(of: NSCalendar.self, forKey: "NS.calendar")?._swiftObject
        self.timeZone = aDecoder.decodeObject(of: NSTimeZone.self, forKey: "NS.timezone")?._swiftObject
    }

    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.era, forKey: "NS.era")
        aCoder.encode(self.year, forKey: "NS.year")
        aCoder.encode(self.quarter, forKey: "NS.quarter")
        aCoder.encode(self.month, forKey: "NS.month")
        aCoder.encode(self.day, forKey: "NS.day")
        aCoder.encode(self.hour, forKey: "NS.hour")
        aCoder.encode(self.minute, forKey: "NS.minute")
        aCoder.encode(self.second, forKey: "NS.second")
        aCoder.encode(self.nanosecond, forKey: "NS.nanosec")
        aCoder.encode(self.weekOfYear, forKey: "NS.weekOfYear")
        aCoder.encode(self.weekOfMonth, forKey: "NS.weekOfMonth")
        aCoder.encode(self.yearForWeekOfYear, forKey: "NS.yearForWOY")
        aCoder.encode(self.weekday, forKey: "NS.weekday")
        aCoder.encode(self.weekdayOrdinal, forKey: "NS.weekdayOrdinal")
        aCoder.encode(self.isLeapMonth, forKey: "NS.isLeapMonth")
        aCoder.encode(self.calendar?._nsObject, forKey: "NS.calendar")
        aCoder.encode(self.timeZone?._nsObject, forKey: "NS.timezone")
    }

    static public var supportsSecureCoding: Bool {
        return true
    }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let newObj = NSDateComponents()
        newObj.calendar = calendar
        newObj.timeZone = timeZone
        newObj.era = era
        newObj.year = year
        newObj.month = month
        newObj.day = day
        newObj.hour = hour
        newObj.minute = minute
        newObj.second = second
        newObj.nanosecond = nanosecond
        newObj.weekOfYear = weekOfYear
        newObj.weekOfMonth = weekOfMonth
        newObj.yearForWeekOfYear = yearForWeekOfYear
        newObj.weekday = weekday
        newObj.weekdayOrdinal = weekdayOrdinal
        newObj.quarter = quarter
        if leapMonthSet {
            newObj.isLeapMonth = isLeapMonth
        }
        return newObj
    }

    /*@NSCopying*/ open var calendar: Calendar? {
        get {
            return _calendar
        }
        set {
            if let val = newValue {
                _calendar = val
            } else {
                _calendar = nil
            }
        }
    }
    /*@NSCopying*/ open var timeZone: TimeZone?

    open var era: Int {
        get {
            return _values[0]
        }
        set {
            _values[0] = newValue
        }
    }

    open var year: Int {
        get {
            return _values[1]
        }
        set {
            _values[1] = newValue
        }
    }

    open var month: Int {
        get {
            return _values[2]
        }
        set {
            _values[2] = newValue
        }
    }

    open var day: Int {
        get {
            return _values[3]
        }
        set {
            _values[3] = newValue
        }
    }

    open var hour: Int {
        get {
            return _values[4]
        }
        set {
            _values[4] = newValue
        }
    }

    open var minute: Int {
        get {
            return _values[5]
        }
        set {
            _values[5] = newValue
        }
    }

    open var second: Int {
        get {
            return _values[6]
        }
        set {
            _values[6] = newValue
        }
    }

    open var weekday: Int {
        get {
            return _values[8]
        }
        set {
            _values[8] = newValue
        }
    }

    open var weekdayOrdinal: Int {
        get {
            return _values[9]
        }
        set {
            _values[9] = newValue
        }
    }

    open var quarter: Int {
        get {
            return _values[10]
        }
        set {
            _values[10] = newValue
        }
    }

    open var nanosecond: Int {
        get {
            return _values[11]
        }
        set {
            _values[11] = newValue
        }
    }

    open var weekOfYear: Int {
        get {
            return _values[12]
        }
        set {
            _values[12] = newValue
        }
    }

    open var weekOfMonth: Int {
        get {
            return _values[13]
        }
        set {
            _values[13] = newValue
        }
    }

    open var yearForWeekOfYear: Int {
        get {
            return _values[14]
        }
        set {
            _values[14] = newValue
        }
    }

    open var isLeapMonth: Bool {
        get {
            return _values[15] == 1
        }
        set {
            _values[15] = newValue ? 1 : 0
        }
    }

    internal var leapMonthSet: Bool {
        return _values[15] != NSDateComponentUndefined
    }

    /*@NSCopying*/ open var date: Date? {
        if let tz = timeZone {
            calendar?.timeZone = tz
        }
        return calendar?.date(from: self._swiftObject)
    }

    /*
    This API allows one to set a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth properties cannot be set by this method.
    */
    open func setValue(_ value: Int, forComponent unit: NSCalendar.Unit) {
        switch unit {
            case .era:
                era = value
            case .year:
                year = value
            case .month:
                month = value
            case .day:
                day = value
            case .hour:
                hour = value
            case .minute:
                minute = value
            case .second:
                second = value
            case .nanosecond:
                nanosecond = value
            case .weekday:
                weekday = value
            case .weekdayOrdinal:
                weekdayOrdinal = value
            case .quarter:
                quarter = value
            case .weekOfMonth:
                weekOfMonth = value
            case .weekOfYear:
                weekOfYear = value
            case .yearForWeekOfYear:
                yearForWeekOfYear = value
            case .calendar:
                print(".Calendar cannot be set via \(#function)")
            case .timeZone:
                print(".TimeZone cannot be set via \(#function)")
            default:
                break
        }
    }

    /*
    This API allows one to get the value of a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth property values cannot be gotten by this method.
    */
    open func value(forComponent unit: NSCalendar.Unit) -> Int {
        switch unit {
            case .era:
                return era
            case .year:
                return year
            case .month:
                return month
            case .day:
                return day
            case .hour:
                return hour
            case .minute:
                return minute
            case .second:
                return second
            case .nanosecond:
                return nanosecond
            case .weekday:
                return weekday
            case .weekdayOrdinal:
                return weekdayOrdinal
            case .quarter:
                return quarter
            case .weekOfMonth:
                return weekOfMonth
            case .weekOfYear:
                return weekOfYear
            case .yearForWeekOfYear:
                return yearForWeekOfYear
            default:
                break
        }
        return NSDateComponentUndefined
    }

    /*
    Reports whether or not the combination of properties which have been set in the receiver is a date which exists in the calendar.
    This method is not appropriate for use on NSDateComponents objects which are specifying relative quantities of calendar components.
    Except for some trivial cases (e.g., 'seconds' should be 0 - 59 in any calendar), this method is not necessarily cheap.
    If the time zone property is set in the NSDateComponents object, it is used.
    The calendar property must be set, or NO is returned.
    */
    open var isValidDate: Bool {
        if let cal = calendar {
            return isValidDate(in: cal)
        }
        return false
    }

    /*
    Reports whether or not the combination of properties which have been set in the receiver is a date which exists in the calendar.
    This method is not appropriate for use on NSDateComponents objects which are specifying relative quantities of calendar components.
    Except for some trivial cases (e.g., 'seconds' should be 0 - 59 in any calendar), this method is not necessarily cheap.
    If the time zone property is set in the NSDateComponents object, it is used.
    */
    open func isValidDate(in calendar: Calendar) -> Bool {
        var cal = calendar
        if let tz = timeZone {
            cal.timeZone = tz
        }
        let ns = nanosecond
        if ns != NSDateComponentUndefined && 1000 * 1000 * 1000 <= ns {
            return false
        }
        if ns != NSDateComponentUndefined && 0 < ns {
            nanosecond = 0
        }
        let d = calendar.date(from: self._swiftObject)
        if ns != NSDateComponentUndefined && 0 < ns {
            nanosecond = ns
        }
        if let date = d {
            let all: NSCalendar.Unit = [.era, .year, .month, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear]
            let comps = cal._bridgeToObjectiveC().components(all, from: date)
            var val = era
            if val != NSDateComponentUndefined {
                if comps.era != val {
                    return false
                }
            }
            val = year
            if val != NSDateComponentUndefined {
                if comps.year != val {
                    return false
                }
            }
            val = month
            if val != NSDateComponentUndefined {
                if comps.month != val {
                    return false
                }
            }
            if leapMonthSet {
                if comps.isLeapMonth != isLeapMonth {
                    return false
                }
            }
            val = day
            if val != NSDateComponentUndefined {
                if comps.day != val {
                    return false
                }
            }
            val = hour
            if val != NSDateComponentUndefined {
                if comps.hour != val {
                    return false
                }
            }
            val = minute
            if val != NSDateComponentUndefined {
                if comps.minute != val {
                    return false
                }
            }
            val = second
            if val != NSDateComponentUndefined {
                if comps.second != val {
                    return false
                }
            }
            val = weekday
            if val != NSDateComponentUndefined {
                if comps.weekday != val {
                    return false
                }
            }
            val = weekdayOrdinal
            if val != NSDateComponentUndefined {
                if comps.weekdayOrdinal != val {
                    return false
                }
            }
            val = quarter
            if val != NSDateComponentUndefined {
                if comps.quarter != val {
                    return false
                }
            }
            val = weekOfMonth
            if val != NSDateComponentUndefined {
                if comps.weekOfMonth != val {
                    return false
                }
            }
            val = weekOfYear
            if val != NSDateComponentUndefined {
                if comps.weekOfYear != val {
                    return false
                }
            }
            val = yearForWeekOfYear
            if val != NSDateComponentUndefined {
                if comps.yearForWeekOfYear != val {
                    return false
                }
            }

            return true
        }
        return false
    }
}

extension NSDateComponents: _SwiftBridgeable {
    typealias SwiftType = DateComponents
    var _swiftObject: SwiftType { return DateComponents(reference: self) }
}

extension NSDateComponents: _StructTypeBridgeable {
    public typealias _StructType = DateComponents

    public func _bridgeToSwift() -> DateComponents {
        return DateComponents._unconditionallyBridgeFromObjectiveC(self)
    }
}

extension NSDateComponents {
    func _createCFDateComponents() -> CFDateComponents {
        let components = CFDateComponentsCreate(kCFAllocatorSystemDefault)!
        CFDateComponentsSetValue(components, kCFCalendarUnitEra, era)
        CFDateComponentsSetValue(components, kCFCalendarUnitYear, year)
        CFDateComponentsSetValue(components, kCFCalendarUnitMonth, month)
        CFDateComponentsSetValue(components, kCFCalendarUnitDay, day)
        CFDateComponentsSetValue(components, kCFCalendarUnitHour, hour)
        CFDateComponentsSetValue(components, kCFCalendarUnitMinute, minute)
        CFDateComponentsSetValue(components, kCFCalendarUnitSecond, second)
        CFDateComponentsSetValue(components, kCFCalendarUnitWeekday, weekday)
        CFDateComponentsSetValue(components, kCFCalendarUnitWeekdayOrdinal, weekdayOrdinal)
        CFDateComponentsSetValue(components, kCFCalendarUnitQuarter, quarter)
        CFDateComponentsSetValue(components, kCFCalendarUnitWeekOfMonth, weekOfMonth)
        CFDateComponentsSetValue(components, kCFCalendarUnitWeekOfYear, weekOfYear)
        CFDateComponentsSetValue(components, kCFCalendarUnitYearForWeekOfYear, yearForWeekOfYear)
        CFDateComponentsSetValue(components, kCFCalendarUnitNanosecond, nanosecond)
        return components
    }
}
