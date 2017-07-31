// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

open class NSTimeZone : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFTimeZone
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    // Primary creation method is +timeZoneWithName:; the
    // data-taking variants should rarely be used directly
    public convenience init?(name tzName: String) {
        self.init(name: tzName, data: nil)
    }

    public convenience init?(name tzName: String, data aData: Data?) {
        if type(of: self) == NSTimeZone.self {
            if let data = aData {
                guard let tz = CFTimeZoneCreate(kCFAllocatorSystemDefault, tzName._cfObject, data._cfObject) else {
                    return nil
                }
                self.init(factory: unsafeBitCast(tz, to: NSTimeZone.self))
            } else {
                guard let tz = CFTimeZoneCreateWithName(kCFAllocatorSystemDefault, tzName._cfObject, true) else {
                    return nil
                }
                self.init(factory: unsafeBitCast(tz, to: NSTimeZone.self))
            }
            
        } else {
            self.init()
        }
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
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSTimeZone else { return false }
        return isEqual(to: other._swiftObject)
    }
    
    open override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }
    
    // `init(forSecondsFromGMT:)` is not a failable initializer, so we need a designated initializer that isn't failable.
    internal convenience init(_name tzName: String) {
        if type(of: self) == NSTimeZone.self {
            let cf = CFTimeZoneCreateWithName(kCFAllocatorSystemDefault, unsafeBitCast(NSString(string: tzName), to: CFString.self), true)!
            self.init(factory: unsafeBitCast(cf, to: NSTimeZone.self))
        } else {
            self.init()
        }
    }

    // Time zones created with this never have daylight savings and the
    // offset is constant no matter the date; the name and abbreviation
    // do NOT follow the POSIX convention (of minutes-west).
    public convenience init(forSecondsFromGMT seconds: Int) {
        let sign = seconds < 0 ? "-" : "+"
        let absoluteValue = abs(seconds)
        var minutes = absoluteValue / 60
        if (absoluteValue % 60) >= 30 { minutes += 1 }
        var hours = minutes / 60
        minutes %= 60
        hours = min(hours, 99) // Two digits only; leave CF to enforce actual max offset.
        let mm = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let hh = hours < 10 ? "0\(hours)" : "\(hours)"
        self.init(_name: "GMT" + sign + hh + mm)
    }
    
    public convenience init?(abbreviation: String) {
        let abbr = abbreviation._cfObject
        guard let name = unsafeBitCast(CFDictionaryGetValue(CFTimeZoneCopyAbbreviationDictionary(), unsafeBitCast(abbr, to: UnsafeRawPointer.self)), to: NSString!.self) else {
            return nil
        }
        self.init(name: name._swiftObject , data: nil)
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
        NSRequiresConcreteImplementation()
    }
    
    open var data: Data {
        NSRequiresConcreteImplementation()
    }
    
    open func secondsFromGMT(for aDate: Date) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    open func abbreviation(for aDate: Date) -> String? {
        NSRequiresConcreteImplementation()
    }
    
    open func isDaylightSavingTime(for aDate: Date) -> Bool {   
        NSRequiresConcreteImplementation()
    }
    
    open func daylightSavingTimeOffset(for aDate: Date) -> TimeInterval {
        NSRequiresConcreteImplementation()
    }
    
    open func nextDaylightSavingTimeTransition(after aDate: Date) -> Date? {
        NSRequiresConcreteImplementation()
    }
}

extension NSTimeZone {

    open class var system: TimeZone {
        return CFTimeZoneCopySystem()._swiftObject
    }

    open class func resetSystemTimeZone() {
        CFTimeZoneResetSystem()
    }

    open class var `default`: TimeZone {
        get {
            return CFTimeZoneCopyDefault()._swiftObject
        }
        set {
            CFTimeZoneSetDefault(newValue._cfObject)
        }
    }

    open class var local: TimeZone { NSUnimplemented() }

    open class var knownTimeZoneNames: [String] {
        guard let knownNames = CFTimeZoneCopyKnownNames() else { return [] }
        return knownNames._nsObject._bridgeToSwift() as! [String]
    }

    open class var abbreviationDictionary: [String : String] {
        get {
            guard let dictionary = CFTimeZoneCopyAbbreviationDictionary() else { return [:] }
            return dictionary._nsObject._bridgeToSwift() as! [String : String]
        }
        set {
            // CFTimeZoneSetAbbreviationDictionary(newValue._cfObject)
            NSUnimplemented()
        }
    }

    open class var timeZoneDataVersion: String { NSUnimplemented() }

    open var secondsFromGMT: Int {
        let currentDate = Date()
        return secondsFromGMT(for: currentDate)
    }

    /// The abbreviation for the receiver, such as "EDT" (Eastern Daylight Time). (read-only)
    ///
    /// This invokes `abbreviationForDate:` with the current date as the argument.
    open var abbreviation: String? {
        let currentDate = Date()
        return abbreviation(for: currentDate)
    }

    open var isDaylightSavingTime: Bool {
        let currentDate = Date()
        return isDaylightSavingTime(for: currentDate)
    }

    open var daylightSavingTimeOffset: TimeInterval {
        let currentDate = Date()
        return daylightSavingTimeOffset(for: currentDate)
    }

    /*@NSCopying*/ open var nextDaylightSavingTimeTransition: Date?  {
        let currentDate = Date()
        return nextDaylightSavingTimeTransition(after: currentDate)
    }

    open func isEqual(to aTimeZone: TimeZone) -> Bool {
        return CFEqual(self._cfObject, aTimeZone._cfObject)
    }

    open func localizedName(_ style: NameStyle, locale: Locale?) -> String? {
        #if os(OSX) || os(iOS)
            let cfStyle = CFTimeZoneNameStyle(rawValue: style.rawValue)!
        #else
            let cfStyle = CFTimeZoneNameStyle(style.rawValue)
        #endif
        return CFTimeZoneCopyLocalizedName(self._cfObject, cfStyle, locale?._cfObject ?? CFLocaleCopyCurrent())._swiftObject
    }

}

extension NSTimeZone: _SwiftBridgeable, _CFBridgeable {
    typealias SwiftType = TimeZone
    var _swiftObject: TimeZone { return TimeZone(reference: self) }
}

extension CFTimeZone : _SwiftBridgeable, _NSBridgeable {
    typealias NSType = NSTimeZone
    var _nsObject : NSTimeZone { return unsafeBitCast(self, to: NSTimeZone.self) }
    var _swiftObject: TimeZone { return _nsObject._swiftObject }
}

extension TimeZone : _NSBridgeable, _CFBridgeable {
    typealias NSType = NSTimeZone
    typealias CFType = CFTimeZone
    var _nsObject : NSTimeZone { return _bridgeToObjectiveC() }
    var _cfObject : CFTimeZone { return _nsObject._cfObject }
}

extension NSTimeZone {

    public enum NameStyle : Int {
        case standard    // Central Standard Time
        case shortStandard    // CST
        case daylightSaving    // Central Daylight Time
        case shortDaylightSaving    // CDT
        case generic    // Central Time
        case shortGeneric    // CT
    }

}

extension NSTimeZone : _NSFactory { }

extension NSNotification.Name {
    public static let NSSystemTimeZoneDidChange = NSNotification.Name(rawValue: kCFTimeZoneSystemTimeZoneDidChangeNotification._swiftObject)
}
