// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*	CFXMLInterface.h
	Copyright (c) 2015 Apple Inc. and the Swift project authors
 */

#if !defined(__COREFOUNDATION_CFXMLINTERFACE__)
#define __COREFOUNDATION_CFXMLINTERFACE__ 1

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFDictionary.h>
#include <CoreFoundation/CFTree.h>
#include <CoreFoundation/CFURL.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN
CF_EXTERN_C_BEGIN

extern CFIndex _kCFXMLInterfaceRecover;
extern CFIndex _kCFXMLInterfaceNoEnt;
extern CFIndex _kCFXMLInterfaceDTDLoad;
extern CFIndex _kCFXMLInterfaceDTDAttr;
extern CFIndex _kCFXMLInterfaceDTDValid;
extern CFIndex _kCFXMLInterfaceNoError;
extern CFIndex _kCFXMLInterfaceNoWarning;
extern CFIndex _kCFXMLInterfacePedantic;
extern CFIndex _kCFXMLInterfaceNoBlanks;
extern CFIndex _kCFXMLInterfaceSAX1;
extern CFIndex _kCFXMLInterfaceXInclude;
extern CFIndex _kCFXMLInterfaceNoNet;
extern CFIndex _kCFXMLInterfaceNoDict;
extern CFIndex _kCFXMLInterfaceNSClean;
extern CFIndex _kCFXMLInterfaceNoCdata;
extern CFIndex _kCFXMLInterfaceNoXIncnode;
extern CFIndex _kCFXMLInterfaceCompact;
extern CFIndex _kCFXMLInterfaceOld10;
extern CFIndex _kCFXMLInterfaceNoBasefix;
extern CFIndex _kCFXMLInterfaceHuge;
extern CFIndex _kCFXMLInterfaceOldsax;
extern CFIndex _kCFXMLInterfaceIgnoreEnc;
extern CFIndex _kCFXMLInterfaceBigLines;

typedef struct _xmlParserInput *_CFXMLInterfaceParserInput;
typedef struct _xmlParserCtxt *_CFXMLInterfaceParserContext;
typedef struct _xmlSAXHandler *_CFXMLInterfaceSAXHandler;
typedef struct _xmlEntity *_CFXMLInterfaceEntity;
typedef struct _xmlEnumeration *_CFXMLInterfaceEnumeration;
typedef struct _xmlElementContent *_CFXMLInterfaceElementContent;
typedef struct _xmlError *_CFXMLInterfaceError;
typedef struct __CFXMLInterface *_CFXMLInterface;

typedef _CFXMLInterfaceParserInput _Nonnull (*_CFXMLInterfaceExternalEntityLoader)(const char *URL, const char *ID, _CFXMLInterfaceParserContext);
typedef void (*_CFXMLInterfaceStructuredErrorFunc)(_CFXMLInterface ctx, _CFXMLInterfaceError error);

void _CFSetupXMLInterface(void);
_CFXMLInterfaceParserInput _CFXMLInterfaceNoNetExternalEntityLoader(const char *URL, const char *ID, _CFXMLInterfaceParserContext ctxt);
_CFXMLInterfaceSAXHandler _CFXMLInterfaceCreateSAXHandler();
void _CFXMLInterfaceDestroySAXHandler(_CFXMLInterfaceSAXHandler handler);
void _CFXMLInterfaceSetStructuredErrorFunc(_CFXMLInterface ctx, _CFXMLInterfaceStructuredErrorFunc _Nullable  handler);
_CFXMLInterfaceParserContext  _CFXMLInterfaceCreatePushParserCtxt(_CFXMLInterfaceSAXHandler _Nullable sax, _CFXMLInterface  user_data, const char * chunk, int size, const char *_Nullable filename);
void _CFXMLInterfaceCtxtUseOptions(_CFXMLInterfaceParserContext _Nullable ctx, CFIndex options);
int _CFXMLInterfaceParseChunk(_CFXMLInterfaceParserContext _Nullable ctxt, const char * chunk, int size, int terminate);
void _CFXMLInterfaceStopParser(_CFXMLInterfaceParserContext _Nullable ctx);
void _CFXMLInterfaceDestroyContext(_CFXMLInterfaceParserContext _Nullable ctx);
int _CFXMLInterfaceSAX2GetColumnNumber(_CFXMLInterfaceParserContext _Nullable ctx);
int _CFXMLInterfaceSAX2GetLineNumber(_CFXMLInterfaceParserContext _Nullable ctx);
void _CFXMLInterfaceSAX2InternalSubset(_CFXMLInterfaceParserContext _Nullable ctx,
                                       const unsigned char * name,
                                       const unsigned char * ExternalID,
                                       const unsigned char * SystemID);
void _CFXMLInterfaceSAX2ExternalSubset(_CFXMLInterfaceParserContext _Nullable ctx,
                                       const unsigned char * name,
                                       const unsigned char * ExternalID,
                                       const unsigned char * SystemID);
int _CFXMLInterfaceIsStandalone(_CFXMLInterfaceParserContext _Nullable ctx);
int _CFXMLInterfaceHasInternalSubset(_CFXMLInterfaceParserContext _Nullable ctx);
int _CFXMLInterfaceHasExternalSubset(_CFXMLInterfaceParserContext _Nullable ctx);
_CFXMLInterfaceEntity _Nullable _CFXMLInterfaceGetPredefinedEntity(const unsigned char * name);
_CFXMLInterfaceEntity _Nullable _CFXMLInterfaceSAX2GetEntity(_CFXMLInterfaceParserContext _Nullable ctx, const unsigned char *  name);
int _CFXMLInterfaceInRecursiveState(_CFXMLInterfaceParserContext ctx);
void _CFXMLInterfaceResetRecursiveState(_CFXMLInterfaceParserContext ctx);
int _CFXMLInterfaceHasDocument(_CFXMLInterfaceParserContext _Nullable ctx);
void _CFXMLInterfaceFreeEnumeration(_CFXMLInterfaceEnumeration _Nullable enumeration);
void _CFXMLInterfaceSAX2UnparsedEntityDecl(_CFXMLInterfaceParserContext _Nullable ctx, const unsigned char * name, const unsigned char *_Nullable publicId, const unsigned char *_Nullable systemId, const unsigned char *_Nullable notationName);
CFErrorRef _CFErrorCreateFromXMLInterface(_CFXMLInterfaceError err) CF_RETURNS_RETAINED;

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* __COREFOUNDATION_CFXMLINTERFACE__ */