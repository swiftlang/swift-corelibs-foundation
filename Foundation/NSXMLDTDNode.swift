// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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
extension XMLDTDNode {
    public enum DTDKind : UInt {
        
        
        case general
        
        case parsed
        
        case unparsed
        
        case parameter
        
        case predefined
        
        
        case cdataAttribute
        
        case idAttribute
        
        case idRefAttribute
        
        case idRefsAttribute
        
        case entityAttribute
        
        case entitiesAttribute
        
        case nmTokenAttribute
        
        case nmTokensAttribute
        
        case enumerationAttribute
        
        case notationAttribute
        
        
        case undefinedDeclaration
        
        case emptyDeclaration
        
        case anyDeclaration
        
        case mixedDeclaration
        
        case elementDeclaration
    }
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
public class XMLDTDNode: XMLNode {
    
    /*!
        @method initWithXMLString:
        @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
    */
    public init?(XMLString string: String) {
        guard let ptr = _CFXMLParseDTDNode(string) else { return nil }
        super.init(ptr: ptr)
    } //primitive
    
    public override init(kind: XMLNode.Kind, options: Int) {
        let ptr: _CFXMLNodePtr

        switch kind {
        case .elementDeclaration:
            ptr = _CFXMLDTDNewElementDesc(nil, nil)!

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
    public var dtdKind: DTDKind {
        switch _CFXMLNodeGetType(_xmlNode) {
        case _kCFXMLDTDNodeTypeElement:
            switch _CFXMLDTDElementNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeElementTypeAny:
                return .anyDeclaration
                
            case _kCFXMLDTDNodeElementTypeEmpty:
                return .emptyDeclaration
                
            case _kCFXMLDTDNodeElementTypeMixed:
                return .mixedDeclaration
                
            case _kCFXMLDTDNodeElementTypeElement:
                return .elementDeclaration
                
            default:
                return .undefinedDeclaration
            }
            
        case _kCFXMLDTDNodeTypeEntity:
            switch _CFXMLDTDEntityNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeEntityTypeInternalGeneral:
                return .general
                
            case _kCFXMLDTDNodeEntityTypeExternalGeneralUnparsed:
                return .unparsed
                
            case _kCFXMLDTDNodeEntityTypeExternalParameter:
                fallthrough
            case _kCFXMLDTDNodeEntityTypeInternalParameter:
                return .parameter
                
            case _kCFXMLDTDNodeEntityTypeInternalPredefined:
                return .predefined
                
            case _kCFXMLDTDNodeEntityTypeExternalGeneralParsed:
                return .general
                
            default:
                fatalError("Invalid entity declaration type")
            }
            
        case _kCFXMLDTDNodeTypeAttribute:
            switch _CFXMLDTDAttributeNodeGetType(_xmlNode) {
            case _kCFXMLDTDNodeAttributeTypeCData:
                return .cdataAttribute
                
            case _kCFXMLDTDNodeAttributeTypeID:
                return .idAttribute
                
            case _kCFXMLDTDNodeAttributeTypeIDRef:
                return .idRefAttribute
                
            case _kCFXMLDTDNodeAttributeTypeIDRefs:
                return .idRefsAttribute
                
            case _kCFXMLDTDNodeAttributeTypeEntity:
                return .entityAttribute
                
            case _kCFXMLDTDNodeAttributeTypeEntities:
                return .entitiesAttribute
                
            case _kCFXMLDTDNodeAttributeTypeNMToken:
                return .nmTokenAttribute
                
            case _kCFXMLDTDNodeAttributeTypeNMTokens:
                return .nmTokensAttribute
                
            case _kCFXMLDTDNodeAttributeTypeEnumeration:
                return .enumerationAttribute
                
            case _kCFXMLDTDNodeAttributeTypeNotation:
                return .notationAttribute
                
            default:
                fatalError("Invalid attribute declaration type")
            }
            
        case _kCFXMLTypeInvalid:
            return unsafeBitCast(0, to: DTDKind.self) // this mirrors Darwin
            
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
            guard dtdKind == .unparsed else {
                return nil
            }

            return _CFXMLGetEntityContent(_xmlNode)?._swiftObject
        }
        set {
            guard dtdKind == .unparsed else {
                return
            }

            if let value = newValue {
                _CFXMLNodeSetContent(_xmlNode, value)
            } else {
                _CFXMLNodeSetContent(_xmlNode, nil)
            }
        }
    }//primitive

    internal override class func _objectNodeForNode(_ node: _CFXMLNodePtr) -> XMLDTDNode {
        let type = _CFXMLNodeGetType(node)
        precondition(type == _kCFXMLDTDNodeTypeAttribute ||
                     type == _kCFXMLDTDNodeTypeNotation  ||
                     type == _kCFXMLDTDNodeTypeEntity    ||
                     type == _kCFXMLDTDNodeTypeElement)

        if let privateData = _CFXMLNodeGetPrivateData(node) {
            return XMLDTDNode.unretainedReference(privateData)
        }

        return XMLDTDNode(ptr: node)
    }

    internal override init(ptr: _CFXMLNodePtr) {
        super.init(ptr: ptr)
    }
}


