// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSPersonNameComponentsFormatterStyle : Int {
    
    case Default
    
    /* Relies on user preferences and language defaults to display shortened form appropriate
      for display in space-constrained settings, e.g. C Darwin */
    case Short
    
    /* The minimally necessary features for differentiation in a casual setting , e.g. Charles Darwin */
    case Medium
    
    /* The fully-qualified name complete with all known components, e.g. Charles Robert Darwin, FRS */
    case Long
    
    /* The maximally-abbreviated form of a name suitable for monograms, e.g. CRD) */
    case Abbreviated
}

public struct NSPersonNameComponentsFormatterOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /* Indicates that the formatter should format the component object's phoneticRepresentation components instead of its own components.
     The developer must have populated these manually. e.g.: Developer creates components object with the following properties:
     <family:"Family", given:"Given", phoneticRepresentation:<family:"FamilyPhonetic", given:"GivenPhonetic">>.
     If this option is specified, we perform formatting operations on <family "FamilyPhonetic", given "GivenPhonetic"> instead. */
    public static let Phonetic = NSPersonNameComponentsFormatterOptions(rawValue: 1 << 1)
}

public class NSPersonNameComponentsFormatter : NSFormatter {
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /* Specify the formatting style for the formatted string on an instance. ShortStyle will fall back to user preferences and language-specific defaults
     */
    public var style: NSPersonNameComponentsFormatterStyle
    
    /* Specify that the formatter should only format the components object's phoneticRepresentation
     */
    public var phonetic: Bool
    
    /* Shortcut for converting an NSPersonNameComponents object into a string without explicitly creating an instance.
        Create an instance for greater customizability.
     */
    public class func localizedStringFromPersonNameComponents(components: NSPersonNameComponents, style nameFormatStyle: NSPersonNameComponentsFormatterStyle, options nameOptions: NSPersonNameComponentsFormatterOptions) -> String { NSUnimplemented() }
    
    /* Convenience method on stringForObjectValue:. Returns a string containing the formatted value of the provided components object.
     */
    public func stringFromPersonNameComponents(components: NSPersonNameComponents) -> String { NSUnimplemented() }
    
    /* Returns attributed string with annotations for each component. For each range, attributes can be obtained by querying
        dictionary key NSPersonNameComponentKey , using NSPersonNameComponent constant values.
     */
    public func annotatedStringFromPersonNameComponents(components: NSPersonNameComponents) -> NSAttributedString { NSUnimplemented() }
    
    /* NSPersonNameComponentsFormatter currently only implements formatting, not parsing. Until it implements parsing, this will always return NO.
     */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public override func objectValue(string: String) throws -> AnyObject? { return nil }
}

// Attributed String identifier key string
public let NSPersonNameComponentKey: String = "NSPersonNameComponentKey"

// Constants for attributed strings
public let NSPersonNameComponentGivenName: String = "givenName"
public let NSPersonNameComponentFamilyName: String = "familyName"
public let NSPersonNameComponentMiddleName: String = "middleName"
public let NSPersonNameComponentPrefix: String = "namePrefix"
public let NSPersonNameComponentSuffix: String = "nameSuffix"
public let NSPersonNameComponentNickname: String = "nickname"

/* The delimiter is the character or characters used to separate name components.
 For CJK languages there is no delimiter.
 */
public let NSPersonNameComponentDelimiter: String = "delimiter"


