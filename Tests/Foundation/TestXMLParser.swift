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

    // The slice size XMLParser(data:) shares with XMLParser(stream:) (`_chunkSize`, 128 KiB).
    private static let chunkSize = 131_072

    /// Merges adjacent `foundCharacters` events; libxml2 may split text at slice boundaries.
    private static func coalesced(_ events: [XMLParserDelegateEvent]) -> [XMLParserDelegateEvent] {
        var result: [XMLParserDelegateEvent] = []
        for event in events {
            if case let .foundCharacters(tail) = event, case let .foundCharacters(head)? = result.last {
                result[result.count - 1] = .foundCharacters(head + tail)
            } else {
                result.append(event)
            }
        }
        return result
    }

    // Regression: Data above libxml2's 10,000,000-byte per-call limit failed when fed in one call.
    func test_withLargeData() {
        let text = String(repeating: "x", count: 1_000)
        let data = Data(("<root>" + String(repeating: "<item>\(text)</item>", count: 10_000) + "</root>").utf8)
        XCTAssertGreaterThan(data.count, 10_000_000)
        var expected: [XMLParserDelegateEvent] = [.startDocument, .didStartElement("root", nil, nil, [:])]
        for _ in 0..<10_000 {
            expected += [.didStartElement("item", nil, nil, [:]), .foundCharacters(text), .didEndElement("item", nil, nil)]
        }
        expected += [.didEndElement("root", nil, nil), .endDocument]

        let parser = XMLParser(data: data)
        let delegate = XMLParserDelegateEventStream()
        parser.delegate = delegate
        XCTAssertTrue(parser.parse(), String(describing: parser.parserError))
        let events = TestXMLParser.coalesced(delegate.events)
        XCTAssertEqual(events.count, expected.count)
        XCTAssertTrue(events == expected)
    }

    // The loop must slice by the Data's own indices and mark a full final slice terminal.
    func test_dataSliceOfExactChunkMultiple() {
        let text = String(repeating: "x", count: 2 * TestXMLParser.chunkSize - "<root></root>".utf8.count)
        let padded = Data(repeating: 0x20, count: 1_234) + Data("<root>\(text)</root>".utf8)
        let slice = padded[1_234...]
        XCTAssertEqual(slice.startIndex, 1_234)
        XCTAssertEqual(slice.count, 2 * TestXMLParser.chunkSize)

        let parser = XMLParser(data: slice)
        let delegate = XMLParserDelegateEventStream()
        parser.delegate = delegate
        XCTAssertTrue(parser.parse())
        let expected: [XMLParserDelegateEvent] = [
            .startDocument, .didStartElement("root", nil, nil, [:]), .foundCharacters(text),
            .didEndElement("root", nil, nil), .endDocument,
        ]
        XCTAssertTrue(TestXMLParser.coalesced(delegate.events) == expected)
    }

    // After a failed call no further slice is fed: <late/> starts in the slice after the error.
    func test_dataErrorStopsLaterSlices() {
        let document = "<root>&undeclared;" + String(repeating: "<a/>", count: TestXMLParser.chunkSize / 4) + "<late/></root>"
        let parser = XMLParser(data: Data(document.utf8))
        let delegate = XMLParserDelegateEventStream()
        parser.delegate = delegate
        XCTAssertFalse(parser.parse())
        XCTAssertNotNil(parser.parserError)
        XCTAssertFalse(delegate.events.contains(.didStartElement("late", nil, nil, [:])))
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
