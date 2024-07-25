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

#include "CFTargetConditionals.h"
#include "CFBase.h"
#include "CFError.h"
#include <stdint.h>
#include <sys/types.h>
#include <stdbool.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN
CF_EXTERN_C_BEGIN

extern const CFIndex _kCFXMLInterfaceRecover;
extern const CFIndex _kCFXMLInterfaceNoEnt;
extern const CFIndex _kCFXMLInterfaceDTDLoad;
extern const CFIndex _kCFXMLInterfaceDTDAttr;
extern const CFIndex _kCFXMLInterfaceDTDValid;
extern const CFIndex _kCFXMLInterfaceNoError;
extern const CFIndex _kCFXMLInterfaceNoWarning;
extern const CFIndex _kCFXMLInterfacePedantic;
extern const CFIndex _kCFXMLInterfaceNoBlanks;
extern const CFIndex _kCFXMLInterfaceSAX1;
extern const CFIndex _kCFXMLInterfaceXInclude;
extern const CFIndex _kCFXMLInterfaceNoNet;
extern const CFIndex _kCFXMLInterfaceNoDict;
extern const CFIndex _kCFXMLInterfaceNSClean;
extern const CFIndex _kCFXMLInterfaceNoCdata;
extern const CFIndex _kCFXMLInterfaceNoXIncnode;
extern const CFIndex _kCFXMLInterfaceCompact;
extern const CFIndex _kCFXMLInterfaceOld10;
extern const CFIndex _kCFXMLInterfaceNoBasefix;
extern const CFIndex _kCFXMLInterfaceHuge;
extern const CFIndex _kCFXMLInterfaceOldsax;
extern const CFIndex _kCFXMLInterfaceIgnoreEnc;
extern const CFIndex _kCFXMLInterfaceBigLines;

extern const CFIndex _kCFXMLTypeInvalid;
extern const CFIndex _kCFXMLTypeDocument;
extern const CFIndex _kCFXMLTypeElement;
extern const CFIndex _kCFXMLTypeAttribute;
extern const CFIndex _kCFXMLTypeProcessingInstruction;
extern const CFIndex _kCFXMLTypeComment;
extern const CFIndex _kCFXMLTypeText;
extern const CFIndex _kCFXMLTypeCDataSection;
extern const CFIndex _kCFXMLTypeDTD;
extern const CFIndex _kCFXMLDocTypeHTML;
extern const CFIndex _kCFXMLTypeNamespace;

extern const CFIndex _kCFXMLDTDNodeTypeEntity;
extern const CFIndex _kCFXMLDTDNodeTypeAttribute;
extern const CFIndex _kCFXMLDTDNodeTypeElement;
extern const CFIndex _kCFXMLDTDNodeTypeNotation;

extern const CFIndex _kCFXMLDTDNodeElementTypeUndefined;
extern const CFIndex _kCFXMLDTDNodeElementTypeEmpty;
extern const CFIndex _kCFXMLDTDNodeElementTypeAny;
extern const CFIndex _kCFXMLDTDNodeElementTypeMixed;
extern const CFIndex _kCFXMLDTDNodeElementTypeElement;

extern const CFIndex _kCFXMLDTDNodeEntityTypeInternalGeneral;
extern const CFIndex _kCFXMLDTDNodeEntityTypeExternalGeneralParsed;
extern const CFIndex _kCFXMLDTDNodeEntityTypeExternalGeneralUnparsed;
extern const CFIndex _kCFXMLDTDNodeEntityTypeInternalParameter;
extern const CFIndex _kCFXMLDTDNodeEntityTypeExternalParameter;
extern const CFIndex _kCFXMLDTDNodeEntityTypeInternalPredefined;

extern const CFIndex _kCFXMLDTDNodeAttributeTypeCData;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeID;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeIDRef;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeIDRefs;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeEntity;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeEntities;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeNMToken;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeNMTokens;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeEnumeration;
extern const CFIndex _kCFXMLDTDNodeAttributeTypeNotation;

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
void _CFSetupXMLBridgeIfNeededUsingBlock(void (^block)(void));

_CFXMLInterfaceParserInput _CFXMLInterfaceNoNetExternalEntityLoader(const char *URL, const char *ID, _CFXMLInterfaceParserContext ctxt);
_CFXMLInterfaceSAXHandler _CFXMLInterfaceCreateSAXHandler(void);
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

typedef void* _CFXMLNodePtr;
typedef void* _CFXMLDocPtr;
typedef void* _CFXMLNamespacePtr;
typedef void* _CFXMLEntityPtr;
typedef void* _CFXMLDTDPtr;
typedef void* _CFXMLDTDNodePtr;

_CFXMLNodePtr _CFXMLNewNode(_CFXMLNamespacePtr _Nullable name_space, const char* name);
_CFXMLNodePtr _CFXMLCopyNode(_CFXMLNodePtr node, bool recursive);

_CFXMLDocPtr _CFXMLNewDoc(const unsigned char* version);
_CFXMLNodePtr _CFXMLNewProcessingInstruction(const unsigned char* name, const unsigned char* value);
_CFXMLNodePtr _CFXMLNewTextNode(const unsigned char* value);
_CFXMLNodePtr _CFXMLNewComment(const unsigned char* value);
_CFXMLNodePtr _CFXMLNewProperty(_CFXMLNodePtr _Nullable node, const unsigned char* name, const unsigned char* _Nullable uri, const unsigned char* value);

CFStringRef _Nullable _CFXMLNodeCopyURI(_CFXMLNodePtr node);
void _CFXMLNodeSetURI(_CFXMLNodePtr node, const unsigned char* _Nullable URI);

void _CFXMLNodeSetPrivateData(_CFXMLNodePtr node, void* data);
void* _Nullable  _CFXMLNodeGetPrivateData(_CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeProperties(_CFXMLNodePtr node);
CFIndex _CFXMLNodeGetType(_CFXMLNodePtr node);
CFStringRef _Nullable _CFXMLNodeCopyName(_CFXMLNodePtr node);
void _CFXMLNodeForceSetName(_CFXMLNodePtr node, const char* _Nullable name);
void _CFXMLNodeSetName(_CFXMLNodePtr node, const char* name);
bool _CFXMLNodeNameEqual(_CFXMLNodePtr node, const char* name);
CFStringRef _Nullable _CFXMLNodeCopyContent(_CFXMLNodePtr node);
void _CFXMLNodeSetContent(_CFXMLNodePtr node,  const unsigned char* _Nullable content);
void _CFXMLUnlinkNode(_CFXMLNodePtr node);

_CFXMLNodePtr _Nullable _CFXMLNodeGetFirstChild(_CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeGetLastChild(_CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeGetNextSibling(_CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeGetPrevSibling(_CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeGetParent(_CFXMLNodePtr node);
CFIndex _CFXMLNodeGetElementChildCount(_CFXMLNodePtr node);
void _CFXMLNodeAddChild(_CFXMLNodePtr node, _CFXMLNodePtr child);
void _CFXMLNodeAddPrevSibling(_CFXMLNodePtr node, _CFXMLNodePtr prevSibling);
void _CFXMLNodeAddNextSibling(_CFXMLNodePtr node, _CFXMLNodePtr nextSibling);
void _CFXMLNodeReplaceNode(_CFXMLNodePtr node, _CFXMLNodePtr replacement);

_CFXMLDocPtr _Nullable _CFXMLNodeGetDocument(_CFXMLNodePtr node);

bool _CFXMLDocStandalone(_CFXMLDocPtr doc);
void _CFXMLDocSetStandalone(_CFXMLDocPtr doc, bool standalone);
_CFXMLNodePtr _Nullable _CFXMLDocRootElement(_CFXMLDocPtr doc);
void _CFXMLDocSetRootElement(_CFXMLDocPtr doc, _CFXMLNodePtr node);
CFStringRef _Nullable _CFXMLDocCopyCharacterEncoding(_CFXMLDocPtr doc);
void _CFXMLDocSetCharacterEncoding(_CFXMLDocPtr doc,  const unsigned char* _Nullable  encoding);
CFStringRef _Nullable _CFXMLDocCopyVersion(_CFXMLDocPtr doc);
void _CFXMLDocSetVersion(_CFXMLDocPtr doc, const unsigned char* _Nullable version);
int _CFXMLDocProperties(_CFXMLDocPtr doc);
void _CFXMLDocSetProperties(_CFXMLDocPtr doc, int newProperties);
_CFXMLDTDPtr _Nullable _CFXMLDocDTD(_CFXMLDocPtr doc);
void _CFXMLDocSetDTD(_CFXMLDocPtr doc, _CFXMLDTDPtr _Nullable dtd);

CF_RETURNS_RETAINED CFStringRef _Nullable _CFXMLEncodeEntities(_CFXMLDocPtr _Nullable doc, const unsigned char* string);
_CFXMLEntityPtr _Nullable _CFXMLGetDocEntity(_CFXMLDocPtr doc, const char* entity);
_CFXMLEntityPtr _Nullable _CFXMLGetDTDEntity(_CFXMLDocPtr doc, const char* entity);
_CFXMLEntityPtr _Nullable _CFXMLGetParameterEntity(_CFXMLDocPtr doc, const char* entity);

CFStringRef _Nullable _CFXMLCopyEntityContent(_CFXMLEntityPtr entity);

CFStringRef _CFXMLCopyStringWithOptions(_CFXMLNodePtr node, uint32_t options);

CF_RETURNS_RETAINED CFArrayRef _Nullable _CFXMLNodesForXPath(_CFXMLNodePtr node, const unsigned char* xpath);
CFStringRef _Nullable _CFXMLCopyPathForNode(_CFXMLNodePtr node);

void _CFXMLCompletePropURI(_CFXMLNodePtr propertyNode, _CFXMLNodePtr node);
_CFXMLNodePtr _Nullable _CFXMLNodeHasProp(_CFXMLNodePtr node, const unsigned char* propertyName, const unsigned char* _Nullable uri);

_CFXMLDocPtr _CFXMLDocPtrFromDataWithOptions(CFDataRef data, unsigned int options);

CFStringRef _Nullable _CFXMLNodeCopyLocalName(_CFXMLNodePtr node);
CFStringRef _Nullable _CFXMLNodeCopyPrefix(_CFXMLNodePtr node);

bool _CFXMLDocValidate(_CFXMLDocPtr doc, CFErrorRef _Nullable * error);

_CFXMLDTDPtr _CFXMLNewDTD(_CFXMLDocPtr _Nullable doc, const unsigned char* name, const unsigned char* publicID, const unsigned char* systemID);
_CFXMLDTDNodePtr _Nullable _CFXMLParseDTDNode(const unsigned char* xmlString);
_CFXMLDTDPtr _Nullable _CFXMLParseDTD(const unsigned char* URL);
_CFXMLDTDPtr _Nullable _CFXMLParseDTDFromData(CFDataRef data, CFErrorRef _Nullable * error);
CFStringRef _Nullable _CFXMLDTDCopyExternalID(_CFXMLDTDPtr dtd);
void _CFXMLDTDSetExternalID(_CFXMLDTDPtr dtd, const unsigned char* _Nullable externalID);
CFStringRef _Nullable _CFXMLDTDCopySystemID(_CFXMLDTDPtr dtd);
void _CFXMLDTDSetSystemID(_CFXMLDTDPtr dtd, const unsigned char* _Nullable systemID);

_CFXMLDTDNodePtr _Nullable _CFXMLDTDGetElementDesc(_CFXMLDTDPtr dtd, const unsigned char* name);
_CFXMLDTDNodePtr _Nullable _CFXMLDTDGetAttributeDesc(_CFXMLDTDPtr dtd, const unsigned char* elementName, const unsigned char* name);
_CFXMLDTDNodePtr _Nullable _CFXMLDTDGetNotationDesc(_CFXMLDTDPtr dtd, const unsigned char* name);
_CFXMLDTDNodePtr _Nullable _CFXMLDTDGetEntityDesc(_CFXMLDTDPtr dtd, const unsigned char* name);
_CFXMLDTDNodePtr _Nullable _CFXMLDTDGetPredefinedEntity(const unsigned char* name);

_CFXMLDTDNodePtr _Nullable _CFXMLDTDNewElementDesc(_CFXMLDTDPtr _Nullable dtd, const unsigned char* _Nullable name);
_CFXMLDTDNodePtr _Nullable _CFXMLDTDNewAttributeDesc(_CFXMLDTDPtr dtd, const unsigned char* name);

CFIndex _CFXMLDTDElementNodeGetType(_CFXMLDTDNodePtr node);
CFIndex _CFXMLDTDEntityNodeGetType(_CFXMLDTDNodePtr node);
CFIndex _CFXMLDTDAttributeNodeGetType(_CFXMLDTDNodePtr node);

CFStringRef _Nullable _CFXMLDTDNodeCopySystemID(_CFXMLDTDNodePtr node);
void _CFXMLDTDNodeSetSystemID(_CFXMLDTDNodePtr node, const unsigned char* _Nullable systemID);
CFStringRef _Nullable _CFXMLDTDNodeCopyPublicID(_CFXMLDTDNodePtr node);
void _CFXMLDTDNodeSetPublicID(_CFXMLDTDNodePtr node, const unsigned char* _Nullable publicID);

// Namespaces
_CFXMLNodePtr _Nonnull * _Nullable _CFXMLNamespaces(_CFXMLNodePtr node, CFIndex* count);
void _CFXMLSetNamespaces(_CFXMLNodePtr node, _CFXMLNodePtr _Nonnull * _Nullable nodes, CFIndex count);
CFStringRef _Nullable _CFXMLNamespaceCopyValue(_CFXMLNodePtr node);
void _CFXMLNamespaceSetValue(_CFXMLNodePtr node, const char* _Nullable value, int64_t length);
CFStringRef _Nullable _CFXMLNamespaceCopyPrefix(_CFXMLNodePtr node);
void _CFXMLNamespaceSetPrefix(_CFXMLNodePtr node, const char* _Nullable prefix, int64_t length);
_CFXMLNodePtr _CFXMLNewNamespace(const char* name, const char* stringValue);
void _CFXMLAddNamespace(_CFXMLNodePtr node, _CFXMLNodePtr nsNode);
void _CFXMLRemoveNamespace(_CFXMLNodePtr node, const char* prefix);

void _CFXMLFreeNode(_CFXMLNodePtr node);
void _CFXMLFreeDocument(_CFXMLDocPtr doc);
void _CFXMLFreeDTD(_CFXMLDTDPtr dtd);
void _CFXMLFreeProperty(_CFXMLNodePtr prop);

const char *_Nullable _CFXMLSplitQualifiedName(const char *_Nonnull qname);
bool _CFXMLGetLengthOfPrefixInQualifiedName(const char *_Nonnull qname, size_t *_Nonnull length);

// Bridging

struct _NSXMLParserBridge {
    void *CFBridge;

    _CFXMLInterface _Nullable (*_Nonnull currentParser)(void);
    _CFXMLInterfaceParserInput _Nullable (*_Nonnull _xmlExternalEntityWithURL)(_CFXMLInterface /*interface*/, const char * /*url*/, const char * /*identifier*/, _CFXMLInterfaceParserContext /*context*/, _CFXMLInterfaceExternalEntityLoader /*originalLoaderFunction*/);
    
    _CFXMLInterfaceParserContext _Nonnull (*_Nonnull getContext)(_CFXMLInterface ctx);
    
    void (*internalSubset)(_CFXMLInterface ctx, const unsigned char *name, const unsigned char *ExternalID, const unsigned char *SystemID);
    int (*isStandalone)(_CFXMLInterface ctx);
    int (*hasInternalSubset)(_CFXMLInterface ctx);
    int (*hasExternalSubset)(_CFXMLInterface ctx);
    _CFXMLInterfaceEntity _Nullable (*_Nonnull getEntity)(_CFXMLInterface ctx, const unsigned char *name);
    void (*notationDecl)(_CFXMLInterface ctx,
                         const unsigned char *name,
                         const unsigned char *publicId,
                         const unsigned char *systemId);
    void (*attributeDecl)(_CFXMLInterface ctx,
                          const unsigned char *elem,
                          const unsigned char *fullname,
                          int type,
                          int def,
                          const unsigned char *defaultValue,
                          _CFXMLInterfaceEnumeration tree);
    void (*elementDecl)(_CFXMLInterface ctx,
                        const unsigned char *name,
                        int type,
                        _CFXMLInterfaceElementContent content);
    void (*unparsedEntityDecl)(_CFXMLInterface ctx,
                               const unsigned char *name,
                               const unsigned char *publicId,
                               const unsigned char *systemId,
                               const unsigned char *notationName);
    void (*startDocument)(_CFXMLInterface ctx);
    void (*endDocument)(_CFXMLInterface ctx);
    void (*startElementNs)(_CFXMLInterface ctx,
                           const unsigned char *localname,
                           const unsigned char *_Nullable prefix,
                           const unsigned char *_Nullable URI,
                           int nb_namespaces,
                           const unsigned char *_Nullable *_Nonnull namespaces,
                           int nb_attributes,
                           int nb_defaulted,
                           const unsigned char *_Nullable *_Nonnull attributes);
    void (*endElementNs)(_CFXMLInterface ctx,
                         const unsigned char *localname,
                         const unsigned char *_Nullable prefix,
                         const unsigned char *_Nullable URI);
    void (*characters)(_CFXMLInterface ctx,
                       const unsigned char *ch,
                       int len);
    void (*processingInstruction)(_CFXMLInterface ctx,
                                  const unsigned char *target,
                                  const unsigned char *data);
    void (*cdataBlock)(_CFXMLInterface ctx,
                       const unsigned char *value,
                       int len);
    void (*comment)(_CFXMLInterface ctx, const unsigned char *value);
    void (*externalSubset)(_CFXMLInterface ctx,
                           const unsigned char *name,
                           const unsigned char *ExternalID,
                           const unsigned char *SystemID);
};

CF_EXPORT struct _NSXMLParserBridge __CFSwiftXMLParserBridge __attribute__((swift_attr("nonisolated(unsafe)")));


CF_EXTERN_C_END
CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* __COREFOUNDATION_CFXMLINTERFACE__ */
