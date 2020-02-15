// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension JSONSerialization {
    public struct ReadingOptions : OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let mutableContainers = ReadingOptions(rawValue: 1 << 0)
        public static let mutableLeaves = ReadingOptions(rawValue: 1 << 1)
        public static let allowFragments = ReadingOptions(rawValue: 1 << 2)
    }

    public struct WritingOptions : OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let prettyPrinted = WritingOptions(rawValue: 1 << 0)
        public static let sortedKeys = WritingOptions(rawValue: 1 << 1)
    }
}


/* A class for converting JSON to Foundation/Swift objects and converting Foundation/Swift objects to JSON.
   
   An object that may be converted to JSON must have the following properties:
    - Top level object is a `Swift.Array` or `Swift.Dictionary`
    - All objects are `Swift.String`, `Foundation.NSNumber`, `Swift.Array`, `Swift.Dictionary`,
      or `Foundation.NSNull`
    - All dictionary keys are `Swift.String`s
    - `NSNumber`s are not NaN or infinity
*/

open class JSONSerialization : NSObject {
    
    /* Determines whether the given object can be converted to JSON.
       Other rules may apply. Calling this method or attempting a conversion are the definitive ways
       to tell if a given object can be converted to JSON data.
       - parameter obj: The object to test.
       - returns: `true` if `obj` can be converted to JSON, otherwise `false`.
     */
    open class func isValidJSONObject(_ obj: Any) -> Bool {
        // TODO: - revisit this once bridging story gets fully figured out
        func isValidJSONObjectInternal(_ obj: Any?) -> Bool {
            // Emulate the SE-0140 behavior bridging behavior for nils
            guard let obj = obj else {
                return true
            }
            
            if !(obj is _NSNumberCastingWithoutBridging) {
              if obj is String || obj is NSNull || obj is Int || obj is Bool || obj is UInt ||
                  obj is Int8 || obj is Int16 || obj is Int32 || obj is Int64 ||
                  obj is UInt8 || obj is UInt16 || obj is UInt32 || obj is UInt64 {
                  return true
              }
            }

            // object is a Double and is not NaN or infinity
            if let number = obj as? Double  {
                return number.isFinite
            }
            // object is a Float and is not NaN or infinity
            if let number = obj as? Float  {
                return number.isFinite
            }

            if let number = obj as? Decimal {
                return number.isFinite
            }

            // object is Swift.Array
            if let array = obj as? [Any?] {
                for element in array {
                    guard isValidJSONObjectInternal(element) else {
                        return false
                    }
                }
                return true
            }

            // object is Swift.Dictionary
            if let dictionary = obj as? [String: Any?] {
                for (_, value) in dictionary {
                    guard isValidJSONObjectInternal(value) else {
                        return false
                    }
                }
                return true
            }

            // object is NSNumber and is not NaN or infinity
            // For better performance, this (most expensive) test should be last.
            if let number = __SwiftValue.store(obj) as? NSNumber {
                if CFNumberIsFloatType(number._cfObject) {
                    let dv = number.doubleValue
                    let invalid = dv.isInfinite || dv.isNaN
                    return !invalid
                } else {
                    return true
                }
            }

            // invalid object
            return false
        }

        // top level object must be an Swift.Array or Swift.Dictionary
        guard obj is [Any?] || obj is [String: Any?] else {
            return false
        }

        return isValidJSONObjectInternal(obj)
    }
    
    /* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
     */
    internal class func _data(withJSONObject value: Any, options opt: WritingOptions, stream: Bool) throws -> Data {
        var jsonStr = [UInt8]()
        
        var writer = JSONWriter(
            pretty: opt.contains(.prettyPrinted),
            sortedKeys: opt.contains(.sortedKeys),
            writer: { (str: String?) in
                if let str = str {
                    jsonStr.append(contentsOf: str.utf8)
                }
            }
        )
        
        if let container = value as? NSArray {
            try writer.serializeJSON(container._bridgeToSwift())
        } else if let container = value as? NSDictionary {
            try writer.serializeJSON(container._bridgeToSwift())
        } else if let container = value as? Array<Any> {
            try writer.serializeJSON(container)
        } else if let container = value as? Dictionary<AnyHashable, Any> {
            try writer.serializeJSON(container)
        } else {
            fatalError("Top-level object was not NSArray or NSDictionary") // This is a fatal error in objective-c too (it is an NSInvalidArgumentException)
        }

        let count = jsonStr.count
        return Data(bytes: &jsonStr, count: count)
    }

    open class func data(withJSONObject value: Any, options opt: WritingOptions = []) throws -> Data {
        return try _data(withJSONObject: value, options: opt, stream: false)
    }
    
    /* Create a Foundation object from JSON data. Set the NSJSONReadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary. Setting the NSJSONReadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries. Setting the NSJSONReadingMutableLeaves option will make the parser generate mutable NSString objects. If an error occurs during the parse, then the error parameter will be set and the result will be nil.
       The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE. The data may or may not have a BOM. The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
     */
    open class func jsonObject(with data: Data, options opt: ReadingOptions = []) throws -> Any {
        return try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Any in
            let encoding: String.Encoding
            let buffer: UnsafeBufferPointer<UInt8>
            if let detected = parseBOM(bytes, length: data.count) {
                encoding = detected.encoding
                buffer = UnsafeBufferPointer(start: bytes.advanced(by: detected.skipLength), count: data.count - detected.skipLength)
            }
            else {
                encoding = detectEncoding(bytes, data.count)
                buffer = UnsafeBufferPointer(start: bytes, count: data.count)
            }
            
            let source = JSONReader.UnicodeSource(buffer: buffer, encoding: encoding)
            let reader = JSONReader(source: source)
            if let (object, _) = try reader.parseObject(0, options: opt) {
                return object
            }
            else if let (array, _) = try reader.parseArray(0, options: opt) {
                return array
            }
            else if opt.contains(.allowFragments), let (value, _) = try reader.parseValue(0, options: opt) {
                return value
            }
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "JSON text did not start with array or object and option to allow fragments not set."
            ])
        }
        
    }
    
    /* Write JSON data into a stream. The stream should be opened and configured. The return value is the number of bytes written to the stream, or 0 on error. All other behavior of this method is the same as the dataWithJSONObject:options:error: method.
     */
    open class func writeJSONObject(_ obj: Any, toStream stream: OutputStream, options opt: WritingOptions) throws -> Int {
        let jsonData = try _data(withJSONObject: obj, options: opt, stream: true)
        let count = jsonData.count
        return jsonData.withUnsafeBytes { (bytePtr: UnsafePointer<UInt8>) -> Int in
            let res: Int = stream.write(bytePtr, maxLength: count)
            /// TODO: If the result here is negative the error should be obtained from the stream to propagate as a throw
            return res
        }
    }
    
    /* Create a JSON object from JSON data stream. The stream should be opened and configured. All other behavior of this method is the same as the JSONObjectWithData:options:error: method.
     */
    open class func jsonObject(with stream: InputStream, options opt: ReadingOptions = []) throws -> Any {
        var data = Data()
        guard stream.streamStatus == .open || stream.streamStatus == .reading else {
            fatalError("Stream is not available for reading")
        }
        repeat {
            var buffer = [UInt8](repeating: 0, count: 1024)
            var bytesRead: Int = 0
            bytesRead = stream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                throw stream.streamError!
            } else {
                data.append(&buffer, count: bytesRead)
            }
        } while stream.hasBytesAvailable
        return try jsonObject(with: data, options: opt)
    }
}

//MARK: - Encoding Detection

internal extension JSONSerialization {
    
    /// Detect the encoding format of the NSData contents
    class func detectEncoding(_ bytes: UnsafePointer<UInt8>, _ length: Int) -> String.Encoding {

        if length >= 4 {
            switch (bytes[0], bytes[1], bytes[2], bytes[3]) {
            case (0, 0, 0, _):
                return .utf32BigEndian
            case (_, 0, 0, 0):
                return .utf32LittleEndian
            case (0, _, 0, _):
                return .utf16BigEndian
            case (_, 0, _, 0):
                return .utf16LittleEndian
            default:
                break
            }
        }
        else if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0, _):
                return .utf16BigEndian
            case (_, 0):
                return .utf16LittleEndian
            default:
                break
            }
        }
        return .utf8
    }
    
    static func parseBOM(_ bytes: UnsafePointer<UInt8>, length: Int) -> (encoding: String.Encoding, skipLength: Int)? {
        if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0xEF, 0xBB):
                if length >= 3 && bytes[2] == 0xBF {
                    return (.utf8, 3)
                }
            case (0x00, 0x00):
                if length >= 4 && bytes[2] == 0xFE && bytes[3] == 0xFF {
                    return (.utf32BigEndian, 4)
                }
            case (0xFF, 0xFE):
                if length >= 4 && bytes[2] == 0 && bytes[3] == 0 {
                    return (.utf32LittleEndian, 4)
                }
                return (.utf16LittleEndian, 2)
            case (0xFE, 0xFF):
                return (.utf16BigEndian, 2)
            default:
                break
            }
        }
        return nil
    }
}

//MARK: - JSONSerializer
private struct JSONWriter {

    var indent = 0
    let pretty: Bool
    let sortedKeys: Bool
    let writer: (String?) -> Void

    init(pretty: Bool = false, sortedKeys: Bool = false, writer: @escaping (String?) -> Void) {
        self.pretty = pretty
        self.sortedKeys = sortedKeys
        self.writer = writer
    }
    
    mutating func serializeJSON(_ object: Any?) throws {

        var toSerialize = object

        if let number = toSerialize as? _NSNumberCastingWithoutBridging {
            toSerialize = number._swiftValueOfOptimalType
        }
        
        guard let obj = toSerialize else {
            try serializeNull()
            return
        }
        
        // For better performance, the most expensive conditions to evaluate should be last.
        switch (obj) {
        case let str as String:
            try serializeString(str)
        case let boolValue as Bool:
            writer(boolValue.description)
        case let num as Int:
            writer(num.description)
        case let num as Int8:
            writer(num.description)
        case let num as Int16:
            writer(num.description)
        case let num as Int32:
            writer(num.description)
        case let num as Int64:
            writer(num.description)
        case let num as UInt:
            writer(num.description)
        case let num as UInt8:
            writer(num.description)
        case let num as UInt16:
            writer(num.description)
        case let num as UInt32:
            writer(num.description)
        case let num as UInt64:
            writer(num.description)
        case let array as Array<Any?>:
            try serializeArray(array)
        case let dict as Dictionary<AnyHashable, Any?>:
            try serializeDictionary(dict)
        case let num as Float:
            try serializeFloat(num)
        case let num as Double:
            try serializeFloat(num)
        case let num as Decimal:
            writer(num.description)
        case let num as NSDecimalNumber:
            writer(num.description)
        case is NSNull:
            try serializeNull()
        case _ where __SwiftValue.store(obj) is NSNumber:
            let num = __SwiftValue.store(obj) as! NSNumber
            writer(num.description)
        default:
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [NSDebugDescriptionErrorKey : "Invalid object cannot be serialized"])
        }
    }

    func serializeString(_ str: String) throws {
        writer("\"")
        for scalar in str.unicodeScalars {
            switch scalar {
                case "\"":
                    writer("\\\"") // U+0022 quotation mark
                case "\\":
                    writer("\\\\") // U+005C reverse solidus
                case "/":
                    writer("\\/") // U+002F solidus
                case "\u{8}":
                    writer("\\b") // U+0008 backspace
                case "\u{c}":
                    writer("\\f") // U+000C form feed
                case "\n":
                    writer("\\n") // U+000A line feed
                case "\r":
                    writer("\\r") // U+000D carriage return
                case "\t":
                    writer("\\t") // U+0009 tab
                case "\u{0}"..."\u{f}":
                    writer("\\u000\(String(scalar.value, radix: 16))") // U+0000 to U+000F
                case "\u{10}"..."\u{1f}":
                    writer("\\u00\(String(scalar.value, radix: 16))") // U+0010 to U+001F
                default:
                    writer(String(scalar))
            }
        }
        writer("\"")
    }

    private func serializeFloat<T: FloatingPoint & LosslessStringConvertible>(_ num: T) throws {
        guard num.isFinite else {
             throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [NSDebugDescriptionErrorKey : "Invalid number value (\(num)) in JSON write"])
        }
        var str = num.description
        if str.hasSuffix(".0") {
            str.removeLast(2)
        }
        writer(str)
    }

    mutating func serializeNumber(_ num: NSNumber) throws {
        if CFNumberIsFloatType(num._cfObject) {
            try serializeFloat(num.doubleValue)
        } else {
            switch num._cfTypeID {
            case CFBooleanGetTypeID():
                writer(num.boolValue.description)
            default:
                writer(num.stringValue)
            }
        }
    }

    mutating func serializeArray(_ array: [Any?]) throws {
        writer("[")
        if pretty {
            writer("\n")
            incIndent()
        }
        
        var first = true
        for elem in array {
            if first {
                first = false
            } else if pretty {
                writer(",\n")
            } else {
                writer(",")
            }
            if pretty {
                writeIndent()
            }
            try serializeJSON(elem)
        }
        if pretty {
            writer("\n")
            decAndWriteIndent()
        }
        writer("]")
    }

    mutating func serializeDictionary(_ dict: Dictionary<AnyHashable, Any?>) throws {
        writer("{")
        if pretty {
            writer("\n")
            incIndent()
            if dict.count > 0 {
                writeIndent()
            }
        }

        var first = true

        func serializeDictionaryElement(key: AnyHashable, value: Any?) throws {
            if first {
                first = false
            } else if pretty {
                writer(",\n")
                writeIndent()
            } else {
                writer(",")
            }

            if let key = key as? String {
                try serializeString(key)
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [NSDebugDescriptionErrorKey : "NSDictionary key must be NSString"])
            }
            pretty ? writer(" : ") : writer(":")
            try serializeJSON(value)
        }

        if sortedKeys {
            let elems = try dict.sorted(by: { a, b in
                guard let a = a.key as? String,
                    let b = b.key as? String else {
                        throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [NSDebugDescriptionErrorKey : "NSDictionary key must be NSString"])
                }
                let options: NSString.CompareOptions = [.numeric, .caseInsensitive, .forcedOrdering]
                let range: Range<String.Index>  = a.startIndex..<a.endIndex
                let locale = NSLocale.system

                return a.compare(b, options: options, range: range, locale: locale) == .orderedAscending
            })
            for elem in elems {
                try serializeDictionaryElement(key: elem.key, value: elem.value)
            }
        } else {
            for (key, value) in dict {
                try serializeDictionaryElement(key: key, value: value)
            }
        }

        if pretty {
            writer("\n")
            decAndWriteIndent()
        }
        writer("}")
    }

    func serializeNull() throws {
        writer("null")
    }
    
    let indentAmount = 2

    mutating func incIndent() {
        indent += indentAmount
    }

    mutating func incAndWriteIndent() {
        indent += indentAmount
        writeIndent()
    }
    
    mutating func decAndWriteIndent() {
        indent -= indentAmount
        writeIndent()
    }
    
    func writeIndent() {
        for _ in 0..<indent {
            writer(" ")
        }
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
    typealias IndexDistance = Int

    struct UnicodeSource {
        let buffer: UnsafeBufferPointer<UInt8>
        let encoding: String.Encoding
        let step: Int

        init(buffer: UnsafeBufferPointer<UInt8>, encoding: String.Encoding) {
            self.buffer = buffer
            self.encoding = encoding

            self.step = {
                switch encoding {
                case .utf8:
                    return 1
                case .utf16BigEndian, .utf16LittleEndian:
                    return 2
                case .utf32BigEndian, .utf32LittleEndian:
                    return 4
                default:
                    return 1
                }
            }()
        }

        func takeASCII(_ input: Index) -> (UInt8, Index)? {
            guard hasNext(input) else {
                return nil
            }

            let index: Int
            switch encoding {
            case .utf8:
                index = input
            case .utf16BigEndian where buffer[input] == 0:
                index = input + 1
            case .utf32BigEndian where buffer[input] == 0 && buffer[input+1] == 0 && buffer[input+2] == 0:
                index = input + 3
            case .utf16LittleEndian where buffer[input+1] == 0:
                index = input
            case .utf32LittleEndian where buffer[input+1] == 0 && buffer[input+2] == 0 && buffer[input+3] == 0:
                index = input
            default:
                return nil
            }
            return (buffer[index] < 0x80) ? (buffer[index], input + step) : nil
        }

        func takeString(_ begin: Index, end: Index) throws -> String {
            let byteLength = begin.distance(to: end)
            
            guard let chunk = String(data: Data(bytes: buffer.baseAddress!.advanced(by: begin), count: byteLength), encoding: encoding) else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unable to convert data to a string using the detected encoding. The data may be corrupt."
                    ])
            }
            return chunk
        }

        func hasNext(_ input: Index) -> Bool {
            return input + step <= buffer.endIndex
        }
        
        func distanceFromStart(_ index: Index) -> IndexDistance {
            return buffer.startIndex.distance(to: index) / step
        }
    }

    let source: UnicodeSource

    func consumeWhitespace(_ input: Index) -> Index? {
        var index = input
        while let (char, nextIndex) = source.takeASCII(index), JSONReader.whitespaceASCII.contains(char) {
            index = nextIndex
        }
        return index
    }

    func consumeStructure(_ ascii: UInt8, input: Index) throws -> Index? {
        return try consumeWhitespace(input).flatMap(consumeASCII(ascii)).flatMap(consumeWhitespace)
    }

    func consumeASCII(_ ascii: UInt8) -> (Index) throws -> Index? {
        return { (input: Index) throws -> Index? in
            switch self.source.takeASCII(input) {
            case nil:
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unexpected end of file during JSON parse."
                    ])
            case let (taken, index)? where taken == ascii:
                return index
            default:
                return nil
            }
        }
    }

    func consumeASCIISequence(_ sequence: String, input: Index) throws -> Index? {
        var index = input
        for scalar in sequence.unicodeScalars {
            guard let nextIndex = try consumeASCII(UInt8(scalar.value))(index) else {
                return nil
            }
            index = nextIndex
        }
        return index
    }

    func takeMatching(_ match: @escaping (UInt8) -> Bool) -> ([Character], Index) -> ([Character], Index)? {
        return { input, index in
            guard let (byte, index) = self.source.takeASCII(index), match(byte) else {
                return nil
            }
            return (input + [Character(UnicodeScalar(byte))], index)
        }
    }

    //MARK: - String Parsing

    func parseString(_ input: Index) throws -> (String, Index)? {
        guard let beginIndex = try consumeWhitespace(input).flatMap(consumeASCII(Structure.QuotationMark)) else {
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
                    throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                        NSDebugDescriptionErrorKey : "Invalid escape sequence at position \(source.distanceFromStart(currentIndex))"
                    ])
                }
            default:
                currentIndex = index
            }
        }
        throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
            NSDebugDescriptionErrorKey : "Unexpected end of file during string parse."
        ])
    }

    func parseEscapeSequence(_ input: Index) throws -> (String, Index)? {
        guard let (byte, index) = source.takeASCII(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Early end of unicode escape sequence around character"
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

    func parseUnicodeSequence(_ input: Index) throws -> (String, Index)? {

        guard let (codeUnit, index) = parseCodeUnit(input) else {
            return nil
        }

        let isLeadSurrogate = UTF16.isLeadSurrogate(codeUnit)
        let isTrailSurrogate = UTF16.isTrailSurrogate(codeUnit)

        guard isLeadSurrogate || isTrailSurrogate else {
            // The code units that are neither lead surrogates nor trail surrogates
            // form valid unicode scalars.
            return (String(UnicodeScalar(codeUnit)!), index)
        }

        // Surrogates must always come in pairs.

        guard isLeadSurrogate else {
            // Trail surrogate must come after lead surrogate
            throw CocoaError.error(.propertyListReadCorrupt,
                                   userInfo: [
                                     NSDebugDescriptionErrorKey : """
                                      Unable to convert unicode escape sequence (no high-surrogate code point) \
                                      to UTF8-encoded character at position \(source.distanceFromStart(input))
                                      """
                                   ])
        }

        guard let (trailCodeUnit, finalIndex) = try consumeASCIISequence("\\u", input: index).flatMap(parseCodeUnit),
              UTF16.isTrailSurrogate(trailCodeUnit) else {
            throw CocoaError.error(.propertyListReadCorrupt,
                                   userInfo: [
                                     NSDebugDescriptionErrorKey : """
                                      Unable to convert unicode escape sequence (no low-surrogate code point) \
                                      to UTF8-encoded character at position \(source.distanceFromStart(input))
                                      """
                                   ])
        }

        return (String(UTF16.decode(UTF16.EncodedScalar([codeUnit, trailCodeUnit]))), finalIndex)
    }

    func isHexChr(_ byte: UInt8) -> Bool {
        return (byte >= 0x30 && byte <= 0x39)
            || (byte >= 0x41 && byte <= 0x46)
            || (byte >= 0x61 && byte <= 0x66)
    }

    func parseCodeUnit(_ input: Index) -> (UTF16.CodeUnit, Index)? {
        let hexParser = takeMatching(isHexChr)
        guard let (result, index) = hexParser([], input).flatMap(hexParser).flatMap(hexParser).flatMap(hexParser),
            let value = Int(String(result), radix: 16) else {
                return nil
        }
        return (UTF16.CodeUnit(value), index)
    }
    
    //MARK: - Number parsing
    private static let ZERO = UInt8(ascii: "0")
    private static let ONE = UInt8(ascii: "1")
    private static let NINE = UInt8(ascii: "9")
    private static let MINUS = UInt8(ascii: "-")
    private static let PLUS = UInt8(ascii: "+")
    private static let LOWER_EXPONENT = UInt8(ascii: "e")
    private static let UPPER_EXPONENT = UInt8(ascii: "E")
    private static let DECIMAL_SEPARATOR = UInt8(ascii: ".")
    private static let allDigits = (ZERO...NINE)
    private static let oneToNine = (ONE...NINE)

    private static let numberCodePoints: [UInt8] = {
        var numberCodePoints = Array(ZERO...NINE)
        numberCodePoints.append(contentsOf: [DECIMAL_SEPARATOR, MINUS, PLUS, LOWER_EXPONENT, UPPER_EXPONENT])
        return numberCodePoints
    }()


    func parseNumber(_ input: Index, options opt: JSONSerialization.ReadingOptions) throws -> (Any, Index)? {

        var isNegative = false
        var string = ""
        var isInteger = true
        var exponent = 0
        var positiveExponent = true
        var index = input
        var digitCount: Int?
        var ascii: UInt8 = 0    // set by nextASCII()

        // Validate the input is a valid JSON number, also gather the following
        // about the input: isNegative, isInteger, the exponent and if it is +/-,
        // and finally the count of digits including excluding an '.'
        func checkJSONNumber() throws -> Bool {
            // Return true if the next character is any one of the valid JSON number characters
            func nextASCII() -> Bool {
                guard let (ch, nextIndex) = source.takeASCII(index),
                    JSONReader.numberCodePoints.contains(ch) else { return false }

                index = nextIndex
                ascii = ch
                string.append(Character(UnicodeScalar(ascii)))
                return true
            }

            // Consume as many digits as possible and return with the next non-digit
            // or nil if end of string.
            func readDigits() -> UInt8? {
                while let (ch, nextIndex) = source.takeASCII(index) {
                    if !JSONReader.allDigits.contains(ch) {
                        return ch
                    }
                    string.append(Character(UnicodeScalar(ch)))
                    index = nextIndex
                }
                return nil
            }

            guard nextASCII() else { return false }

            if ascii == JSONReader.MINUS {
                isNegative = true
                guard nextASCII() else { return false }
            }

            if JSONReader.oneToNine.contains(ascii) {
                guard let ch = readDigits() else { return true }
                ascii = ch
                if [ JSONReader.DECIMAL_SEPARATOR, JSONReader.LOWER_EXPONENT, JSONReader.UPPER_EXPONENT ].contains(ascii) {
                    guard nextASCII() else { return false } // There should be at least one char as readDigits didn't remove the '.eE'
                }
            } else if ascii == JSONReader.ZERO {
                guard nextASCII() else { return true }
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue,
                              userInfo: [NSDebugDescriptionErrorKey : "Numbers must start with a 1-9 at character \(input)." ])
            }

            if ascii == JSONReader.DECIMAL_SEPARATOR {
                isInteger = false
                guard readDigits() != nil else { return true }
                guard nextASCII() else { return true }
            } else if JSONReader.allDigits.contains(ascii) {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue,
                              userInfo: [NSDebugDescriptionErrorKey : "Leading zeros not allowed at character \(input)." ])
            }

            digitCount = string.count - (isInteger ? 0 : 1) - (isNegative ? 1 : 0)
            guard ascii == JSONReader.LOWER_EXPONENT || ascii == JSONReader.UPPER_EXPONENT else {
                // End of valid number characters
                return true
            }
            digitCount = digitCount! - 1

            // Process the exponent
            isInteger = false
            guard nextASCII() else { return false }
            if ascii == JSONReader.MINUS {
                positiveExponent = false
                guard nextASCII() else { return false }
            } else if ascii == JSONReader.PLUS {
                positiveExponent = true
                guard nextASCII() else { return false }
            }
            guard JSONReader.allDigits.contains(ascii) else { return false }
            exponent = Int(ascii - JSONReader.ZERO)
            while nextASCII() {
                guard JSONReader.allDigits.contains(ascii) else { return false } // Invalid exponent character
                exponent = (exponent * 10) + Int(ascii - JSONReader.ZERO)
                if exponent > 324 {
                    // Exponent is too large to store in a Double
                    return false
                }
            }
            return true
        }

        guard try checkJSONNumber() == true else { return nil }
        digitCount = digitCount ?? string.count - (isInteger ? 0 : 1) - (isNegative ? 1 : 0)

        // Try Int64() or UInt64() first
        if isInteger {
            if isNegative {
                if digitCount! <= 19, let intValue = Int64(string) {
                    return (NSNumber(value: intValue), index)
                }
            } else {
                if digitCount! <= 20, let uintValue = UInt64(string) {
                    return (NSNumber(value: uintValue), index)
                }
            }
        }

        // Decimal holds more digits of precision but a smaller exponent than Double
        // so try that if the exponent fits and there are more digits than Double can hold
        if digitCount! > 17 && exponent >= -128 && exponent <= 127,
            let decimal = Decimal(string: string), decimal.isFinite {
            return (NSDecimalNumber(decimal: decimal), index)
        }
        // Fall back to Double() for everything else
        if let doubleValue = Double(string) {
            return (NSNumber(value: doubleValue), index)
        }
        return nil
    }

    //MARK: - Value parsing
    func parseValue(_ input: Index, options opt: JSONSerialization.ReadingOptions) throws -> (Any, Index)? {
        if let (value, parser) = try parseString(input) {
            return (value, parser)
        }
        else if let parser = try consumeASCIISequence("true", input: input) {
            return (NSNumber(value: true), parser)
        }
        else if let parser = try consumeASCIISequence("false", input: input) {
            return (NSNumber(value: false), parser)
        }
        else if let parser = try consumeASCIISequence("null", input: input) {
            return (NSNull(), parser)
        }
        else if let (object, parser) = try parseObject(input, options: opt) {
            return (object, parser)
        }
        else if let (array, parser) = try parseArray(input, options: opt) {
            return (array, parser)
        }
        else if let (number, parser) = try parseNumber(input, options: opt) {
            return (number, parser)
        }
        return nil
    }

    //MARK: - Object parsing
    func parseObject(_ input: Index, options opt: JSONSerialization.ReadingOptions) throws -> ([String: Any], Index)? {
        guard let beginIndex = try consumeStructure(Structure.BeginObject, input: input) else {
            return nil
        }
        var index = beginIndex
        var output: [String: Any] = [:]
        while true {
            if let finalIndex = try consumeStructure(Structure.EndObject, input: index) {
                return (output, finalIndex)
            }
    
            if let (key, value, nextIndex) = try parseObjectMember(index, options: opt) {
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
    
    func parseObjectMember(_ input: Index, options opt: JSONSerialization.ReadingOptions) throws -> (String, Any, Index)? {
        guard let (name, index) = try parseString(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Missing object key at location \(source.distanceFromStart(input))"
            ])
        }
        guard let separatorIndex = try consumeStructure(Structure.NameSeparator, input: index) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Invalid separator at location \(source.distanceFromStart(index))"
            ])
        }
        guard let (value, finalIndex) = try parseValue(separatorIndex, options: opt) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Invalid value at location \(source.distanceFromStart(separatorIndex))"
            ])
        }
        
        return (name, value, finalIndex)
    }

    //MARK: - Array parsing
    func parseArray(_ input: Index, options opt: JSONSerialization.ReadingOptions) throws -> ([Any], Index)? {
        guard let beginIndex = try consumeStructure(Structure.BeginArray, input: input) else {
            return nil
        }
        var index = beginIndex
        var output: [Any] = []
        while true {
            if let finalIndex = try consumeStructure(Structure.EndArray, input: index) {
                return (output, finalIndex)
            }
    
            if let (value, nextIndex) = try parseValue(index, options: opt) {
                output.append(value)
    
                if let finalIndex = try consumeStructure(Structure.EndArray, input: nextIndex) {
                    return (output, finalIndex)
                }
                else if let nextIndex = try consumeStructure(Structure.ValueSeparator, input: nextIndex) {
                    index = nextIndex
                    continue
                }
            }
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Badly formed array at location \(source.distanceFromStart(index))"
            ])
        }
    }
}
