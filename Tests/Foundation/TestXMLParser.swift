// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

enum XMLParserDelegateEvent {
    case startDocument
    case endDocument
    case didStartElement(String, String?, String?, [String: String])
    case didEndElement(String, String?, String?)
    case foundCharacters(String)
}

extension XMLParserDelegateEvent: Equatable {

    public static func ==(lhs: XMLParserDelegateEvent, rhs: XMLParserDelegateEvent) -> Bool {
        switch (lhs, rhs) {
        case (.startDocument, startDocument):
            return true
        case (.endDocument, endDocument):
            return true
        case let (.didStartElement(lhsElement, lhsNamespace, lhsQname, lhsAttr),
                  didStartElement(rhsElement, rhsNamespace, rhsQname, rhsAttr)):
            return lhsElement == rhsElement && lhsNamespace == rhsNamespace && lhsQname == rhsQname && lhsAttr == rhsAttr
        case let (.didEndElement(lhsElement, lhsNamespace, lhsQname),
                  .didEndElement(rhsElement, rhsNamespace, rhsQname)):
            return lhsElement == rhsElement && lhsNamespace == rhsNamespace && lhsQname == rhsQname
        case let (.foundCharacters(lhsChar), .foundCharacters(rhsChar)):
            return lhsChar == rhsChar
        default:
            return false
        }
    }

}

class XMLParserDelegateEventStream: NSObject, XMLParserDelegate {
    var events: [XMLParserDelegateEvent] = []

    func parserDidStartDocument(_ parser: XMLParser) {
        events.append(.startDocument)
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        events.append(.endDocument)
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        events.append(.didStartElement(elementName, namespaceURI, qName, attributeDict))
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        events.append(.didEndElement(elementName, namespaceURI, qName))
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        events.append(.foundCharacters(string))
    }
}

class TestXMLParser : XCTestCase {

    // Helper method to embed the correct encoding in the XML header
    static func xmlUnderTest(encoding: String.Encoding? = nil) -> String {
        let xmlUnderTest = "<test attribute='value'><foo>bar</foo></test>"
        guard var encoding = encoding?.description else {
            return xmlUnderTest
        }
        if let open = encoding.range(of: "(") {
            let range: Range<String.Index> = open.upperBound..<encoding.endIndex
            encoding = String(encoding[range])
        }
        if let close = encoding.range(of: ")") {
            encoding = String(encoding[..<close.lowerBound])
        }
        return "<?xml version='1.0' encoding='\(encoding.uppercased())' standalone='no'?>\n\(xmlUnderTest)\n"
    }

    static func xmlUnderTestExpectedEvents(namespaces: Bool = false) -> [XMLParserDelegateEvent] {
        let uri: String? = namespaces ? "" : nil
        return [
            .startDocument,
            .didStartElement("test", uri, namespaces ? "test" : nil, ["attribute": "value"]),
            .didStartElement("foo", uri, namespaces ? "foo" : nil, [:]),
            .foundCharacters("bar"),
            .didEndElement("foo", uri, namespaces ? "foo" : nil),
            .didEndElement("test", uri, namespaces ? "test" : nil),
            .endDocument,
        ]
    }


    func test_withData() {
        let xml = Array(TestXMLParser.xmlUnderTest().utf8CString)
        let data = xml.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<CChar>) -> Data in
            return buffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: buffer.count * MemoryLayout<CChar>.stride) {
                return Data(bytes: $0, count: buffer.count)
            }
        }
        let parser = XMLParser(data: data)
        let stream = XMLParserDelegateEventStream()
        parser.delegate = stream
        let res = parser.parse()
        XCTAssertEqual(stream.events, TestXMLParser.xmlUnderTestExpectedEvents())
        XCTAssertTrue(res)
    }

    func test_withDataEncodings() {
        // If th <?xml header isn't present, any non-UTF8 encodings fail. This appears to be libxml2 behavior.
        // These don't work, it may just be an issue with the `encoding=xxx`.
        //   - .nextstep, .utf32LittleEndian
        var encodings: [String.Encoding] = [.utf16LittleEndian, .utf16BigEndian,  .utf8]
#if !os(Windows)
        // libxml requires iconv support for UTF32
        encodings.append(.utf32BigEndian)
#endif
        for encoding in encodings {
            let xml = TestXMLParser.xmlUnderTest(encoding: encoding)
            let parser = XMLParser(data: xml.data(using: encoding)!)
            let stream = XMLParserDelegateEventStream()
            parser.delegate = stream
            let res = parser.parse()
            XCTAssertEqual(stream.events, TestXMLParser.xmlUnderTestExpectedEvents())
            XCTAssertTrue(res)
        }
    }

    func test_withDataOptions() {
        let xml = TestXMLParser.xmlUnderTest()
        let parser = XMLParser(data: xml.data(using: .utf8)!)
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = true
        let stream = XMLParserDelegateEventStream()
        parser.delegate = stream
        let res = parser.parse()
        XCTAssertEqual(stream.events, TestXMLParser.xmlUnderTestExpectedEvents(namespaces: true)  )
        XCTAssertTrue(res)
    }

    func test_entityDeclarationsWithoutExternalReporting() {
        checkEntityDeclarations(shouldResolveExternalEntities: false)
    }

    func test_entityDeclarationsWithExternalReporting() {
        checkEntityDeclarations(shouldResolveExternalEntities: true)
    }

    func test_entityDeclarationWithInvalidUTF8Name() {
        class Delegate: NSObject, XMLParserDelegate {
            var declarations: [String] = []

            func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
                declarations.append(name)
            }
        }

        // Older libxml2 recovery can report an entity name containing invalid UTF-8.
        var document = Data("<!DOCTYPE root [<!ENTITY a".utf8)
        document.append(0xFF)
        document.append(contentsOf: " 'value'>]><root/>".utf8)
        let parser = XMLParser(data: document)
        let delegate = Delegate()
        parser.delegate = delegate

        XCTAssertFalse(parser.parse())
        XCTAssertEqual((parser.parserError as? NSError)?.domain, XMLParser.errorDomain)
        XCTAssertTrue(delegate.declarations.isEmpty)
    }

    private func checkEntityDeclarations(shouldResolveExternalEntities: Bool) {
        enum Declaration: Equatable {
            case internalEntity(String, String?)
            case externalEntity(String, String?, String?)
            case notation(String, String?, String?)
            case unparsedEntity(String, String?, String?, String?)
        }

        class Delegate: NSObject, XMLParserDelegate {
            var declarations: [Declaration] = []
            var resolutionCalls = 0

            func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
                declarations.append(.internalEntity(name, value))
            }
            func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
                declarations.append(.externalEntity(name, publicID, systemID))
            }
            func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
                declarations.append(.notation(name, publicID, systemID))
            }
            func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) {
                declarations.append(.unparsedEntity(name, publicID, systemID, notationName))
            }
            func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
                resolutionCalls += 1
                return nil
            }
        }

        let xml = """
        <!DOCTYPE root [
          <!ENTITY literal 'Literal value'>
          <!ENTITY system SYSTEM 'entity-system.xml'>
          <!ENTITY public PUBLIC '-//FoundationXML//Entity Test//EN' 'entity-public.xml'>
          <!ENTITY % internalPE 'value'>
          <!ENTITY % externalPE SYSTEM 'parameter.dtd'>
          <!ENTITY % publicPE PUBLIC '-//FoundationXML//Parameter Test//EN' 'public-parameter.dtd'>
          <!NOTATION image PUBLIC '-//FoundationXML//Notation Test//EN' 'image-format'>
          <!ENTITY unparsed PUBLIC '-//FoundationXML//Unparsed Test//EN' 'image.bin' NDATA image>
        ]><root/>
        """
        let parser = XMLParser(data: Data(xml.utf8))
        let delegate = Delegate()
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = shouldResolveExternalEntities
        parser.externalEntityResolvingPolicy = .never
        XCTAssertTrue(parser.parse())
        XCTAssertNil(parser.parserError)

        var expected: [Declaration] = [.internalEntity("literal", "Literal value")]
        if shouldResolveExternalEntities {
            expected += [
                .externalEntity("system", nil, "entity-system.xml"),
                .externalEntity("public", "-//FoundationXML//Entity Test//EN", "entity-public.xml"),
            ]
        }
        expected.append(.internalEntity("internalPE", "value"))
        if shouldResolveExternalEntities {
            expected += [
                .externalEntity("externalPE", nil, "parameter.dtd"),
                .externalEntity("publicPE", "-//FoundationXML//Parameter Test//EN", "public-parameter.dtd"),
            ]
        }
        expected += [
            .notation("image", "-//FoundationXML//Notation Test//EN", "image-format"),
            .unparsedEntity("unparsed", "-//FoundationXML//Unparsed Test//EN", "image.bin", "image"),
        ]
        XCTAssertEqual(delegate.declarations, expected)
        XCTAssertEqual(delegate.resolutionCalls, 0)
    }

    func test_sr9758_abortParsing() {
        class Delegate: NSObject, XMLParserDelegate {
            func parserDidStartDocument(_ parser: XMLParser) { parser.abortParsing() }
        }
        let xml = TestXMLParser.xmlUnderTest(encoding: .utf8)
        let parser = XMLParser(data: xml.data(using: .utf8)!)
        let delegate = Delegate()
        defer {
            // XMLParser holds a weak reference to delegate. Keep it alive.
            _fixLifetime(delegate)
        }
        parser.delegate = delegate
        XCTAssertFalse(parser.parse())
        XCTAssertNotNil(parser.parserError)
    }

    func test_sr10157_swappedElementNames() {
        class ElementNameChecker: NSObject, XMLParserDelegate {
            let name: String
            init(_ name: String) { self.name = name }
            func parser(_ parser: XMLParser,
                        didStartElement elementName: String,
                        namespaceURI: String?,
                        qualifiedName qName: String?,
                        attributes attributeDict: [String: String] = [:])
            {
                if parser.shouldProcessNamespaces {
                    XCTAssertEqual(self.name, qName)
                } else {
                    XCTAssertEqual(self.name, elementName)
                }
            }
            func parser(_ parser: XMLParser,
                        didEndElement elementName: String,
                        namespaceURI: String?,
                        qualifiedName qName: String?)
            {
                if parser.shouldProcessNamespaces {
                    XCTAssertEqual(self.name, qName)
                } else {
                    XCTAssertEqual(self.name, elementName)
                }
            }
            func check() {
                let elementString = "<\(self.name) />"
                var parser = XMLParser(data: elementString.data(using: .utf8)!)
                parser.delegate = self
                XCTAssertTrue(parser.parse())
                
                // Confirm that the parts of QName is also not swapped.
                parser = XMLParser(data: elementString.data(using: .utf8)!)
                parser.delegate = self
                parser.shouldProcessNamespaces = true
                XCTAssertTrue(parser.parse())
            }
        }
        
        ElementNameChecker("noPrefix").check()
        ElementNameChecker("myPrefix:myLocalName").check()
    }

    func testExternalEntity() throws {
        class Delegate: XMLParserDelegateEventStream {
            override func parserDidStartDocument(_ parser: XMLParser) {
                // Start a child parser, updating `currentParser` to the child parser
                // to ensure that `currentParser` won't be reset to `nil`, which would
                // ignore any external entity related configuration.
                let childParser = XMLParser(data: "<child />".data(using: .utf8)!)
                XCTAssertTrue(childParser.parse())
                super.parserDidStartDocument(parser)
            }
        }
        try withTemporaryDirectory { dir, _ in
            let greetingPath = dir.appendingPathComponent("greeting.xml")
            try Data("<hello />".utf8).write(to: greetingPath)
            let xml = """
            <?xml version="1.0" standalone="no"?>
            <!DOCTYPE doc [
              <!ENTITY greeting SYSTEM "\(greetingPath.absoluteString)">
            ]>
            <doc>&greeting;</doc>
            """

            let parser = XMLParser(data: xml.data(using: .utf8)!)
            // Explicitly disable external entity resolving
            parser.externalEntityResolvingPolicy = .never
            let delegate = Delegate()
            parser.delegate = delegate
            // The parse result changes depending on the libxml2 version
            // because of the following libxml2 commit (shipped in libxml2 2.9.10):
            // https://gitlab.gnome.org/GNOME/libxml2/-/commit/eddfbc38fa7e84ccd480eab3738e40d1b2c83979
            // So we don't check the parse result here.
            _ = parser.parse()
            XCTAssertEqual(delegate.events, [
                .startDocument,
                .didStartElement("doc", nil, nil, [:]),
                // Should not have parsed the external entity
                .didEndElement("doc", nil, nil),
                .endDocument,
            ])
        }
    }
}
