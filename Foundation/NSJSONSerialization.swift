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
        NSUnimplemented()
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
