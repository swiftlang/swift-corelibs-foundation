// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension ISO8601DateFormatter {
    
    
    public struct Options : OptionSet {
        public private(set) var rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static var withYear = ISO8601DateFormatter.Options(rawValue: 1 << 0)
        
        public static var withMonth = ISO8601DateFormatter.Options(rawValue: 1 << 1)
        
        public static var withWeekOfYear = ISO8601DateFormatter.Options(rawValue: 1 << 2)
        
        public static var withDay = ISO8601DateFormatter.Options(rawValue: 1 << 3)
        
        public static var withTime = ISO8601DateFormatter.Options(rawValue: 1 << 4)
        
        public static var withTimeZone = ISO8601DateFormatter.Options(rawValue: 1 << 5)
        
        public static var withSpaceBetweenDateAndTime = ISO8601DateFormatter.Options(rawValue: 1 << 6)
        
        public static var withDashSeparatorInDate = ISO8601DateFormatter.Options(rawValue: 1 << 7)
        
        public static var withColonSeparatorInTime = ISO8601DateFormatter.Options(rawValue: 1 << 8)
        
        public static var withColonSeparatorInTimeZone = ISO8601DateFormatter.Options(rawValue: 1 << 9)
        
        public static var withFullDate = ISO8601DateFormatter.Options(rawValue: 1 << 10)
        
        public static var withFullTime = ISO8601DateFormatter.Options(rawValue: 1 << 11)
        
        public static var withInternetDateTime = ISO8601DateFormatter.Options(rawValue: 1 << 12)
    }
}

open class ISO8601DateFormatter : Formatter, NSSecureCoding {
    
    
    /* Please note that there can be a significant performance cost when resetting these properties. Resetting each property can result in regenerating the entire CFDateFormatterRef, which can be very expensive. */
    open var timeZone: TimeZone! // The default time zone is GMT.
    
    
    open var formatOptions: ISO8601DateFormatter.Options
    
    
    /* This init method creates a formatter object set to the GMT time zone and preconfigured with the RFC 3339 standard format ("yyyy-MM-dd'T'HH:mm:ssXXXXX") using the following options:
     NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithDashSeparatorInDate | NSISO8601DateFormatWithColonSeparatorInTime | NSISO8601DateFormatWithColonSeparatorInTimeZone
     */
    public override init() { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    open override func encode(with aCoder: NSCoder) { NSUnimplemented() }
    public static var supportsSecureCoding: Bool { return true }
    
    
    open func string(from date: Date) -> String {
        NSUnimplemented()
    }
    
    open func date(from string: String) -> Date? {
        NSUnimplemented()
    }
    
    
    open class func string(from date: Date, timeZone: TimeZone, formatOptions: ISO8601DateFormatter.Options = []) -> String {
        NSUnimplemented()
    }
}
