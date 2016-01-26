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
internal let kCFCalendarUnitEra = CFCalendarUnit.Era.rawValue
internal let kCFCalendarUnitYear = CFCalendarUnit.Year.rawValue
internal let kCFCalendarUnitMonth = CFCalendarUnit.Month.rawValue
internal let kCFCalendarUnitDay = CFCalendarUnit.Day.rawValue
internal let kCFCalendarUnitHour = CFCalendarUnit.Hour.rawValue
internal let kCFCalendarUnitMinute = CFCalendarUnit.Minute.rawValue
internal let kCFCalendarUnitSecond = CFCalendarUnit.Second.rawValue
internal let kCFCalendarUnitWeekday = CFCalendarUnit.Weekday.rawValue
internal let kCFCalendarUnitWeekdayOrdinal = CFCalendarUnit.WeekdayOrdinal.rawValue
internal let kCFCalendarUnitQuarter = CFCalendarUnit.Quarter.rawValue
internal let kCFCalendarUnitWeekOfMonth = CFCalendarUnit.WeekOfMonth.rawValue
internal let kCFCalendarUnitWeekOfYear = CFCalendarUnit.WeekOfYear.rawValue
internal let kCFCalendarUnitYearForWeekOfYear = CFCalendarUnit.YearForWeekOfYear.rawValue

internal let kCFDateFormatterNoStyle = CFDateFormatterStyle.NoStyle
internal let kCFDateFormatterShortStyle = CFDateFormatterStyle.ShortStyle
internal let kCFDateFormatterMediumStyle = CFDateFormatterStyle.MediumStyle
internal let kCFDateFormatterLongStyle = CFDateFormatterStyle.LongStyle
internal let kCFDateFormatterFullStyle = CFDateFormatterStyle.FullStyle
#endif

public let NSCalendarIdentifierGregorian: String = "gregorian"
public let NSCalendarIdentifierBuddhist: String = "buddhist"
public let NSCalendarIdentifierChinese: String = "chinese"
public let NSCalendarIdentifierCoptic: String = "coptic"
public let NSCalendarIdentifierEthiopicAmeteMihret: String = "ethiopic"
public let NSCalendarIdentifierEthiopicAmeteAlem: String = "ethiopic-amete-alem"
public let NSCalendarIdentifierHebrew: String = "hebrew"
public let NSCalendarIdentifierISO8601: String = ""
public let NSCalendarIdentifierIndian: String = "indian"
public let NSCalendarIdentifierIslamic: String = "islamic"
public let NSCalendarIdentifierIslamicCivil: String = "islamic-civil"
public let NSCalendarIdentifierJapanese: String = "japanese"
public let NSCalendarIdentifierPersian: String = "persian"
public let NSCalendarIdentifierRepublicOfChina: String = "roc"
public let NSCalendarIdentifierIslamicTabular: String = "islamic-tbla"
public let NSCalendarIdentifierIslamicUmmAlQura: String = "islamic-umalqura"

public struct NSCalendarUnit : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let Era = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitEra))
    public static let Year = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitYear))
    public static let Month = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitMonth))
    public static let Day = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitDay))
    public static let Hour = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitHour))
    public static let Minute = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitMinute))
    public static let Second = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitSecond))
    public static let Weekday = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitWeekday))
    public static let WeekdayOrdinal = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitWeekdayOrdinal))
    public static let Quarter = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitQuarter))
    public static let WeekOfMonth = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitWeekOfMonth))
    public static let WeekOfYear = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitWeekOfYear))
    public static let YearForWeekOfYear = NSCalendarUnit(rawValue: UInt(kCFCalendarUnitYearForWeekOfYear))

    public static let Nanosecond = NSCalendarUnit(rawValue: UInt(1 << 15))
    public static let Calendar = NSCalendarUnit(rawValue: UInt(1 << 20))
    public static let TimeZone = NSCalendarUnit(rawValue: UInt(1 << 21))
    
    internal var _cfValue: CFCalendarUnit {
#if os(OSX) || os(iOS)
        return CFCalendarUnit(rawValue: self.rawValue)
#else
        return CFCalendarUnit(self.rawValue)
#endif
    }
}

public struct NSCalendarOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let WrapComponents = NSCalendarOptions(rawValue: 1 << 0)
    public static let MatchStrictly = NSCalendarOptions(rawValue: 1 << 1)
    public static let SearchBackwards = NSCalendarOptions(rawValue: 1 << 2)
    public static let MatchPreviousTimePreservingSmallerUnits = NSCalendarOptions(rawValue: 1 << 8)
    public static let MatchNextTimePreservingSmallerUnits = NSCalendarOptions(rawValue: 1 << 9)
    public static let MatchNextTime = NSCalendarOptions(rawValue: 1 << 10)
    public static let MatchFirst = NSCalendarOptions(rawValue: 1 << 12)
    public static let MatchLast = NSCalendarOptions(rawValue: 1 << 13)
}

public class NSCalendar : NSObject, NSCopying, NSSecureCoding {
    typealias CFType = CFCalendarRef
    private var _base = _CFInfo(typeID: CFCalendarGetTypeID())
    private var _identifier = UnsafeMutablePointer<Void>()
    private var _locale = UnsafeMutablePointer<Void>()
    private var _localeID = UnsafeMutablePointer<Void>()
    private var _tz = UnsafeMutablePointer<Void>()
    private var _cal = UnsafeMutablePointer<Void>()
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFCalendarRef.self)
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            guard let calendarIdentifier = aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.identifier") else {
                return nil
            }
            
            self.init(calendarIdentifier: calendarIdentifier.bridge())
            
            if let timeZone = aDecoder.decodeObjectOfClass(NSTimeZone.self, forKey: "NS.timezone") {
                self.timeZone = timeZone
            }
            if let locale = aDecoder.decodeObjectOfClass(NSLocale.self, forKey: "NS.locale") {
                self.locale = locale
            }
            self.firstWeekday = aDecoder.decodeIntegerForKey("NS.firstwkdy")
            self.minimumDaysInFirstWeek = aDecoder.decodeIntegerForKey("NS.mindays")
            if let startDate = aDecoder.decodeObjectOfClass(NSDate.self, forKey: "NS.gstartdate") {
                self._startDate = startDate
            }
        } else {
            NSUnimplemented()
        }
    }
    
    private var _startDate : NSDate? {
        get {
            return CFCalendarCopyGregorianStartDate(self._cfObject)?._nsObject
        }
        set {
            if let startDate = newValue {
                CFCalendarSetGregorianStartDate(self._cfObject, startDate._cfObject)
            }
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeObject(self.calendarIdentifier.bridge(), forKey: "NS.identifier")
            aCoder.encodeObject(self.timeZone, forKey: "NS.timezone")
            aCoder.encodeObject(self.locale, forKey: "NS.locale")
            aCoder.encodeInteger(self.firstWeekday, forKey: "NS.firstwkdy")
            aCoder.encodeInteger(self.minimumDaysInFirstWeek, forKey: "NS.mindays")
            aCoder.encodeObject(self._startDate, forKey: "NS.gstartdate");
        } else {
            NSUnimplemented()
        }
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    

    public class func currentCalendar() -> NSCalendar {
        return CFCalendarCopyCurrent()._nsObject
    }
    
    public class func autoupdatingCurrentCalendar() -> NSCalendar { NSUnimplemented() }  // tracks changes to user's preferred calendar identifier
    
    public /*not inherited*/ init?(identifier calendarIdentifierConstant: String) {
        super.init()
        if !_CFCalendarInitWithIdentifier(_cfObject, calendarIdentifierConstant._cfObject) {
            return nil
        }
    }
    
    public init?(calendarIdentifier ident: String) {
        super.init()
        if !_CFCalendarInitWithIdentifier(_cfObject, ident._cfObject) {
            return nil
        }
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let cal = object as? NSCalendar {
            return CFEqual(_cfObject, cal._cfObject)
        } else {
            return false
        }
    }
    
    public override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }

    deinit {
        _CFDeinit(self)
    }
    
    public var calendarIdentifier: String  {
        get {
            return CFCalendarGetIdentifier(_cfObject)._swiftObject
        }
    }
    
    /*@NSCopying*/ public var locale: NSLocale? {
        get {
            return CFCalendarCopyLocale(_cfObject)._nsObject
        }
        set {
            CFCalendarSetLocale(_cfObject, newValue?._cfObject)
        }
    }
    /*@NSCopying*/ public var timeZone: NSTimeZone {
        get {
            return CFCalendarCopyTimeZone(_cfObject)._nsObject
        }
        set {
            CFCalendarSetTimeZone(_cfObject, newValue._cfObject)
        }
    }
    
    public var firstWeekday: Int {
        get {
            return CFCalendarGetFirstWeekday(_cfObject)
        }
        set {
            CFCalendarSetFirstWeekday(_cfObject, CFIndex(newValue))
        }
    }
    
    public var minimumDaysInFirstWeek: Int {
        get {
            return CFCalendarGetMinimumDaysInFirstWeek(_cfObject)
        }
        set {
            CFCalendarSetMinimumDaysInFirstWeek(_cfObject, CFIndex(newValue))
        }
    }
    
    // Methods to return component name strings localized to the calendar's locale
    
    private func _symbols(key: CFStringRef) -> [String] {
        let dateFormatter = CFDateFormatterCreate(kCFAllocatorSystemDefault, locale?._cfObject, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle)
        CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterCalendarKey, _cfObject)
        let result = (CFDateFormatterCopyProperty(dateFormatter, key) as! CFArrayRef)._swiftObject
        return result.map {
            return ($0 as! NSString)._swiftObject
        }
    }
    
    private func _symbol(key: CFStringRef) -> String {
        let dateFormatter = CFDateFormatterCreate(kCFAllocatorSystemDefault, locale?._cfObject, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle)
        CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterCalendarKey, self._cfObject)
        return (CFDateFormatterCopyProperty(dateFormatter, key) as! CFStringRef)._swiftObject
    }
    
    public var eraSymbols: [String] {
        return _symbols(kCFDateFormatterEraSymbolsKey)
    }
    
    public var longEraSymbols: [String] {
        return _symbols(kCFDateFormatterLongEraSymbolsKey)
    }
    
    public var monthSymbols: [String] {
        return _symbols(kCFDateFormatterMonthSymbolsKey)
    }
    
    public var shortMonthSymbols: [String] {
        return _symbols(kCFDateFormatterShortMonthSymbolsKey)
    }
    
    public var veryShortMonthSymbols: [String] {
        return _symbols(kCFDateFormatterVeryShortMonthSymbolsKey)
    }
    
    public var standaloneMonthSymbols: [String] {
        return _symbols(kCFDateFormatterStandaloneMonthSymbolsKey)
    }
    
    public var shortStandaloneMonthSymbols: [String] {
        return _symbols(kCFDateFormatterShortStandaloneMonthSymbolsKey)
    }
    
    public var veryShortStandaloneMonthSymbols: [String] {
        return _symbols(kCFDateFormatterVeryShortStandaloneMonthSymbolsKey)
    }
    
    public var weekdaySymbols: [String] {
        return _symbols(kCFDateFormatterWeekdaySymbolsKey)
    }
    
    public var shortWeekdaySymbols: [String] {
        return _symbols(kCFDateFormatterShortWeekdaySymbolsKey)
    }
    
    public var veryShortWeekdaySymbols: [String] {
        return _symbols(kCFDateFormatterVeryShortWeekdaySymbolsKey)
    }
    
    public var standaloneWeekdaySymbols: [String] {
        return _symbols(kCFDateFormatterStandaloneWeekdaySymbolsKey)
    }
    
    public var shortStandaloneWeekdaySymbols: [String] {
        return _symbols(kCFDateFormatterShortStandaloneWeekdaySymbolsKey)
    }

    public var veryShortStandaloneWeekdaySymbols: [String] {
        return _symbols(kCFDateFormatterVeryShortStandaloneWeekdaySymbolsKey)
    }
    
    public var quarterSymbols: [String] {
        return _symbols(kCFDateFormatterQuarterSymbolsKey)
    }
    
    public var shortQuarterSymbols: [String] {
        return _symbols(kCFDateFormatterShortQuarterSymbolsKey)
    }
    
    public var standaloneQuarterSymbols: [String] {
        return _symbols(kCFDateFormatterStandaloneQuarterSymbolsKey)
    }
    
    public var shortStandaloneQuarterSymbols: [String] {
        return _symbols(kCFDateFormatterShortStandaloneQuarterSymbolsKey)
    }
    
    public var AMSymbol: String {
        return _symbol(kCFDateFormatterAMSymbolKey)
    }
    
    public var PMSymbol: String {
        return _symbol(kCFDateFormatterPMSymbolKey)
    }
    
    // Calendrical calculations
    
    public func minimumRangeOfUnit(unit: NSCalendarUnit) -> NSRange {
        let r = CFCalendarGetMinimumRangeOfUnit(self._cfObject, unit._cfValue)
        if (r.location == kCFNotFound) {
            return NSMakeRange(NSNotFound, NSNotFound)
        }
        return NSMakeRange(r.location, r.length)
    }
    
    public func maximumRangeOfUnit(unit: NSCalendarUnit) -> NSRange {
        let r = CFCalendarGetMaximumRangeOfUnit(_cfObject, unit._cfValue)
        if r.location == kCFNotFound {
            return NSMakeRange(NSNotFound, NSNotFound)
        }
        return NSMakeRange(r.location, r.length)
    }
    
    public func rangeOfUnit(smaller: NSCalendarUnit, inUnit larger: NSCalendarUnit, forDate date: NSDate) -> NSRange {
        let r = CFCalendarGetRangeOfUnit(_cfObject, smaller._cfValue, larger._cfValue, date.timeIntervalSinceReferenceDate)
        if r.location == kCFNotFound {
            return NSMakeRange(NSNotFound, NSNotFound)
        }
        return NSMakeRange(r.location, r.length);
    }
    
    public func ordinalityOfUnit(smaller: NSCalendarUnit, inUnit larger: NSCalendarUnit, forDate date: NSDate) -> Int {
        return Int(CFCalendarGetOrdinalityOfUnit(_cfObject, smaller._cfValue, larger._cfValue, date.timeIntervalSinceReferenceDate))
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// public func rangeOfUnit(unit: NSCalendarUnit, startDate datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, forDate date: NSDate) -> Bool
    /// which is not implementable on Linux due to the lack of being able to properly implement AutoreleasingUnsafeMutablePointer.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func rangeOfUnit(unit: NSCalendarUnit, forDate date: NSDate) -> NSDateInterval? {
        var start: CFAbsoluteTime = 0.0
        var ti: CFTimeInterval = 0.0
        let res: Bool = withUnsafeMutablePointers(&start, &ti) { startp, tip in
           return CFCalendarGetTimeRangeOfUnit(_cfObject, unit._cfValue, date.timeIntervalSinceReferenceDate, startp, tip)
        }
        
        if res {
            return NSDateInterval(start: NSDate(timeIntervalSinceReferenceDate: start), interval: ti)
        }
        return nil
    }
    
    private func _convert(component: Int, type: String, inout vector: [Int32], inout compDesc: [Int8]) {
        if component != NSDateComponentUndefined {
            vector.append(Int32(component))
            compDesc.append(Int8(type.utf8[type.utf8.startIndex]))
        }
    }
    
    private func _convert(comps: NSDateComponents) -> (Array<Int32>, Array<Int8>) {
        var vector = [Int32]()
        var compDesc = [Int8]()
        _convert(comps.era, type: "E", vector: &vector, compDesc: &compDesc)
        _convert(comps.year, type: "y", vector: &vector, compDesc: &compDesc)
        _convert(comps.quarter, type: "Q", vector: &vector, compDesc: &compDesc)
        if comps.weekOfYear != NSDateComponentUndefined {
            _convert(comps.weekOfYear, type: "w", vector: &vector, compDesc: &compDesc)
        } else {
            // _convert(comps.week, type: "^", vector: &vector, compDesc: &compDesc)
        }
        _convert(comps.weekOfMonth, type: "W", vector: &vector, compDesc: &compDesc)
        _convert(comps.yearForWeekOfYear, type: "Y", vector: &vector, compDesc: &compDesc)
        _convert(comps.weekday, type: "E", vector: &vector, compDesc: &compDesc)
        _convert(comps.weekdayOrdinal, type: "F", vector: &vector, compDesc: &compDesc)
        _convert(comps.month, type: "M", vector: &vector, compDesc: &compDesc)
        _convert(comps.leapMonth ? 1 : 0, type: "L", vector: &vector, compDesc: &compDesc)
        _convert(comps.day, type: "d", vector: &vector, compDesc: &compDesc)
        _convert(comps.hour, type: "H", vector: &vector, compDesc: &compDesc)
        _convert(comps.minute, type: "m", vector: &vector, compDesc: &compDesc)
        _convert(comps.second, type: "s", vector: &vector, compDesc: &compDesc)
        _convert(comps.nanosecond, type: "#", vector: &vector, compDesc: &compDesc)
        compDesc.append(0)
        return (vector, compDesc)
    }
    
    public func dateFromComponents(comps: NSDateComponents) -> NSDate? {
        var (vector, compDesc) = _convert(comps)
        
        self.timeZone = comps.timeZone ?? timeZone
        
        var at: CFAbsoluteTime = 0.0
        let res: Bool = withUnsafeMutablePointer(&at) { t in
            return vector.withUnsafeMutableBufferPointer { (inout vectorBuffer: UnsafeMutableBufferPointer<Int32>) in
                return _CFCalendarComposeAbsoluteTimeV(_cfObject, t, compDesc, vectorBuffer.baseAddress, Int32(vector.count))
            }
        }
        
        if res {
            return NSDate(timeIntervalSinceReferenceDate: at)
        } else {
            return nil
        }
    }
    
    private func _setup(unitFlags: NSCalendarUnit, field: NSCalendarUnit, type: String, inout compDesc: [Int8]) {
        if unitFlags.contains(field) {
            compDesc.append(Int8(type.utf8[type.utf8.startIndex]))
        }
    }
    
    private func _setup(unitFlags: NSCalendarUnit) -> [Int8] {
        var compDesc = [Int8]()
        _setup(unitFlags, field: .Era, type: "G", compDesc: &compDesc)
        _setup(unitFlags, field: .Year, type: "y", compDesc: &compDesc)
        _setup(unitFlags, field: .Quarter, type: "Q", compDesc: &compDesc)
        _setup(unitFlags, field: .Month, type: "M", compDesc: &compDesc)
        _setup(unitFlags, field: .Month, type: "l", compDesc: &compDesc)
        _setup(unitFlags, field: .Day, type: "d", compDesc: &compDesc)
        _setup(unitFlags, field: .WeekOfYear, type: "w", compDesc: &compDesc)
        _setup(unitFlags, field: .WeekOfMonth, type: "W", compDesc: &compDesc)
        _setup(unitFlags, field: .YearForWeekOfYear, type: "Y", compDesc: &compDesc)
        _setup(unitFlags, field: .Weekday, type: "E", compDesc: &compDesc)
        _setup(unitFlags, field: .WeekdayOrdinal, type: "F", compDesc: &compDesc)
        _setup(unitFlags, field: .Hour, type: "H", compDesc: &compDesc)
        _setup(unitFlags, field: .Minute, type: "m", compDesc: &compDesc)
        _setup(unitFlags, field: .Second, type: "s", compDesc: &compDesc)
        _setup(unitFlags, field: .Nanosecond, type: "#", compDesc: &compDesc)
        compDesc.append(0)
        return compDesc
    }
    
    private func _setComp(unitFlags: NSCalendarUnit, field: NSCalendarUnit, vector: [Int32], inout compIndex: Int, setter: (Int32) -> Void) {
        if unitFlags.contains(field) {
            setter(vector[compIndex])
            compIndex += 1
        }
    }
    
    private func _components(unitFlags: NSCalendarUnit, vector: [Int32]) -> NSDateComponents {
        var compIdx = 0
        let comps = NSDateComponents()
        _setComp(unitFlags, field: .Era, vector: vector, compIndex: &compIdx) { comps.era = Int($0) }
        _setComp(unitFlags, field: .Year, vector: vector, compIndex: &compIdx) { comps.year = Int($0) }
        _setComp(unitFlags, field: .Quarter, vector: vector, compIndex: &compIdx) { comps.quarter = Int($0) }
        _setComp(unitFlags, field: .Month, vector: vector, compIndex: &compIdx) { comps.month = Int($0) }
        _setComp(unitFlags, field: .Month, vector: vector, compIndex: &compIdx) { comps.leapMonth = $0 != 0 }
        _setComp(unitFlags, field: .Day, vector: vector, compIndex: &compIdx) { comps.day = Int($0) }
        _setComp(unitFlags, field: .WeekOfYear, vector: vector, compIndex: &compIdx) { comps.weekOfYear = Int($0) }
        _setComp(unitFlags, field: .WeekOfMonth, vector: vector, compIndex: &compIdx) { comps.weekOfMonth = Int($0) }
        _setComp(unitFlags, field: .YearForWeekOfYear, vector: vector, compIndex: &compIdx) { comps.yearForWeekOfYear = Int($0) }
        _setComp(unitFlags, field: .Weekday, vector: vector, compIndex: &compIdx) { comps.weekday = Int($0) }
        _setComp(unitFlags, field: .WeekdayOrdinal, vector: vector, compIndex: &compIdx) { comps.weekdayOrdinal = Int($0) }
        _setComp(unitFlags, field: .Hour, vector: vector, compIndex: &compIdx) { comps.hour = Int($0) }
        _setComp(unitFlags, field: .Minute, vector: vector, compIndex: &compIdx) { comps.minute = Int($0) }
        _setComp(unitFlags, field: .Second, vector: vector, compIndex: &compIdx) { comps.second = Int($0) }
        _setComp(unitFlags, field: .Nanosecond, vector: vector, compIndex: &compIdx) { comps.nanosecond = Int($0) }
        
        if unitFlags.contains(.Calendar) {
            comps.calendar = self
        }
        if unitFlags.contains(.TimeZone) {
            comps.timeZone = timeZone
        }
        return comps
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// The Darwin version is not nullable but this one is since the conversion from the date and unit flags can potentially return nil
    public func components(unitFlags: NSCalendarUnit, fromDate date: NSDate) -> NSDateComponents? {
        let compDesc = _setup(unitFlags)
        
        // _CFCalendarDecomposeAbsoluteTimeV requires a bit of a funky vector layout; which does not express well in swift; this is the closest I can come up with to the required format
        // int32_t ints[20];
        // int32_t *vector[20] = {&ints[0], &ints[1], &ints[2], &ints[3], &ints[4], &ints[5], &ints[6], &ints[7], &ints[8], &ints[9], &ints[10], &ints[11], &ints[12], &ints[13], &ints[14], &ints[15], &ints[16], &ints[17], &ints[18], &ints[19]};
        var ints = [Int32](count: 20, repeatedValue: 0)
        let res = ints.withUnsafeMutableBufferPointer { (inout intArrayBuffer: UnsafeMutableBufferPointer<Int32>) -> Bool in
            var vector: [UnsafeMutablePointer<Int32>] = (0..<20).map { idx in
                intArrayBuffer.baseAddress.advancedBy(idx)
            }

            return vector.withUnsafeMutableBufferPointer { (inout vecBuffer: UnsafeMutableBufferPointer<UnsafeMutablePointer<Int32>>) in
                return _CFCalendarDecomposeAbsoluteTimeV(_cfObject, date.timeIntervalSinceReferenceDate, compDesc, vecBuffer.baseAddress, Int32(compDesc.count - 1))
            }
        }
        if res {
            return _components(unitFlags, vector: ints)
        }
        
        return nil
    }
    
    public func dateByAddingComponents(comps: NSDateComponents, toDate date: NSDate, options opts: NSCalendarOptions) -> NSDate? {
        var (vector, compDesc) = _convert(comps)
        var at: CFAbsoluteTime = 0.0
        
        let res: Bool = withUnsafeMutablePointer(&at) { t in
            return vector.withUnsafeMutableBufferPointer { (inout vectorBuffer: UnsafeMutableBufferPointer<Int32>) in
                return _CFCalendarAddComponentsV(_cfObject, t, CFOptionFlags(opts.rawValue), compDesc, vectorBuffer.baseAddress, Int32(vector.count))
            }
        }
        
        if res {
            return NSDate(timeIntervalSinceReferenceDate: at)
        }
        
        return nil
    }
    
    public func components(unitFlags: NSCalendarUnit, fromDate startingDate: NSDate, toDate resultDate: NSDate, options opts: NSCalendarOptions) -> NSDateComponents {
        let compDesc = _setup(unitFlags)
        var ints = [Int32](count: 20, repeatedValue: 0)
        let res = ints.withUnsafeMutableBufferPointer { (inout intArrayBuffer: UnsafeMutableBufferPointer<Int32>) -> Bool in
            var vector: [UnsafeMutablePointer<Int32>] = (0..<20).map { idx in
                return intArrayBuffer.baseAddress.advancedBy(idx)
            }

            return vector.withUnsafeMutableBufferPointer { (inout vecBuffer: UnsafeMutableBufferPointer<UnsafeMutablePointer<Int32>>) in
                _CFCalendarGetComponentDifferenceV(_cfObject, startingDate.timeIntervalSinceReferenceDate, resultDate.timeIntervalSinceReferenceDate, CFOptionFlags(opts.rawValue), compDesc, vecBuffer.baseAddress, Int32(vector.count))
                return false
            }
        }
        if res {
            return _components(unitFlags, vector: ints)
        }
        fatalError()
    }
    
    /*
    This API is a convenience for getting era, year, month, and day of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    public func getEra(eraValuePointer: UnsafeMutablePointer<Int>, year yearValuePointer: UnsafeMutablePointer<Int>, month monthValuePointer: UnsafeMutablePointer<Int>, day dayValuePointer: UnsafeMutablePointer<Int>, fromDate date: NSDate) {
        if let comps = components([.Era, .Year, .Month, .Day], fromDate: date) {
            if eraValuePointer != nil {
                eraValuePointer.memory = comps.era
            }
            if yearValuePointer != nil {
                yearValuePointer.memory = comps.year
            }
            if monthValuePointer != nil {
                monthValuePointer.memory = comps.month
            }
            if dayValuePointer != nil {
                dayValuePointer.memory = comps.day
            }
        }
    }
    
    /*
    This API is a convenience for getting era, year for week-of-year calculations, week of year, and weekday of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    public func getEra(eraValuePointer: UnsafeMutablePointer<Int>, yearForWeekOfYear yearValuePointer: UnsafeMutablePointer<Int>, weekOfYear weekValuePointer: UnsafeMutablePointer<Int>, weekday weekdayValuePointer: UnsafeMutablePointer<Int>, fromDate date: NSDate) {
        if let comps = components([.Era, .YearForWeekOfYear, .WeekOfYear, .Weekday], fromDate: date) {
            if eraValuePointer != nil {
                eraValuePointer.memory = comps.era
            }
            if yearValuePointer != nil {
                yearValuePointer.memory = comps.yearForWeekOfYear
            }
            if weekValuePointer != nil {
                weekValuePointer.memory = comps.weekOfYear
            }
            if weekdayValuePointer != nil {
                weekdayValuePointer.memory = comps.weekday
            }
        }
    }
    
    /*
    This API is a convenience for getting hour, minute, second, and nanoseconds of a given date.
    Pass NULL for a NSInteger pointer parameter if you don't care about that value.
    */
    public func getHour(hourValuePointer: UnsafeMutablePointer<Int>, minute minuteValuePointer: UnsafeMutablePointer<Int>, second secondValuePointer: UnsafeMutablePointer<Int>, nanosecond nanosecondValuePointer: UnsafeMutablePointer<Int>, fromDate date: NSDate) {
        if let comps = components([.Hour, .Minute, .Second, .Nanosecond], fromDate: date) {
            if hourValuePointer != nil {
                hourValuePointer.memory = comps.hour
            }
            if minuteValuePointer != nil {
                minuteValuePointer.memory = comps.minute
            }
            if secondValuePointer != nil {
                secondValuePointer.memory = comps.second
            }
            if nanosecondValuePointer != nil {
                nanosecondValuePointer.memory = comps.nanosecond
            }
        }
    }
    
    /*
    Get just one component's value.
    */
    public func component(unit: NSCalendarUnit, fromDate date: NSDate) -> Int {
        let comps = components(unit, fromDate: date)
        if let res = comps?.valueForComponent(unit) {
            return res
        } else {
            return NSDateComponentUndefined
        }
    }
    
    /*
    Create a date with given components.
    Current era is assumed.
    */
    public func dateWithEra(eraValue: Int, year yearValue: Int, month monthValue: Int, day dayValue: Int, hour hourValue: Int, minute minuteValue: Int, second secondValue: Int, nanosecond nanosecondValue: Int) -> NSDate? {
        let comps = NSDateComponents()
        comps.era = eraValue
        comps.year = yearValue
        comps.month = monthValue
        comps.day = dayValue
        comps.hour = hourValue
        comps.minute = minuteValue
        comps.second = secondValue
        comps.nanosecond = nanosecondValue
        return dateFromComponents(comps)
    }
    
    /*
    Create a date with given components.
    Current era is assumed.
    */
    public func dateWithEra(eraValue: Int, yearForWeekOfYear yearValue: Int, weekOfYear weekValue: Int, weekday weekdayValue: Int, hour hourValue: Int, minute minuteValue: Int, second secondValue: Int, nanosecond nanosecondValue: Int) -> NSDate? {
        let comps = NSDateComponents()
        comps.era = eraValue
        comps.yearForWeekOfYear = yearValue
        comps.weekOfYear = weekValue
        comps.weekday = weekdayValue
        comps.hour = hourValue
        comps.minute = minuteValue
        comps.second = secondValue
        comps.nanosecond = nanosecondValue
        return dateFromComponents(comps)
    }
    
    /*
    This API returns the first moment date of a given date.
    Pass in [NSDate date], for example, if you want the start of "today".
    If there were two midnights, it returns the first.  If there was none, it returns the first moment that did exist.
    */
    public func startOfDayForDate(date: NSDate) -> NSDate {
        return rangeOfUnit(.Day, forDate: date)!.start
    }
    
    /*
    This API returns all the date components of a date, as if in a given time zone (instead of the receiving calendar's time zone).
    The time zone overrides the time zone of the NSCalendar for the purposes of this calculation.
    Note: if you want "date information in a given time zone" in order to display it, you should use NSDateFormatter to format the date.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// The Darwin version is not nullable but this one is since the conversion from the date and unit flags can potentially return nil
    public func componentsInTimeZone(timezone: NSTimeZone, fromDate date: NSDate) -> NSDateComponents? {
        let oldTz = self.timeZone
        self.timeZone = timezone
        let comps = components([.Era, .Year, .Month, .Day, .Hour, .Minute, .Second, .Nanosecond, .Weekday, .WeekdayOrdinal, .Quarter, .WeekOfMonth, .WeekOfYear, .YearForWeekOfYear, .Calendar, .TimeZone], fromDate: date)
        self.timeZone = oldTz
        return comps
    }
    
    /*
    This API compares the given dates down to the given unit, reporting them equal if they are the same in the given unit and all larger units, otherwise either less than or greater than.
    */
    public func compareDate(date1: NSDate, toDate date2: NSDate, toUnitGranularity unit: NSCalendarUnit) -> NSComparisonResult {
        switch (unit) {
            case NSCalendarUnit.Calendar:
                return .OrderedSame
            case NSCalendarUnit.TimeZone:
                return .OrderedSame
            case NSCalendarUnit.Day:
                fallthrough
            case NSCalendarUnit.Hour:
                let range = rangeOfUnit(unit, forDate: date1)
                let ats = range!.start.timeIntervalSinceReferenceDate
                let at2 = date2.timeIntervalSinceReferenceDate
                if ats <= at2 && at2 < ats + range!.interval {
                    return .OrderedSame
                }
                if at2 < ats {
                    return .OrderedDescending
                }
                return .OrderedAscending
            case NSCalendarUnit.Minute:
                var int1 = 0.0
                var int2 = 0.0
                modf(date1.timeIntervalSinceReferenceDate, &int1)
                modf(date2.timeIntervalSinceReferenceDate, &int2)
                int1 = floor(int1 / 60.0)
                int2 = floor(int2 / 60.0)
                if int1 == int2 {
                    return .OrderedSame
                }
                if int2 < int1 {
                    return .OrderedDescending
                }
                return .OrderedAscending
            case NSCalendarUnit.Second:
                var int1 = 0.0
                var int2 = 0.0
                modf(date1.timeIntervalSinceReferenceDate, &int1)
                modf(date2.timeIntervalSinceReferenceDate, &int2)
                if int1 == int2 {
                    return .OrderedSame
                }
                if int2 < int1 {
                    return .OrderedDescending
                }
                return .OrderedAscending
            case NSCalendarUnit.Nanosecond:
                var int1 = 0.0
                var int2 = 0.0
                let frac1 = modf(date1.timeIntervalSinceReferenceDate, &int1)
                let frac2 = modf(date2.timeIntervalSinceReferenceDate, &int2)
                int1 = floor(frac1 * 1000000000.0)
                int2 = floor(frac2 * 1000000000.0)
                if int1 == int2 {
                    return .OrderedSame
                }
                if int2 < int1 {
                    return .OrderedDescending
                }
                return .OrderedAscending
            default:
                break
        }

        let calendarUnits1: [NSCalendarUnit] = [.Era, .Year, .Month, .Day]
        let calendarUnits2: [NSCalendarUnit] = [.Era, .Year, .Month, .WeekdayOrdinal, .Day]
        let calendarUnits3: [NSCalendarUnit] = [.Era, .Year, .Month, .WeekOfMonth, .Weekday]
        let calendarUnits4: [NSCalendarUnit] = [.Era, .YearForWeekOfYear, .WeekOfYear, .Weekday]
        var units: [NSCalendarUnit]
        if unit == .YearForWeekOfYear || unit == .WeekOfYear {
            units = calendarUnits4
        } else if unit == .WeekdayOrdinal {
            units = calendarUnits2
        } else if unit == .Weekday || unit == .WeekOfMonth {
            units = calendarUnits3
        } else {
            units = calendarUnits1
        }
        
        // TODO: verify that the return value here is never going to be nil; it seems like it may - thusly making the return value here optional which would result in sadness and regret
        let reducedUnits = units.reduce(NSCalendarUnit()) { $0.union($1) }
        let comp1 = components(reducedUnits, fromDate: date1)!
        let comp2 = components(reducedUnits, fromDate: date2)!
    
        for unit in units {
            let value1 = comp1.valueForComponent(unit)
            let value2 = comp2.valueForComponent(unit)
            if value1 > value2 {
                return .OrderedDescending
            } else if value1 < value2 {
                return .OrderedAscending
            }
            if unit == .Month && calendarIdentifier == kCFCalendarIdentifierChinese._swiftObject {
                let leap1 = comp1.leapMonth
                let leap2 = comp2.leapMonth
                if !leap1 && leap2 {
                    return .OrderedAscending
                } else if leap1 && !leap2 {
                    return .OrderedDescending
                }
            }
            if unit == reducedUnits {
                return .OrderedSame
            }
        }
        return .OrderedSame
    }
    
    /*
    This API compares the given dates down to the given unit, reporting them equal if they are the same in the given unit and all larger units.
    */
    public func isDate(date1: NSDate, equalToDate date2: NSDate, toUnitGranularity unit: NSCalendarUnit) -> Bool {
        return compareDate(date1, toDate: date2, toUnitGranularity: unit) == .OrderedSame
    }
    
    /*
    This API compares the Days of the given dates, reporting them equal if they are in the same Day.
    */
    public func isDate(date1: NSDate, inSameDayAsDate date2: NSDate) -> Bool {
        return compareDate(date1, toDate: date2, toUnitGranularity: .Day) == .OrderedSame
    }
    
    /*
    This API reports if the date is within "today".
    */
    public func isDateInToday(date: NSDate) -> Bool {
        return compareDate(date, toDate: NSDate(), toUnitGranularity: .Day) == .OrderedSame
    }
    
    /*
    This API reports if the date is within "yesterday".
    */
    public func isDateInYesterday(date: NSDate) -> Bool {
        if let interval = rangeOfUnit(.Day, forDate: NSDate()) {
            let inYesterday = interval.start.dateByAddingTimeInterval(-60.0)
            return compareDate(date, toDate: inYesterday, toUnitGranularity: .Day) == .OrderedSame
        } else {
            return false
        }
    }
    
    /*
    This API reports if the date is within "tomorrow".
    */
    public func isDateInTomorrow(date: NSDate) -> Bool {
        if let interval = rangeOfUnit(.Day, forDate: NSDate()) {
            let inTomorrow = interval.end.dateByAddingTimeInterval(60.0)
            return compareDate(date, toDate: inTomorrow, toUnitGranularity: .Day) == .OrderedSame
        } else {
            return false
        }
    }
    
    /*
    This API reports if the date is within a weekend period, as defined by the calendar and calendar's locale.
    */
    public func isDateInWeekend(date: NSDate) -> Bool {
        return _CFCalendarIsWeekend(_cfObject, date.timeIntervalSinceReferenceDate)
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// public func rangeOfWeekendStartDate(datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, containingDate date: NSDate) -> Bool
    /// which is not implementable on Linux due to the lack of being able to properly implement AutoreleasingUnsafeMutablePointer.
    /// Find the range of the weekend around the given date, returned via two by-reference parameters.
    /// Returns nil if the given date is not in a weekend.
    /// - Note: A given entire Day within a calendar is not necessarily all in a weekend or not; weekends can start in the middle of a Day in some calendars and locales.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func rangeOfWeekendContaining(date: NSDate) -> NSDateInterval? {
        if let next = nextWeekendAfter(date, options: []) {
            if let prev = nextWeekendAfter(next.start, options: .SearchBackwards) {
                if prev.start.timeIntervalSinceReferenceDate <= date.timeIntervalSinceReferenceDate && date.timeIntervalSinceReferenceDate <= prev.end.timeIntervalSinceReferenceDate {
                    return prev
                }
            }
        }
        return nil
    }
    
    /// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer.
    /// The current exposed API in Foundation on Darwin platforms is:
    /// public func nextWeekendStartDate(datep: AutoreleasingUnsafeMutablePointer<NSDate?>, interval tip: UnsafeMutablePointer<NSTimeInterval>, options: NSCalendarOptions, afterDate date: NSDate) -> Bool
    /// Returns the range of the next weekend, via two by-reference parameters, which starts strictly after the given date.
    /// The .SearchBackwards option can be used to find the previous weekend range strictly before the date.
    /// Returns nil if there are no such things as weekend in the calendar and its locale.
    /// - Note: A given entire Day within a calendar is not necessarily all in a weekend or not; weekends can start in the middle of a Day in some calendars and locales.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func nextWeekendAfter(date: NSDate, options: NSCalendarOptions) -> NSDateInterval? {
        var range = _CFCalendarWeekendRange()
        let res = withUnsafeMutablePointer(&range) { rangep in
            return _CFCalendarGetNextWeekend(_cfObject, rangep)
        }
        if res {
            let comp = NSDateComponents()
            comp.weekday = range.start
            if let nextStart = nextDateAfterDate(date, matchingComponents: comp, options: options.union(.MatchNextTime)) {
                let start = nextStart.dateByAddingTimeInterval(range.onsetTime)
                comp.weekday = range.end
                if let nextEnd = nextDateAfterDate(date, matchingComponents: comp, options: options.union(.MatchNextTime)) {
                    var end = nextEnd
                    if end.compare(start) == .OrderedAscending {
                        if let nextOrderedEnd = nextDateAfterDate(end, matchingComponents: comp, options: options.union(.MatchNextTime)) {
                            end = nextOrderedEnd
                        } else {
                            return nil
                        }
                    }
                    if range.ceaseTime > 0 {
                        end = end.dateByAddingTimeInterval(range.ceaseTime)
                    } else {
                        if let dayEnd = rangeOfUnit(.Day, forDate: end) {
                            end = startOfDayForDate(dayEnd.end)
                        } else {
                            return nil
                        }
                    }
                    return NSDateInterval(start: start, end: end)
                }
            }
        }
        return nil
    }
    
    /*
    This API returns the difference between two dates specified as date components.
    For units which are not specified in each NSDateComponents, but required to specify an absolute date, the base value of the unit is assumed.  For example, for an NSDateComponents with just a Year and a Month specified, a Day of 1, and an Hour, Minute, Second, and Nanosecond of 0 are assumed.
    Calendrical calculations with unspecified Year or Year value prior to the start of a calendar are not advised.
    For each date components object, if its time zone property is set, that time zone is used for it; if the calendar property is set, that is used rather than the receiving calendar, and if both the calendar and time zone are set, the time zone property value overrides the time zone of the calendar property.
    No options are currently defined; pass 0.
    */
    public func components(unitFlags: NSCalendarUnit, fromDateComponents startingDateComp: NSDateComponents, toDateComponents resultDateComp: NSDateComponents, options: NSCalendarOptions) -> NSDateComponents? {
        var startDate: NSDate?
        var toDate: NSDate?
        if let startCalendar = startingDateComp.calendar {
            startDate = startCalendar.dateFromComponents(startingDateComp)
        } else {
            startDate = dateFromComponents(startingDateComp)
        }
        if let toCalendar = resultDateComp.calendar {
            toDate = toCalendar.dateFromComponents(resultDateComp)
        } else {
            toDate = dateFromComponents(resultDateComp)
        }
        if let start = startDate {
            if let end = toDate {
                return components(unitFlags, fromDate: start, toDate: end, options: options)
            }
        }
        return nil
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by adding an amount of a specific component to a given date.
    The NSCalendarWrapComponents option specifies if the component should be incremented and wrap around to zero/one on overflow, and should not cause higher units to be incremented.
    */
    public func dateByAddingUnit(unit: NSCalendarUnit, value: Int, toDate date: NSDate, options: NSCalendarOptions) -> NSDate? {
        let comps = NSDateComponents()
        comps.setValue(value, forComponent: unit)
        return dateByAddingComponents(comps, toDate: date, options: options)
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
    public func enumerateDatesStartingAfterDate(start: NSDate, matchingComponents comps: NSDateComponents, options opts: NSCalendarOptions, usingBlock block: (NSDate?, Bool, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    
    /*
    This method computes the next date which matches (or most closely matches) a given set of components.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    public func nextDateAfterDate(date: NSDate, matchingComponents comps: NSDateComponents, options: NSCalendarOptions) -> NSDate? {
        var result: NSDate?
        enumerateDatesStartingAfterDate(date, matchingComponents: comps, options: options) { date, exactMatch, stop in
            result = date
            stop.memory = true
        }
        return result
    }
    
    /*
    This API returns a new NSDate object representing the date found which matches a specific component value.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    public func nextDateAfterDate(date: NSDate, matchingUnit unit: NSCalendarUnit, value: Int, options: NSCalendarOptions) -> NSDate? {
        let comps = NSDateComponents()
        comps.setValue(value, forComponent: unit)
        return nextDateAfterDate(date, matchingComponents: comps, options: options)
    }
    
    /*
    This API returns a new NSDate object representing the date found which matches the given hour, minute, and second values.
    The general semantics follow those of the -enumerateDatesStartingAfterDate:... method above.
    To compute a sequence of results, use the -enumerateDatesStartingAfterDate:... method above, rather than looping and calling this method with the previous loop iteration's result.
    */
    public func nextDateAfterDate(date: NSDate, matchingHour hourValue: Int, minute minuteValue: Int, second secondValue: Int, options: NSCalendarOptions) -> NSDate? {
        let comps = NSDateComponents()
        comps.hour = hourValue
        comps.minute = minuteValue
        comps.second = secondValue
        return nextDateAfterDate(date, matchingComponents: comps, options: options)
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by setting a specific component to a given time, and trying to keep lower components the same.  If the unit already has that value, this may result in a date which is the same as the given date.
    Changing a component's value often will require higher or coupled components to change as well.  For example, setting the Weekday to Thursday usually will require the Day component to change its value, and possibly the Month and Year as well.
    If no such time exists, the next available time is returned (which could, for example, be in a different day, week, month, ... than the nominal target date).  Setting a component to something which would be inconsistent forces other units to change; for example, setting the Weekday to Thursday probably shifts the Day and possibly Month and Year.
    The specific behaviors here are as yet unspecified; for example, if I change the weekday to Thursday, does that move forward to the next, backward to the previous, or to the nearest Thursday?  A likely rule is that the algorithm will try to produce a result which is in the next-larger unit to the one given (there's a table of this mapping at the top of this document).  So for the "set to Thursday" example, find the Thursday in the Week in which the given date resides (which could be a forwards or backwards move, and not necessarily the nearest Thursday).  For forwards or backwards behavior, one can use the -nextDateAfterDate:matchingUnit:value:options: method above.
    */
    public func dateBySettingUnit(unit: NSCalendarUnit, value v: Int, ofDate date: NSDate, options opts: NSCalendarOptions) -> NSDate? {
        let currentValue = component(unit, fromDate: date)
        if currentValue == v {
            return date
        }
        let targetComp = NSDateComponents()
        targetComp.setValue(v, forComponent: unit)
        var result: NSDate?
        enumerateDatesStartingAfterDate(date, matchingComponents: targetComp, options: .MatchNextTime) { date, match, stop in
            result = date
            stop.memory = true
        }
        return result
    }
    
    /*
    This API returns a new NSDate object representing the date calculated by setting hour, minute, and second to a given time.
    If no such time exists, the next available time is returned (which could, for example, be in a different day than the nominal target date).
    The intent is to return a date on the same day as the original date argument.  This may result in a date which is earlier than the given date, of course.
    */
    public func dateBySettingHour(h: Int, minute m: Int, second s: Int, ofDate date: NSDate, options opts: NSCalendarOptions) -> NSDate? {
        if let range = rangeOfUnit(.Day, forDate: date) {
            let comps = NSDateComponents()
            comps.hour = h
            comps.minute = m
            comps.second = s
            var options: NSCalendarOptions = .MatchNextTime
            options.unionInPlace(opts.contains(.MatchLast) ? .MatchLast : .MatchFirst)
            if opts.contains(.MatchStrictly) {
                options.unionInPlace(.MatchStrictly)
            }
            if let result = nextDateAfterDate(range.start.dateByAddingTimeInterval(-0.5), matchingComponents: comps, options: options) {
                if result.compare(range.start) == .OrderedAscending {
                    return nextDateAfterDate(range.start, matchingComponents: comps, options: options)
                }
                return result
            }
            
        }
        return nil
    }
    
    /*
    This API returns YES if the date has all the matched components. Otherwise, it returns NO.
    It is useful to test the return value of the -nextDateAfterDate:matchingUnit:value:options:, to find out if the components were obeyed or if the method had to fudge the result value due to missing time.
    */
    public func date(date: NSDate, matchesComponents components: NSDateComponents) -> Bool {
        let units: [NSCalendarUnit] = [.Era, .Year, .Month, .Day, .Hour, .Minute, .Second, .Weekday, .WeekdayOrdinal, .Quarter, .WeekOfMonth, .WeekOfYear, .YearForWeekOfYear, .Nanosecond]
        var unitFlags: NSCalendarUnit = []
        for unit in units {
            if components.valueForComponent(unit) != NSDateComponentUndefined {
                unitFlags.unionInPlace(unit)
            }
        }
        if unitFlags == [] {
            if components.leapMonthSet {
                if let comp = self.components(.Month, fromDate: date) {
                    return comp.leapMonth
                }
                return false
            }
        }
        if let comp = self.components(unitFlags, fromDate: date) {
            let tempComp = components.copy() as! NSDateComponents
            if comp.leapMonthSet && !components.leapMonthSet {
                tempComp.leapMonth = comp.leapMonth
            }
            let nanosecond = comp.valueForComponent(.Nanosecond)
            if nanosecond != NSDateComponentUndefined {
                if labs(nanosecond - tempComp.valueForComponent(.Nanosecond)) > 500 {
                    return false
                } else {
                    comp.nanosecond = 0
                    tempComp.nanosecond = 0
                }
                return tempComp.isEqual(comp)
            }
        }
        return false
    }
    
}

// This notification is posted through [NSNotificationCenter defaultCenter]
// when the system day changes. Register with "nil" as the object of this
// notification. If the computer/device is asleep when the day changed,
// this will be posted on wakeup. You'll get just one of these if the
// machine has been asleep for several days. The definition of "Day" is
// relative to the current calendar ([NSCalendar currentCalendar]) of the
// process and its locale and time zone. There are no guarantees that this
// notification is received by observers in a "timely" manner, same as
// with distributed notifications.

public let NSCalendarDayChangedNotification: String = "" // NSUnimplemented

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

public var NSDateComponentUndefined: Int = LONG_MAX

public class NSDateComponents : NSObject, NSCopying, NSSecureCoding {
    internal var _calendar: NSCalendar?
    internal var _timeZone: NSTimeZone?
    internal var _values = [Int](count: 19, repeatedValue: NSDateComponentUndefined)
    public override init() {
        super.init()
    }
    
    public override var hash: Int {
        var calHash = 0
        if let cal = calendar {
            calHash = cal.hash
        }
        if let tz = timeZone {
            calHash ^= tz.hash
        }
        var y = year
        if NSDateComponentUndefined == y {
            y = 0
        }
        var m = month
        if NSDateComponentUndefined == m {
            m = 0
        }
        var d = day
        if NSDateComponentUndefined == d {
            d = 0
        }
        var h = hour
        if NSDateComponentUndefined == h {
            h = 0
        }
        var mm = minute
        if NSDateComponentUndefined == mm {
            mm = 0 
        }
        var s = second
        if NSDateComponentUndefined == s {
            s = 0 
        }
        var yy = yearForWeekOfYear
        if NSDateComponentUndefined == yy {
            yy = 0
        }
        return calHash + (32832013 * (y + yy) + 2678437 * m + 86413 * d + 3607 * h + 61 * mm + s) + (41 * weekOfYear + 11 * weekOfMonth + 7 * weekday + 3 * weekdayOrdinal + quarter) * (1 << 5)
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? NSDateComponents {
            if era != other.era {
                return false
            }
            if year != other.year {
                return false
            }
            if quarter != other.quarter {
                return false
            }
            if month != other.month {
                return false
            }
            if day != other.day {
                return false
            }
            if hour != other.hour {
                return false
            }
            if minute != other.minute {
                return false
            }
            if second != other.second {
                return false
            }
            if nanosecond != other.nanosecond {
                return false
            }
            if weekOfYear != other.weekOfYear {
                return false
            }
            if weekOfMonth != other.weekOfMonth {
                return false
            }
            if yearForWeekOfYear != other.yearForWeekOfYear {
                return false
            }
            if weekday != other.weekday {
                return false
            }
            if weekdayOrdinal != other.weekdayOrdinal {
                return false
            }
            if leapMonth != other.leapMonth {
                return false
            }
            if calendar != other.calendar {
                return false
            }
            if timeZone != other.timeZone {
                return false
            }
            return true
        }
        return false
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            self.init()
            
            self.era = aDecoder.decodeIntegerForKey("NS.era")
            self.year = aDecoder.decodeIntegerForKey("NS.year")
            self.quarter = aDecoder.decodeIntegerForKey("NS.quarter")
            self.month = aDecoder.decodeIntegerForKey("NS.month")
            self.day = aDecoder.decodeIntegerForKey("NS.day")
            self.hour = aDecoder.decodeIntegerForKey("NS.hour")
            self.minute = aDecoder.decodeIntegerForKey("NS.minute")
            self.second = aDecoder.decodeIntegerForKey("NS.second")
            self.nanosecond = aDecoder.decodeIntegerForKey("NS.nanosec")
            self.weekOfYear = aDecoder.decodeIntegerForKey("NS.weekOfYear")
            self.weekOfMonth = aDecoder.decodeIntegerForKey("NS.weekOfMonth")
            self.yearForWeekOfYear = aDecoder.decodeIntegerForKey("NS.yearForWOY")
            self.weekday = aDecoder.decodeIntegerForKey("NS.weekday")
            self.weekdayOrdinal = aDecoder.decodeIntegerForKey("NS.weekdayOrdinal")
            self.leapMonth = aDecoder.decodeBoolForKey("NS.leapMonth")
            self.calendar = aDecoder.decodeObjectOfClass(NSCalendar.self, forKey: "NS.calendar")
            self.timeZone = aDecoder.decodeObjectOfClass(NSTimeZone.self, forKey: "NS.timezone")
        } else {
            NSUnimplemented()
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeInteger(self.era, forKey: "NS.era")
            aCoder.encodeInteger(self.year, forKey: "NS.year")
            aCoder.encodeInteger(self.quarter, forKey: "NS.quarter")
            aCoder.encodeInteger(self.month, forKey: "NS.month")
            aCoder.encodeInteger(self.day, forKey: "NS.day")
            aCoder.encodeInteger(self.hour, forKey: "NS.hour")
            aCoder.encodeInteger(self.minute, forKey: "NS.minute")
            aCoder.encodeInteger(self.second, forKey: "NS.second")
            aCoder.encodeInteger(self.nanosecond, forKey: "NS.nanosec")
            aCoder.encodeInteger(self.weekOfYear, forKey: "NS.weekOfYear")
            aCoder.encodeInteger(self.weekOfMonth, forKey: "NS.weekOfMonth")
            aCoder.encodeInteger(self.yearForWeekOfYear, forKey: "NS.yearForWOY")
            aCoder.encodeInteger(self.weekday, forKey: "NS.weekday")
            aCoder.encodeInteger(self.weekdayOrdinal, forKey: "NS.weekdayOrdinal")
            aCoder.encodeBool(self.leapMonth, forKey: "NS.leapMonth")
            aCoder.encodeObject(self.calendar, forKey: "NS.calendar")
            aCoder.encodeObject(self.timeZone, forKey: "NS.timezone")
        } else {
            NSUnimplemented()
        }
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ public var calendar: NSCalendar? {
        get {
            return _calendar
        }
        set {
            if let val = newValue {
                _calendar = (val.copy() as! NSCalendar)
            } else {
                _calendar = nil
            }
        }
    }
    /*@NSCopying*/ public var timeZone: NSTimeZone? {
        get {
            return _timeZone
        }
        set {
            if let val = newValue {
                _timeZone = (val.copy() as! NSTimeZone)
            } else {
                _timeZone = nil
            }
        }
    }
    // these all should probably be optionals
    
    public var era: Int {
        get {
            return _values[0]
        }
        set {
            _values[0] = newValue
        }
    }
    
    public var year: Int {
        get {
            return _values[1]
        }
        set {
            _values[1] = newValue
        }
    }
    
    public var month: Int {
        get {
            return _values[2]
        }
        set {
            _values[2] = newValue
        }
    }
    
    public var day: Int {
        get {
            return _values[3]
        }
        set {
            _values[3] = newValue
        }
    }
    
    public var hour: Int {
        get {
            return _values[4]
        }
        set {
            _values[4] = newValue
        }
    }
    
    public var minute: Int {
        get {
            return _values[5]
        }
        set {
            _values[5] = newValue
        }
    }
    
    public var second: Int {
        get {
            return _values[6]
        }
        set {
            _values[6] = newValue
        }
    }
    
    public var weekday: Int {
        get {
            return _values[8]
        }
        set {
            _values[8] = newValue
        }
    }
    
    public var weekdayOrdinal: Int {
        get {
            return _values[9]
        }
        set {
            _values[9] = newValue
        }
    }
    
    public var quarter: Int {
        get {
            return _values[10]
        }
        set {
            _values[10] = newValue
        }
    }
    
    public var nanosecond: Int {
        get {
            return _values[11]
        }
        set {
            _values[11] = newValue
        }
    }
    
    public var weekOfYear: Int {
        get {
            return _values[12]
        }
        set {
            _values[12] = newValue
        }
    }
    
    public var weekOfMonth: Int {
        get {
            return _values[13]
        }
        set {
            _values[13] = newValue
        }
    }
    
    public var yearForWeekOfYear: Int {
        get {
            return _values[14]
        }
        set {
            _values[14] = newValue
        }
    }
    
    public var leapMonth: Bool {
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
    
    /*@NSCopying*/ public var date: NSDate? {
        if let tz = timeZone {
            calendar?.timeZone = tz
        }
        return calendar?.dateFromComponents(self)
    }
    
    /*
    This API allows one to set a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth properties cannot be set by this method.
    */
    public func setValue(value: Int, forComponent unit: NSCalendarUnit) {
        switch unit {
            case NSCalendarUnit.Era:
                era = value
                break
            case NSCalendarUnit.Year:
                year = value
                break
            case NSCalendarUnit.Month:
                month = value
                break
            case NSCalendarUnit.Day:
                day = value
                break
            case NSCalendarUnit.Hour:
                hour = value
                break
            case NSCalendarUnit.Minute:
                minute = value
                break
            case NSCalendarUnit.Second:
                second = value
                break
            case NSCalendarUnit.Nanosecond:
                nanosecond = value
                break
            case NSCalendarUnit.Weekday:
                weekday = value
                break
            case NSCalendarUnit.WeekdayOrdinal:
                weekdayOrdinal = value
                break
            case NSCalendarUnit.Quarter:
                quarter = value
                break
            case NSCalendarUnit.WeekOfMonth:
                weekOfMonth = value
                break
            case NSCalendarUnit.WeekOfYear:
                weekOfYear = value
                break
            case NSCalendarUnit.YearForWeekOfYear:
                yearForWeekOfYear = value
                break
            case NSCalendarUnit.Calendar:
                print(".Calendar cannot be set via \(__FUNCTION__)")
                break
            case NSCalendarUnit.TimeZone:
                print(".TimeZone cannot be set via \(__FUNCTION__)")
                break
            default:
                break
        }
    }
    
    /*
    This API allows one to get the value of a specific component of NSDateComponents, by enum constant value rather than property name.
    The calendar and timeZone and isLeapMonth property values cannot be gotten by this method.
    */
    public func valueForComponent(unit: NSCalendarUnit) -> Int {
        switch unit {
            case NSCalendarUnit.Era:
                return era
            case NSCalendarUnit.Year:
                return year
            case NSCalendarUnit.Month:
                return month
            case NSCalendarUnit.Day:
                return day
            case NSCalendarUnit.Hour:
                return hour
            case NSCalendarUnit.Minute:
                return minute
            case NSCalendarUnit.Second:
                return second
            case NSCalendarUnit.Nanosecond:
                return nanosecond
            case NSCalendarUnit.Weekday:
                return weekday
            case NSCalendarUnit.WeekdayOrdinal:
                return weekdayOrdinal
            case NSCalendarUnit.Quarter:
                return quarter
            case NSCalendarUnit.WeekOfMonth:
                return weekOfMonth
            case NSCalendarUnit.WeekOfYear:
                return weekOfYear
            case NSCalendarUnit.YearForWeekOfYear:
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
    public var validDate: Bool {
        if let cal = calendar {
            return isValidDateInCalendar(cal)
        }
        return false
    }
    
    /*
    Reports whether or not the combination of properties which have been set in the receiver is a date which exists in the calendar.
    This method is not appropriate for use on NSDateComponents objects which are specifying relative quantities of calendar components.
    Except for some trivial cases (e.g., 'seconds' should be 0 - 59 in any calendar), this method is not necessarily cheap.
    If the time zone property is set in the NSDateComponents object, it is used.
    */
    public func isValidDateInCalendar(calendar: NSCalendar) -> Bool {
        let cal = calendar.copy() as! NSCalendar
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
        let d = calendar.dateFromComponents(self)
        if ns != NSDateComponentUndefined && 0 < ns {
            nanosecond = ns
        }
        if let date = d {
            let all: NSCalendarUnit = [.Era, .Year, .Month, .Day, .Hour, .Minute, .Second, .Weekday, .WeekdayOrdinal, .Quarter, .WeekOfMonth, .WeekOfYear, .YearForWeekOfYear]
            if let comps = calendar.components(all, fromDate: date) {
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
                    if comps.leapMonth != leapMonth {
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
        }
        return false
    }
}

extension NSCalendar : _CFBridgable { }

extension CFCalendarRef : _NSBridgable {
    typealias NSType = NSCalendar
    internal var _nsObject: NSType { return unsafeBitCast(self, NSType.self) }
}

