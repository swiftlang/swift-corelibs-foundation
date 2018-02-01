// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension DateIntervalFormatter {
    public enum Style : UInt {
        
        case noStyle
        case shortStyle
        case mediumStyle
        case longStyle
        case fullStyle
    }
}

// DateIntervalFormatter is used to format the range between two NSDates in a locale-sensitive way.
// DateIntervalFormatter returns nil and NO for all methods in Formatter.

open class DateIntervalFormatter : Formatter {
    
    public override init() {
        NSUnimplemented()
    }

    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ open var locale: Locale! // default is [NSLocale currentLocale]
    /*@NSCopying*/ open var calendar: Calendar! // default is the calendar of the locale
    /*@NSCopying*/ open var timeZone: TimeZone! // default is [NSTimeZone defaultTimeZone]
    open var dateTemplate: String! // default is an empty string
    open var dateStyle: Style // default is .noStyle
    open var timeStyle: Style // default is .noStyle
    
    /*
         If the range smaller than the resolution specified by the dateTemplate, a single date format will be produced. If the range is larger than the format specified by the dateTemplate, a locale-specific fallback will be used to format the items missing from the pattern.
         
         For example, if the range is 2010-03-04 07:56 - 2010-03-04 19:56 (12 hours)
         - The pattern jm will produce
            for en_US, "7:56 AM - 7:56 PM"
            for en_GB, "7:56 - 19:56"
         - The pattern MMMd will produce
            for en_US, "Mar 4"
            for en_GB, "4 Mar"
         If the range is 2010-03-04 07:56 - 2010-03-08 16:11 (4 days, 8 hours, 15 minutes)
         - The pattern jm will produce
            for en_US, "3/4/2010 7:56 AM - 3/8/2010 4:11 PM"
            for en_GB, "4/3/2010 7:56 - 8/3/2010 16:11"
         - The pattern MMMd will produce
            for en_US, "Mar 4-8"
            for en_GB, "4-8 Mar"
    */
    open func string(from fromDate: Date, to toDate: Date) -> String { NSUnimplemented() }
    
    open func string(from dateInterval: DateInterval) -> String? { NSUnimplemented() }
}
