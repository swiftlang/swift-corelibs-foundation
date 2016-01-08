// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*	CFXMLInterface.c
	Copyright (c) 2015 Apple Inc. and the Swift project authors
 */

#include <CoreFoundation/CFRuntime.h>
#include <libxml/globals.h>
#include <libxml/xmlerror.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/tree.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlsave.h>
#include <libxml/xpath.h>
#include "CFInternal.h"

/*
 libxml2 does not have nullability annotations and does not import well into swift when given potentially differing versions of the library that might be installed on the host operating system. This is a simple C wrapper to simplify some of that interface layer to libxml2.
 */

CFIndex _kCFXMLInterfaceRecover = XML_PARSE_RECOVER;
CFIndex _kCFXMLInterfaceNoEnt = XML_PARSE_NOENT;
CFIndex _kCFXMLInterfaceDTDLoad = XML_PARSE_DTDLOAD;
CFIndex _kCFXMLInterfaceDTDAttr = XML_PARSE_DTDATTR;
CFIndex _kCFXMLInterfaceDTDValid = XML_PARSE_DTDVALID;
CFIndex _kCFXMLInterfaceNoError = XML_PARSE_NOERROR;
CFIndex _kCFXMLInterfaceNoWarning = XML_PARSE_NOWARNING;
CFIndex _kCFXMLInterfacePedantic = XML_PARSE_PEDANTIC;
CFIndex _kCFXMLInterfaceNoBlanks = XML_PARSE_NOBLANKS;
CFIndex _kCFXMLInterfaceSAX1 = XML_PARSE_SAX1;
CFIndex _kCFXMLInterfaceXInclude = XML_PARSE_XINCLUDE;
CFIndex _kCFXMLInterfaceNoNet = XML_PARSE_NONET;
CFIndex _kCFXMLInterfaceNoDict = XML_PARSE_NODICT;
CFIndex _kCFXMLInterfaceNSClean = XML_PARSE_NSCLEAN;
CFIndex _kCFXMLInterfaceNoCdata = XML_PARSE_NOCDATA;
CFIndex _kCFXMLInterfaceNoXIncnode = XML_PARSE_NOXINCNODE;
CFIndex _kCFXMLInterfaceCompact = XML_PARSE_COMPACT;
CFIndex _kCFXMLInterfaceOld10 = XML_PARSE_OLD10;
CFIndex _kCFXMLInterfaceNoBasefix = XML_PARSE_NOBASEFIX;
CFIndex _kCFXMLInterfaceHuge = XML_PARSE_HUGE;
CFIndex _kCFXMLInterfaceOldsax = XML_PARSE_OLDSAX;
CFIndex _kCFXMLInterfaceIgnoreEnc = XML_PARSE_IGNORE_ENC;
CFIndex _kCFXMLInterfaceBigLines = XML_PARSE_BIG_LINES;
CFIndex _kCFXMLTypeDocument = XML_DOCUMENT_NODE;
CFIndex _kCFXMLTypeElement = XML_ELEMENT_NODE;
CFIndex _kCFXMLTypeAttribute = XML_ATTRIBUTE_NODE;
CFIndex _kCFXMLTypeDTD = XML_DTD_NODE;
CFIndex _kCFXMLDocTypeHTML = XML_DOC_HTML;
CFIndex _kCFXMLDTDNodeTypeEntity = XML_ENTITY_DECL;
CFIndex _kCFXMLDTDNodeTypeAttribute = XML_ATTRIBUTE_DECL;
CFIndex _kCFXMLDTDNodeTypeElement = XML_ELEMENT_DECL;
CFIndex _kCFXMLDTDNodeTypeNotation = XML_NOTATION_NODE;

CFIndex _kCFXMLNodePreserveWhitespace = 1 << 25;
CFIndex _kCFXMLNodeCompactEmptyElement = 1 << 2;
CFIndex _kCFXMLNodePrettyPrint = 1 << 17;
CFIndex _kCFXMLNodeLoadExternalEntitiesNever = 1 << 19;
CFIndex _kCFXMLNodeLoadExternalEntitiesAlways = 1 << 14;

static xmlExternalEntityLoader __originalLoader = NULL;

static xmlParserInputPtr _xmlExternalEntityLoader(const char *urlStr, const char * ID, xmlParserCtxtPtr context) {
    _CFXMLInterface parser = __CFSwiftBridge.NSXMLParser.currentParser();
    if (parser != NULL) {
        return __CFSwiftBridge.NSXMLParser._xmlExternalEntityWithURL(parser, urlStr, ID, context, __originalLoader);
    }
    return __originalLoader(urlStr, ID, context);
}

void _CFSetupXMLInterface(void) {
    static dispatch_once_t xmlInitGuard;
    dispatch_once(&xmlInitGuard, ^{
        xmlInitParser();
        // set up the external entity loader
        __originalLoader = xmlGetExternalEntityLoader();
        xmlSetExternalEntityLoader(_xmlExternalEntityLoader);
    });
}

_CFXMLInterfaceParserInput _CFXMLInterfaceNoNetExternalEntityLoader(const char *URL, const char *ID, _CFXMLInterfaceParserContext ctxt) {
    return xmlNoNetExternalEntityLoader(URL, ID, ctxt);
}

static void _errorCallback(void *ctx, const char *msg, ...) {
    xmlParserCtxtPtr context = __CFSwiftBridge.NSXMLParser.getContext((_CFXMLInterface)ctx);
    xmlErrorPtr error = xmlCtxtGetLastError(context);
// TODO: reporting
//    _reportError(error, (_CFXMLInterface)ctx);
}

_CFXMLInterfaceSAXHandler _CFXMLInterfaceCreateSAXHandler() {
    _CFXMLInterfaceSAXHandler saxHandler = (_CFXMLInterfaceSAXHandler)calloc(1, sizeof(struct _xmlSAXHandler));
    saxHandler->internalSubset = (internalSubsetSAXFunc)__CFSwiftBridge.NSXMLParser.internalSubset;
    saxHandler->isStandalone = (isStandaloneSAXFunc)__CFSwiftBridge.NSXMLParser.isStandalone;
    
    saxHandler->hasInternalSubset = (hasInternalSubsetSAXFunc)__CFSwiftBridge.NSXMLParser.hasInternalSubset;
    saxHandler->hasExternalSubset = (hasExternalSubsetSAXFunc)__CFSwiftBridge.NSXMLParser.hasExternalSubset;
    
    saxHandler->getEntity = (getEntitySAXFunc)__CFSwiftBridge.NSXMLParser.getEntity;
    
    saxHandler->notationDecl = (notationDeclSAXFunc)__CFSwiftBridge.NSXMLParser.notationDecl;
    saxHandler->attributeDecl = (attributeDeclSAXFunc)__CFSwiftBridge.NSXMLParser.attributeDecl;
    saxHandler->elementDecl = (elementDeclSAXFunc)__CFSwiftBridge.NSXMLParser.elementDecl;
    saxHandler->unparsedEntityDecl = (unparsedEntityDeclSAXFunc)__CFSwiftBridge.NSXMLParser.unparsedEntityDecl;
    saxHandler->startDocument = (startDocumentSAXFunc)__CFSwiftBridge.NSXMLParser.startDocument;
    saxHandler->endDocument = (endDocumentSAXFunc)__CFSwiftBridge.NSXMLParser.endDocument;
    saxHandler->startElementNs = (startElementNsSAX2Func)__CFSwiftBridge.NSXMLParser.startElementNs;
    saxHandler->endElementNs = (endElementNsSAX2Func)__CFSwiftBridge.NSXMLParser.endElementNs;
    saxHandler->characters = (charactersSAXFunc)__CFSwiftBridge.NSXMLParser.characters;
    saxHandler->processingInstruction = (processingInstructionSAXFunc)__CFSwiftBridge.NSXMLParser.processingInstruction;
    saxHandler->error = _errorCallback;
    saxHandler->cdataBlock = (cdataBlockSAXFunc)__CFSwiftBridge.NSXMLParser.cdataBlock;
    saxHandler->comment = (commentSAXFunc)__CFSwiftBridge.NSXMLParser.comment;
    
    saxHandler->externalSubset = (externalSubsetSAXFunc)__CFSwiftBridge.NSXMLParser.externalSubset;
    
    saxHandler->initialized = XML_SAX2_MAGIC; // make sure start/endElementNS are used
    return saxHandler;
}

void _CFXMLInterfaceDestroySAXHandler(_CFXMLInterfaceSAXHandler handler) {
    free(handler);
}

void _CFXMLInterfaceSetStructuredErrorFunc(_CFXMLInterface ctx, _CFXMLInterfaceStructuredErrorFunc handler) {
    xmlSetStructuredErrorFunc(ctx, (xmlStructuredErrorFunc)handler);
}

_CFXMLInterfaceParserContext _CFXMLInterfaceCreatePushParserCtxt(_CFXMLInterfaceSAXHandler sax, _CFXMLInterface user_data, const char *chunk, int size, const char *filename) {
    return xmlCreatePushParserCtxt(sax, user_data, chunk, size, filename);
}

void _CFXMLInterfaceCtxtUseOptions(_CFXMLInterfaceParserContext ctx, CFIndex options) {
    xmlCtxtUseOptions(ctx, options);
}

int _CFXMLInterfaceParseChunk(_CFXMLInterfaceParserContext ctxt, const char *chunk, int size, int terminate) {
    return xmlParseChunk(ctxt, chunk, size, terminate);
}

void _CFXMLInterfaceStopParser(_CFXMLInterfaceParserContext ctx) {
    xmlStopParser(ctx);
}

void _CFXMLInterfaceDestroyContext(_CFXMLInterfaceParserContext ctx) {
    if (ctx == NULL) return;
    if (ctx->myDoc) {
        xmlFreeDoc(ctx->myDoc);
    }
    xmlFreeParserCtxt(ctx);
}

int _CFXMLInterfaceSAX2GetLineNumber(_CFXMLInterfaceParserContext ctx) {
    if (ctx == NULL) return 0;
    return xmlSAX2GetLineNumber(ctx);
}

int _CFXMLInterfaceSAX2GetColumnNumber(_CFXMLInterfaceParserContext ctx) {
    if (ctx == NULL) return 0;
    return xmlSAX2GetColumnNumber(ctx);
}

void _CFXMLInterfaceSAX2InternalSubset(_CFXMLInterfaceParserContext ctx,
                                       const unsigned char *name,
                                       const unsigned char *ExternalID,
                                       const unsigned char *SystemID) {
    if (ctx != NULL) xmlSAX2InternalSubset(ctx, name, ExternalID, SystemID);
}

void _CFXMLInterfaceSAX2ExternalSubset(_CFXMLInterfaceParserContext ctx,
                                       const unsigned char *name,
                                       const unsigned char *ExternalID,
                                       const unsigned char *SystemID) {
    if (ctx != NULL) xmlSAX2ExternalSubset(ctx, name, ExternalID, SystemID);
}

int _CFXMLInterfaceIsStandalone(_CFXMLInterfaceParserContext ctx) {
    if (ctx != NULL) return ctx->myDoc->standalone;
    return 0;
}

int _CFXMLInterfaceHasInternalSubset(_CFXMLInterfaceParserContext ctx) {
    if (ctx != NULL) return ctx->myDoc->intSubset != NULL;
    return 0;
}

int _CFXMLInterfaceHasExternalSubset(_CFXMLInterfaceParserContext ctx) {
    if (ctx != NULL) return ctx->myDoc->extSubset != NULL;
    return 0;
}

_CFXMLInterfaceEntity _CFXMLInterfaceGetPredefinedEntity(const unsigned char *name) {
    return xmlGetPredefinedEntity(name);
}

_CFXMLInterfaceEntity _CFXMLInterfaceSAX2GetEntity(_CFXMLInterfaceParserContext ctx, const unsigned char *name) {
    if (ctx == NULL) return NULL;
    _CFXMLInterfaceEntity entity = xmlSAX2GetEntity(ctx, name);
    if (entity && ctx->instate == XML_PARSER_CONTENT) ctx->_private = (void *)1;
    return entity;
}

int _CFXMLInterfaceInRecursiveState(_CFXMLInterfaceParserContext ctx) {
    return ctx->_private == (void *)1;
}

void _CFXMLInterfaceResetRecursiveState(_CFXMLInterfaceParserContext ctx) {
    ctx->_private = NULL;
}

int _CFXMLInterfaceHasDocument(_CFXMLInterfaceParserContext ctx) {
    if (ctx == NULL) return 0;
    return ctx->myDoc != NULL;
}

void _CFXMLInterfaceFreeEnumeration(_CFXMLInterfaceEnumeration enumeration) {
    if (enumeration == NULL) return;
    xmlFreeEnumeration(enumeration);
}

void _CFXMLInterfaceSAX2UnparsedEntityDecl(_CFXMLInterfaceParserContext ctx, const unsigned char *name, const unsigned char *publicId, const unsigned char *systemId, const unsigned char *notationName) {
    if (ctx == NULL) return;
    xmlSAX2UnparsedEntityDecl(ctx, name, publicId, systemId, notationName);
}

CFErrorRef _CFErrorCreateFromXMLInterface(_CFXMLInterfaceError err) {
    return CFErrorCreate(kCFAllocatorSystemDefault, CFSTR("NSXMLParserErrorDomain"), err->code, nil);
}

_CFXMLNodePtr _CFXMLNewNode(_CFXMLNamespacePtr namespace, const char* name) {
    return xmlNewNode(namespace, (const xmlChar*)name);
}

_CFXMLNodePtr _CFXMLCopyNode(_CFXMLNodePtr node, bool recursive) {
    return xmlCopyNode(node, recursive ? 1 : 0);
}

_CFXMLDocPtr _CFXMLNewDoc(const unsigned char* version) {
    return xmlNewDoc(version);
}

_CFXMLNodePtr _CFXMLNewProcessingInstruction(const unsigned char* name, const unsigned char* value) {
    return xmlNewPI(name, value);
}

_CFXMLNodePtr _CFXMLNewTextNode(const unsigned char* value) {
    return xmlNewText(value);
}

_CFXMLNodePtr _CFXMLNewComment(const unsigned char* value) {
    return xmlNewComment(value);
}

_CFXMLNodePtr _CFXMLNewProperty(_CFXMLNodePtr node, const unsigned char* name, const unsigned char* value) {
    return xmlNewProp(node, name, value);
}

_CFXMLNamespacePtr _CFXMLNewNamespace(_CFXMLNodePtr node, const unsigned char* uri, const unsigned char* prefix) {
    return xmlNewNs(node, uri, prefix);
}

CF_RETURNS_RETAINED CFStringRef _CFXMLNodeURI(_CFXMLNodePtr node) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    switch (nodePtr->type) {
        case XML_ATTRIBUTE_NODE:
        case XML_ELEMENT_NODE:
            return CFStringCreateWithCString(NULL, (const char*)nodePtr->ns->href, kCFStringEncodingUTF8);

        case XML_DOCUMENT_NODE:
        {
            xmlDocPtr doc = (xmlDocPtr)node;
            return CFStringCreateWithCString(NULL, (const char*)doc->URL, kCFStringEncodingUTF8);
        }

        default:
            return NULL;
    }
}

void _CFXMLNodeSetURI(_CFXMLNodePtr node, const unsigned char* URI) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    switch (nodePtr->type) {
        case XML_ATTRIBUTE_NODE:
        case XML_ELEMENT_NODE:

            if (!URI) {
                if (nodePtr->ns) {
                    xmlFree(nodePtr->ns);
                }
                nodePtr->ns = NULL;
                return;
            }

            xmlNsPtr ns = xmlSearchNsByHref(nodePtr->doc, nodePtr, URI);
            if (!ns) {
                if (nodePtr->ns && (nodePtr->ns->href == NULL)) {
                    nodePtr->ns->href = xmlStrdup(URI);
                    return;
                }

                ns = xmlNewNs(nodePtr, URI, NULL);
            }

            xmlSetNs(nodePtr, ns);
            break;

        case XML_DOCUMENT_NODE:
        {
            xmlDocPtr doc = (xmlDocPtr)node;
            if (doc->URL) {
                xmlFree((xmlChar*)doc->URL);
            }
            doc->URL = URI;
        }
            break;

        default:
            return;
    }
}

void _CFXMLNodeSetPrivateData(_CFXMLNodePtr node, void* data) {
    ((xmlNodePtr)node)->_private = data;
}

void* _Nullable  _CFXMLNodeGetPrivateData(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->_private;
}

_CFXMLNodePtr _CFXMLNodeProperties(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->properties;
}

CFIndex _CFXMLNodeGetType(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->type;
}

const char* _CFXMLNodeGetName(_CFXMLNodePtr node) {
    return (const char*)(((xmlNodePtr)node)->name);
}

void _CFXMLNodeSetName(_CFXMLNodePtr node, const char* name) {
    xmlNodeSetName(node, (const xmlChar*)name);
}

CFStringRef _CFXMLNodeGetContent(_CFXMLNodePtr node) {
    xmlChar* content = xmlNodeGetContent(node);
    if (content == NULL) {
        return NULL;
    }
    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)content, kCFStringEncodingUTF8);
    xmlFree(content);

    return result;
}

void _CFXMLNodeSetContent(_CFXMLNodePtr node, const unsigned char* _Nullable  content) {
    if (content == NULL) {
        xmlNodeSetContent(node, nil);
        return;
    }

    xmlNodeSetContent(node, content);
}

_CFXMLDocPtr _CFXMLNodeGetDocument(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->doc;
}

CFStringRef _CFXMLEncodeEntities(_CFXMLDocPtr doc, const unsigned char* string) {
    if (!string) {
        return NULL;
    }
    
    const xmlChar* stringResult = xmlEncodeEntitiesReentrant(doc, string);
    
    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)stringResult, kCFStringEncodingUTF8);

    xmlFree((xmlChar*)stringResult);

    return result;
}

void _CFXMLUnlinkNode(_CFXMLNodePtr node) {
    xmlUnlinkNode(node);
}

_CFXMLNodePtr _CFXMLNodeGetFirstChild(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->children;
}

_CFXMLNodePtr _CFXMLNodeGetLastChild(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->last;
}

_CFXMLNodePtr _CFXMLNodeGetNextSibling(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->next;
}

_CFXMLNodePtr _CFXMLNodeGetPrevSibling(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->prev;
}

_CFXMLNodePtr _CFXMLNodeGetParent(_CFXMLNodePtr node) {
    return ((xmlNodePtr)node)->parent;
}

bool _CFXMLDocStandalone(_CFXMLDocPtr doc) {
    return ((xmlDocPtr)doc)->standalone == 1;
}
void _CFXMLDocSetStandalone(_CFXMLDocPtr doc, bool standalone) {
    ((xmlDocPtr)doc)->standalone = standalone ? 1 : 0;
}

_CFXMLNodePtr _CFXMLDocRootElement(_CFXMLDocPtr doc) {
    return xmlDocGetRootElement(doc);
}

void _CFXMLDocSetRootElement(_CFXMLDocPtr doc, _CFXMLNodePtr node) {
    xmlDocSetRootElement(doc, node);
}

CF_RETURNS_RETAINED CFStringRef _CFXMLDocCharacterEncoding(_CFXMLDocPtr doc) {
    return CFStringCreateWithCString(NULL, (const char*)((xmlDocPtr)doc)->encoding, kCFStringEncodingUTF8);
}

void _CFXMLDocSetCharacterEncoding(_CFXMLDocPtr doc,  const unsigned char* _Nullable  encoding) {
    xmlDocPtr docPtr = (xmlDocPtr)doc;

    if (docPtr->encoding) {
        xmlFree((xmlChar*)docPtr->encoding);
    }

    docPtr->encoding = encoding;
}

CF_RETURNS_RETAINED CFStringRef _CFXMLDocVersion(_CFXMLDocPtr doc) {
    return CFStringCreateWithCString(NULL, (const char*)((xmlDocPtr)doc)->version, kCFStringEncodingUTF8);
}

void _CFXMLDocSetVersion(_CFXMLDocPtr doc, const unsigned char* version) {
    xmlDocPtr docPtr = (xmlDocPtr)doc;

    if (docPtr->version) {
        xmlFree((xmlChar*)docPtr->version);
    }

    docPtr->version = xmlStrdup(version);
}

int _CFXMLDocProperties(_CFXMLDocPtr doc) {
    return ((xmlDocPtr)doc)->properties;
}

void _CFXMLDocSetProperties(_CFXMLDocPtr doc, int newProperties) {
    ((xmlDocPtr)doc)->properties = newProperties;
}

CFIndex _CFXMLNodeGetElementChildCount(_CFXMLNodePtr node) {
    return xmlChildElementCount(node);
}

void _CFXMLNodeAddChild(_CFXMLNodePtr node, _CFXMLNodePtr child) {
    xmlAddChild(node, child);
}

void _CFXMLNodeAddPrevSibling(_CFXMLNodePtr node, _CFXMLNodePtr prevSibling) {
    xmlAddPrevSibling(node, prevSibling);
}

void _CFXMLNodeAddNextSibling(_CFXMLNodePtr node, _CFXMLNodePtr nextSibling) {
    xmlAddNextSibling(node, nextSibling);
}

void _CFXMLNodeReplaceNode(_CFXMLNodePtr node, _CFXMLNodePtr replacement) {
    xmlReplaceNode(node, replacement);
}

_CFXMLEntityPtr _CFXMLGetDocEntity(_CFXMLDocPtr doc, const char* entity) {
    return xmlGetDocEntity(doc, (const xmlChar*)entity);
}

_CFXMLEntityPtr _CFXMLGetDTDEntity(_CFXMLDocPtr doc, const char* entity) {
    return xmlGetDtdEntity(doc, (const xmlChar*)entity);
}

_CFXMLEntityPtr _CFXMLGetParameterEntity(_CFXMLDocPtr doc, const char* entity) {
    return xmlGetParameterEntity(doc, (const xmlChar*)entity);
}

CFStringRef _CFXMLGetEntityContent(_CFXMLEntityPtr entity) {
    const xmlChar* content = ((xmlEntityPtr)entity)->content;
    if (!content) {
        return NULL;
    }

    CFIndex length = ((xmlEntityPtr)entity)->length;
    CFStringRef result = CFStringCreateWithBytes(NULL, content, length, kCFStringEncodingUTF8, false);

    return result;
}

CFStringRef _CFXMLStringWithOptions(_CFXMLNodePtr node, uint32_t options) {
    xmlBufferPtr buffer = xmlBufferCreate();

    uint32_t xmlOptions = XML_SAVE_AS_XML;

    if (options & _kCFXMLNodePreserveWhitespace) {
        xmlOptions |= XML_SAVE_WSNONSIG;
    }

    if (!(options & _kCFXMLNodeCompactEmptyElement)) {
        xmlOptions |= XML_SAVE_NO_EMPTY;
    }

    if (options & _kCFXMLNodePrettyPrint) {
        xmlOptions |= XML_SAVE_FORMAT;
    }

    xmlSaveCtxtPtr ctx = xmlSaveToBuffer(buffer, "utf-8", xmlOptions);
    xmlSaveTree(ctx, node);
    int error = xmlSaveClose(ctx);

    if (error == -1) {
        return CFSTR("");
    }

    const xmlChar* bufferContents = xmlBufferContent(buffer);

    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)bufferContents, kCFStringEncodingUTF8);

    xmlBufferFree(buffer);

    return result;
}

CF_RETURNS_RETAINED CFArrayRef _CFXMLNodesForXPath(_CFXMLNodePtr node, const unsigned char* xpath) {

    if (((xmlNodePtr)node)->doc == NULL) {
        return NULL;
    }

    xmlXPathContextPtr context = xmlXPathNewContext(((xmlNodePtr)node)->doc);
    xmlXPathObjectPtr evalResult = xmlXPathNodeEval(node, xpath, context);

    xmlNodeSetPtr nodes = evalResult->nodesetval;

    int count = nodes->nodeNr;

    CFMutableArrayRef results = CFArrayCreateMutable(NULL, count, NULL);
    for (int i = 0; i < count; i++) {
        CFArrayAppendValue(results, nodes->nodeTab[i]);
    }

    xmlFree(context);
    xmlFree(evalResult);

    return results;
}

_CFXMLNodePtr _CFXMLNodeHasProp(_CFXMLNodePtr node, const unsigned char* propertyName) {
    return xmlHasProp(node, propertyName);
}

_CFXMLDocPtr _CFXMLDocPtrFromDataWithOptions(CFDataRef data, int options) {
    uint32_t xmlOptions = 0;

    if ((options & _kCFXMLNodePreserveWhitespace) == 0) {
        xmlOptions |= XML_PARSE_NOBLANKS;
    }

    if (options & _kCFXMLNodeLoadExternalEntitiesNever) {
        xmlOptions &= ~(XML_PARSE_NOENT);
    } else {
        xmlOptions |= XML_PARSE_NOENT;
    }

    if (options & _kCFXMLNodeLoadExternalEntitiesAlways) {
        xmlOptions |= XML_PARSE_DTDLOAD;
    }

    return xmlReadMemory((const char*)CFDataGetBytePtr(data), CFDataGetLength(data), NULL, NULL, xmlOptions);
}

CF_RETURNS_RETAINED CFStringRef _CFXMLNodeLocalName(_CFXMLNodePtr node) {
    int length = 0;
    const xmlChar* result = xmlSplitQName3(((xmlNodePtr)node)->name, &length);
    return CFStringCreateWithCString(NULL, (const char*)result, kCFStringEncodingUTF8);
}

CF_RETURNS_RETAINED CFStringRef _CFXMLNodePrefix(_CFXMLNodePtr node) {
    xmlChar* result = NULL;
    xmlChar* unused = xmlSplitQName2(((xmlNodePtr)node)->name, &result);

    CFStringRef resultString = CFStringCreateWithCString(NULL, (const char*)result, kCFStringEncodingUTF8);
    xmlFree(result);
    xmlFree(unused);

    return resultString;
}

void _CFXMLValidityErrorHandler(void* ctxt, const char* msg, ...);
void _CFXMLValidityErrorHandler(void* ctxt, const char* msg, ...) {
    char* formattedMessage = calloc(1, 1024);

    va_list args;
    va_start(args, msg);
    vsprintf(formattedMessage, msg, args);
    va_end(args);

    CFStringRef message = CFStringCreateWithCString(NULL, formattedMessage, kCFStringEncodingUTF8);
    CFStringAppend(ctxt, message);
    CFRelease(message);
    free(formattedMessage);
}

bool _CFXMLDocValidate(_CFXMLDocPtr doc, CFErrorRef _Nullable * error) {
    CFMutableStringRef errorMessage = CFStringCreateMutable(NULL, 0);

    xmlValidCtxtPtr ctxt = xmlNewValidCtxt();
    ctxt->error = &_CFXMLValidityErrorHandler;
    ctxt->userData = errorMessage;

    int result = xmlValidateDocument(ctxt, doc);

    xmlFreeValidCtxt(ctxt);

    if (result == 0 && error != NULL) {
        CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(NULL, 1, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(userInfo, kCFErrorLocalizedDescriptionKey, errorMessage);

        *error = CFErrorCreate(NULL, CFSTR("NSXMLParserErrorDomain"), 0, userInfo);

        CFRelease(userInfo);
    }

    CFRelease(errorMessage);

    return error != NULL && *error != NULL;
}

void _CFXMLFreeNode(_CFXMLNodePtr node) {
    xmlFreeNode(node);
}

void _CFXMLFreeDocument(_CFXMLDocPtr doc) {
    xmlFreeDoc(doc);
}
