// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSFormattingContext : Int {
    
    // The capitalization context to be used is unknown (this is the default value).
    case Unknown

    // The capitalization context is determined dynamically from the set {NSFormattingContextStandalone, NSFormattingContextBeginningOfSentence, NSFormattingContextMiddleOfSentence}. For example, if a date is placed at the beginning of a sentence, NSFormattingContextBeginningOfSentence is used to format the string automatically. When this context is used, the formatter will return a string proxy that works like a normal string in most cases. After returning from the formatter, the string in the string proxy is formatted by using NSFormattingContextUnknown. When the string proxy is used in stringWithFormat:, we can determine where the %@ is and then set the context accordingly. With the new context, the string in the string proxy will be formatted again and be put into the final string returned from stringWithFormat:.
    case Dynamic
    
    // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for stand-alone usage such as an isolated name on a calendar page.
    case Standalone
    
    // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for a list or menu item.
    case ListItem
    
    // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for the beginning of a sentence.
    case BeginningOfSentence

    // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for the middle of a sentence.
    case MiddleOfSentence
}

/*
 * There are 3 widths: long, medium, and short.
 * For example, for English, when formatting "3 pounds"
 * Long is "3 pounds"; medium is "3 lb"; short is "3#";
 */

public enum NSFormattingUnitStyle : Int {
    
    case Short
    case Medium
    case Long
}

public class NSFormatter : NSObject, NSCopying, NSCoding {
    
    public override init() {
        
    }
    
    public required init?(coder: NSCoder) {
        
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public func stringForObjectValue(obj: AnyObject) -> String? {
        NSRequiresConcreteImplementation()
    }
    
    public func editingStringForObjectValue(obj: AnyObject) -> String? {
        return stringForObjectValue(obj)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func objectValue(string: String) throws -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
}

