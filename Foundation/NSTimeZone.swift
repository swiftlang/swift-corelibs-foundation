// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public class NSTimeZone : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFTimeZoneRef
    private var _base = _CFInfo(typeID: CFTimeZoneGetTypeID())
    private var _name = UnsafeMutablePointer<Void>()
    private var _data = UnsafeMutablePointer<Void>()
    private var _periods = UnsafeMutablePointer<Void>()
    private var _periodCnt = Int32(0)
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    // Primary creation method is +timeZoneWithName:; the
    // data-taking variants should rarely be used directly
    public convenience init?(name tzName: String) {
        self.init(name: tzName, data: nil)
    }

    public init?(name tzName: String, data aData: NSData?) {
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
            
            self.init(name: name!.bridge(), data: data)
        } else {
            if let name = aDecoder.decodeObject() as? NSString {
                if aDecoder.versionForClassName("NSTimeZone") == 0 {
                    self.init(name: name._swiftObject)
                } else {
                    let data = aDecoder.decodeObject() as? NSData
                    self.init(name: name._swiftObject, data: data)
                }
            } else {
                return nil
            }
        }
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let tz = object as? NSTimeZone {
            return isEqualToTimeZone(tz)
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
    
    public convenience init?(abbreviation: String) { NSUnimplemented() }

    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeObject(self.name.bridge(), forKey:"NS.name")
            // darwin versions of this method can and will encode mutable data, however it is not required for compatability
            aCoder.encodeObject(self.data, forKey:"NS.data")
        } else {
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public var name: String {
        if self.dynamicType === NSTimeZone.self {
            return CFTimeZoneGetName(_cfObject)._swiftObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public var data: NSData {
        if self.dynamicType === NSTimeZone.self {
            return CFTimeZoneGetData(_cfObject)._nsObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func secondsFromGMTForDate(aDate: NSDate) -> Int {
        if self.dynamicType === NSTimeZone.self {
            return Int(CFTimeZoneGetSecondsFromGMT(_cfObject, aDate.timeIntervalSinceReferenceDate))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func abbreviationForDate(aDate: NSDate) -> String? {
        if self.dynamicType === NSTimeZone.self {
            return CFTimeZoneCopyAbbreviation(_cfObject, aDate.timeIntervalSinceReferenceDate)._swiftObject
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func isDaylightSavingTimeForDate(aDate: NSDate) -> Bool {
        if self.dynamicType === NSTimeZone.self {
            return CFTimeZoneIsDaylightSavingTime(_cfObject, aDate.timeIntervalSinceReferenceDate)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func daylightSavingTimeOffsetForDate(aDate: NSDate) -> NSTimeInterval {
        if self.dynamicType === NSTimeZone.self {
            return CFTimeZoneGetDaylightSavingTimeOffset(_cfObject, aDate.timeIntervalSinceReferenceDate)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func nextDaylightSavingTimeTransitionAfterDate(aDate: NSDate) -> NSDate? {
        if self.dynamicType === NSTimeZone.self {
            return NSDate(timeIntervalSinceReferenceDate: CFTimeZoneGetNextDaylightSavingTimeTransition(_cfObject, aDate.timeIntervalSinceReferenceDate))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
}

extension NSTimeZone {

    public class func systemTimeZone() -> NSTimeZone {
        return CFTimeZoneCopySystem()._nsObject
    }

    public class func resetSystemTimeZone() {
        CFTimeZoneResetSystem()
    }

    public class func defaultTimeZone() -> NSTimeZone {
        return CFTimeZoneCopyDefault()._nsObject
    }

    public class func setDefaultTimeZone(aTimeZone: NSTimeZone) {
        CFTimeZoneSetDefault(aTimeZone._cfObject)
    }
}

extension NSTimeZone : _CFBridgable { }

extension CFTimeZoneRef : _NSBridgable {
    typealias NSType = NSTimeZone
    internal var _nsObject : NSType {
        return unsafeBitCast(self, NSType.self)
    }
}

extension NSTimeZone {
    public class func localTimeZone() -> NSTimeZone { NSUnimplemented() }
    
    public class func knownTimeZoneNames() -> [String] { NSUnimplemented() }
    
    public class func abbreviationDictionary() -> [String : String] { NSUnimplemented() }
    public class func setAbbreviationDictionary(dict: [String : String]) { NSUnimplemented() }
    
    public class func timeZoneDataVersion() -> String { NSUnimplemented() }
    
    public var secondsFromGMT: Int { NSUnimplemented() }

    /// The abbreviation for the receiver, such as "EDT" (Eastern Daylight Time). (read-only)
    ///
    /// This invokes `abbreviationForDate:` with the current date as the argument.
    public var abbreviation: String? {
        let currentDate = NSDate()
        return abbreviationForDate(currentDate)
    }

    public var daylightSavingTime: Bool { NSUnimplemented() }
    public var daylightSavingTimeOffset: NSTimeInterval { NSUnimplemented() }
    /*@NSCopying*/ public var nextDaylightSavingTimeTransition: NSDate?  { NSUnimplemented() }
    
    public func isEqualToTimeZone(aTimeZone: NSTimeZone) -> Bool {
        return CFEqual(self._cfObject, aTimeZone._cfObject)
    }
    
    public func localizedName(style: NSTimeZoneNameStyle, locale: NSLocale?) -> String? { NSUnimplemented() }
}
public enum NSTimeZoneNameStyle : Int {
    case Standard    // Central Standard Time
    case ShortStandard    // CST
    case DaylightSaving    // Central Daylight Time
    case ShortDaylightSaving    // CDT
    case Generic    // Central Time
    case ShortGeneric    // CT
}

