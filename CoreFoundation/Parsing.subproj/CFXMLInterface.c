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