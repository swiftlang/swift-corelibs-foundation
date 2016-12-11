// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension Formatter {
    public enum Context : Int {
        
        // The capitalization context to be used is unknown (this is the default value).
        case unknown

        // The capitalization context is determined dynamically from the set {NSFormattingContextStandalone, NSFormattingContextBeginningOfSentence, NSFormattingContextMiddleOfSentence}. For example, if a date is placed at the beginning of a sentence, NSFormattingContextBeginningOfSentence is used to format the string automatically. When this context is used, the formatter will return a string proxy that works like a normal string in most cases. After returning from the formatter, the string in the string proxy is formatted by using NSFormattingContextUnknown. When the string proxy is used in stringWithFormat:, we can determine where the %@ is and then set the context accordingly. With the new context, the string in the string proxy will be formatted again and be put into the final string returned from stringWithFormat:.
        case dynamic
        
        // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for stand-alone usage such as an isolated name on a calendar page.
        case standalone
        
        // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for a list or menu item.
        case listItem
        
        // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for the beginning of a sentence.
        case beginningOfSentence

        // The capitalization context if a date or date symbol is to be formatted with capitalization appropriate for the middle of a sentence.
        case middleOfSentence
    }

    /*
     * There are 3 widths: long, medium, and short.
     * For example, for English, when formatting "3 pounds"
     * Long is "3 pounds"; medium is "3 lb"; short is "3#";
     */

    public enum UnitStyle : Int {
        
        case short
        case medium
        case long
    }
}

open class Formatter : NSObject, NSCopying, NSCoding {
    
    public override init() {
        
    }
    
    public required init?(coder: NSCoder) {
        
    }
    
    open func encode(with aCoder: NSCoder) {
        
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    open func string(for obj: Any) -> String? {
        NSRequiresConcreteImplementation()
    }
    
    open func editingString(for obj: Any) -> String? {
        return string(for: obj)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func objectValue(_ string: String) throws -> Any? {
        NSRequiresConcreteImplementation()
    }
}

