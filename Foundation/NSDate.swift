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
    get {
        return 978307200.0
    }
}

public class NSDate : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFDateRef
    
    deinit {
        _CFDeinit(self)
    }
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    internal let _base = _CFInfo(typeID: CFDateGetTypeID())
    internal let _timeIntervalSinceReferenceDate: NSTimeInterval
    
    public var timeIntervalSinceReferenceDate: NSTimeInterval {
        get {
            return _timeIntervalSinceReferenceDate
        }
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
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }

    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
    public override var description: String {
        get {
            return CFCopyDescription(_cfObject)._swiftObject
        }
    }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String {
        return description
    }
    
    override internal var _cfTypeID: CFTypeID {
        return CFDateGetTypeID()
    }
}

extension NSDate {
    
    public func timeIntervalSinceDate(anotherDate: NSDate) -> NSTimeInterval {
        return self.timeIntervalSinceReferenceDate - anotherDate.timeIntervalSinceReferenceDate
    }
    
    public var timeIntervalSinceNow: NSTimeInterval {
        get {
            return timeIntervalSinceDate(NSDate())
        }
    }
    
    public var timeIntervalSince1970: NSTimeInterval {
        get {
            return timeIntervalSinceReferenceDate + NSTimeIntervalSince1970
        }
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

