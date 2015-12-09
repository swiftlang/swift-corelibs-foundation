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
    
    public init() {
        self.init(m11: CGFloat(), m12: CGFloat(), m21: CGFloat(), m22: CGFloat(), tX: CGFloat(), tY: CGFloat())
    }
    
    public init(m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat) {
        (self.m11, self.m12, self.m21, self.m22) = (m11, m12, m21, m22)
        (self.tX, self.tY) = (tX, tY)
    }
}

public class NSAffineTransform : NSObject, NSCopying, NSSecureCoding {
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return NSAffineTransform(transform: self)
    }
    // Necessary because `NSObject.copy()` returns `self`.
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    // Initialization
    public convenience init(transform: NSAffineTransform) {
        self.init()
        transformStruct = transform.transformStruct
    }
    
    public override init() {
        transformStruct = NSAffineTransformStruct(m11: CGFloat(1.0), m12: CGFloat(), m21: CGFloat(), m22: CGFloat(1.0), tX: CGFloat(), tY: CGFloat())
    }
    
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
    public func transformPoint(aPoint: NSPoint) -> NSPoint {
        /**
         [ x' ]     [ x ]   [ m11  m12  tX ] [ x ]   [ m11*x + m12*y + tX ]
         [ y' ] = T [ y ] = [ m21  m22  tY ] [ y ] = [ m21*x + m22*y + tY ]
         [  1 ]     [ 1 ]   [  0    0    1 ] [ 1 ]   [           1        ]
         */
        let x = transformStruct.m11*aPoint.x + transformStruct.m12*aPoint.y + transformStruct.tX
        let y = transformStruct.m21*aPoint.x + transformStruct.m22*aPoint.y + transformStruct.tY
        
        return NSPoint(x: x, y: y)
    }

    public func transformSize(aSize: NSSize) -> NSSize {
        /**
         [ w' ]     [ w ]   [ m11  m12  tX ] [ w ]   [ m11*w + m12*h ]
         [ h' ] = T [ h ] = [ m21  m22  tY ] [ h ] = [ m21*w + m22*h ]
         [  0 ]     [ 0 ]   [  0    0    1 ] [ 1 ]   [       0       ]
         NOTE: Translation has no effect on sizes.
         */
        let w = transformStruct.m11*aSize.width + transformStruct.m12*aSize.height
        let h = transformStruct.m21*aSize.width + transformStruct.m22*aSize.height
        
        return NSSize(width: w, height: h)
    }

    // Transform Struct
    public var transformStruct: NSAffineTransformStruct
}
