// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
/*!
    @class NSXMLDTD
    @abstract Defines the order, repetition, and allowable values for a document
*/
public class NSXMLDTD : NSXMLNode {

    internal var _xmlDTD: _CFXMLDTDPtr {
        return _CFXMLDTDPtr(_xmlNode)
    }
    
    public convenience init(contentsOfURL url: NSURL, options mask: Int) throws {
        guard let urlString = url.absoluteString else {
            //TODO: throw an error
            fatalError("nil URL")
        }

        let node = _CFXMLParseDTD(urlString)
        if node == nil {
            //TODO: throw error
            fatalError("parsing dtd string failed")
        }
        self.init(ptr: node)
    }

    public convenience init(data: NSData, options mask: Int) throws {
        var unmanagedError: Unmanaged<CFErrorRef>? = nil
        let node = _CFXMLParseDTDFromData(data._cfObject, &unmanagedError)
        if node == nil {
            if let error = unmanagedError?.takeRetainedValue()._nsObject {
                throw error
            }
        }

        self.init(ptr: node)
    } //primitive
    
    /*!
        @method publicID
        @abstract Sets the public id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set.
    */
    public var publicID: String? {
        get {
            return _CFXMLDTDExternalID(_xmlDTD)?._swiftObject
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
    public var systemID: String? {
        get {
            return _CFXMLDTDSystemID(_xmlDTD)?._swiftObject
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
    public func insertChild(child: NSXMLNode, atIndex index: Int) {
        _insertChild(child, atIndex: index)
    } //primitive
    
    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    public func insertChildren(children: [NSXMLNode], atIndex index: Int) {
        _insertChildren(children, atIndex: index)
    }
    
    /*!
        @method removeChildAtIndex:
        @abstract Removes a child at a particular index.
    */
    public func removeChildAtIndex(index: Int) {
        _removeChildAtIndex(index)
    } //primitive
    
    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    public func setChildren(children: [NSXMLNode]?) {
        _setChildren(children)
    } //primitive
    
    /*!
        @method addChild:
        @abstract Adds a child to the end of the existing children.
    */
    public func addChild(child: NSXMLNode) {
        _addChild(child)
    }
    
    /*!
        @method replaceChildAtIndex:withNode:
        @abstract Replaces a child at a particular index with another child.
    */
    public func replaceChildAtIndex(index: Int, withNode node: NSXMLNode) {
        _replaceChildAtIndex(index, withNode: node)
    }
    
    /*!
        @method entityDeclarationForName:
        @abstract Returns the entity declaration matching this name.
    */
    public func entityDeclarationForName(name: String) -> NSXMLDTDNode? {
        let node = _CFXMLDTDGetEntityDesc(_xmlDTD, name)
        if node == nil {
            return nil
        }
        return NSXMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method notationDeclarationForName:
        @abstract Returns the notation declaration matching this name.
    */
    public func notationDeclarationForName(name: String) -> NSXMLDTDNode? {
        let node = _CFXMLDTDGetNotationDesc(_xmlDTD, name)

        if node == nil {
            return nil
        }
        return NSXMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method elementDeclarationForName:
        @abstract Returns the element declaration matching this name.
    */
    public func elementDeclarationForName(name: String) -> NSXMLDTDNode? {
        let node = _CFXMLDTDGetElementDesc(_xmlDTD, name)

        if node == nil {
            return nil
        }
        return NSXMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method attributeDeclarationForName:
        @abstract Returns the attribute declaration matching this name.
    */
    public func attributeDeclarationForName(name: String, elementName: String) -> NSXMLDTDNode? {
        let node = _CFXMLDTDGetAttributeDesc(_xmlDTD, elementName, name)

        if node == nil {
            return nil
        }
        return NSXMLDTDNode._objectNodeForNode(node)
    } //primitive
    
    /*!
        @method predefinedEntityDeclarationForName:
        @abstract Returns the predefined entity declaration matching this name.
    	@discussion The five predefined entities are
    	<ul><li>&amp;lt; - &lt;</li><li>&amp;gt; - &gt;</li><li>&amp;amp; - &amp;</li><li>&amp;quot; - &quot;</li><li>&amp;apos; - &amp;</li></ul>
    */
    public class func predefinedEntityDeclarationForName(name: String) -> NSXMLDTDNode? {
        let node = _CFXMLDTDGetPredefinedEntity(name)

        if node == nil {
            return nil
        }

        return NSXMLDTDNode._objectNodeForNode(node)
    }
    
    internal override class func _objectNodeForNode(node: _CFXMLNodePtr) -> NSXMLDTD {
        precondition(_CFXMLNodeGetType(node) == _kCFXMLTypeDTD)

        if _CFXMLNodeGetPrivateData(node) != nil {
            let unmanaged = Unmanaged<NSXMLDTD>.fromOpaque(_CFXMLNodeGetPrivateData(node))
            return unmanaged.takeUnretainedValue()
        }
        
        return NSXMLDTD(ptr: node)
    }
    
    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}


