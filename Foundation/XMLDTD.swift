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
    @class XMLDTD
    @abstract Defines the order, repetition, and allowable values for a document
*/
open class XMLDTD : XMLNode {

    internal var _xmlDTD: _CFXMLDTDPtr {
        return _CFXMLDTDPtr(_xmlNode)
    }
    
    public init() {
        NSUnimplemented()
    }
    
    public convenience init(contentsOf url: URL, options mask: XMLNode.Options = []) throws {
        let urlString = url.absoluteString

        guard let node = _CFXMLParseDTD(urlString) else {
            //TODO: throw error
            fatalError("parsing dtd string failed")
        }
        self.init(ptr: node)
    }

    public convenience init(data: Data, options mask: XMLNode.Options = []) throws {
        var unmanagedError: Unmanaged<CFError>? = nil
        
        guard let node = _CFXMLParseDTDFromData(data._cfObject, &unmanagedError) else {
            if let error = unmanagedError?.takeRetainedValue()._nsObject {
                throw error
            }
            //TODO: throw a generic error?
            fatalError("parsing dtd from data failed")
        }

        self.init(ptr: node)
    }
    
    /*!
        @method openID
        @abstract Sets the open id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set.
    */
    open var publicID: String? {
        get {
            return _CFXMLDTDCopyExternalID(_xmlDTD)?._swiftObject
        }

        set {
            if let value = newValue {
                _CFXMLDTDSetExternalID(_xmlDTD, value)
            } else {
                _CFXMLDTDSetExternalID(_xmlDTD, nil)
            }
        }
    }
    
    /*!
        @method systemID
        @abstract Sets the system id. This should be a URL that points to a valid DTD.
    */
    open var systemID: String? {
        get {
            return _CFXMLDTDCopySystemID(_xmlDTD)?._swiftObject
        }

        set {
            if let value = newValue {
                _CFXMLDTDSetSystemID(_xmlDTD, value)
            } else {
                _CFXMLDTDSetSystemID(_xmlDTD, nil)
            }
        }
    }

    /*!
        @method insertChild:atIndex:
        @abstract Inserts a child at a particular index.
    */
    open func insertChild(_ child: XMLNode, at index: Int) {
        _insertChild(child, atIndex: index)
    } //primitive
    
    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    open func insertChildren(_ children: [XMLNode], at index: Int) {
        _insertChildren(children, atIndex: index)
    }
    
    /*!
        @method removeChildAtIndex:
        @abstract Removes a child at a particular index.
    */
    open func removeChild(at index: Int) {
        _removeChildAtIndex(index)
    } //primitive
    
    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    open func setChildren(_ children: [XMLNode]?) {
        _setChildren(children)
    } //primitive
    
    /*!
        @method addChild:
        @abstract Adds a child to the end of the existing children.
    */
    open func addChild(_ child: XMLNode) {
        _addChild(child)
    }
    
    /*!
        @method replaceChildAtIndex:withNode:
        @abstract Replaces a child at a particular index with another child.
    */
    open func replaceChild(at index: Int, with node: XMLNode) {
        _replaceChildAtIndex(index, withNode: node)
    }
    
    /*!
        @method entityDeclarationForName:
        @abstract Returns the entity declaration matching this name.
    */
    open func entityDeclaration(forName name: String) -> XMLDTDNode? {
        guard let node = _CFXMLDTDGetEntityDesc(_xmlDTD, name) else { return nil }
        return XMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method notationDeclarationForName:
        @abstract Returns the notation declaration matching this name.
    */
    open func notationDeclaration(forName name: String) -> XMLDTDNode? {
        guard let node = _CFXMLDTDGetNotationDesc(_xmlDTD, name) else { return nil }
        return XMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method elementDeclarationForName:
        @abstract Returns the element declaration matching this name.
    */
    open func elementDeclaration(forName name: String) -> XMLDTDNode? {
        guard let node = _CFXMLDTDGetElementDesc(_xmlDTD, name) else { return nil }
        return XMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method attributeDeclarationForName:
        @abstract Returns the attribute declaration matching this name.
    */
    open func attributeDeclaration(forName name: String, elementName: String) -> XMLDTDNode? {
        guard let node = _CFXMLDTDGetAttributeDesc(_xmlDTD, elementName, name) else { return nil }
        return XMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method predefinedEntityDeclarationForName:
        @abstract Returns the predefined entity declaration matching this name.
    	@discussion The five predefined entities are
    	<ul><li>&amp;lt; - &lt;</li><li>&amp;gt; - &gt;</li><li>&amp;amp; - &amp;</li><li>&amp;quot; - &quot;</li><li>&amp;apos; - &amp;</li></ul>
    */
    open class func predefinedEntityDeclaration(forName name: String) -> XMLDTDNode? {
        guard let node = _CFXMLDTDGetPredefinedEntity(name) else { return nil }
        return XMLDTDNode._objectNodeForNode(node)
    }
    
    internal override class func _objectNodeForNode(_ node: _CFXMLNodePtr) -> XMLDTD {
        precondition(_CFXMLNodeGetType(node) == _kCFXMLTypeDTD)

        if let privateData = _CFXMLNodeGetPrivateData(node) {
            return XMLDTD.unretainedReference(privateData)
        }
        
        return XMLDTD(ptr: node)
    }
    
    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}


