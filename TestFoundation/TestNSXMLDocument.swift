// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    @testable import SwiftFoundation
    import SwiftXCTest
#endif

import libxml2


class TestNSXMLDocument : XCTestCase {

    var allTests: [(String, () -> Void)] {
        return [
            ("test_basicCreation", test_basicCreation),
            ("test_xpath", test_xpath),
            ("test_elementCreation", test_elementCreation),
            ("test_elementChildren", test_elementChildren),
            ("test_stringValue", test_stringValue),
            ("test_objectValue", test_objectValue),
            ("test_attributes", test_attributes),
            ("test_comments", test_comments),
            ("test_processingInstruction", test_processingInstruction),
            ("test_parseXMLString", test_parseXMLString)
        ]
    }

    func test_basicCreation() {
        let doc = NSXMLDocument(rootElement: nil)
        XCTAssert(doc.version == "1.0", "expected 1.0, got \(doc.version)")
        doc.version = "1.1"
        XCTAssert(doc.version == "1.1", "expected 1.1, got \(doc.version)")
        let node = NSXMLElement(name: "Hello", URI: "http://www.example.com")

        let fooNode = NSXMLElement(name: "Foo")
        let barNode = NSXMLElement(name: "msxml:Bar")
        let bazNode = NSXMLElement(name: "Baz")

        doc.setRootElement(node)

        let element = doc.rootElement()!
        element.addChild(fooNode)
        fooNode.addChild(bazNode)
        element.addChild(barNode)
//        doc.setRootElement(element)

        print("RootDocument:\n\(element.rootDocument?.description ?? "")")

        print(doc.rootElement()?.name ?? "")

        print(doc.nextNode)
        print(doc.nextNode?.nextNode)
        print(doc.nextNode?.nextNode?.nextNode)
        print(doc.nextNode?.nextNode?.nextNode?.nextNode)
        print(doc.nextNode?.nextNode?.nextNode?.nextNode?.nextNode)

        print(barNode)
        print(barNode.previousNode)
        print(barNode.previousNode?.previousNode)
        print(barNode.previousNode?.previousNode?.previousNode)
        print(barNode.previousNode?.previousNode?.previousNode?.previousNode)

        print(barNode.prefix)
        print(fooNode.prefix)
    }

    func test_xpath() {
        let doc = NSXMLDocument(rootElement: nil)
        let foo = NSXMLElement(name: "foo")
        let bar1 = NSXMLElement(name: "bar")
        let bar2 = NSXMLElement(name: "bar")
        let bar3 = NSXMLElement(name: "bar")
        let baz = NSXMLElement(name: "baz")

        doc.setRootElement(foo)
        foo.addChild(bar1)
        foo.addChild(bar2)
        foo.addChild(bar3)
        bar2.addChild(baz)

        XCTAssertEqual(baz.XPath, "foo/bar[2]/baz")

        let baz2 = NSXMLElement(name: "baz")
        bar2.addChild(baz2)

        XCTAssertEqual(baz.XPath, "foo/bar[2]/baz[1]")
        XCTAssertEqual(try! doc.nodesForXPath(baz.XPath!).first, baz)

        let nodes = try! doc.nodesForXPath("foo/bar")
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0], bar1)
        XCTAssertEqual(nodes[1], bar2)
        XCTAssertEqual(nodes[2], bar3)
    }

    func test_elementCreation() {
        let element = NSXMLElement(name: "test", stringValue: "This is my value")
        XCTAssertEqual(element.XMLString, "<test>This is my value</test>")
        XCTAssertEqual(element.children?.count, 1)
    }

    func test_elementChildren() {
        let element = NSXMLElement(name: "root")
        let foo = NSXMLElement(name: "foo")
        let bar = NSXMLElement(name: "bar")
        let bar2 = bar.copy() as! NSXMLElement

        element.addChild(foo)
        element.addChild(bar)
        element.addChild(bar2)

        XCTAssertEqual(element.elementsForName("bar"), [bar, bar2])
        XCTAssertFalse(element.elementsForName("foo").contains(bar))
        XCTAssertFalse(element.elementsForName("foo").contains(bar2))

        let baz = NSXMLElement(name: "baz")
        element.insertChild(baz, atIndex: 2)
        XCTAssertEqual(element.children?[2], baz)

        foo.detach()
        bar.detach()

        element.insertChildren([foo, bar], atIndex: 1)
        XCTAssertEqual(element.children?[1], foo)
        XCTAssertEqual(element.children?[2], bar)
        XCTAssertEqual(element.children?[0], baz, "\(element.children?[0])")

        let faz = NSXMLElement(name: "faz")
        element.replaceChildAtIndex(2, withNode: faz)
        XCTAssertEqual(element.children?[2], faz)

        for node in [foo, bar, baz, bar2, faz] {
            node.detach()
        }
        XCTAssert(element.children?.count == 0)

        element.setChildren([foo, bar, baz, bar2, faz])
        XCTAssert(element.children?.count == 5)
    }

    func test_stringValue() {
        let element = NSXMLElement(name: "root")
        let foo = NSXMLElement(name: "foo")
        element.addChild(foo)

        element.stringValue = "Hello!<evil/>"
        XCTAssertEqual(element.XMLString, "<root>Hello!&lt;evil/&gt;</root>")
        XCTAssertEqual(element.stringValue, "Hello!<evil/>", element.stringValue ?? "stringValue unexpectedly nil")

	/*
        element.stringValue = nil

        let doc = NSXMLDocument(rootElement: element)
        xmlCreateIntSubset(xmlDocPtr(doc._xmlNode), "test.dtd", nil, nil)
        xmlAddDocEntity(xmlDocPtr(doc._xmlNode), "author", Int32(XML_INTERNAL_GENERAL_ENTITY.rawValue), nil, nil, "Robert Thompson")
        let author = NSXMLElement(name: "author")
        doc.rootElement()?.addChild(author)
        author.setStringValue("&author;&03A3;", resolvingEntities: true)
        print(doc)
	*/
    }

    func test_objectValue() {
        let element = NSXMLElement(name: "root")
        let dict: [String: AnyObject] = ["hello": "world"._bridgeToObject()]
        element.objectValue = dict._bridgeToObject()

        //XCTAssertEqual(element.XMLString, "<root>{\n    hello = world;\n}</root>", element.XMLString)
    }

    func test_attributes() {
        let element = NSXMLElement(name: "root")
        let attribute = NSXMLNode.attributeWithName("color", stringValue: "#ff00ff") as! NSXMLNode
        element.addAttribute(attribute)
        XCTAssertEqual(element.XMLString, "<root color=\"#ff00ff\"></root>", element.XMLString)
        element.removeAttributeForName("color")
        XCTAssertEqual(element.XMLString, "<root></root>", element.XMLString)

        element.addAttribute(attribute)

        let otherAttribute = NSXMLNode.attributeWithName("foo", stringValue: "bar") as! NSXMLNode
        element.addAttribute(otherAttribute)

        guard let attributes = element.attributes else {
            XCTFail()
            return
        }

        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(attributes.first, attribute)
        XCTAssertEqual(attributes.last, otherAttribute)

        let barAttribute = NSXMLNode.attributeWithName("bar", stringValue: "buz") as! NSXMLNode
        let bazAttribute = NSXMLNode.attributeWithName("baz", stringValue: "fiz") as! NSXMLNode

        element.attributes = [barAttribute, bazAttribute]

        XCTAssertEqual(element.attributes?.count, 2)
        XCTAssertEqual(element.attributes?.first, barAttribute)
        XCTAssertEqual(element.attributes?.last, bazAttribute)

        element.setAttributesWithDictionary(["hello": "world", "foobar": "buzbaz"])
        XCTAssertEqual(element.attributeForName("hello")?.stringValue, "world", "\(element.attributeForName("hello")?.stringValue)")
        XCTAssertEqual(element.attributeForName("foobar")?.stringValue, "buzbaz", "\(element.attributes ?? [])")
    }

    func test_comments() {
        let element = NSXMLElement(name: "root")
        let comment = NSXMLNode.commentWithStringValue("Here is a comment") as! NSXMLNode
        element.addChild(comment)
        XCTAssertEqual(element.XMLString, "<root><!--Here is a comment--></root>")
    }

    func test_processingInstruction() {
        let document = NSXMLDocument(rootElement: NSXMLElement(name: "root"))
        let pi = NSXMLNode.processingInstructionWithName("xml-stylesheet", stringValue: "type=\"text/css\" href=\"style.css\"") as! NSXMLNode

        document.addChild(pi)

        XCTAssertEqual(pi.XMLString, "<?xml-stylesheet type=\"text/css\" href=\"style.css\"?>")
    }

    func test_parseXMLString() {
        let string = "<?xml version=\"1.0\" encoding=\"utf-8\"?><!DOCTYPE test.dtd [\n        <!ENTITY author \"Robert Thompson\">\n        ]><root><author>&author;</author></root>"
        do {
            let doc = try NSXMLDocument(XMLString: string, options: NSXMLNodeLoadExternalEntitiesNever)
            XCTAssert(doc.childCount == 1)
            XCTAssertEqual(doc.rootElement()?.children?[0].stringValue, "Robert Thompson")

            // NSURLSession is still unimplemented
            //let newDoc = try NSXMLDocument(contentsOfURL: NSURL(string:"https://mandelbrotsetapp.com")!, options: 0)

            let newDoc = try NSXMLDocument(contentsOfURL: NSBundle.mainBundle().URLForResource("NSXMLDocumentTestData", withExtension: "xml")!, options: 0)
            XCTAssertEqual(newDoc.rootElement()?.name, "root")
            let root = newDoc.rootElement()!
            let children = root.children!
            XCTAssertEqual(children[0].stringValue, "Hello world", children[0].stringValue!)
            XCTAssertEqual(children[1].children?[0].stringValue, "I'm here", (children[1].children?[0].stringValue)!)

            doc.insertChild(NSXMLElement(name: "body"), atIndex: 1)
            XCTAssertEqual(doc.children?[1].name, "body")
            XCTAssertEqual(doc.children?[2].name, "root", (doc.children?[2].name)!)
        } catch {
            XCTFail("\(error)")
        }
    }
}
