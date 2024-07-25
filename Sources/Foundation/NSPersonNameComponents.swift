// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@available(*, unavailable)
extension NSPersonNameComponents : @unchecked Sendable { }

open class NSPersonNameComponents : NSObject, NSCopying, NSSecureCoding {
    
    override public init() {
        _pnc = PersonNameComponents()
    }
    
    internal init(pnc: PersonNameComponents) {
        _pnc = pnc
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        self.init(pnc: .init())
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        func bridgeOptionalString(_ value: NSString?) -> String? {
            if let obj = value {
                return String._unconditionallyBridgeFromObjectiveC(obj)
            } else {
                return nil
            }
        }
        self.namePrefix = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.namePrefix") as NSString?)
        self.givenName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.givenName") as NSString?)
        self.middleName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.middleName") as NSString?)
        self.familyName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.familyName") as NSString?)
        self.nameSuffix = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.nameSuffix") as NSString?)
        self.nickname = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.nickname") as NSString?)
    }
    
    static public var supportsSecureCoding: Bool { return true }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.namePrefix?._bridgeToObjectiveC(), forKey: "NS.namePrefix")
        aCoder.encode(self.givenName?._bridgeToObjectiveC(), forKey: "NS.givenName")
        aCoder.encode(self.middleName?._bridgeToObjectiveC(), forKey: "NS.middleName")
        aCoder.encode(self.familyName?._bridgeToObjectiveC(), forKey: "NS.familyName")
        aCoder.encode(self.nameSuffix?._bridgeToObjectiveC(), forKey: "NS.nameSuffix")
        aCoder.encode(self.nickname?._bridgeToObjectiveC(), forKey: "NS.nickname")
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = NSPersonNameComponents()
        copy._pnc = _pnc
        return copy
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object else { return false }

        switch object {
        case let other as NSPersonNameComponents:
            return _pnc == other._pnc
        case let other as PersonNameComponents:
            return _pnc == other
        default:
            return false
        }
    }

    private func isEqual(_ other: NSPersonNameComponents) -> Bool {
        _pnc == other._pnc
    }
    
    // Internal for ObjectiveCBridgable access
    internal var _pnc = PersonNameComponents()
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr.
    open var namePrefix: String? {
        get { _pnc.namePrefix }
        set { _pnc.namePrefix = newValue }
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny",  name bestowed upon an individual by one's parents, e.g. Johnathan
    open var givenName: String? {
        get { _pnc.givenName }
        set { _pnc.givenName = newValue }
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", secondary given name chosen to differentiate those with the same first name, e.g. Maple
    open var middleName: String? {
        get { _pnc.middleName }
        set { _pnc.middleName = newValue }
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", name passed from one generation to another to indicate lineage, e.g. Appleseed
    open var familyName: String? {
        get { _pnc.familyName }
        set { _pnc.familyName = newValue }
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D.
    open var nameSuffix: String? {
        get { _pnc.nameSuffix }
        set { _pnc.nameSuffix = newValue }
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", name substituted for the purposes of familiarity, e.g. "Johnny"
    open var nickname: String? {
        get { _pnc.nickname }
        set { _pnc.nickname = newValue }
    }
    
    /// Each element of the phoneticRepresentation should correspond to an element of the original PersonNameComponents instance.
    /// The phoneticRepresentation of the phoneticRepresentation object itself will be ignored. nil by default, must be instantiated.
    open var phoneticRepresentation: PersonNameComponents? {
        get { _pnc.phoneticRepresentation }
        set { _pnc.phoneticRepresentation = newValue }
    }
}

extension NSPersonNameComponents : _StructTypeBridgeable {
    public typealias _StructType = PersonNameComponents

    public func _bridgeToSwift() -> _StructType {
        return PersonNameComponents._unconditionallyBridgeFromObjectiveC(self)
    }
}
