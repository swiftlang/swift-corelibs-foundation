// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public class NSTimeZone : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFTimeZone
    private var _base = _CFInfo(typeID: CFTimeZoneGetTypeID())
    private var _name: UnsafeMutableRawPointer? = nil
    private var _data: UnsafeMutableRawPointer? = nil
    private var _periods: UnsafeMutableRawPointer? = nil
    private var _periodCnt = Int32(0)
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    // Primary creation method is +timeZoneWithName:; the
    // data-taking variants should rarely be used directly
    public convenience init?(name tzName: String) {
        self.init(name: tzName, data: nil)
    }

    public init?(name tzName: String, data aData: Data?) {
        super.init()
        if !_CFTimeZoneInit(_cfObject, tzName._cfObject, aData?._cfObject) {
            return nil
        }
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            let name = aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.name")
            let data = aDecoder.decodeObjectOfClass(NSData.self, forKey: "NS.data")
            
            if name == nil {
                return nil
            }
            
            self.init(name: name!.bridge(), data: data?._swiftObject)
        } else {
            if let name = aDecoder.decodeObject() as? NSString {
                if aDecoder.version(forClassName: "NSTimeZone") == 0 {
                    self.init(name: name._swiftObject)
                } else {
                    let data = aDecoder.decodeObject() as? NSData
                    self.init(name: name._swiftObject, data: data?._swiftObject)
                }
            } else {
                return nil
            }
        }
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let tz = object as? TimeZone {
            return isEqual(to: tz)
        } else {
            return false
        }
    }
    
    public override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }

    deinit {
        _CFDeinit(self)
    }

    // Time zones created with this never have daylight savings and the
    // offset is constant no matter the date; the name and abbreviation
    // do NOT follow the POSIX convention (of minutes-west).
    public convenience init(forSecondsFromGMT seconds: Int) { NSUnimplemented() }
    
    public convenience init?(abbreviation: String) {
        let abbr = abbreviation._cfObject
        guard let name = unsafeBitCast(CFDictionaryGetValue(CFTimeZoneCopyAbbreviationDictionary(), unsafeBitCast(abbr, to: UnsafeRawPointer.self)), to: NSString!.self) else {
            return nil
        }
        self.init(name: name._swiftObject , data: nil)
    }

    public func encode(with aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.name.bridge(), forKey:"NS.name")
            // darwin versions of this method can and will encode mutable data, however it is not required for compatability
            aCoder.encode(self.data._nsObject, forKey:"NS.data")
        } else {
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject {
        return self
    }
    
    public var name: String {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetName(_cfObject)._swiftObject
    }
    
    public var data: Data {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetData(_cfObject)._swiftObject
    }
    
    public func secondsFromGMT(for aDate: Date) -> Int {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return Int(CFTimeZoneGetSecondsFromGMT(_cfObject, aDate.timeIntervalSinceReferenceDate))
    }
    
    public func abbreviation(for aDate: Date) -> String? {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneCopyAbbreviation(_cfObject, aDate.timeIntervalSinceReferenceDate)._swiftObject
    }
    
    public func isDaylightSavingTime(for aDate: Date) -> Bool {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneIsDaylightSavingTime(_cfObject, aDate.timeIntervalSinceReferenceDate)
    }
    
    public func daylightSavingTimeOffset(for aDate: Date) -> TimeInterval {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetDaylightSavingTimeOffset(_cfObject, aDate.timeIntervalSinceReferenceDate)
    }
    
    public func nextDaylightSavingTimeTransition(after aDate: Date) -> Date? {
        guard self.dynamicType === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return Date(timeIntervalSinceReferenceDate: CFTimeZoneGetNextDaylightSavingTimeTransition(_cfObject, aDate.timeIntervalSinceReferenceDate))
    }
}

extension NSTimeZone {

    public class func systemTimeZone() -> TimeZone {
        return CFTimeZoneCopySystem()._swiftObject
    }

    public class func resetSystemTimeZone() {
        CFTimeZoneResetSystem()
    }

    public class func defaultTimeZone() -> TimeZone {
        return CFTimeZoneCopyDefault()._swiftObject
    }

    public class func setDefaultTimeZone(_ aTimeZone: TimeZone) {
        CFTimeZoneSetDefault(aTimeZone._cfObject)
    }
}

extension NSTimeZone: _SwiftBridgable, _CFBridgable {
    typealias SwiftType = TimeZone
    var _swiftObject: TimeZone { return TimeZone(reference: self) }
}

extension CFTimeZone : _SwiftBridgable, _NSBridgable {
    typealias NSType = NSTimeZone
    var _nsObject : NSTimeZone { return unsafeBitCast(self, to: NSTimeZone.self) }
    var _swiftObject: TimeZone { return _nsObject._swiftObject }
}

extension TimeZone : _NSBridgable, _CFBridgable {
    typealias NSType = NSTimeZone
    typealias CFType = CFTimeZone
    var _nsObject : NSTimeZone { return _bridgeToObjectiveC() }
    var _cfObject : CFTimeZone { return _nsObject._cfObject }
}

extension NSTimeZone {
    public class func localTimeZone() -> TimeZone { NSUnimplemented() }
    
    public class var knownTimeZoneNames: [String] { NSUnimplemented() }
    
    public class var abbreviationDictionary: [String : String] {
        get {
            NSUnimplemented()
        }
        set {
            NSUnimplemented()
        }
    }
    
    public class var timeZoneDataVersion: String { NSUnimplemented() }
    
    public var secondsFromGMT: Int { NSUnimplemented() }

    /// The abbreviation for the receiver, such as "EDT" (Eastern Daylight Time). (read-only)
    ///
    /// This invokes `abbreviationForDate:` with the current date as the argument.
    public var abbreviation: String? {
        let currentDate = Date()
        return abbreviation(for: currentDate)
    }

    public var daylightSavingTime: Bool { NSUnimplemented() }
    public var daylightSavingTimeOffset: TimeInterval { NSUnimplemented() }
    /*@NSCopying*/ public var nextDaylightSavingTimeTransition: Date?  { NSUnimplemented() }
    
    public func isEqual(to aTimeZone: TimeZone) -> Bool {
        return CFEqual(self._cfObject, aTimeZone._cfObject)
    }
    
    public func localizedName(_ style: NameStyle, locale: Locale?) -> String? { NSUnimplemented() }
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
