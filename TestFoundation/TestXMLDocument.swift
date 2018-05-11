// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestXMLDocument : LoopbackServerTest {

    static var allTests: [(String, (TestXMLDocument) -> () throws -> Void)] {
        return [
            ("test_basicCreation", test_basicCreation),
            ("test_nextPreviousNode", test_nextPreviousNode),
            ("test_xpath", test_xpath),
            ("test_elementCreation", test_elementCreation),
            ("test_elementChildren", test_elementChildren),
            ("test_stringValue", test_stringValue),
            ("test_objectValue", test_objectValue),
            ("test_attributes", test_attributes),
            ("test_comments", test_comments),
            ("test_processingInstruction", test_processingInstruction),
            ("test_parseXMLString", test_parseXMLString),
            ("test_prefixes", test_prefixes),
            ("test_validation_success", test_validation_success),
            ("test_validation_failure", test_validation_failure),
            ("test_dtd", test_dtd),
            ("test_documentWithDTD", test_documentWithDTD),
            ("test_dtd_attributes", test_dtd_attributes),
            ("test_documentWithEncodingSetDoesntCrash", test_documentWithEncodingSetDoesntCrash),
            ("test_nodeFindingWithNamespaces", test_nodeFindingWithNamespaces),
            ("test_createElement", test_createElement),
            ("test_addNamespace", test_addNamespace),
            ("test_removeNamespace", test_removeNamespace),
            ("test_optionPreserveAll", test_optionPreserveAll),
        ]
    }

    func test_basicCreation() {
        let doc = XMLDocument(rootElement: nil)
        XCTAssert(doc.version == "1.0", "expected 1.0, got \(String(describing: doc.version))")
        doc.version = "1.1"
        XCTAssert(doc.version == "1.1", "expected 1.1, got \(String(describing: doc.version))")
        let node = XMLElement(name: "Hello", uri: "http://www.example.com")

        doc.setRootElement(node)

        let element = doc.rootElement()!
        XCTAssert(element === node)
    }
    
    func test_createElement() throws {
        let element = try XMLElement(xmlString: "<D:propfind xmlns:D=\"DAV:\"><D:prop></D:prop></D:propfind>")
        XCTAssert(element.name! == "D:propfind")
        XCTAssert(element.rootDocument == nil)
        if let namespace = element.namespaces?.first {
            XCTAssert(namespace.prefix == "D")
            XCTAssert(namespace.stringValue == "DAV:")
        } else {
            XCTFail("Namespace was not parsed correctly")
        }
        
        if let child = element.elements(forName: "D:prop").first {
            XCTAssert(child.localName == "prop")
            XCTAssert(child.prefix == "D")
            XCTAssert(child.name == "D:prop")
        } else {
            XCTFail("Child element was not parsed correctly!")
        }
    }

    func test_nextPreviousNode() {
        let doc = XMLDocument(rootElement: nil)
        let node = XMLElement(name: "Hello", uri: "http://www.example.com")

        let fooNode = XMLElement(name: "Foo")
        let barNode = XMLElement(name: "Bar")
        let bazNode = XMLElement(name: "Baz")

        doc.setRootElement(node)
        node.addChild(fooNode)
        fooNode.addChild(bazNode)
        node.addChild(barNode)

        XCTAssert(doc.next === node)
        XCTAssert(doc.next?.next === fooNode)
        XCTAssert(doc.next?.next?.next === bazNode)
        XCTAssert(doc.next?.next?.next?.next === barNode)

        XCTAssert(barNode.previous === bazNode)
        XCTAssert(barNode.previous?.previous === fooNode)
        XCTAssert(barNode.previous?.previous?.previous === node)
        XCTAssert(barNode.previous?.previous?.previous?.previous === doc)
    }

    func test_xpath() throws {
        let doc = XMLDocument(rootElement: nil)
        let foo = XMLElement(name: "foo")
        let bar1 = XMLElement(name: "bar")
        let bar2 = XMLElement(name: "bar")
        let bar3 = XMLElement(name: "bar")
        let baz = XMLElement(name: "baz")

        doc.setRootElement(foo)
        foo.addChild(bar1)
        foo.addChild(bar2)
        foo.addChild(bar3)
        bar2.addChild(baz)
        
        XCTAssertEqual(baz.xPath, "/foo/bar[2]/baz")
        
        let baz2 = XMLElement(name: "/baz")
        bar2.addChild(baz2)

        XCTAssertEqual(baz.xPath, "/foo/bar[2]/baz")
        XCTAssertEqual(try! doc.nodes(forXPath:baz.xPath!).first, baz)

        let nodes = try! doc.nodes(forXPath:"/foo/bar")
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0], bar1)
        XCTAssertEqual(nodes[1], bar2)
        XCTAssertEqual(nodes[2], bar3)

        let emptyResults = try! doc.nodes(forXPath: "/items/item/name[@type='alternate']/@value")
        XCTAssertEqual(emptyResults.count, 0)

        let xmlString = """
        <?xml version="1.0" encoding="utf-8" standalone="yes"?>
            <D:propfind xmlns:D="DAV:">
                <D:prop>
                    <D:getlastmodified></D:getlastmodified>
                    <D:getcontentlength></D:getcontentlength>
                    <D:creationdate></D:creationdate>
                    <D:resourcetype></D:resourcetype>
                </D:prop>
            </D:propfind>
        """
        
        let namespaceDoc = try XMLDocument(xmlString: xmlString, options: [])
        let propNodes = try namespaceDoc.nodes(forXPath: "//D:prop")
        if let propNode = propNodes.first {
            XCTAssert(propNode.name == "D:prop")
        } else {
            XCTAssert(false, "propNode should have existed, but was nil")            
        }
    }

    func test_elementCreation() {
        let element = XMLElement(name: "test", stringValue: "This is my value")
        XCTAssertEqual(element.xmlString, "<test>This is my value</test>")
        XCTAssertEqual(element.children?.count, 1)
    }

    func test_elementChildren() {
        let element = XMLElement(name: "root")
        let foo = XMLElement(name: "foo")
        let bar = XMLElement(name: "bar")
        let bar2 = bar.copy() as! XMLElement

        element.addChild(foo)
        element.addChild(bar)
        element.addChild(bar2)

        XCTAssertEqual(element.elements(forName:"bar"), [bar, bar2])
        XCTAssertFalse(element.elements(forName:"foo").contains(bar))
        XCTAssertFalse(element.elements(forName:"foo").contains(bar2))
        
        let baz = XMLElement(name: "baz")
        element.insertChild(baz, at: 2)
        XCTAssertEqual(element.children?[2], baz)

        foo.detach()
        bar.detach()

        element.insertChildren([foo, bar], at: 1)
        XCTAssertEqual(element.children?[1], foo)
        XCTAssertEqual(element.children?[2], bar)
        XCTAssertEqual(element.children?[0], baz)

        let faz = XMLElement(name: "faz")
        element.replaceChild(at: 2, with: faz)
        XCTAssertEqual(element.children?[2], faz)

        for node in [foo, bar, baz, bar2, faz] {
            node.detach()
        }
        XCTAssert(element.children?.count == 0)

        element.setChildren([foo, bar, baz, bar2, faz])
        XCTAssert(element.children?.count == 5)
    }

    func test_stringValue() {
        let element = XMLElement(name: "root")
        let foo = XMLElement(name: "foo")
        element.addChild(foo)

        element.stringValue = "Hello!<evil/>"
        XCTAssertEqual(element.xmlString, "<root>Hello!&lt;evil/&gt;</root>")
        XCTAssertEqual(element.stringValue, "Hello!<evil/>", element.stringValue ?? "stringValue unexpectedly nil")

        element.stringValue = nil

        //        let doc = XMLDocument(rootElement: element)
        //        xmlCreateIntSubset(xmlDocPtr(doc._xmlNode), "test.dtd", nil, nil)
        //        xmlAddDocEntity(xmlDocPtr(doc._xmlNode), "author", Int32(XML_INTERNAL_GENERAL_ENTITY.rawValue), nil, nil, "Robert Thompson")
        //        let author = XMLElement(name: "author")
        //        doc.rootElement()?.addChild(author)
        //        author.setStringValue("&author;", resolvingEntities: true)
        //        XCTAssertEqual(author.stringValue, "Robert Thompson", author.stringValue ?? "")
    }


    func test_objectValue() {
        let element = XMLElement(name: "root")
        let dict: [String: String] = ["hello": "world"]
        element.objectValue = dict
        
        /// - Todo: verify this behavior
        // id to Any conversion changed descriptions so this now is "<root>[\"hello\": \"world\"]</root>"
        // XCTAssertEqual(element.xmlString, "<root>{\n    hello = world;\n}</root>", element.xmlString)
    }

    func test_attributes() {
        let element = XMLElement(name: "root")
        let attribute = XMLNode.attribute(withName: "color", stringValue: "#ff00ff") as! XMLNode
        element.addAttribute(attribute)
        XCTAssertEqual(element.xmlString, "<root color=\"#ff00ff\"></root>", element.xmlString)
        element.removeAttribute(forName:"color")
        XCTAssertEqual(element.xmlString, "<root></root>", element.xmlString)

        element.addAttribute(attribute)

        let otherAttribute = XMLNode.attribute(withName: "foo", stringValue: "bar") as! XMLNode
        element.addAttribute(otherAttribute)

        guard let attributes = element.attributes else {
            XCTFail()
            return
        }

        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(attributes.first, attribute)
        XCTAssertEqual(attributes.last, otherAttribute)

        let barAttribute = XMLNode.attribute(withName: "bar", stringValue: "buz") as! XMLNode
        let bazAttribute = XMLNode.attribute(withName: "baz", stringValue: "fiz") as! XMLNode

        element.attributes = [barAttribute, bazAttribute]

        XCTAssertEqual(element.attributes?.count, 2)
        XCTAssertEqual(element.attributes?.first, barAttribute)
        XCTAssertEqual(element.attributes?.last, bazAttribute)

        element.setAttributesWith(["hello": "world", "foobar": "buzbaz"])
        XCTAssertEqual(element.attribute(forName:"hello")?.stringValue, "world", "\(element.attribute(forName:"hello")?.stringValue as Optional)")
        XCTAssertEqual(element.attribute(forName:"foobar")?.stringValue, "buzbaz", "\(element.attributes ?? [])")
    }

    func test_comments() {
        let element = XMLElement(name: "root")
        let comment = XMLNode.comment(withStringValue:"Here is a comment") as! XMLNode
        element.addChild(comment)
        XCTAssertEqual(element.xmlString, "<root><!--Here is a comment--></root>")
    }

    func test_processingInstruction() {
        let document = XMLDocument(rootElement: XMLElement(name: "root"))
        let pi = XMLNode.processingInstruction(withName:"xml-stylesheet", stringValue: "type=\"text/css\" href=\"style.css\"") as! XMLNode

        document.addChild(pi)

        XCTAssertEqual(pi.xmlString, "<?xml-stylesheet type=\"text/css\" href=\"style.css\"?>")
    }

    func test_parseXMLString() throws {
        let string = "<?xml version=\"1.0\" encoding=\"utf-8\"?><!DOCTYPE test.dtd [\n        <!ENTITY author \"Robert Thompson\">\n        ]><root><author>&author;</author></root>"

        let doc = try XMLDocument(xmlString: string, options: [.nodeLoadExternalEntitiesNever])
        XCTAssert(doc.childCount == 1)
        XCTAssertEqual(doc.rootElement()?.children?[0].stringValue, "Robert Thompson")

        guard let testDataURL = testBundle().url(forResource: "NSXMLDocumentTestData", withExtension: "xml") else {
            XCTFail("Could not find XML test data")
            return
        }

        let newDoc = try XMLDocument(contentsOf: testDataURL, options: [])
        XCTAssertEqual(newDoc.rootElement()?.name, "root")
        let root = newDoc.rootElement()!
        let children = root.children!
        XCTAssertEqual(children[0].stringValue, "Hello world", children[0].stringValue!)
        XCTAssertEqual(children[1].children?[0].stringValue, "I'm here", (children[1].children?[0].stringValue)!)

        doc.insertChild(XMLElement(name: "body"), at: 1)
        XCTAssertEqual(doc.children?[1].name, "body")
        XCTAssertEqual(doc.children?[2].name, "root", (doc.children?[2].name)!)
    }

    func test_prefixes() {
        let element = XMLElement(name: "xml:root")
        XCTAssertEqual(element.prefix, "xml")
        XCTAssertEqual(element.localName, "root")
    }
    
    func test_addNamespace() {
        let doc = XMLDocument(rootElement: XMLElement(name: "Foo"))
        let ns = XMLNode.namespace(withName: "F", stringValue: "http://example.com/fakenamespace") as! XMLNode
        doc.rootElement()?.addNamespace(ns)
        XCTAssert((doc.rootElement()?.namespaces ?? []).map({ $0.stringValue ?? "foo" }).contains(ns.stringValue ?? "bar"), "namespaces didn't include the added namespace!")
        XCTAssert(doc.rootElement()?.uri == "http://example.com/fakenamespace", "uri was \(doc.rootElement()?.uri ?? "null") instead of http://example.com/fakenamespace")
        
        let otherNS = XMLNode.namespace(withName: "R", stringValue: "http://example.com/rnamespace") as! XMLNode
        doc.rootElement()?.addNamespace(otherNS)
        XCTAssert((doc.rootElement()?.namespaces ?? []).map({ $0.stringValue ?? "foo" }).contains(ns.stringValue ?? "bar"), "lost original namespace")
        XCTAssert((doc.rootElement()?.namespaces ?? []).map({ $0.stringValue ?? "foo" }).contains(otherNS.stringValue ?? "bar"), "Lost new namespace")
        doc.rootElement()?.addNamespace(XMLNode.namespace(withName: "R", stringValue: "http://example.com/rnamespace") as! XMLNode)
        XCTAssert(doc.rootElement()?.namespaces?.count == 2, "incorrectly added a namespace with duplicate name!")
        
        let otherDoc = XMLDocument(rootElement: XMLElement(name: "Bar"))
        otherDoc.rootElement()?.namespaces = [XMLNode.namespace(withName: "R", stringValue: "http://example.com/rnamespace") as! XMLNode, XMLNode.namespace(withName: "F", stringValue: "http://example.com/fakenamespace") as! XMLNode]
        XCTAssert(otherDoc.rootElement()?.namespaces?.count == 2)
        let namespaces: [XMLNode]? = otherDoc.rootElement()?.namespaces
        let names: [String]? = namespaces?.compactMap { $0.name }
        XCTAssertNotNil(names)
        XCTAssert(names![0] == "R" && names![1] == "F")
        otherDoc.rootElement()?.namespaces = nil
        XCTAssert((otherDoc.rootElement()?.namespaces?.count ?? 0) == 0)
    }
    
    func test_removeNamespace() {
        let doc = XMLDocument(rootElement: XMLElement(name: "Foo"))
        let ns = XMLNode.namespace(withName: "F", stringValue: "http://example.com/fakenamespace") as! XMLNode
        let otherNS = XMLNode.namespace(withName: "R", stringValue: "http://example.com/rnamespace") as! XMLNode
        
        doc.rootElement()?.addNamespace(ns)
        doc.rootElement()?.addNamespace(otherNS)
        XCTAssert(doc.rootElement()?.namespaces?.count == 2)
        
        doc.rootElement()?.removeNamespace(forPrefix: "F")
        
        XCTAssert(doc.rootElement()?.namespaces?.count == 1)
        XCTAssert(doc.rootElement()?.namespaces?.first?.name == "R")
    }

    func test_validation_success() throws {
        let validString = "<?xml version=\"1.0\" standalone=\"yes\"?><!DOCTYPE foo [ <!ELEMENT foo (#PCDATA)> ]><foo>Hello world</foo>"
        do {
            let doc = try XMLDocument(xmlString: validString, options: [])
            try doc.validate()
        } catch {
            XCTFail("\(error)")
        }

        let dtdUrl = "http://127.0.0.1:\(TestURLSession.serverPort)/DTDs/PropertyList-1.0.dtd"
        let plistDocString = "<?xml version='1.0' encoding='utf-8'?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"\(dtdUrl)\"> <plist version='1.0'><dict><key>MyKey</key><string>Hello!</string></dict></plist>"
        let plistDoc = try XMLDocument(xmlString: plistDocString, options: [])
        do {
            try plistDoc.validate()
            XCTAssert(plistDoc.rootElement()?.name == "plist")
            let plist = try PropertyListSerialization.propertyList(from: plistDoc.xmlData, options: [], format: nil) as! [String: Any]
            XCTAssert((plist["MyKey"] as? String) == "Hello!")
        } catch let nsError as NSError {
            XCTFail("\(nsError.userInfo)")
        }
    }

    func test_validation_failure() throws {
        let xmlString = "<?xml version=\"1.0\" standalone=\"yes\"?><!DOCTYPE foo [ <!ELEMENT img EMPTY> ]><foo><img>not empty</img></foo>"
        do {
            let doc = try XMLDocument(xmlString: xmlString, options: [])
            try doc.validate()
            XCTFail("Should have thrown")
        } catch let nsError as NSError {
            XCTAssert(nsError.code == XMLParser.ErrorCode.internalError.rawValue)
            XCTAssert(nsError.domain == XMLParser.errorDomain)
            XCTAssert((nsError.userInfo[NSLocalizedDescriptionKey] as! String).contains("Element img was declared EMPTY this one has content"))
        }

        let dtdUrl = "http://127.0.0.1:\(TestURLSession.serverPort)/DTDs/PropertyList-1.0.dtd"
        let plistDocString = "<?xml version='1.0' encoding='utf-8'?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"\(dtdUrl)\"> <plist version='1.0'><dict><key>MyKey</key><string>Hello!</string><key>MyBooleanThing</key><true>foobar</true></dict></plist>"
        let plistDoc = try XMLDocument(xmlString: plistDocString, options: [])
        do {
            try plistDoc.validate()
            XCTFail("Should have thrown!")
        } catch let error as NSError {
            XCTAssert((error.userInfo[NSLocalizedDescriptionKey] as! String).contains("Element true was declared EMPTY this one has content"))
        }
    }

    func test_dtd() throws {
        let node = XMLNode.dtdNode(withXMLString:"<!ELEMENT foo (#PCDATA)>") as! XMLDTDNode
        XCTAssert(node.name == "foo")
        
        let dtd = try XMLDTD(contentsOf: testBundle().url(forResource: "PropertyList-1.0", withExtension: "dtd")!, options: [])
        //        dtd.systemID = testBundle().URLForResource("PropertyList-1.0", withExtension: "dtd")?.absoluteString
        dtd.name = "plist"
        //        dtd.publicID = "-//Apple//DTD PLIST 1.0//EN"
        let plistNode = dtd.elementDeclaration(forName:"plist")
        XCTAssert(plistNode?.name == "plist")
        let plistObjectNode = dtd.entityDeclaration(forName:"plistObject")
        XCTAssert(plistObjectNode?.name == "plistObject")
        XCTAssert(plistObjectNode?.stringValue == "(array | data | date | dict | real | integer | string | true | false )")
        let plistAttribute = dtd.attributeDeclaration(forName:"version", elementName: "plist")
        XCTAssert(plistAttribute?.name == "version")

        let doc = try XMLDocument(xmlString: "<?xml version='1.0' encoding='utf-8'?><plist version='1.0'><dict><key>hello</key><string>world</string></dict></plist>", options: [])
        doc.dtd = dtd
        do {
            try doc.validate()
        } catch let error as NSError {
            XCTFail("\(error.userInfo)")
        }

        let amp = XMLDTD.predefinedEntityDeclaration(forName:"amp")
        XCTAssert(amp?.name == "amp", amp?.name ?? "")
        XCTAssert(amp?.stringValue == "&", amp?.stringValue ?? "")
        if let entityNode = XMLNode.dtdNode(withXMLString:"<!ENTITY author 'Robert Thompson'>") as? XMLDTDNode {
            XCTAssert(entityNode.name == "author")
            XCTAssert(entityNode.stringValue == "Robert Thompson")
        }

        let elementDecl = XMLDTDNode(kind: .elementDeclaration)
        elementDecl.name = "MyElement"
        elementDecl.stringValue = "(#PCDATA | array)*"
        XCTAssert(elementDecl.stringValue == "(#PCDATA | array)*", elementDecl.stringValue ?? "nil string value")
        XCTAssert(elementDecl.name == "MyElement")
    }

    func test_documentWithDTD() throws {
        let doc = try XMLDocument(contentsOf: testBundle().url(forResource: "NSXMLDTDTestData", withExtension: "xml")!, options: [])
        let dtd = doc.dtd
        XCTAssert(dtd?.name == "root")
        
        let notation = dtd?.notationDeclaration(forName:"myNotation")
        notation?.detach()
        XCTAssert(notation?.name == "myNotation")
        XCTAssert(notation?.systemID == "http://www.example.com", notation?.systemID ?? "nil system id!")

        do {
            try doc.validate()
        } catch {
            XCTFail("\(error)")
        }

        let root = dtd?.elementDeclaration(forName:"root")
        root?.stringValue = "(#PCDATA)"
        do {
            try doc.validate()
            XCTFail("should have thrown")
        } catch let error as NSError {
            XCTAssert(error.code == XMLParser.ErrorCode.internalError.rawValue)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func test_dtd_attributes() throws {
        let doc = try XMLDocument(contentsOf: testBundle().url(forResource: "NSXMLDTDTestData", withExtension: "xml")!, options: [])
        let dtd = doc.dtd!
        let attrDecl = dtd.attributeDeclaration(forName: "print", elementName: "foo")!
        XCTAssert(attrDecl.dtdKind == .enumerationAttribute)
    }

    func test_documentWithEncodingSetDoesntCrash() throws {
        weak var weakDoc: XMLDocument? = nil
        func makeSureDocumentIsAllocatedAndFreed() {
                let doc = XMLDocument(rootElement: XMLElement(name: "test"))
                doc.characterEncoding = "UTF-8"
                weakDoc = doc
        }
        makeSureDocumentIsAllocatedAndFreed()
        XCTAssertNil(weakDoc, "document not freed even through it should have")
    }
    
    func test_nodeFindingWithNamespaces() throws {
        let xmlString = """
        <?xml version="1.0" encoding="utf-8" standalone="yes"?>
            <D:propfind xmlns:D="DAV:">
                <D:prop>
                    <D:getlastmodified></D:getlastmodified>
                    <D:getcontentlength></D:getcontentlength>
                    <D:creationdate></D:creationdate>
                    <D:resourcetype></D:resourcetype>
                </D:prop>
            </D:propfind>
        """
        
        let doc = try XMLDocument(xmlString: xmlString, options: [])
        let namespace = (doc.rootElement()?.namespaces?.first)!
        XCTAssert(namespace.kind == .namespace, "The node was not a namespace but was a \(namespace.kind)")
        XCTAssert(namespace.stringValue == "DAV:", "expected a string value of DAV: got \(namespace.stringValue as Any)")
        XCTAssert(namespace.name == "D", "expected a name of D, got \(namespace.name as Any)")
        
        let newNS = XMLNode.namespace(withName: "R", stringValue: "http://apple.com") as! XMLNode
        XCTAssert(newNS.name == "R", "expected name R, got name \(newNS.name as Any)")
        XCTAssert(newNS.stringValue == "http://apple.com", "expected stringValue http://apple.com, got stringValue \(newNS.stringValue as Any)")
        newNS.stringValue = "FOO:"
        XCTAssert(newNS.stringValue == "FOO:")
        newNS.name = "F"
        XCTAssert(newNS.name == "F")
        
        let root = doc.rootElement()!
        XCTAssert(root.localName == "propfind")
        XCTAssert(root.name == "D:propfind")
        XCTAssert(root.prefix == "D")
        let node = doc.findFirstChild(named: "prop")
        XCTAssert(node != nil, "failed to find existing node")
        XCTAssert(node?.localName == "prop")
        
        XCTAssert(doc.rootElement()?.elements(forLocalName: "prop", uri: "DAV:").first?.name == "D:prop", "failed to get elements, got \(doc.rootElement()?.elements(forLocalName: "prop", uri: "DAV:").first as Any)")
    }

    func test_optionPreserveAll() {
        let xmlString = """
<?xml version="1.0" encoding="UTF-8"?>
<document>
</document>
"""

        let data = xmlString.data(using: .utf8)!
        guard let document = try? XMLDocument(data: data, options: .nodePreserveAll) else {
            XCTFail("XMLDocument with options .nodePreserveAll")
            return
        }
        let expected = xmlString.lowercased() + "\n"
        XCTAssertEqual(expected, String(describing: document))
    }
}

fileprivate extension XMLNode {
    fileprivate func findFirstChild(named name: String) -> XMLNode? {
        guard let children = self.children else {
            return nil
        }
        
        for child in children {
            if let childName = child.localName {
                if childName == name {
                    return child
                }
            }
            
            if let result = child.findFirstChild(named: name) {
                return result
            }
        }
        
        return nil
    }
}


