// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension DateIntervalFormatter {
    public enum Style: UInt {
        case none
        case short
        case medium
        case long
        case full
    }
}

// DateIntervalFormatter is used to format the range between two Dates in a locale-sensitive way.

open class DateIntervalFormatter : Formatter {
    private let _dateFormatter: DateFormatter
    private var _formatter: OpaquePointer? = nil
    private var _dateTemplate: String?

    open var calendar: Calendar! {
        get { return _dateFormatter.calendar }
        set {
            if let newValue = newValue {
                _dateFormatter.calendar = newValue
                setTemplateFromProperties()
            }
        }
    }

    open var locale: Locale! {
        get { return _dateFormatter.locale }
        set {
            if let newValue = newValue {
                _dateFormatter.locale = newValue
                setTemplateFromProperties()
            }
        }
    }

    open var timeZone: TimeZone! {
        get { return _dateFormatter.timeZone }
        set {
            if let newValue = newValue {
                _dateFormatter.timeZone = newValue
                setTemplateFromProperties()
            }
        }
    }

    open var dateStyle: Style {
        get {
            switch _dateFormatter.dateStyle {
            case .none:     return .none
            case .short:    return .short
            case .medium:   return .medium
            case .long:     return .long
            case .full:     return .full
            }
        }
        set {
            switch newValue {
            case .none:     _dateFormatter.dateStyle = .none
            case .short:    _dateFormatter.dateStyle = .short
            case .medium:   _dateFormatter.dateStyle = .medium
            case .long:     _dateFormatter.dateStyle = .long
            case .full:     _dateFormatter.dateStyle = .full
            }
            setTemplateFromProperties()
        }
    }

    open var timeStyle: Style {
        get {
            switch _dateFormatter.timeStyle {
            case .none:     return .none
            case .short:    return .short
            case .medium:   return .medium
            case .long:     return .long
            case .full:     return .full
            }
        }

        set {
            switch newValue {
            case .none:     _dateFormatter.timeStyle = .none
            case .short:    _dateFormatter.timeStyle = .short
            case .medium:   _dateFormatter.timeStyle = .medium
            case .long:     _dateFormatter.timeStyle = .long
            case .full:     _dateFormatter.timeStyle = .full
            }
            setTemplateFromProperties()
        }
    }

    open var dateTemplate: String! {
        get { return _dateTemplate }
        set {
            _dateTemplate = newValue
            resetFormatter()
        }
    }

    public override init() {
        _dateFormatter = DateFormatter()
        _dateFormatter.locale = Locale.current
        _dateFormatter.timeZone = NSTimeZone.default
        _dateFormatter.calendar = Locale.current.calendar
        _dateFormatter.dateStyle = .short
        _dateFormatter.timeStyle = .short
        _dateTemplate = _dateFormatter.dateFormat
        super.init()
    }

    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }

    deinit {
        resetFormatter()
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


    open func string(from dateInterval: DateInterval) -> String? {
        return _string(from: dateInterval) ?? ""
    }

    open func string(from fromDate: Date, to toDate: Date) -> String {
        return _string(from: DateInterval(start: fromDate, end: toDate)) ?? ""
    }

    private func _string(from dateInterval: DateInterval) -> String? {
        if _formatter == nil {
            _formatter = createFormatter()
        }
        guard let formatter = _formatter else { return nil }

        var outputBufferLength = 32
        while outputBufferLength < 1024 { // Hard limit to growing buffer
            let outputBuffer = UnsafeMutablePointer<unichar>.allocate(capacity: outputBufferLength)
            defer { outputBuffer.deallocate() }

            var status = U_ZERO_ERROR
            let startDate = dateInterval.start.timeIntervalSince1970 * 1000
            let endDate = dateInterval.end.timeIntervalSince1970 * 1000
            let length = date_interval_formatter_format(formatter, startDate, endDate, outputBuffer, Int32(outputBufferLength), nil, &status)
            if status.rawValue <= 0 && length <= outputBufferLength {
                return String(utf16CodeUnits: outputBuffer, count: Int(length))
            }
            if status != U_BUFFER_OVERFLOW_ERROR {
                break
            }
            outputBufferLength = Int(length) + 1
        }
        return nil
    }

    private func setTemplateFromProperties() {
        resetFormatter()
        _dateTemplate = _dateFormatter.dateFormat
    }

    private func createFormatter() -> OpaquePointer? {
        guard let template = dateTemplate else { return nil }

        var status = UErrorCode(rawValue: 0)
        // ICU requires some of its inputs to be UTF-16
        let formatter = template.utf16.map { $0 }.withUnsafeBufferPointer { skeleton -> OpaquePointer? in
            guard let skeletonBaseAddress = skeleton.baseAddress else { return nil }
            if let tz = timeZone {
                return tz.identifier.utf16.map { $0 }.withUnsafeBufferPointer { tzId in
                    date_interval_formatter_open(locale.identifier, skeletonBaseAddress, Int32(skeleton.count), tzId.baseAddress, Int32(tzId.count), &status)
                }
            } else {
                return date_interval_formatter_open(locale.identifier, skeletonBaseAddress, Int32(skeleton.count), nil, 0, &status)
            }
        }
        if status.rawValue > U_ZERO_ERROR.rawValue && formatter != nil {
            // If there was an error creating the formatter but it still returned one then release it as it could be in an inconsistent state
            date_interval_formatter_close(formatter!)
            return nil
        }
        return formatter
    }

    private func resetFormatter() {
        if let formatter = _formatter {
            date_interval_formatter_close(formatter)
            _formatter = nil
        }
    }
}
