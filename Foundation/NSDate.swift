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
    import Darwin
    #elseif os(Linux)
    import Glibc
#endif

public typealias NSTimeInterval = Double

public var NSTimeIntervalSince1970: Double {
    return 978307200.0
}

public class NSDate : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFDateRef
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let date = object as? NSDate {
            return isEqualToDate(date)
        } else {
            return false
        }
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    internal let _base = _CFInfo(typeID: CFDateGetTypeID())
    internal let _timeIntervalSinceReferenceDate: NSTimeInterval
    
    public var timeIntervalSinceReferenceDate: NSTimeInterval {
        return _timeIntervalSinceReferenceDate
    }
    
    public convenience override init() {
        var tv = timeval()
        withUnsafeMutablePointer(&tv) { t in
            gettimeofday(t, nil)
        }
        var timestamp = NSTimeInterval(tv.tv_sec) - NSTimeIntervalSince1970
        timestamp += NSTimeInterval(tv.tv_usec) / 1000000.0
        self.init(timeIntervalSinceReferenceDate: timestamp)
    }
    
    public required init(timeIntervalSinceReferenceDate ti: NSTimeInterval) {
        _timeIntervalSinceReferenceDate = ti
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            let ti = aDecoder.decodeDoubleForKey("NS.time")
            self.init(timeIntervalSinceReferenceDate: ti)
        } else {
            var ti: NSTimeInterval = 0.0
            withUnsafeMutablePointer(&ti) { (ptr: UnsafeMutablePointer<Double>) -> Void in
                aDecoder.decodeValueOfObjCType("d", at: UnsafeMutablePointer<Void>(ptr))
            }
            self.init(timeIntervalSinceReferenceDate: ti)
        }
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }

    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
	if aCoder.allowsKeyedCoding {
	    aCoder.encodeDouble(_timeIntervalSinceReferenceDate, forKey: "NS.time")
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
    public func descriptionWithLocale(locale: AnyObject?) -> String {
        guard let aLocale = locale else { return description }
        let dateFormatterRef = CFDateFormatterCreate(kCFAllocatorSystemDefault, (aLocale as! NSLocale)._cfObject, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle)
        CFDateFormatterSetProperty(dateFormatterRef, kCFDateFormatterTimeZoneKey, CFTimeZoneCopySystem())

        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, dateFormatterRef, _cfObject)._swiftObject
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFDateGetTypeID()
    }
}

extension NSDate {
    
    public func timeIntervalSinceDate(anotherDate: NSDate) -> NSTimeInterval {
        return self.timeIntervalSinceReferenceDate - anotherDate.timeIntervalSinceReferenceDate
    }
    
    public var timeIntervalSinceNow: NSTimeInterval {
        return timeIntervalSinceDate(NSDate())
    }
    
    public var timeIntervalSince1970: NSTimeInterval {
        return timeIntervalSinceReferenceDate + NSTimeIntervalSince1970
    }
    
    public func dateByAddingTimeInterval(ti: NSTimeInterval) -> NSDate {
        return NSDate(timeIntervalSinceReferenceDate:_timeIntervalSinceReferenceDate + ti)
    }
    
    public func earlierDate(anotherDate: NSDate) -> NSDate {
        if self.timeIntervalSinceReferenceDate < anotherDate.timeIntervalSinceReferenceDate {
            return self
        } else {
            return anotherDate
        }
    }
    
    public func laterDate(anotherDate: NSDate) -> NSDate {
        if self.timeIntervalSinceReferenceDate < anotherDate.timeIntervalSinceReferenceDate {
            return anotherDate
        } else {
            return self
        }
    }
    
    public func compare(other: NSDate) -> NSComparisonResult {
        let t1 = self.timeIntervalSinceReferenceDate
        let t2 = other.timeIntervalSinceReferenceDate
        if t1 < t2 {
            return .OrderedAscending
        } else if t1 > t2 {
            return .OrderedDescending
        } else {
            return .OrderedSame
        }
    }
    
    public func isEqualToDate(otherDate: NSDate) -> Bool {
        return timeIntervalSinceReferenceDate == otherDate.timeIntervalSinceReferenceDate
    }
}

extension NSDate {
    internal static let _distantFuture = NSDate(timeIntervalSinceReferenceDate: 63113904000.0)
    public class func distantFuture() -> NSDate {
        return _distantFuture
    }
    
    internal static let _distantPast = NSDate(timeIntervalSinceReferenceDate: -63113904000.0)
    public class func distantPast() -> NSDate {
        return _distantPast
    }
    
    public convenience init(timeIntervalSinceNow secs: NSTimeInterval) {
        self.init(timeIntervalSinceReferenceDate: secs + NSDate().timeIntervalSinceReferenceDate)
    }
    
    public convenience init(timeIntervalSince1970 secs: NSTimeInterval) {
        self.init(timeIntervalSinceReferenceDate: secs - NSTimeIntervalSince1970)
    }
    
    public convenience init(timeInterval secsToBeAdded: NSTimeInterval, sinceDate date: NSDate) {
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate + secsToBeAdded)
    }
}

extension NSDate : _CFBridgable { }

extension CFDateRef : _NSBridgable {
    typealias NSType = NSDate
    internal var _nsObject: NSType { return unsafeBitCast(self, NSType.self) }
}

/// Alternative API for avoiding AutoreleasingUnsafeMutablePointer usage in NSCalendar and NSFormatter
/// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to the AutoreleasingUnsafeMutablePointer usage case of returning a NSDate + NSTimeInterval or using a pair of dates representing a range
/// - Note: Since this API is under consideration it may be either removed or revised in the near future
public class NSDateInterval : NSObject {
    public internal(set) var start: NSDate
    public internal(set) var end: NSDate
    
    public var interval: NSTimeInterval {
        return end.timeIntervalSinceReferenceDate - start.timeIntervalSinceReferenceDate
    }
    
    public required init(start: NSDate, end: NSDate) {
        self.start = start
        self.end = end
    }
    
    public convenience init(start: NSDate, interval: NSTimeInterval) {
        self.init(start: start, end: NSDate(timeInterval: interval, sinceDate: start))
    }
}

