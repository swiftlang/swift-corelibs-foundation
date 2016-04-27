// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
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
            let child = _CFXMLNewTextNode(string)
            _CFXMLNodeAddChild(_xmlNode, child)
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
    public func elementsForName(_ name: String) -> [NSXMLElement] {
        return self.filter({ _CFXMLNodeGetType($0._xmlNode) == _kCFXMLTypeElement }).filter({ $0.name == name }).flatMap({ $0 as? NSXMLElement })
    }

    /*!
        @method elementsForLocalName:URI
        @abstract Returns all of the child elements that match this localname URI pair.
    */
    public func elementsForLocalName(_ localName: String, URI: String?) -> [NSXMLElement] { NSUnimplemented() }

    /*!
        @method addAttribute:
        @abstract Adds an attribute. Attributes with duplicate names are not added.
    */
    public func addAttribute(_ attribute: NSXMLNode) {
        guard _CFXMLNodeHasProp(_xmlNode, UnsafePointer<UInt8>(_CFXMLNodeGetName(attribute._xmlNode))) == nil else { return }
        addChild(attribute)
    } //primitive

    /*!
        @method removeAttributeForName:
        @abstract Removes an attribute based on its name.
    */
    public func removeAttributeForName(_ name: String) {
        if let prop = _CFXMLNodeHasProp(_xmlNode, name) {
            let propNode = NSXMLNode._objectNodeForNode(_CFXMLNodePtr(prop))
            _childNodes.remove(propNode)
            // We can't use `xmlRemoveProp` because someone else may still have a reference to this attribute
            _CFXMLUnlinkNode(_CFXMLNodePtr(prop))
        }
    } //primitive

    /*!
        @method setAttributes
        @abstract Set the attributes. In the case of duplicate names, the first attribute with the name is used.
    */
    public var attributes: [NSXMLNode]? {
        get {
            var result: [NSXMLNode] = []
            var nextAttribute = _CFXMLNodeProperties(_xmlNode)
            while let attribute = nextAttribute {
                result.append(NSXMLNode._objectNodeForNode(attribute))
                nextAttribute = _CFXMLNodeGetNextSibling(attribute)
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
        var nextAttribute = _CFXMLNodeProperties(_xmlNode)
        while let attribute = nextAttribute {
            var shouldFreeNode = true
            if let privateData = _CFXMLNodeGetPrivateData(attribute) {
                let nodeUnmanagedRef = Unmanaged<NSXMLNode>.fromOpaque(privateData)
                let node = nodeUnmanagedRef.takeUnretainedValue()
                _childNodes.remove(node)

                shouldFreeNode = false
            }

            let temp = _CFXMLNodeGetNextSibling(attribute)
            _CFXMLUnlinkNode(attribute)
            if shouldFreeNode {
                _CFXMLFreeNode(attribute)
            }

            nextAttribute = temp
        }
    }

    /*!
     @method setAttributesWithDictionary:
     @abstract Set the attributes based on a name-value dictionary.
     */
    public func setAttributesWithDictionary(_ attributes: [String : String]) {
        removeAttributes()
        for (name, value) in attributes {
            addAttribute(NSXMLNode.attributeWithName(name, stringValue: value) as! NSXMLNode)
        }
    }

    /*!
        @method attributeForName:
        @abstract Returns an attribute matching this name.
    */
    public func attributeForName(_ name: String) -> NSXMLNode? {
        guard let attribute = _CFXMLNodeHasProp(_xmlNode, name) else { return nil }
        return NSXMLNode._objectNodeForNode(attribute)
    }

    /*!
        @method attributeForLocalName:URI:
        @abstract Returns an attribute matching this localname URI pair.
    */
    public func attributeForLocalName(_ localName: String, URI: String?) -> NSXMLNode? { NSUnimplemented() } //primitive

    /*!
        @method addNamespace:URI:
        @abstract Adds a namespace. Namespaces with duplicate names are not added.
    */
    public func addNamespace(_ aNamespace: NSXMLNode) { NSUnimplemented() } //primitive

    /*!
        @method addNamespace:URI:
        @abstract Removes a namespace with a particular name.
    */
    public func removeNamespaceForPrefix(_ name: String) { NSUnimplemented() } //primitive

    /*!
        @method namespaces
        @abstract Set the namespaces. In the case of duplicate names, the first namespace with the name is used.
    */
    public var namespaces: [NSXMLNode]? { NSUnimplemented() } //primitive

    /*!
        @method namespaceForPrefix:
        @abstract Returns the namespace matching this prefix.
    */
    public func namespaceForPrefix(_ name: String) -> NSXMLNode? { NSUnimplemented() }

    /*!
        @method resolveNamespaceForName:
        @abstract Returns the namespace who matches the prefix of the name given. Looks in the entire namespace chain.
    */
    public func resolveNamespaceForName(_ name: String) -> NSXMLNode? { NSUnimplemented() }

    /*!
        @method resolvePrefixForNamespaceURI:
        @abstract Returns the URI of this prefix. Looks in the entire namespace chain.
    */
    public func resolvePrefixForNamespaceURI(_ namespaceURI: String) -> String? { NSUnimplemented() }

    /*!
        @method insertChild:atIndex:
        @abstract Inserts a child at a particular index.
    */
    public func insertChild(_ child: NSXMLNode, atIndex index: Int) {
        _insertChild(child, atIndex: index)
    } //primitive

    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    public func insertChildren(_ children: [NSXMLNode], atIndex index: Int) {
        _insertChildren(children, atIndex: index)
    }

    /*!
        @method removeChildAtIndex:atIndex:
        @abstract Removes a child at a particular index.
    */
    public func removeChildAtIndex(_ index: Int) {
        _removeChildAtIndex(index)
    } //primitive

    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    public func setChildren(_ children: [NSXMLNode]?) {
        _setChildren(children)
    } //primitive

    /*!
        @method addChild:
        @abstract Adds a child to the end of the existing children.
    */
    public func addChild(_ child: NSXMLNode) {
        _addChild(child)
    }

    /*!
        @method replaceChildAtIndex:withNode:
        @abstract Replaces a child at a particular index with another child.
    */
    public func replaceChildAtIndex(_ index: Int, withNode node: NSXMLNode) {
        _replaceChildAtIndex(index, withNode: node)
    }

    /*!
        @method normalizeAdjacentTextNodesPreservingCDATA:
        @abstract Adjacent text nodes are coalesced. If the node's value is the empty string, it is removed. This should be called with a value of NO before using XQuery or XPath.
    */
    public func normalizeAdjacentTextNodesPreservingCDATA(_ preserve: Bool) { NSUnimplemented() }

    internal override class func _objectNodeForNode(_ node: _CFXMLNodePtr) -> NSXMLElement {
        precondition(_CFXMLNodeGetType(node) == _kCFXMLTypeElement)

        if let privateData = _CFXMLNodeGetPrivateData(node) {
            let unmanaged = Unmanaged<NSXMLElement>.fromOpaque(privateData)
            return unmanaged.takeUnretainedValue()
        }

        return NSXMLElement(ptr: node)
    }

    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}

extension NSXMLElement {
    /*!
        @method setAttributesAsDictionary:
        @abstract Set the attributes base on a name-value dictionary.
        @discussion This method is deprecated and does not function correctly. Use -setAttributesWithDictionary: instead.
     */
    public func setAttributesAsDictionary(_ attributes: [NSObject : AnyObject]) { NSUnimplemented() }
}
