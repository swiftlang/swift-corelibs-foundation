// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_exported import FoundationEssentials
@_implementationOnly import _CoreFoundation


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
    internal var _components: DateComponents

    internal init(components: DateComponents) {
        _components = components
    }
    
    public override init() {
        _components = DateComponents()
        super.init()
    }

    open override var hash: Int {
        _components.hashValue
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSDateComponents else { return false }
        return _components == other._components
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
        if let isLeapMonth = _components.isLeapMonth {
            newObj.isLeapMonth = isLeapMonth
        }
        return newObj
    }

    /*@NSCopying*/ open var calendar: Calendar? {
        get {
            _components.calendar
        }
        set {
            _components.calendar = newValue
        }
    }
    
    /*@NSCopying*/ open var timeZone: TimeZone? {
        get {
            _components.timeZone
        }
        set {
            _components.timeZone = newValue
        }
    }

    open var era: Int {
        get {
            _components.era ?? NSDateComponentUndefined
        }
        set {
            _components.era = newValue
        }
    }

    open var year: Int {
        get {
            _components.year ?? NSDateComponentUndefined
        }
        set {
            _components.year = newValue
        }
    }

    open var month: Int {
        get {
            _components.month ?? NSDateComponentUndefined
        }
        set {
            _components.month = newValue
        }
    }

    open var day: Int {
        get {
            _components.day ?? NSDateComponentUndefined
        }
        set {
            _components.day = newValue
        }
    }

    open var hour: Int {
        get {
            _components.hour ?? NSDateComponentUndefined
        }
        set {
            _components.hour = newValue
        }
    }

    open var minute: Int {
        get {
            _components.minute ?? NSDateComponentUndefined
        }
        set {
            _components.minute = newValue
        }
    }

    open var second: Int {
        get {
            _components.second ?? NSDateComponentUndefined
        }
        set {
            _components.second = newValue
        }
    }

    open var weekday: Int {
        get {
            _components.weekday ?? NSDateComponentUndefined
        }
        set {
            _components.weekday = newValue
        }
    }

    open var weekdayOrdinal: Int {
        get {
            _components.weekdayOrdinal ?? NSDateComponentUndefined
        }
        set {
            _components.weekdayOrdinal = newValue
        }
    }

    open var quarter: Int {
        get {
            _components.quarter ?? NSDateComponentUndefined
        }
        set {
            _components.quarter = newValue
        }
    }

    open var nanosecond: Int {
        get {
            _components.nanosecond ?? NSDateComponentUndefined
        }
        set {
            _components.nanosecond = newValue
        }
    }

    open var weekOfYear: Int {
        get {
            _components.weekOfYear ?? NSDateComponentUndefined
        }
        set {
            _components.weekOfYear = newValue
        }
    }

    open var weekOfMonth: Int {
        get {
            _components.weekOfMonth ?? NSDateComponentUndefined
        }
        set {
            _components.weekOfMonth = newValue
        }
    }

    open var yearForWeekOfYear: Int {
        get {
            _components.yearForWeekOfYear ?? NSDateComponentUndefined
        }
        set {
            _components.yearForWeekOfYear = newValue
        }
    }

    open var isLeapMonth: Bool {
        get {
            _components.isLeapMonth ?? false
        }
        set {
            _components.isLeapMonth = newValue
        }
    }

    /*@NSCopying*/ open var date: Date? {
        _components.date
    }

    /*
    This API allows one to set a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth properties cannot be set by this method.
    */
    open func setValue(_ value: Int, forComponent unit: NSCalendar.Unit) {
        _components.setValue(value, for: unit._calendarComponent)
    }

    /*
    This API allows one to get the value of a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth property values cannot be gotten by this method.
    */
    open func value(forComponent unit: NSCalendar.Unit) -> Int {
        _components.value(for: unit._calendarComponent) ?? NSDateComponentUndefined
    }

    /*
    Reports whether or not the combination of properties which have been set in the receiver is a date which exists in the calendar.
    This method is not appropriate for use on NSDateComponents objects which are specifying relative quantities of calendar components.
    Except for some trivial cases (e.g., 'seconds' should be 0 - 59 in any calendar), this method is not necessarily cheap.
    If the time zone property is set in the NSDateComponents object, it is used.
    The calendar property must be set, or NO is returned.
    */
    open var isValidDate: Bool {
        _components.isValidDate
    }

    /*
    Reports whether or not the combination of properties which have been set in the receiver is a date which exists in the calendar.
    This method is not appropriate for use on NSDateComponents objects which are specifying relative quantities of calendar components.
    Except for some trivial cases (e.g., 'seconds' should be 0 - 59 in any calendar), this method is not necessarily cheap.
    If the time zone property is set in the NSDateComponents object, it is used.
    */
    open func isValidDate(in calendar: Calendar) -> Bool {
        _components.isValidDate(in: calendar)
    }
}

// MARK: - Bridging

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
