// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public struct NSAffineTransformStruct {
    public var m11: CGFloat
    public var m12: CGFloat
    public var m21: CGFloat
    public var m22: CGFloat
    public var tX: CGFloat
    public var tY: CGFloat
    public init() { NSUnimplemented() }
    public init(m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat) { NSUnimplemented() }
}

public class NSAffineTransform : NSObject, NSCopying, NSSecureCoding {
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    // Initialization
    public convenience init(transform: NSAffineTransform) { NSUnimplemented() }
    public override init() { NSUnimplemented() }
    
    // Translating
    public func translateXBy(deltaX: CGFloat, yBy deltaY: CGFloat) { NSUnimplemented() }
    
    // Rotating
    public func rotateByDegrees(angle: CGFloat) { NSUnimplemented() }
    public func rotateByRadians(angle: CGFloat) { NSUnimplemented() }
    
    // Scaling
    public func scaleBy(scale: CGFloat) { NSUnimplemented() }
    public func scaleXBy(scaleX: CGFloat, yBy scaleY: CGFloat) { NSUnimplemented() }
    
    // Inverting
    public func invert() { NSUnimplemented() }
    
    // Transforming with transform
    public func appendTransform(transform: NSAffineTransform) { NSUnimplemented() }
    public func prependTransform(transform: NSAffineTransform) { NSUnimplemented() }
    
    // Transforming points and sizes
    public func transformPoint(aPoint: NSPoint) -> NSPoint { NSUnimplemented() }
    public func transformSize(aSize: NSSize) -> NSSize { NSUnimplemented() }
    
    // Transform Struct
    public var transformStruct: NSAffineTransformStruct
}

