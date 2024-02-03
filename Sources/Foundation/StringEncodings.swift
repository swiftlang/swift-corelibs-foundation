
extension String.Encoding {
    // Map selected IANA character set names to encodings, see
    // https://www.iana.org/assignments/character-sets/character-sets.xhtml
    internal init?(charSet: String) {
        let encoding: String.Encoding?

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

        self.init(rawValue: value)
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
