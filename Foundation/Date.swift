//
//  Date.swift
//  Foundation
//
//  Created by Philippe Hausler on 5/13/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import CoreFoundation

/**
 `Date` structs represent a single point in time.
 */
public struct Date : ReferenceConvertible, Comparable, Equatable, CustomStringConvertible {
    public typealias ReferenceType = NSDate
    
    private var _time : TimeInterval
    
    /// The number of seconds from 1 January 1970 to the reference date, 1 January 2001.
    public static let timeIntervalBetween1970AndReferenceDate = 978307200.0
    
    /// The interval between 00:00:00 UTC on 1 January 2001 and the current date and time.
    public static var timeIntervalSinceReferenceDate : TimeInterval {
        return CFAbsoluteTimeGetCurrent()
    }
    
    /// Returns a `Date` initialized to the current date and time.
    public init() {
        _time = CFAbsoluteTimeGetCurrent()
    }
    
    /// Returns a `Date` initialized relative to the current date and time by a given number of seconds.
    public init(timeIntervalSinceNow: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeIntervalSinceNow + CFAbsoluteTimeGetCurrent())
    }
    
    /// Returns a `Date` initialized relative to 00:00:00 UTC on 1 January 1970 by a given number of seconds.
    public init(timeIntervalSince1970: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeIntervalSince1970 - Date.timeIntervalBetween1970AndReferenceDate)
    }
    
    /**
     Returns a `Date` initialized relative to another given date by a given number of seconds.
     
     - Parameter timeInterval: The number of seconds to add to `date`. A negative value means the receiver will be earlier than `date`.
     - Parameter date: The reference date.
     */
    public init(timeInterval: TimeInterval, since date: Date) {
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate + timeInterval)
    }
    
    /// Returns a `Date` initialized relative to 00:00:00 UTC on 1 January 2001 by a given number of seconds.
    public init(timeIntervalSinceReferenceDate ti: TimeInterval) {
        _time = ti
    }
    
    /// Returns a `Date` initialized with the value from a `NSDate`. `Date` does not store the reference after initialization.
    private init(reference: NSDate) {
        self.init(timeIntervalSinceReferenceDate: reference.timeIntervalSinceReferenceDate)
    }
    
    private var reference : NSDate {
        return NSDate(timeIntervalSinceReferenceDate: _time)
    }
    
    /**
     Returns the interval between the date object and 00:00:00 UTC on 1 January 2001.
     
     This property’s value is negative if the date object is earlier than the system’s absolute reference date (00:00:00 UTC on 1 January 2001).
     */
    public var timeIntervalSinceReferenceDate: TimeInterval {
        return _time
    }
    
    /**
     Returns the interval between the receiver and another given date.
     
     - Parameter another: The date with which to compare the receiver.
     
     - Returns: The interval between the receiver and the `another` parameter. If the receiver is earlier than `anotherDate`, the return value is negative. If `anotherDate` is `nil`, the results are undefined.
     
     - SeeAlso: `timeIntervalSince1970`
     - SeeAlso: `timeIntervalSinceNow`
     - SeeAlso: `timeIntervalSinceReferenceDate`
     */
    public func timeIntervalSince(_ date: Date) -> TimeInterval {
        return self.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate
    }
    
    /**
     The time interval between the date and the current date and time.
     
     If the date is earlier than the current date and time, this property’s value is negative.
     
     - SeeAlso: `timeIntervalSince(_:)`
     - SeeAlso: `timeIntervalSince1970`
     - SeeAlso: `timeIntervalSinceReferenceDate`
     */
    public var timeIntervalSinceNow: TimeInterval {
        return self.timeIntervalSinceReferenceDate - CFAbsoluteTimeGetCurrent()
    }
    
    /**
     The interval between the date object and 00:00:00 UTC on 1 January 1970.
     
     This property’s value is negative if the date object is earlier than 00:00:00 UTC on 1 January 1970.
     
     - SeeAlso: `timeIntervalSince(_:)`
     - SeeAlso: `timeIntervalSinceNow`
     - SeeAlso: `timeIntervalSinceReferenceDate`
     */
    public var timeIntervalSince1970: TimeInterval {
        return self.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
    }
    
    /**
     Creates and returns a Date value representing a date in the distant future.
     
     The distant future is in terms of centuries.
     */
    public static let distantFuture = Date(timeIntervalSinceReferenceDate: 63113904000.0)
    
    /**
     Creates and returns a Date value representing a date in the distant past.
     
     The distant past is in terms of centuries.
     */
    public static let distantPast = Date(timeIntervalSinceReferenceDate: -63114076800.0)
    
    public var hashValue: Int {
        return Int(bitPattern: __CFHashDouble(_time))
    }
    
    public func compare(_ other: Date) -> ComparisonResult {
        if _time < other.timeIntervalSinceReferenceDate {
            return .orderedAscending
        } else if _time > other.timeIntervalSinceReferenceDate {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    /**
     A string representation of the date object (read-only).
     
     The representation is useful for debugging only.
     
     There are a number of options to acquire a formatted string for a date including: date formatters (see
     [NSDateFormatter](//apple_ref/occ/cl/NSDateFormatter) and [Data Formatting Guide](//apple_ref/doc/uid/10000029i)), and the `Date` functions `description(locale:)`.
     */
    public var description: String {
        // Defer to NSDate for description
        return NSDate(timeIntervalSinceReferenceDate: _time).description
    }
    
    /**
     Returns a string representation of the receiver using the given
     locale.
     
     - Parameter locale: A `Locale` object. If you pass `nil`, `NSDate` formats the date in the same way as the `description` property.
     
     - Returns: A string representation of the receiver, using the given locale, or if the locale argument is `nil`, in the international format `YYYY-MM-DD HH:MM:SS ±HHMM`, where `±HHMM` represents the time zone offset in hours and minutes from UTC (for example, “`2001-03-24 10:45:32 +0600`”).
     */
    public func description(with locale: Locale?) -> String {
        return NSDate(timeIntervalSinceReferenceDate: _time).descriptionWithLocale(locale)
    }
    
    public var debugDescription: String { return description }
}

/// Returns true if the two Date values are equal.
public func ==(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeIntervalSinceReferenceDate == rhs.timeIntervalSinceReferenceDate
}

/// Returns true if the left hand Date is less than the right hand Date.
public func <(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeIntervalSinceReferenceDate < rhs.timeIntervalSinceReferenceDate
}

/// Returns a Date with a specified amount of time added to it.
public func +(lhs: Date, rhs: TimeInterval) -> Date {
    return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate + rhs)
}

/// Returns a Date with a specified amount of time subtracted from it.
public func -(lhs: Date, rhs: TimeInterval) -> Date {
    return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate - rhs)
}

public func +=(lhs: inout Date, rhs: TimeInterval) {
    lhs = lhs + rhs
}

public func -=(lhs: inout Date, rhs: TimeInterval) {
    lhs = lhs - rhs
}
