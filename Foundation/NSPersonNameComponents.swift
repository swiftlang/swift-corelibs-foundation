// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSPersonNameComponents : NSObject, NSCopying, NSSecureCoding {
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    static public func supportsSecureCoding() -> Bool { return true }
    public func encodeWithCoder(aCoder: NSCoder) { NSUnimplemented() }
    public func copyWithZone(zone: NSZone) -> AnyObject { NSUnimplemented() }
    
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
    /*@NSCopying*/ public var phoneticRepresentation: NSPersonNameComponents?
}

