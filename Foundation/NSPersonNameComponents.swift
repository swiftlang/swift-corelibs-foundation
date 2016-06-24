// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSPersonNameComponents : NSObject, NSCopying, NSSecureCoding {
    
    public convenience required init?(coder aDecoder: NSCoder) {
        self.init()
        if aDecoder.allowsKeyedCoding {
            self.namePrefix = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.namePrefix") as NSString?)?.bridge()
            self.givenName = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.givenName") as NSString?)?.bridge()
            self.middleName = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.middleName") as NSString?)?.bridge()
            self.familyName = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.familyName") as NSString?)?.bridge()
            self.nameSuffix = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.nameSuffix") as NSString?)?.bridge()
            self.nickname = (aDecoder.decodeObjectOfClass(NSString.self, forKey: "NS.nickname") as NSString?)?.bridge()
        } else {
            self.namePrefix = (aDecoder.decodeObject() as? NSString)?.bridge()
            self.givenName = (aDecoder.decodeObject() as? NSString)?.bridge()
            self.middleName = (aDecoder.decodeObject() as? NSString)?.bridge()
            self.familyName = (aDecoder.decodeObject() as? NSString)?.bridge()
            self.nameSuffix = (aDecoder.decodeObject() as? NSString)?.bridge()
            self.nickname = (aDecoder.decodeObject() as? NSString)?.bridge()
        }
    }
    
    static public func supportsSecureCoding() -> Bool { return true }
    
    public func encode(with aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.namePrefix?.bridge(), forKey: "NS.namePrefix")
            aCoder.encode(self.givenName?.bridge(), forKey: "NS.givenName")
            aCoder.encode(self.middleName?.bridge(), forKey: "NS.middleName")
            aCoder.encode(self.familyName?.bridge(), forKey: "NS.familyName")
            aCoder.encode(self.nameSuffix?.bridge(), forKey: "NS.nameSuffix")
            aCoder.encode(self.nickname?.bridge(), forKey: "NS.nickname")
        } else {
            // FIXME check order
            aCoder.encode(self.namePrefix?.bridge())
            aCoder.encode(self.givenName?.bridge())
            aCoder.encode(self.middleName?.bridge())
            aCoder.encode(self.familyName?.bridge())
            aCoder.encode(self.nameSuffix?.bridge())
            aCoder.encode(self.nickname?.bridge())
        }
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject { NSUnimplemented() }
    
    /* The below examples all assume the full name Dr. Johnathan Maple Appleseed Esq., nickname "Johnny" */
    
    /* Pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr. */
    public var namePrefix: String?
    
    /* Name bestowed upon an individual by one's parents, e.g. Johnathan */
    public var givenName: String?
    
    /* Secondary given name chosen to differentiate those with the same first name, e.g. Maple  */
    public var middleName: String?
    
    /* Name passed from one generation to another to indicate lineage, e.g. Appleseed  */
    public var familyName: String?
    
    /* Post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D. */
    public var nameSuffix: String?
    
    /* Name substituted for the purposes of familiarity, e.g. "Johnny"*/
    public var nickname: String?
    
    /* Each element of the phoneticRepresentation should correspond to an element of the original PersonNameComponents instance.
       The phoneticRepresentation of the phoneticRepresentation object itself will be ignored. nil by default, must be instantiated.
    */
    /*@NSCopying*/ public var phoneticRepresentation: PersonNameComponents?
}

