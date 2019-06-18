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

fileprivate protocol _JSONValue {
    func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws
}

//@_specialize(where T == String)
//extension<T: _JSONValue> [String : T] : _JSONValue {
extension Dictionary : _JSONValue where Key == String, Value : _JSONValue {
    
//    @_specialize(where Visitor == JSONWriter)
//    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

//@_specialize(where T == String)
//extension<T: _JSONValue> [T] : _JSONValue {
extension Array : _JSONValue where Element : _JSONValue {
    
//    @_specialize(where Visitor == JSONWriter)
//    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

extension String : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

//@_specialize(where T == Int)
//@_specialize(where T == UInt)
//@_specialize(where T == Int32)
//@_specialize(where T == UInt32)
//@_specialize(where T == Int64)
//@_specialize(where T == UInt64)
//extension<T: FixedWidthInteger> T : _JSONValue {
extension Int : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

//@_specialize(where T == Double)
//@_specialize(where T == Float)
//extension<T: FloatingPoint> T : _JSONValue {
extension Float : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        guard isFinite && !isNaN else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Invalid number value (\(self)) in JSON write"])
        }
        try visitor.visit(self)
    }
}

//TODO: delete this, use parameterized extensions
extension Double : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        guard isFinite && !isNaN else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Invalid number value (\(self)) in JSON write"])
        }
        try visitor.visit(self)
    }
}

extension Bool : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

extension Decimal : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        guard isFinite else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Invalid number value (\(self)) in JSON write"])
        }
        try visitor.visit(self)
    }
}

extension NSNull : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self)
    }
}

extension NSNumber : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        if CFNumberIsFloatType(_cfObject) {
            try doubleValue.visit(with: &visitor)
        } else {
            switch _cfTypeID {
            case CFBooleanGetTypeID():
                try boolValue.visit(with: &visitor)
            default:
                try intValue.visit(with: &visitor)
            }
        }
    }
}

extension NSArray : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self) //typecheck lazily as we go
    }
}

extension NSDictionary : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self) //typecheck lazily as we go
    }
}

extension NSString : _JSONValue {
    
    @_specialize(where Visitor == JSONWriter)
    @_specialize(where Visitor == JSONValidator)
    fileprivate func visit<Visitor: JSONVisitor>(with visitor: inout Visitor) throws {
        try visitor.visit(self as String)
    }
}

fileprivate protocol JSONVisitor {
    mutating func visit(_ string: String) throws
    mutating func visit<F: FloatingPoint & LosslessStringConvertible>(_ float: F) throws
    mutating func visit<I: FixedWidthInteger> (_ int: I) throws
    mutating func visit(_ bool: Bool) throws
    mutating func visit(_ null: NSNull) throws
    mutating func visit(_ decimal: Decimal) throws
    mutating func visit<J: _JSONValue>(_ dictionary: [String : J]) throws
    mutating func visit<J: _JSONValue>(_ array: [J]) throws
    mutating func visit(_ cocoaArray: NSArray) throws
    mutating func visit(_ cocoaDictionary: NSDictionary) throws
}

extension JSONVisitor {
    mutating func visit<T>(topLevelJSON value: T?) throws {
        guard let value = value else {
            return
        }
        if let dict = value as? [String : _JSONValue] {
            try visit(dict) //TODO: should be dict.visit(with: &self)
        } else if let arr = value as? [_JSONValue] {
            try visit(arr) //TODO: should be arr.visit(with: &self)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListWriteInvalid.rawValue, userInfo: ["NSDebugDescription" : "Invalid top level object \(value) in JSON write, must be Dictionary, NSDictionary, Array, or NSArray"])
        }
    }
    
    mutating func visit<T>(_ any: T) throws {
        if let value = any as? _JSONValue {
            try value.visit(with: &self)
        }
        throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListWriteInvalid.rawValue, userInfo: ["NSDebugDescription" : "Invalid value (\(any)) in JSON write"])
    }
    
    mutating func visit<J:_JSONValue>(_ jsonFragment: J) throws {
        try jsonFragment.visit(with: &self)
    }
}

private struct JSONValidator : JSONVisitor {
    mutating func visit(_ string: String) throws { }
    mutating func visit<F: FloatingPoint & LosslessStringConvertible>(_ float: F) throws { }
    mutating func visit<I: FixedWidthInteger> (_ int: I) throws { }
    mutating func visit(_ bool: Bool) throws { }
    mutating func visit(_ null: NSNull) throws { }
    mutating func visit(_ decimal: Decimal) throws { }
    mutating func visit<J: _JSONValue>(_ dictionary: [String : J]) throws {
        for (_, value) in dictionary {
            try value.visit(with: &self)
        }
    }
    mutating func visit<J: _JSONValue>(_ array: [J]) throws {
        for value in array {
            try value.visit(with: &self)
        }
    }
    mutating func visit(_ cocoaArray: NSArray) throws {
        for object in cocoaArray {
            guard let json = object as? _JSONValue else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListWriteInvalid.rawValue, userInfo: ["NSDebugDescription" : "Invalid value (\(object)) in JSON write"])
            }
            try json.visit(with: &self)
        }
    }
    mutating func visit(_ cocoaDictionary: NSDictionary) throws {
        var err: NSError? = nil
        cocoaDictionary.enumerateKeysAndObjects { (key, value, stopPtr) in
            guard let jsonKey = key as? _JSONValue else {
                err = NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListWriteInvalid.rawValue, userInfo: ["NSDebugDescription" : "Invalid NSDictionary key (\(key)) in JSON write"])
                stopPtr.pointee = true
                return
            }
            guard let jsonValue = value as? _JSONValue else {
                err = NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListWriteInvalid.rawValue, userInfo: ["NSDebugDescription" : "Invalid NSDictionary value (\(value)) in JSON write"])
                stopPtr.pointee = true
                return
            }
            do {
                try jsonKey.visit(with: &self)
                try jsonValue.visit(with: &self)
            } catch where error is NSError {
                err = (error as! NSError)
                stopPtr.pointee = true
            } catch {
                fatalError()
            }
        }
        if let error = err {
            throw error
        }
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
        do {
            var validator = JSONValidator()
            try validator.visit(topLevelJSON: obj)
        } catch {
            return false
        }
        return true
    }
    
    /* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
     */
    internal class func _data(withJSONObject value: Any, options opt: WritingOptions, stream: Bool) throws -> Data {
        var writer = JSONWriter(
            pretty: opt.contains(.prettyPrinted),
            sortedKeys: opt.contains(.sortedKeys)
        )
        
        try! writer.visit(topLevelJSON: value) // This is a fatal error in objective-c too (it is an NSInvalidArgumentException)

        let jsonStr = writer.result
        let count = jsonStr.utf8.count
        return jsonStr.withCString {
            Data(bytes: $0, count: count)
        }
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
                "NSDebugDescription" : "JSON text did not start with array or object and option to allow fragments not set."
            ])
        }
        
    }
    
    /* Write JSON data into a stream. The stream should be opened and configured. The return value is the number of bytes written to the stream, or 0 on error. All other behavior of this method is the same as the dataWithJSONObject:options:error: method.
     */
    open class func writeJSONObject(_ obj: Any, toStream stream: OutputStream, options opt: WritingOptions) throws -> Int {
        let jsonData = try _data(withJSONObject: obj, options: opt, stream: true)
        let count = jsonData.count
        return jsonData.withUnsafeBytes { (bytePtr: UnsafeRawBufferPointer) -> Int in
            let res: Int = stream.write(bytePtr.bindMemory(to: UInt8.self).baseAddress!, maxLength: count)
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
private struct JSONWriter : JSONVisitor {

    var indent = 0
    let pretty: Bool
    let sortedKeys: Bool
    var result = ""

    init(pretty: Bool = false, sortedKeys: Bool = false) {
        self.pretty = pretty
        self.sortedKeys = sortedKeys
    }
    
    mutating func visit(_ any: Any?) throws {

        var toSerialize = any

        if let number = toSerialize as? _NSNumberCastingWithoutBridging {
            toSerialize = number._swiftValueOfOptimalType
        }
        
        guard let obj = toSerialize else {
            try NSNull().visit(with: &self)
            return
        }
        
        guard let jsonObj = obj as? _JSONValue else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Invalid value (\(obj)) in JSON write"])
        }
        
        try jsonObj.visit(with: &self)
    }
    
    mutating func visit<I: FixedWidthInteger> (_ int: I) {
        result += int.description //TODO
    }
    
    mutating func visit(_ bool: Bool) {
        result += bool.description
    }
    
    mutating func visit(_ decimal: Decimal) {
        result += decimal.description
    }

    mutating func visit(_ str: String) throws {
        result += "\""
        for scalar in str.unicodeScalars {
            switch scalar {
                case "\"":
                    result += "\\\"" // U+0022 quotation mark
                case "\\":
                    result += "\\\\" // U+005C reverse solidus
                case "/":
                    result += "\\/" // U+002F solidus
                case "\u{8}":
                    result += "\\b" // U+0008 backspace
                case "\u{c}":
                    result += "\\f" // U+000C form feed
                case "\n":
                    result += "\\n" // U+000A line feed
                case "\r":
                    result += "\\r" // U+000D carriage return
                case "\t":
                    result += "\\t" // U+0009 tab
                case "\u{0}"..."\u{f}":
                    result += "\\u000\(String(scalar.value, radix: 16))" // U+0000 to U+000F
                case "\u{10}"..."\u{1f}":
                    result += "\\u00\(String(scalar.value, radix: 16))" // U+0010 to U+001F
                default:
                    result += String(scalar)
            }
        }
        result += "\""
    }

    mutating func visit<F: FloatingPoint & LosslessStringConvertible>(_ num: F) throws {
        var str = num.description //TODO
        if str.hasSuffix(".0") {
            str.removeLast(2)
        }
        result += str
    }
    
    mutating func visitArrayLikeSequence<Seq: Sequence>(_ array: Seq) throws {
        result += "["
        if pretty {
            result += "\n"
            incAndWriteIndent()
        }
        
        var first = true
        for elem in array {
            guard let jsonElem = elem as? _JSONValue else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Invalid NSArray value (\(elem)) in JSON write"])
            }
            if first {
                first = false
            } else if pretty {
                result += ",\n"
                writeIndent()
            } else {
                result += ","
            }
            try jsonElem.visit(with: &self)
        }
        if pretty {
            result += "\n"
            decAndWriteIndent()
        }
        result += "]"
    }

    mutating func visit<J: _JSONValue>(_ array: [J]) throws {
        try visitArrayLikeSequence(array)
    }
    
    mutating func visit(_ cocoaArray: NSArray) throws {
        try visitArrayLikeSequence(cocoaArray)
    }

    mutating func visit<J: _JSONValue>(_ dict: [String : J]) throws {
        result += "{"
        if pretty {
            result += "\n"
            incAndWriteIndent()
        }

        var first = true

        func visitElement<J: _JSONValue>(key: String, value: J) throws {
            if first {
                first = false
            } else if pretty {
                result += ",\n"
                writeIndent()
            } else {
                result += ","
            }

            try key.visit(with: &self)
            result += pretty ? " : " : ":"
            try value.visit(with: &self)
        }

        if sortedKeys {
            let elems = dict.sorted(by: { a, b in
                let options: NSString.CompareOptions = [.numeric, .caseInsensitive, .forcedOrdering]
                let range: Range<String.Index>  = a.key.startIndex..<a.key.endIndex
                let locale = NSLocale.system

                return a.key.compare(b.key, options: options, range: range, locale: locale) == .orderedAscending
            })
            for elem in elems {
                try visitElement(key: elem.key, value: elem.value)
            }
        } else {
            for (key, value) in dict {
                try visitElement(key: key, value: value)
            }
        }

        if pretty {
            result += "\n"
            decAndWriteIndent()
        }
        result += "}"
    }

    mutating func visit(_ null: NSNull) {
        result += "null"
    }
    
    let indentAmount = 2
    
    mutating func incAndWriteIndent() {
        indent += indentAmount
        writeIndent()
    }
    
    mutating func decAndWriteIndent() {
        indent -= indentAmount
        writeIndent()
    }
    
    mutating func writeIndent() {
        for _ in 0..<indent {
            result += " "
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
                    "NSDebugDescription" : "Unable to convert data to a string using the detected encoding. The data may be corrupt."
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
                    "NSDebugDescription" : "Unexpected end of file during JSON parse."
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
                        "NSDebugDescription" : "Invalid escape sequence at position \(source.distanceFromStart(currentIndex))"
                    ])
                }
            default:
                currentIndex = index
            }
        }
        throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
            "NSDebugDescription" : "Unexpected end of file during string parse."
        ])
    }

    func parseEscapeSequence(_ input: Index) throws -> (String, Index)? {
        guard let (byte, index) = source.takeASCII(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
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
                                     "NSDebugDescription" : """
                                      Unable to convert unicode escape sequence (no high-surrogate code point) \
                                      to UTF8-encoded character at position \(source.distanceFromStart(input))
                                      """
                                   ])
        }

        guard let (trailCodeUnit, finalIndex) = try consumeASCIISequence("\\u", input: index).flatMap(parseCodeUnit),
              UTF16.isTrailSurrogate(trailCodeUnit) else {
            throw CocoaError.error(.propertyListReadCorrupt,
                                   userInfo: [
                                     "NSDebugDescription" : """
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
                              userInfo: ["NSDebugDescription" : "Numbers must start with a 1-9 at character \(input)." ])
            }

            if ascii == JSONReader.DECIMAL_SEPARATOR {
                isInteger = false
                guard readDigits() != nil else { return true }
                guard nextASCII() else { return true }
            } else if JSONReader.allDigits.contains(ascii) {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue,
                              userInfo: ["NSDebugDescription" : "Leading zeros not allowed at character \(input)." ])
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
                "NSDebugDescription" : "Missing object key at location \(source.distanceFromStart(input))"
            ])
        }
        guard let separatorIndex = try consumeStructure(Structure.NameSeparator, input: index) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid separator at location \(source.distanceFromStart(index))"
            ])
        }
        guard let (value, finalIndex) = try parseValue(separatorIndex, options: opt) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid value at location \(source.distanceFromStart(separatorIndex))"
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
                "NSDebugDescription" : "Badly formed array at location \(source.distanceFromStart(index))"
            ])
        }
    }
}
