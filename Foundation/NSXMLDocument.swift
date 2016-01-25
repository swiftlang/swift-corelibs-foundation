// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
// Input options
//  NSXMLNodeOptionsNone
//  NSXMLNodePreserveAll
//  NSXMLNodePreserveNamespaceOrder
//  NSXMLNodePreserveAttributeOrder
//  NSXMLNodePreserveEntities
//  NSXMLNodePreservePrefixes
//  NSXMLNodePreserveCDATA
//  NSXMLNodePreserveEmptyElements
//  NSXMLNodePreserveQuotes
//  NSXMLNodePreserveWhitespace
//  NSXMLNodeLoadExternalEntities
//  NSXMLNodeLoadExternalEntitiesSameOriginOnly

//  NSXMLDocumentTidyHTML
//  NSXMLDocumentTidyXML

//  NSXMLDocumentValidate

// Output options
//  NSXMLNodePrettyPrint
//  NSXMLDocumentIncludeContentTypeDeclaration

/*!
    @typedef NSXMLDocumentContentKind
	@abstract Define what type of document this is.
	@constant NSXMLDocumentXMLKind The default document type
	@constant NSXMLDocumentXHTMLKind Set if NSXMLDocumentTidyHTML is set and HTML is detected
	@constant NSXMLDocumentHTMLKind Outputs empty tags without a close tag, eg <br>
	@constant NSXMLDocumentTextKind Output the string value of the document
*/
public enum NSXMLDocumentContentKind : UInt {

    case XMLKind
    case XHTMLKind
    case HTMLKind
    case TextKind
}

/*!
    @class NSXMLDocument
    @abstract An XML Document
	@discussion Note: if the application of a method would result in more than one element in the children array, an exception is thrown. Trying to add a document, namespace, attribute, or node with a parent also throws an exception. To add a node with a parent first detach or create a copy of it.
*/
public class NSXMLDocument : NSXMLNode {
    private var _xmlDoc: _CFXMLDocPtr {
        return _CFXMLDocPtr(_xmlNode)
    }
    /*!
        @method initWithXMLString:options:error:
        @abstract Returns a document created from either XML or HTML, if the HTMLTidy option is set. Parse errors are returned in <tt>error</tt>.
    */
    public convenience init(XMLString string: String, options mask: Int) throws {
        guard let data = string._bridgeToObject().dataUsingEncoding(NSUTF8StringEncoding) else {
            // TODO: Throw an error
            fatalError("String: '\(string)' could not be converted to NSData using UTF-8 encoding")
        }

        try self.init(data: data, options: mask)
    }

    /*!
        @method initWithContentsOfURL:options:error:
        @abstract Returns a document created from the contents of an XML or HTML URL. Connection problems such as 404, parse errors are returned in <tt>error</tt>.
    */
    public convenience init(contentsOfURL url: NSURL, options mask: Int) throws {
        let data = try NSData(contentsOfURL: url, options: .DataReadingMappedIfSafe)

        try self.init(data: data, options: mask)
    }

    /*!
        @method initWithData:options:error:
        @abstract Returns a document created from data. Parse errors are returned in <tt>error</tt>.
    */
    public init(data: NSData, options mask: Int) throws {
        let docPtr = _CFXMLDocPtrFromDataWithOptions(data._cfObject, Int32(mask))
        super.init(ptr: _CFXMLNodePtr(docPtr))

        if mask & NSXMLDocumentValidate != 0 {
            try validate()
        }
    } //primitive

    /*!
        @method initWithRootElement:
        @abstract Returns a document with a single child, the root element.
    */
    public init(rootElement element: NSXMLElement?) {
        precondition(element?.parent == nil)

        super.init(kind: .DocumentKind, options: NSXMLNodeOptionsNone)
        if let element = element {
            _CFXMLDocSetRootElement(_xmlDoc, element._xmlNode)
            _childNodes.insert(element)
        }
    }

    public class func replacementClassForClass(cls: AnyClass) -> AnyClass { NSUnimplemented() }

    /*!
        @method characterEncoding
        @abstract Sets the character encoding to an IANA type.
    */
    public var characterEncoding: String? {
        get {
            return _CFXMLDocCharacterEncoding(_xmlDoc)?._swiftObject
        }
        set {
            if let value = newValue {
                _CFXMLDocSetCharacterEncoding(_xmlDoc, value)
            } else {
                _CFXMLDocSetCharacterEncoding(_xmlDoc, nil)
            }
        }
    } //primitive

    /*!
        @method version
        @abstract Sets the XML version. Should be 1.0 or 1.1.
    */
    public var version: String? {
        get {
            return _CFXMLDocVersion(_xmlDoc)?._swiftObject
        }
        set {
            if let value = newValue {
                precondition(value == "1.0" || value == "1.1")
                _CFXMLDocSetVersion(_xmlDoc, value)
            } else {
                _CFXMLDocSetVersion(_xmlDoc, nil)
            }
        }
    } //primitive

    /*!
        @method standalone
        @abstract Set whether this document depends on an external DTD. If this option is set the standalone declaration will appear on output.
    */
    public var standalone: Bool {
        get {
            return _CFXMLDocStandalone(_xmlDoc)
        }
        set {
            _CFXMLDocSetStandalone(_xmlDoc, newValue)
        }
    }//primitive

    /*!
        @method documentContentKind
        @abstract The kind of document.
    */
    public var documentContentKind: NSXMLDocumentContentKind  {
        get {
            let properties = _CFXMLDocProperties(_xmlDoc);

            if properties & Int32(_kCFXMLDocTypeHTML) != 0 {
                return .HTMLKind
            }

            return .XMLKind
        }

        set {
            var properties = _CFXMLDocProperties(_xmlDoc)
            switch newValue {
            case .HTMLKind:
                properties |= Int32(_kCFXMLDocTypeHTML)

            default:
                properties &= ~Int32(_kCFXMLDocTypeHTML)
            }

            _CFXMLDocSetProperties(_xmlDoc, properties)
        }
    }//primitive

    /*!
        @method MIMEType
        @abstract Set the MIME type, eg text/xml.
    */
    public var MIMEType: String? //primitive

    /*!
        @method DTD
        @abstract Set the associated DTD. This DTD will be output with the document.
    */
    /*@NSCopying*/ public var DTD: NSXMLDTD? {
        get {
            return NSXMLDTD._objectNodeForNode(_CFXMLDocDTD(_xmlDoc));
        }
        set {
            let currDTD = _CFXMLDocDTD(_xmlDoc)
            if currDTD != nil {
                if _CFXMLNodeGetPrivateData(currDTD) != nil {
                    let DTD = NSXMLDTD._objectNodeForNode(currDTD)
                    _CFXMLUnlinkNode(currDTD)
                    _childNodes.remove(DTD)
                } else {
                    _CFXMLFreeDTD(currDTD)
                }
            }

            if let value = newValue {
                guard let dtd = value.copy() as? NSXMLDTD else {
                    fatalError("Failed to copy DTD")
                }
                _CFXMLDocSetDTD(_xmlDoc, dtd._xmlDTD)
                _childNodes.insert(dtd)
            } else {
                _CFXMLDocSetDTD(_xmlDoc, nil)
            }
        }
    }//primitive

    /*!
        @method setRootElement:
        @abstract Set the root element. Removes all other children including comments and processing-instructions.
    */
    public func setRootElement(root: NSXMLElement) {
        precondition(root.parent == nil)

        for child in _childNodes {
            child.detach()
        }

        _CFXMLDocSetRootElement(_xmlDoc, root._xmlNode)
        _childNodes.insert(root)
    }

    /*!
        @method rootElement
        @abstract The root element.
    */
    public func rootElement() -> NSXMLElement? {
        let rootPtr = _CFXMLDocRootElement(_xmlDoc)
        if rootPtr == nil {
            return nil
        }

        return NSXMLNode._objectNodeForNode(rootPtr) as? NSXMLElement
    } //primitive

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
        @method removeChildAtIndex:atIndex:
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
        @method XMLData
        @abstract Invokes XMLDataWithOptions with NSXMLNodeOptionsNone.
    */
    /*@NSCopying*/ public var XMLData: NSData { return XMLDataWithOptions(NSXMLNodeOptionsNone) }

    /*!
        @method XMLDataWithOptions:
        @abstract The representation of this node as it would appear in an XML document, encoded based on characterEncoding.
    */
    public func XMLDataWithOptions(options: Int) -> NSData {
        let string = XMLStringWithOptions(options)
        // TODO: support encodings other than UTF-8

        return string._bridgeToObject().dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
    }

    /*!
        @method objectByApplyingXSLT:arguments:error:
        @abstract Applies XSLT with arguments (NSString key/value pairs) to this document, returning a new document.
    */
    public func objectByApplyingXSLT(xslt: NSData, arguments: [String : String]?) throws -> AnyObject { NSUnimplemented() }

    /*!
        @method objectByApplyingXSLTString:arguments:error:
        @abstract Applies XSLT as expressed by a string with arguments (NSString key/value pairs) to this document, returning a new document.
    */
    public func objectByApplyingXSLTString(xslt: String, arguments: [String : String]?) throws -> AnyObject { NSUnimplemented() }

    /*!
        @method objectByApplyingXSLTAtURL:arguments:error:
        @abstract Applies the XSLT at a URL with arguments (NSString key/value pairs) to this document, returning a new document. Error may contain a connection error from the URL.
    */
    public func objectByApplyingXSLTAtURL(xsltURL: NSURL, arguments argument: [String : String]?) throws -> AnyObject { NSUnimplemented() }

    public func validate() throws {
        var unmanagedError: Unmanaged<CFError>? = nil
        let result = _CFXMLDocValidate(_xmlDoc, &unmanagedError)
        if !result,
            let unmanagedError = unmanagedError {
            let error = unmanagedError.takeRetainedValue()
            throw error._nsObject
        }
    }

    internal override class func _objectNodeForNode(node: _CFXMLNodePtr) -> NSXMLDocument {
        precondition(_CFXMLNodeGetType(node) == _kCFXMLTypeDocument)

        if _CFXMLNodeGetPrivateData(node) != nil {
            let unmanaged = Unmanaged<NSXMLDocument>.fromOpaque(_CFXMLNodeGetPrivateData(node))
            return unmanaged.takeUnretainedValue()
        }

        return NSXMLDocument(ptr: node)
    }

    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}
