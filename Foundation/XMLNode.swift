// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

//import libxml2
import CoreFoundation

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
open class XMLNode: NSObject, NSCopying {

    public enum Kind : UInt {
        case invalid
        case document
        case element
        case attribute
        case namespace
        case processingInstruction
        case comment
        case text
        case DTDKind
        case entityDeclaration
        case attributeDeclaration
        case elementDeclaration
        case notationDeclaration
    }

    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let nodeIsCDATA = Options(rawValue: 1 << 0)
        public static let nodeExpandEmptyElement = Options(rawValue: 1 << 1)
        public static let nodeCompactEmptyElement = Options(rawValue: 1 << 2)
        public static let nodeUseSingleQuotes = Options(rawValue: 1 << 3)
        public static let nodeUseDoubleQuotes = Options(rawValue: 1 << 4)
        public static let nodeNeverEscapeContents = Options(rawValue: 1 << 5)

        public static let documentTidyHTML = Options(rawValue: 1 << 9)
        public static let documentTidyXML = Options(rawValue: 1 << 10)
        public static let documentValidate = Options(rawValue: 1 << 13)

        public static let nodeLoadExternalEntitiesAlways = Options(rawValue: 1 << 14)
        public static let nodeLoadExternalEntitiesSameOriginOnly = Options(rawValue: 1 << 15)
        public static let nodeLoadExternalEntitiesNever = Options(rawValue: 1 << 19)

        public static let documentXInclude = Options(rawValue: 1 << 16)
        public static let nodePrettyPrint = Options(rawValue: 1 << 17)
        public static let documentIncludeContentTypeDeclaration = Options(rawValue: 1 << 18)

        public static let nodePreserveNamespaceOrder = Options(rawValue: 1 << 20)
        public static let nodePreserveAttributeOrder = Options(rawValue: 1 << 21)
        public static let nodePreserveEntities = Options(rawValue: 1 << 22)
        public static let nodePreservePrefixes = Options(rawValue: 1 << 23)
        public static let nodePreserveCDATA = Options(rawValue: 1 << 24)
        public static let nodePreserveWhitespace = Options(rawValue: 1 << 25)
        public static let nodePreserveDTD = Options(rawValue: 1 << 26)
        public static let nodePreserveCharacterReferences = Options(rawValue: 1 << 27)
        public static let nodePromoteSignificantWhitespace = Options(rawValue: 1 << 28)
        public static let nodePreserveEmptyElements = Options([.nodeExpandEmptyElement, .nodeCompactEmptyElement])
        public static let nodePreserveQuotes = Options([.nodeUseSingleQuotes, .nodeUseDoubleQuotes])
        public static let nodePreserveAll = Options(rawValue: 0xFFF00000).union([.nodePreserveNamespaceOrder, .nodePreserveAttributeOrder, .nodePreserveEntities, .nodePreservePrefixes, .nodePreserveCDATA, .nodePreserveEmptyElements, .nodePreserveQuotes, .nodePreserveWhitespace, .nodePreserveDTD, .nodePreserveCharacterReferences])
    }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    internal let _xmlNode: _CFXMLNodePtr

    open func copy(with zone: NSZone? = nil) -> Any {
        let newNode = _CFXMLCopyNode(_xmlNode, true)
        return XMLNode._objectNodeForNode(newNode)
    }

    /*!
        @method initWithKind:
        @abstract Invokes @link initWithKind:options: @/link with options set to NSXMLNodeOptionsNone
    */
    public convenience init(kind: XMLNode.Kind) {
        self.init(kind: kind, options: [])
    }

    /*!
        @method initWithKind:options:
        @abstract Inits a node with fidelity options as description NSXMLNodeOptions.h
    */
    public init(kind: XMLNode.Kind, options: XMLNode.Options = []) {

        switch kind {
        case .document:
            let docPtr = _CFXMLNewDoc("1.0")
            _CFXMLDocSetStandalone(docPtr, false) // same default as on Darwin
            _xmlNode = _CFXMLNodePtr(docPtr)

        case .element:
            _xmlNode = _CFXMLNewNode(nil, "")

        case .attribute:
            _xmlNode = _CFXMLNodePtr(_CFXMLNewProperty(nil, "", ""))

        case .DTDKind:
            _xmlNode = _CFXMLNewDTD(nil, "", "", "")

        case .namespace:
            _xmlNode = _CFXMLNewNamespace("", "")

        default:
            fatalError("invalid node kind for this initializer")
        }

        super.init()

        withUnretainedReference {
            _CFXMLNodeSetPrivateData(_xmlNode, $0)
        }
    }

    /*!
        @method document:
        @abstract Returns an empty document.
    */
    open class func document() -> Any {
        return XMLDocument(rootElement: nil)
    }

    /*!
        @method documentWithRootElement:
        @abstract Returns a document
        @param element The document's root node.
    */
    open class func document(withRootElement element: XMLElement) -> Any {
        return XMLDocument(rootElement: element)
    }

    /*!
        @method elementWithName:
        @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
    */
    open class func element(withName name: String) -> Any {
        return XMLElement(name: name)
    }

    /*!
        @method elementWithName:URI:
        @abstract Returns an element whose full QName is specified.
    */
    open class func element(withName name: String, uri: String) -> Any {
        return XMLElement(name: name, uri: uri)
    }

    /*!
        @method elementWithName:stringValue:
        @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
    */
    open class func element(withName name: String, stringValue string: String) -> Any {
        return XMLElement(name: name, stringValue: string)
    }

    /*!
        @method elementWithName:children:attributes:
        @abstract Returns an element children and attributes <tt>&lt;name attr1="foo" attr2="bar">&lt;-- child1 -->child2&lt;/name></tt>.
    */
    open class func element(withName name: String, children: [XMLNode]?, attributes: [XMLNode]?) -> Any {
        let element = XMLElement(name: name)
        element.setChildren(children)
        element.attributes = attributes

        return element
    }

    /*!
        @method attributeWithName:stringValue:
        @abstract Returns an attribute <tt>name="stringValue"</tt>.
    */
    open class func attribute(withName name: String, stringValue: String) -> Any {
        let attribute = _CFXMLNewProperty(nil, name, stringValue)

        return XMLNode(ptr: attribute)
    }

    /*!
        @method attributeWithLocalName:URI:stringValue:
        @abstract Returns an attribute whose full QName is specified.
    */
    open class func attribute(withName name: String, uri: String, stringValue: String) -> Any {
        let attribute = XMLNode.attribute(withName: name, stringValue: stringValue) as! XMLNode
//        attribute.URI = URI

        return attribute
    }

    /*!
        @method namespaceWithName:stringValue:
        @abstract Returns a namespace <tt>xmlns:name="stringValue"</tt>.
    */
    open class func namespace(withName name: String, stringValue: String) -> Any {
        let node = _CFXMLNewNamespace(name, stringValue)
        return XMLNode(ptr: node)
    }

    /*!
        @method processingInstructionWithName:stringValue:
        @abstract Returns a processing instruction <tt>&lt;?name stringValue></tt>.
    */
    public class func processingInstruction(withName name: String, stringValue: String) -> Any {
        let node = _CFXMLNewProcessingInstruction(name, stringValue)
        return XMLNode(ptr: node)
    }

    /*!
        @method commentWithStringValue:
        @abstract Returns a comment <tt>&lt;--stringValue--></tt>.
    */
    open class func comment(withStringValue stringValue: String) -> Any {
        let node = _CFXMLNewComment(stringValue)
        return XMLNode(ptr: node)
    }

    /*!
        @method textWithStringValue:
        @abstract Returns a text node.
    */
    open class func text(withStringValue stringValue: String) -> Any {
        let node = _CFXMLNewTextNode(stringValue)
        return XMLNode(ptr: node)
    }

    /*!
        @method DTDNodeWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    open class func dtdNode(withXMLString string: String) -> Any? {
        guard let node = _CFXMLParseDTDNode(string) else { return nil }

        return XMLDTDNode(ptr: node)
    }

    /*!
        @method kind
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    open var kind: XMLNode.Kind  {
        switch _CFXMLNodeGetType(_xmlNode) {
        case _kCFXMLTypeElement:
            return .element

        case _kCFXMLTypeAttribute:
            return .attribute

        case _kCFXMLTypeDocument:
            return .document

        case _kCFXMLTypeDTD:
            return .DTDKind

        case _kCFXMLDTDNodeTypeElement:
            return .elementDeclaration

        case _kCFXMLDTDNodeTypeEntity:
            return .entityDeclaration

        case _kCFXMLDTDNodeTypeNotation:
            return .notationDeclaration

        case _kCFXMLDTDNodeTypeAttribute:
            return .attributeDeclaration

        case _kCFXMLTypeNamespace:
            return .namespace

        default:
            return .invalid
        }
    }

    /*!
        @method name
        @abstract Sets the nodes name. Applicable for element, attribute, namespace, processing-instruction, document type declaration, element declaration, attribute declaration, entity declaration, and notation declaration.
    */
    open var name: String? {
        get {
            if case .namespace = kind {
                return _CFXMLNamespaceCopyPrefix(_xmlNode)?._swiftObject
            }

            return _CFXMLNodeCopyName(_xmlNode)?._swiftObject
        }
        set {
            if case .namespace = kind {
                _CFXMLNamespaceSetPrefix(_xmlNode, newValue, Int64(newValue?.utf8.count ?? 0))
            } else {
                if let newName = newValue {
                    _CFXMLNodeSetName(_xmlNode, newName)
                } else {
                    _CFXMLNodeSetName(_xmlNode, "")
                }
            }
        }
    }

    private var _objectValue: Any? = nil

    /*!
        @method objectValue
        @abstract Sets the content of the node. Setting the objectValue removes all existing children including processing instructions and comments. Setting the object value on an element creates a single text node child.
    */
    open var objectValue: Any? {
        get {
            if let value = _objectValue {
                return value
            } else {
                return stringValue
            }
        }
        set {
            _objectValue = newValue
            if let describableValue = newValue as? CustomStringConvertible {
                stringValue = "\(describableValue.description)"
            } else if let value = newValue {
                stringValue = "\(value)"
            } else {
                stringValue = nil
            }
        }
    }

    /*!
        @method stringValue:
        @abstract Sets the content of the node. Setting the stringValue removes all existing children including processing instructions and comments. Setting the string value on an element creates a single text node child. The getter returns the string value of the node, which may be either its content or child text nodes, depending on the type of node. Elements are recursed and text nodes concatenated in document order with no intervening spaces.
    */
    open var stringValue: String? {
        get {
            switch kind {
            case .entityDeclaration:
                return _CFXMLCopyEntityContent(_CFXMLEntityPtr(_xmlNode))?._swiftObject

            case .namespace:
                return _CFXMLNamespaceCopyValue(_xmlNode)?._swiftObject

            default:
                return _CFXMLNodeCopyContent(_xmlNode)?._swiftObject
            }
        }
        set {
            if case .namespace = kind {
                if let newValue = newValue {
                    precondition(URL(string: newValue) != nil, "namespace stringValue must be a valid href")
                }

                _CFXMLNamespaceSetValue(_xmlNode, newValue, Int64(newValue?.utf8.count ?? 0))
                return
            }

            _removeAllChildNodesExceptAttributes() // in case anyone is holding a reference to any of these children we're about to destroy

            if let string = newValue {
                let newContent = _CFXMLEncodeEntities(_CFXMLNodeGetDocument(_xmlNode), string)?._swiftObject ?? ""
                _CFXMLNodeSetContent(_xmlNode, newContent)
            } else {
                _CFXMLNodeSetContent(_xmlNode, nil)
            }
        }
    }

    private func _removeAllChildNodesExceptAttributes() {
        for node in _childNodes {
            if node.kind != .attribute {
                _CFXMLUnlinkNode(node._xmlNode)
                _childNodes.remove(node)
            }
        }
    }

    internal func _removeAllChildren() {
        var nextChild = _CFXMLNodeGetFirstChild(_xmlNode)
        while let child = nextChild {
            _CFXMLUnlinkNode(child)
            nextChild = _CFXMLNodeGetNextSibling(child)
        }
        _childNodes.removeAll(keepingCapacity: true)
    }

    /*!
        @method setStringValue:resolvingEntities:
        @abstract Sets the content as with @link setStringValue: @/link, but when "resolve" is true, character references, predefined entities and user entities available in the document's dtd are resolved. Entities not available in the dtd remain in their entity form.
    */
    open func setStringValue(_ string: String, resolvingEntities resolve: Bool) {
        guard resolve else {
            stringValue = string
            return
        }

        _removeAllChildNodesExceptAttributes()

        var entities: [(Range<Int>, String)] = []
        var entityChars: [Character] = []
        var inEntity = false
        var startIndex = 0
        for (index, char) in string.enumerated() {
            if char == "&" {
                inEntity = true
                startIndex = index
                continue
            }
            if char == ";" && inEntity {
                inEntity = false
                let min = startIndex
                let max = index + 1
                entities.append((min..<max, String(entityChars)))
                startIndex = 0
                entityChars.removeAll()
            }
            if inEntity {
                entityChars.append(char)
            }
        }

        var result: [Character] = Array(string)
        let doc = _CFXMLNodeGetDocument(_xmlNode)!
        for (range, entity) in entities {
            var entityPtr = _CFXMLGetDocEntity(doc, entity)
            if entityPtr == nil {
                entityPtr = _CFXMLGetDTDEntity(doc, entity)
            }
            if entityPtr == nil {
                entityPtr = _CFXMLGetParameterEntity(doc, entity)
            }
            if let validEntity = entityPtr {
                let replacement = _CFXMLCopyEntityContent(validEntity)?._swiftObject ?? ""
                result.replaceSubrange(range, with: replacement)
            } else {
                result.replaceSubrange(range, with: []) // This appears to be how Darwin Foundation does it
            }
        }
        stringValue = String(result)
    }

    /*!
        @method index
        @abstract A node's index amongst its siblings.
    */
    open var index: Int {
        if let siblings = self.parent?.children,
            let index = siblings.index(of: self) {
            return index
        }

        return 0
    }

    /*!
        @method level
        @abstract The depth of the node within the tree. Documents and standalone nodes are level 0.
    */
    open var level: Int {
        var result = 0
        var nextParent = _CFXMLNodeGetParent(_xmlNode)
        while let parent = nextParent {
            result += 1
            nextParent = _CFXMLNodeGetParent(parent)
        }

        return result
    }

    /*!
        @method rootDocument
        @abstract The encompassing document or nil.
    */
    open var rootDocument: XMLDocument? {
        guard let doc = _CFXMLNodeGetDocument(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(_CFXMLNodePtr(doc)) as? XMLDocument
    }

    /*!
        @method parent
        @abstract The parent of this node. Documents and standalone Nodes have a nil parent; there is not a 1-to-1 relationship between parent and children, eg a namespace cannot be a child but has a parent element.
    */
    /*@NSCopying*/ open var parent: XMLNode? {
        guard let parentPtr = _CFXMLNodeGetParent(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(parentPtr)
    }

    /*!
        @method childCount
        @abstract The amount of children, relevant for documents, elements, and document type declarations. Use this instead of [[self children] count].
    */
    open var childCount: Int {
        return _CFXMLNodeGetElementChildCount(_xmlNode)
    }

    /*!
        @method children
        @abstract An immutable array of child nodes. Relevant for documents, elements, and document type declarations.
    */
    open var children: [XMLNode]? {
        switch kind {
        case .document:
            fallthrough
        case .element:
            fallthrough
        case .DTDKind:
            return Array<XMLNode>(self as XMLNode)

        default:
            return nil
        }
    }

    /*!
        @method childAtIndex:
        @abstract Returns the child node at a particular index.
    */
    open func child(at index: Int) -> XMLNode? {
        precondition(index >= 0)
        precondition(index < childCount)

        return self[self.index(startIndex, offsetBy: index)]
    }

    /*!
        @method previousSibling:
        @abstract Returns the previous sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ open var previousSibling: XMLNode? {
        guard let prev = _CFXMLNodeGetPrevSibling(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(prev)
    }

    /*!
        @method nextSibling:
        @abstract Returns the next sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ open var nextSibling: XMLNode? {
        guard let next = _CFXMLNodeGetNextSibling(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(next)
    }

    /*!
        @method previousNode:
        @abstract Returns the previous node in document order. This can be used to walk the tree backwards.
    */
    /*@NSCopying*/ open var previous: XMLNode? {
        if let previousSibling = self.previousSibling {
            if let lastChild = _CFXMLNodeGetLastChild(previousSibling._xmlNode) {
                return XMLNode._objectNodeForNode(lastChild)
            } else {
                return previousSibling
            }
        } else if let parent = self.parent {
            return parent
        } else {
            return nil
        }
    }

    /*!
        @method nextNode:
        @abstract Returns the next node in document order. This can be used to walk the tree forwards.
    */
    /*@NSCopying*/ open var next: XMLNode? {
        if let children = _CFXMLNodeGetFirstChild(_xmlNode) {
            return XMLNode._objectNodeForNode(children)
        } else if let next = nextSibling {
            return next
        } else if let parent = self.parent {
            return parent.nextSibling
        } else {
            return nil
        }
    }

    /*!
        @method detach:
        @abstract Detaches this node from its parent.
    */
    open func detach() {
        guard let parentPtr = _CFXMLNodeGetParent(_xmlNode) else { return }
        _CFXMLUnlinkNode(_xmlNode)

        guard let parentNodePtr = _CFXMLNodeGetPrivateData(parentPtr) else { return }

        let parent: XMLNode = NSObject.unretainedReference(parentNodePtr)
        parent._childNodes.remove(self)
    }

    /*!
        @method XPath
        @abstract Returns the XPath to this node, for example foo/bar[2]/baz.
    */
    open var xPath: String? {
        guard _CFXMLNodeGetDocument(_xmlNode) != nil else { return nil }

        return _CFXMLCopyPathForNode(_xmlNode)?._swiftObject
    }

    /*!
    	@method localName
    	@abstract Returns the local name bar if this attribute or element's name is foo:bar
    */
    open var localName: String? {
        return _CFXMLNodeCopyLocalName(_xmlNode)?._swiftObject
    }

    /*!
    	@method prefix
    	@abstract Returns the prefix foo if this attribute or element's name if foo:bar
    */
    open var prefix: String? {
        return _CFXMLNodeCopyPrefix(_xmlNode)?._swiftObject
    }

    /*!
    	@method URI
    	@abstract Set the URI of this element, attribute, or document. For documents it is the URI of document origin. Getter returns the URI of this element, attribute, or document. For documents it is the URI of document origin and is automatically set when using initWithContentsOfURL.
    */
    open var uri: String? {
        get {
            return _CFXMLNodeCopyURI(_xmlNode)?._swiftObject
        }
        set {
            if let URI = newValue {
                _CFXMLNodeSetURI(_xmlNode, URI)
            } else {
                _CFXMLNodeSetURI(_xmlNode, nil)
            }
        }
    }

    /*!
        @method localNameForName:
        @abstract Returns the local name bar in foo:bar.
     */
    open class func localName(forName name: String) -> String {
//        return name.withCString {
//            var length: Int32 = 0
//            let result = xmlSplitQName3(UnsafePointer<xmlChar>($0), &length)
//            return String.fromCString(UnsafePointer<CChar>(result)) ?? ""
//        }
        NSUnimplemented()
    }

    /*!
        @method localNameForName:
        @abstract Returns the prefix foo in the name foo:bar.
    */
    open class func prefix(forName name: String) -> String? {
//        return name.withCString {
//            var result: UnsafeMutablePointer<xmlChar> = nil
//            let unused = xmlSplitQName2(UnsafePointer<xmlChar>($0), &result)
//            defer {
//                xmlFree(result)
//                xmlFree(UnsafeMutablePointer<xmlChar>(unused))
//            }
//            return String.fromCString(UnsafePointer<CChar>(result))
//        }
        NSUnimplemented()
    }

    /*!
        @method predefinedNamespaceForPrefix:
        @abstract Returns the namespace belonging to one of the predefined namespaces xml, xs, or xsi
    */
    open class func predefinedNamespace(forPrefix name: String) -> XMLNode? { NSUnimplemented() }

    /*!
        @method description
        @abstract Used for debugging. May give more information than XMLString.
    */
    open override var description: String {
        return xmlString
    }

    /*!
        @method XMLString
        @abstract The representation of this node as it would appear in an XML document.
    */
    open var xmlString: String {
        return xmlString(options: [])
    }

    /*!
        @method XMLStringWithOptions:
        @abstract The representation of this node as it would appear in an XML document, with various output options available.
    */
    open func xmlString(options: Options) -> String {
        return _CFXMLCopyStringWithOptions(_xmlNode, UInt32(options.rawValue))._swiftObject
    }

    /*!
        @method canonicalXMLStringPreservingComments:
        @abstract W3 canonical form (http://www.w3.org/TR/xml-c14n). The input option NSXMLNodePreserveWhitespace should be set for true canonical form.
    */
    open func canonicalXMLStringPreservingComments(_ comments: Bool) -> String { NSUnimplemented() }

    /*!
        @method nodesForXPath:error:
        @abstract Returns the nodes resulting from applying an XPath to this node using the node as the context item ("."). normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
    	@returns An array whose elements are a kind of NSXMLNode.
    */
    open func nodes(forXPath xpath: String) throws -> [XMLNode] {
        guard let nodes = _CFXMLNodesForXPath(_xmlNode, xpath) else {
            NSUnimplemented()
        }

        var result: [XMLNode] = []
        for i in 0..<CFArrayGetCount(nodes) {
            let nodePtr = CFArrayGetValueAtIndex(nodes, i)!
            result.append(XMLNode._objectNodeForNode(_CFXMLNodePtr(mutating: nodePtr)))
        }

        return result
    }

    /*!
        @method objectsForXQuery:constants:error:
        @abstract Returns the objects resulting from applying an XQuery to this node using the node as the context item ("."). Constants are a name-value dictionary for constants declared "external" in the query. normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
    	@returns An array whose elements are kinds of NSArray, NSData, NSDate, NSNumber, NSString, NSURL, or NSXMLNode.
    */
    open func objects(forXQuery xquery: String, constants: [String : Any]?) throws -> [Any] {
        NSUnimplemented()
    }

    open func objects(forXQuery xquery: String) throws -> [Any] {
        NSUnimplemented()
    }

    internal var _childNodes: Set<XMLNode> = []

    deinit {
        for node in _childNodes {
            node.detach()
        }

        switch kind {
        case .document:
            _CFXMLFreeDocument(_CFXMLDocPtr(_xmlNode))

        case .DTDKind:
            _CFXMLFreeDTD(_CFXMLDTDPtr(_xmlNode))

        case .attribute:
            _CFXMLFreeProperty(_xmlNode)

        default:
            _CFXMLFreeNode(_xmlNode)
        }
    }

    internal init(ptr: _CFXMLNodePtr) {
        precondition(_CFXMLNodeGetPrivateData(ptr) == nil, "Only one XMLNode per xmlNodePtr allowed")

        _xmlNode = ptr
        super.init()

        if let parent = _CFXMLNodeGetParent(_xmlNode) {
            let parentNode = XMLNode._objectNodeForNode(parent)
            parentNode._childNodes.insert(self)
        }

        withUnretainedReference {
            _CFXMLNodeSetPrivateData(_xmlNode, $0)
        }
    }

    internal class func _objectNodeForNode(_ node: _CFXMLNodePtr) -> XMLNode {
        switch _CFXMLNodeGetType(node) {
        case _kCFXMLTypeElement:
            return XMLElement._objectNodeForNode(node)

        case _kCFXMLTypeDocument:
            return XMLDocument._objectNodeForNode(node)

        case _kCFXMLTypeDTD:
            return XMLDTD._objectNodeForNode(node)

        case _kCFXMLDTDNodeTypeEntity:
            fallthrough
        case _kCFXMLDTDNodeTypeElement:
            fallthrough
        case _kCFXMLDTDNodeTypeNotation:
            fallthrough
        case _kCFXMLDTDNodeTypeAttribute:
            return XMLDTDNode._objectNodeForNode(node)

        default:
            if let _private = _CFXMLNodeGetPrivateData(node) {
                return XMLNode.unretainedReference(_private)
            }

            return XMLNode(ptr: node)
        }
    }

    // libxml2 believes any node can have children, though XMLNode disagrees.
    // Nevertheless, this belongs here so that XMLElement and XMLDocument can share
    // the same implementation.
    internal func _insertChild(_ child: XMLNode, atIndex index: Int) {
        precondition(index >= 0)
        precondition(index <= childCount)
        precondition(child.parent == nil)

        _childNodes.insert(child)

        if index == 0 {
            let first = _CFXMLNodeGetFirstChild(_xmlNode)!
            _CFXMLNodeAddPrevSibling(first, child._xmlNode)
        } else {
            let currChild = self.child(at: index - 1)!._xmlNode
            _CFXMLNodeAddNextSibling(currChild, child._xmlNode)
        }
    }

    // see above
    internal func _insertChildren(_ children: [XMLNode], atIndex index: Int) {
        for (childIndex, node) in children.enumerated() {
            _insertChild(node, atIndex: index + childIndex)
        }
    }

    /*!
     @method removeChildAtIndex:atIndex:
     @abstract Removes a child at a particular index.
     */
    // See above!
    internal func _removeChildAtIndex(_ index: Int) {
        guard let child = child(at: index) else {
            fatalError("index out of bounds")
        }

        _childNodes.remove(child)
        _CFXMLUnlinkNode(child._xmlNode)
    }

    // see above
    internal func _setChildren(_ children: [XMLNode]?) {
        _removeAllChildren()
        guard let children = children else {
            return
        }

        for child in children {
            _addChild(child)
        }
    }

    /*!
     @method addChild:
     @abstract Adds a child to the end of the existing children.
     */
    // see above
    internal func _addChild(_ child: XMLNode) {
        precondition(child.parent == nil)

        _CFXMLNodeAddChild(_xmlNode, child._xmlNode)
        _childNodes.insert(child)
    }

    /*!
     @method replaceChildAtIndex:withNode:
     @abstract Replaces a child at a particular index with another child.
     */
    // see above
    internal func _replaceChildAtIndex(_ index: Int, withNode node: XMLNode) {
        let child = self.child(at: index)!
        _childNodes.remove(child)
        _CFXMLNodeReplaceNode(child._xmlNode, node._xmlNode)
        _childNodes.insert(node)
    }
}

internal protocol _NSXMLNodeCollectionType: Collection { }

extension XMLNode: _NSXMLNodeCollectionType {

    public struct Index: Comparable {
        fileprivate let node: _CFXMLNodePtr?
        fileprivate let offset: Int?
    }

    public subscript(index: Index) -> XMLNode {
        return XMLNode._objectNodeForNode(index.node!)
    }

    public var startIndex: Index {
        let node = _CFXMLNodeGetFirstChild(_xmlNode)
        return Index(node: node, offset: node.map { _ in 0 })
    }

    public var endIndex: Index {
        return Index(node: nil, offset: nil)
    }

    public func index(after i: Index) -> Index {
        precondition(i.node != nil, "can't increment endIndex")
        let nextNode = _CFXMLNodeGetNextSibling(i.node!)
        return Index(node: nextNode, offset: nextNode.map { _ in i.offset! + 1 } )
    }
}

extension XMLNode.Index {
    public static func ==(lhs: XMLNode.Index, rhs: XMLNode.Index) -> Bool {
        return lhs.offset == rhs.offset
    }

    public static func <(lhs: XMLNode.Index, rhs: XMLNode.Index) -> Bool {
        switch (lhs.offset, rhs.offset) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (let lhsOffset?, let rhsOffset?):
            return lhsOffset < rhsOffset
        }
    }
}
