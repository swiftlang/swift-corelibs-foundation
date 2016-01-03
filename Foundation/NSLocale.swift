// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public class NSLocale : NSObject, NSCopying, NSSecureCoding {
    typealias CFType = CFLocaleRef
    private var _base = _CFInfo(typeID: CFLocaleGetTypeID())
    private var _identifier = UnsafeMutablePointer<Void>()
    private var _cache = UnsafeMutablePointer<Void>()
    private var _prefs = UnsafeMutablePointer<Void>()
#if os(OSX) || os(iOS)
    private var _lock = pthread_mutex_t()
#elseif os(Linux)
    private var _lock = Int32(0)
#endif
    private var _nullLocale = false
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    public func objectForKey(key: String) -> AnyObject? {
        return CFLocaleGetValue(_cfObject, key._cfObject)
    }
    
    public func displayNameForKey(key: String, value: String) -> String? {
        return CFLocaleCopyDisplayNameForPropertyValue(_cfObject, key._cfObject, value._cfObject)?._swiftObject
    }
    
    public init(localeIdentifier string: String) {
        super.init()
        _CFLocaleInit(_cfObject, string._cfObject)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            guard let identifier = aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.identifier") else {
                return nil
            }
            self.init(localeIdentifier: identifier.bridge())
        } else {
            NSUnimplemented()
        }
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject { NSUnimplemented() }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            let identifier = CFLocaleGetIdentifier(self._cfObject)
            aCoder.encodeObject(identifier, forKey: "NS.identifier")
        } else {
            NSUnimplemented()
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
}

extension NSLocale {
    public class func currentLocale() -> NSLocale {
        return CFLocaleCopyCurrent()._nsObject
    }
    
    public class func systemLocale() -> NSLocale {
        return CFLocaleGetSystem()._nsObject
    }
}

extension NSLocale {
    
    public class func availableLocaleIdentifiers() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyAvailableLocaleIdentifiers()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func ISOLanguageCodes() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyISOLanguageCodes()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func ISOCountryCodes() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyISOCountryCodes()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func ISOCurrencyCodes() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyISOCurrencyCodes()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func commonISOCurrencyCodes() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyCommonISOCurrencyCodes()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func preferredLanguages() -> [String] {
        var identifiers = Array<String>()
        for obj in CFLocaleCopyPreferredLanguages()._nsObject {
            identifiers.append((obj as! NSString)._swiftObject)
        }
        return identifiers
    }
    
    public class func componentsFromLocaleIdentifier(string: String) -> [String : String] {
        var comps = Dictionary<String, String>()
        CFLocaleCreateComponentsFromLocaleIdentifier(kCFAllocatorSystemDefault, string._cfObject)._nsObject.enumerateKeysAndObjectsUsingBlock { (key: NSObject, object: AnyObject, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            comps[(key as! NSString)._swiftObject] = (object as! NSString)._swiftObject
        }
        return comps
    }
    
    public class func localeIdentifierFromComponents(dict: [String : String]) -> String {
        return CFLocaleCreateLocaleIdentifierFromComponents(kCFAllocatorSystemDefault, dict._cfObject)._swiftObject
    }
    
    public class func canonicalLocaleIdentifierFromString(string: String) -> String {
        return CFLocaleCreateCanonicalLocaleIdentifierFromString(kCFAllocatorSystemDefault, string._cfObject)._swiftObject
    }
    
    public class func canonicalLanguageIdentifierFromString(string: String) -> String {
        return CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorSystemDefault, string._cfObject)._swiftObject
    }
    
    public class func localeIdentifierFromWindowsLocaleCode(lcid: UInt32) -> String? {
        return CFLocaleCreateLocaleIdentifierFromWindowsLocaleCode(kCFAllocatorSystemDefault, lcid)._swiftObject
    }
    
    public class func windowsLocaleCodeFromLocaleIdentifier(localeIdentifier: String) -> UInt32 {
        return CFLocaleGetWindowsLocaleCodeFromLocaleIdentifier(localeIdentifier._cfObject)
    }
    
    public class func characterDirectionForLanguage(isoLangCode: String) -> NSLocaleLanguageDirection {
        let dir = CFLocaleGetLanguageCharacterDirection(isoLangCode._cfObject)
#if os(OSX) || os(iOS)
        return NSLocaleLanguageDirection(rawValue: UInt(dir.rawValue))!
#else
        return NSLocaleLanguageDirection(rawValue: UInt(dir))!
#endif
    }
    
    public class func lineDirectionForLanguage(isoLangCode: String) -> NSLocaleLanguageDirection {
        let dir = CFLocaleGetLanguageLineDirection(isoLangCode._cfObject)
#if os(OSX) || os(iOS)
        return NSLocaleLanguageDirection(rawValue: UInt(dir.rawValue))!
#else
        return NSLocaleLanguageDirection(rawValue: UInt(dir))!
#endif
    }
}

public enum NSLocaleLanguageDirection : UInt {
    case Unknown
    case LeftToRight
    case RightToLeft
    case TopToBottom
    case BottomToTop
}

public let NSCurrentLocaleDidChangeNotification: String = "kCFLocaleCurrentLocaleDidChangeNotification"

public let NSLocaleIdentifier: String = "kCFLocaleIdentifierKey"
public let NSLocaleLanguageCode: String = "kCFLocaleLanguageCodeKey"
public let NSLocaleCountryCode: String = "kCFLocaleCountryCodeKey"
public let NSLocaleScriptCode: String = "kCFLocaleScriptCodeKey"
public let NSLocaleVariantCode: String = "kCFLocaleVariantCodeKey"
public let NSLocaleExemplarCharacterSet: String = "kCFLocaleExemplarCharacterSetKey"
public let NSLocaleCalendar: String = "kCFLocaleCalendarKey"
public let NSLocaleCollationIdentifier: String = "collation"
public let NSLocaleUsesMetricSystem: String = "kCFLocaleUsesMetricSystemKey"
public let NSLocaleMeasurementSystem: String = "kCFLocaleMeasurementSystemKey"
public let NSLocaleDecimalSeparator: String = "kCFLocaleDecimalSeparatorKey"
public let NSLocaleGroupingSeparator: String = "kCFLocaleGroupingSeparatorKey"
public let NSLocaleCurrencySymbol: String = "kCFLocaleCurrencySymbolKey"
public let NSLocaleCurrencyCode: String = "currency"
public let NSLocaleCollatorIdentifier: String = "kCFLocaleCollatorIdentifierKey"
public let NSLocaleQuotationBeginDelimiterKey: String = "kCFLocaleQuotationBeginDelimiterKey"
public let NSLocaleQuotationEndDelimiterKey: String = "kCFLocaleQuotationEndDelimiterKey"
public let NSLocaleCalendarIdentifier: String = "kCFLocaleCalendarIdentifierKey"
public let NSLocaleAlternateQuotationBeginDelimiterKey: String = "kCFLocaleAlternateQuotationBeginDelimiterKey"
public let NSLocaleAlternateQuotationEndDelimiterKey: String = "kCFLocaleAlternateQuotationEndDelimiterKey"

extension CFLocaleRef : _NSBridgable {
    typealias NSType = NSLocale
    internal var _nsObject: NSLocale {
        return unsafeBitCast(self, NSType.self)
    }
}
