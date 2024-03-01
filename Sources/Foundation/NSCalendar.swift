// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import _CoreFoundation
@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials

internal let kCFCalendarUnitEra = CFCalendarUnit.era
internal let kCFCalendarUnitYear = CFCalendarUnit.year
internal let kCFCalendarUnitMonth = CFCalendarUnit.month
internal let kCFCalendarUnitDay = CFCalendarUnit.day
internal let kCFCalendarUnitHour = CFCalendarUnit.hour
internal let kCFCalendarUnitMinute = CFCalendarUnit.minute
internal let kCFCalendarUnitSecond = CFCalendarUnit.second
internal let kCFCalendarUnitWeekday = CFCalendarUnit.weekday
internal let kCFCalendarUnitWeekdayOrdinal = CFCalendarUnit.weekdayOrdinal
internal let kCFCalendarUnitQuarter = CFCalendarUnit.quarter
internal let kCFCalendarUnitWeekOfMonth = CFCalendarUnit.weekOfMonth
internal let kCFCalendarUnitWeekOfYear = CFCalendarUnit.weekOfYear
internal let kCFCalendarUnitYearForWeekOfYear = CFCalendarUnit.yearForWeekOfYear
internal let kCFCalendarUnitNanosecond = CFCalendarUnit(rawValue: CFOptionFlags(_CoreFoundation.kCFCalendarUnitNanosecond))

internal func _CFCalendarUnitRawValue(_ unit: CFCalendarUnit) -> CFOptionFlags {
    return unit.rawValue
}

extension NSCalendar {
    // This is not the same as Calendar.Identifier due to a spelling difference in ISO8601
    public struct Identifier : RawRepresentable, Equatable, Hashable, Comparable {
        public private(set) var rawValue: String
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        init(_ id: Calendar.Identifier) {
            switch id {
            case .gregorian: self = .gregorian
            case .buddhist: self = .buddhist
            case .chinese: self = .chinese
            case .coptic: self = .coptic
            case .ethiopicAmeteMihret: self = .ethiopicAmeteMihret
            case .ethiopicAmeteAlem: self = .ethiopicAmeteAlem
            case .hebrew: self = .hebrew
            case .iso8601: self = .ISO8601
            case .indian: self = .indian
            case .islamic: self = .islamic
            case .islamicCivil: self = .islamicCivil
            case .japanese: self = .japanese
            case .persian: self = .persian
            case .republicOfChina: self = .republicOfChina
            case .islamicTabular: self = .islamicTabular
            case .islamicUmmAlQura: self = .islamicUmmAlQura
            }
        }
        
        init?(string: String) {
            switch string {
                case "gregorian": self = .gregorian
                case "buddhist": self = .buddhist
                case "chinese": self = .chinese
                case "coptic": self = .coptic
                case "ethiopic": self = .ethiopicAmeteMihret
                case "ethiopic-amete-alem": self = .ethiopicAmeteAlem
                case "hebrew": self = .hebrew
                case "iso8601": self = .ISO8601
                case "indian": self = .indian
                case "islamic": self = .islamic
                case "islamic-civil": self = .islamicCivil
                case "japanese": self = .japanese
                case "persian": self = .persian
                case "roc": self = .republicOfChina
                case "islamic-tbla": self = .islamicTabular
                case "islamic-umalqura": self = .islamicUmmAlQura
                default: return nil
            }
        }

        public static let gregorian = NSCalendar.Identifier("gregorian")
        public static let buddhist = NSCalendar.Identifier("buddhist")
        public static let chinese = NSCalendar.Identifier("chinese")
        public static let coptic = NSCalendar.Identifier("coptic")
        public static let ethiopicAmeteMihret = NSCalendar.Identifier("ethiopic")
        public static let ethiopicAmeteAlem = NSCalendar.Identifier("ethiopic-amete-alem")
        public static let hebrew = NSCalendar.Identifier("hebrew")
        public static let ISO8601 = NSCalendar.Identifier("iso8601")
        public static let indian = NSCalendar.Identifier("indian")
        public static let islamic = NSCalendar.Identifier("islamic")
        public static let islamicCivil = NSCalendar.Identifier("islamic-civil")
        public static let japanese = NSCalendar.Identifier("japanese")
        public static let persian = NSCalendar.Identifier("persian")
        public static let republicOfChina = NSCalendar.Identifier("roc")
        public static let islamicTabular = NSCalendar.Identifier("islamic-tbla")
        public static let islamicUmmAlQura = NSCalendar.Identifier("islamic-umalqura")
        
        var _calendarIdentifier: Calendar.Identifier? {
            switch self {
            case .gregorian: .gregorian
            case .buddhist: .buddhist
            case .chinese: .chinese
            case .coptic: .coptic
            case .ethiopicAmeteMihret: .ethiopicAmeteMihret
            case .ethiopicAmeteAlem: .ethiopicAmeteAlem
            case .hebrew: .hebrew
            case .ISO8601: .iso8601
            case .indian: .indian
            case .islamic: .islamic
            case .islamicCivil: .islamicCivil
            case .japanese: .japanese
            case .persian: .persian
            case .republicOfChina: .republicOfChina
            case .islamicTabular: .islamicTabular
            case .islamicUmmAlQura: .islamicUmmAlQura
            default: nil
            }
        }
    }

    
    public struct Unit: OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let era = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitEra))
        public static let year = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitYear))
        public static let month = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitMonth))
        public static let day = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitDay))
        public static let hour = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitHour))
        public static let minute = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitMinute))
        public static let second = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitSecond))
        public static let weekday = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitWeekday))
        public static let weekdayOrdinal = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitWeekdayOrdinal))
        public static let quarter = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitQuarter))
        public static let weekOfMonth = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitWeekOfMonth))
        public static let weekOfYear = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitWeekOfYear))
        public static let yearForWeekOfYear = Unit(rawValue: _CFCalendarUnitRawValue(kCFCalendarUnitYearForWeekOfYear))

        public static let nanosecond = Unit(rawValue: UInt(1 << 15))
        public static let calendar = Unit(rawValue: UInt(1 << 20))
        public static let timeZone = Unit(rawValue: UInt(1 << 21))

        internal var _cfValue: CFCalendarUnit {
            return CFCalendarUnit(rawValue: self.rawValue)
        }
        
        internal var _calendarComponent: Calendar.Component {
            switch self {
            case .era: .era
            case .year: .year
            case .month: .month
            case .day: .day
            case .hour: .hour
            case .minute: .minute
            case .second: .second
            case .weekday: .weekday
            case .weekdayOrdinal: .weekdayOrdinal
            case .quarter: .quarter
            case .weekOfMonth: .weekOfMonth
            case .weekOfYear: .weekOfYear
            case .yearForWeekOfYear: .yearForWeekOfYear
            case .calendar: .calendar
            case .timeZone: .timeZone
            case .nanosecond: .nanosecond
            default: fatalError("Unknown component \(self)")
            }
        }
        
        internal var _calendarComponents: Set<Calendar.Component> {
            var result = Set<Calendar.Component>()
            if self.contains(.era) { result.insert(.era) }
            if self.contains(.year) { result.insert(.year) }
            if self.contains(.month) { result.insert(.month) }
            if self.contains(.day) { result.insert(.day) }
            if self.contains(.hour) { result.insert(.hour) }
            if self.contains(.minute) { result.insert(.minute) }
            if self.contains(.second) { result.insert(.second) }
            if self.contains(.weekday) { result.insert(.weekday) }
            if self.contains(.weekdayOrdinal) { result.insert(.weekdayOrdinal) }
            if self.contains(.quarter) { result.insert(.quarter) }
            if self.contains(.weekOfMonth) { result.insert(.weekOfMonth) }
            if self.contains(.weekOfYear) { result.insert(.weekOfYear) }
            if self.contains(.yearForWeekOfYear) { result.insert(.yearForWeekOfYear) }
            if self.contains(.nanosecond) { result.insert(.nanosecond) }
            if self.contains(.calendar) { result.insert(.calendar) }
            if self.contains(.timeZone) { result.insert(.timeZone) }
            return result
        }

    }

    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let wrapComponents = Options(rawValue: 1 << 0)
        public static let matchStrictly = Options(rawValue: 1 << 1)
        public static let searchBackwards = Options(rawValue: 1 << 2)
        public static let matchPreviousTimePreservingSmallerUnits = Options(rawValue: 1 << 8)
        public static let matchNextTimePreservingSmallerUnits = Options(rawValue: 1 << 9)
        public static let matchNextTime = Options(rawValue: 1 << 10)
        public static let matchFirst = Options(rawValue: 1 << 12)
        public static let matchLast = Options(rawValue: 1 << 13)
    }
}

extension NSCalendar.Identifier {
    public static func <(_ lhs: NSCalendar.Identifier, _ rhs: NSCalendar.Identifier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

open class NSCalendar : NSObject, NSCopying, NSSecureCoding {
    var _calendar: Calendar
    
    internal init(calendar: Calendar) {
        _calendar = calendar
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard let calendarIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "NS.identifier") else {
            return nil
        }

        guard let id = Identifier(string: calendarIdentifier._swiftObject) else {
            return nil
        }
        self.init(identifier: id)

        if aDecoder.containsValue(forKey: "NS.timezone") {
            if let timeZone = aDecoder.decodeObject(of: NSTimeZone.self, forKey: "NS.timezone") {
                self.timeZone = timeZone._swiftObject
            }
        }
        if aDecoder.containsValue(forKey: "NS.locale") {
            if let locale = aDecoder.decodeObject(of: NSLocale.self, forKey: "NS.locale") {
                self.locale = locale._swiftObject
            }
        }
        self.firstWeekday = aDecoder.decodeInteger(forKey: "NS.firstwkdy")
        self.minimumDaysInFirstWeek = aDecoder.decodeInteger(forKey: "NS.mindays")
        
        if aDecoder.containsValue(forKey: "NS.gstartdate") {
            if let startDate = aDecoder.decodeObject(of: NSDate.self, forKey: "NS.gstartdate") {
                self.gregorianStartDate = startDate._swiftObject
            }
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.calendarIdentifier.rawValue._bridgeToObjectiveC(), forKey: "NS.identifier")
        aCoder.encode(self.timeZone._nsObject, forKey: "NS.timezone")
        aCoder.encode(self.locale?._bridgeToObjectiveC(), forKey: "NS.locale")
        aCoder.encode(self.firstWeekday, forKey: "NS.firstwkdy")
        aCoder.encode(self.minimumDaysInFirstWeek, forKey: "NS.mindays")
        aCoder.encode(self.gregorianStartDate?._nsObject, forKey: "NS.gstartdate")
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = NSCalendar(identifier: calendarIdentifier)!
        copy.locale = locale
        copy.timeZone = timeZone
        copy.firstWeekday = firstWeekday
        copy.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        copy.gregorianStartDate = gregorianStartDate
        return copy
    }
    

    open class var current: Calendar {
        return Calendar.current
    }
    
    open class var autoupdatingCurrent: Calendar {
        // swift-corelibs-foundation does not yet support autoupdating, but we can return the current calendar (which will not change).
        return Calendar.autoupdatingCurrent
    }
    
    public /*not inherited*/ init?(identifier calendarIdentifierConstant: Identifier) {
        guard let id = calendarIdentifierConstant._calendarIdentifier else {
            return nil
        }
        _calendar = Calendar(identifier: id)
        super.init()
    }
    
    public init?(calendarIdentifier ident: Identifier) {
        guard let id = ident._calendarIdentifier else {
            return nil
        }
        _calendar = Calendar(identifier: id)
        super.init()
    }
    
    open override var hash: Int {
        _calendar.hashValue
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        if let value = value, self === value as AnyObject {
            return true
        }
        
        guard let calendar = value as? NSCalendar else { return false }
        
        return _calendar == calendar._calendar
    }
    
    open override var description: String {
        _calendar.description
    }

    open var calendarIdentifier: Identifier  {
        Identifier(_calendar.identifier)
    }
    
    open var locale: Locale? {
        get {
            _calendar.locale
        }
        set {
            _calendar.locale = newValue
        }
    }
    open var timeZone: TimeZone {
        get {
            _calendar.timeZone
        }
        set {
            _calendar.timeZone = newValue
        }
    }
    
    open var firstWeekday: Int {
        get {
            _calendar.firstWeekday
        }
        set {
            _calendar.firstWeekday = newValue
        }
    }
    
    open var minimumDaysInFirstWeek: Int {
        get {
            _calendar.minimumDaysInFirstWeek
        }
        set {
            _calendar.minimumDaysInFirstWeek = newValue
        }
    }
    
    internal var gregorianStartDate: Date? {
        get {
            return CFCalendarCopyGregorianStartDate(_cfObject)?._swiftObject
        }
        set {
            let date = newValue as NSDate?
            CFCalendarSetGregorianStartDate(_cfObject, date?._cfObject)
        }
    }
    
    open var eraSymbols: [String] {
        return _calendar.eraSymbols
    }
    
    open var longEraSymbols: [String] {
        _calendar.longEraSymbols
    }
    
    open var monthSymbols: [String] {
        _calendar.monthSymbols
    }
    
    open var shortMonthSymbols: [String] {
        _calendar.shortMonthSymbols
    }
    
    open var veryShortMonthSymbols: [String] {
        _calendar.veryShortMonthSymbols
    }
    
    open var standaloneMonthSymbols: [String] {
        _calendar.standaloneMonthSymbols
    }
    
    open var shortStandaloneMonthSymbols: [String] {
        _calendar.shortStandaloneMonthSymbols
    }
    
    open var veryShortStandaloneMonthSymbols: [String] {
        _calendar.veryShortStandaloneMonthSymbols
    }
    
    open var weekdaySymbols: [String] {
        _calendar.weekdaySymbols
    }
    
    open var shortWeekdaySymbols: [String] {
        _calendar.shortWeekdaySymbols
    }
    
    open var veryShortWeekdaySymbols: [String] {
        _calendar.veryShortWeekdaySymbols
    }
    
    open var standaloneWeekdaySymbols: [String] {
        _calendar.standaloneWeekdaySymbols
    }
    
    open var shortStandaloneWeekdaySymbols: [String] {
        _calendar.shortStandaloneWeekdaySymbols
    }

    open var veryShortStandaloneWeekdaySymbols: [String] {
        _calendar.veryShortStandaloneWeekdaySymbols
    }
    
    open var quarterSymbols: [String] {
        _calendar.quarterSymbols
    }
    
    open var shortQuarterSymbols: [String] {
        _calendar.shortQuarterSymbols
    }
    
    open var standaloneQuarterSymbols: [String] {
        _calendar.standaloneQuarterSymbols
    }
    
    open var shortStandaloneQuarterSymbols: [String] {
        _calendar.shortStandaloneQuarterSymbols
    }
    
    open var amSymbol: String {
        _calendar.amSymbol
    }
    
    open var pmSymbol: String {
        _calendar.pmSymbol
    }
    
    // Calendrical calculations
    
    open func minimumRange(of unit: Unit) -> NSRange {
        _toNSRange(_calendar.minimumRange(of: unit._calendarComponent))
    }
    
    open func maximumRange(of unit: Unit) -> NSRange {
        _toNSRange(_calendar.maximumRange(of: unit._calendarComponent))
    }
    
    open func range(of smaller: Unit, in larger: Unit, for date: Date) -> NSRange {
        _toNSRange(_calendar.range(of: smaller._calendarComponent, in: larger._calendarComponent, for: date))
    }
    
    open func ordinality(of smaller: Unit, in larger: Unit, for date: Date) -> Int {
        _calendar.ordinality(of: smaller._calendarComponent, in: larger._calendarComponent, for: date) ?? NSNotFound
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// open func rangeOfUnit(_ unit: Unit, startDate datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, forDate date: NSDate) -> Bool
    /// which is not implementable on Linux due to the lack of being able to properly implement AutoreleasingUnsafeMutablePointer.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func range(of unit: Unit, for date: Date) -> DateInterval? {
        _calendar.dateInterval(of: unit._calendarComponent, for: date)
    }
        
    open func date(from comps: DateComponents) -> Date? {
        _calendar.date(from: comps)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// The Darwin version is not nullable but this one is since the conversion from the date and unit flags can potentially return nil
    open func components(_ unitFlags: Unit, from date: Date) -> DateComponents {
        _calendar.dateComponents(unitFlags._calendarComponents, from: date)
    }
    
    open func date(byAdding comps: DateComponents, to date: Date, options opts: Options = []) -> Date? {
        _calendar.date(byAdding: comps, to: date, wrappingComponents: opts.contains(.wrapComponents))
    }
    
    open func components(_ unitFlags: Unit, from startingDate: Date, to resultDate: Date, options opts: Options = []) -> DateComponents {
        _calendar.dateComponents(unitFlags._calendarComponents, from: startingDate, to: resultDate)
    }
    
    /*
    This API is a convenience for getting era, year, month, and day of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    open func getEra(_ eraValuePointer: UnsafeMutablePointer<Int>?, year yearValuePointer: UnsafeMutablePointer<Int>?, month monthValuePointer: UnsafeMutablePointer<Int>?, day dayValuePointer: UnsafeMutablePointer<Int>?, from date: Date) {
        let comps = components([.era, .year, .month, .day], from: date)

        eraValuePointer?.pointee = comps.era ?? NSDateComponentUndefined
        yearValuePointer?.pointee = comps.year ?? NSDateComponentUndefined
        monthValuePointer?.pointee = comps.month ?? NSDateComponentUndefined
        dayValuePointer?.pointee = comps.day ?? NSDateComponentUndefined
    }
    
    /*
    This API is a convenience for getting era, year for week-of-year calculations, week of year, and weekday of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    open func getEra(_ eraValuePointer: UnsafeMutablePointer<Int>?, yearForWeekOfYear yearValuePointer: UnsafeMutablePointer<Int>?, weekOfYear weekValuePointer: UnsafeMutablePointer<Int>?, weekday weekdayValuePointer: UnsafeMutablePointer<Int>?, from date: Date) {
        let comps = components([.era, .yearForWeekOfYear, .weekOfYear, .weekday], from: date)

        eraValuePointer?.pointee = comps.era ?? NSDateComponentUndefined
        yearValuePointer?.pointee = comps.yearForWeekOfYear ?? NSDateComponentUndefined
        weekValuePointer?.pointee = comps.weekOfYear ?? NSDateComponentUndefined
        weekdayValuePointer?.pointee = comps.weekday ?? NSDateComponentUndefined
    }
    
    /*
    This API is a convenience for getting hour, minute, second, and nanoseconds of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    open func getHour(_ hourValuePointer: UnsafeMutablePointer<Int>?, minute minuteValuePointer: UnsafeMutablePointer<Int>?, second secondValuePointer: UnsafeMutablePointer<Int>?, nanosecond nanosecondValuePointer: UnsafeMutablePointer<Int>?, from date: Date) {
        let comps = components([.hour, .minute, .second, .nanosecond], from: date)

        hourValuePointer?.pointee = comps.hour ?? NSDateComponentUndefined
        minuteValuePointer?.pointee = comps.minute ?? NSDateComponentUndefined
        secondValuePointer?.pointee = comps.second ?? NSDateComponentUndefined
        nanosecondValuePointer?.pointee = comps.nanosecond ?? NSDateComponentUndefined
    }
    
    /*
    Get just one component's value.
    */
    open func component(_ unit: Unit, from date: Date) -> Int {
        let comps = components(unit, from: date)
        if let res = comps.value(for: unit._calendarComponent) {
            return res
        } else {
            return NSDateComponentUndefined
        }
    }
    
    /*
    Create a date with given components.
    Current era is assumed.
    */
    open func date(era eraValue: Int, year yearValue: Int, month monthValue: Int, day dayValue: Int, hour hourValue: Int, minute minuteValue: Int, second secondValue: Int, nanosecond nanosecondValue: Int) -> Date? {
        var comps = DateComponents()
        comps.era = eraValue
        comps.year = yearValue
        comps.month = monthValue
        comps.day = dayValue
        comps.hour = hourValue
        comps.minute = minuteValue
        comps.second = secondValue
        comps.nanosecond = nanosecondValue
        return date(from: comps)
    }
    
    /*
    Create a date with given components.
    Current era is assumed.
    */
    open func date(era eraValue: Int, yearForWeekOfYear yearValue: Int, weekOfYear weekValue: Int, weekday weekdayValue: Int, hour hourValue: Int, minute minuteValue: Int, second secondValue: Int, nanosecond nanosecondValue: Int) -> Date? {
        var comps = DateComponents()
        comps.era = eraValue
        comps.yearForWeekOfYear = yearValue
        comps.weekOfYear = weekValue
        comps.weekday = weekdayValue
        comps.hour = hourValue
        comps.minute = minuteValue
        comps.second = secondValue
        comps.nanosecond = nanosecondValue
        return date(from: comps)
    }
    
    /*
    This API returns the first moment date of a given date.
    Pass in [NSDate date], for example, if you want the start of "today".
    If there were two midnights, it returns the first.  If there was none, it returns the first moment that did exist.
    */
    open func startOfDay(for date: Date) -> Date {
        _calendar.startOfDay(for: date)
    }
    
    /*
    This API returns all the date components of a date, as if in a given time zone (instead of the receiving calendar's time zone).
    The time zone overrides the time zone of the NSCalendar for the purposes of this calculation.
    Note: if you want "date information in a given time zone" in order to display it, you should use NSDateFormatter to format the date.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// The Darwin version is not nullable but this one is since the conversion from the date and unit flags can potentially return nil
    open func components(in timezone: TimeZone, from date: Date) -> DateComponents {
        _calendar.dateComponents(in: timezone, from: date)
    }
    
    /*
    This API compares the given dates down to the given unit, reporting them equal if they are the same in the given unit and all larger units, otherwise either less than or greater than.
    */
    open func compare(_ date1: Date, to date2: Date, toUnitGranularity unit: Unit) -> ComparisonResult {
        _calendar.compare(date1, to: date2, toGranularity: unit._calendarComponent)
    }
    
    /*
    This API compares the given dates down to the given unit, reporting them equal if they are the same in the given unit and all larger units.
    */
    open func isDate(_ date1: Date, equalTo date2: Date, toUnitGranularity unit: Unit) -> Bool {
        _calendar.isDate(date1, equalTo: date2, toGranularity: unit._calendarComponent)
    }
    
    /*
    This API compares the Days of the given dates, reporting them equal if they are in the same Day.
    */
    open func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        _calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /*
    This API reports if the date is within "today".
    */
    open func isDateInToday(_ date: Date) -> Bool {
        _calendar.isDateInToday(date)
    }
    
    /*
    This API reports if the date is within "yesterday".
    */
    open func isDateInYesterday(_ date: Date) -> Bool {
        _calendar.isDateInYesterday(date)
    }
    
    /*
    This API reports if the date is within "tomorrow".
    */
    open func isDateInTomorrow(_ date: Date) -> Bool {
        _calendar.isDateInTomorrow(date)
    }
    
    /*
    This API reports if the date is within a weekend period, as defined by the calendar and calendar's locale.
    */
    open func isDateInWeekend(_ date: Date) -> Bool {
        _calendar.isDateInWeekend(date)
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// open func rangeOfWeekendStartDate(_ datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, containingDate date: NSDate) -> Bool
    /// which is not implementable on Linux due to the lack of being able to properly implement AutoreleasingUnsafeMutablePointer.
    /// Find the range of the weekend around the given date, returned via two by-reference parameters.
    /// Returns nil if the given date is not in a weekend.
    /// - Note: A given entire Day within a calendar is not necessarily all in a weekend or not; weekends can start in the middle of a Day in some calendars and locales.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func range(ofWeekendContaining date: Date) -> DateInterval? {
        if let next = nextWeekendAfter(date, options: []) {
            if let prev = nextWeekendAfter(next.start, options: .searchBackwards) {
                if prev.start <= date && date < prev.end /* exclude the end since it's the start of the next day */ {
                    return prev
                }
            }
        }
        return nil
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// open func nextWeekendStartDate(_ datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, options: Options, afterDate date: NSDate) -> Bool
    /// Returns the range of the next weekend, via two by-reference parameters, which starts strictly after the given date.
    /// The .SearchBackwards option can be used to find the previous weekend range strictly before the date.
    /// Returns nil if there are no such things as weekend in the calendar and its locale.
    /// - Note: A given entire Day within a calendar is not necessarily all in a weekend or not; weekends can start in the middle of a Day in some calendars and locales.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func nextWeekendAfter(_ date: Date, options: Options) -> DateInterval? {
        _calendar.nextWeekend(startingAfter: date, direction: options.contains(.searchBackwards) ? .backward : .forward)
    }
    
    /*
    This API returns the difference between two dates specified as date components.
    For units which are not specified in each NSDateComponents, but required to specify an absolute date, the base value of the unit is assumed.  For example, for an NSDateComponents with just a Year and a Month specified, a Day of 1, and an Hour, Minute, Second, and Nanosecond of 0 are assumed.
    Calendrical calculations with unspecified Year or Year value prior to the start of a calendar are not advised.
    For each date components object, if its time zone property is set, that time zone is used for it; if the calendar property is set, that is used rather than the receiving calendar, and if both the calendar and time zone are set, the time zone property value overrides the time zone of the calendar property.
    No options are currently defined; pass 0.
    */
    open func components(_ unitFlags: Unit, from startingDateComp: DateComponents, to resultDateComp: DateComponents, options: Options = []) -> DateComponents {
        _calendar.dateComponents(unitFlags._calendarComponents, from: startingDateComp, to: resultDateComp)
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by adding an amount of a specific component to a given date.
    The NSCalendarWrapComponents option specifies if the component should be incremented and wrap around to zero/one on overflow, and should not cause higher units to be incremented.
    */
    open func date(byAdding unit: Unit, value: Int, to date: Date, options: Options = []) -> Date? {
        var comps = DateComponents()
        comps.setValue(value, for: unit._calendarComponent)
        return self.date(byAdding: comps, to: date, options: options)
    }
    
    /*
    This method computes the dates which match (or most closely match) a given set of components, and calls the block once for each of them, until the enumeration is stopped.
    There will be at least one intervening date which does not match all the components (or the given date itself must not match) between the given date and any result.
    If the NSCalendarSearchBackwards option is used, this method finds the previous match before the given date.  The intent is that the same matches as for a forwards search will be found (that is, if you are enumerating forwards or backwards for each hour with minute "27", the seconds in the date you will get in forwards search would obviously be 00, and the same will be true in a backwards search in order to implement this rule.  Similarly for DST backwards jumps which repeats times, you'll get the first match by default, where "first" is defined from the point of view of searching forwards.  So, when searching backwards looking for a particular hour, with no minute and second specified, you don't get a minute and second of 59:59 for the matching hour (which would be the nominal first match within a given hour, given the other rules here, when searching backwards).
    If the NSCalendarMatchStrictly option is used, the algorithm travels as far forward or backward as necessary looking for a match, but there are ultimately implementation-defined limits in how far distant the search will go.  If the NSCalendarMatchStrictly option is not specified, the algorithm searches up to the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument.  If you want to find the next Feb 29 in the Gregorian calendar, for example, you have to specify the NSCalendarMatchStrictly option to guarantee finding it.
    If an exact match is not possible, and requested with the NSCalendarMatchStrictly option, nil is passed to the block and the enumeration ends.  (Logically, since an exact match searches indefinitely into the future, if no match is found there's no point in continuing the enumeration.)
    
    If the NSCalendarMatchStrictly option is NOT used, exactly one option from the set {NSCalendarMatchPreviousTimePreservingSmallerUnits, NSCalendarMatchNextTimePreservingSmallerUnits, NSCalendarMatchNextTime} must be specified, or an illegal argument exception will be thrown.
    
    If the NSCalendarMatchPreviousTimePreservingSmallerUnits option is specified, and there is no matching time before the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument, the method will return the previous existing value of the missing unit and preserves the lower units' values (e.g., no 2:37am results in 1:37am, if that exists).
    
    If the NSCalendarMatchNextTimePreservingSmallerUnits option is specified, and there is no matching time before the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument, the method will return the next existing value of the missing unit and preserves the lower units' values (e.g., no 2:37am results in 3:37am, if that exists).
    
    If the NSCalendarMatchNextTime option is specified, and there is no matching time before the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument, the method will return the next existing time which exists (e.g., no 2:37am results in 3:00am, if that exists).
    If the NSCalendarMatchFirst option is specified, and there are two or more matching times (all the components are the same, including isLeapMonth) before the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument, the method will return the first occurrence.
    If the NSCalendarMatchLast option is specified, and there are two or more matching times (all the components are the same, including isLeapMonth) before the end of the next instance of the next higher unit to the highest specified unit in the NSDateComponents argument, the method will return the last occurrence.
    If neither the NSCalendarMatchFirst or NSCalendarMatchLast option is specified, the default behavior is to act as if NSCalendarMatchFirst was specified.
    There is no option to return middle occurrences of more than two occurrences of a matching time, if such exist.
    
    Result dates have an integer number of seconds (as if 0 was specified for the nanoseconds property of the NSDateComponents matching parameter), unless a value was set in the nanoseconds property, in which case the result date will have that number of nanoseconds (or as close as possible with floating point numbers).
    The enumeration is stopped by setting *stop = YES in the block and return.  It is not necessary to set *stop to NO to keep the enumeration going.
    */
    open func enumerateDates(startingAfter start: Date, matching comps: DateComponents, options opts: NSCalendar.Options = [], using block: (Date?, Bool, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        if !verifyCalendarOptions(opts) {
            return
        }
        
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(opts)
        _calendar.enumerateDates(startingAfter: start, matching: comps, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction) { result, exactMatch, stop in
            let ptr = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            ptr.initialize(to: ObjCBool(false))
            block(result, exactMatch, ptr)
            if ptr.pointee.boolValue {
                stop = true
            }
            ptr.deinitialize(count: 1)
            ptr.deallocate()
        }
    }
    
    private func verifyCalendarOptions(_ options: NSCalendar.Options) -> Bool {
        var optionsAreValid = true
        
        let matchStrictly = options.contains(.matchStrictly)
        let matchPrevious = options.contains(.matchPreviousTimePreservingSmallerUnits)
        let matchNextKeepSmaller = options.contains(.matchNextTimePreservingSmallerUnits)
        let matchNext = options.contains(.matchNextTime)
        let matchFirst = options.contains(.matchFirst)
        let matchLast = options.contains(.matchLast)
        
        if matchStrictly && (matchPrevious || matchNextKeepSmaller || matchNext) {
            // We can't throw here because we've never thrown on this case before, even though it is technically an invalid case.  The next best thing is to return.
            optionsAreValid = false
        }
        
        if !matchStrictly {
            if (matchPrevious && matchNext) || (matchPrevious && matchNextKeepSmaller) || (matchNext && matchNextKeepSmaller) || (!matchPrevious && !matchNext && !matchNextKeepSmaller) {
                fatalError("Exactly one option from the set {NSCalendarMatchPreviousTimePreservingSmallerUnits, NSCalendarMatchNextTimePreservingSmallerUnits, NSCalendarMatchNextTime} must be specified.")
            }
        }
        
        if (matchFirst && matchLast) {
            fatalError("Only one option from the set {NSCalendarMatchFirst, NSCalendarMatchLast} can be specified.")
        }
        
        return optionsAreValid
    }
    
    /*
    This method computes the next date which matches (or most closely matches) a given set of components.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    open func nextDate(after date: Date, matching comps: DateComponents, options: Options = []) -> Date? {
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(options)
        return _calendar.nextDate(after: date, matching: comps, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction)
    }
    
    /*
    This API returns a new NSDate object representing the date found which matches a specific component value.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    open func nextDate(after date: Date, matching unit: Unit, value: Int, options: Options = []) -> Date? {
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(options)
        var dc = DateComponents()
        dc.setValue(value, for: unit._calendarComponent)
        return _calendar.nextDate(after: date, matching: dc, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction)
    }
    
    /*
    This API returns a new NSDate object representing the date found which matches the given hour, minute, and second values.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    open func nextDate(after date: Date, matchingHour hourValue: Int, minute minuteValue: Int, second secondValue: Int, options: Options = []) -> Date? {
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(options)
        let dc = DateComponents(hour: hourValue, minute: minuteValue, second: secondValue)
        return _calendar.nextDate(after: date, matching: dc, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction)
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by setting a specific component to a given time, and trying to keep lower components the same.  If the unit already has that value, this may result in a date which is the same as the given date.
    Changing a component's value often will require higher or coupled components to change as well.  For example, setting the Weekday to Thursday usually will require the Day component to change its value, and possibly the Month and Year as well.
    If no such time exists, the next available time is returned (which could, for example, be in a different day, week, month, ... than the nominal target date).  Setting a component to something which would be inconsistent forces other units to change; for example, setting the Weekday to Thursday probably shifts the Day and possibly Month and Year.
    The specific behaviors here are as yet unspecified; for example, if I change the weekday to Thursday, does that move forward to the next, backward to the previous, or to the nearest Thursday?  A likely rule is that the algorithm will try to produce a result which is in the next-larger unit to the one given (there's a table of this mapping at the top of this document).  So for the "set to Thursday" example, find the Thursday in the Week in which the given date resides (which could be a forwards or backwards move, and not necessarily the nearest Thursday).  For forwards or backwards behavior, one can use the -nextDateAfterDate:matchingUnit:value:options: method above.
    */
    open func date(bySettingUnit unit: Unit, value v: Int, of date: Date, options opts: Options = []) -> Date? {
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(opts)
        let current = _calendar.component(unit._calendarComponent, from: date)
        if current == v {
            return date
        }

        var target = DateComponents()
        target.setValue(v, for: unit._calendarComponent)
        var result: Date?
        _calendar.enumerateDates(startingAfter: date, matching: target, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction) { date, exactMatch, stop in
            result = date
            stop = true
        }
        return result
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by setting hour, minute, and second to a given time.
    If no such time exists, the next available time is returned (which could, for example, be in a different day than the nominal target date).
    The intent is to return a date on the same day as the original date argument.  This may result in a date which is earlier than the given date, of course.
    */
    open func date(bySettingHour h: Int, minute m: Int, second s: Int, of date: Date, options opts: Options = []) -> Date? {
        let (matchingPolicy, repeatedTimePolicy, direction) = _fromNSCalendarOptions(opts)
        return _calendar.date(bySettingHour: h, minute: m, second: s, of: date, matchingPolicy: matchingPolicy, repeatedTimePolicy: repeatedTimePolicy, direction: direction)
    }
    
    /*
    This API returns YES if the date has all the matched components. Otherwise, it returns NO.
    It is useful to test the return value of the -nextDateAfterDate:matchingUnit:value:options:, to find out if the components were obeyed or if the method had to fudge the result value due to missing time.
    */
    open func date(_ date: Date, matchesComponents components: DateComponents) -> Bool {
        _calendar.date(date, matchesComponents: components)
    }
    
}

#if !os(WASI)
// This notification is posted through [NSNotificationCenter defaultCenter]
// when the system day changes. Register with "nil" as the object of this
// notification. If the computer/device is asleep when the day changed,
// this will be posted on wakeup. You'll get just one of these if the
// machine has been asleep for several days. The definition of "Day" is
// relative to the current calendar ([NSCalendar currentCalendar]) of the
// process and its locale and time zone. There are no guarantees that this
// notification is received by observers in a "timely" manner, same as
// with distributed notifications.

extension NSNotification.Name {
    public static let NSCalendarDayChanged = NSNotification.Name(rawValue: "NSCalendarDayChangedNotification")
}
#endif


private func _toNSRange(_ range: Range<Int>?) -> NSRange {
    if let r = range {
        return NSRange(location: r.lowerBound, length: r.upperBound - r.lowerBound)
    } else {
        return NSRange(location: NSNotFound, length: NSNotFound)
    }
}

private func _fromNSCalendarOptions(_ options: NSCalendar.Options) -> (matchingPolicy: Calendar.MatchingPolicy, repeatedTimePolicy: Calendar.RepeatedTimePolicy, direction: Calendar.SearchDirection) {

    let matchingPolicy: Calendar.MatchingPolicy
    let repeatedTimePolicy: Calendar.RepeatedTimePolicy
    let direction: Calendar.SearchDirection

    if options.contains(.matchNextTime) {
        matchingPolicy = .nextTime
    } else if options.contains(.matchNextTimePreservingSmallerUnits) {
        matchingPolicy = .nextTimePreservingSmallerComponents
    } else if options.contains(.matchPreviousTimePreservingSmallerUnits) {
        matchingPolicy = .previousTimePreservingSmallerComponents
    } else if options.contains(.matchStrictly) {
        matchingPolicy = .strict
    } else {
        // Default
        matchingPolicy = .nextTime
    }

    if options.contains(.matchFirst) {
        repeatedTimePolicy = .first
    } else if options.contains(.matchLast) {
        repeatedTimePolicy = .last
    } else {
        // Default
        repeatedTimePolicy = .first
    }

    if options.contains(.searchBackwards) {
        direction = .backward
    } else {
        direction = .forward
    }

    return (matchingPolicy, repeatedTimePolicy, direction)
}

// MARK: - Bridging

extension CFCalendar : _NSBridgeable, _SwiftBridgeable {
    typealias NSType = NSCalendar
    internal var _nsObject: NSType {
        let id = CFCalendarGetIdentifier(self)!._swiftObject
        let ns = NSCalendar(identifier: .init(string: id)!)!
        ns.timeZone = CFCalendarCopyTimeZone(self)._swiftObject
        ns.firstWeekday = CFCalendarGetFirstWeekday(self)
        ns.minimumDaysInFirstWeek = CFCalendarGetMinimumDaysInFirstWeek(self)
        return ns
    }
    internal var _swiftObject: Calendar {
        return _nsObject._swiftObject
    }
}

extension NSCalendar {
    internal var _cfObject: CFCalendar {
        let cf = CFCalendarCreateWithIdentifier(nil, calendarIdentifier._calendarIdentifier!._cfCalendarIdentifier._cfObject)!
        CFCalendarSetTimeZone(cf, timeZone._cfObject)
        if let l = locale {
            CFCalendarSetLocale(cf, l._cfObject)
        }
        CFCalendarSetFirstWeekday(cf, firstWeekday)
        CFCalendarSetMinimumDaysInFirstWeek(cf, minimumDaysInFirstWeek)
        return cf
    }
}

extension NSCalendar: _SwiftBridgeable {
    typealias SwiftType = Calendar
    var _swiftObject: SwiftType { _calendar }
}

extension NSCalendar : _StructTypeBridgeable {
    public typealias _StructType = Calendar
    
    public func _bridgeToSwift() -> Calendar {
        return Calendar._unconditionallyBridgeFromObjectiveC(self)
    }
}

extension Calendar: _NSBridgeable {
    typealias NSType = NSCalendar
    typealias CFType = CFCalendar
    var _nsObject: NSCalendar { return _bridgeToObjectiveC() }
    var _cfObject: CFCalendar { return _nsObject._cfObject }
}


extension Calendar : ReferenceConvertible {
    public typealias ReferenceType = NSCalendar
}

extension Calendar: _ObjectiveCBridgeable {
    public typealias _ObjectType = NSCalendar
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSCalendar {
        NSCalendar(calendar: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSCalendar, result: inout Calendar?) {
        if !_conditionallyBridgeFromObjectiveC(input, result: &result) {
            fatalError("Unable to bridge \(NSCalendar.self) to \(self)")
        }
    }
    
    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSCalendar, result: inout Calendar?) -> Bool {
        result = input._calendar
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSCalendar?) -> Calendar {
        var result: Calendar? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}
