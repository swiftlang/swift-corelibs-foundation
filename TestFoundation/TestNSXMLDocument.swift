// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

import CoreFoundation

class TestNSXMLDocument : XCTestCase {

    static var allTests: [(String, (TestNSXMLDocument) -> () throws -> Void)] {
        #if os(OSX) || os(iOS)
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
                ("test_dtd_attributes", test_dtd_attributes)
            ]
        #else // On Linux, currently the tests that rely on NSError are segfaulting in swift_dynamicCast
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
                //                ("test_validation_failure", test_validation_failure),
                ("test_dtd", test_dtd),
                //                ("test_documentWithDTD", test_documentWithDTD),
                ("test_dtd_attributes", test_dtd_attributes)
            ]
        #endif
    }

    func test_basicCreation() {
        let doc = XMLDocument(rootElement: nil)
        XCTAssert(doc.version == "1.0", "expected 1.0, got \(doc.version)")
        doc.version = "1.1"
        XCTAssert(doc.version == "1.1", "expected 1.1, got \(doc.version)")
        let node = XMLElement(name: "Hello", uri: "http://www.example.com")

        doc.setRootElement(node)

        let element = doc.rootElement()!
        XCTAssert(element === node)
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

        XCTAssert(doc.nextNode === node)
        XCTAssert(doc.nextNode?.nextNode === fooNode)
        XCTAssert(doc.nextNode?.nextNode?.nextNode === bazNode)
        XCTAssert(doc.nextNode?.nextNode?.nextNode?.nextNode === barNode)

        XCTAssert(barNode.previousNode === bazNode)
        XCTAssert(barNode.previousNode?.previousNode === fooNode)
        XCTAssert(barNode.previousNode?.previousNode?.previousNode === node)
        XCTAssert(barNode.previousNode?.previousNode?.previousNode?.previousNode === doc)
    }

    func test_xpath() {
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

        XCTAssertEqual(baz.xPath, "foo/bar[2]/baz")

        let baz2 = XMLElement(name: "baz")
        bar2.addChild(baz2)

        XCTAssertEqual(baz.xPath, "foo/bar[2]/baz[1]")
        XCTAssertEqual(try! doc.nodes(forXPath:baz.xPath!).first, baz)

        let nodes = try! doc.nodes(forXPath:"foo/bar")
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0], bar1)
        XCTAssertEqual(nodes[1], bar2)
        XCTAssertEqual(nodes[2], bar3)
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

        //        let doc = NSXMLDocument(rootElement: element)
        //        xmlCreateIntSubset(xmlDocPtr(doc._xmlNode), "test.dtd", nil, nil)
        //        xmlAddDocEntity(xmlDocPtr(doc._xmlNode), "author", Int32(XML_INTERNAL_GENERAL_ENTITY.rawValue), nil, nil, "Robert Thompson")
        //        let author = NSXMLElement(name: "author")
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

    func test_validation_success() throws {
        let validString = "<?xml version=\"1.0\" standalone=\"yes\"?><!DOCTYPE foo [ <!ELEMENT foo (#PCDATA)> ]><foo>Hello world</foo>"
        do {
            let doc = try XMLDocument(xmlString: validString, options: [])
            try doc.validate()
        } catch {
            XCTFail("\(error)")
        }

        let plistDocString = "<?xml version='1.0' encoding='utf-8'?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> <plist version='1.0'><dict><key>MyKey</key><string>Hello!</string></dict></plist>"
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

        let plistDocString = "<?xml version='1.0' encoding='utf-8'?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> <plist version='1.0'><dict><key>MyKey</key><string>Hello!</string><key>MyBooleanThing</key><true>foobar</true></dict></plist>"
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
}
