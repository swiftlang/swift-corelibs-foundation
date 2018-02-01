// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension DateComponentsFormatter {
    public enum UnitsStyle : Int {
        case positional // "1:10; may fall back to abbreviated units in some cases, e.g. 3d"
        case abbreviated // "1h 10m"
        case short // "1hr, 10min"
        case full // "1 hour, 10 minutes"
        case spellOut // "One hour, ten minutes"
        case brief // "1hr 10min"
    }

    public struct ZeroFormattingBehavior : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let none = ZeroFormattingBehavior(rawValue: 0) //drop none, pad none
        public static let `default` = ZeroFormattingBehavior(rawValue: 1 << 0) //Positional units: drop leading zeros, pad other zeros. All others: drop all zeros.
        
        public static let dropLeading = ZeroFormattingBehavior(rawValue: 1 << 1) // Off: "0h 10m", On: "10m"
        public static let dropMiddle = ZeroFormattingBehavior(rawValue: 1 << 2) // Off: "1h 0m 10s", On: "1h 10s"
        public static let dropTrailing = ZeroFormattingBehavior(rawValue: 1 << 3) // Off: "1h 0m", On: "1h"
        public static let dropAll = [ZeroFormattingBehavior.dropLeading, ZeroFormattingBehavior.dropMiddle, ZeroFormattingBehavior.dropTrailing]
        
        public static let pad = ZeroFormattingBehavior(rawValue: 1 << 16) // Off: "1:0:10", On: "01:00:10"
    }
}

/* DateComponentsFormatter provides locale-correct and flexible string formatting of quantities of time, such as "1 day" or "1h 10m", as specified by NSDateComponents. For formatting intervals of time (such as "2PM to 5PM"), see DateIntervalFormatter. DateComponentsFormatter is thread-safe, in that calling methods on it from multiple threads will not cause crashes or incorrect results, but it makes no attempt to prevent confusion when one thread sets something and another thread isn't expecting it to change.
 */

open class DateComponentsFormatter : Formatter {
    
    public override init() {
        NSUnimplemented()
    }

    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /* 'obj' must be an instance of NSDateComponents.
     */
    open override func string(for obj: Any?) -> String? { NSUnimplemented() }
    
    open func string(from components: DateComponents) -> String? { NSUnimplemented() }
    
    /* Normally, DateComponentsFormatter will calculate as though counting from the current date and time (e.g. in February, 1 month formatted as a number of days will be 28). -stringFromDate:toDate: calculates from the passed-in startDate instead.
     
       See 'allowedUnits' for how the default set of allowed units differs from -stringFromDateComponents:.
     
       Note that this is still formatting the quantity of time between the dates, not the pair of dates itself. For strings like "Feb 22nd - Feb 28th", use DateIntervalFormatter.
     */
    open func string(from startDate: Date, to endDate: Date) -> String? { NSUnimplemented() }
    
    /* Convenience method for formatting a number of seconds. See 'allowedUnits' for how the default set of allowed units differs from -stringFromDateComponents:.
     */
    open func string(from ti: TimeInterval) -> String? { NSUnimplemented() }
    
    open class func localizedString(from components: DateComponents, unitsStyle: UnitsStyle) -> String? { NSUnimplemented() }
    
    /* Choose how to indicate units. For example, 1h 10m vs 1:10. Default is DateComponentsFormatter.UnitsStyle.positional.
     */
    open var unitsStyle: UnitsStyle
    
    /* Bitmask of units to include. Set to 0 to get the default behavior. Note that, especially if the maximum number of units is low, unit collapsing is on, or zero dropping is on, not all allowed units may actually be used for a given NSDateComponents. Default value is the components of the passed-in NSDateComponents object, or years | months | weeks | days | hours | minutes | seconds if passed an NSTimeInterval or pair of NSDates.
     
       Allowed units are:
     
        NSCalendarUnitYear
        NSCalendarUnitMonth
        NSCalendarUnitWeekOfMonth (used to mean "quantity of weeks")
        NSCalendarUnitDay
        NSCalendarUnitHour
        NSCalendarUnitMinute
        NSCalendarUnitSecond
     
       Specifying any other NSCalendarUnits will result in an exception.
     */
    open var allowedUnits: NSCalendar.Unit
    
    /* Bitmask specifying how to handle zeros in units. This includes both padding and dropping zeros so that a consistent number digits are displayed, causing updating displays to remain more stable. Default is DateComponentsFormatter.ZeroFormattingBehavior.default.
     
       If the combination of zero formatting behavior and style would lead to ambiguous date formats (for example, 1:10 meaning 1 hour, 10 seconds), DateComponentsFormatter will throw an exception.
     */
    open var zeroFormattingBehavior: ZeroFormattingBehavior
    
    /* Specifies the locale and calendar to use for formatting date components that do not themselves have calendars. Defaults to NSAutoupdatingCurrentCalendar. If set to nil, uses the gregorian calendar with the en_US_POSIX locale.
     */
    /*@NSCopying*/ open var calendar: Calendar?
    
    /* Choose whether non-integer units should be used to handle display of values that can't be exactly represented with the allowed units. For example, if minutes aren't allowed, then "1h 30m" could be formatted as "1.5h". Default is NO.
     */
    open var allowsFractionalUnits: Bool
    
    /* Choose whether or not, and at which point, to round small units in large values to zero.
       Examples:
        1h 10m 30s, maximumUnitCount set to 0: "1h 10m 30s"
        1h 10m 30s, maximumUnitCount set to 2: "1h 10m"
        10m 30s, maximumUnitCount set to 0: "10m 30s"
        10m 30s, maximumUnitCount set to 2: "10m 30s"
    
       Default is 0, which is interpreted as unlimited.
     */
    open var maximumUnitCount: Int
    
    /* Choose whether to express largest units just above the threshold for the next lowest unit as a larger quantity of the lower unit. For example: "1m 3s" vs "63s". Default is NO.
     */
    open var collapsesLargestUnit: Bool
    
    /* Choose whether to indicate that the allowed units/insignificant units choices lead to inexact results. In some languages, simply prepending "about " to the string will produce incorrect results; this handles those cases correctly. Default is NO.
     */
    open var includesApproximationPhrase: Bool
    
    /* Choose whether to produce strings like "35 minutes remaining". Default is NO.
     */
    open var includesTimeRemainingPhrase: Bool
    
    /* 
       Currently unimplemented, will be removed in a future seed.
     */
    open var formattingContext: Context
    
    /* DateComponentsFormatter currently only implements formatting, not parsing. Until it implements parsing, this will always return NO.
     */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> Any? { return nil }
}

