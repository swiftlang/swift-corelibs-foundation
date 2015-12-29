// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public struct NSJSONReadingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let MutableContainers = NSJSONReadingOptions(rawValue: 1 << 0)
    public static let MutableLeaves = NSJSONReadingOptions(rawValue: 1 << 1)
    public static let AllowFragments = NSJSONReadingOptions(rawValue: 1 << 2)
}

public struct NSJSONWritingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let PrettyPrinted = NSJSONWritingOptions(rawValue: 1 << 0)
}


/* A class for converting JSON to Foundation/Swift objects and converting Foundation/Swift objects to JSON.
   
   An object that may be converted to JSON must have the following properties:
    - Top level object is a `Swift.Array` or `Swift.Dictionary`
    - All objects are `Swift.String`, `Foundation.NSNumber`, `Swift.Array`, `Swift.Dictionary`,
      or `Foundation.NSNull`
    - All dictionary keys are `Swift.String`s
    - `NSNumber`s are not NaN or infinity
*/

public class NSJSONSerialization : NSObject {
    
    /* Determines whether the given object can be converted to JSON.
       Other rules may apply. Calling this method or attempting a conversion are the definitive ways
       to tell if a given object can be converted to JSON data.
       - parameter obj: The object to test.
       - returns: `true` if `obj` can be converted to JSON, otherwise `false`.
     */
    public class func isValidJSONObject(obj: Any) -> Bool {
        // TODO: - revisit this once bridging story gets fully figured out
        func isValidJSONObjectInternal(obj: Any) -> Bool {
            // object is Swift.String or NSNull
            if obj is String || obj is NSNull {
                return true
            }

            // object is NSNumber and is not NaN or infinity
            if let number = obj as? NSNumber {
                let invalid = number.doubleValue.isInfinite || number.doubleValue.isNaN
                return !invalid
            }

            // object is Swift.Array
            if let array = obj as? [Any] {
                for element in array {
                    guard isValidJSONObjectInternal(element) else {
                        return false
                    }
                }
                return true
            }

            // object is Swift.Dictionary
            if let dictionary = obj as? [String: Any] {
                for (_, value) in dictionary {
                    guard isValidJSONObjectInternal(value) else {
                        return false
                    }
                }
                return true
            }

            // invalid object
            return false
        }

        // top level object must be an Swift.Array or Swift.Dictionary
        guard obj is [Any] || obj is [String: Any] else {
            return false
        }

        return isValidJSONObjectInternal(obj)
    }
    
    /* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
     */
    public class func dataWithJSONObject(obj: AnyObject, options opt: NSJSONWritingOptions) throws -> NSData {
        NSUnimplemented()
    }
    
    /* Create a Foundation object from JSON data. Set the NSJSONReadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary. Setting the NSJSONReadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries. Setting the NSJSONReadingMutableLeaves option will make the parser generate mutable NSString objects. If an error occurs during the parse, then the error parameter will be set and the result will be nil.
       The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE. The data may or may not have a BOM. The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
     */
    /// - Experiment: Note that the return type of this function is different than on Darwin Foundation (Any instead of AnyObject). This is likely to change once we have a more complete story for bridging in place.
    public class func JSONObjectWithData(data: NSData, options opt: NSJSONReadingOptions) throws -> Any {
        
        let bytes = UnsafePointer<UInt8>(data.bytes)
        let encoding: NSStringEncoding
        let buffer: UnsafeBufferPointer<UInt8>
        if let detected = parseBOM(bytes, length: data.length) {
            encoding = detected.encoding
            buffer = UnsafeBufferPointer(start: bytes.advancedBy(detected.skipLength), count: data.length - detected.skipLength)
        }
        else {
            encoding = detectEncoding(bytes, data.length)
            buffer = UnsafeBufferPointer(start: bytes, count: data.length)
        }

        let source = JSONReader.UnicodeSource(buffer: buffer, encoding: encoding)
        let reader = JSONReader(source: source)
        if let (object, _) = try reader.parseObject(0) {
            return object
        }
        else if let (array, _) = try reader.parseArray(0) {
            return array
        }
        else if opt.contains(.AllowFragments), let (value, _) = try reader.parseValue(0) {
            return value
        }
        throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
            "NSDebugDescription" : "JSON text did not start with array or object and option to allow fragments not set."
        ])
    }
    
    /* Write JSON data into a stream. The stream should be opened and configured. The return value is the number of bytes written to the stream, or 0 on error. All other behavior of this method is the same as the dataWithJSONObject:options:error: method.
     */
    public class func writeJSONObject(obj: AnyObject, toStream stream: NSOutputStream, options opt: NSJSONWritingOptions) throws -> Int {
        NSUnimplemented()
    }
    
    /* Create a JSON object from JSON data stream. The stream should be opened and configured. All other behavior of this method is the same as the JSONObjectWithData:options:error: method.
     */
    public class func JSONObjectWithStream(stream: NSInputStream, options opt: NSJSONReadingOptions) throws -> AnyObject {
        NSUnimplemented()
    }
}

//MARK: - Encoding Detection

internal extension NSJSONSerialization {
    
    /// Detect the encoding format of the NSData contents
    class func detectEncoding(bytes: UnsafePointer<UInt8>, _ length: Int) -> NSStringEncoding {

        if length >= 4 {
            switch (bytes[0], bytes[1], bytes[2], bytes[3]) {
            case (0, 0, 0, _):
                return NSUTF32BigEndianStringEncoding
            case (_, 0, 0, 0):
                return NSUTF32LittleEndianStringEncoding
            case (0, _, 0, _):
                return NSUTF16BigEndianStringEncoding
            case (_, 0, _, 0):
                return NSUTF16LittleEndianStringEncoding
            default:
                break
            }
        }
        else if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0, _):
                return NSUTF16BigEndianStringEncoding
            case (_, 0):
                return NSUTF16LittleEndianStringEncoding
            default:
                break
            }
        }
        return NSUTF8StringEncoding
    }
    
    static func parseBOM(bytes: UnsafePointer<UInt8>, length: Int) -> (encoding: NSStringEncoding, skipLength: Int)? {
        if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0xEF, 0xBB):
                if length >= 3 && bytes[2] == 0xBF {
                    return (NSUTF8StringEncoding, 3)
                }
            case (0x00, 0x00):
                if length >= 4 && bytes[2] == 0xFE && bytes[3] == 0xFF {
                    return (NSUTF32BigEndianStringEncoding, 4)
                }
            case (0xFF, 0xFE):
                if length >= 4 && bytes[2] == 0 && bytes[3] == 0 {
                    return (NSUTF32LittleEndianStringEncoding, 4)
                }
                return (NSUTF16LittleEndianStringEncoding, 2)
            case (0xFE, 0xFF):
                return (NSUTF16BigEndianStringEncoding, 2)
            default:
                break
            }
        }
        return nil
    }
}

//MARK: - JSONDeserializer
private struct JSONReader {

    static let whitespaceASCII: [UInt8] = [
        0x09, // Horizontal tab
        0x0A, // Line feed or New line
        0x0D, // Carriage return
        0x20, // Space
    ]

    struct Structure {
        static let BeginArray: UInt8     = 0x5B // [
        static let EndArray: UInt8       = 0x5D // ]
        static let BeginObject: UInt8    = 0x7B // {
        static let EndObject: UInt8      = 0x7D // }
        static let NameSeparator: UInt8  = 0x3A // :
        static let ValueSeparator: UInt8 = 0x2C // ,
        static let QuotationMark: UInt8  = 0x22 // "
        static let Escape: UInt8         = 0x5C // \
    }

    typealias Index = Int

    struct UnicodeSource {
        let buffer: UnsafeBufferPointer<UInt8>
        let encoding: NSStringEncoding
        let step: Int

        init(buffer: UnsafeBufferPointer<UInt8>, encoding: NSStringEncoding) {
            self.buffer = buffer
            self.encoding = encoding

            self.step = {
                switch encoding {
                case NSUTF8StringEncoding:
                    return 1
                case NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding:
                    return 2
                case NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding:
                    return 4
                default:
                    return 1
                }
            }()
        }

        func takeASCII(input: Index) -> (UInt8, Index)? {
            guard hasNext(input) else {
                return nil
            }

            let index: Int
            switch encoding {
            case NSUTF8StringEncoding:
                index = input
            case NSUTF16BigEndianStringEncoding where buffer[input] == 0:
                index = input + 1
            case NSUTF32BigEndianStringEncoding where buffer[input] == 0 && buffer[input+1] == 0 && buffer[input+2] == 0:
                index = input + 3
            case NSUTF16LittleEndianStringEncoding where buffer[input+1] == 0:
                index = input
            case NSUTF32LittleEndianStringEncoding where buffer[input+1] == 0 && buffer[input+2] == 0 && buffer[input+3] == 0:
                index = input
            default:
                return nil
            }
            return (buffer[index] < 0x80) ? (buffer[index], input + step) : nil
        }

        func takeString(begin: Index, end: Index) throws -> String {
            let byteLength = begin.distanceTo(end)
            guard let chunk = NSString(bytes: buffer.baseAddress.advancedBy(begin), length: byteLength, encoding: encoding)?.bridge() else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                    "NSDebugDescription" : "Unable to convert data to a string using the detected encoding. The data may be corrupt."
                    ])
            }
            return chunk
        }

        func hasNext(input: Index) -> Bool {
            return input + step <= buffer.endIndex
        }
        
        func distanceFromStart(index: Index) -> Index.Distance {
            return buffer.startIndex.distanceTo(index) / step
        }
    }

    let source: UnicodeSource

    func consumeWhitespace(input: Index) -> Index? {
        var index = input
        while let (char, nextIndex) = source.takeASCII(index) where JSONReader.whitespaceASCII.contains(char) {
            index = nextIndex
        }
        return index
    }

    func consumeStructure(ascii: UInt8, input: Index) throws -> Index? {
        return try consumeWhitespace(input).flatMap(consumeASCII(ascii)).flatMap(consumeWhitespace)
    }

    func consumeASCII(ascii: UInt8) -> (Index) throws -> Index? {
        return { (input: Index) throws -> Index? in
            switch self.source.takeASCII(input) {
            case nil:
                throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                    "NSDebugDescription" : "Unexpected end of file during JSON parse."
                    ])
            case let (taken, index)? where taken == ascii:
                return index
            default:
                return nil
            }
        }
    }

    func consumeASCIISequence(sequence: String, input: Index) throws -> Index? {
        var index = input
        for scalar in sequence.unicodeScalars {
            guard let nextIndex = try consumeASCII(UInt8(scalar.value))(index) else {
                return nil
            }
            index = nextIndex
        }
        return index
    }

    func takeMatching(match: (UInt8) -> Bool) -> ([Character], Index) -> ([Character], Index)? {
        return { input, index in
            guard let (byte, index) = self.source.takeASCII(index) where match(byte) else {
                return nil
            }
            return (input + [Character(UnicodeScalar(byte))], index)
        }
    }

    //MARK: - String Parsing

    func parseString(input: Index) throws -> (String, Index)? {
        guard let beginIndex = try consumeStructure(Structure.QuotationMark, input: input) else {
            return nil
        }
        var chunkIndex: Int = beginIndex
        var currentIndex: Int = chunkIndex

        var output: String = ""
        while source.hasNext(currentIndex) {
            guard let (ascii, index) = source.takeASCII(currentIndex) else {
                currentIndex += source.step
                continue
            }
            switch ascii {
            case Structure.QuotationMark:
                output += try source.takeString(chunkIndex, end: currentIndex)
                return (output, index)
            case Structure.Escape:
                output += try source.takeString(chunkIndex, end: currentIndex)
                if let (escaped, nextIndex) = try parseEscapeSequence(index) {
                    output += escaped
                    chunkIndex = nextIndex
                    currentIndex = nextIndex
                    continue
                }
                else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                        "NSDebugDescription" : "Invalid escape sequence at position \(source.distanceFromStart(currentIndex))"
                    ])
                }
            default:
                currentIndex = index
            }
        }
        throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
            "NSDebugDescription" : "Unexpected end of file during string parse."
        ])
    }

    func parseEscapeSequence(input: Index) throws -> (String, Index)? {
        guard let (byte, index) = source.takeASCII(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Early end of unicode escape sequence around character"
            ])
        }
        let output: String
        switch byte {
        case 0x22: output = "\""
        case 0x5C: output = "\\"
        case 0x2F: output = "/"
        case 0x62: output = "\u{08}" // \b
        case 0x66: output = "\u{0C}" // \f
        case 0x6E: output = "\u{0A}" // \n
        case 0x72: output = "\u{0D}" // \r
        case 0x74: output = "\u{09}" // \t
        case 0x75: return try parseUnicodeSequence(index)
        default: return nil
        }
        return (output, index)
    }

    func parseUnicodeSequence(input: Index) throws -> (String, Index)? {

        guard let (codeUnit, index) = parseCodeUnit(input) else {
            return nil
        }

        if !UTF16.isLeadSurrogate(codeUnit) {
            return (String(UnicodeScalar(codeUnit)), index)
        }

        guard let (trailCodeUnit, finalIndex) = try consumeASCIISequence("\\u", input: index).flatMap(parseCodeUnit) where UTF16.isTrailSurrogate(trailCodeUnit) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to convert unicode escape sequence (no low-surrogate code point) to UTF8-encoded character at position \(source.distanceFromStart(input))"
            ])
        }

        let highValue = (UInt32(codeUnit  - 0xD800) << 10)
        let lowValue  =  UInt32(trailCodeUnit - 0xDC00)
        return (String(UnicodeScalar(highValue + lowValue + 0x10000)), finalIndex)
    }

    func isHexChr(byte: UInt8) -> Bool {
        return (byte >= 0x30 && byte <= 0x39)
            || (byte >= 0x41 && byte <= 0x46)
            || (byte >= 0x61 && byte <= 0x66)
    }
    func parseCodeUnit(input: Index) -> (UTF16.CodeUnit, Index)? {
        let hexParser = takeMatching(isHexChr)
        guard let (result, index) = hexParser([], input).flatMap(hexParser).flatMap(hexParser).flatMap(hexParser),
            let value = Int(String(result), radix: 16) else {
                return nil
        }
        return (UTF16.CodeUnit(value), index)
    }
    
    //MARK: - Number parsing
    static let numberCodePoints: [UInt8] = [
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, // 0...9
        0x2E, 0x2D, 0x2B, 0x45, 0x65, // . - + E e
    ]
    func parseNumber(input: Index) throws -> (Double, Index)? {
        func parseDouble(address: UnsafePointer<UInt8>) -> (Double, Index.Distance)? {
            let startPointer = UnsafePointer<Int8>(address)
            let endPointer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(1)
            defer { endPointer.dealloc(1) }
            
            let result = strtod(startPointer, endPointer)
            let distance = startPointer.distanceTo(endPointer[0])
            guard distance > 0 else {
                return nil
            }
            
            return (result, distance)
        }
        
        if source.encoding == NSUTF8StringEncoding {
            return parseDouble(source.buffer.baseAddress.advancedBy(input)).map { return ($0.0, input + $0.1) }
        }
        else {
            var numberCharacters = [UInt8]()
            var index = input
            while let (ascii, nextIndex) = source.takeASCII(index) where JSONReader.numberCodePoints.contains(ascii) {
                numberCharacters.append(ascii)
                index = nextIndex
            }
            
            numberCharacters.append(0)
            
            return numberCharacters.withUnsafeBufferPointer { parseDouble($0.baseAddress) }.map { return ($0.0, index) }
        }
    }

    //MARK: - Value parsing
    func parseValue(input: Index) throws -> (Any, Index)? {
        if let (value, parser) = try parseString(input) {
            return (value, parser)
        }
        else if let parser = try consumeASCIISequence("true", input: input) {
            return (true, parser)
        }
        else if let parser = try consumeASCIISequence("false", input: input) {
            return (false, parser)
        }
        else if let parser = try consumeASCIISequence("null", input: input) {
            return (NSNull(), parser)
        }
        else if let (object, parser) = try parseObject(input) {
            return (object, parser)
        }
        else if let (array, parser) = try parseArray(input) {
            return (array, parser)
        }
        else if let (number, parser) = try parseNumber(input) {
            return (number, parser)
        }
        return nil
    }

    //MARK: - Object parsing
    func parseObject(input: Index) throws -> ([String: Any], Index)? {
        guard let beginIndex = try consumeStructure(Structure.BeginObject, input: input) else {
            return nil
        }
        var index = beginIndex
        var output: [String: Any] = [:]
        while true {
            if let finalIndex = try consumeStructure(Structure.EndObject, input: index) {
                return (output, finalIndex)
            }
    
            if let (key, value, nextIndex) = try parseObjectMember(index) {
                output[key] = value
    
                if let finalParser = try consumeStructure(Structure.EndObject, input: nextIndex) {
                    return (output, finalParser)
                }
                else if let nextIndex = try consumeStructure(Structure.ValueSeparator, input: nextIndex) {
                    index = nextIndex
                    continue
                }
                else {
                    return nil
                }
            }
            return nil
        }
    }
    
    func parseObjectMember(input: Index) throws -> (String, Any, Index)? {
        guard let (name, index) = try parseString(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Missing object key at location \(source.distanceFromStart(input))"
            ])
        }
        guard let separatorIndex = try consumeStructure(Structure.NameSeparator, input: index) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid separator at location \(source.distanceFromStart(index))"
            ])
        }
        guard let (value, finalIndex) = try parseValue(separatorIndex) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid value at location \(source.distanceFromStart(separatorIndex))"
            ])
        }
        
        return (name, value, finalIndex)
    }

    //MARK: - Array parsing
    func parseArray(input: Index) throws -> ([Any], Index)? {
        guard let beginIndex = try consumeStructure(Structure.BeginArray, input: input) else {
            return nil
        }
        var index = beginIndex
        var output: [Any] = []
        while true {
            if let finalIndex = try consumeStructure(Structure.EndArray, input: index) {
                return (output, finalIndex)
            }
    
            if let (value, nextIndex) = try parseValue(index) {
                output.append(value)
    
                if let finalIndex = try consumeStructure(Structure.EndArray, input: nextIndex) {
                    return (output, finalIndex)
                }
                else if let nextIndex = try consumeStructure(Structure.ValueSeparator, input: nextIndex) {
                    index = nextIndex
                    continue
                }
            }
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Badly formed array at location \(source.distanceFromStart(index))"
            ])
        }
    }
}
