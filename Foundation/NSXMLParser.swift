// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public enum NSXMLParserExternalEntityResolvingPolicy : UInt {
    
    case ResolveExternalEntitiesNever // default
    case ResolveExternalEntitiesNoNetwork
    case ResolveExternalEntitiesSameOriginOnly //only applies to NSXMLParser instances initialized with -initWithContentsOfURL:
    case ResolveExternalEntitiesAlways
}

public class NSXMLParser : NSObject {
    
    // initializes the parser with the specified URL.
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }
    
    // create the parser from data
    public init(data: NSData) { NSUnimplemented() }
    
    //create a parser that incrementally pulls data from the specified stream and parses it.
    public convenience init(stream: NSInputStream) { NSUnimplemented() }
    
    public weak var delegate: NSXMLParserDelegate?
    
    public var shouldProcessNamespaces: Bool
    public var shouldReportNamespacePrefixes: Bool
    
    //defaults to NSXMLNodeLoadExternalEntitiesNever
    public var externalEntityResolvingPolicy: NSXMLParserExternalEntityResolvingPolicy
    
    public var allowedExternalEntityURLs: Set<NSURL>?

    // called to start the event-driven parse. Returns YES in the event of a successful parse, and NO in case of error.
    public func parse() -> Bool { NSUnimplemented() }

    // called by the delegate to stop the parse. The delegate will get an error message sent to it.
    public func abortParsing() { NSUnimplemented() }
    
    /*@NSCopying*/ public var parserError: NSError? { NSUnimplemented() } // can be called after a parse is over to determine parser state.
    
    //Toggles between disabling external entities entirely, and the current setting of the 'externalEntityResolvingPolicy'.
    //The 'externalEntityResolvingPolicy' property should be used instead of this, unless targeting 10.9/7.0 or earlier
    public var shouldResolveExternalEntities: Bool

    // Once a parse has begun, the delegate may be interested in certain parser state. These methods will only return meaningful information during parsing, or after an error has occurred.
    public var publicID: String? { NSUnimplemented() }
    public var systemID: String? { NSUnimplemented() }
    public var lineNumber: Int { NSUnimplemented() }
    public var columnNumber: Int { NSUnimplemented() }
}

/*
 
 For the discussion of event methods, assume the following XML:

 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type='text/css' href='cvslog.css'?>
 <!DOCTYPE cvslog SYSTEM "cvslog.dtd">
 <cvslog xmlns="http://xml.apple.com/cvslog">
   <radar:radar xmlns:radar="http://xml.apple.com/radar">
     <radar:bugID>2920186</radar:bugID>
     <radar:title>API/NSXMLParser: there ought to be an NSXMLParser</radar:title>
   </radar:radar>
 </cvslog>
 
 */

// The parser's delegate is informed of events through the methods in the NSXMLParserDelegateEventAdditions category.
public protocol NSXMLParserDelegate : class {
    
    // Document handling methods
    func parserDidStartDocument(parser: NSXMLParser)
    // sent when the parser begins parsing of the document.
    func parserDidEndDocument(parser: NSXMLParser)
    // sent when the parser has completed parsing. If this is encountered, the parse was successful.
    
    // DTD handling methods for various declarations.
    func parser(parser: NSXMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(parser: NSXMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?)
    
    func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?)
    
    func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String)
    
    func parser(parser: NSXMLParser, foundInternalEntityDeclarationWithName name: String, value: String?)
    
    func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    // sent when the parser finds an element start tag.
    // In the case of the cvslog tag, the following is what the delegate receives:
    //   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
    // In the case of the radar tag, the following is what's passed in:
    //    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
    // If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    // sent when an end tag is encountered. The various parameters are supplied as above.
    
    func parser(parser: NSXMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String)
    // sent when the parser first sees a namespace attribute.
    // In the case of the cvslog tag, before the didStartElement:, you'd get one of these with prefix == @"" and namespaceURI == @"http://xml.apple.com/cvslog" (i.e. the default namespace)
    // In the case of the radar:radar tag, before the didStartElement: you'd get one of these with prefix == @"radar" and namespaceURI == @"http://xml.apple.com/radar"
    
    func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String)
    // sent when the namespace prefix in question goes out of scope.
    
    func parser(parser: NSXMLParser, foundCharacters string: String)
    // This returns the string of the characters encountered thus far. You may not necessarily get the longest character run. The parser reserves the right to hand these to the delegate as potentially many calls in a row to -parser:foundCharacters:
    
    func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String)
    // The parser reports ignorable whitespace in the same way as characters it's found.
    
    func parser(parser: NSXMLParser, foundProcessingInstructionWithTarget target: String, data: String?)
    // The parser reports a processing instruction to you using this method. In the case above, target == @"xml-stylesheet" and data == @"type='text/css' href='cvslog.css'"
    
    func parser(parser: NSXMLParser, foundComment comment: String)
    // A comment (Text in a <!-- --> block) is reported to the delegate as a single string
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData)
    // this reports a CDATA block to the delegate as an NSData.
    
    func parser(parser: NSXMLParser, resolveExternalEntityName name: String, systemID: String?) -> NSData?
    // this gives the delegate an opportunity to resolve an external entity itself and reply with the resulting data.
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError)
    // ...and this reports a fatal error to the delegate. The parser will stop parsing.
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError)
}

extension NSXMLParserDelegate {
    
    func parserDidStartDocument(parser: NSXMLParser) { }
    func parserDidEndDocument(parser: NSXMLParser) { }

    func parser(parser: NSXMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(parser: NSXMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) { }
    
    func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) { }
    
    func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String) { }
    
    func parser(parser: NSXMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { }
    
    func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) { }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { }
    
    func parser(parser: NSXMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) { }
    
    func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String) { }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) { }
    
    func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String) { }
    
    func parser(parser: NSXMLParser, foundProcessingInstructionWithTarget target: String, data: String?) { }
    
    func parser(parser: NSXMLParser, foundComment comment: String) { }
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) { }
    
    func parser(parser: NSXMLParser, resolveExternalEntityName name: String, systemID: String?) -> NSData? { return nil }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) { }
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) { }
}


// If validation is on, this will report a fatal validation error to the delegate. The parser will stop parsing.
public let NSXMLParserErrorDomain: String = "NSXMLParserErrorDomain" // for use with NSError.

// Error reporting
public enum NSXMLParserError : Int {
    
    case InternalError
    case OutOfMemoryError
    case DocumentStartError
    case EmptyDocumentError
    case PrematureDocumentEndError
    case InvalidHexCharacterRefError
    case InvalidDecimalCharacterRefError
    case InvalidCharacterRefError
    case InvalidCharacterError
    case CharacterRefAtEOFError
    case CharacterRefInPrologError
    case CharacterRefInEpilogError
    case CharacterRefInDTDError
    case EntityRefAtEOFError
    case EntityRefInPrologError
    case EntityRefInEpilogError
    case EntityRefInDTDError
    case ParsedEntityRefAtEOFError
    case ParsedEntityRefInPrologError
    case ParsedEntityRefInEpilogError
    case ParsedEntityRefInInternalSubsetError
    case EntityReferenceWithoutNameError
    case EntityReferenceMissingSemiError
    case ParsedEntityRefNoNameError
    case ParsedEntityRefMissingSemiError
    case UndeclaredEntityError
    case UnparsedEntityError
    case EntityIsExternalError
    case EntityIsParameterError
    case UnknownEncodingError
    case EncodingNotSupportedError
    case StringNotStartedError
    case StringNotClosedError
    case NamespaceDeclarationError
    case EntityNotStartedError
    case EntityNotFinishedError
    case LessThanSymbolInAttributeError
    case AttributeNotStartedError
    case AttributeNotFinishedError
    case AttributeHasNoValueError
    case AttributeRedefinedError
    case LiteralNotStartedError
    case LiteralNotFinishedError
    case CommentNotFinishedError
    case ProcessingInstructionNotStartedError
    case ProcessingInstructionNotFinishedError
    case NotationNotStartedError
    case NotationNotFinishedError
    case AttributeListNotStartedError
    case AttributeListNotFinishedError
    case MixedContentDeclNotStartedError
    case MixedContentDeclNotFinishedError
    case ElementContentDeclNotStartedError
    case ElementContentDeclNotFinishedError
    case XMLDeclNotStartedError
    case XMLDeclNotFinishedError
    case ConditionalSectionNotStartedError
    case ConditionalSectionNotFinishedError
    case ExternalSubsetNotFinishedError
    case DOCTYPEDeclNotFinishedError
    case MisplacedCDATAEndStringError
    case CDATANotFinishedError
    case MisplacedXMLDeclarationError
    case SpaceRequiredError
    case SeparatorRequiredError
    case NMTOKENRequiredError
    case NAMERequiredError
    case PCDATARequiredError
    case URIRequiredError
    case PublicIdentifierRequiredError
    case LTRequiredError
    case GTRequiredError
    case LTSlashRequiredError
    case EqualExpectedError
    case TagNameMismatchError
    case UnfinishedTagError
    case StandaloneValueError
    case InvalidEncodingNameError
    case CommentContainsDoubleHyphenError
    case InvalidEncodingError
    case ExternalStandaloneEntityError
    case InvalidConditionalSectionError
    case EntityValueRequiredError
    case NotWellBalancedError
    case ExtraContentError
    case InvalidCharacterInEntityError
    case ParsedEntityRefInInternalError
    case EntityRefLoopError
    case EntityBoundaryError
    case InvalidURIError
    case URIFragmentError
    case NoDTDError
    case DelegateAbortedParseError
}

