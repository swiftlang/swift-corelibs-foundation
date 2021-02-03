// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation

extension JSONSerialization {
    public struct ReadingOptions : OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let mutableContainers = ReadingOptions(rawValue: 1 << 0)
        public static let mutableLeaves = ReadingOptions(rawValue: 1 << 1)
        
        public static let fragmentsAllowed = ReadingOptions(rawValue: 1 << 2)
        @available(swift, deprecated: 100000, renamed: "JSONSerialization.ReadingOptions.fragmentsAllowed")
        public static let allowFragments = ReadingOptions(rawValue: 1 << 2)
    }

    public struct WritingOptions : OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let prettyPrinted = WritingOptions(rawValue: 1 << 0)
        public static let sortedKeys = WritingOptions(rawValue: 1 << 1)
        public static let fragmentsAllowed = WritingOptions(rawValue: 1 << 2)
        public static let withoutEscapingSlashes = WritingOptions(rawValue: 1 << 3)
    }
}

extension JSONSerialization {
    // Structures with container nesting deeper than this limit are not valid if passed in in-memory for validation, nor if they are read during deserialization.
    // This matches Darwin Foundation's validation behavior.
    fileprivate static let maximumRecursionDepth = 512
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
        var recursionDepth = 0
        
        // TODO: - revisit this once bridging story gets fully figured out
        func isValidJSONObjectInternal(_ obj: Any?) -> Bool {
            // Match Darwin Foundation in not considering a deep object valid.
            guard recursionDepth < JSONSerialization.maximumRecursionDepth else { return false }
            recursionDepth += 1
            defer { recursionDepth -= 1 }
            
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
            options: opt,
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
            guard opt.contains(.fragmentsAllowed) else {
                fatalError("Top-level object was not NSArray or NSDictionary") // This is a fatal error in objective-c too (it is an NSInvalidArgumentException)
            }
            try writer.serializeJSON(value)
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
        do {
            let jsonValue = try data.withUnsafeBytes { (ptr) -> JSONValue in
                // first parse boom
                var encoding: String.Encoding? = nil
                if let (encoding, advanceBy) = parseBOM(ptr) {
                    let newPtr = ptr[advanceBy..<ptr.count]
                    let json = String(bytes: newPtr, encoding: encoding)!
                    return try json.utf8.withContiguousStorageIfAvailable { (utf8) -> JSONValue in
                        var parser = JSONParser(bytes: utf8)
                        return try parser.parse()
                    }!
                }
                
                // second try to detect encoding in another way
                if encoding == nil {
                    encoding = JSONSerialization.detectEncoding(ptr)
                }
                
                // if utf8 all is good
                if encoding == .utf8 {
                    var parser = JSONParser(bytes: ptr)
                    return try parser.parse()
                }
                
                #warning("@Fabian: pretty sure we should throw an error here, if this is invalid data")
                let json = String(bytes: ptr, encoding: encoding!)!
                return try json.utf8.withContiguousStorageIfAvailable { (utf8) -> JSONValue in
                    var parser = JSONParser(bytes: utf8)
                    return try parser.parse()
                }!
            }
            
            if jsonValue.isValue, !opt.contains(.fragmentsAllowed) {
                throw JSONError.singleFragmentFoundButNotAllowed
            }
            
            return try jsonValue.toObjcRepresentation(options: opt)
        } catch let error as JSONError {
            switch error {
            case .unexpectedEndOfFile:
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unexpected end of file during JSON parse."
                ])
            case .unexpectedCharacter(_, let characterIndex):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Invalid value around character \(characterIndex)."
                ])
            case .expectedLowSurrogateUTF8SequenceAfterHighSurrogate:
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unexpected end of file during string parse (expected low-surrogate code point but did not find one)."
                ])
            case .couldNotCreateUnicodeScalarFromUInt32:
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unable to convert hex escape sequence (no high character) to UTF8-encoded character."
                ])
            case .unexpectedEscapedCharacter(_, _, let index):
                // we lower the failure index by one to match the darwin implementations counting
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Invalid escape sequence around character \(index - 1)."
                ])
            case .singleFragmentFoundButNotAllowed:
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "JSON text did not start with array or object and option to allow fragments not set."
                ])
            case .tooManyNestedArraysOrDictionaries(characterIndex: let characterIndex):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Too many nested arrays or dictionaries around character \(characterIndex + 1)."
                ])
            case .invalidHexDigitSequence(let string, index: let index):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : #"Invalid hex encoded sequence in "\#(string)" at \#(index)."#
                ])
            case .unescapedControlCharacterInString(ascii: let ascii, in: _, index: let index) where ascii == UInt8(ascii: "\\"):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : #"Invalid escape sequence around character \#(index)."#
                ])
            case .unescapedControlCharacterInString(ascii: _, in: _, index: let index):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : #"Unescaped control character around character \#(index)."#
                ])
            case .numberWithLeadingZero(index: let index):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : #"Number with leading zero around character \#(index)."#
                ])
            case .numberIsNotRepresentableInSwift(parsed: let parsed):
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : #"Number \#(parsed) is not representable in Swift."#
                ])
            }
        } catch {
            preconditionFailure("Only `JSONError` expected")
        }
        
    }
    
    /* Write JSON data into a stream. The stream should be opened and configured. The return value is the number of bytes written to the stream, or 0 on error. All other behavior of this method is the same as the dataWithJSONObject:options:error: method.
     */
    open class func writeJSONObject(_ obj: Any, toStream stream: OutputStream, options opt: WritingOptions) throws -> Int {
        let jsonData = try _data(withJSONObject: obj, options: opt, stream: true)
        return jsonData.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Int in
            let ptr = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            let res: Int = stream.write(ptr, maxLength: rawBuffer.count)
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
            let buffer = try [UInt8](unsafeUninitializedCapacity: 1024) { buf, initializedCount in
                let bytesRead = stream.read(buf.baseAddress!, maxLength: buf.count)
                initializedCount = bytesRead
                guard bytesRead >= 0 else {
                    throw stream.streamError!
                }
            }
            data.append(buffer, count: buffer.count)
        } while stream.hasBytesAvailable
        return try jsonObject(with: data, options: opt)
    }
}

//MARK: - Encoding Detection

private extension JSONSerialization {
    /// Detect the encoding format of the NSData contents
    static func detectEncoding(_ bytes: UnsafeRawBufferPointer) -> String.Encoding {
        if bytes.count >= 4 {
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
        else if bytes.count >= 2 {
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
    
    static func parseBOM(_ bytes: UnsafeRawBufferPointer) -> (encoding: String.Encoding, skipLength: Int)? {
        guard bytes.count >= 2 else {
            return nil
        }
        
        if bytes.starts(with: Self.utf8BOM) {
            return (.utf8, 3)
        }
        if bytes.starts(with: Self.utf32BigEndianBOM) {
            return (.utf32BigEndian, 4)
        }
        if bytes.starts(with: Self.utf32LittleEndianBOM) {
            return (.utf32LittleEndian, 4)
        }
        if bytes.starts(with: [0xFF, 0xFE]) {
            return (.utf16LittleEndian, 2)
        }
        if bytes.starts(with: [0xFE, 0xFF]) {
            return (.utf16BigEndian, 2)
        }
        
        return nil
    }
    
    // These static properties don't look very nice, but we need them to
    // workaround: https://bugs.swift.org/browse/SR-14102
    private static let utf8BOM: [UInt8] = [0xEF, 0xBB, 0xBF]
    private static let utf32BigEndianBOM: [UInt8] = [0x00, 0x00, 0xFE, 0xFF]
    private static let utf32LittleEndianBOM: [UInt8] = [0xFF, 0xFE, 0x00, 0x00]
    private static let utf16BigEndianBOM: [UInt8] = [0xFF, 0xFE]
    private static let utf16LittleEndianBOM: [UInt8] = [0xFE, 0xFF]
}

//MARK: - JSONSerializer
private struct JSONWriter {

    var indent = 0
    let pretty: Bool
    let sortedKeys: Bool
    let withoutEscapingSlashes: Bool
    let writer: (String?) -> Void

    init(options: JSONSerialization.WritingOptions, writer: @escaping (String?) -> Void) {
        pretty = options.contains(.prettyPrinted)
        sortedKeys = options.contains(.sortedKeys)
        withoutEscapingSlashes = options.contains(.withoutEscapingSlashes)
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
                    if !withoutEscapingSlashes { writer("\\") }
                    writer("/") // U+002F solidus
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
private struct JSONParser {
    
    var reader: DocumentReader
    var depth: Int = 0
    
    init<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8 {
        self.reader = DocumentReader(bytes: [UInt8](bytes))
    }

    mutating func parse() throws -> JSONValue {
        let value = try parseValue()
        #if DEBUG
        defer {
            guard self.depth == 0 else {
                preconditionFailure("Expected to end parsing with a depth of 0")
            }
        }
        #endif

        // handle extra character if top level was number
        if case .number = value {
            guard let extraCharacter = reader.value else {
                return value
            }

            switch extraCharacter {
            case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                break
            default:
                throw JSONError.unexpectedCharacter(ascii: extraCharacter, characterIndex: reader.index)
            }
        }

        while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                continue
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        return value
    }

    // MARK: Generic Value Parsing

    mutating func parseValue() throws -> JSONValue {
        while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: "\""):
                return .string(try self.parseString())
            case UInt8(ascii: "{"):
                let object = try parseObject()
                return .object(object)
            case UInt8(ascii: "["):
                let array = try parseArray()
                return .array(array)
            case UInt8(ascii: "f"), UInt8(ascii: "t"):
                let bool = try parseBool()
                return .bool(bool)
            case UInt8(ascii: "n"):
                try self.parseNull()
                return .null

            case UInt8(ascii: "-"), UInt8(ascii: "0") ... UInt8(ascii: "9"):
                let number = try parseNumber()
                return .number(number)
            case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                continue
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        throw JSONError.unexpectedEndOfFile
    }

    // MARK: - Parse Null -

    mutating func parseNull() throws {
        guard self.reader.read()?.0 == UInt8(ascii: "u"),
              self.reader.read()?.0 == UInt8(ascii: "l"),
              self.reader.read()?.0 == UInt8(ascii: "l")
        else {
            guard let value = reader.value else {
                throw JSONError.unexpectedEndOfFile
            }

            throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
        }
    }

    // MARK: - Parse Bool -

    mutating func parseBool() throws -> Bool {
        switch self.reader.value {
        case UInt8(ascii: "t"):
            guard self.reader.read()?.0 == UInt8(ascii: "r"),
                  self.reader.read()?.0 == UInt8(ascii: "u"),
                  self.reader.read()?.0 == UInt8(ascii: "e")
            else {
                guard let value = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
            }

            return true
        case UInt8(ascii: "f"):
            guard self.reader.read()?.0 == UInt8(ascii: "a"),
                  self.reader.read()?.0 == UInt8(ascii: "l"),
                  self.reader.read()?.0 == UInt8(ascii: "s"),
                  self.reader.read()?.0 == UInt8(ascii: "e")
            else {
                guard let value = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
            }

            return false
        default:
            preconditionFailure("Expected to have `t` or `f` as first character")
        }
    }

    // MARK: - Parse String -

    mutating func parseString() throws -> String {
        try self.reader.readUTF8StringTillNextUnescapedQuote()
    }

    // MARK: - Parse Number -

    enum ControlCharacter {
        case operand
        case decimalPoint
        case exp
        case expOperator
    }

    mutating func parseNumber() throws -> String {
        var pastControlChar: ControlCharacter = .operand
        var numbersSinceControlChar: UInt = 0
        var hasLeadingZero = false

        // parse first character

        let stringStartIndex = self.reader.index
        switch self.reader.value! {
        case UInt8(ascii: "0"):
            numbersSinceControlChar = 1
            pastControlChar = .operand
            hasLeadingZero = true
        case UInt8(ascii: "1") ... UInt8(ascii: "9"):
            numbersSinceControlChar = 1
            pastControlChar = .operand
        case UInt8(ascii: "-"):
            numbersSinceControlChar = 0
            pastControlChar = .operand
        default:
            preconditionFailure("This state should never be reached")
        }

        // parse everything else

        while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: "0"):
                if hasLeadingZero {
                    throw JSONError.numberWithLeadingZero(index: index)
                }
                if numbersSinceControlChar == 0, pastControlChar == .operand {
                    // the number started with a minus. this is the leading zero.
                    hasLeadingZero = true
                }
                numbersSinceControlChar += 1
            case UInt8(ascii: "1") ... UInt8(ascii: "9"):
                if hasLeadingZero {
                    throw JSONError.numberWithLeadingZero(index: index)
                }
                numbersSinceControlChar += 1
            case UInt8(ascii: "."):
                guard numbersSinceControlChar > 0, pastControlChar == .operand else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                hasLeadingZero = false

                pastControlChar = .decimalPoint
                numbersSinceControlChar = 0

            case UInt8(ascii: "e"), UInt8(ascii: "E"):
                guard numbersSinceControlChar > 0,
                      pastControlChar == .operand || pastControlChar == .decimalPoint
                else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                hasLeadingZero = false

                pastControlChar = .exp
                numbersSinceControlChar = 0
            case UInt8(ascii: "+"), UInt8(ascii: "-"):
                guard numbersSinceControlChar == 0, pastControlChar == .exp else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                pastControlChar = .expOperator
                numbersSinceControlChar = 0
            case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                guard numbersSinceControlChar > 0 else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                return self.reader.makeStringFast(self.reader[stringStartIndex ..< index])
            case UInt8(ascii: ","), UInt8(ascii: "]"), UInt8(ascii: "}"):
                guard numbersSinceControlChar > 0 else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                return self.reader.makeStringFast(self.reader[stringStartIndex ..< index])
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        guard numbersSinceControlChar > 0 else {
            throw JSONError.unexpectedEndOfFile
        }

        return String(decoding: self.reader.remainingBytes(from: stringStartIndex), as: Unicode.UTF8.self)
    }

    // MARK: - Parse Array -

    enum ArrayState {
        case expectValueOrEnd
        case expectValue
        case expectSeperatorOrEnd
    }

    mutating func parseArray() throws -> [JSONValue] {
        assert(self.reader.value == UInt8(ascii: "["))
        guard self.depth < 512 else {
            throw JSONError.tooManyNestedArraysOrDictionaries(characterIndex: self.reader.index)
        }
        self.depth += 1
        defer { depth -= 1 }
        var state = ArrayState.expectValueOrEnd

        var array = [JSONValue]()
        array.reserveCapacity(10)

        // parse first value or immidiate end

        do {
            let value = try parseValue()
            array.append(value)

            if case .number = value {
                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case UInt8(ascii: ","):
                    state = .expectValue
                case UInt8(ascii: "]"):
                    return array
                case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: reader.index)
                }
            } else {
                state = .expectSeperatorOrEnd
            }
        } catch JSONError.unexpectedCharacter(ascii: UInt8(ascii: "]"), _) {
            return []
        }

        // parse further

        while true {
            switch state {
            case .expectSeperatorOrEnd:
                // parsing for seperator or end

                seperatorloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                        continue
                    case UInt8(ascii: "]"):
                        return array
                    case UInt8(ascii: ","):
                        state = .expectValue
                        break seperatorloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                if state != .expectValue {
                    throw JSONError.unexpectedEndOfFile
                }
            case .expectValue:
                let value = try parseValue()
                array.append(value)

                guard case .number = value else {
                    state = .expectSeperatorOrEnd
                    continue
                }

                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case UInt8(ascii: ","):
                    state = .expectValue
                case UInt8(ascii: "]"):
                    return array
                case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: self.reader.index)
                }
            case .expectValueOrEnd:
                preconditionFailure("this state should not be reachable at this point")
            }
        }
    }

    // MARK: - Object parsing -

    enum ObjectState: Equatable {
        case expectKeyOrEnd
        case expectKey
        case expectColon(key: String)
        case expectValue(key: String)
        case expectSeperatorOrEnd
    }

    mutating func parseObject() throws -> [String: JSONValue] {
        assert(self.reader.value == UInt8(ascii: "{"))
        guard self.depth < 512 else {
            throw JSONError.tooManyNestedArraysOrDictionaries(characterIndex: self.reader.index)
        }
        self.depth += 1
        defer { depth -= 1 }

        var state = ObjectState.expectKeyOrEnd

        // parse first key or end immidiatly
        loop: while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                continue
            case UInt8(ascii: "\""):
                state = .expectColon(key: try self.parseString())
                break loop
            case UInt8(ascii: "}"):
                return [:]
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        guard case .expectColon = state else {
            throw JSONError.unexpectedEndOfFile
        }

        var object = [String: JSONValue]()
        object.reserveCapacity(20)

        while true {
            switch state {
            case .expectKey:
                keyloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case UInt8(ascii: "\""):
                        let key = try parseString()
                        state = .expectColon(key: key)
                        break keyloop
                    case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                        continue
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectColon = state else {
                    throw JSONError.unexpectedEndOfFile
                }

            case .expectColon(let key):
                colonloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                        continue
                    case UInt8(ascii: ":"):
                        state = .expectValue(key: key)
                        break colonloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectValue = state else {
                    throw JSONError.unexpectedEndOfFile
                }

            case .expectValue(let key):
                let value = try parseValue()
                object[key] = value

                // special handling for numbers
                guard case .number = value else {
                    state = .expectSeperatorOrEnd
                    continue
                }

                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case UInt8(ascii: ","):
                    state = .expectKey
                case UInt8(ascii: "}"):
                    return object
                case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: self.reader.index)
                }

            case .expectSeperatorOrEnd:
                seperatorloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case UInt8(ascii: " "), UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\t"):
                        continue
                    case UInt8(ascii: "}"):
                        return object
                    case UInt8(ascii: ","):
                        state = .expectKey
                        break seperatorloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectKey = state else {
                    throw JSONError.unexpectedEndOfFile
                }
            case .expectKeyOrEnd:
                preconditionFailure("this state should be unreachable here")
            }
        }
    }
}

private extension JSONParser {
    
    struct DocumentReader {
        let array: [UInt8]
        let count: Int

        private(set) var index: Int = -1
        private(set) var value: UInt8?

        init(bytes: [UInt8]) {
            self.array = bytes
            self.count = self.array.count
        }

        subscript(bounds: Range<Int>) -> ArraySlice<UInt8> {
            self.array[bounds]
        }

        mutating func read() -> (UInt8, Int)? {
            guard self.index < self.count - 1 else {
                self.value = nil
                self.index = self.array.endIndex
                return nil
            }

            self.index += 1
            self.value = self.array[self.index]

            return (self.value!, self.index)
        }

        func remainingBytes(from index: Int) -> ArraySlice<UInt8> {
            self.array.suffix(from: index)
        }

        enum EscapedSequenceError: Swift.Error {
            case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: Int)
            case unexpectedEscapedCharacter(ascii: UInt8, index: Int)
            case couldNotCreateUnicodeScalarFromUInt32(index: Int, unicodeScalarValue: UInt32)
        }

        mutating func readUTF8StringTillNextUnescapedQuote() throws -> String {
            precondition(self.value == UInt8(ascii: "\""), "Expected to have read a quote character last")
            var stringStartIndex = self.index + 1
            var output: String?

            while let (byte, index) = read() {
                switch byte {
                case UInt8(ascii: "\""):
                    guard var result = output else {
                        // if we don't have an output string we create a new string
                        return self.makeStringFast(self.array[stringStartIndex ..< index])
                    }
                    // if we have an output string we append
                    result += self.makeStringFast(self.array[stringStartIndex ..< index])
                    return result

                case 0 ... 31:
                    // All Unicode characters may be placed within the
                    // quotation marks, except for the characters that must be escaped:
                    // quotation mark, reverse solidus, and the control characters (U+0000
                    // through U+001F).
                    var string = output ?? ""
                    string += self.makeStringFast(self.array[stringStartIndex ... index])
                    throw JSONError.unescapedControlCharacterInString(ascii: byte, in: string, index: index)

                case UInt8(ascii: "\\"):
                    if output != nil {
                        output! += self.makeStringFast(self.array[stringStartIndex ..< index])
                    } else {
                        output = self.makeStringFast(self.array[stringStartIndex ..< index])
                    }

                    do {
                        let (escaped, newIndex) = try parseEscapeSequence()
                        output! += escaped
                        stringStartIndex = newIndex + 1
                    } catch EscapedSequenceError.unexpectedEscapedCharacter(let ascii, let failureIndex) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.unexpectedEscapedCharacter(ascii: ascii, in: output!, index: failureIndex)
                    } catch EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(let failureIndex) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: output!, index: failureIndex)
                    } catch EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(let failureIndex, let unicodeScalarValue) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.couldNotCreateUnicodeScalarFromUInt32(
                            in: output!, index: failureIndex, unicodeScalarValue: unicodeScalarValue
                        )
                    }

                default:
                    continue
                }
            }

            throw JSONError.unexpectedEndOfFile
        }

        // can be removed as soon https://bugs.swift.org/browse/SR-12126 and
        // https://bugs.swift.org/browse/SR-12125 has landed.
        // Thanks @weissi for making my code fast!
        func makeStringFast<Bytes: Collection>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
            if let string = bytes.withContiguousStorageIfAvailable({ String(decoding: $0, as: Unicode.UTF8.self) }) {
                return string
            } else {
                return String(decoding: bytes, as: Unicode.UTF8.self)
            }
        }

        mutating func parseEscapeSequence() throws -> (String, Int) {
            guard let (byte, index) = read() else {
                throw JSONError.unexpectedEndOfFile
            }

            switch byte {
            case 0x22: return ("\"", index)
            case 0x5C: return ("\\", index)
            case 0x2F: return ("/", index)
            case 0x62: return ("\u{08}", index) // \b
            case 0x66: return ("\u{0C}", index) // \f
            case 0x6E: return ("\u{0A}", index) // \n
            case 0x72: return ("\u{0D}", index) // \r
            case 0x74: return ("\u{09}", index) // \t
            case 0x75:
                let (character, newIndex) = try parseUnicodeSequence()
                return (String(character), newIndex)
            default:
                throw EscapedSequenceError.unexpectedEscapedCharacter(ascii: byte, index: index)
            }
        }

        mutating func parseUnicodeSequence() throws -> (Unicode.Scalar, Int) {
            // we build this for utf8 only for now.
            let bitPattern = try parseUnicodeHexSequence()

            // check if high surrogate
            let isFirstByteHighSurrogate = bitPattern & 0xFC00 // nil everything except first six bits
            if isFirstByteHighSurrogate == 0xD800 {
                // if we have a high surrogate we expect a low surrogate next
                let highSurrogateBitPattern = bitPattern
                guard let (escapeChar, _) = read(),
                      let (uChar, _) = read()
                else {
                    throw JSONError.unexpectedEndOfFile
                }

                guard escapeChar == UInt8(ascii: #"\"#), uChar == UInt8(ascii: "u") else {
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: self.index)
                }

                let lowSurrogateBitBattern = try parseUnicodeHexSequence()
                let isSecondByteLowSurrogate = lowSurrogateBitBattern & 0xFC00 // nil everything except first six bits
                guard isSecondByteLowSurrogate == 0xDC00 else {
                    // we are in an escaped sequence. for this reason an output string must have
                    // been initialized
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: self.index)
                }

                let highValue = UInt32(highSurrogateBitPattern - 0xD800) * 0x400
                let lowValue = UInt32(lowSurrogateBitBattern - 0xDC00)
                let unicodeValue = highValue + lowValue + 0x10000
                guard let unicode = Unicode.Scalar(unicodeValue) else {
                    throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                        index: self.index, unicodeScalarValue: unicodeValue
                    )
                }
                return (unicode, self.index)
            }

            guard let unicode = Unicode.Scalar(bitPattern) else {
                throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                    index: self.index, unicodeScalarValue: UInt32(bitPattern)
                )
            }
            return (unicode, self.index)
        }

        mutating func parseUnicodeHexSequence() throws -> UInt16 {
            // As stated in RFC-8259 an escaped unicode character is 4 HEXDIGITs long
            // https://tools.ietf.org/html/rfc8259#section-7
            guard let (firstHex, startIndex) = read(),
                  let (secondHex, _) = read(),
                  let (thirdHex, _) = read(),
                  let (forthHex, _) = read()
            else {
                throw JSONError.unexpectedEndOfFile
            }

            guard let first = DocumentReader.hexAsciiTo4Bits(firstHex),
                  let second = DocumentReader.hexAsciiTo4Bits(secondHex),
                  let third = DocumentReader.hexAsciiTo4Bits(thirdHex),
                  let forth = DocumentReader.hexAsciiTo4Bits(forthHex)
            else {
                let hexString = String(decoding: [firstHex, secondHex, thirdHex, forthHex], as: Unicode.UTF8.self)
                throw JSONError.invalidHexDigitSequence(hexString, index: startIndex)
            }
            let firstByte = UInt16(first) << 4 | UInt16(second)
            let secondByte = UInt16(third) << 4 | UInt16(forth)

            let bitPattern = UInt16(firstByte) << 8 | UInt16(secondByte)

            return bitPattern
        }

        static func hexAsciiTo4Bits(_ ascii: UInt8) -> UInt8? {
            switch ascii {
            case 48 ... 57:
                return ascii - 48
            case 65 ... 70:
                // uppercase letters
                return ascii - 55
            case 97 ... 102:
                // lowercase letters
                return ascii - 87
            default:
                return nil
            }
        }
    }
}

// MARK:
private enum JSONError: Swift.Error, Equatable {
    case unexpectedCharacter(ascii: UInt8, characterIndex: Int)
    case unexpectedEndOfFile
    case tooManyNestedArraysOrDictionaries(characterIndex: Int)
    case invalidHexDigitSequence(String, index: Int)
    case unexpectedEscapedCharacter(ascii: UInt8, in: String, index: Int)
    case unescapedControlCharacterInString(ascii: UInt8, in: String, index: Int)
    case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: String, index: Int)
    case couldNotCreateUnicodeScalarFromUInt32(in: String, index: Int, unicodeScalarValue: UInt32)
    case numberWithLeadingZero(index: Int)
    case numberIsNotRepresentableInSwift(parsed: String)
    case singleFragmentFoundButNotAllowed
}

private enum JSONValue {
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    case array([JSONValue])
    case object([String: JSONValue])
}

private extension JSONValue {
    var isValue: Bool {
        switch self {
        case .array, .object:
            return false
        case .null, .number, .string, .bool:
            return true
        }
    }
    
    var isContainer: Bool {
        switch self {
        case .array, .object:
            return true
        case .null, .number, .string, .bool:
            return false
        }
    }
}

extension JSONValue {
    var debugDataTypeDescription: String {
        switch self {
        case .array:
            return "an array"
        case .bool:
            return "bool"
        case .number:
            return "a number"
        case .string:
            return "a string"
        case .object:
            return "a dictionary"
        case .null:
            return "null"
        }
    }
}

private extension JSONValue {
    func toObjcRepresentation(options: JSONSerialization.ReadingOptions) throws -> Any {
        switch self {
        case .array(let values):
            let array = try values.map { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return array
            }
            return NSMutableArray(array: array, copyItems: false)
        case .object(let object):
            let dictionary = try object.mapValues { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return dictionary
            }
            return NSMutableDictionary(dictionary: dictionary, copyItems: false)
        case .bool(let bool):
            return NSNumber(value: bool)
        case .number(let string):
            let decIndex = string.firstIndex(of: ".")
            let expIndex = string.firstIndex(of: "e")
            let isInteger = decIndex == nil && expIndex == nil
            let isNegative = string.utf8[string.utf8.startIndex] == UInt8(ascii: "-")
            let digitCount = string[string.startIndex..<(expIndex ?? string.endIndex)].count
            
            // Try Int64() or UInt64() first
            if isInteger {
                if isNegative {
                    if digitCount <= 19, let intValue = Int64(string) {
                        return NSNumber(value: intValue)
                    }
                } else {
                    if digitCount <= 20, let uintValue = UInt64(string) {
                        return NSNumber(value: uintValue)
                    }
                }
            }

            var exp = 0
            
            if let expIndex = expIndex {
                let expStartIndex = string.index(after: expIndex)
                let slice = string[expStartIndex...]
                var iterator = slice.utf8.makeIterator()
                var isNegative = false
                if slice.utf8.first == UInt8(ascii: "-") {
                    isNegative = true
                    _ = iterator.next()
                }
                else if slice.utf8.first == UInt8(ascii: "+") {
                    _ = iterator.next()
                }
                while let next = iterator.next() {
                    exp += exp * 10
                    exp += Int(next - UInt8(ascii: "0"))
                }
                
                if isNegative {
                    exp = exp * -1
                }
            }
            
            // Decimal holds more digits of precision but a smaller exponent than Double
            // so try that if the exponent fits and there are more digits than Double can hold
            if digitCount > 17, exp >= -128, exp <= 127, let decimal = Decimal(string: string), decimal.isFinite {
                return NSDecimalNumber(decimal: decimal)
            }
            
            // Fall back to Double() for everything else
            if let doubleValue = Double(string) {
                return NSNumber(value: doubleValue)
            }
            
            throw JSONError.numberIsNotRepresentableInSwift(parsed: string)
        case .null:
            return NSNull()
        case .string(let string):
            if options.contains(.mutableLeaves) {
                return NSMutableString(string: string)
            }
            return string
        }
    }
}
