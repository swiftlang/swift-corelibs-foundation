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

/// Records only what the later-chunk error tests need: started element names and parse errors.
/// Shared by the document-end and recoverable-error tests, which assert different failure modes.
class XMLParserErrorRecordingDelegate: NSObject, XMLParserDelegate {
    var elementNames: [String] = []
    var errors: [Error] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        elementNames.append(elementName)
    }
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        errors.append(parseError)
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

    // Regression: a many-element document above libxml2's per-call input/lookup limit must parse
    // successfully through both `XMLParser(data:)` and `XMLParser(stream:)`, delivering the exact
    // same complete content. Against the unpatched base the Data path fails (the negative control).
    func test_withLargeData() {
        let text = String(repeating: "x", count: 1_000)
        let element = "<item>" + text + "</item>"
        let itemCount = 10_000
        let document = "<root>" + String(repeating: element, count: itemCount) + "</root>"
        let data = Data(document.utf8)
        XCTAssertGreaterThan(data.count, 10_000_000)

        var expected: [XMLParserDelegateEvent] = [.startDocument, .didStartElement("root", nil, nil, [:])]
        for _ in 0..<itemCount {
            expected.append(.didStartElement("item", nil, nil, [:]))
            expected.append(.foundCharacters(text))
            expected.append(.didEndElement("item", nil, nil))
        }
        expected.append(.didEndElement("root", nil, nil))
        expected.append(.endDocument)

        func parse(streamed: Bool) -> (result: Bool, parser: XMLParser, events: [XMLParserDelegateEvent]) {
            let parser = streamed ? XMLParser(stream: InputStream(data: data)) : XMLParser(data: data)
            let delegate = XMLParserDelegateEventStream()
            parser.delegate = delegate
            let result = parser.parse()
            return (result, parser, delegate.events)
        }

        let dataParsed = parse(streamed: false)
        XCTAssertTrue(dataParsed.result, "Data parse failed: \(String(describing: dataParsed.parser.parserError))")
        XCTAssertNil(dataParsed.parser.parserError)

        let streamParsed = parse(streamed: true)
        XCTAssertTrue(streamParsed.result, "Stream parse failed: \(String(describing: streamParsed.parser.parserError))")
        XCTAssertNil(streamParsed.parser.parserError)

        // Compare each path against the independently constructed expected content, and against
        // each other. Raw foundCharacters callback boundaries are permitted to differ.
        let dataEvents = TestXMLParser.coalesced(dataParsed.events)
        let streamEvents = TestXMLParser.coalesced(streamParsed.events)
        TestXMLParser.assertEventsEqual(dataEvents, expected, "large Data vs expected")
        TestXMLParser.assertEventsEqual(streamEvents, expected, "large stream vs expected")
        TestXMLParser.assertEventsEqual(dataEvents, streamEvents, "large Data vs stream")
    }

    // Compatibility control, not a well-formedness check: XML 1.0 excludes U+0000, and libxml2
    // reports a trailing NUL as XML_ERR_DOCUMENT_END (5) with wellFormed=false. The C bridge maps a
    // terminal XML_ERR_DOCUMENT_END to success, so `parse()` returns true while `parserError` is
    // non-nil (code 5). This pins that pre-existing Data-path behavior across the terminal call; the
    // bounded Data path reuses the terminal call and does not change the outcome.
    func test_withTrailingNulAboveChunkSize() {
        // The final nonempty chunk carries the terminating flag, preserving trailing-NUL handling
        // for a document just above one chunk.
        let text = String(repeating: "x", count: TestXMLParser.dataChunkSize)
        var data = Data(("<root>" + text + "</root>").utf8)
        data.append(0)

        let parser = XMLParser(data: data)
        let delegate = XMLParserDelegateEventStream()
        parser.delegate = delegate

        XCTAssertTrue(parser.parse())
        TestXMLParser.assertEventsEqual(TestXMLParser.coalesced(delegate.events),
                                        TestXMLParser.rootEvents(text: text))
    }

    // The production Data path reuses `XMLParser._chunkSize` (128 KiB) for its slices; tests align
    // input bytes to this size so boundary cases land where the implementation splits.
    private static let dataChunkSize = 131_072

    /// Coalesces adjacent `foundCharacters` events. libxml2 may split character runs at chunk or
    /// parser-call boundaries, and the delegate contract permits fragmented callbacks, so
    /// comparisons normalize on this coalesced sequence rather than on raw callback boundaries.
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

    /// Expected normalized events for a document of the form `<root>text</root>`.
    private static func rootEvents(text: String) -> [XMLParserDelegateEvent] {
        [
            .startDocument,
            .didStartElement("root", nil, nil, [:]),
            .foundCharacters(text),
            .didEndElement("root", nil, nil),
            .endDocument,
        ]
    }

    private static func events(ofData data: Data) -> (result: Bool, events: [XMLParserDelegateEvent]) {
        let delegate = XMLParserDelegateEventStream()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        let result = parser.parse()
        return (result, delegate.events)
    }

    // MARK: - Bounded diagnostic comparison

    /// Compares two complete normalized event sequences. On mismatch the failure reports the
    /// counts, the first differing index, a bounded description of the two events at that index
    /// and, for text or attributes, where inside the event they differ, instead of letting XCTest
    /// print tens of thousands of events or a 128 KiB string.
    static func assertEventsEqual(
        _ actual: [XMLParserDelegateEvent],
        _ expected: [XMLParserDelegateEvent],
        _ context: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if actual == expected { return }

        var message = "XML event sequence mismatch"
        if !context.isEmpty { message += " (\(context))" }
        message += ": expected \(expected.count) events, actual \(actual.count)"

        let shared = min(actual.count, expected.count)
        if let index = (0..<shared).first(where: { actual[$0] != expected[$0] }) {
            message += "; first difference at index \(index)"
            message += "\n  expected: \(describe(expected[index]))"
            message += "\n  actual:   \(describe(actual[index]))"
            if let detail = detail(expected[index], actual[index]) { message += "\n  \(detail)" }
        } else if actual.count > expected.count {
            message += "; the first \(shared) events match; first unexpected event: \(describe(actual[shared]))"
        } else {
            message += "; the first \(shared) events match; first missing event: \(describe(expected[shared]))"
        }

        XCTFail(message, file: file, line: line)
    }

    /// Bounded one-line description of an event for the failure message. Long strings are cut to
    /// a prefix plus their byte count and at most a few attributes are listed; the assertion itself
    /// compares the events, not these descriptions.
    private static func describe(_ event: XMLParserDelegateEvent) -> String {
        switch event {
        case .startDocument: return ".startDocument"
        case .endDocument: return ".endDocument"
        case let .didStartElement(name, namespaceURI, qualifiedName, attributes):
            return ".didStartElement(\(bounded(name)), ns: \(bounded(namespaceURI)), "
                + "qName: \(bounded(qualifiedName)), attrs: \(bounded(attributes)))"
        case let .didEndElement(name, namespaceURI, qualifiedName):
            return ".didEndElement(\(bounded(name)), ns: \(bounded(namespaceURI)), qName: \(bounded(qualifiedName)))"
        case let .foundCharacters(text):
            return ".foundCharacters(\(bounded(text)))"
        }
    }

    /// Where two events of the same kind differ when their bounded descriptions can hide it: the
    /// first differing character of their text, or the attributes whose values differ.
    private static func detail(_ expected: XMLParserDelegateEvent, _ actual: XMLParserDelegateEvent) -> String? {
        switch (expected, actual) {
        case let (.foundCharacters(expectedText), .foundCharacters(actualText)):
            return "text: " + difference(expectedText, actualText)
        case let (.didStartElement(_, _, _, expectedAttributes), .didStartElement(_, _, _, actualAttributes))
            where expectedAttributes != actualAttributes:
            let keys = Set(expectedAttributes.keys).union(actualAttributes.keys)
                .filter { expectedAttributes[$0] != actualAttributes[$0] }.sorted()
            var entries = keys.prefix(4).map {
                "\(bounded($0)): expected \(bounded(expectedAttributes[$0])), actual \(bounded(actualAttributes[$0]))"
            }
            if keys.count > 4 { entries.append("... (+\(keys.count - 4) more)") }
            return "differing attributes: " + entries.joined(separator: "; ")
        default:
            return nil
        }
    }

    /// The first differing character of two strings, with a short excerpt of each from just before it.
    private static func difference(_ expected: String, _ actual: String) -> String {
        var e = expected.startIndex, a = actual.startIndex, offset = 0
        while e < expected.endIndex, a < actual.endIndex, expected[e] == actual[a] {
            expected.formIndex(after: &e)
            actual.formIndex(after: &a)
            offset += 1
        }
        let back = min(offset, 8)
        let expectedExcerpt = String(expected[expected.index(e, offsetBy: -back)...].prefix(16))
        let actualExcerpt = String(actual[actual.index(a, offsetBy: -back)...].prefix(16))
        return "first difference at character \(offset) (UTF-8 offset \(expected[..<e].utf8.count)): "
            + "expected \(bounded(expectedExcerpt, limit: 64)), actual \(bounded(actualExcerpt, limit: 64))"
    }

    private static func bounded(_ text: String?, limit: Int = 32) -> String {
        guard let text else { return "nil" }
        if text.utf8.count <= limit { return String(reflecting: text) }
        return "\(String(reflecting: String(text.prefix(limit))))... (\(text.utf8.count) bytes)"
    }

    private static func bounded(_ attributes: [String: String], limit: Int = 4) -> String {
        let keys = attributes.keys.sorted()
        var entries = keys.prefix(limit).map { "\(bounded($0)): \(bounded(attributes[$0]))" }
        if keys.count > limit { entries.append("... (+\(keys.count - limit) more)") }
        return "[" + entries.joined(separator: ", ") + "]"
    }

    // Regression: a UTF-8 sequence or an XML token split across the 128 KiB Data slice boundary
    // must be reassembled by libxml2 and delivered as the same complete content as when it is not
    // split. Each case places a different token type exactly on the boundary.
    func test_dataChunkBoundariesInUTF8AndXMLTokens() {
        let chunk = TestXMLParser.dataChunkSize
        // Split each UTF-8 sequence or XML token across the boundary, surrounded by distinct text.
        // `split` is the number of the token's bytes that land in the first slice.
        let cases: [(xml: String, split: Int, events: [XMLParserDelegateEvent])] = [
            ("é", 1, [.foundCharacters("é")]),                 // 2-byte sequence: C3 | A9
            ("漢", 1, [.foundCharacters("漢")]),               // 3-byte sequence: E6 | BC A2
            ("😀", 2, [.foundCharacters("😀")]),               // 4-byte sequence: F0 9F | 98 80
            ("<e a=\"value\"/>", 8, [.didStartElement("e", nil, nil, ["a": "value"]), .didEndElement("e", nil, nil)]), // attribute value: va | lue
            ("<elementname/>", 4, [.didStartElement("elementname", nil, nil, [:]), .didEndElement("elementname", nil, nil)]), // element name: <ele | mentname/>
            ("&amp;", 2, [.foundCharacters("&")]),             // character reference: &a | mp;
        ]
        for (xml, split, events) in cases {
            let prefix = String(repeating: "x", count: chunk - "<root>".utf8.count - split)
            let document = Data(("<root>" + prefix + xml + "tail</root>").utf8)
            XCTAssertGreaterThan(document.count, chunk)
            let expected: [XMLParserDelegateEvent] = [
                .startDocument, .didStartElement("root", nil, nil, [:]), .foundCharacters(prefix),
            ] + events + [.foundCharacters("tail"), .didEndElement("root", nil, nil), .endDocument]
            let parsed = TestXMLParser.events(ofData: document)
            XCTAssertTrue(parsed.result, xml)
            TestXMLParser.assertEventsEqual(TestXMLParser.coalesced(parsed.events),
                                            TestXMLParser.coalesced(expected), xml)
        }
    }

    func test_dataUTF16SurrogatePairAcrossChunkBoundary() throws {
        let chunk = TestXMLParser.dataChunkSize
        let prefix = "<?xml version=\"1.0\" encoding=\"UTF-16\"?><root><text>"
        // Account for the two-byte BOM and put the high surrogate in the first chunk's last two bytes.
        let padding = String(repeating: "x", count: (chunk - 4) / 2 - prefix.utf16.count)
        let text = padding + "😀tail"
        let document = prefix + text + "</text><after/></root>"
        let cases: [(encoding: String.Encoding, signature: [UInt8], boundary: [UInt8])] = [
            (.utf16LittleEndian, [0xFF, 0xFE, 0x3C, 0x00], [0x3D, 0xD8, 0x00, 0xDE]),
            (.utf16BigEndian, [0xFE, 0xFF, 0x00, 0x3C], [0xD8, 0x3D, 0xDE, 0x00]),
        ]
        let expected: [XMLParserDelegateEvent] = [
            .startDocument,
            .didStartElement("root", nil, nil, [:]),
            .didStartElement("text", nil, nil, [:]),
            .foundCharacters(text),
            .didEndElement("text", nil, nil),
            .didStartElement("after", nil, nil, [:]),
            .didEndElement("after", nil, nil),
            .didEndElement("root", nil, nil),
            .endDocument,
        ]
        for (encoding, signature, boundary) in cases {
            var data = Data(signature.prefix(2))
            data.append(try XCTUnwrap(document.data(using: encoding)))
            // One BOM followed immediately by '<'; D83D and DE00 straddle the actual byte boundary.
            XCTAssertEqual(Array(data.prefix(4)), signature)
            XCTAssertEqual(Array(data[(chunk - 2)..<(chunk + 2)]), boundary)
            XCTAssertGreaterThan(data.count, chunk)
            XCTAssertLessThan(data.count, 2 * chunk)

            // Data and InputStream must consume byte-identical input and produce identical content.
            for parser in [XMLParser(data: data), XMLParser(stream: InputStream(data: data))] {
                let delegate = XMLParserDelegateEventStream()
                parser.delegate = delegate
                XCTAssertTrue(parser.parse(), "\(encoding)")
                XCTAssertNil(parser.parserError)
                TestXMLParser.assertEventsEqual(TestXMLParser.coalesced(delegate.events), expected, "\(encoding)")
            }
        }
    }

    func test_dataChunkExactAndOffByOneSizes() {
        // The final slice is always nonempty: a full chunk, one byte, or one byte short of a full chunk.
        let chunk = TestXMLParser.dataChunkSize
        for total in [chunk, 2 * chunk, 2 * chunk + 1, 2 * chunk - 1] {
            let textLength = total - "<root></root>".utf8.count
            let text = String(repeating: "y", count: textLength)
            let document = Data(("<root>" + text + "</root>").utf8)
            XCTAssertEqual(document.count, total)

            let (result, events) = TestXMLParser.events(ofData: document)
            XCTAssertTrue(result, "size \(total)")
            TestXMLParser.assertEventsEqual(TestXMLParser.coalesced(events),
                                            TestXMLParser.rootEvents(text: text), "size \(total)")
        }
    }

    func test_dataSliceWithNonZeroStartIndex() {
        // A Data slice whose startIndex is not 0 must be chunked using the slice's own indices.
        let chunk = TestXMLParser.dataChunkSize
        let text = String(repeating: "z", count: chunk)
        let document = Data(("<root>" + text + "</root>").utf8)
        var padded = Data(repeating: 0x20, count: 1_234)
        padded.append(document)
        let slice = padded[1_234...]
        XCTAssertEqual(slice.startIndex, 1_234)
        XCTAssertEqual(slice.count, document.count)

        let sliced = TestXMLParser.events(ofData: slice)
        XCTAssertTrue(sliced.result)
        TestXMLParser.assertEventsEqual(TestXMLParser.coalesced(sliced.events),
                                        TestXMLParser.rootEvents(text: text))
    }

    // Regression: a malformed-document error raised in a NONterminal Data slice is no longer masked
    // by the C bridge's terminal-call `XML_ERR_DOCUMENT_END` remapping. Against the unpatched base
    // (single terminal call) this document parses as `true` on libxml2 2.9.13, because the recovered
    // document ends with a terminal `XML_ERR_DOCUMENT_END` that the bridge maps to success; the
    // patched path feeds multiple slices, reports `false`, and matches the stream path.
    func test_dataNonterminalDocumentEndErrorIsNotMasked() {
        let chunk = TestXMLParser.dataChunkSize
        let goodElements = chunk / 4 + 100
        var document = Data("<root>".utf8)
        document.append(Data(String(repeating: "<a/>", count: goodElements).utf8))
        document.append(contentsOf: "</wrong>".utf8)
        document.append(Data(String(repeating: "<b/>", count: chunk / 4 * 2).utf8))
        document.append(contentsOf: "</root>".utf8)

        let delegate = XMLParserErrorRecordingDelegate()
        let parser = XMLParser(data: document)
        parser.delegate = delegate
        XCTAssertFalse(parser.parse())
        XCTAssertFalse(delegate.errors.isEmpty)
        XCTAssertEqual(delegate.elementNames, ["root"] + Array(repeating: "a", count: goodElements))
        XCTAssertNotNil(parser.parserError)
    }

    // Regression: an undeclared entity in an early slice fails the parse, and the later slices are
    // never fed, so elements after the error (e.g. `<late/>`) are not delivered.
    func test_dataRecoverableErrorStopsBeforeLaterChunks() {
        let chunk = TestXMLParser.dataChunkSize
        let document = Data(("<root><before/>&undeclared;<after/>"
            + String(repeating: "<a/>", count: chunk / 4 * 2)
            + "<late/></root>").utf8)

        let delegate = XMLParserErrorRecordingDelegate()
        let parser = XMLParser(data: document)
        parser.delegate = delegate
        XCTAssertFalse(parser.parse())
        XCTAssertFalse(delegate.errors.isEmpty)
        XCTAssertNotNil(parser.parserError)
        XCTAssertFalse(delegate.elementNames.contains("late"))
    }

    // Regression: abortParsing() from inside the second slice stops delivery immediately and stops
    // feeding the remaining slices. This differs from test_sr9758_abortParsing, which aborts inside
    // parserDidStartDocument before any slice is fed.
    func test_dataAbortInLaterChunkStopsDelivery() {
        class Delegate: NSObject, XMLParserDelegate {
            let abortAt: Int
            var elements = 0
            var endDocument = false
            init(abortAt: Int) { self.abortAt = abortAt }
            func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
                elements += 1
                if elements == abortAt { parser.abortParsing() }
            }
            func parserDidEndDocument(_ parser: XMLParser) { endDocument = true }
        }
        let chunk = TestXMLParser.dataChunkSize
        let document = Data(("<root>" + String(repeating: "<a/>", count: chunk / 4 * 3) + "</root>").utf8)
        let abortAt = chunk / 4 + 50                            // inside the second chunk
        let delegate = Delegate(abortAt: abortAt)
        let parser = XMLParser(data: document)
        parser.delegate = delegate
        XCTAssertFalse(parser.parse())
        XCTAssertNotNil(parser.parserError)
        XCTAssertEqual(delegate.elements, abortAt)
        XCTAssertFalse(delegate.endDocument)
    }

    // Protects the preserved empty-Data path: the patch routes empty Data through a single terminal
    // call, which must deliver no delegate events. The parse return value is intentionally not
    // asserted here, matching the pre-existing empty-input behavior.
    func test_emptyDataDeliversNoEvents() {
        let delegate = XMLParserDelegateEventStream()
        let parser = XMLParser(data: Data())
        parser.delegate = delegate
        _ = parser.parse()
        XCTAssertTrue(delegate.events.isEmpty)
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
