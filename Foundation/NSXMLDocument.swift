// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import libxml2
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
    private var _xmlDoc: xmlDocPtr {
        get {
            return xmlDocPtr(_xmlNode)
        }
    }
    /*!
        @method initWithXMLString:options:error:
        @abstract Returns a document created from either XML or HTML, if the HTMLTidy option is set. Parse errors are returned in <tt>error</tt>.
    */
    public convenience init(XMLString string: String, options mask: Int) throws {
        let data: NSData = string.withCString {
            (stringPtr: UnsafePointer<CChar>) -> NSData in
            return NSData(bytes: UnsafeMutablePointer<Void>(stringPtr), length: Int(strlen(stringPtr)) + 1, copy: true, deallocator: nil)
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
        var xmlOptions: UInt32 = 0
        if mask & NSXMLNodePreserveWhitespace == 0 {
            xmlOptions |= XML_PARSE_NOBLANKS.rawValue
        }

        if mask & NSXMLNodeLoadExternalEntitiesNever != 0 {
            xmlOptions &= ~(XML_PARSE_NOENT.rawValue)
        } else {
            xmlOptions |= XML_PARSE_NOENT.rawValue
        }

        if mask & NSXMLNodeLoadExternalEntitiesAlways != 0 {
            xmlOptions |= XML_PARSE_DTDLOAD.rawValue
        }

        let docPtr = xmlReadMemory(UnsafePointer<Int8>(data.bytes), Int32(data.length), nil, nil, Int32(xmlOptions))
        super.init(ptr: xmlNodePtr(docPtr))
    } //primitive

    /*!
        @method initWithRootElement:
        @abstract Returns a document with a single child, the root element.
    */
    public init(rootElement element: NSXMLElement?) {
        precondition(element?.parent == nil)

        super.init(kind: .DocumentKind, options: NSXMLNodeOptionsNone)
        if let element = element {
            xmlDocSetRootElement(_xmlDoc, element._xmlNode)
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
            return String.fromCString(UnsafePointer<CChar>(_xmlDoc.memory.encoding))
        }
        set {
            if _xmlDoc.memory.encoding != nil {
                xmlFree(UnsafeMutablePointer<xmlChar>(_xmlDoc.memory.encoding))
            }
            if let encoding = newValue {
                _xmlDoc.memory.encoding = encoding._xmlString
            } else {
                _xmlDoc.memory.encoding = nil
            }
        }
    } //primitive

    /*!
        @method version
        @abstract Sets the XML version. Should be 1.0 or 1.1.
    */
    public var version: String? {
        get {
            return String.fromCString(UnsafePointer<CChar>(_xmlDoc.memory.version))
        }
        set {
            newValue?.withCString {
                ptr -> Void in
                memcpy(UnsafeMutablePointer<Void>(_xmlDoc.memory.version), ptr, 3)
            }
        }
    } //primitive

    /*!
        @method standalone
        @abstract Set whether this document depends on an external DTD. If this option is set the standalone declaration will appear on output.
    */
    public var standalone: Bool {
        get {
            return _xmlDoc.memory.standalone != 0
        }
        set {
            if newValue {
                _xmlDoc.memory.standalone = 1
            } else {
                _xmlDoc.memory.standalone = 0
            }
        }
    }//primitive

    /*!
        @method documentContentKind
        @abstract The kind of document.
    */
    public var documentContentKind: NSXMLDocumentContentKind  {
        get {
            let properties = _xmlDoc.memory.properties

            if properties & Int32(XML_DOC_HTML.rawValue) != 0 {
                return .HTMLKind
            }

            return .XMLKind
        }

        set {
            switch newValue {
            case .HTMLKind:
                _xmlDoc.memory.properties |= Int32(XML_DOC_HTML.rawValue)

            default:
                _xmlDoc.memory.properties &= ~Int32(XML_DOC_HTML.rawValue)
            }
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
    /*@NSCopying*/ public var DTD: NSXMLDTD? //primitive

    /*!
        @method setRootElement:
        @abstract Set the root element. Removes all other children including comments and processing-instructions.
    */
    public func setRootElement(root: NSXMLElement) {
        precondition(root.parent == nil)

        for child in _childNodes {
            child.detach()
        }

        xmlDocSetRootElement(_xmlDoc, root._xmlNode)
        _childNodes.insert(root)
    }

    /*!
        @method rootElement
        @abstract The root element.
    */
    public func rootElement() -> NSXMLElement? {
        let rootPtr = xmlDocGetRootElement(_xmlDoc)
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
    /*@NSCopying*/ public var XMLData: NSData { NSUnimplemented() }

    /*!
        @method XMLDataWithOptions:
        @abstract The representation of this node as it would appear in an XML document, encoded based on characterEncoding.
    */
    public func XMLDataWithOptions(options: Int) -> NSData { NSUnimplemented() }

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

    public func validate() throws { NSUnimplemented() }

    internal override class func _objectNodeForNode(node: xmlNodePtr) -> NSXMLDocument {
        precondition(node.memory.type == XML_DOCUMENT_NODE)

        if node.memory._private != nil {
            let unmanaged = Unmanaged<NSXMLDocument>.fromOpaque(node.memory._private)
            return unmanaged.takeUnretainedValue()
        }

        return NSXMLDocument(ptr: node)
    }

    internal override init(ptr: xmlNodePtr) {
        super.init(ptr: ptr)
    }
}

internal extension String {
    internal var _xmlString: UnsafePointer<xmlChar> {
        return self.withCString {
            (ptr: UnsafePointer<CChar>) -> UnsafePointer<xmlChar> in
            let length = self.utf8.count + 1
            let result = UnsafeMutablePointer<CChar>.alloc(length)
            strncpy(result, ptr, length)
            return UnsafePointer<xmlChar>(result)
        }
    }
}
