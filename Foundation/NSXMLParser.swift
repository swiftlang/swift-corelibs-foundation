// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// It is necessary to explicitly cast strlen to UInt to match the type
// of prefixLen because currently, strlen (and other functions that
// rely on swift_ssize_t) use the machine word size (int on 32 bit and
// long in on 64 bit).  I've filed a bug at bugs.swift.org:
// https://bugs.swift.org/browse/SR-314

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif
import CoreFoundation

extension XMLParser {
    public enum ExternalEntityResolvingPolicy : UInt {
        
        case resolveExternalEntitiesNever // default
        case resolveExternalEntitiesNoNetwork
        case resolveExternalEntitiesSameOriginOnly //only applies to NSXMLParser instances initialized with -initWithContentsOfURL:
        case resolveExternalEntitiesAlways
    }
}

extension _CFXMLInterface {
    var parser: XMLParser {
        return unsafeBitCast(self, to: XMLParser.self)
    }
}

extension XMLParser {
    internal var interface: _CFXMLInterface {
        return unsafeBitCast(self, to: _CFXMLInterface.self)
    }
}

private func UTF8STRING(_ bytes: UnsafePointer<UInt8>) -> String? {
    // strlen operates on the wrong type, char*. We can't rebind the memory to a different type without knowing it's length,
    // but since we know strlen is in libc, its safe to directly bitcast the pointer without worrying about multiple accesses
    // of different types visible to the compiler.
    let len = strlen(unsafeBitCast(bytes, to: UnsafePointer<Int8>.self))
    let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: bytes, count: Int(len)))
    return str
}

internal func _NSXMLParserCurrentParser() -> _CFXMLInterface? {
    if let parser = XMLParser.currentParser() {
        return parser.interface
    } else {
        return nil
    }
}

internal func _NSXMLParserExternalEntityWithURL(_ interface: _CFXMLInterface, urlStr: UnsafePointer<Int8>, identifier: UnsafePointer<Int8>, context: _CFXMLInterfaceParserContext, originalLoaderFunction: _CFXMLInterfaceExternalEntityLoader) -> _CFXMLInterfaceParserInput? {
    let parser = interface.parser
    let policy = parser.externalEntityResolvingPolicy
    var a: URL?
    if let allowedEntityURLs = parser.allowedExternalEntityURLs {
        if let url = URL(string: String(describing: urlStr)) {
            a = url
            if let scheme = url.scheme {
                if scheme == "file" {
                    a = URL(fileURLWithPath: url.path)
                }
            }
        }
        if let url = a {
            let allowed = allowedEntityURLs.contains(url)
            if allowed || policy != .resolveExternalEntitiesSameOriginOnly {
                if allowed {
                    return originalLoaderFunction(urlStr, identifier, context)
                }
            }
        }
    }
    
    switch policy {
    case .resolveExternalEntitiesSameOriginOnly:
        guard let url = parser._url else { break }
        
        if a == nil {
            a = URL(string: String(describing: urlStr))
        }
        
        guard let aUrl = a else { break }
        
        var matches: Bool
        if let aHost = aUrl.host, let host = url.host {
            matches = host == aHost
        } else {
            return nil
        }
        
        if matches {
            if let aPort = aUrl.port, let port = url.port {
                matches = port == aPort
            } else {
                return nil
            }
        }
        
        if matches {
            if let aScheme = aUrl.scheme, let scheme = url.scheme {
                matches = scheme == aScheme
            } else {
                return nil
            }
        }
        
        if !matches {
            return nil
        }
        break
    case .resolveExternalEntitiesAlways:
        break
    case .resolveExternalEntitiesNever:
        return nil
    case .resolveExternalEntitiesNoNetwork:
        return _CFXMLInterfaceNoNetExternalEntityLoader(urlStr, identifier, context)
    }
    
    return originalLoaderFunction(urlStr, identifier, context)
}

internal func _NSXMLParserGetContext(_ ctx: _CFXMLInterface) -> _CFXMLInterfaceParserContext {
    return ctx.parser._parserContext!
}

internal func _NSXMLParserInternalSubset(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, ExternalID: UnsafePointer<UInt8>, SystemID: UnsafePointer<UInt8>) -> Void {
    _CFXMLInterfaceSAX2InternalSubset(ctx.parser._parserContext, name, ExternalID, SystemID)
}

internal func _NSXMLParserIsStandalone(_ ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceIsStandalone(ctx.parser._parserContext)
}

internal func _NSXMLParserHasInternalSubset(_ ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceHasInternalSubset(ctx.parser._parserContext)
}

internal func _NSXMLParserHasExternalSubset(_ ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceHasExternalSubset(ctx.parser._parserContext)
}

internal func _NSXMLParserGetEntity(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>) -> _CFXMLInterfaceEntity? {
    let parser = ctx.parser
    let context = _NSXMLParserGetContext(ctx)
    var entity = _CFXMLInterfaceGetPredefinedEntity(name)
    if entity == nil {
        entity = _CFXMLInterfaceSAX2GetEntity(context, name)
    }
    if entity == nil {
        if let delegate = parser.delegate {
            let entityName = UTF8STRING(name)!
            // if the systemID was valid, we would already have the correct entity (since we're loading external dtds) so this callback is a bit of a misnomer
            let result = delegate.parser(parser, resolveExternalEntityName: entityName, systemID: nil)
            if _CFXMLInterfaceHasDocument(context) != 0 {
                if let data = result {
                    // unfortunately we can't add the entity to the doc to avoid further lookup since the delegate can change under us
                    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                        _NSXMLParserCharacters(ctx, ch: bytes, len: Int32(data.count))
                    }
                    
                }
            }
        }
    }
    return entity
}

internal func _NSXMLParserNotationDecl(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, publicId: UnsafePointer<UInt8>, systemId: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let notationName = UTF8STRING(name)!
        let publicIDString = UTF8STRING(publicId)
        let systemIDString = UTF8STRING(systemId)
        delegate.parser(parser, foundNotationDeclarationWithName: notationName, publicID: publicIDString, systemID: systemIDString)
    }
}

internal func _NSXMLParserAttributeDecl(_ ctx: _CFXMLInterface, elem: UnsafePointer<UInt8>, fullname: UnsafePointer<UInt8>, type: Int32, def: Int32, defaultValue: UnsafePointer<UInt8>, tree: _CFXMLInterfaceEnumeration) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let elementString = UTF8STRING(elem)!
        let nameString = UTF8STRING(fullname)!
        let typeString = "" // FIXME!
        let defaultValueString = UTF8STRING(defaultValue)
        delegate.parser(parser, foundAttributeDeclarationWithName: nameString, forElement: elementString, type: typeString, defaultValue: defaultValueString)
    }
    // in a regular sax implementation tree is added to an attribute, which takes ownership of it; in our case we need to make sure to release it
    _CFXMLInterfaceFreeEnumeration(tree)
}

internal func _NSXMLParserElementDecl(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, type: Int32, content: _CFXMLInterfaceElementContent) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let nameString = UTF8STRING(name)!
        let modelString = "" // FIXME!
        delegate.parser(parser, foundElementDeclarationWithName: nameString, model: modelString)
    }
}

internal func _NSXMLParserUnparsedEntityDecl(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, publicId: UnsafePointer<UInt8>, systemId: UnsafePointer<UInt8>, notationName: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    let context = _NSXMLParserGetContext(ctx)
    
    // Add entities to the libxml2 doc so they'll resolve properly
    _CFXMLInterfaceSAX2UnparsedEntityDecl(context, name, publicId, systemId, notationName)
    if let delegate = parser.delegate {
        let declName = UTF8STRING(name)!
        let publicIDString = UTF8STRING(publicId)
        let systemIDString = UTF8STRING(systemId)
        let notationNameString = UTF8STRING(notationName)
        delegate.parser(parser, foundUnparsedEntityDeclarationWithName: declName, publicID: publicIDString, systemID: systemIDString, notationName: notationNameString)
    }
}

internal func _NSXMLParserStartDocument(_ ctx: _CFXMLInterface) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parserDidStartDocument(parser)
    }
}

internal func _NSXMLParserEndDocument(_ ctx: _CFXMLInterface) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parserDidEndDocument(parser)
    }
}

internal func _colonSeparatedStringFromPrefixAndSuffix(_ prefix: UnsafePointer<UInt8>, _ prefixlen: UInt, _ suffix: UnsafePointer<UInt8>, _ suffixLen: UInt) -> String {
    let prefixString = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: prefix, count: Int(prefixlen)))
    let suffixString = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: suffix, count: Int(suffixLen)))
    return "\(prefixString!):\(suffixString!)"
}

internal func _NSXMLParserStartElementNs(_ ctx: _CFXMLInterface, localname: UnsafePointer<UInt8>, prefix: UnsafePointer<UInt8>?, URI: UnsafePointer<UInt8>, nb_namespaces: Int32, namespaces: UnsafeMutablePointer<UnsafePointer<UInt8>?>, nb_attributes: Int32, nb_defaulted: Int32, attributes: UnsafeMutablePointer<UnsafePointer<UInt8>?>) -> Void {
    let parser = ctx.parser
    let reportQNameURI = parser.shouldProcessNamespaces
    let reportNamespaces = parser.shouldReportNamespacePrefixes
    // Since strlen is in libc, it's safe to bitcast the UInt8 pointer argument to an Int8 (char *) pointer.
    let prefixLen = prefix != nil ? UInt(strlen(unsafeBitCast(prefix!, to: UnsafePointer<Int8>.self))) : 0
    let localnameString = (prefixLen == 0 || reportQNameURI) ? UTF8STRING(localname) : nil
    let qualifiedNameString = prefixLen != 0 ? _colonSeparatedStringFromPrefixAndSuffix(prefix!, UInt(prefixLen), localname, UInt(strlen(unsafeBitCast(localname, to: UnsafePointer<Int8>.self)))) : localnameString
    let namespaceURIString = reportQNameURI ? UTF8STRING(URI) : nil
    
    var nsDict = [String:String]()
    var attrDict = [String:String]()
    if nb_attributes + nb_namespaces > 0 {
        for idx in stride(from: 0, to: Int(nb_namespaces) * 2, by: 2) {
            var namespaceNameString: String?
            var asAttrNamespaceNameString: String?
            if let ns = namespaces[idx] {
                if reportNamespaces {
                    namespaceNameString = UTF8STRING(ns)
                }
                asAttrNamespaceNameString = _colonSeparatedStringFromPrefixAndSuffix("xmlns", 5, ns, UInt(strlen(unsafeBitCast(ns, to: UnsafePointer<Int8>.self))))
            } else {
                namespaceNameString = ""
                asAttrNamespaceNameString = "xmlns"
            }
            let namespaceValueString = namespaces[idx + 1] != nil ? UTF8STRING(namespaces[idx + 1]!) : ""
            if reportNamespaces {
                if let k = namespaceNameString, let v = namespaceValueString {
                    nsDict[k] = v
                }
            }
            if !reportQNameURI {
                if let k = asAttrNamespaceNameString,
                   let v = namespaceValueString {
                    attrDict[k] = v
                }
            }
        }
    }
    
    if reportNamespaces {
        parser._pushNamespaces(nsDict)
    }
    
    for idx in stride(from: 0, to: Int(nb_attributes) * 5, by: 5) {
        if attributes[idx] == nil {
            continue
        }
        var attributeQName: String
        let attrLocalName = attributes[idx]!
        let attrPrefix = attributes[idx + 1]
        // Since strlen is in libc, it's safe to bitcast the UInt8 pointer argument to an Int8 (char *) pointer.
        let attrPrefixLen = attrPrefix != nil ? strlen(unsafeBitCast(attrPrefix!, to: UnsafePointer<Int8>.self)) : 0
        if attrPrefixLen != 0 {
            attributeQName = _colonSeparatedStringFromPrefixAndSuffix(attrPrefix!, UInt(attrPrefixLen), attrLocalName, UInt(strlen((unsafeBitCast(attrLocalName, to: UnsafePointer<Int8>.self)))))
        } else {
            attributeQName = UTF8STRING(attrLocalName)!
        }
        // idx+2 = URI, which we throw away
        // idx+3 = value, i+4 = endvalue
        // By using XML_PARSE_NOENT the attribute value string will already have entities resolved
        var attributeValue = ""
        if attributes[idx + 3] != nil && attributes[idx + 4] != nil {
            let numBytesWithoutTerminator = attributes[idx + 4]! - attributes[idx + 3]!
            let numBytesWithTerminator = numBytesWithoutTerminator + 1
            if numBytesWithoutTerminator != 0 {
                var chars = [UInt8](repeating: 0, count: numBytesWithTerminator)
                attributeValue = chars.withUnsafeMutableBufferPointer({ (buffer: inout UnsafeMutableBufferPointer<UInt8>) -> String in
                    // In Swift code, buffer is alwaus accessed as UInt8.
                    // Since strncpy is in libc, it's safe to bitcast the UInt8 pointer arguments to an Int8 (char *) pointer.
                    strncpy(unsafeBitCast(buffer.baseAddress!, to: UnsafeMutablePointer<Int8>.self),
                        unsafeBitCast(attributes[idx + 3]!, to: UnsafePointer<Int8>.self),
                        numBytesWithoutTerminator) //not strlcpy because attributes[i+3] is not Nul terminated
                    return UTF8STRING(buffer.baseAddress!)!
                })
            }
            attrDict[attributeQName] = attributeValue
        }
        
    }
    
    if let delegate = parser.delegate {
        if reportQNameURI {
            delegate.parser(parser, didStartElement: localnameString!, namespaceURI: (namespaceURIString != nil ? namespaceURIString : ""), qualifiedName: (qualifiedNameString != nil ? qualifiedNameString : ""), attributes: attrDict)
        } else {
            delegate.parser(parser, didStartElement: qualifiedNameString!, namespaceURI: nil, qualifiedName: nil, attributes: attrDict)
        }
    }
}

internal func _NSXMLParserEndElementNs(_ ctx: _CFXMLInterface , localname: UnsafePointer<UInt8>, prefix: UnsafePointer<UInt8>?, URI: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    let reportQNameURI = parser.shouldProcessNamespaces
    let prefixLen = prefix != nil ? strlen(unsafeBitCast(prefix!, to: UnsafePointer<Int8>.self)) : 0
    let localnameString = (prefixLen == 0 || reportQNameURI) ? UTF8STRING(localname) : nil
    let nilStr: String? = nil
    let qualifiedNameString = (prefixLen != 0) ? _colonSeparatedStringFromPrefixAndSuffix(prefix!, UInt(prefixLen), localname, UInt(strlen(unsafeBitCast(localname, to: UnsafePointer<Int8>.self)))) : nilStr
    let namespaceURIString = reportQNameURI ? UTF8STRING(URI) : nilStr
    
    
    if let delegate = parser.delegate {
        if reportQNameURI {
            // When reporting namespace info, the delegate parameters are not passed in nil
            delegate.parser(parser, didEndElement: localnameString!, namespaceURI: namespaceURIString == nil ? "" : namespaceURIString, qualifiedName: qualifiedNameString == nil ? "" : qualifiedNameString)
        } else {
            delegate.parser(parser, didEndElement: qualifiedNameString!, namespaceURI: nil, qualifiedName: nil)
        }
    }
    
    // Pop the last namespaces that were pushed (safe since XML is balanced)
    parser._popNamespaces()
}

internal func _NSXMLParserCharacters(_ ctx: _CFXMLInterface, ch: UnsafePointer<UInt8>, len: Int32) -> Void {
    let parser = ctx.parser
    let context = parser._parserContext!
    if _CFXMLInterfaceInRecursiveState(context) != 0 {
        _CFXMLInterfaceResetRecursiveState(context)
    } else {
        if let delegate = parser.delegate {
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: ch, count: Int(len)))
            delegate.parser(parser, foundCharacters: str!)
        }
    }
}

internal func _NSXMLParserProcessingInstruction(_ ctx: _CFXMLInterface, target: UnsafePointer<UInt8>, data: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let targetString = UTF8STRING(target)!
        let dataString = UTF8STRING(data)
        delegate.parser(parser, foundProcessingInstructionWithTarget: targetString, data: dataString)
    }
}

internal func _NSXMLParserCdataBlock(_ ctx: _CFXMLInterface, value: UnsafePointer<UInt8>, len: Int32) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parser(parser, foundCDATA: Data(bytes: value, count: Int(len)))
    }
}

internal func _NSXMLParserComment(_ ctx: _CFXMLInterface, value: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let comment = UTF8STRING(value)!
        delegate.parser(parser, foundComment: comment)
    }
}

internal func _NSXMLParserExternalSubset(_ ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, ExternalID: UnsafePointer<UInt8>, SystemID: UnsafePointer<UInt8>) -> Void {
    _CFXMLInterfaceSAX2ExternalSubset(ctx.parser._parserContext, name, ExternalID, SystemID)
}

internal func _structuredErrorFunc(_ interface: _CFXMLInterface, error: _CFXMLInterfaceError) {
    let err = _CFErrorCreateFromXMLInterface(error)._nsObject
    let parser = interface.parser
    parser._parserError = err
    if let delegate = parser.delegate {
        delegate.parser(parser, parseErrorOccurred: err)
    }
}

open class XMLParser : NSObject {
    private var _handler: _CFXMLInterfaceSAXHandler
    internal var _stream: InputStream?
    internal var _data: Data?
    internal var _chunkSize = Int(4096 * 32) // a suitably large number for a decent chunk size
    internal var _haveDetectedEncoding = false
    internal var _bomChunk: Data?
    fileprivate var _parserContext: _CFXMLInterfaceParserContext?
    internal var _delegateAborted = false
    internal var _url: URL?
    internal var _namespaces = [[String:String]]()
    
    // initializes the parser with the specified URL.
    public convenience init?(contentsOf url: URL) {
        if url.isFileURL {
            if let stream = InputStream(url: url) {
                self.init(stream: stream)
                _url = url
            } else {
                return nil
            }
        } else {
            do {
                let data = try Data(contentsOf: url)
                self.init(data: data)
                self._url = url
            } catch {
                return nil
            }
        }
    }
    
    // create the parser from data
    public init(data: Data) {
        _CFSetupXMLInterface()
        _data = data
        _handler = _CFXMLInterfaceCreateSAXHandler()
        _parserContext = nil
    }
    
    deinit {
        _CFXMLInterfaceDestroySAXHandler(_handler)
        _CFXMLInterfaceDestroyContext(_parserContext)
    }
    
    //create a parser that incrementally pulls data from the specified stream and parses it.
    public init(stream: InputStream) {
        _CFSetupXMLInterface()
        _stream = stream
        _handler = _CFXMLInterfaceCreateSAXHandler()
        _parserContext = nil
    }
    
    open weak var delegate: XMLParserDelegate?
    
    open var shouldProcessNamespaces: Bool = false
    open var shouldReportNamespacePrefixes: Bool = false
    
    //defaults to NSXMLNodeLoadExternalEntitiesNever
    open var externalEntityResolvingPolicy: ExternalEntityResolvingPolicy = .resolveExternalEntitiesNever
    
    open var allowedExternalEntityURLs: Set<URL>?
    
    internal static func currentParser() -> XMLParser? {
        if let current = Thread.current.threadDictionary["__CurrentNSXMLParser"] {
            return current as? XMLParser
        } else {
            return nil
        }
    }
    
    internal static func setCurrentParser(_ parser: XMLParser?) {
        if let p = parser {
            Thread.current.threadDictionary["__CurrentNSXMLParser"] = p
        } else {
            Thread.current.threadDictionary.removeValue(forKey: "__CurrentNSXMLParser")
        }
    }
    
    internal func _handleParseResult(_ parseResult: Int32) -> Bool {
        return true
        /*
        var result = true
        if parseResult != 0 {
            if parseResult != -1 {
                // TODO: determine if this result is a fatal error from libxml via the CF implementations
            }
        }
        return result
        */
    }

    internal func parseData(_ data: Data) -> Bool {
        _CFXMLInterfaceSetStructuredErrorFunc(interface, _structuredErrorFunc)
        var result = true
        /* The vast majority of this method just deals with ensuring we do a single parse
         on the first 4 received bytes before continuing on to the actual incremental section */
        if _haveDetectedEncoding {
            var totalLength = data.count
            if let chunk = _bomChunk {
                totalLength += chunk.count
            }
            if (totalLength < 4) {
                if let chunk = _bomChunk {
                    var newData = Data()
                    newData.append(chunk)
                    newData.append(data)
                    _bomChunk = newData
                } else {
                    _bomChunk = data
                }
            } else {
                var allExistingData: Data
                if let chunk = _bomChunk {
                    var newData = Data()
                    newData.append(chunk)
                    newData.append(data)
                    allExistingData = newData
                } else {
                    allExistingData = data
                }

                var handler: _CFXMLInterfaceSAXHandler? = nil
                if delegate != nil {
                    handler = _handler
                }
                
                _parserContext = allExistingData.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> _CFXMLInterfaceParserContext in
                    return _CFXMLInterfaceCreatePushParserCtxt(handler, interface, bytes, 4, nil)
                }

                var options = _kCFXMLInterfaceRecover | _kCFXMLInterfaceNoEnt // substitute entities, recover on errors
                if shouldResolveExternalEntities {
                    options |= _kCFXMLInterfaceDTDLoad
                }

                if handler == nil {
                    options |= (_kCFXMLInterfaceNoError | _kCFXMLInterfaceNoWarning)
                }

                _CFXMLInterfaceCtxtUseOptions(_parserContext, options)
                _haveDetectedEncoding = true
                _bomChunk = nil

                if (totalLength > 4) {
                    let remainingData = allExistingData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Data in
                        let ptr = bytes.advanced(by: 4)
                        return Data(bytesNoCopy: ptr, count: totalLength - 4, deallocator: .none)
                    }
                    
                    let _ = parseData(remainingData)
                }
            }
        } else {
            let parseResult = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Int32 in
                return _CFXMLInterfaceParseChunk(_parserContext, bytes, Int32(data.count), 0)
            }
            
            result = _handleParseResult(parseResult)
        }
        _CFXMLInterfaceSetStructuredErrorFunc(interface, nil)
        return result
    }

    internal func parseFromStream() -> Bool {
        var result = true
        XMLParser.setCurrentParser(self)
        if let stream = _stream {
            stream.open()
            let buffer = malloc(_chunkSize)!.bindMemory(to: UInt8.self, capacity: _chunkSize)
            var len = stream.read(buffer, maxLength: _chunkSize)
            if len != -1 {
                while len > 0 {
                    let data = Data(bytesNoCopy: buffer, count: len, deallocator: .none)
                    result = parseData(data)
                    len = stream.read(buffer, maxLength: _chunkSize)
                }
            } else {
                result = false
            }
            free(buffer)
            stream.close()
        } else if let data = _data {
            let buffer = malloc(_chunkSize)!.bindMemory(to: UInt8.self, capacity: _chunkSize)
            var range = NSMakeRange(0, min(_chunkSize, data.count))
            while result {
                let chunk = data.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> Data in
                    let ptr = buffer.advanced(by: range.location)
                    return Data(bytesNoCopy: UnsafeMutablePointer(mutating: ptr), count: range.length, deallocator: .none)
                }
                result = parseData(chunk)
                if range.location + range.length >= data.count {
                    break
                }
                range = NSMakeRange(range.location + range.length, min(_chunkSize, data.count - (range.location + range.length)))
            }
            free(buffer)
        } else {
            result = false
        }
        XMLParser.setCurrentParser(nil)
        return result
    }
    
    // called to start the event-driven parse. Returns YES in the event of a successful parse, and NO in case of error.
    open func parse() -> Bool {
        return parseFromStream()
    }
    
    // called by the delegate to stop the parse. The delegate will get an error message sent to it.
    open func abortParsing() {
        if let context = _parserContext {
            _CFXMLInterfaceStopParser(context)
            _delegateAborted = true
        }
    }
    
    internal var _parserError: Error?

    // can be called after a parse is over to determine parser state.
    open var parserError: Error? {
        return _parserError
    }
    
    //Toggles between disabling external entities entirely, and the current setting of the 'externalEntityResolvingPolicy'.
    //The 'externalEntityResolvingPolicy' property should be used instead of this, unless targeting 10.9/7.0 or earlier
    open var shouldResolveExternalEntities: Bool = false
    
    // Once a parse has begun, the delegate may be interested in certain parser state. These methods will only return meaningful information during parsing, or after an error has occurred.
    open var publicID: String? {
        return nil
    }
    
    open var systemID: String? {
        return nil
    }
    
    open var lineNumber: Int {
        return Int(_CFXMLInterfaceSAX2GetLineNumber(_parserContext))
    }
    
    open var columnNumber: Int {
        return Int(_CFXMLInterfaceSAX2GetColumnNumber(_parserContext))
    }
    
    internal func _pushNamespaces(_ ns: [String:String]) {
        _namespaces.append(ns)
        if let del = self.delegate {
            ns.forEach {
                del.parser(self, didStartMappingPrefix: $0.0, toURI: $0.1)
            }
        }
    }
    
    internal func _popNamespaces() {
        let ns = _namespaces.removeLast()
        if let del = self.delegate {
            ns.forEach {
                del.parser(self, didEndMappingPrefix: $0.0)
            }
        }
    }
}

/*
 
 For the discussion of event methods, assume the following XML:
 
 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type='text/css' href='cvslog.css'?>
 <!DOCTYPE cvslog SYSTEM "cvslog.dtd">
 <cvslog xmlns="http://xml.apple.com/cvslog">
 <radar:radar xmlns:radar="http://xml.apple.com/radar">
 <radar:bugID>2920186</radar:bugID>
 <radar:title>API/NSXMLParser: there ought to be an NSXMLParser</radar:title>
 </radar:radar>
 </cvslog>
 
 */

// The parser's delegate is informed of events through the methods in the NSXMLParserDelegateEventAdditions category.
public protocol XMLParserDelegate: class {
    
    // Document handling methods
    func parserDidStartDocument(_ parser: XMLParser)
    // sent when the parser begins parsing of the document.
    func parserDidEndDocument(_ parser: XMLParser)
    // sent when the parser has completed parsing. If this is encountered, the parse was successful.
    
    // DTD handling methods for various declarations.
    func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?)
    
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?)
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String)
    
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?)
    
    func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    // sent when the parser finds an element start tag.
    // In the case of the cvslog tag, the following is what the delegate receives:
    //   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
    // In the case of the radar tag, the following is what's passed in:
    //    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
    // If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    // sent when an end tag is encountered. The various parameters are supplied as above.
    
    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String)
    // sent when the parser first sees a namespace attribute.
    // In the case of the cvslog tag, before the didStartElement:, you'd get one of these with prefix == @"" and namespaceURI == @"http://xml.apple.com/cvslog" (i.e. the default namespace)
    // In the case of the radar:radar tag, before the didStartElement: you'd get one of these with prefix == @"radar" and namespaceURI == @"http://xml.apple.com/radar"
    
    func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String)
    // sent when the namespace prefix in question goes out of scope.
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    // This returns the string of the characters encountered thus far. You may not necessarily get the longest character run. The parser reserves the right to hand these to the delegate as potentially many calls in a row to -parser:foundCharacters:
    
    func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String)
    // The parser reports ignorable whitespace in the same way as characters it's found.
    
    func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?)
    // The parser reports a processing instruction to you using this method. In the case above, target == @"xml-stylesheet" and data == @"type='text/css' href='cvslog.css'"
    
    func parser(_ parser: XMLParser, foundComment comment: String)
    // A comment (Text in a <!-- --> block) is reported to the delegate as a single string
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data)
    // this reports a CDATA block to the delegate as an NSData.
    
    func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data?
    // this gives the delegate an opportunity to resolve an external entity itself and reply with the resulting data.
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: NSError)
    // ...and this reports a fatal error to the delegate. The parser will stop parsing.
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: NSError)
}

extension XMLParserDelegate {
    
    func parserDidStartDocument(_ parser: XMLParser) { }
    func parserDidEndDocument(_ parser: XMLParser) { }
    
    func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) { }
    
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) { }
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) { }
    
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { }
    
    func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) { }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { }
    
    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) { }
    
    func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) { }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) { }
    
    func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) { }
    
    func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) { }
    
    func parser(_ parser: XMLParser, foundComment comment: String) { }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) { }
    
    func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? { return nil }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: NSError) { }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: NSError) { }
}

extension XMLParser {
    // If validation is on, this will report a fatal validation error to the delegate. The parser will stop parsing.
    public static let ErrorDomain: String = "NSXMLParserErrorDomain" // for use with NSError.

    // Error reporting
    public enum ErrorCode : Int {
        
        
        case internalError
        
        case outOfMemoryError
        
        case documentStartError
        
        case emptyDocumentError
        
        case prematureDocumentEndError
        
        case invalidHexCharacterRefError
        
        case invalidDecimalCharacterRefError
        
        case invalidCharacterRefError
        
        case invalidCharacterError
        
        case characterRefAtEOFError
        
        case characterRefInPrologError
        
        case characterRefInEpilogError
        
        case characterRefInDTDError
        
        case entityRefAtEOFError
        
        case entityRefInPrologError
        
        case entityRefInEpilogError
        
        case entityRefInDTDError
        
        case parsedEntityRefAtEOFError
        
        case parsedEntityRefInPrologError
        
        case parsedEntityRefInEpilogError
        
        case parsedEntityRefInInternalSubsetError
        
        case entityReferenceWithoutNameError
        
        case entityReferenceMissingSemiError
        
        case parsedEntityRefNoNameError
        
        case parsedEntityRefMissingSemiError
        
        case undeclaredEntityError
        
        case unparsedEntityError
        
        case entityIsExternalError
        
        case entityIsParameterError
        
        case unknownEncodingError
        
        case encodingNotSupportedError
        
        case stringNotStartedError
        
        case stringNotClosedError
        
        case namespaceDeclarationError
        
        case entityNotStartedError
        
        case entityNotFinishedError
        
        case lessThanSymbolInAttributeError
        
        case attributeNotStartedError
        
        case attributeNotFinishedError
        
        case attributeHasNoValueError
        
        case attributeRedefinedError
        
        case literalNotStartedError
        
        case literalNotFinishedError
        
        case commentNotFinishedError
        
        case processingInstructionNotStartedError
        
        case processingInstructionNotFinishedError
        
        case notationNotStartedError
        
        case notationNotFinishedError
        
        case attributeListNotStartedError
        
        case attributeListNotFinishedError
        
        case mixedContentDeclNotStartedError
        
        case mixedContentDeclNotFinishedError
        
        case elementContentDeclNotStartedError
        
        case elementContentDeclNotFinishedError
        
        case xmlDeclNotStartedError
        
        case xmlDeclNotFinishedError
        
        case conditionalSectionNotStartedError
        
        case conditionalSectionNotFinishedError
        
        case externalSubsetNotFinishedError
        
        case doctypeDeclNotFinishedError
        
        case misplacedCDATAEndStringError
        
        case cdataNotFinishedError
        
        case misplacedXMLDeclarationError
        
        case spaceRequiredError
        
        case separatorRequiredError
        
        case nmtokenRequiredError
        
        case nameRequiredError
        
        case pcdataRequiredError
        
        case uriRequiredError
        
        case publicIdentifierRequiredError
        
        case ltRequiredError
        
        case gtRequiredError
        
        case ltSlashRequiredError
        
        case equalExpectedError
        
        case tagNameMismatchError
        
        case unfinishedTagError
        
        case standaloneValueError
        
        case invalidEncodingNameError
        
        case commentContainsDoubleHyphenError
        
        case invalidEncodingError
        
        case externalStandaloneEntityError
        
        case invalidConditionalSectionError
        
        case entityValueRequiredError
        
        case notWellBalancedError
        
        case extraContentError
        
        case invalidCharacterInEntityError
        
        case parsedEntityRefInInternalError
        
        case entityRefLoopError
        
        case entityBoundaryError
        
        case invalidURIError
        
        case uriFragmentError
        
        case nodtdError
        
        case delegateAbortedParseError
    }
}
