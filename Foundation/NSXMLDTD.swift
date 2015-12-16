// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import libxml2
/*!
    @class NSXMLDTD
    @abstract Defines the order, repetition, and allowable values for a document
*/
public class NSXMLDTD : NSXMLNode {
    
    public convenience init(contentsOfURL url: NSURL, options mask: Int) throws { NSUnimplemented() }
    public init(data: NSData, options mask: Int) throws { NSUnimplemented() } //primitive
    
    /*!
        @method publicID
        @abstract Sets the public id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set.
    */
    public var publicID: String? //primitive
    
    /*!
        @method systemID
        @abstract Sets the system id. This should be a URL that points to a valid DTD.
    */
    public var systemID: String? //primitive
    
    /*!
        @method insertChild:atIndex:
        @abstract Inserts a child at a particular index.
    */
    public func insertChild(child: NSXMLNode, atIndex index: Int) { NSUnimplemented() } //primitive
    
    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    public func insertChildren(children: [NSXMLNode], atIndex index: Int) { NSUnimplemented() }
    
    /*!
        @method removeChildAtIndex:
        @abstract Removes a child at a particular index.
    */
    public func removeChildAtIndex(index: Int) { NSUnimplemented() } //primitive
    
    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    public func setChildren(children: [NSXMLNode]?) { NSUnimplemented() } //primitive
    
    /*!
        @method addChild:
        @abstract Adds a child to the end of the existing children.
    */
    public func addChild(child: NSXMLNode) { NSUnimplemented() }
    
    /*!
        @method replaceChildAtIndex:withNode:
        @abstract Replaces a child at a particular index with another child.
    */
    public func replaceChildAtIndex(index: Int, withNode node: NSXMLNode) { NSUnimplemented() }
    
    /*!
        @method entityDeclarationForName:
        @abstract Returns the entity declaration matching this name.
    */
    public func entityDeclarationForName(name: String) -> NSXMLDTDNode? { NSUnimplemented() } //primitive
    
    /*!
        @method notationDeclarationForName:
        @abstract Returns the notation declaration matching this name.
    */
    public func notationDeclarationForName(name: String) -> NSXMLDTDNode? { NSUnimplemented() } //primitive
    
    /*!
        @method elementDeclarationForName:
        @abstract Returns the element declaration matching this name.
    */
    public func elementDeclarationForName(name: String) -> NSXMLDTDNode? { NSUnimplemented() } //primitive
    
    /*!
        @method attributeDeclarationForName:
        @abstract Returns the attribute declaration matching this name.
    */
    public func attributeDeclarationForName(name: String, elementName: String) -> NSXMLDTDNode? { NSUnimplemented() } //primitive
    
    /*!
        @method predefinedEntityDeclarationForName:
        @abstract Returns the predefined entity declaration matching this name.
    	@discussion The five predefined entities are
    	<ul><li>&amp;lt; - &lt;</li><li>&amp;gt; - &gt;</li><li>&amp;amp; - &amp;</li><li>&amp;quot; - &quot;</li><li>&amp;apos; - &amp;</li></ul>
    */
    public class func predefinedEntityDeclarationForName(name: String) -> NSXMLDTDNode? { NSUnimplemented() }
    
    internal override class func _objectNodeForNode(node: xmlNodePtr) -> NSXMLDTD {
        precondition(node.memory.type == XML_DTD_NODE)
        
        if node.memory._private != nil {
            let unmanaged = Unmanaged<NSXMLDTD>.fromOpaque(node.memory._private)
            return unmanaged.takeUnretainedValue()
        }
        
        return NSXMLDTD(ptr: node)
    }
    
    internal override init(ptr: xmlNodePtr) {
        super.init(ptr: ptr)
    }
}


