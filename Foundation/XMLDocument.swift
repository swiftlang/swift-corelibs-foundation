// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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

extension XMLDocument {

    /*!
        @typedef XMLDocument.ContentKind
        @abstract Define what type of document this is.
        @constant XMLDocument.ContentKind.xml The default document type
        @constant XMLDocument.ContentKind.xhtml Set if XMLNode.Options.documentTidyHTML is set and HTML is detected
        @constant XMLDocument.ContentKind.html Outputs empty tags without a close tag, eg <br>
        @constant XMLDocument.ContentKind.text Output the string value of the document
    */
    public enum ContentKind : UInt {

        case xml
        case xhtml
        case html
        case text
    }
}

/*!
    @class XMLDocument
    @abstract An XML Document
	@discussion Note: if the application of a method would result in more than one element in the children array, an exception is thrown. Trying to add a document, namespace, attribute, or node with a parent also throws an exception. To add a node with a parent first detach or create a copy of it.
*/
open class XMLDocument : XMLNode {
    private var _xmlDoc: _CFXMLDocPtr {
        return _CFXMLDocPtr(_xmlNode)
    }
    
    public init() {
        NSUnimplemented()
    }
    
    /*!
        @method initWithXMLString:options:error:
        @abstract Returns a document created from either XML or HTML, if the HTMLTidy option is set. Parse errors are returned in <tt>error</tt>.
    */
    public convenience init(xmlString string: String, options mask: XMLNode.Options = []) throws {
        guard let data = string.data(using: .utf8) else {
            // TODO: Throw an error
            fatalError("String: '\(string)' could not be converted to NSData using UTF-8 encoding")
        }

        try self.init(data: data, options: mask)
    }

    /*!
        @method initWithContentsOfURL:options:error:
        @abstract Returns a document created from the contents of an XML or HTML URL. Connection problems such as 404, parse errors are returned in <tt>error</tt>.
    */
    public convenience init(contentsOf url: URL, options mask: XMLNode.Options = []) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        try self.init(data: data, options: mask)
    }

    /*!
        @method initWithData:options:error:
        @abstract Returns a document created from data. Parse errors are returned in <tt>error</tt>.
    */
    public init(data: Data, options mask: XMLNode.Options = []) throws {
        let docPtr = _CFXMLDocPtrFromDataWithOptions(data._cfObject, UInt32(mask.rawValue))
        super.init(ptr: _CFXMLNodePtr(docPtr))

        if mask.contains(.documentValidate) {
            try validate()
        }
    }

    /*!
        @method initWithRootElement:
        @abstract Returns a document with a single child, the root element.
    */
    public init(rootElement element: XMLElement?) {
        precondition(element?.parent == nil)

        super.init(kind: .document, options: [])
        if let element = element {
            _CFXMLDocSetRootElement(_xmlDoc, element._xmlNode)
            _childNodes.insert(element)
        }
    }

    open class func replacementClass(for cls: AnyClass) -> AnyClass {
        NSUnimplemented()
    }

    /*!
        @method characterEncoding
        @abstract Sets the character encoding to an IANA type.
    */
    open var characterEncoding: String? {
        get {
            return _CFXMLDocCopyCharacterEncoding(_xmlDoc)?._swiftObject
        }
        set {
            if let value = newValue {
                _CFXMLDocSetCharacterEncoding(_xmlDoc, value)
            } else {
                _CFXMLDocSetCharacterEncoding(_xmlDoc, nil)
            }
        }
    }

    /*!
        @method version
        @abstract Sets the XML version. Should be 1.0 or 1.1.
    */
    open var version: String? {
        get {
            return _CFXMLDocCopyVersion(_xmlDoc)?._swiftObject
        }
        set {
            if let value = newValue {
                precondition(value == "1.0" || value == "1.1")
                _CFXMLDocSetVersion(_xmlDoc, value)
            } else {
                _CFXMLDocSetVersion(_xmlDoc, nil)
            }
        }
    }

    /*!
        @method standalone
        @abstract Set whether this document depends on an external DTD. If this option is set the standalone declaration will appear on output.
    */
    open var isStandalone: Bool {
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
    open var documentContentKind: XMLDocument.ContentKind  {
        get {
            let properties = _CFXMLDocProperties(_xmlDoc)

            if properties & Int32(_kCFXMLDocTypeHTML) != 0 {
                return .html
            }

            return .xml
        }

        set {
            var properties = _CFXMLDocProperties(_xmlDoc)
            switch newValue {
            case .html:
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
    open var mimeType: String?

    /*!
        @method DTD
        @abstract Set the associated DTD. This DTD will be output with the document.
    */
    /*@NSCopying*/ open var dtd: XMLDTD? {
        get {
            return XMLDTD._objectNodeForNode(_CFXMLDocDTD(_xmlDoc)!)
        }
        set {
            if let currDTD = _CFXMLDocDTD(_xmlDoc) {
                if _CFXMLNodeGetPrivateData(currDTD) != nil {
                    let DTD = XMLDTD._objectNodeForNode(currDTD)
                    _CFXMLUnlinkNode(currDTD)
                    _childNodes.remove(DTD)
                } else {
                    _CFXMLFreeDTD(currDTD)
                }
            }

            if let value = newValue {
                guard let dtd = value.copy() as? XMLDTD else {
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
    open func setRootElement(_ root: XMLElement) {
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
    open func rootElement() -> XMLElement? {
        guard let rootPtr = _CFXMLDocRootElement(_xmlDoc) else {
            return nil
        }

        return XMLNode._objectNodeForNode(rootPtr) as? XMLElement
    }

    /*!
        @method insertChild:atIndex:
        @abstract Inserts a child at a particular index.
    */
    open func insertChild(_ child: XMLNode, at index: Int) {
        _insertChild(child, atIndex: index)
    }

    /*!
        @method insertChildren:atIndex:
        @abstract Insert several children at a particular index.
    */
    open func insertChildren(_ children: [XMLNode], at index: Int) {
        _insertChildren(children, atIndex: index)
    }

    /*!
        @method removeChildAtIndex:atIndex:
        @abstract Removes a child at a particular index.
    */
    open func removeChild(at index: Int) {
        _removeChildAtIndex(index)
    }

    /*!
        @method setChildren:
        @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
    */
    open func setChildren(_ children: [XMLNode]?) {
        _setChildren(children)
    }

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
        @method XMLData
        @abstract Invokes XMLDataWithOptions with XMLNode.Options.none.
    */
    /*@NSCopying*/ open var xmlData: Data { return xmlData() }

    /*!
        @method XMLDataWithOptions:
        @abstract The representation of this node as it would appear in an XML document, encoded based on characterEncoding.
    */
    open func xmlData(options: XMLNode.Options = []) -> Data {
        let string = xmlString(options: options)
        // TODO: support encodings other than UTF-8

        return string.data(using: .utf8) ?? Data()
    }

    /*!
        @method objectByApplyingXSLT:arguments:error:
        @abstract Applies XSLT with arguments (NSString key/value pairs) to this document, returning a new document.
    */
    open func object(byApplyingXSLT xslt: Data, arguments: [String : String]?) throws -> Any {
        NSUnimplemented()
    }

    /*!
        @method objectByApplyingXSLTString:arguments:error:
        @abstract Applies XSLT as expressed by a string with arguments (NSString key/value pairs) to this document, returning a new document.
    */
    open func object(byApplyingXSLTString xslt: String, arguments: [String : String]?) throws -> Any {
        NSUnimplemented()
    }

    /*!
        @method objectByApplyingXSLTAtURL:arguments:error:
        @abstract Applies the XSLT at a URL with arguments (NSString key/value pairs) to this document, returning a new document. Error may contain a connection error from the URL.
    */
    open func objectByApplyingXSLT(at xsltURL: URL, arguments argument: [String : String]?) throws -> Any {
        NSUnimplemented()
    }

    open func validate() throws {
        var unmanagedError: Unmanaged<CFError>? = nil
        let result = _CFXMLDocValidate(_xmlDoc, &unmanagedError)
        if !result,
            let unmanagedError = unmanagedError {
            let error = unmanagedError.takeRetainedValue()
            throw error._nsObject
        }
    }

    internal override class func _objectNodeForNode(_ node: _CFXMLNodePtr) -> XMLDocument {
        precondition(_CFXMLNodeGetType(node) == _kCFXMLTypeDocument)

        if let privateData = _CFXMLNodeGetPrivateData(node) {
            return XMLDocument.unretainedReference(privateData)
        }

        return XMLDocument(ptr: node)
    }

    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}
