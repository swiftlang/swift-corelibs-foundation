// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @typedef NSXMLNodeKind
*/
public enum NSXMLNodeKind : UInt {
    
    case InvalidKind
    case DocumentKind
    case ElementKind
    case AttributeKind
    case NamespaceKind
    case ProcessingInstructionKind
    case CommentKind
    case TextKind
    case DTDKind
    case EntityDeclarationKind
    case AttributeDeclarationKind
    case ElementDeclarationKind
    case NotationDeclarationKind
}

// initWithKind options
//  NSXMLNodeOptionsNone
//  NSXMLNodePreserveAll
//  NSXMLNodePreserveNamespaceOrder
//  NSXMLNodePreserveAttributeOrder
//  NSXMLNodePreserveEntities
//  NSXMLNodePreservePrefixes
//  NSXMLNodeIsCDATA
//  NSXMLNodeExpandEmptyElement
//  NSXMLNodeCompactEmptyElement
//  NSXMLNodeUseSingleQuotes
//  NSXMLNodeUseDoubleQuotes

// Output options
//  NSXMLNodePrettyPrint


/*!
    @class NSXMLNode
    @abstract The basic unit of an XML document.
*/
public class NSXMLNode : NSObject, NSCopying {
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /*!
        @method initWithKind:
        @abstract Invokes @link initWithKind:options: @/link with options set to NSXMLNodeOptionsNone
    */
    public convenience init(kind: NSXMLNodeKind) { NSUnimplemented() }
    
    /*!
        @method initWithKind:options:
        @abstract Inits a node with fidelity options as description NSXMLNodeOptions.h
    */
    public init(kind: NSXMLNodeKind, options: Int) {
        NSUnimplemented()
    }
    
    /*!
        @method document:
        @abstract Returns an empty document.
    */
    public class func document() -> AnyObject { NSUnimplemented() }
    
    /*!
        @method documentWithRootElement:
        @abstract Returns a document
        @param element The document's root node.
    */
    public class func documentWithRootElement(element: NSXMLElement) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method elementWithName:
        @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
    */
    public class func elementWithName(name: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method elementWithName:URI:
        @abstract Returns an element whose full QName is specified.
    */
    public class func elementWithName(name: String, URI: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method elementWithName:stringValue:
        @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
    */
    public class func elementWithName(name: String, stringValue string: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method elementWithName:children:attributes:
        @abstract Returns an element children and attributes <tt>&lt;name attr1="foo" attr2="bar">&lt;-- child1 -->child2&lt;/name></tt>.
    */
    public class func elementWithName(name: String, children: [NSXMLNode]?, attributes: [NSXMLNode]?) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method attributeWithName:stringValue:
        @abstract Returns an attribute <tt>name="stringValue"</tt>.
    */
    public class func attributeWithName(name: String, stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method attributeWithLocalName:URI:stringValue:
        @abstract Returns an attribute whose full QName is specified.
    */
    public class func attributeWithName(name: String, URI: String, stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method namespaceWithName:stringValue:
        @abstract Returns a namespace <tt>xmlns:name="stringValue"</tt>.
    */
    public class func namespaceWithName(name: String, stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method processingInstructionWithName:stringValue:
        @abstract Returns a processing instruction <tt>&lt;?name stringValue></tt>.
    */
    public class func processingInstructionWithName(name: String, stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method commentWithStringValue:
        @abstract Returns a comment <tt>&lt;--stringValue--></tt>.
    */
    public class func commentWithStringValue(stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method textWithStringValue:
        @abstract Returns a text node.
    */
    public class func textWithStringValue(stringValue: String) -> AnyObject { NSUnimplemented() }
    
    /*!
        @method DTDNodeWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public class func DTDNodeWithXMLString(string: String) -> AnyObject? { NSUnimplemented() }
    
    /*!
        @method kind
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public var kind: NSXMLNodeKind  { NSUnimplemented() } //primitive
    
    /*!
        @method name
        @abstract Sets the nodes name. Applicable for element, attribute, namespace, processing-instruction, document type declaration, element declaration, attribute declaration, entity declaration, and notation declaration.
    */
    public var name: String? //primitive
    
    /*!
        @method objectValue
        @abstract Sets the content of the node. Setting the objectValue removes all existing children including processing instructions and comments. Setting the object value on an element creates a single text node child.
    */
    public var objectValue: AnyObject? //primitive
    
    /*!
        @method stringValue:
        @abstract Sets the content of the node. Setting the stringValue removes all existing children including processing instructions and comments. Setting the string value on an element creates a single text node child. The getter returns the string value of the node, which may be either its content or child text nodes, depending on the type of node. Elements are recursed and text nodes concatenated in document order with no intervening spaces.
    */
    public var stringValue: String? //primitive
    
    /*!
        @method setStringValue:resolvingEntities:
        @abstract Sets the content as with @link setStringValue: @/link, but when "resolve" is true, character references, predefined entities and user entities available in the document's dtd are resolved. Entities not available in the dtd remain in their entity form.
    */
    public func setStringValue(string: String, resolvingEntities resolve: Bool) { NSUnimplemented() } //primitive
    
    /*!
        @method index
        @abstract A node's index amongst its siblings.
    */
    public var index: Int { NSUnimplemented() } //primitive
    
    /*!
        @method level
        @abstract The depth of the node within the tree. Documents and standalone nodes are level 0.
    */
    public var level: Int { NSUnimplemented() }
    
    /*!
        @method rootDocument
        @abstract The encompassing document or nil.
    */
    public var rootDocument: NSXMLDocument? { NSUnimplemented() }
    
    /*!
        @method parent
        @abstract The parent of this node. Documents and standalone Nodes have a nil parent; there is not a 1-to-1 relationship between parent and children, eg a namespace cannot be a child but has a parent element.
    */
    /*@NSCopying*/ public var parent: NSXMLNode? { NSUnimplemented() } //primitive
    
    /*!
        @method childCount
        @abstract The amount of children, relevant for documents, elements, and document type declarations. Use this instead of [[self children] count].
    */
    public var childCount: Int { NSUnimplemented() } //primitive
    
    /*!
        @method children
        @abstract An immutable array of child nodes. Relevant for documents, elements, and document type declarations.
    */
    public var children: [NSXMLNode]? { NSUnimplemented() } //primitive
    
    /*!
        @method childAtIndex:
        @abstract Returns the child node at a particular index.
    */
    public func childAtIndex(index: Int) -> NSXMLNode? { NSUnimplemented() } //primitive
    
    /*!
        @method previousSibling:
        @abstract Returns the previous sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ public var previousSibling: NSXMLNode? { NSUnimplemented() }
    
    /*!
        @method nextSibling:
        @abstract Returns the next sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ public var nextSibling: NSXMLNode? { NSUnimplemented() }
    
    /*!
        @method previousNode:
        @abstract Returns the previous node in document order. This can be used to walk the tree backwards.
    */
    /*@NSCopying*/ public var previousNode: NSXMLNode? { NSUnimplemented() }
    
    /*!
        @method nextNode:
        @abstract Returns the next node in document order. This can be used to walk the tree forwards.
    */
    /*@NSCopying*/ public var nextNode: NSXMLNode? { NSUnimplemented() }
    
    /*!
        @method detach:
        @abstract Detaches this node from its parent.
    */
    public func detach() { NSUnimplemented() } //primitive
    
    /*!
        @method XPath
        @abstract Returns the XPath to this node, for example foo/bar[2]/baz.
    */
    public var XPath: String? { NSUnimplemented() }
    
    /*!
    	@method localName
    	@abstract Returns the local name bar if this attribute or element's name is foo:bar
    */
    public var localName: String? { NSUnimplemented() } //primitive
    
    /*!
    	@method prefix
    	@abstract Returns the prefix foo if this attribute or element's name if foo:bar
    */
    public var prefix: String? { NSUnimplemented() } //primitive
    
    /*!
    	@method URI
    	@abstract Set the URI of this element, attribute, or document. For documents it is the URI of document origin. Getter returns the URI of this element, attribute, or document. For documents it is the URI of document origin and is automatically set when using initWithContentsOfURL.
    */
    public var URI: String? //primitive
    
    /*!
        @method localNameForName:
        @abstract Returns the local name bar in foo:bar.
    */
    public class func localNameForName(name: String) -> String { NSUnimplemented() }
    
    /*!
        @method localNameForName:
        @abstract Returns the prefix foo in the name foo:bar.
    */
    public class func prefixForName(name: String) -> String? { NSUnimplemented() }
    
    /*!
        @method predefinedNamespaceForPrefix:
        @abstract Returns the namespace belonging to one of the predefined namespaces xml, xs, or xsi
    */
    public class func predefinedNamespaceForPrefix(name: String) -> NSXMLNode? { NSUnimplemented() }
    
    /*!
        @method description
        @abstract Used for debugging. May give more information than XMLString.
    */
    public override var description: String { NSUnimplemented() }
    
    /*!
        @method XMLString
        @abstract The representation of this node as it would appear in an XML document.
    */
    public var XMLString: String { NSUnimplemented() }
    
    /*!
        @method XMLStringWithOptions:
        @abstract The representation of this node as it would appear in an XML document, with various output options available.
    */
    public func XMLStringWithOptions(options: Int) -> String { NSUnimplemented() }
    
    /*!
        @method canonicalXMLStringPreservingComments:
        @abstract W3 canonical form (http://www.w3.org/TR/xml-c14n). The input option NSXMLNodePreserveWhitespace should be set for true canonical form.
    */
    public func canonicalXMLStringPreservingComments(comments: Bool) -> String { NSUnimplemented() }
    
    /*!
        @method nodesForXPath:error:
        @abstract Returns the nodes resulting from applying an XPath to this node using the node as the context item ("."). normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
    	@returns An array whose elements are a kind of NSXMLNode.
    */
    public func nodesForXPath(xpath: String) throws -> [NSXMLNode] { NSUnimplemented() }
    
    /*!
        @method objectsForXQuery:constants:error:
        @abstract Returns the objects resulting from applying an XQuery to this node using the node as the context item ("."). Constants are a name-value dictionary for constants declared "external" in the query. normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
    	@returns An array whose elements are kinds of NSArray, NSData, NSDate, NSNumber, NSString, NSURL, or NSXMLNode.
    */
    public func objectsForXQuery(xquery: String, constants: [String : AnyObject]?) throws -> [AnyObject] { NSUnimplemented() }
    
    public func objectsForXQuery(xquery: String) throws -> [AnyObject] { NSUnimplemented() }
}


