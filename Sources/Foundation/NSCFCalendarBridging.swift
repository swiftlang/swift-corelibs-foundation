// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// This file can be deleted once DateFormatter and DateIntervalFormatter stop needing a bridged CFCalendar.

@_implementationOnly import CoreFoundation
@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials

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
        if let start = gregorianStartDate {
            CFCalendarSetGregorianStartDate(cf, start._cfObject)
        }
        return cf
    }
}

extension Calendar: _NSBridgeable {
    typealias NSType = NSCalendar
    typealias CFType = CFCalendar
    var _nsObject: NSCalendar { return _bridgeToObjectiveC() }
    var _cfObject: CFCalendar { return _nsObject._cfObject }
}
