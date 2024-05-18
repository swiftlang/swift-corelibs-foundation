// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation

extension ISO8601DateFormatter {

    public struct Options : OptionSet {
        
        public private(set) var rawValue: UInt
        
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let withYear = ISO8601DateFormatter.Options(rawValue: 1 << 0)

        public static let withMonth = ISO8601DateFormatter.Options(rawValue: 1 << 1)

        public static let withWeekOfYear = ISO8601DateFormatter.Options(rawValue: 1 << 2)
        
        public static let withDay = ISO8601DateFormatter.Options(rawValue: 1 << 4)
        
        public static let withTime = ISO8601DateFormatter.Options(rawValue: 1 << 5)
        
        public static let withTimeZone = ISO8601DateFormatter.Options(rawValue: 1 << 6)
        
        public static let withSpaceBetweenDateAndTime = ISO8601DateFormatter.Options(rawValue: 1 << 7)
        
        public static let withDashSeparatorInDate = ISO8601DateFormatter.Options(rawValue: 1 << 8)
        
        public static let withColonSeparatorInTime = ISO8601DateFormatter.Options(rawValue: 1 << 9)
        
        public static let withColonSeparatorInTimeZone = ISO8601DateFormatter.Options(rawValue: 1 << 10)
        
        public static let withFractionalSeconds = ISO8601DateFormatter.Options(rawValue: 1 << 11)
        
        public static let withFullDate = ISO8601DateFormatter.Options(rawValue: withYear.rawValue + withMonth.rawValue + withDay.rawValue + withDashSeparatorInDate.rawValue)
        
        public static let withFullTime = ISO8601DateFormatter.Options(rawValue: withTime.rawValue + withTimeZone.rawValue + withColonSeparatorInTime.rawValue + withColonSeparatorInTimeZone.rawValue)

        public static let withInternetDateTime = ISO8601DateFormatter.Options(rawValue: withFullDate.rawValue + withFullTime.rawValue)
    }

}

open class ISO8601DateFormatter : Formatter, NSSecureCoding {
    
    typealias CFType = CFDateFormatter
    private final var __cfObject: CFType?
    private final var _cfObject: CFType {
        guard let obj = __cfObject else {
            let format = CFISO8601DateFormatOptions(rawValue: formatOptions.rawValue)
            let obj = CFDateFormatterCreateISO8601Formatter(kCFAllocatorSystemDefault, format)!
            CFDateFormatterSetProperty(obj, kCFDateFormatterTimeZone, timeZone._cfObject)
            __cfObject = obj
            return obj
        }
        return obj
    }
    
    /* Please note that there can be a significant performance cost when resetting these properties. Resetting each property can result in regenerating the entire CFDateFormatterRef, which can be very expensive. */
    
    open var timeZone: TimeZone! { willSet { _reset() } }
    
    open var formatOptions: ISO8601DateFormatter.Options { willSet { _reset() } }
    
    public override init() {
        timeZone = TimeZone(identifier: "GMT")
        formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            fatalError("Decoding ISO8601DateFormatter requires a coder that allows keyed coding")
        }
        
        self.formatOptions = Options(rawValue: UInt(aDecoder.decodeInteger(forKey: "NS.formatOptions")))
        
        let timeZone: NSTimeZone?
        
        if aDecoder.containsValue(forKey: "NS.timeZone") {
            if let tz = aDecoder.decodeObject(of: NSTimeZone.self, forKey: "NS.timeZone") {
                timeZone = tz
            } else {
                aDecoder.failWithError(CocoaError(.coderReadCorrupt, userInfo: [ NSLocalizedDescriptionKey: "Time zone was corrupt while decoding ISO8601DateFormatter" ]))
                return nil
            }
        } else {
            timeZone = nil
        }
        
        if let zone = timeZone?._swiftObject {
            self.timeZone = zone
        }
        
        super.init()
    }
    
    open override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            fatalError("Encoding ISO8601DateFormatter requires a coder that allows keyed coding")
        }
        
        aCoder.encode(Int(formatOptions.rawValue), forKey: "NS.formatOptions")
        if let timeZone = timeZone {
            aCoder.encode(timeZone._nsObject, forKey: "NS.timeZone")
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copied = ISO8601DateFormatter()
        copied.timeZone = timeZone
        copied.formatOptions = formatOptions
        return copied
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
    open func string(from date: Date) -> String {
        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, _cfObject, date._cfObject)._swiftObject
    }
    
    open func date(from string: String) -> Date? {
        
        var range = CFRange(location: 0, length: string.length)
        let date = withUnsafeMutablePointer(to: &range) { (rangep: UnsafeMutablePointer<CFRange>) -> Date? in
            guard let res = CFDateFormatterCreateDateFromString(kCFAllocatorSystemDefault, _cfObject, string._cfObject, rangep) else {
                return nil
            }
            return res._swiftObject
        }
        return date
        
    }
    
    open class func string(from date: Date, timeZone: TimeZone, formatOptions: ISO8601DateFormatter.Options = []) -> String {
        let format = CFISO8601DateFormatOptions(rawValue: formatOptions.rawValue)
        let obj = CFDateFormatterCreateISO8601Formatter(kCFAllocatorSystemDefault, format)
        CFDateFormatterSetProperty(obj, kCFDateFormatterTimeZone, timeZone._cfObject)
        return CFDateFormatterCreateStringWithDate(kCFAllocatorSystemDefault, obj, date._cfObject)._swiftObject
    }
    
    private func _reset() {
        __cfObject = nil
    }
    
}
