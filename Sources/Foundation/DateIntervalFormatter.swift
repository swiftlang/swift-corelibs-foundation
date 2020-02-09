// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal let kCFDateIntervalFormatterNoStyle = CFDateIntervalFormatterStyle.noStyle
internal let kCFDateIntervalFormatterShortStyle = CFDateIntervalFormatterStyle.shortStyle
internal let kCFDateIntervalFormatterMediumStyle = CFDateIntervalFormatterStyle.mediumStyle
internal let kCFDateIntervalFormatterLongStyle = CFDateIntervalFormatterStyle.longStyle
internal let kCFDateIntervalFormatterFullStyle = CFDateIntervalFormatterStyle.fullStyle

internal let kCFDateIntervalFormatterBoundaryStyleDefault = _CFDateIntervalFormatterBoundaryStyle.cfDateIntervalFormatterBoundaryStyleDefault
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
internal let kCFDateIntervalFormatterBoundaryStyleMinimizeAdjacentMonths = _CFDateIntervalFormatterBoundaryStyle.cfDateIntervalFormatterBoundaryStyleMinimizeAdjacentMonths
#endif

extension DateIntervalFormatter {
    // Keep these in sync with CFDateIntervalFormatterStyle.
    public enum Style: UInt {
        case none = 0
        case short = 1
        case medium = 2
        case long = 3
        case full = 4
    }
}

internal extension DateIntervalFormatter.Style {
    init(_ cfStyle: CFDateIntervalFormatterStyle) {
        switch cfStyle {
        case kCFDateIntervalFormatterNoStyle: self = .none
        case kCFDateIntervalFormatterShortStyle: self = .short
        case kCFDateIntervalFormatterMediumStyle: self = .medium
        case kCFDateIntervalFormatterLongStyle: self = .long
        case kCFDateIntervalFormatterFullStyle: self = .full
        default: fatalError()
        }
    }
}

internal extension CFDateIntervalFormatterStyle {
    init(_ style: DateIntervalFormatter.Style) {
        switch style {
        case .none: self = kCFDateIntervalFormatterNoStyle
        case .short: self = kCFDateIntervalFormatterShortStyle
        case .medium: self = kCFDateIntervalFormatterMediumStyle
        case .long: self = kCFDateIntervalFormatterLongStyle
        case .full: self = kCFDateIntervalFormatterFullStyle
        }
    }
}

internal extension DateIntervalFormatter.BoundaryStyle {
    init(_ cfStyle: _CFDateIntervalFormatterBoundaryStyle) {
        switch cfStyle {
        case kCFDateIntervalFormatterBoundaryStyleDefault: self = .default
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case kCFDateIntervalFormatterBoundaryStyleMinimizeAdjacentMonths: self = .minimizeAdjacentMonths
#endif
        default: fatalError()
        }
    }
}

internal extension _CFDateIntervalFormatterBoundaryStyle {
    init(_ style: DateIntervalFormatter.BoundaryStyle) {
        switch style {
        case .default: self = kCFDateIntervalFormatterBoundaryStyleDefault
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case .minimizeAdjacentMonths: self = kCFDateIntervalFormatterBoundaryStyleMinimizeAdjacentMonths
#endif
        }
    }
}

// DateIntervalFormatter is used to format the range between two NSDates in a locale-sensitive way.
// DateIntervalFormatter returns nil and NO for all methods in Formatter.

open class DateIntervalFormatter: Formatter {
    let core: CFDateIntervalFormatter
    
    public override init() {
        core = CFDateIntervalFormatterCreate(nil, nil, kCFDateIntervalFormatterShortStyle, kCFDateIntervalFormatterShortStyle)
        super.init()
    }

    private init(cfFormatter: CFDateIntervalFormatter) {
        self.core = cfFormatter
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding else { fatalError("Requires a keyed coding-capable archiver.") }
        
        func cfObject<T: NSObject & _CFBridgeable>(of aClass: T.Type, from coder: NSCoder, forKey key: String) -> T.CFType? {
            if coder.containsValue(forKey: key) {
                let object = coder.decodeObject(forKey: key) as? T
                return object?._cfObject
            } else {
                return nil
            }
        }
        
        let core = CFDateIntervalFormatterCreate(nil, nil, kCFDateIntervalFormatterMediumStyle, kCFDateIntervalFormatterMediumStyle)
        _CFDateIntervalFormatterInitializeFromCoderValues(core,
                                                          coder.decodeInt64(forKey: "NS.dateStyle"),
                                                          coder.decodeInt64(forKey: "NS.timeStyle"),
                                                          cfObject(of: NSString.self, from: coder, forKey: "NS.dateTemplate"),
                                                          cfObject(of: NSString.self, from: coder, forKey: "NS.dateTemplateFromStyle"),
                                                          coder.decodeBool(forKey: "NS.modified"),
                                                          coder.decodeBool(forKey: "NS.useTemplate"),
                                                          cfObject(of: NSLocale.self, from: coder, forKey: "NS.locale"),
                                                          cfObject(of: NSCalendar.self, from: coder, forKey: "NS.calendar"),
                                                          cfObject(of: NSTimeZone.self, from: coder, forKey: "NS.timeZone"))
        self.core = core
        
        super.init(coder: coder)
    }
    
    open override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else { fatalError("Requires a keyed coding-capable archiver.") }
        super.encode(with: aCoder)
        
        var dateStyle: Int64 = 0
        var timeStyle: Int64 = 0
        var dateTemplate: Unmanaged<CFString>?
        var dateTemplateFromStyles: Unmanaged<CFString>?
        var modified: _DarwinCompatibleBoolean = false
        var useTemplate: _DarwinCompatibleBoolean = false
        var locale: Unmanaged<CFLocale>?
        var calendar: Unmanaged<CFCalendar>?
        var timeZone: Unmanaged<CFTimeZone>?
        
        _CFDateIntervalFormatterCopyCoderValues(core,
                                                &dateStyle,
                                                &timeStyle,
                                                &dateTemplate,
                                                &dateTemplateFromStyles,
                                                &modified,
                                                &useTemplate,
                                                &locale,
                                                &calendar,
                                                &timeZone);
        
        aCoder.encode(dateStyle, forKey: "NS.dateStyle")
        aCoder.encode(timeStyle, forKey: "NS.timeStyle")
        
        let dateTemplateNS = dateTemplate?.takeRetainedValue()._nsObject
        aCoder.encode(dateTemplateNS, forKey: "NS.dateTemplate")
        
        let dateTemplateFromStylesNS = dateTemplateFromStyles?.takeRetainedValue()._nsObject
        aCoder.encode(dateTemplateFromStylesNS, forKey: "NS.dateTemplateFromStyles")

        aCoder.encode(modified == true, forKey: "NS.modified");
        aCoder.encode(useTemplate == true, forKey: "NS.useTemplate")

        let localeNS = locale?.takeRetainedValue()._nsObject
        aCoder.encode(localeNS, forKey: "NS.locale")
        
        let calendarNS = calendar?.takeRetainedValue()._nsObject
        aCoder.encode(calendarNS, forKey: "NS.calendar")
        
        let timeZoneNS = timeZone?.takeRetainedValue()._nsObject
        aCoder.encode(timeZoneNS, forKey: "NS.timeZone")
    }
    
    /*@NSCopying*/ open var locale: Locale! {
        get { return CFDateIntervalFormatterCopyLocale(core)._swiftObject }
        set { CFDateIntervalFormatterSetLocale(core, newValue?._cfObject) }
    }
    
    /*@NSCopying*/ open var calendar: Calendar! {
        get { return CFDateIntervalFormatterCopyCalendar(core)._swiftObject }
        set { CFDateIntervalFormatterSetCalendar(core, newValue?._cfObject) }
    }
    
    /*@NSCopying*/ open var timeZone: TimeZone! {
        get { return CFDateIntervalFormatterCopyTimeZone(core)._swiftObject }
        set { CFDateIntervalFormatterSetTimeZone(core, newValue?._cfObject) }
    }
    
    open var dateTemplate: String! {
        get { return CFDateIntervalFormatterCopyDateTemplate(core)._swiftObject }
        set { CFDateIntervalFormatterSetDateTemplate(core, newValue?._cfObject) }
    }
    
    open var dateStyle: Style {
        get { return Style(CFDateIntervalFormatterGetDateStyle(core)) }
        set { CFDateIntervalFormatterSetDateStyle(core, CFDateIntervalFormatterStyle(newValue)) }
    }
    open var timeStyle: Style {
        get { return Style(CFDateIntervalFormatterGetTimeStyle(core)) }
        set { CFDateIntervalFormatterSetTimeStyle(core, CFDateIntervalFormatterStyle(newValue)) }
    }
    
    internal enum BoundaryStyle: UInt {
        case `default` = 0
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        case minimizeAdjacentMonths = 1
#endif
    }
    
    internal var boundaryStyle: BoundaryStyle {
        get { return BoundaryStyle(_CFDateIntervalFormatterGetBoundaryStyle(core)) }
        set { _CFDateIntervalFormatterSetBoundaryStyle(core, _CFDateIntervalFormatterBoundaryStyle(newValue) )}
    }
    
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
    open func string(from fromDate: Date, to toDate: Date) -> String {
        return CFDateIntervalFormatterCreateStringFromDateToDate(core, fromDate._cfObject, toDate._cfObject)._swiftObject
    }
    
    open func string(from dateInterval: DateInterval) -> String? {
        let result = CFDateIntervalFormatterCreateStringFromDateToDate(core, dateInterval.start._cfObject, dateInterval.end._cfObject)._swiftObject
        return result.isEmpty ? nil : result
    }
    
    open override func string(for obj: Any) -> String? {
        guard let interval = obj as? DateInterval else {
            return nil
        }
        
        return string(from: interval)
    }
    
    open override func editingString(for obj: Any) -> String? {
        return nil
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return DateIntervalFormatter(cfFormatter: CFDateIntervalFormatterCreateCopy(nil, core))
    }
}
