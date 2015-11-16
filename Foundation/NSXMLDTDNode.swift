// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @typedef NSXMLDTDNodeKind
	@abstract The subkind of a DTD node kind.
*/
public enum NSXMLDTDNodeKind : UInt {
    
    case NSXMLEntityGeneralKind
    case NSXMLEntityParsedKind
    case NSXMLEntityUnparsedKind
    case NSXMLEntityParameterKind
    case NSXMLEntityPredefined
    
    case NSXMLAttributeCDATAKind
    case NSXMLAttributeIDKind
    case NSXMLAttributeIDRefKind
    case NSXMLAttributeIDRefsKind
    case NSXMLAttributeEntityKind
    case NSXMLAttributeEntitiesKind
    case NSXMLAttributeNMTokenKind
    case NSXMLAttributeNMTokensKind
    case NSXMLAttributeEnumerationKind
    case NSXMLAttributeNotationKind
    
    case NSXMLElementDeclarationUndefinedKind
    case NSXMLElementDeclarationEmptyKind
    case NSXMLElementDeclarationAnyKind
    case NSXMLElementDeclarationMixedKind
    case NSXMLElementDeclarationElementKind
}

/*!
    @class NSXMLDTDNode
    @abstract The nodes that are exclusive to a DTD
	@discussion Every DTD node has a name. Object value is defined as follows:<ul>
		<li><b>Entity declaration</b> - the string that that entity resolves to eg "&lt;"</li>
		<li><b>Attribute declaration</b> - the default value, if any</li>
		<li><b>Element declaration</b> - the validation string</li>
		<li><b>Notation declaration</b> - no objectValue</li></ul>
*/
public class NSXMLDTDNode : NSXMLNode {
    
    /*!
        @method initWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public init?(XMLString string: String) { NSUnimplemented() } //primitive
    
    public override init(kind: NSXMLNodeKind, options: Int) { NSUnimplemented() } //primitive
    
    /*!
        @method DTDKind
        @abstract Sets the DTD sub kind.
    */
    public var DTDKind: NSXMLDTDNodeKind //primitive
    
    /*!
        @method isExternal
        @abstract True if the system id is set. Valid for entities and notations.
    */
    public var external: Bool { NSUnimplemented() } //primitive
    
    /*!
        @method publicID
        @abstract Sets the public id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set. Valid for entities and notations.
    */
    public var publicID: String? //primitive
    
    /*!
        @method systemID
        @abstract Sets the system id. This should be a URL that points to a valid DTD. Valid for entities and notations.
    */
    public var systemID: String? //primitive
    
    /*!
        @method notationName
        @abstract Set the notation name. Valid for entities only.
    */
    public var notationName: String? //primitive
}


