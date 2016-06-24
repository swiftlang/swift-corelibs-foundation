// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public typealias TimeInterval = Double

public var NSTimeIntervalSince1970: Double {
    return 978307200.0
}

public class NSDate : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFDate
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let date = object as? Date {
            return isEqual(to: date)
        } else {
            return false
        }
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    internal let _base = _CFInfo(typeID: CFDateGetTypeID())
    internal let _timeIntervalSinceReferenceDate: TimeInterval
    
    public var timeIntervalSinceReferenceDate: TimeInterval {
        return _timeIntervalSinceReferenceDate
    }

    public convenience override init() {
        var tv = timeval()
        let _ = withUnsafeMutablePointer(&tv) { t in
            gettimeofday(t, nil)
        }
        var timestamp = TimeInterval(tv.tv_sec) - NSTimeIntervalSince1970
        timestamp += TimeInterval(tv.tv_usec) / 1000000.0
        self.init(timeIntervalSinceReferenceDate: timestamp)
    }

    public required init(timeIntervalSinceReferenceDate ti: TimeInterval) {
        _timeIntervalSinceReferenceDate = ti
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            let ti = aDecoder.decodeDouble(forKey: "NS.time")
            self.init(timeIntervalSinceReferenceDate: ti)
        } else {
            var ti: TimeInterval = 0.0
            withUnsafeMutablePointer(&ti) { (ptr: UnsafeMutablePointer<Double>) -> Void in
                aDecoder.decodeValue(ofObjCType: "d", at: UnsafeMutablePointer<Void>(ptr))
            }
            self.init(timeIntervalSinceReferenceDate: ti)
        }
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }

    public func copy(with zone: NSZone? = nil) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encode(with aCoder: NSCoder) {
	if aCoder.allowsKeyedCoding {
	    aCoder.encode(_timeIntervalSinceReferenceDate, forKey: "NS.time")
	} else {
	    NSUnimplemented()
	}
    }

    /**
     A string representation of the date object (read-only).

     The representation is useful for debugging only.

     There are a number of options to acquire a formatted string for a date
     including: date formatters (see
     [NSDateFormatter](//apple_ref/occ/cl/NSDateFormatter) and
     [Data Formatting Guide](//apple_ref/doc/uid/10000029i)),
     and the `NSDate` methods `descriptionWithLocale:`,
     `dateWithCalendarFormat:timeZone:`, and
     `descriptionWithCalendarFormat:timeZone:locale:`.
     */
    public override var description: String {
        let dateFormatterRef = CFDateFormatterCreate(kCFAllocatorSystemDefault, nil, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle)
        let timeZone = CFTimeZoneCreateWithTimeIntervalFromGMT(kCFAllocatorSystemDefault, 0.0)
        CFDateFormatterSetProperty(dateFormatterRef, kCFDateFormatterTimeZoneKey, timeZone)
        CFDateFormatterSetFormat(dateFormatterRef, "uuuu-MM-dd HH:mm:ss '+0000'"._cfObject)

        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, dateFormatterRef, _cfObject)._swiftObject
    }

    /**
     Returns a string representation of the receiver using the given locale.

     - Parameter locale: An `NSLocale` object.

       If you pass `nil`, `NSDate` formats the date in the same way as the
       `description` property.

     - Returns: A string representation of the receiver, using the given locale,
       or if the locale argument is `nil`, in the international format
       `YYYY-MM-DD HH:MM:SS ±HHMM`, where `±HHMM` represents the time zone
       offset in hours and minutes from UTC (for example,
       "2001-03-24 10:45:32 +0600")
     */
    public func descriptionWithLocale(_ locale: AnyObject?) -> String {
        guard let aLocale = locale else { return description }
        let dateFormatterRef = CFDateFormatterCreate(kCFAllocatorSystemDefault, (aLocale as! Locale)._cfObject, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle)
        CFDateFormatterSetProperty(dateFormatterRef, kCFDateFormatterTimeZoneKey, CFTimeZoneCopySystem())

        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, dateFormatterRef, _cfObject)._swiftObject
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFDateGetTypeID()
    }
}

extension NSDate {
    
    public func timeIntervalSince(_ anotherDate: Date) -> TimeInterval {
        return self.timeIntervalSinceReferenceDate - anotherDate.timeIntervalSinceReferenceDate
    }
    
    public var timeIntervalSinceNow: TimeInterval {
        return timeIntervalSince(Date())
    }
    
    public var timeIntervalSince1970: TimeInterval {
        return timeIntervalSinceReferenceDate + NSTimeIntervalSince1970
    }
    
    public func addingTimeInterval(_ ti: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate:_timeIntervalSinceReferenceDate + ti)
    }
    
    public func earlierDate(_ anotherDate: Date) -> Date {
        if self.timeIntervalSinceReferenceDate < anotherDate.timeIntervalSinceReferenceDate {
            return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate)
        } else {
            return anotherDate
        }
    }
    
    public func laterDate(_ anotherDate: Date) -> Date {
        if self.timeIntervalSinceReferenceDate < anotherDate.timeIntervalSinceReferenceDate {
            return anotherDate
        } else {
            return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate)
        }
    }
    
    public func compare(_ other: Date) -> ComparisonResult {
        let t1 = self.timeIntervalSinceReferenceDate
        let t2 = other.timeIntervalSinceReferenceDate
        if t1 < t2 {
            return .orderedAscending
        } else if t1 > t2 {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    public func isEqual(to otherDate: Date) -> Bool {
        return timeIntervalSinceReferenceDate == otherDate.timeIntervalSinceReferenceDate
    }
}

extension NSDate {
    internal static let _distantFuture = Date(timeIntervalSinceReferenceDate: 63113904000.0)
    public static func distantFuture() -> Date {
        return _distantFuture
    }
    
    internal static let _distantPast = Date(timeIntervalSinceReferenceDate: -63113904000.0)
    public static func distantPast() -> Date {
        return _distantPast
    }
    
    public convenience init(timeIntervalSinceNow secs: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: secs + Date().timeIntervalSinceReferenceDate)
    }
    
    public convenience init(timeIntervalSince1970 secs: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: secs - NSTimeIntervalSince1970)
    }
    
    public convenience init(timeInterval secsToBeAdded: TimeInterval, sinceDate date: Date) {
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate + secsToBeAdded)
    }
}

extension NSDate: _CFBridgable, _SwiftBridgable {
    typealias SwiftType = Date
    var _swiftObject: Date {
        return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate)
    }
}

extension CFDate : _NSBridgable, _SwiftBridgable {
    typealias NSType = NSDate
    typealias SwiftType = Date
    
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
    internal var _swiftObject: Date { return _nsObject._swiftObject }
}

extension Date : _NSBridgable, _CFBridgable {
    typealias NSType = NSDate
    typealias CFType = CFDate
    
    internal var _nsObject: NSType { return NSDate(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate) }
    internal var _cfObject: CFType { return _nsObject._cfObject }
}


public class NSDateInterval : NSObject, NSCopying, NSSecureCoding {
    
    
    /*
     NSDateInterval represents a closed date interval in the form of [startDate, endDate].  It is possible for the start and end dates to be the same with a duration of 0.  NSDateInterval does not support reverse intervals i.e. intervals where the duration is less than 0 and the end date occurs earlier in time than the start date.
     */
    
    public private(set) var startDate: Date
    
    public var endDate: Date {
        get {
            if duration == 0 {
                return startDate
            } else {
                return startDate + duration
            }
        }
    }
    
    public private(set) var duration: TimeInterval
    
    
    // This method initializes an NSDateInterval object with start and end dates set to the current date and the duration set to 0.
    public convenience override init() {
        self.init(start: Date(), duration: 0)
    }
    
    
    public required convenience init?(coder: NSCoder) {
        precondition(coder.allowsKeyedCoding)
        guard let start = coder.decodeObjectOfClass(NSDate.self, forKey: "NS.startDate") else {
            coder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.CoderValueNotFoundError.rawValue, userInfo: nil))
            return nil
        }
        guard let end = coder.decodeObjectOfClass(NSDate.self, forKey: "NS.startDate") else {
            coder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.CoderValueNotFoundError.rawValue, userInfo: nil))
            return nil
        }
        self.init(start: start._swiftObject, end: end._swiftObject)
    }
    
    
    // This method will throw an exception if the duration is less than 0.
    public init(start startDate: Date, duration: TimeInterval) {
        self.startDate = startDate
        self.duration = duration
    }
    
    
    // This method will throw an exception if the end date comes before the start date.
    public convenience init(start startDate: Date, end endDate: Date) {
        self.init(start: startDate, duration: endDate.timeIntervalSince(startDate))
    }
    
    public func copy(with zone: NSZone?) -> AnyObject {
        return NSDateInterval(start: startDate, duration: duration)
    }
    
    public func encode(with aCoder: NSCoder) {
        precondition(aCoder.allowsKeyedCoding)
        aCoder.encode(startDate._nsObject, forKey: "NS.startDate")
        aCoder.encode(endDate._nsObject, forKey: "NS.endDate")
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    /*
     (ComparisonResult)compare:(NSDateInterval *) prioritizes ordering by start date. If the start dates are equal, then it will order by duration.
     e.g.
     Given intervals a and b
     a.   |-----|
     b.      |-----|
     [a compare:b] would return NSOrderAscending because a's startDate is earlier in time than b's start date.
     
     In the event that the start dates are equal, the compare method will attempt to order by duration.
     e.g.
     Given intervals c and d
     c.  |-----|
     d.  |---|
     [c compare:d] would result in NSOrderDescending because c is longer than d.
     
     If both the start dates and the durations are equal, then the intervals are considered equal and NSOrderedSame is returned as the result.
     */
    public func compare(_ dateInterval: DateInterval) -> ComparisonResult {
        let result = startDate.compare(dateInterval.start)
        if result == .orderedSame {
            if self.duration < dateInterval.duration { return .orderedAscending }
            if self.duration > dateInterval.duration { return .orderedDescending }
            return .orderedSame
        }
        return result
    }
    
    
    public func isEqual(to dateInterval: DateInterval) -> Bool {
        return startDate == dateInterval.start && duration == dateInterval.duration
    }
    
    public func intersects(_ dateInterval: DateInterval) -> Bool {
        return contains(dateInterval.start) || contains(dateInterval.end) || dateInterval.contains(startDate) || dateInterval.contains(endDate)
    }
    
    
    /*
     This method returns an NSDateInterval object that represents the interval where the given date interval and the current instance intersect. In the event that there is no intersection, the method returns nil.
     */
    public func intersection(with dateInterval: DateInterval) -> DateInterval? {
        if !intersects(dateInterval) {
            return nil
        }
        
        if isEqual(to: dateInterval) {
            return DateInterval(start: startDate, duration: duration)
        }
        
        let timeIntervalForSelfStart = startDate.timeIntervalSinceReferenceDate
        let timeIntervalForSelfEnd = startDate.timeIntervalSinceReferenceDate
        let timeIntervalForGivenStart = dateInterval.start.timeIntervalSinceReferenceDate
        let timeIntervalForGivenEnd = dateInterval.end.timeIntervalSinceReferenceDate
        
        let resultStartDate : Date
        if timeIntervalForGivenStart >= timeIntervalForSelfStart {
            resultStartDate = dateInterval.start
        } else {
            // self starts after given
            resultStartDate = startDate
        }
        
        let resultEndDate : Date
        if timeIntervalForGivenEnd >= timeIntervalForSelfEnd {
            resultEndDate = endDate
        } else {
            // given ends before self
            resultEndDate = dateInterval.end
        }
        
        return DateInterval(start: resultStartDate, end: resultEndDate)
    }
    
    
    public func contains(_ date: Date) -> Bool {
        let timeIntervalForGivenDate = date.timeIntervalSinceReferenceDate
        let timeIntervalForSelfStart = startDate.timeIntervalSinceReferenceDate
        let timeIntervalforSelfEnd = endDate.timeIntervalSinceReferenceDate
        if (timeIntervalForGivenDate >= timeIntervalForSelfStart) && (timeIntervalForGivenDate <= timeIntervalforSelfEnd) {
            return true
        }
        return false
    }
}
