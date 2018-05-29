
extension String {
    public struct Encoding : RawRepresentable {
        public var rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let ascii = Encoding(rawValue: 1)
        public static let nextstep = Encoding(rawValue: 2)
        public static let japaneseEUC = Encoding(rawValue: 3)
        public static let utf8 = Encoding(rawValue: 4)
        public static let isoLatin1 = Encoding(rawValue: 5)
        public static let symbol = Encoding(rawValue: 6)
        public static let nonLossyASCII = Encoding(rawValue: 7)
        public static let shiftJIS = Encoding(rawValue: 8)
        public static let isoLatin2 = Encoding(rawValue: 9)
        public static let unicode = Encoding(rawValue: 10)
        public static let windowsCP1251 = Encoding(rawValue: 11)
        public static let windowsCP1252 = Encoding(rawValue: 12)
        public static let windowsCP1253 = Encoding(rawValue: 13)
        public static let windowsCP1254 = Encoding(rawValue: 14)
        public static let windowsCP1250 = Encoding(rawValue: 15)
        public static let iso2022JP = Encoding(rawValue: 21)
        public static let macOSRoman = Encoding(rawValue: 30)
        public static let utf16 = Encoding.unicode
        public static let utf16BigEndian = Encoding(rawValue: 0x90000100)
        public static let utf16LittleEndian = Encoding(rawValue: 0x94000100)
        public static let utf32 = Encoding(rawValue: 0x8c000100)
        public static let utf32BigEndian = Encoding(rawValue: 0x98000100)
        public static let utf32LittleEndian = Encoding(rawValue: 0x9c000100)

        // Map selected IANA character set names to encodings, see
        // https://www.iana.org/assignments/character-sets/character-sets.xhtml
        internal init?(charSet: String) {
            let encoding: Encoding?

            switch charSet.lowercased() {
            case "us-ascii":        encoding = .ascii
            case "utf-8":           encoding = .utf8
            case "utf-16":          encoding = .utf16
            case "utf-16be":        encoding = .utf16BigEndian
            case "utf-16le":        encoding = .utf16LittleEndian
            case "utf-32":          encoding = .utf32
            case "utf-32be":        encoding = .utf32BigEndian
            case "utf-32le":        encoding = .utf32LittleEndian
            case "iso-8859-1":      encoding = .isoLatin1
            case "iso-8859-2":      encoding = .isoLatin2
            case "iso-2022-jp":     encoding = .iso2022JP
            case "windows-1250":    encoding = .windowsCP1250
            case "windows-1251":    encoding = .windowsCP1251
            case "windows-1252":    encoding = .windowsCP1252
            case "windows-1253":    encoding = .windowsCP1253
            case "windows-1254":    encoding = .windowsCP1254
            case "shift_jis":       encoding = .shiftJIS
            case "euc-jp":          encoding = .japaneseEUC
            case "macintosh":       encoding = .macOSRoman
            default:                encoding = nil
            }
            guard let value = encoding?.rawValue else {
                return nil
            }
            rawValue = value
        }
    }
    
    public typealias EncodingConversionOptions = NSString.EncodingConversionOptions
    public typealias EnumerationOptions = NSString.EnumerationOptions
    public typealias CompareOptions = NSString.CompareOptions
}

extension String.Encoding : Hashable {
    public var hashValue : Int {
        return rawValue.hashValue
    }

    public static func ==(lhs: String.Encoding, rhs: String.Encoding) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension String.Encoding : CustomStringConvertible {
    public var description: String {
        return String.localizedName(of: self)
    }
}


@available(*, unavailable, renamed: "String.Encoding")
public typealias NSStringEncoding = UInt

@available(*, unavailable, renamed: "String.Encoding.ascii")
public var NSASCIIStringEncoding: String.Encoding {
    return .ascii
}
@available(*, unavailable, renamed: "String.Encoding.nextstep")
public var NSNEXTSTEPStringEncoding: String.Encoding {
    return .nextstep
}
@available(*, unavailable, renamed: "String.Encoding.japaneseEUC")
public var NSJapaneseEUCStringEncoding: String.Encoding {
    return .japaneseEUC
}
@available(*, unavailable, renamed: "String.Encoding.utf8")
public var NSUTF8StringEncoding: String.Encoding {
    return .utf8
}
@available(*, unavailable, renamed: "String.Encoding.isoLatin1")
public var NSISOLatin1StringEncoding: String.Encoding {
    return .isoLatin1
}
@available(*, unavailable, renamed: "String.Encoding.symbol")
public var NSSymbolStringEncoding: String.Encoding {
    return .symbol
}
@available(*, unavailable, renamed: "String.Encoding.nonLossyASCII")
public var NSNonLossyASCIIStringEncoding: String.Encoding {
    return .nonLossyASCII
}
@available(*, unavailable, renamed: "String.Encoding.shiftJIS")
public var NSShiftJISStringEncoding: String.Encoding {
    return .shiftJIS
}
@available(*, unavailable, renamed: "String.Encoding.isoLatin2")
public var NSISOLatin2StringEncoding: String.Encoding {
    return .isoLatin2
}
@available(*, unavailable, renamed: "String.Encoding.unicode")
public var NSUnicodeStringEncoding: String.Encoding {
    return .unicode
}
@available(*, unavailable, renamed: "String.Encoding.windowsCP1251")
public var NSWindowsCP1251StringEncoding: String.Encoding {
    return .windowsCP1251
}
@available(*, unavailable, renamed: "String.Encoding.windowsCP1252")
public var NSWindowsCP1252StringEncoding: String.Encoding {
    return .windowsCP1252
}
@available(*, unavailable, renamed: "String.Encoding.windowsCP1253")
public var NSWindowsCP1253StringEncoding: String.Encoding {
    return .windowsCP1253
}
@available(*, unavailable, renamed: "String.Encoding.windowsCP1254")
public var NSWindowsCP1254StringEncoding: String.Encoding {
    return .windowsCP1254
}
@available(*, unavailable, renamed: "String.Encoding.windowsCP1250")
public var NSWindowsCP1250StringEncoding: String.Encoding {
    return .windowsCP1250
}
@available(*, unavailable, renamed: "String.Encoding.iso2022JP")
public var NSISO2022JPStringEncoding: String.Encoding {
    return .iso2022JP
}
@available(*, unavailable, renamed: "String.Encoding.macOSRoman")
public var NSMacOSRomanStringEncoding: String.Encoding {
    return .macOSRoman
}
@available(*, unavailable, renamed: "String.Encoding.utf16")
public var NSUTF16StringEncoding: String.Encoding {
    return .utf16
}
@available(*, unavailable, renamed: "String.Encoding.utf16BigEndian")
public var NSUTF16BigEndianStringEncoding: String.Encoding {
    return .utf16BigEndian
}
@available(*, unavailable, renamed: "String.Encoding.utf16LittleEndian")
public var NSUTF16LittleEndianStringEncoding: String.Encoding {
    return .utf16LittleEndian
}
@available(*, unavailable, renamed: "String.Encoding.utf32")
public var NSUTF32StringEncoding: String.Encoding {
    return .utf32
}
@available(*, unavailable, renamed: "String.Encoding.utf32BigEndian")
public var NSUTF32BigEndianStringEncoding: String.Encoding {
    return .utf32BigEndian
}
@available(*, unavailable, renamed: "String.Encoding.utf32LittleEndian")
public var NSUTF32LittleEndianStringEncoding: String.Encoding {
    return .utf32LittleEndian
}
