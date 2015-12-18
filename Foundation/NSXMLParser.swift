// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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
#elseif os(Linux)
    import Glibc
#endif
import CoreFoundation

public enum NSXMLParserExternalEntityResolvingPolicy : UInt {
    
    case ResolveExternalEntitiesNever // default
    case ResolveExternalEntitiesNoNetwork
    case ResolveExternalEntitiesSameOriginOnly //only applies to NSXMLParser instances initialized with -initWithContentsOfURL:
    case ResolveExternalEntitiesAlways
}

extension _CFXMLInterface {
    var parser: NSXMLParser {
        return unsafeBitCast(self, NSXMLParser.self)
    }
}

extension NSXMLParser {
    internal var interface: _CFXMLInterface {
        return unsafeBitCast(self, _CFXMLInterface.self)
    }
}

private func UTF8STRING(bytes: UnsafePointer<UInt8>) -> String? {
    let len = strlen(UnsafePointer<Int8>(bytes))
    let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: bytes, count: Int(len)))
    return str
}

internal func _NSXMLParserCurrentParser() -> _CFXMLInterface {
    if let parser = NSXMLParser.currentParser() {
        return parser.interface
    } else {
        return nil
    }
}

internal func _NSXMLParserExternalEntityWithURL(interface: _CFXMLInterface, urlStr: UnsafePointer<Int8>, identifier: UnsafePointer<Int8>, context: _CFXMLInterfaceParserContext, originalLoaderFunction: _CFXMLInterfaceExternalEntityLoader) -> _CFXMLInterfaceParserInput {
    let parser = interface.parser
    let policy = parser.externalEntityResolvingPolicy
    var a: NSURL?
    if let allowedEntityURLs = parser.allowedExternalEntityURLs {
        if let url = NSURL(string: String(urlStr)) {
            a = url
            if let scheme = url.scheme {
                if scheme == "file" {
                    a = NSURL(fileURLWithPath: url.path!)
                }
            }
        }
        if let url = a {
            let allowed = allowedEntityURLs.contains(url)
            if allowed || policy != .ResolveExternalEntitiesSameOriginOnly {
                if allowed {
                    return originalLoaderFunction(urlStr, identifier, context)
                }
            }
        }
    }
    
    switch policy {
    case .ResolveExternalEntitiesSameOriginOnly:
        guard let url = parser._url else { break }
        
        if a == nil {
            a = NSURL(string: String(urlStr))
        }
        
        guard let aUrl = a else { break }
        
        var matches: Bool
        if let aHost = aUrl.host, host = url.host {
            matches = host == aHost
        } else {
            return nil
        }
        
        if matches {
            if let aPort = aUrl.port, port = url.port {
                matches = port == aPort
            } else {
                return nil
            }
        }
        
        if matches {
            if let aScheme = aUrl.scheme, scheme = url.scheme {
                matches = scheme == aScheme
            } else {
                return nil
            }
        }
        
        if !matches {
            return nil
        }
        break
    case .ResolveExternalEntitiesAlways:
        break
    case .ResolveExternalEntitiesNever:
        return nil
    case .ResolveExternalEntitiesNoNetwork:
        return _CFXMLInterfaceNoNetExternalEntityLoader(urlStr, identifier, context)
    }
    
    return originalLoaderFunction(urlStr, identifier, context)
}

internal func _NSXMLParserGetContext(ctx: _CFXMLInterface) -> _CFXMLInterfaceParserContext {
    return ctx.parser._parserContext
}

internal func _NSXMLParserInternalSubset(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, ExternalID: UnsafePointer<UInt8>, SystemID: UnsafePointer<UInt8>) -> Void {
    _CFXMLInterfaceSAX2InternalSubset(ctx.parser._parserContext, name, ExternalID, SystemID)
}

internal func _NSXMLParserIsStandalone(ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceIsStandalone(ctx.parser._parserContext)
}

internal func _NSXMLParserHasInternalSubset(ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceHasInternalSubset(ctx.parser._parserContext)
}

internal func _NSXMLParserHasExternalSubset(ctx: _CFXMLInterface) -> Int32 {
    return _CFXMLInterfaceHasExternalSubset(ctx.parser._parserContext)
}

internal func _NSXMLParserGetEntity(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>) -> _CFXMLInterfaceEntity {
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
                    _NSXMLParserCharacters(ctx, ch: UnsafePointer<UInt8>(data.bytes), len: Int32(data.length))
                }
            }
        }
    }
    return entity
}

internal func _NSXMLParserNotationDecl(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, publicId: UnsafePointer<UInt8>, systemId: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let notationName = UTF8STRING(name)!
        let publicIDString = UTF8STRING(publicId)
        let systemIDString = UTF8STRING(systemId)
        delegate.parser(parser, foundNotationDeclarationWithName: notationName, publicID: publicIDString, systemID: systemIDString)
    }
}

internal func _NSXMLParserAttributeDecl(ctx: _CFXMLInterface, elem: UnsafePointer<UInt8>, fullname: UnsafePointer<UInt8>, type: Int32, def: Int32, defaultValue: UnsafePointer<UInt8>, tree: _CFXMLInterfaceEnumeration) -> Void {
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

internal func _NSXMLParserElementDecl(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, type: Int32, content: _CFXMLInterfaceElementContent) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let nameString = UTF8STRING(name)!
        let modelString = "" // FIXME!
        delegate.parser(parser, foundElementDeclarationWithName: nameString, model: modelString)
    }
}

internal func _NSXMLParserUnparsedEntityDecl(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, publicId: UnsafePointer<UInt8>, systemId: UnsafePointer<UInt8>, notationName: UnsafePointer<UInt8>) -> Void {
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

internal func _NSXMLParserStartDocument(ctx: _CFXMLInterface) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parserDidStartDocument(parser)
    }
}

internal func _NSXMLParserEndDocument(ctx: _CFXMLInterface) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parserDidEndDocument(parser)
    }
}

internal func _colonSeparatedStringFromPrefixAndSuffix(prefix: UnsafePointer<UInt8>, _ prefixlen: UInt, _ suffix: UnsafePointer<UInt8>, _ suffixLen: UInt) -> String {
    let prefixString = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: prefix, count: Int(prefixlen)))
    let suffixString = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: suffix, count: Int(suffixLen)))
    return "\(prefixString!):\(suffixString!)"
}

internal func _NSXMLParserStartElementNs(ctx: _CFXMLInterface, localname: UnsafePointer<UInt8>, prefix: UnsafePointer<UInt8>, URI: UnsafePointer<UInt8>, nb_namespaces: Int32, namespaces: UnsafeMutablePointer<UnsafePointer<UInt8>>, nb_attributes: Int32, nb_defaulted: Int32, attributes: UnsafeMutablePointer<UnsafePointer<UInt8>>) -> Void {
    let parser = ctx.parser
    let reportQNameURI = parser.shouldProcessNamespaces
    let reportNamespaces = parser.shouldReportNamespacePrefixes
    let prefixLen = prefix == nil ? UInt(strlen(UnsafePointer<Int8>(prefix))) : 0
    let localnameString = (prefixLen == 0 || reportQNameURI) ? UTF8STRING(localname) : nil
    let qualifiedNameString = prefixLen != 0 ? _colonSeparatedStringFromPrefixAndSuffix(prefix, UInt(prefixLen), localname, UInt(strlen(UnsafePointer<Int8>(localname)))) : localnameString
    let namespaceURIString = reportQNameURI ? UTF8STRING(URI) : nil
    
    var nsDict = [String:String]()
    var attrDict = [String:String]()
    if nb_attributes + nb_namespaces > 0 {
        for idx in 0.stride(to: Int(nb_namespaces) * 2, by: 2) {
            var namespaceNameString: String?
            var asAttrNamespaceNameString: String?
            if namespaces[idx] != nil {
                if reportNamespaces {
                    namespaceNameString = UTF8STRING(namespaces[idx])
                }
                asAttrNamespaceNameString = _colonSeparatedStringFromPrefixAndSuffix("xmlns", 5, namespaces[idx], UInt(strlen(UnsafePointer<Int8>(namespaces[idx]))))
            } else {
                namespaceNameString = ""
                asAttrNamespaceNameString = "xmlns"
            }
            let namespaceValueString = namespaces[idx + 1] == nil ? UTF8STRING(namespaces[idx + 1]) : ""
            if reportNamespaces {
                if let k = namespaceNameString, v = namespaceValueString {
                    nsDict[k] = v
                }
            }
            if !reportQNameURI {
                if let k = asAttrNamespaceNameString, v = namespaceValueString {
                    attrDict[k] = v
                }
            }
        }
    }
    
    if reportNamespaces {
        parser._pushNamespaces(nsDict)
    }
    
    for idx in 0.stride(to: Int(nb_attributes) * 5, by: 5) {
        if attributes[idx] == nil {
            continue
        }
        var attributeQName: String
        let attrLocalName = attributes[idx]
        let attrPrefix = attributes[idx + 1]
        let attrPrefixLen = attrPrefix == nil ? strlen(UnsafePointer<Int8>(attrPrefix)) : 0
        if attrPrefixLen != 0 {
            attributeQName = _colonSeparatedStringFromPrefixAndSuffix(attrPrefix, UInt(attrPrefixLen), attrLocalName, UInt(strlen((UnsafePointer<Int8>(attrLocalName)))))
        } else {
            attributeQName = UTF8STRING(attrLocalName)!
        }
        // idx+2 = URI, which we throw away
        // idx+3 = value, i+4 = endvalue
        // By using XML_PARSE_NOENT the attribute value string will already have entities resolved
        var attributeValue = ""
        if attributes[idx + 3] != nil && attributes[idx + 4] != nil {
            let numBytesWithoutTerminator = attributes[idx + 4] - attributes[idx + 3]
            let numBytesWithTerminator = numBytesWithoutTerminator + 1
            if numBytesWithoutTerminator != 0 {
                var chars = [Int8](count: numBytesWithTerminator, repeatedValue: 0)
                attributeValue = chars.withUnsafeMutableBufferPointer({ (inout buffer: UnsafeMutableBufferPointer<Int8>) -> String in
                    strncpy(buffer.baseAddress, UnsafePointer<Int8>(attributes[idx + 3]), numBytesWithoutTerminator) //not strlcpy because attributes[i+3] is not Nul terminated
                    return UTF8STRING(UnsafePointer<UInt8>(buffer.baseAddress))!
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

internal func _NSXMLParserEndElementNs(ctx: _CFXMLInterface , localname: UnsafePointer<UInt8>, prefix: UnsafePointer<UInt8>, URI: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    let reportQNameURI = parser.shouldProcessNamespaces
    let prefixLen = prefix == nil ? strlen(UnsafePointer<Int8>(prefix)) : 0
    let localnameString = (prefixLen == 0 || reportQNameURI) ? UTF8STRING(localname) : nil
    let nilStr: String? = nil
    let qualifiedNameString = (prefixLen != 0) ? _colonSeparatedStringFromPrefixAndSuffix(prefix, UInt(prefixLen), localname, UInt(strlen(UnsafePointer<Int8>(localname)))) : nilStr
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

internal func _NSXMLParserCharacters(ctx: _CFXMLInterface, ch: UnsafePointer<UInt8>, len: Int32) -> Void {
    let parser = ctx.parser
    let context = parser._parserContext
    if _CFXMLInterfaceInRecursiveState(context) != 0 {
        _CFXMLInterfaceResetRecursiveState(context)
    } else {
        if let delegate = parser.delegate {
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: ch, count: Int(len)))
            delegate.parser(parser, foundCharacters: str!)
        }
    }
}

internal func _NSXMLParserProcessingInstruction(ctx: _CFXMLInterface, target: UnsafePointer<UInt8>, data: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let targetString = UTF8STRING(target)!
        let dataString = UTF8STRING(data)
        delegate.parser(parser, foundProcessingInstructionWithTarget: targetString, data: dataString)
    }
}

internal func _NSXMLParserCdataBlock(ctx: _CFXMLInterface, value: UnsafePointer<UInt8>, len: Int32) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        delegate.parser(parser, foundCDATA: NSData(bytes: UnsafePointer<Void>(value), length: Int(len)))
    }
}

internal func _NSXMLParserComment(ctx: _CFXMLInterface, value: UnsafePointer<UInt8>) -> Void {
    let parser = ctx.parser
    if let delegate = parser.delegate {
        let comment = UTF8STRING(value)!
        delegate.parser(parser, foundComment: comment)
    }
}

internal func _NSXMLParserExternalSubset(ctx: _CFXMLInterface, name: UnsafePointer<UInt8>, ExternalID: UnsafePointer<UInt8>, SystemID: UnsafePointer<UInt8>) -> Void {
    _CFXMLInterfaceSAX2ExternalSubset(ctx.parser._parserContext, name, ExternalID, SystemID)
}

internal func _structuredErrorFunc(interface: _CFXMLInterface, error: _CFXMLInterfaceError) {
    let err = _CFErrorCreateFromXMLInterface(error)._nsObject
    let parser = interface.parser
    parser._parserError = err
    if let delegate = parser.delegate {
        delegate.parser(parser, parseErrorOccurred: err)
    }
}

public class NSXMLParser : NSObject {
    private var _handler: _CFXMLInterfaceSAXHandler
    internal var _stream: NSInputStream?
    internal var _data: NSData?
    internal var _chunkSize = Int(4096 * 32) // a suitably large number for a decent chunk size
    internal var _haveDetectedEncoding = false
    internal var _bomChunk: NSData?
    private var _parserContext: _CFXMLInterfaceParserContext
    internal var _delegateAborted = false
    internal var _url: NSURL?
    internal var _namespaces = [[String:String]]()
    
    // initializes the parser with the specified URL.
    public convenience init?(contentsOfURL url: NSURL) {
        if url.fileURL {
            if let stream = NSInputStream(URL: url) {
                self.init(stream: stream)
                _url = url
            }
        } else {
            if let data = NSData(contentsOfURL: url) {
                self.init(data: data)
                self._url = url
            }
        }
        return nil
    }
    
    // create the parser from data
    public init(data: NSData) {
        _CFSetupXMLInterface()
        _data = data.copy() as? NSData
        _handler = _CFXMLInterfaceCreateSAXHandler()
        _parserContext = nil
    }
    
    deinit {
        _CFXMLInterfaceDestroySAXHandler(_handler)
        _CFXMLInterfaceDestroyContext(_parserContext)
    }
    
    //create a parser that incrementally pulls data from the specified stream and parses it.
    public init(stream: NSInputStream) {
        _CFSetupXMLInterface()
        _stream = stream
        _handler = _CFXMLInterfaceCreateSAXHandler()
        _parserContext = nil
    }
    
    public weak var delegate: NSXMLParserDelegate?
    
    public var shouldProcessNamespaces: Bool = false
    public var shouldReportNamespacePrefixes: Bool = false
    
    //defaults to NSXMLNodeLoadExternalEntitiesNever
    public var externalEntityResolvingPolicy: NSXMLParserExternalEntityResolvingPolicy = .ResolveExternalEntitiesNever
    
    public var allowedExternalEntityURLs: Set<NSURL>?
    
    internal static func currentParser() -> NSXMLParser? {
        if let current = NSThread.currentThread().threadDictionary["__CurrentNSXMLParser"] {
            return current as? NSXMLParser
        } else {
            return nil
        }
    }
    
    internal static func setCurrentParser(parser: NSXMLParser?) {
        if let p = parser {
            NSThread.currentThread().threadDictionary["__CurrentNSXMLParser"] = p
        } else {
            NSThread.currentThread().threadDictionary.removeValueForKey("__CurrentNSXMLParser")
        }
    }
    
    internal func _handleParseResult(parseResult: Int32) -> Bool {
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
    
    internal func parseData(data: NSData) -> Bool {
        _CFXMLInterfaceSetStructuredErrorFunc(interface, _structuredErrorFunc)
        var result = true
        /* The vast majority of this method just deals with ensuring we do a single parse
         on the first 4 received bytes before continuing on to the actual incremental section */
        if _haveDetectedEncoding {
            var totalLength = data.length
            if let chunk = _bomChunk {
                totalLength += chunk.length
            }
            if (totalLength < 4) {
                if let chunk = _bomChunk {
                    let newData = NSMutableData()
                    newData.appendData(chunk)
                    newData.appendData(data)
                    _bomChunk = newData
                } else {
                    _bomChunk = data
                }
            } else {
                var allExistingData: NSData
                if let chunk = _bomChunk {
                    let newData = NSMutableData()
                    newData.appendData(chunk)
                    newData.appendData(data)
                    allExistingData = newData
                } else {
                    allExistingData = data
                }
                
                var handler: _CFXMLInterfaceSAXHandler = nil
                if delegate != nil {
                    handler = _handler
                }
                
                _parserContext = _CFXMLInterfaceCreatePushParserCtxt(handler, interface, UnsafePointer<Int8>(allExistingData.bytes), 4, nil)
                
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
                    let remainingData = NSData(bytesNoCopy: UnsafeMutablePointer<Void>(allExistingData.bytes.advancedBy(4)), length: totalLength - 4, freeWhenDone: false)
                    parseData(remainingData)
                }
            }
        } else {
            let parseResult = _CFXMLInterfaceParseChunk(_parserContext, UnsafePointer<Int8>(data.bytes), Int32(data.length), 0)
            result = _handleParseResult(parseResult)
        }
        _CFXMLInterfaceSetStructuredErrorFunc(interface, nil)
        return result
    }
    
    internal func parseFromStream() -> Bool {
        var result = true
        NSXMLParser.setCurrentParser(self)
        if let stream = _stream {
            stream.open()
            let buffer = malloc(_chunkSize)
            var len = stream.read(UnsafeMutablePointer<UInt8>(buffer), maxLength: _chunkSize)
            if len != -1 {
                while len > 0 {
                    let data = NSData(bytesNoCopy: buffer, length: len, freeWhenDone: false)
                    result = parseData(data)
                    len = stream.read(UnsafeMutablePointer<UInt8>(buffer), maxLength: _chunkSize)
                }
            } else {
                result = false
            }
            free(buffer)
            stream.close()
        } else if let data = _data {
            let buffer = malloc(_chunkSize)
            var range = NSMakeRange(0, min(_chunkSize, data.length))
            while result {
                data.getBytes(buffer, range: range)
                let chunk = NSData(bytesNoCopy: buffer, length: range.length, freeWhenDone: false)
                result = parseData(chunk)
                if range.location + range.length >= data.length {
                    break
                }
                range = NSMakeRange(range.location + range.length, min(_chunkSize, data.length - (range.location + range.length)))
            }
            free(buffer)
        } else {
            result = false
        }
        NSXMLParser.setCurrentParser(nil)
        return result
    }
    
    // called to start the event-driven parse. Returns YES in the event of a successful parse, and NO in case of error.
    public func parse() -> Bool {
        return parseFromStream()
    }
    
    // called by the delegate to stop the parse. The delegate will get an error message sent to it.
    public func abortParsing() {
        if _parserContext != nil {
            _CFXMLInterfaceStopParser(_parserContext)
            _delegateAborted = true
        }
    }
    
    internal var _parserError: NSError?
    /*@NSCopying*/ public var parserError: NSError? { return _parserError } // can be called after a parse is over to determine parser state.
    
    //Toggles between disabling external entities entirely, and the current setting of the 'externalEntityResolvingPolicy'.
    //The 'externalEntityResolvingPolicy' property should be used instead of this, unless targeting 10.9/7.0 or earlier
    public var shouldResolveExternalEntities: Bool = false
    
    // Once a parse has begun, the delegate may be interested in certain parser state. These methods will only return meaningful information during parsing, or after an error has occurred.
    public var publicID: String? { return nil }
    public var systemID: String? { return nil }
    public var lineNumber: Int { return Int(_CFXMLInterfaceSAX2GetLineNumber(_parserContext)) }
    public var columnNumber: Int { return Int(_CFXMLInterfaceSAX2GetColumnNumber(_parserContext)) }
    
    internal func _pushNamespaces(ns: [String:String]) {
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
public protocol NSXMLParserDelegate : class {
    
    // Document handling methods
    func parserDidStartDocument(parser: NSXMLParser)
    // sent when the parser begins parsing of the document.
    func parserDidEndDocument(parser: NSXMLParser)
    // sent when the parser has completed parsing. If this is encountered, the parse was successful.
    
    // DTD handling methods for various declarations.
    func parser(parser: NSXMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(parser: NSXMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?)
    
    func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?)
    
    func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String)
    
    func parser(parser: NSXMLParser, foundInternalEntityDeclarationWithName name: String, value: String?)
    
    func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?)
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    // sent when the parser finds an element start tag.
    // In the case of the cvslog tag, the following is what the delegate receives:
    //   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
    // In the case of the radar tag, the following is what's passed in:
    //    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
    // If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    // sent when an end tag is encountered. The various parameters are supplied as above.
    
    func parser(parser: NSXMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String)
    // sent when the parser first sees a namespace attribute.
    // In the case of the cvslog tag, before the didStartElement:, you'd get one of these with prefix == @"" and namespaceURI == @"http://xml.apple.com/cvslog" (i.e. the default namespace)
    // In the case of the radar:radar tag, before the didStartElement: you'd get one of these with prefix == @"radar" and namespaceURI == @"http://xml.apple.com/radar"
    
    func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String)
    // sent when the namespace prefix in question goes out of scope.
    
    func parser(parser: NSXMLParser, foundCharacters string: String)
    // This returns the string of the characters encountered thus far. You may not necessarily get the longest character run. The parser reserves the right to hand these to the delegate as potentially many calls in a row to -parser:foundCharacters:
    
    func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String)
    // The parser reports ignorable whitespace in the same way as characters it's found.
    
    func parser(parser: NSXMLParser, foundProcessingInstructionWithTarget target: String, data: String?)
    // The parser reports a processing instruction to you using this method. In the case above, target == @"xml-stylesheet" and data == @"type='text/css' href='cvslog.css'"
    
    func parser(parser: NSXMLParser, foundComment comment: String)
    // A comment (Text in a <!-- --> block) is reported to the delegate as a single string
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData)
    // this reports a CDATA block to the delegate as an NSData.
    
    func parser(parser: NSXMLParser, resolveExternalEntityName name: String, systemID: String?) -> NSData?
    // this gives the delegate an opportunity to resolve an external entity itself and reply with the resulting data.
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError)
    // ...and this reports a fatal error to the delegate. The parser will stop parsing.
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError)
}

extension NSXMLParserDelegate {
    
    func parserDidStartDocument(parser: NSXMLParser) { }
    func parserDidEndDocument(parser: NSXMLParser) { }
    
    func parser(parser: NSXMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(parser: NSXMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) { }
    
    func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) { }
    
    func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String) { }
    
    func parser(parser: NSXMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { }
    
    func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) { }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { }
    
    func parser(parser: NSXMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) { }
    
    func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String) { }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) { }
    
    func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String) { }
    
    func parser(parser: NSXMLParser, foundProcessingInstructionWithTarget target: String, data: String?) { }
    
    func parser(parser: NSXMLParser, foundComment comment: String) { }
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) { }
    
    func parser(parser: NSXMLParser, resolveExternalEntityName name: String, systemID: String?) -> NSData? { return nil }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) { }
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) { }
}


// If validation is on, this will report a fatal validation error to the delegate. The parser will stop parsing.
public let NSXMLParserErrorDomain: String = "NSXMLParserErrorDomain" // for use with NSError.

// Error reporting
public enum NSXMLParserError : Int {
    
    case InternalError
    case OutOfMemoryError
    case DocumentStartError
    case EmptyDocumentError
    case PrematureDocumentEndError
    case InvalidHexCharacterRefError
    case InvalidDecimalCharacterRefError
    case InvalidCharacterRefError
    case InvalidCharacterError
    case CharacterRefAtEOFError
    case CharacterRefInPrologError
    case CharacterRefInEpilogError
    case CharacterRefInDTDError
    case EntityRefAtEOFError
    case EntityRefInPrologError
    case EntityRefInEpilogError
    case EntityRefInDTDError
    case ParsedEntityRefAtEOFError
    case ParsedEntityRefInPrologError
    case ParsedEntityRefInEpilogError
    case ParsedEntityRefInInternalSubsetError
    case EntityReferenceWithoutNameError
    case EntityReferenceMissingSemiError
    case ParsedEntityRefNoNameError
    case ParsedEntityRefMissingSemiError
    case UndeclaredEntityError
    case UnparsedEntityError
    case EntityIsExternalError
    case EntityIsParameterError
    case UnknownEncodingError
    case EncodingNotSupportedError
    case StringNotStartedError
    case StringNotClosedError
    case NamespaceDeclarationError
    case EntityNotStartedError
    case EntityNotFinishedError
    case LessThanSymbolInAttributeError
    case AttributeNotStartedError
    case AttributeNotFinishedError
    case AttributeHasNoValueError
    case AttributeRedefinedError
    case LiteralNotStartedError
    case LiteralNotFinishedError
    case CommentNotFinishedError
    case ProcessingInstructionNotStartedError
    case ProcessingInstructionNotFinishedError
    case NotationNotStartedError
    case NotationNotFinishedError
    case AttributeListNotStartedError
    case AttributeListNotFinishedError
    case MixedContentDeclNotStartedError
    case MixedContentDeclNotFinishedError
    case ElementContentDeclNotStartedError
    case ElementContentDeclNotFinishedError
    case XMLDeclNotStartedError
    case XMLDeclNotFinishedError
    case ConditionalSectionNotStartedError
    case ConditionalSectionNotFinishedError
    case ExternalSubsetNotFinishedError
    case DOCTYPEDeclNotFinishedError
    case MisplacedCDATAEndStringError
    case CDATANotFinishedError
    case MisplacedXMLDeclarationError
    case SpaceRequiredError
    case SeparatorRequiredError
    case NMTOKENRequiredError
    case NAMERequiredError
    case PCDATARequiredError
    case URIRequiredError
    case PublicIdentifierRequiredError
    case LTRequiredError
    case GTRequiredError
    case LTSlashRequiredError
    case EqualExpectedError
    case TagNameMismatchError
    case UnfinishedTagError
    case StandaloneValueError
    case InvalidEncodingNameError
    case CommentContainsDoubleHyphenError
    case InvalidEncodingError
    case ExternalStandaloneEntityError
    case InvalidConditionalSectionError
    case EntityValueRequiredError
    case NotWellBalancedError
    case ExtraContentError
    case InvalidCharacterInEntityError
    case ParsedEntityRefInInternalError
    case EntityRefLoopError
    case EntityBoundaryError
    case InvalidURIError
    case URIFragmentError
    case NoDTDError
    case DelegateAbortedParseError
}

