// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension PersonNameComponentsFormatter {
    public enum Style : Int {
        
        case `default`
        
        /* Relies on user preferences and language defaults to display shortened form appropriate
          for display in space-constrained settings, e.g. C Darwin */
        case short
        
        /* The minimally necessary features for differentiation in a casual setting , e.g. Charles Darwin */
        case medium
        
        /* The fully-qualified name complete with all known components, e.g. Charles Robert Darwin, FRS */
        case long
        
        /* The maximally-abbreviated form of a name suitable for monograms, e.g. CRD) */
        case abbreviated
    }

    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        /* Indicates that the formatter should format the component object's phoneticRepresentation components instead of its own components.
         The developer must have populated these manually. e.g.: Developer creates components object with the following properties:
         <family:"Family", given:"Given", phoneticRepresentation:<family:"FamilyPhonetic", given:"GivenPhonetic">>.
         If this option is specified, we perform formatting operations on <family "FamilyPhonetic", given "GivenPhonetic"> instead. */
        public static let phonetic = Options(rawValue: 1 << 1)
    }
}

@available(*, deprecated, message: "Person name components formatting isn't available in swift-corelibs-foundation")
open class PersonNameComponentsFormatter : Formatter {
    
    @available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")
    public required init?(coder: NSCoder) {
        NSUnsupported()
    }
    
    /* Specify the formatting style for the formatted string on an instance. ShortStyle will fall back to user preferences and language-specific defaults
     */
    open var style: Style
    
    /* Specify that the formatter should only format the components object's phoneticRepresentation
     */
    open var isPhonetic: Bool
    
    /* Shortcut for converting an NSPersonNameComponents object into a string without explicitly creating an instance.
        Create an instance for greater customizability.
     */
    @available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")
    open class func localizedString(from components: PersonNameComponents, style nameFormatStyle: Style, options nameOptions: Options = []) -> String { NSUnsupported() }
    
    /* Convenience method on string(for:):. Returns a string containing the formatted value of the provided components object.
     */
    @available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")
    open func string(from components: PersonNameComponents) -> String { NSUnsupported() }
    
    /* Returns attributed string with annotations for each component. For each range, attributes can be obtained by querying
        dictionary key NSPersonNameComponentKey , using NSPersonNameComponent constant values.
     */
    @available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")
    open func annotatedString(from components: PersonNameComponents) -> NSAttributedString { NSUnsupported() }
    
    @available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")
    open func personNameComponents(from string: String) -> PersonNameComponents? { NSUnsupported() }
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


