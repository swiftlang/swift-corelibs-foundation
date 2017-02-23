// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension ByteCountFormatter {
    public struct Units : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        // This causes default units appropriate for the platform to be used. Specifying any units explicitly causes just those units to be used in showing the number.
        public static let useDefault = Units(rawValue: 0)
        //  Specifying any of the following causes the specified units to be used in showing the number.
        public static let useBytes = Units(rawValue: 1 << 0)
        public static let useKB = Units(rawValue: 1 << 1)
        public static let useMB = Units(rawValue: 1 << 2)
        public static let useGB = Units(rawValue: 1 << 3)
        public static let useTB = Units(rawValue: 1 << 4)
        public static let usePB = Units(rawValue: 1 << 5)
        public static let useEB = Units(rawValue: 1 << 6)
        public static let useZB = Units(rawValue: 1 << 7)
        public static let useYBOrHigher = Units(rawValue: 0x0FF << 8)
        // Can use any unit in showing the number.
        public static let useAll = Units(rawValue: 0x0FFFF)
    }

    public enum CountStyle : Int {
        
        // Specifies display of file or storage byte counts. The actual behavior for this is platform-specific; on OS X 10.8, this uses the decimal style, but that may change over time.
        case file
        // Specifies display of memory byte counts. The actual behavior for this is platform-specific; on OS X 10.8, this uses the binary style, but that may change over time.
        case memory
        // The following two allow specifying the number of bytes for KB explicitly. It's better to use one of the above values in most cases.
        case decimal // 1000 bytes are shown as 1 KB
        case binary // 1024 bytes are shown as 1 KB
    }
}

open class ByteCountFormatter : Formatter {
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /* Specify the units that can be used in the output. If NSByteCountFormatterUseDefault, uses platform-appropriate settings; otherwise will only use the specified units. This is the default value. Note that ZB and YB cannot be covered by the range of possible values, but you can still choose to use these units to get fractional display ("0.0035 ZB" for instance).
     */
    open var allowedUnits: Units = .useDefault
    
    /* Specify how the count is displayed by indicating the number of bytes to be used for kilobyte. The default setting is NSByteCountFormatterFileCount, which is the system specific value for file and storage sizes.
     */
    open var countStyle: CountStyle = .file
    
    /* Choose whether to allow more natural display of some values, such as zero, where it may be displayed as "Zero KB," ignoring all other flags or options (with the exception of NSByteCountFormatterUseBytes, which would generate "Zero bytes"). The result is appropriate for standalone output. Default value is YES. Special handling of certain values such as zero is especially important in some languages, so it's highly recommended that this property be left in its default state.
     */
    open var allowsNonnumericFormatting: Bool = true
    
    /* Choose whether to include the number or the units in the resulting formatted string. (For example, instead of 723 KB, returns "723" or "KB".) You can call the API twice to get both parts, separately. But note that putting them together yourself via string concatenation may be wrong for some locales; so use this functionality with care.  Both of these values are YES by default.  Setting both to NO will unsurprisingly result in an empty string.
     */
    open var includesUnit: Bool = true
    open var includesCount: Bool = true
    
    /* Choose whether to parenthetically (localized as appropriate) display the actual number of bytes as well, for instance "723 KB (722,842 bytes)".  This will happen only if needed, that is, the first part is already not showing the exact byte count.  If includesUnit or includesCount are NO, then this setting has no effect.  Default value is NO.
     */
    open var includesActualByteCount: Bool = false
    
    /* Choose the display style. The "adaptive" algorithm is platform specific and uses a different number of fraction digits based on the magnitude (in 10.8: 0 fraction digits for bytes and KB; 1 fraction digits for MB; 2 for GB and above). Otherwise the result always tries to show at least three significant digits, introducing fraction digits as necessary. Default is YES.
     */
    open var isAdaptive: Bool = true
    
    /* Choose whether to zero pad fraction digits so a consistent number of fraction digits are displayed, causing updating displays to remain more stable. For instance, if the adaptive algorithm is used, this option formats 1.19 and 1.2 GB as "1.19 GB" and "1.20 GB" respectively, while without the option the latter would be displayed as "1.2 GB". Default value is NO.
     */
    open var zeroPadsFractionDigits: Bool = false
    
    /* Specify the formatting context for the formatted string. Default is NSFormattingContextUnknown.
     */
    open var formattingContext: Context = .unknown

    /* A variable to store the actual bytes passed into the methods. This value is used if the includesActualByteCount property is set.
    */
    private var actualBytes: String = ""
    
    /* Create an instance of NumberFormatter for use in various methods
    */
    private let numberFormatter = NumberFormatter()
    
    /* Shortcut for converting a byte count into a string without creating an NSByteCountFormatter and an NSNumber. If you need to specify options other than countStyle, create an instance of NSByteCountFormatter first.
    */
    open class func string(fromByteCount byteCount: Int64, countStyle: ByteCountFormatter.CountStyle) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = countStyle
        return formatter.string(fromByteCount: byteCount)
    }
    
    /* Convenience method on string(for:):. Convert a byte count into a string without creating an NSNumber.
    */
    open func string(fromByteCount byteCount: Int64) -> String {
        //Convert actual bytes to a formatted string for use later
        if includesActualByteCount {
            numberFormatter.numberStyle = .decimal
            actualBytes = numberFormatter.string(from: NSNumber(value: byteCount))!
        }
        
        if allowedUnits != .useDefault && allowedUnits != .useAll {
            if countStyle == .file || countStyle == .decimal {
                return unitsToUseFor(byteCount: byteCount, byteSize: decimalByteSize)
            } else {
                return unitsToUseFor(byteCount: byteCount, byteSize: binaryByteSize)
            }
        } else if countStyle == .decimal || countStyle == .file {
            return convertValue(fromByteCount: byteCount, for: decimalByteSize)
        } else {
            return convertValue(fromByteCount: byteCount, for: binaryByteSize)
        }
    }
    
    /* Convenience method on string(for:):. Convert a byte count into a string without creating an NSNumber.
     */
    open override func string(for obj: Any?) -> String? {
        guard let value = obj as? Double else {
            return nil
        }
        
        return string(fromByteCount: Int64(value))
    }
    
    /* If allowedUnits has been set this function will ensure the correct unit is used and conversion is done. The conversion is done by making use of the divide method.
    */
    private func unitsToUseFor(byteCount: Int64, byteSize: [Unit: Double]) -> String {
        let bytes = Double(byteCount)
        
        if bytes == 0 {
            return "Zero \(Unit.KB)"
        } else if bytes == 1 {
            return formatNumberFor(bytes: bytes, unit: Unit.byte)
        }
        
        switch allowedUnits {
        case Units.useBytes: return formatNumberFor(bytes: bytes, unit: Unit.bytes)
        case Units.useKB: return divide(bytes, by: byteSize, for: .KB)
        case Units.useMB: return divide(bytes, by: byteSize, for: .MB)
        case Units.useGB: return divide(bytes, by: byteSize, for: .GB)
        case Units.useTB: return divide(bytes, by: byteSize, for: .TB)
        case Units.usePB: return divide(bytes, by: byteSize, for: .PB)
        case Units.useEB: return divide(bytes, by: byteSize, for: .EB)
        case Units.useZB: return divide(bytes, by: byteSize, for: .ZB)
        default: return divide(bytes, by: byteSize, for: .YB)
            
        }
    }
    
    /* This method accepts a byteCount and a byteSize value. Checks to see what range the byteCount falls into and then converts to the units determined by that range. The range to be used is decided by the byteSize parameter. The conversion is done by making use of the divide method.
    */
    private func convertValue(fromByteCount byteCount: Int64, for byteSize: [Unit: Double]) -> String {
        let byte = Double(byteCount)
        if byte == 0 && allowsNonnumericFormatting {
            return "Zero \(Unit.KB)"
        } else if byte == 1 {
            return "\(byteCount) \(Unit.byte)"
            
        } else if  byte < byteSize[Unit.KB]! && byte > -byteSize[Unit.KB]!{
            return formatNumberFor(bytes: byte, unit: Unit.bytes)
            
        } else if byte < byteSize[Unit.MB]! && byte > -byteSize[Unit.MB]! {
            return divide(byte, by: byteSize, for: .KB)
            
        } else if byte < byteSize[Unit.GB]! && byte > -byteSize[Unit.GB]! {
            return divide(byte, by: byteSize, for: .MB)
            
        } else if byte < byteSize[Unit.TB]! && byte > -byteSize[Unit.TB]! {
            return divide(byte, by: byteSize, for: .GB)
            
        } else if byte < byteSize[Unit.PB]! && byte > -byteSize[Unit.PB]! {
            return divide(byte, by: byteSize, for: .TB)
            
        } else if byte < byteSize[Unit.EB]! && byte > -byteSize[Unit.EB]! {
            return divide(byte, by: byteSize, for: .PB)
            
        } else {
            return divide(byte, by: byteSize, for: .EB)
        }
    }
    
    // Coverts the number of bytes to the correct value given a specified unit, then passes the value and unit to formattedValue
    private func divide(_ bytes: Double, by byteSize: [Unit: Double], for unit: Unit) -> String {
        guard let byteSizeUnit = byteSize[unit] else {
            fatalError("Cannot find value \(unit)")
        }
        let result = bytes/byteSizeUnit
        return formatNumberFor(bytes: result, unit: unit)
    }
    
    //Formats the byte value using the NumberFormatter class based on set properties and the unit passed in as a parameter.
    private func formatNumberFor(bytes: Double, unit: Unit) -> String {
        
        numberFormatter.numberStyle = .decimal
        
        switch (zeroPadsFractionDigits, isAdaptive) {
        //zeroPadsFractionDigits is true, isAdaptive is true
        case (true, true):
            switch unit {
            case .bytes, .byte, .KB:
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 0
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            case .MB:
                numberFormatter.minimumFractionDigits = 1
                numberFormatter.maximumFractionDigits = 1
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            default:
                numberFormatter.minimumFractionDigits = 2
                numberFormatter.maximumFractionDigits = 2
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            }
        //zeroPadsFractionDigits is true, isAdaptive is false
        case (true, false):
            if unit == .byte || unit == .bytes {
                return partsToIncludeFor(value: "\(bytes)", unit: unit)
            } else {
                numberFormatter.usesSignificantDigits = true
                numberFormatter.minimumSignificantDigits = 3
                numberFormatter.maximumSignificantDigits = 3
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            }
        //zeroPadsFractionDigits is false, isAdaptive is true
        case (false, true):
            switch unit {
            case .bytes, .byte, .KB:
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 0
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            case .MB:
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 1
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            default:
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 2
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            }
        //zeroPadsFractionDigits is false, isAdaptive is false
        case (false, false):
            if unit == .byte || unit == .bytes {
                return partsToIncludeFor(value: "\(bytes)", unit: unit)
            } else {
                numberFormatter.usesSignificantDigits = true
                numberFormatter.minimumSignificantDigits = 3
                numberFormatter.maximumSignificantDigits = 3
                let result = numberFormatter.string(from: NSNumber(value: bytes))
                return partsToIncludeFor(value: result!, unit: unit)
            }
        }
    }
    
    // Returns the correct string based on the includesValue and includesUnit properties
    private func partsToIncludeFor(value: String, unit: Unit) -> String {
        if includesActualByteCount, includesUnit, includesCount {
            switch unit {
            case .byte, .bytes: return "\(value) \(unit)"
            default: return "\(value) \(unit) (\(actualBytes) \(Unit.bytes))"
            }
        } else if includesCount, includesUnit {
            return "\(value) \(unit)"
        } else if includesCount, !includesUnit {
            return "\(value)"
        } else if !includesCount, includesUnit {
            return "\(unit)"
        } else {
            return ""
        }
    }
    
    //Enum containing available byte units
    private enum Unit: String {
        case byte
        case bytes
        case KB
        case MB
        case GB
        case TB
        case PB
        case EB
        case ZB
        case YB
    }
    // Maps each unit to it's corresponding value in bytes for decimal
    private let decimalByteSize: [Unit: Double] = [.byte: 1, .KB: 1000, .MB: pow(1000, 2), .GB: pow(1000, 3), .TB: pow(1000, 4), .PB: pow(1000, 5), .EB: pow(1000, 6), .ZB: pow(1000, 7), .YB: pow(1000, 8)]
    
    // Maps each unit to it's corresponding value in bytes for binary
    private let binaryByteSize: [Unit: Double] = [.byte: 1, .KB: 1024, .MB: pow(1024, 2), .GB: pow(1024, 3), .TB: pow(1024, 4), .PB: pow(1024, 5), .EB: pow(1024, 6), .ZB: pow(1024, 7), .YB: pow(1024, 8)]
    
    }

