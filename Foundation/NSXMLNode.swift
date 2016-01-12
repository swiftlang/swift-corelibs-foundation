// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

//import libxml2
import CoreFoundation
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

    internal let _xmlNode: _CFXMLNodePtr

    public func copyWithZone(zone: NSZone) -> AnyObject {
        let newNode = _CFXMLCopyNode(_xmlNode, true)
        return NSXMLNode._objectNodeForNode(newNode)
    }

    /*!
        @method initWithKind:
        @abstract Invokes @link initWithKind:options: @/link with options set to NSXMLNodeOptionsNone
    */
    public convenience init(kind: NSXMLNodeKind) {
        self.init(kind: kind, options: NSXMLNodeOptionsNone)
    }

    /*!
        @method initWithKind:options:
        @abstract Inits a node with fidelity options as description NSXMLNodeOptions.h
    */
    public init(kind: NSXMLNodeKind, options: Int) {

        switch kind {
        case .DocumentKind:
            let docPtr = _CFXMLNewDoc("1.0")
            _CFXMLDocSetStandalone(docPtr, false) // same default as on Darwin
            _xmlNode = _CFXMLNodePtr(docPtr)

        case .ElementKind:
            _xmlNode = _CFXMLNewNode(nil, "")

        case .AttributeKind:
            _xmlNode = _CFXMLNodePtr(_CFXMLNewProperty(nil, "", ""))

        case .DTDKind:
            _xmlNode = _CFXMLNewDTD(nil, "", "", "")
            
        default:
            _xmlNode = nil
        }

        super.init()

        let unmanaged = Unmanaged<NSXMLNode>.passUnretained(self)
        let ptr = UnsafeMutablePointer<Void>(unmanaged.toOpaque())

        _CFXMLNodeSetPrivateData(_xmlNode, ptr)
    }

    /*!
        @method document:
        @abstract Returns an empty document.
    */
    public class func document() -> AnyObject {
        return NSXMLDocument(rootElement: nil)
    }

    /*!
        @method documentWithRootElement:
        @abstract Returns a document
        @param element The document's root node.
    */
    public class func documentWithRootElement(element: NSXMLElement) -> AnyObject {
        return NSXMLDocument(rootElement: element)
    }

    /*!
        @method elementWithName:
        @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
    */
    public class func elementWithName(name: String) -> AnyObject {
        return NSXMLElement(name: name)
    }

    /*!
        @method elementWithName:URI:
        @abstract Returns an element whose full QName is specified.
    */
    public class func elementWithName(name: String, URI: String) -> AnyObject {
        return NSXMLElement(name: name, URI: URI)
    }

    /*!
        @method elementWithName:stringValue:
        @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
    */
    public class func elementWithName(name: String, stringValue string: String) -> AnyObject {
        return NSXMLElement(name: name, stringValue: string)
    }

    /*!
        @method elementWithName:children:attributes:
        @abstract Returns an element children and attributes <tt>&lt;name attr1="foo" attr2="bar">&lt;-- child1 -->child2&lt;/name></tt>.
    */
    public class func elementWithName(name: String, children: [NSXMLNode]?, attributes: [NSXMLNode]?) -> AnyObject {
        let element = NSXMLElement(name: name)
        element.setChildren(children)
        element.attributes = attributes

        return element
    }

    /*!
        @method attributeWithName:stringValue:
        @abstract Returns an attribute <tt>name="stringValue"</tt>.
    */
    public class func attributeWithName(name: String, stringValue: String) -> AnyObject {
        let attribute = _CFXMLNewProperty(nil, name, stringValue)

        return NSXMLNode(ptr: attribute)
    }

    /*!
        @method attributeWithLocalName:URI:stringValue:
        @abstract Returns an attribute whose full QName is specified.
    */
    public class func attributeWithName(name: String, URI: String, stringValue: String) -> AnyObject {
        let attribute = NSXMLNode.attributeWithName(name, stringValue: stringValue) as! NSXMLNode
//        attribute.URI = URI

        return attribute
    }

    /*!
        @method namespaceWithName:stringValue:
        @abstract Returns a namespace <tt>xmlns:name="stringValue"</tt>.
    */
    public class func namespaceWithName(name: String, stringValue: String) -> AnyObject { NSUnimplemented() }

    /*!
        @method processingInstructionWithName:stringValue:
        @abstract Returns a processing instruction <tt>&lt;?name stringValue></tt>.
    */
    public class func processingInstructionWithName(name: String, stringValue: String) -> AnyObject {
        let node = _CFXMLNewProcessingInstruction(name, stringValue)
        return NSXMLNode(ptr: node)
    }

    /*!
        @method commentWithStringValue:
        @abstract Returns a comment <tt>&lt;--stringValue--></tt>.
    */
    public class func commentWithStringValue(stringValue: String) -> AnyObject {
        let node = _CFXMLNewComment(stringValue)
        return NSXMLNode(ptr: node)
    }

    /*!
        @method textWithStringValue:
        @abstract Returns a text node.
    */
    public class func textWithStringValue(stringValue: String) -> AnyObject {
        let node = _CFXMLNewTextNode(stringValue)
        return NSXMLNode(ptr: node)
    }

    /*!
        @method DTDNodeWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public class func DTDNodeWithXMLString(string: String) -> AnyObject? {
        let node = _CFXMLParseDTDNode(string)
        if node == nil {
            return nil
        }

        return NSXMLDTDNode(ptr: node)
    }

    /*!
        @method kind
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public var kind: NSXMLNodeKind  {
        guard _xmlNode != nil else { return .InvalidKind }
        switch _CFXMLNodeGetType(_xmlNode) {
        case _kCFXMLTypeElement:
            return .ElementKind

        case _kCFXMLTypeAttribute:
            return .AttributeKind

        case _kCFXMLTypeDocument:
            return .DocumentKind

        case _kCFXMLTypeDTD:
            return .DTDKind

        case _kCFXMLDTDNodeTypeElement:
            return .ElementDeclarationKind

        case _kCFXMLDTDNodeTypeEntity:
            return .EntityDeclarationKind

        case _kCFXMLDTDNodeTypeNotation:
            return .NotationDeclarationKind

        case _kCFXMLDTDNodeTypeAttribute:
            return .AttributeDeclarationKind

        default:
            return .InvalidKind
        }
    } //primitive

    /*!
        @method name
        @abstract Sets the nodes name. Applicable for element, attribute, namespace, processing-instruction, document type declaration, element declaration, attribute declaration, entity declaration, and notation declaration.
    */
    public var name: String? {
        get {
            return String.fromCString(_CFXMLNodeGetName(_xmlNode))
        }
        set {
            if let newName = newValue {
                _CFXMLNodeSetName(_xmlNode, newName)
            } else {
                _CFXMLNodeSetName(_xmlNode, "")
            }
        }
    }

    private var _objectValue: AnyObject? = nil

    /*!
        @method objectValue
        @abstract Sets the content of the node. Setting the objectValue removes all existing children including processing instructions and comments. Setting the object value on an element creates a single text node child.
    */
    public var objectValue: AnyObject? {
        get {
            if let value = _objectValue {
                return value
            } else {
                return stringValue?._bridgeToObject()
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
    }//primitive

    /*!
        @method stringValue:
        @abstract Sets the content of the node. Setting the stringValue removes all existing children including processing instructions and comments. Setting the string value on an element creates a single text node child. The getter returns the string value of the node, which may be either its content or child text nodes, depending on the type of node. Elements are recursed and text nodes concatenated in document order with no intervening spaces.
    */
    public var stringValue: String? {
        get {
            switch kind {
            case .EntityDeclarationKind:
                return _CFXMLGetEntityContent(_CFXMLEntityPtr(_xmlNode))?._swiftObject

            default:
                return _CFXMLNodeGetContent(_xmlNode)?._swiftObject
            }
        }
        set {
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
            if node.kind != NSXMLNodeKind.AttributeKind {
                _CFXMLUnlinkNode(node._xmlNode)
                _childNodes.remove(node)
            }
        }
    }

    internal func _removeAllChildren() {
        var child = _CFXMLNodeGetFirstChild(_xmlNode)
        while child != nil {
            _CFXMLUnlinkNode(child)
            child = _CFXMLNodeGetNextSibling(child)
        }
        _childNodes.removeAll(keepCapacity: true)
    }

    /*!
        @method setStringValue:resolvingEntities:
        @abstract Sets the content as with @link setStringValue: @/link, but when "resolve" is true, character references, predefined entities and user entities available in the document's dtd are resolved. Entities not available in the dtd remain in their entity form.
    */
    public func setStringValue(string: String, resolvingEntities resolve: Bool) {
        guard resolve else {
            stringValue = string
            return
        }

        _removeAllChildNodesExceptAttributes()

        var entities: [(Range<Int>, String)] = []
        var entityChars: [Character] = []
        var inEntity = false
        var startIndex = 0
        for (index, char) in string.characters.enumerate() {
            if char == "&" {
                inEntity = true
                startIndex = index
                continue
            }
            if char == ";" && inEntity {
                inEntity = false
                entities.append((Range<Int>(start: startIndex, end: index + 1),String(entityChars)))
                startIndex = 0
                entityChars.removeAll()
            }
            if inEntity {
                entityChars.append(char)
            }
        }

        var result: [Character] = Array(string.characters)
        let doc = _CFXMLNodeGetDocument(_xmlNode)
        for (range, entity) in entities {
            var entityPtr = _CFXMLGetDocEntity(doc, entity)
            if entityPtr == nil {
                entityPtr = _CFXMLGetDTDEntity(doc, entity)
            }
            if entityPtr == nil {
                entityPtr = _CFXMLGetParameterEntity(doc, entity)
            }
            if entityPtr != nil {
                let replacement = _CFXMLGetEntityContent(entityPtr)?._swiftObject ?? ""
                result.replaceRange(range, with: replacement.characters)
            } else {
                result.replaceRange(range, with: []) // This appears to be how Darwin Foundation does it
            }
        }
        stringValue = String(result)
    } //primitive

    /*!
        @method index
        @abstract A node's index amongst its siblings.
    */
    public var index: Int {
        if let siblings = self.parent?.children,
            let index = siblings.indexOf(self) {
            return index
        }

        return 0
    } //primitive

    /*!
        @method level
        @abstract The depth of the node within the tree. Documents and standalone nodes are level 0.
    */
    public var level: Int {
        var result = 0
        var parent = _CFXMLNodeGetParent(_xmlNode)
        while parent != nil {
            result += 1
            parent = _CFXMLNodeGetParent(parent)
        }

        return result
    }

    /*!
        @method rootDocument
        @abstract The encompassing document or nil.
    */
    public var rootDocument: NSXMLDocument? {
        let doc = _CFXMLNodeGetDocument(_xmlNode)
        guard doc != nil else { return nil }

        return NSXMLNode._objectNodeForNode(_CFXMLNodePtr(doc)) as? NSXMLDocument
    }

    /*!
        @method parent
        @abstract The parent of this node. Documents and standalone Nodes have a nil parent; there is not a 1-to-1 relationship between parent and children, eg a namespace cannot be a child but has a parent element.
    */
    /*@NSCopying*/ public var parent: NSXMLNode? {
        let parentPtr = _CFXMLNodeGetParent(_xmlNode)
        guard parentPtr != nil else { return nil }

        return NSXMLNode._objectNodeForNode(parentPtr)
    } //primitive

    /*!
        @method childCount
        @abstract The amount of children, relevant for documents, elements, and document type declarations. Use this instead of [[self children] count].
    */
    public var childCount: Int {
        return _CFXMLNodeGetElementChildCount(_xmlNode)
    } //primitive

    /*!
        @method children
        @abstract An immutable array of child nodes. Relevant for documents, elements, and document type declarations.
    */
    public var children: [NSXMLNode]? {
        switch kind {
        case .DocumentKind:
            fallthrough
        case .ElementKind:
            fallthrough
        case .DTDKind:
            return Array<NSXMLNode>(self as NSXMLNode)

        default:
            return nil
        }
    } //primitive

    /*!
        @method childAtIndex:
        @abstract Returns the child node at a particular index.
    */
    public func childAtIndex(index: Int) -> NSXMLNode? {
        precondition(index >= 0)
        precondition(index < childCount)

        var nodeIndex = startIndex
        for _ in 0..<index {
            nodeIndex = nodeIndex.successor()
        }

        return self[nodeIndex]
    } //primitive

    /*!
        @method previousSibling:
        @abstract Returns the previous sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ public var previousSibling: NSXMLNode? {
        let prev = _CFXMLNodeGetPrevSibling(_xmlNode)
        guard prev != nil else { return nil }

        return NSXMLNode._objectNodeForNode(prev)
    }

    /*!
        @method nextSibling:
        @abstract Returns the next sibling, or nil if there isn't one.
    */
    /*@NSCopying*/ public var nextSibling: NSXMLNode? {
        let next = _CFXMLNodeGetNextSibling(_xmlNode)
        guard next != nil else { return nil }

        return NSXMLNode._objectNodeForNode(next)
    }

    /*!
        @method previousNode:
        @abstract Returns the previous node in document order. This can be used to walk the tree backwards.
    */
    /*@NSCopying*/ public var previousNode: NSXMLNode? {
        if let previousSibling = self.previousSibling {
            if _CFXMLNodeGetLastChild(previousSibling._xmlNode) != nil {
                return NSXMLNode._objectNodeForNode(_CFXMLNodeGetLastChild(previousSibling._xmlNode))
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
    /*@NSCopying*/ public var nextNode: NSXMLNode? {
        let children = _CFXMLNodeGetFirstChild(_xmlNode)
        if children != nil {
            return NSXMLNode._objectNodeForNode(children)
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
    public func detach() {
        let parentPtr = _CFXMLNodeGetParent(_xmlNode)
        guard parentPtr != nil else { return }
        _CFXMLUnlinkNode(_xmlNode)

        let parentNodePtr = _CFXMLNodeGetPrivateData(parentPtr)
        guard parentNodePtr != nil else { return }
        let parent = Unmanaged<NSXMLNode>.fromOpaque(parentNodePtr).takeUnretainedValue()
        parent._childNodes.remove(self)
    } //primitive

    /*!
        @method XPath
        @abstract Returns the XPath to this node, for example foo/bar[2]/baz.
    */
    public var XPath: String? {
        guard _CFXMLNodeGetDocument(_xmlNode) != nil else { return nil }

        var pathComponents: [String?] = []
        var parent  = _CFXMLNodeGetParent(_xmlNode)
        if parent != nil {
            let parentObj = NSXMLNode._objectNodeForNode(parent)
            let siblingsWithSameName = parentObj.filter { $0.name == self.name }

            if siblingsWithSameName.count > 1 {
                guard let index = siblingsWithSameName.indexOf(self) else { return nil }

                pathComponents.append("\(self.name ?? "")[\(index + 1)]")
            } else {
                pathComponents.append(self.name)
            }
        } else {
            return self.name
        }
        while true {
            if _CFXMLNodeGetParent(parent) != nil {
                let grandparent = NSXMLNode._objectNodeForNode(_CFXMLNodeGetParent(parent))
                let possibleParentNodes = grandparent.filter { $0.name == self.parent?.name }
                let count = possibleParentNodes.reduce(0) {
                    return $0.0 + 1
                }

                if count <= 1 {
                    pathComponents.append(NSXMLNode._objectNodeForNode(parent).name)
                } else {
                    var parentNumber = 1
                    for possibleParent in possibleParentNodes {
                        if possibleParent == self.parent {
                            break
                        }
                        parentNumber += 1
                    }

                    pathComponents.append("\(self.parent?.name ?? "")[\(parentNumber)]")
                }

                parent = _CFXMLNodeGetParent(parent)

            } else {
                pathComponents.append(NSXMLNode._objectNodeForNode(parent).name)
                break
            }
        }

        return pathComponents.reverse().flatMap({ return $0 }).joinWithSeparator("/")
    }

    /*!
    	@method localName
    	@abstract Returns the local name bar if this attribute or element's name is foo:bar
    */
    public var localName: String? {
        return _CFXMLNodeLocalName(_xmlNode)?._swiftObject
    } //primitive

    /*!
    	@method prefix
    	@abstract Returns the prefix foo if this attribute or element's name if foo:bar
    */
    public var prefix: String? {
        return _CFXMLNodePrefix(_xmlNode)?._swiftObject
    } //primitive

    /*!
    	@method URI
    	@abstract Set the URI of this element, attribute, or document. For documents it is the URI of document origin. Getter returns the URI of this element, attribute, or document. For documents it is the URI of document origin and is automatically set when using initWithContentsOfURL.
    */
    public var URI: String? { //primitive
        get {
            return _CFXMLNodeURI(_xmlNode)?._swiftObject
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
    public class func localNameForName(name: String) -> String {
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
    public class func prefixForName(name: String) -> String? {
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
    public class func predefinedNamespaceForPrefix(name: String) -> NSXMLNode? { NSUnimplemented() }

    /*!
        @method description
        @abstract Used for debugging. May give more information than XMLString.
    */
    public override var description: String {
        return XMLString
    }

    /*!
        @method XMLString
        @abstract The representation of this node as it would appear in an XML document.
    */
    public var XMLString: String {
        return XMLStringWithOptions(NSXMLNodeOptionsNone)
    }

    /*!
        @method XMLStringWithOptions:
        @abstract The representation of this node as it would appear in an XML document, with various output options available.
    */
    public func XMLStringWithOptions(options: Int) -> String {
        return _CFXMLStringWithOptions(_xmlNode, UInt32(options))._swiftObject
    }

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
    public func nodesForXPath(xpath: String) throws -> [NSXMLNode] {
        guard let nodes = _CFXMLNodesForXPath(_xmlNode, xpath) else {
            NSUnimplemented();
        }

        var result: [NSXMLNode] = []
        for i in 0..<CFArrayGetCount(nodes) {
            let nodePtr = CFArrayGetValueAtIndex(nodes, i)
            result.append(NSXMLNode._objectNodeForNode(_CFXMLNodePtr(nodePtr)))
        }

        return result
    }

    /*!
        @method objectsForXQuery:constants:error:
        @abstract Returns the objects resulting from applying an XQuery to this node using the node as the context item ("."). Constants are a name-value dictionary for constants declared "external" in the query. normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
    	@returns An array whose elements are kinds of NSArray, NSData, NSDate, NSNumber, NSString, NSURL, or NSXMLNode.
    */
    public func objectsForXQuery(xquery: String, constants: [String : AnyObject]?) throws -> [AnyObject] { NSUnimplemented() }

    public func objectsForXQuery(xquery: String) throws -> [AnyObject] { NSUnimplemented() }

    internal var _childNodes: Set<NSXMLNode> = []

    deinit {
        for node in _childNodes {
            node.detach()
        }

        switch kind {
        case .DocumentKind:
            _CFXMLFreeDocument(_CFXMLDocPtr(_xmlNode))

        case .DTDKind:
            _CFXMLFreeDTD(_CFXMLDTDPtr(_xmlNode))

        case .AttributeKind:
            _CFXMLFreeProperty(_xmlNode)
            
        default:
            _CFXMLFreeNode(_xmlNode)
        }
    }

    internal init(ptr: _CFXMLNodePtr) {
        precondition(ptr != nil)
        precondition(_CFXMLNodeGetPrivateData(ptr) == nil, "Only one NSXMLNode per xmlNodePtr allowed")

        _xmlNode = ptr
        super.init()

        let parent = _CFXMLNodeGetParent(_xmlNode)
        if parent != nil {
            let parentNode = NSXMLNode._objectNodeForNode(parent)
            parentNode._childNodes.insert(self)
        }

        let unmanaged = Unmanaged<NSXMLNode>.passUnretained(self)
        _CFXMLNodeSetPrivateData(_xmlNode, UnsafeMutablePointer<Void>(unmanaged.toOpaque()))
    }

    internal class func _objectNodeForNode(node: _CFXMLNodePtr) -> NSXMLNode {
        switch _CFXMLNodeGetType(node) {
        case _kCFXMLTypeElement:
            return NSXMLElement._objectNodeForNode(node)

        case _kCFXMLTypeDocument:
            return NSXMLDocument._objectNodeForNode(node)

        case _kCFXMLTypeDTD:
            return NSXMLDTD._objectNodeForNode(node)

        case _kCFXMLDTDNodeTypeEntity:
            fallthrough
        case _kCFXMLDTDNodeTypeElement:
            fallthrough
        case _kCFXMLDTDNodeTypeNotation:
            fallthrough
        case _kCFXMLDTDNodeTypeAttribute:
            return NSXMLDTDNode._objectNodeForNode(node)

        default:
            let _private = _CFXMLNodeGetPrivateData(node)
            if _private != nil {
                let unmanaged = Unmanaged<NSXMLNode>.fromOpaque(_private)
                return unmanaged.takeUnretainedValue()
            }

            return NSXMLNode(ptr: node)
        }
    }

    // libxml2 believes any node can have children, though NSXMLNode disagrees.
    // Nevertheless, this belongs here so that NSXMLElement and NSXMLDocument can share
    // the same implementation.
    internal func _insertChild(child: NSXMLNode, atIndex index: Int) {
        precondition(index >= 0)
        precondition(index <= childCount)
        precondition(child.parent == nil)

        _childNodes.insert(child)

        if index == 0 {
            let first = _CFXMLNodeGetFirstChild(_xmlNode)
            _CFXMLNodeAddPrevSibling(first, child._xmlNode)
        } else {
            let currChild = childAtIndex(index - 1)!._xmlNode
            _CFXMLNodeAddNextSibling(currChild, child._xmlNode)
        }
    } //primitive

    // see above
    internal func _insertChildren(children: [NSXMLNode], atIndex index: Int) {
        for (childIndex, node) in children.enumerate() {
            _insertChild(node, atIndex: index + childIndex)
        }
    }

    /*!
     @method removeChildAtIndex:atIndex:
     @abstract Removes a child at a particular index.
     */
    // See above!
    internal func _removeChildAtIndex(index: Int) {
        guard let child = childAtIndex(index) else {
            fatalError("index out of bounds")
        }

        _childNodes.remove(child)
        _CFXMLUnlinkNode(child._xmlNode)
    } //primitive

    // see above
    internal func _setChildren(children: [NSXMLNode]?) {
        _removeAllChildren()
        guard let children = children else {
            return
        }

        for child in children {
            _addChild(child)
        }
    } //primitive

    /*!
     @method addChild:
     @abstract Adds a child to the end of the existing children.
     */
    // see above
    internal func _addChild(child: NSXMLNode) {
        precondition(child.parent == nil)

        _CFXMLNodeAddChild(_xmlNode, child._xmlNode)
        _childNodes.insert(child)
    }

    /*!
     @method replaceChildAtIndex:withNode:
     @abstract Replaces a child at a particular index with another child.
     */
    // see above
    internal func _replaceChildAtIndex(index: Int, withNode node: NSXMLNode) {
        let child = childAtIndex(index)!
        _childNodes.remove(child)
        _CFXMLNodeReplaceNode(child._xmlNode, node._xmlNode)
        _childNodes.insert(node)
    }
}

internal protocol _NSXMLNodeCollectionType: CollectionType { }

extension NSXMLNode: _NSXMLNodeCollectionType {
    public struct Index: BidirectionalIndexType {
        private let node: _CFXMLNodePtr

        public func predecessor() -> Index {
            guard node != nil else { return self }
            return Index(node: _CFXMLNodeGetPrevSibling(node))
        }

        public func successor() -> Index {
            guard node != nil else { return self }
            return Index(node: _CFXMLNodeGetNextSibling(node))
        }
    }

    public subscript(index: Index) -> NSXMLNode {
        return NSXMLNode._objectNodeForNode(index.node)
    }

    public var startIndex: Index {
        return Index(node: _CFXMLNodeGetFirstChild(_xmlNode))
    }

    public var endIndex: Index {
        return Index(node: nil)
    }
}

public func ==(lhs: NSXMLNode.Index, rhs: NSXMLNode.Index) -> Bool {
    return lhs.node == rhs.node
}
