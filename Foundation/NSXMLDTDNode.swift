// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
/*!
    @typedef NSXMLDTDNodeKind
	@abstract The subkind of a DTD node kind.
*/
public enum NSXMLDTDNodeKind : UInt {
    
    case NSXMLEntityGeneralKind
    case NSXMLEntityParsedKind
    case NSXMLEntityUnparsedKind
    case NSXMLEntityParameterKind
    case NSXMLEntityPredefined
    
    case NSXMLAttributeCDATAKind
    case NSXMLAttributeIDKind
    case NSXMLAttributeIDRefKind
    case NSXMLAttributeIDRefsKind
    case NSXMLAttributeEntityKind
    case NSXMLAttributeEntitiesKind
    case NSXMLAttributeNMTokenKind
    case NSXMLAttributeNMTokensKind
    case NSXMLAttributeEnumerationKind
    case NSXMLAttributeNotationKind
    
    case NSXMLElementDeclarationUndefinedKind
    case NSXMLElementDeclarationEmptyKind
    case NSXMLElementDeclarationAnyKind
    case NSXMLElementDeclarationMixedKind
    case NSXMLElementDeclarationElementKind
}

/*!
    @class NSXMLDTDNode
    @abstract The nodes that are exclusive to a DTD
	@discussion Every DTD node has a name. Object value is defined as follows:<ul>
		<li><b>Entity declaration</b> - the string that that entity resolves to eg "&lt;"</li>
		<li><b>Attribute declaration</b> - the default value, if any</li>
		<li><b>Element declaration</b> - the validation string</li>
		<li><b>Notation declaration</b> - no objectValue</li></ul>
*/
public class NSXMLDTDNode : NSXMLNode {
    
    /*!
        @method initWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public init?(XMLString string: String) {
        let ptr = _CFXMLParseDTDNode(string)
        if ptr == nil {
            return nil
        } else {
            super.init(ptr: ptr)
        }
    } //primitive
    
    public override init(kind: NSXMLNodeKind, options: Int) {
        var ptr: _CFXMLNodePtr = nil

        switch kind {
        case .ElementDeclarationKind:
            ptr = _CFXMLDTDNewElementDesc(nil, nil)

        default:
            super.init(kind: kind, options: options)
            return
        }

        super.init(ptr: ptr)
    } //primitive
    
    /*!
        @method DTDKind
        @abstract Sets the DTD sub kind.
    */
    public var DTDKind: NSXMLDTDNodeKind {
        switch _CFXMLNodeGetType(_xmlNode) {
        case _kCFXMLDTDNodeTypeElement:
            switch _CFXMLDTDElementNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeElementTypeAny:
                return .NSXMLElementDeclarationAnyKind
                
            case _kCFXMLDTDNodeElementTypeEmpty:
                return .NSXMLElementDeclarationEmptyKind
                
            case _kCFXMLDTDNodeElementTypeMixed:
                return .NSXMLElementDeclarationMixedKind
                
            case _kCFXMLDTDNodeElementTypeElement:
                return .NSXMLElementDeclarationElementKind
                
            default:
                return .NSXMLElementDeclarationUndefinedKind
            }
            
        case _kCFXMLDTDNodeTypeEntity:
            switch _CFXMLDTDEntityNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeEntityTypeInternalGeneral:
                return .NSXMLEntityGeneralKind
                
            case _kCFXMLDTDNodeEntityTypeExternalGeneralUnparsed:
                return .NSXMLEntityUnparsedKind
                
            case _kCFXMLDTDNodeEntityTypeExternalParameter:
                fallthrough
            case _kCFXMLDTDNodeEntityTypeInternalParameter:
                return .NSXMLEntityParameterKind
                
            case _kCFXMLDTDNodeEntityTypeInternalPredefined:
                return .NSXMLEntityPredefined
                
            case _kCFXMLDTDNodeEntityTypeExternalGeneralParsed:
                return .NSXMLEntityParsedKind
                
            default:
                fatalError("Invalid entity declaration type");
            }
            
        case _kCFXMLDTDNodeTypeAttribute:
            switch _CFXMLDTDAttributeNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeAttributeTypeCData:
                return .NSXMLAttributeCDATAKind
                
            case _kCFXMLDTDNodeAttributeTypeID:
                return .NSXMLAttributeIDKind
                
            case _kCFXMLDTDNodeAttributeTypeIDRef:
                return .NSXMLAttributeIDRefKind
                
            case _kCFXMLDTDNodeAttributeTypeIDRefs:
                return .NSXMLAttributeIDRefsKind
                
            case _kCFXMLDTDNodeAttributeTypeEntity:
                return .NSXMLAttributeEntityKind
                
            case _kCFXMLDTDNodeAttributeTypeEntities:
                return .NSXMLAttributeEntitiesKind
                
            case _kCFXMLDTDNodeAttributeTypeNMToken:
                return .NSXMLAttributeNMTokenKind
                
            case _kCFXMLDTDNodeAttributeTypeNMTokens:
                return .NSXMLAttributeNMTokensKind
                
            case _kCFXMLDTDNodeAttributeTypeEnumeration:
                return .NSXMLAttributeEnumerationKind
                
            case _kCFXMLDTDNodeAttributeTypeNotation:
                return .NSXMLAttributeNotationKind
                
            default:
                fatalError("Invalid attribute declaration type")
            }
            
        case _kCFXMLTypeInvalid:
            return unsafeBitCast(0, NSXMLDTDNodeKind.self) // this mirrors Darwin
            
        default:
            fatalError("This is not actually a DTD node!")
        }
    }//primitive
    
    /*!
        @method isExternal
        @abstract True if the system id is set. Valid for entities and notations.
    */
    public var external: Bool {
        return systemID != nil
    } //primitive
    
    /*!
        @method publicID
        @abstract Sets the public id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set. Valid for entities and notations.
    */
    public var publicID: String? {
        get {
            return _CFXMLDTDNodeGetPublicID(_xmlNode)?._swiftObject
        }
        set {
            if let value = newValue {
                _CFXMLDTDNodeSetPublicID(_xmlNode, value)
            } else {
                _CFXMLDTDNodeSetPublicID(_xmlNode, nil)
            }
        }
    }
    
    /*!
        @method systemID
        @abstract Sets the system id. This should be a URL that points to a valid DTD. Valid for entities and notations.
    */
    public var systemID: String? {
        get {
            return _CFXMLDTDNodeGetSystemID(_xmlNode)?._swiftObject
        }
        set {
            if let value = newValue {
                _CFXMLDTDNodeSetSystemID(_xmlNode, value)
            } else {
                _CFXMLDTDNodeSetSystemID(_xmlNode, nil)
            }
        }
    }
    
    /*!
        @method notationName
        @abstract Set the notation name. Valid for entities only.
    */
    public var notationName: String? {
        get {
            guard DTDKind == .NSXMLEntityUnparsedKind else {
                return nil
            }

            return _CFXMLGetEntityContent(_xmlNode)?._swiftObject
        }
        set {
            guard DTDKind == .NSXMLEntityUnparsedKind else {
                return
            }

            if let value = newValue {
                _CFXMLNodeSetContent(_xmlNode, value)
            } else {
                _CFXMLNodeSetContent(_xmlNode, nil)
            }
        }
    }//primitive

    internal override class func _objectNodeForNode(node: _CFXMLNodePtr) -> NSXMLDTDNode {
        let type = _CFXMLNodeGetType(node)
        precondition(type == _kCFXMLDTDNodeTypeAttribute ||
                     type == _kCFXMLDTDNodeTypeNotation  ||
                     type == _kCFXMLDTDNodeTypeEntity    ||
                     type == _kCFXMLDTDNodeTypeElement)

        if _CFXMLNodeGetPrivateData(node) != nil {
            let unmanaged = Unmanaged<NSXMLDTDNode>.fromOpaque(_CFXMLNodeGetPrivateData(node))
            return unmanaged.takeUnretainedValue()
        }

        return NSXMLDTDNode(ptr: node)
    }

    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}


