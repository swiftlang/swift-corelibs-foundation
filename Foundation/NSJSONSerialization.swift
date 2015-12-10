// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


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
                    || number.floatValue.isInfinite || number.floatValue.isNaN
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
        
        guard let string = NSString(data: data, encoding: detectEncoding(data)) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to convert data to a string using the detected encoding. The data may be corrupt."
            ])
        }
        let result = try JSONObjectWithString(string._swiftObject)
        return result
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

//MARK: - Deserialization
internal extension NSJSONSerialization {
    
    static func JSONObjectWithString(string: String) throws -> Any {
        let parser = JSONDeserializer.UnicodeParser(viewSkippingBOM: string.unicodeScalars)
        if let (object, _) = try JSONDeserializer.parseObject(parser) {
            return object
        }
        else if let (array, _) = try JSONDeserializer.parseArray(parser) {
            return array
        }
        throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
            "NSDebugDescription" : "JSON text did not start with array or object and option to allow fragments not set."
        ])
    }
}

//MARK: - Encoding Detection

internal extension NSJSONSerialization {
    
    /// Detect the encoding format of the NSData contents
    class func detectEncoding(data: NSData) -> NSStringEncoding {
        let bytes = UnsafePointer<UInt8>(data.bytes)
        let length = data.length
        if let encoding = parseBOM(bytes, length: length) {
            return encoding
        }
        
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
    
    static func parseBOM(bytes: UnsafePointer<UInt8>, length: Int) -> NSStringEncoding? {
        if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0xEF, 0xBB):
                if length >= 3 && bytes[2] == 0xBF {
                    return NSUTF8StringEncoding
                }
            case (0x00, 0x00):
                if length >= 4 && bytes[2] == 0xFE && bytes[3] == 0xFF {
                    return NSUTF32BigEndianStringEncoding
                }
            case (0xFF, 0xFE):
                if length >= 4 && bytes[2] == 0 && bytes[3] == 0 {
                    return NSUTF32LittleEndianStringEncoding
                }
                return NSUTF16LittleEndianStringEncoding
            case (0xFE, 0xFF):
                return NSUTF16BigEndianStringEncoding
            default:
                break
            }
        }
        return nil
    }
}

//MARK: - JSONDeserializer
private struct JSONDeserializer {
    
    struct UnicodeParser {
        let view: String.UnicodeScalarView
        let index: String.UnicodeScalarIndex
        
        init(view: String.UnicodeScalarView, index: String.UnicodeScalarIndex) {
            self.view = view
            self.index = index
        }
        
        init(viewSkippingBOM view: String.UnicodeScalarView) {
            if view.startIndex < view.endIndex && view[view.startIndex] == UnicodeScalar(0xFEFF) {
                self.init(view: view, index: view.startIndex.successor())
                return
            }
            self.init(view: view, index: view.startIndex)
        }
        
        func successor() -> UnicodeParser {
            return UnicodeParser(view: view, index: index.successor())
        }
        
        var distanceFromStart: String.UnicodeScalarIndex.Distance {
            return view.startIndex.distanceTo(index)
        }
    }
    
    static let whitespaceScalars = "\u{20}\u{09}\u{0A}\u{0D}".unicodeScalars
    static func consumeWhitespace(parser: UnicodeParser) -> UnicodeParser {
        var index = parser.index
        let view = parser.view
        let endIndex = view.endIndex
        while index < endIndex && whitespaceScalars.contains(view[index]) {
            index = index.successor()
        }
        return UnicodeParser(view: view, index: index)
    }
    
    struct StructureScalar {
        static let BeginArray     = UnicodeScalar(0x5B) // [ left square bracket
        static let EndArray       = UnicodeScalar(0x5D) // ] right square bracket
        static let BeginObject    = UnicodeScalar(0x7B) // { left curly bracket
        static let EndObject      = UnicodeScalar(0x7D) // } right curly bracket
        static let NameSeparator  = UnicodeScalar(0x3A) // : colon
        static let ValueSeparator = UnicodeScalar(0x2C) // , comma
    }
    
    static func consumeStructure(scalar: UnicodeScalar, input: UnicodeParser) throws -> UnicodeParser? {
        if let parser = try consumeScalar(scalar, input: consumeWhitespace(input)) {
            return consumeWhitespace(parser)
        }
        return nil
    }
    
    static func consumeScalar(scalar: UnicodeScalar, input: UnicodeParser) throws -> UnicodeParser? {
        switch takeScalar(input) {
        case nil:
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unexpected end of file during JSON parse."
            ])
        case let (taken, parser)? where taken == scalar:
            return parser
        default:
            return nil
        }
    }
    
    static func consumeSequence(sequence: String, input: UnicodeParser) throws -> UnicodeParser? {
        var parser = input
        for scalar in sequence.unicodeScalars {
            guard let newParser = try consumeScalar(scalar, input: parser) else {
                return nil
            }
            parser = newParser
        }
        return parser
    }
    
    static func takeScalar(input: UnicodeParser) -> (UnicodeScalar, UnicodeParser)? {
        guard input.index < input.view.endIndex else {
            return nil
        }
        return (input.view[input.index], input.successor())
    }
    
    static func takeInClass(matchClass: String.UnicodeScalarView, count: UInt = UInt.max, input: UnicodeParser) -> (String.UnicodeScalarView, UnicodeParser)? {
        var output = String.UnicodeScalarView()
        var remaining = count
        var parser = input
        while remaining > 0, let (taken, newParser) = takeScalar(parser) where matchClass.contains(taken) {
            output.append(taken)
            parser = newParser
            remaining -= 1
        }
        guard output.count > 0 && (count != UInt.max || remaining == 0) else {
            return nil
        }
        return (output, parser)
    }

    //MARK: - String Parsing
    struct StringScalar{
        static let QuotationMark = UnicodeScalar(0x22) // "
        static let Escape        = UnicodeScalar(0x5C) // \
    }
    
    static func parseString(input: UnicodeParser) throws -> (String, UnicodeParser)? {
        guard let begin = try consumeScalar(StringScalar.QuotationMark, input: input) else {
            return nil
        }
        let view = begin.view
        let endIndex = view.endIndex
        var index = begin.index
        var value = String.UnicodeScalarView()
        while index < endIndex {
            let scalar = view[index]
            index = index.successor()
            
            switch scalar {
            case StringScalar.QuotationMark:
                return (String(value), UnicodeParser(view: view, index: index))
            case StringScalar.Escape:
                let parser = UnicodeParser(view: view, index: index)
                if let (escaped, newParser) = try parseEscapeSequence(parser) {
                    value.append(escaped)
                    index = newParser.index
                }
                else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                        "NSDebugDescription" : "Invalid unicode escape sequence at position \(parser.distanceFromStart - 1)"
                    ])
                }
            default:
                value.append(scalar)
            }
        }
        throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
            "NSDebugDescription" : "Unexpected end of file during string parse."
        ])
    }
    
    static func parseEscapeSequence(input: UnicodeParser) throws -> (UnicodeScalar, UnicodeParser)? {
        guard let (scalar, parser) = takeScalar(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Early end of unicode escape sequence around character"
            ])
        }
        switch scalar {
        case UnicodeScalar(0x22):                   // "    quotation mark  U+0022
            fallthrough
        case UnicodeScalar(0x5C):                   // \    reverse solidus U+005F
            fallthrough
        case UnicodeScalar(0x2F):                   // /    solidus         U+002F
            return (scalar, parser)
        case UnicodeScalar(0x62):                   // b    backspace       U+0008
            return (UnicodeScalar(0x08), parser)
        case UnicodeScalar(0x66):                   // f    form feed       U+000C
            return (UnicodeScalar(0x0C), parser)
        case UnicodeScalar(0x6E):                   // n    line feed       U+000A
            return (UnicodeScalar(0x0A), parser)
        case UnicodeScalar(0x72):                   // r    carriage return U+000D
            return (UnicodeScalar(0x0D), parser)
        case UnicodeScalar(0x74):                   // t    tab             U+0009
            return (UnicodeScalar(0x09), parser)
        case UnicodeScalar(0x75):                   // u    unicode
            return try parseUnicodeSequence(parser)
        default:
            return nil
        }
    }
    
    static func parseUnicodeSequence(input: UnicodeParser) throws -> (UnicodeScalar, UnicodeParser)? {
        
        guard let (codeUnit, parser) = parseCodeUnit(input) else {
            return nil
        }
        
        if !UTF16.isLeadSurrogate(codeUnit) {
            return (UnicodeScalar(codeUnit), parser)
        }
        
        guard let (trailCodeUnit, finalParser) = try consumeSequence("\\u", input: parser).flatMap(parseCodeUnit) where UTF16.isTrailSurrogate(trailCodeUnit) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to convert hex escape sequence (no high character) to UTF8-encoded character at position \(parser.distanceFromStart)"
            ])
        }
        
        var utf = UTF16()
        var generator = [codeUnit, trailCodeUnit].generate()
        switch utf.decode(&generator) {
        case .Result(let scalar):
            return (scalar, finalParser)
        default:
            return nil
        }
    }
    
    static let hexScalars = "1234567890abcdefABCDEF".unicodeScalars
    static func parseCodeUnit(input: UnicodeParser) -> (UTF16.CodeUnit, UnicodeParser)? {
        guard let (result, parser) = takeInClass(hexScalars, count: 4, input: input),
            let value = Int(String(result), radix: 16) else {
                return nil
        }
        return (UTF16.CodeUnit(value), parser)
    }
    
    //MARK: - Number parsing
    static let numberScalars = ".+-0123456789eE".unicodeScalars
    static func parseNumber(input: UnicodeParser) throws -> (Double, UnicodeParser)? {
        let view = input.view
        let endIndex = view.endIndex
        var index = input.index
        var value = String.UnicodeScalarView()
        while index < endIndex && numberScalars.contains(view[index]) {
            value.append(view[index])
            index = index.successor()
        }
        guard value.count > 0, let result = Double(String(value)) else {
            return nil
        }
        return (result, UnicodeParser(view: view, index: index))
    }

    //MARK: - Value parsing
    static func parseValue(input: UnicodeParser) throws -> (Any, UnicodeParser)? {
        if let (value, parser) = try parseString(input) {
            return (value, parser)
        }
        else if let parser = try consumeSequence("true", input: input) {
            return (true, parser)
        }
        else if let parser = try consumeSequence("false", input: input) {
            return (false, parser)
        }
        else if let parser = try consumeSequence("null", input: input) {
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
    static func parseObject(input: UnicodeParser) throws -> ([String: Any], UnicodeParser)? {
        guard let beginParser = try consumeStructure(StructureScalar.BeginObject, input: input) else {
            return nil
        }
        var parser = beginParser
        var output: [String: Any] = [:]
        while true {
            if let finalParser = try consumeStructure(StructureScalar.EndObject, input: parser) {
                return (output, finalParser)
            }
    
            if let (key, value, newParser) = try parseObjectMember(parser) {
                output[key] = value
    
                if let finalParser = try consumeStructure(StructureScalar.EndObject, input: newParser) {
                    return (output, finalParser)
                }
                else if let nextParser = try consumeStructure(StructureScalar.ValueSeparator, input: newParser) {
                    parser = nextParser
                    continue
                }
                else {
                    return nil
                }
            }
            return nil
        }
    }
    
    static func parseObjectMember(input: UnicodeParser) throws -> (String, Any, UnicodeParser)? {
        guard let (name, parser) = try parseString(input) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Missing object key at location \(input.distanceFromStart)"
            ])
        }
        guard let separatorParser = try consumeStructure(StructureScalar.NameSeparator, input: parser) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid value at location \(input.distanceFromStart)"
            ])
        }
        guard let (value, finalParser) = try parseValue(separatorParser) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Invalid value at location \(input.distanceFromStart)"
            ])
        }
        
        return (name, value, finalParser)
    }

    //MARK: - Array parsing
    static func parseArray(input: UnicodeParser) throws -> ([Any], UnicodeParser)? {
        guard let beginParser = try consumeStructure(StructureScalar.BeginArray, input: input) else {
            return nil
        }
        var parser = beginParser
        var output: [Any] = []
        while true {
            if let finalParser = try consumeStructure(StructureScalar.EndArray, input: parser) {
                return (output, finalParser)
            }
    
            if let (value, newParser) = try parseValue(parser) {
                output.append(value)
    
                if let finalParser = try consumeStructure(StructureScalar.EndArray, input: newParser) {
                    return (output, finalParser)
                }
                else if let nextParser = try consumeStructure(StructureScalar.ValueSeparator, input: newParser) {
                    parser = nextParser
                    continue
                }
                else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                        "NSDebugDescription" : "Unexpected end of file while parsing array at location \(input.distanceFromStart)"
                    ])
                }
            }
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unexpected end of file while parsing array at location \(input.distanceFromStart)"
            ])
        }
    }
}
