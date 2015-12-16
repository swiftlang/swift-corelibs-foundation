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
    @class NSXMLElement
    @abstract An XML element
    @discussion Note: Trying to add a document, namespace, attribute, or node with a parent throws an exception. To add a node with a parent first detach or create a copy of it.
*/
public class NSXMLElement : NSXMLNode {

    /*!
        @method initWithName:
        @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
    */
    public convenience init(name: String) {
        self.init(name: name, URI: nil)
    }

    /*!
        @method initWithName:URI:
        @abstract Returns an element whose full QName is specified.
    */
    public init(name: String, URI: String?) {
        super.init(kind: .ElementKind, options: 0)
        self.URI = URI
        self.name = name
    } //primitive

    /*!
        @method initWithName:stringValue:
        @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
    */
    public convenience init(name: String, stringValue string: String?) {
        self.init(name: name, URI: nil)
        if let string = string {
            let child = xmlNewText(string)
            xmlAddChild(_xmlNode, child)
        }
    }

    /*!
        @method initWithXMLString:error:
        @abstract Returns an element created from a string. Parse errors are collected in <tt>error</tt>.
    */
    public init(XMLString string: String) throws { NSUnimplemented() }

    public convenience override init(kind: NSXMLNodeKind, options: Int) {
        self.init(name: "", URI: nil)
    }

    /*!
        @method elementsForName:
        @abstract Returns all of the child elements that match this name.
    */
    public func elementsForName(name: String) -> [NSXMLElement] {
        return self.filter({ $0._xmlNode.memory.type == XML_ELEMENT_NODE }).filter({ $0.name == name }).flatMap({ $0 as? NSXMLElement })
    }

    /*!
        @method elementsForLocalName:URI
        @abstract Returns all of the child elements that match this localname URI pair.
    */
    public func elementsForLocalName(localName: String, URI: String?) -> [NSXMLElement] { NSUnimplemented() }

    /*!
        @method addAttribute:
        @abstract Adds an attribute. Attributes with duplicate names are not added.
    */
    public func addAttribute(attribute: NSXMLNode) {
        guard xmlHasProp(_xmlNode, attribute._xmlNode.memory.name) == nil else { return }
        addChild(attribute)
    } //primitive

    /*!
        @method removeAttributeForName:
        @abstract Removes an attribute based on its name.
    */
    public func removeAttributeForName(name: String) {
        let prop = xmlHasProp(_xmlNode, name)
        if prop != nil {
            let propNode = NSXMLNode._objectNodeForNode(xmlNodePtr(prop))
            _childNodes.remove(propNode)
            // We can't use `xmlRemoveProp` because someone else may still have a reference to this attribute
            xmlUnlinkNode(xmlNodePtr(prop))
        }
    } //primitive

    /*!
        @method setAttributes
        @abstract Set the attributes. In the case of duplicate names, the first attribute with the name is used.
    */
    public var attributes: [NSXMLNode]? {
        get {
            var result: [NSXMLNode] = []
            var attribute = _xmlNode.memory.properties
            while attribute != nil {
                result.append(NSXMLNode._objectNodeForNode(xmlNodePtr(attribute)))
                attribute = attribute.memory.next
            }
            return result.count > 0 ? result : nil // This appears to be how Darwin does it
        }

        set {
            removeAttributes()

            guard let attributes = newValue else {
                return
            }

            for attribute in attributes {
                addAttribute(attribute)
            }
        }
    }

    private func removeAttributes() {
        var attribute = _xmlNode.memory.properties
        while attribute != nil {
            var shouldFreeNode = true
            if attribute.memory._private != nil {
                let nodeUnmanagedRef = Unmanaged<NSXMLNode>.fromOpaque(attribute.memory._private)
                let node = nodeUnmanagedRef.takeUnretainedValue()
                _childNodes.remove(node)

                shouldFreeNode = false
            }

            let temp = attribute.memory.next
            xmlUnlinkNode(xmlNodePtr(attribute))
            if shouldFreeNode {
                xmlFreeNode(xmlNodePtr(attribute))
            }

            attribute = temp
        }
    }

    /*!
     @method setAttributesWithDictionary:
     @abstract Set the attributes based on a name-value dictionary.
     */
    public func setAttributesWithDictionary(attributes: [String : String]) {
        removeAttributes()
        for (name, value) in attributes {
            addAttribute(NSXMLNode.attributeWithName(name, stringValue: value) as! NSXMLNode)
        }
    }

    /*!
        @method attributeForName:
        @abstract Returns an attribute matching this name.
    */
    public func attributeForName(name: String) -> NSXMLNode? {
        let attribute = xmlHasProp(_xmlNode, name)
        return NSXMLNode._objectNodeForNode(xmlNodePtr(attribute))
    }

    /*!
        @method attributeForLocalName:URI:
        @abstract Returns an attribute matching this localname URI pair.
    */
    public func attributeForLocalName(localName: String, URI: String?) -> NSXMLNode? { NSUnimplemented() } //primitive

    /*!
        @method addNamespace:URI:
        @abstract Adds a namespace. Namespaces with duplicate names are not added.
    */
    public func addNamespace(aNamespace: NSXMLNode) { NSUnimplemented() } //primitive

    /*!
        @method addNamespace:URI:
        @abstract Removes a namespace with a particular name.
    */
    public func removeNamespaceForPrefix(name: String) { NSUnimplemented() } //primitive

    /*!
        @method namespaces
        @abstract Set the namespaces. In the case of duplicate names, the first namespace with the name is used.
    */
    public var namespaces: [NSXMLNode]? { NSUnimplemented() } //primitive

    /*!
        @method namespaceForPrefix:
        @abstract Returns the namespace matching this prefix.
    */
    public func namespaceForPrefix(name: String) -> NSXMLNode? { NSUnimplemented() }

    /*!
        @method resolveNamespaceForName:
        @abstract Returns the namespace who matches the prefix of the name given. Looks in the entire namespace chain.
    */
    public func resolveNamespaceForName(name: String) -> NSXMLNode? { NSUnimplemented() }

    /*!
        @method resolvePrefixForNamespaceURI:
        @abstract Returns the URI of this prefix. Looks in the entire namespace chain.
    */
    public func resolvePrefixForNamespaceURI(namespaceURI: String) -> String? { NSUnimplemented() }

    /*!
        @method insertChild:atIndex:
        @abstract Inserts a child at a particular index.
    */
    public func insertChild(child: NSXMLNode, atIndex index: Int) {
        precondition(index >= 0)
        precondition(index <= childCount)
        precondition(child.parent == nil)

        _childNodes.insert(child)

        if index == 0 {
            let first = _xmlNode.memory.children
            xmlAddPrevSibling(first, child._xmlNode)
        } else {
            let currChild = childAtIndex(index - 1)!._xmlNode
            xmlAddNextSibling(currChild, child._xmlNode)
        }
    } //primitive

    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    public func insertChildren(children: [NSXMLNode], atIndex index: Int) {
        for (childIndex, node) in children.enumerate() {
            insertChild(node, atIndex: index + childIndex)
        }
    }

    /*!
        @method removeChildAtIndex:atIndex:
        @abstract Removes a child at a particular index.
    */
    public func removeChildAtIndex(index: Int) {
        guard let child = childAtIndex(index) else {
            fatalError("index out of bounds")
        }

        _childNodes.remove(child)
        xmlUnlinkNode(child._xmlNode)
    } //primitive

    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    public func setChildren(children: [NSXMLNode]?) {
        _removeAllChildren()
        guard let children = children else {
            return
        }

        for child in children {
            addChild(child)
        }
    } //primitive

    /*!
        @method addChild:
        @abstract Adds a child to the end of the existing children.
    */
    public func addChild(child: NSXMLNode) {
        precondition(child.parent == nil)

        xmlAddChild(_xmlNode, child._xmlNode)
        _childNodes.insert(child)
    }

    /*!
        @method replaceChildAtIndex:withNode:
        @abstract Replaces a child at a particular index with another child.
    */
    public func replaceChildAtIndex(index: Int, withNode node: NSXMLNode) {
        let child = childAtIndex(index)!
        _childNodes.remove(child)
        xmlReplaceNode(child._xmlNode, node._xmlNode)
        _childNodes.insert(node)
    }

    /*!
        @method normalizeAdjacentTextNodesPreservingCDATA:
        @abstract Adjacent text nodes are coalesced. If the node's value is the empty string, it is removed. This should be called with a value of NO before using XQuery or XPath.
    */
    public func normalizeAdjacentTextNodesPreservingCDATA(preserve: Bool) { NSUnimplemented() }

    internal override class func _objectNodeForNode(node: xmlNodePtr) -> NSXMLElement {
        precondition(node.memory.type == XML_ELEMENT_NODE)

        if node.memory._private != nil {
            let unmanaged = Unmanaged<NSXMLElement>.fromOpaque(node.memory._private)
            return unmanaged.takeUnretainedValue()
        }

        return NSXMLElement(ptr: node)
    }

    internal override init(ptr: xmlNodePtr) {
        super.init(ptr: ptr)
    }
}

extension NSXMLElement {
    /*!
        @method setAttributesAsDictionary:
        @abstract Set the attributes base on a name-value dictionary.
        @discussion This method is deprecated and does not function correctly. Use -setAttributesWithDictionary: instead.
     */
    public func setAttributesAsDictionary(attributes: [NSObject : AnyObject]) { NSUnimplemented() }
}
