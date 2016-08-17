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
            let name = aDecoder.decodeObject(of: NSString.self, forKey: "NS.name")
            let data = aDecoder.decodeObject(of: NSData.self, forKey: "NS.data")
            
            if name == nil {
                return nil
            }
            
            self.init(name: String._unconditionallyBridgeFromObjectiveC(name), data: data?._swiftObject)
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
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    open override func isEqual(_ object: AnyObject?) -> Bool {
        if let tz = object as? NSTimeZone {
            return isEqual(to: tz._swiftObject)
        } else {
            return false
        }
    }
    
    open override var description: String {
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

    open func encode(with aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.name._bridgeToObjectiveC(), forKey:"NS.name")
            // darwin versions of this method can and will encode mutable data, however it is not required for compatability
            aCoder.encode(self.data._bridgeToObjectiveC(), forKey:"NS.data")
        } else {
        }
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
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetName(_cfObject)._swiftObject
    }
    
    open var data: Data {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetData(_cfObject)._swiftObject
    }
    
    open func secondsFromGMT(for aDate: Date) -> Int {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return Int(CFTimeZoneGetSecondsFromGMT(_cfObject, aDate.timeIntervalSinceReferenceDate))
    }
    
    open func abbreviation(for aDate: Date) -> String? {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneCopyAbbreviation(_cfObject, aDate.timeIntervalSinceReferenceDate)._swiftObject
    }
    
    open func isDaylightSavingTime(for aDate: Date) -> Bool {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneIsDaylightSavingTime(_cfObject, aDate.timeIntervalSinceReferenceDate)
    }
    
    open func daylightSavingTimeOffset(for aDate: Date) -> TimeInterval {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return CFTimeZoneGetDaylightSavingTimeOffset(_cfObject, aDate.timeIntervalSinceReferenceDate)
    }
    
    open func nextDaylightSavingTimeTransition(after aDate: Date) -> Date? {
        guard type(of: self) === NSTimeZone.self else {
            NSRequiresConcreteImplementation()
        }
        return Date(timeIntervalSinceReferenceDate: CFTimeZoneGetNextDaylightSavingTimeTransition(_cfObject, aDate.timeIntervalSinceReferenceDate))
    }
}

extension NSTimeZone {

    open class func systemTimeZone() -> TimeZone {
        return CFTimeZoneCopySystem()._swiftObject
    }

    open class func resetSystemTimeZone() {
        CFTimeZoneResetSystem()
    }

    open class func defaultTimeZone() -> TimeZone {
        return CFTimeZoneCopyDefault()._swiftObject
    }

    open class func setDefaultTimeZone(_ aTimeZone: TimeZone) {
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
    open class func localTimeZone() -> TimeZone { NSUnimplemented() }
    
    open class var knownTimeZoneNames: [String] { NSUnimplemented() }
    
    open class var abbreviationDictionary: [String : String] {
        get {
            NSUnimplemented()
        }
        set {
            NSUnimplemented()
        }
    }
    
    open class var timeZoneDataVersion: String { NSUnimplemented() }
    
    open var secondsFromGMT: Int { NSUnimplemented() }

    /// The abbreviation for the receiver, such as "EDT" (Eastern Daylight Time). (read-only)
    ///
    /// This invokes `abbreviationForDate:` with the current date as the argument.
    open var abbreviation: String? {
        let currentDate = Date()
        return abbreviation(for: currentDate)
    }

    open var daylightSavingTime: Bool { NSUnimplemented() }
    open var daylightSavingTimeOffset: TimeInterval { NSUnimplemented() }
    /*@NSCopying*/ open var nextDaylightSavingTimeTransition: Date?  { NSUnimplemented() }
    
    open func isEqual(to aTimeZone: TimeZone) -> Bool {
        return CFEqual(self._cfObject, aTimeZone._cfObject)
    }
    
    open func localizedName(_ style: NameStyle, locale: Locale?) -> String? { NSUnimplemented() }
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
