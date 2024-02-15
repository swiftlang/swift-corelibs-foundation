// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import _CoreFoundation
@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials

open class NSTimeZone : NSObject, NSCopying, NSSecureCoding, NSCoding {
    var _timeZone: TimeZone
    
    init(_timeZone tz: TimeZone) {
        _timeZone = tz
    }
    
    public convenience init?(name tzName: String) {
        self.init(name: tzName, data: nil)
    }

    public init?(name tzName: String, data aData: Data?) {
        /* From https://developer.apple.com/documentation/foundation/nstimezone/1387250-init:
         "Discussion
         As of macOS 10.6, the underlying implementation of this method has been changed to ignore the specified data parameter."
         */
        if let tz = TimeZone(identifier: tzName) {
            _timeZone = tz
        } else {
            return nil
        }
        
        super.init()
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let name = aDecoder.decodeObject(of: NSString.self, forKey: "NS.name")
        let data = aDecoder.decodeObject(of: NSData.self, forKey: "NS.data")

        if name == nil {
            return nil
        }

        self.init(name: String._unconditionallyBridgeFromObjectiveC(name), data: data?._swiftObject)
    }
    
    open override var hash: Int {
        _timeZone.hashValue
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSTimeZone else { return false }
        return isEqual(to: other._swiftObject)
    }
    
    open override var description: String {
        _timeZone.description
    }

    // Time zones created with this never have daylight savings and the
    // offset is constant no matter the date; the name and abbreviation
    // do NOT follow the POSIX convention (of minutes-west).
    public convenience init(forSecondsFromGMT seconds: Int) {
        let tz = TimeZone(secondsFromGMT: seconds)!
        self.init(_timeZone: tz)
    }
    
    public convenience init?(abbreviation: String) {
        guard let tz = TimeZone(abbreviation: abbreviation) else {
            return nil
        }
        self.init(_timeZone: tz)
    }

    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.name._bridgeToObjectiveC(), forKey:"NS.name")
        // Darwin versions of this method can and will encode mutable data, however it is not required for compatibility
        aCoder.encode(self.data._bridgeToObjectiveC(), forKey:"NS.data")
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    open var name: String {
        _timeZone.identifier
    }
    
    open var data: Data {
        TimeZone._dataFromTZFile(_timeZone.identifier)
    }

    open func secondsFromGMT(for aDate: Date) -> Int {
        _timeZone.secondsFromGMT(for: aDate)
    }
    
    open func abbreviation(for aDate: Date) -> String? {
        _timeZone.abbreviation(for: aDate)
    }
    
    open func isDaylightSavingTime(for aDate: Date) -> Bool {
        _timeZone.isDaylightSavingTime(for: aDate)
    }
    
    open func daylightSavingTimeOffset(for aDate: Date) -> TimeInterval {
        _timeZone.daylightSavingTimeOffset(for: aDate)
    }
    
    open func nextDaylightSavingTimeTransition(after aDate: Date) -> Date? {
        _timeZone.nextDaylightSavingTimeTransition(after: aDate)
    }

    open class var system: TimeZone {
        TimeZone.current
    }

    open class func resetSystemTimeZone() {
        let _ = TimeZone._resetSystemTimeZone()
        // Also reset CF's system time zone
        CFTimeZoneResetSystem()
    }

    open class var `default`: TimeZone {
        get {
            // This assumes that the behavior of CFTimeZoneCopyDefault is the same as FoundationEssential's default, when no default has been set
            TimeZone._default
        }
        set {
            TimeZone._default = newValue
            // Need to reset the default in two places since CFTimeZone does not call up to Swift on this platform
            CFTimeZoneSetDefault(newValue._cfObject)
        }
    }

    open class var local: TimeZone {
        TimeZone.autoupdatingCurrent
    }

    open class var knownTimeZoneNames: [String] {
        TimeZone.knownTimeZoneIdentifiers
    }

    open class var abbreviationDictionary: [String : String] {
        get {
            TimeZone.abbreviationDictionary
        }
        set {
            TimeZone.abbreviationDictionary = newValue
        }
    }

    open class var timeZoneDataVersion: String {
        TimeZone.timeZoneDataVersion
    }

    open var secondsFromGMT: Int {
        _timeZone.secondsFromGMT()
    }

    /// The abbreviation for the receiver, such as "EDT" (Eastern Daylight Time). (read-only)
    ///
    /// This invokes `abbreviationForDate:` with the current date as the argument.
    open var abbreviation: String? {
        _timeZone.abbreviation()
    }

    open var isDaylightSavingTime: Bool {
        _timeZone.isDaylightSavingTime()
    }

    open var daylightSavingTimeOffset: TimeInterval {
        _timeZone.daylightSavingTimeOffset()
    }

    /*@NSCopying*/ open var nextDaylightSavingTimeTransition: Date?  {
        _timeZone.nextDaylightSavingTimeTransition
    }

    open func isEqual(to aTimeZone: TimeZone) -> Bool {
        self._timeZone == aTimeZone
    }

    open func localizedName(_ style: NameStyle, locale: Locale?) -> String? {
        _timeZone.localizedName(for: style, locale: locale)
    }

}

extension NSTimeZone {
    public typealias NameStyle = TimeZone.NameStyle
}

extension NSNotification.Name {
    public static let NSSystemTimeZoneDidChange = NSNotification.Name(rawValue: kCFTimeZoneSystemTimeZoneDidChangeNotification._swiftObject)
}

// MARK: - Bridging

extension NSTimeZone: _SwiftBridgeable {
    typealias SwiftType = TimeZone
    var _swiftObject: TimeZone {
        _timeZone
    }
    
    var _cfObject : CFTimeZone {
        let name = self.name
        let tz = CFTimeZoneCreateWithName(nil, name._cfObject, true)!
        return tz
    }
}

extension CFTimeZone : _SwiftBridgeable, _NSBridgeable {
    typealias NSType = NSTimeZone
    var _nsObject : NSTimeZone {
        let name = CFTimeZoneGetName(self)._swiftObject
        let tz = TimeZone(identifier: name)!
        return NSTimeZone(_timeZone: tz)
    }
    
    var _swiftObject: TimeZone {
        return _nsObject._swiftObject
    }
}

extension TimeZone : _NSBridgeable {
    typealias NSType = NSTimeZone
    typealias CFType = CFTimeZone
    var _nsObject : NSTimeZone {
        return _bridgeToObjectiveC()
    }
    
    var _cfObject : CFTimeZone {
        _nsObject._cfObject
    }
}

extension TimeZone : ReferenceConvertible {
    public typealias ReferenceType = NSTimeZone
}

extension TimeZone : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSTimeZone {
        NSTimeZone(_timeZone: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSTimeZone, result: inout TimeZone?) {
        if !_conditionallyBridgeFromObjectiveC(input, result: &result) {
            fatalError("Unable to bridge \(NSTimeZone.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSTimeZone, result: inout TimeZone?) -> Bool {
        result = input._timeZone
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSTimeZone?) -> TimeZone {
        var result: TimeZone? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

