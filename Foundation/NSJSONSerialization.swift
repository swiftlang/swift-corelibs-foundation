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

enum NSJSONSerializationError: ErrorType {
    case InvalidStringEncoding
    case NotAnArrayOrObject
    case UnterminatedString(String.UnicodeScalarIndex.Distance)
    case MissingObjectKey(String.UnicodeScalarIndex.Distance)
    case InvalidValue(String.UnicodeScalarIndex.Distance)
    case BadlyFormedArray(String.UnicodeScalarIndex.Distance)
    case UnexpectedEndOfFile
}

/* A class for converting JSON to Foundation/Swift objects and converting Foundation/Swift objects to JSON.
   
   An object that may be converted to JSON must have the following properties:
    - Top level object is an Array or Dictionary
    - All objects are String, NSNumber, Array, Dictionary, or NSNull
    - All dictionary keys are Strings
    - NSNumbers are not NaN or infinity
*/

public class NSJSONSerialization : NSObject {
    
    /* Returns YES if the given object can be converted to JSON data, NO otherwise.
    
    Other rules may apply. Calling this method or attempting a conversion are the definitive ways to tell if a given object can be converted to JSON data.
     */
    public class func isValidJSONObject(obj: AnyObject) -> Bool {
        NSUnimplemented()
    }
    
    /* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
     */
    public class func dataWithJSONObject(obj: AnyObject, options opt: NSJSONWritingOptions) throws -> NSData {
        NSUnimplemented()
    }
    
    /* Create a Foundation object from JSON data. Set the NSJSONReadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary. Setting the NSJSONReadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries. Setting the NSJSONReadingMutableLeaves option will make the parser generate mutable NSString objects. If an error occurs during the parse, then the error parameter will be set and the result will be nil.
       The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE. The data may or may not have a BOM. The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
     */
    public class func JSONObjectWithData(data: NSData, options opt: NSJSONReadingOptions) throws -> AnyObject {
        
        guard let string = NSString(data: data, encoding: detectEncoding(data)) else {
            throw NSJSONSerializationError.InvalidStringEncoding
        }
        return try JSONObjectWithString(string as String)
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
    
    static func JSONObjectWithString(string: String) throws -> AnyObject {
        let parser = JSONDeserializer.UnicodeParser(viewSkippingBOM: string.unicodeScalars)
        if let (object, _) = try JSONDeserializer.parseObject(parser) {
            return object
        }
        else if let (array, _) = try JSONDeserializer.parseArray(parser) {
            return array
        }
        throw NSJSONSerializationError.NotAnArrayOrObject
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
            if view.startIndex < view.endIndex && view[view.startIndex] == UnicodeScalar(65279) {
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
    
    static let whitespaceScalars = [
        UnicodeScalar(0x20), // Space
        UnicodeScalar(0x09), // Horizontal tab
        UnicodeScalar(0x0A), // Line feed or New line
        UnicodeScalar(0x0D)  // Carriage return
    ]
    
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
        guard input.index < input.view.endIndex else {
            throw NSJSONSerializationError.UnexpectedEndOfFile
        }
        if scalar == input.view[input.index] {
            return input.successor()
        }
        return nil
    }
    
    static func readScalar(input: UnicodeParser) -> (UnicodeScalar, UnicodeParser)? {
        guard input.index < input.view.endIndex else {
            return nil
        }
        return (input.view[input.index], input.successor())
    }
    
    static func consumeString(string: String, input: UnicodeParser) throws -> UnicodeParser? {
        var parser = input
        for scalar in string.unicodeScalars {
            guard let newParser = try consumeScalar(scalar, input: parser) else {
                return nil
            }
            parser = newParser
        }
        return parser
    }

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
            default:
                value.append(scalar)
            }
        }
        throw NSJSONSerializationError.UnterminatedString(input.distanceFromStart)
    }
    
    static let numberScalars = [
        UnicodeScalar(0x2E), // .
        UnicodeScalar(0x30), // 0
        UnicodeScalar(0x31), // 1
        UnicodeScalar(0x32), // 2
        UnicodeScalar(0x33), // 3
        UnicodeScalar(0x34), // 4
        UnicodeScalar(0x35), // 5
        UnicodeScalar(0x36), // 6
        UnicodeScalar(0x37), // 7
        UnicodeScalar(0x38), // 8
        UnicodeScalar(0x39), // 9
        UnicodeScalar(0x65), // e
        UnicodeScalar(0x45), // E
        UnicodeScalar(0x2B), // +
        UnicodeScalar(0x2D), // -
    ]
    static func parseNumber(input: UnicodeParser) throws -> (AnyObject, UnicodeParser)? {
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
        return (NSNumber(double: result), UnicodeParser(view: view, index: index))
    }

    static func parseValue(input: UnicodeParser) throws -> (AnyObject, UnicodeParser)? {
        if let (value, parser) = try parseString(input) {
            return (value, parser)
        }
        else if let parser = try consumeString("true", input: input) {
            return (true, parser)
        }
        else if let parser = try consumeString("false", input: input) {
            return (false, parser)
        }
        else if let parser = try consumeString("null", input: input) {
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

    static func parseObjectMember(input: UnicodeParser) throws -> (String, AnyObject, UnicodeParser)? {
        guard let (name, parser) = try parseString(input) else {
            throw NSJSONSerializationError.MissingObjectKey(input.distanceFromStart)
        }
        guard let separatorParser = try consumeStructure(StructureScalar.NameSeparator, input: parser) else {
            return nil
        }
        guard let (value, finalParser) = try parseValue(separatorParser) else {
            throw NSJSONSerializationError.InvalidValue(separatorParser.distanceFromStart)
        }
    
        return (name, value, finalParser)
    }

    static func parseObject(input: UnicodeParser) throws -> ([String: AnyObject], UnicodeParser)? {
        guard let beginParser = try consumeStructure(StructureScalar.BeginObject, input: input) else {
            return nil
        }
        var parser = beginParser
        var output: [String: AnyObject] = [:]
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

    static func parseArray(input: UnicodeParser) throws -> ([AnyObject], UnicodeParser)? {
        guard let beginParser = try consumeStructure(StructureScalar.BeginArray, input: input) else {
            return nil
        }
        var parser = beginParser
        var output: [AnyObject] = []
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
                    throw NSJSONSerializationError.BadlyFormedArray(newParser.distanceFromStart)
                }
            }
            throw NSJSONSerializationError.InvalidValue(parser.distanceFromStart)
        }
    }
}
