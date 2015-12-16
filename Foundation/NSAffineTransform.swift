// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

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
        transformStruct = NSAffineTransformStruct(
            m11: CGFloat(1.0), m12: CGFloat(),
            m21: CGFloat(), m22: CGFloat(1.0),
            tX: CGFloat(), tY: CGFloat()
        )
    }
    
    // Translating
    public func translateXBy(deltaX: CGFloat, yBy deltaY: CGFloat) {
        let translation = NSAffineTransformStruct.translation(tX: deltaX, tY: deltaY)
        
        transformStruct = transformStruct.concat(translation)
    }
    
    // Rotating
    public func rotateByDegrees(angle: CGFloat) {
        let rotation = NSAffineTransformStruct.rotation(degrees: angle)
        
        transformStruct = transformStruct.concat(rotation)
    }
    public func rotateByRadians(angle: CGFloat) {
        let rotation = NSAffineTransformStruct.rotation(radians: angle)
        
        transformStruct = transformStruct.concat(rotation)
    }
    
    // Scaling
    public func scaleBy(scale: CGFloat) {
        scaleXBy(scale, yBy: scale)
    }

    public func scaleXBy(scaleX: CGFloat, yBy scaleY: CGFloat) {
        let scale = NSAffineTransformStruct.scale(sX: scaleX, sY: scaleY)
        
        transformStruct = transformStruct.concat(scale)
    }
    
    // Inverting
    public func invert() {
        if let inverse = transformStruct.inverse {
            transformStruct = inverse
        }
        else {
            preconditionFailure("NSAffineTransform: Transform has no inverse")
        }
    }
    
    // Transforming with transform
    public func appendTransform(transform: NSAffineTransform) {
        transformStruct = transform.transformStruct.concat(transformStruct)
    }
    public func prependTransform(transform: NSAffineTransform) {
        transformStruct = transformStruct.concat(transform.transformStruct)
    }
    
    // Transforming points and sizes
    public func transformPoint(aPoint: NSPoint) -> NSPoint {
        return transformStruct.applied(toPoint: aPoint)
    }

    public func transformSize(aSize: NSSize) -> NSSize {
        return transformStruct.applied(toSize: aSize)
    }

    // Transform Struct
    public var transformStruct: NSAffineTransformStruct
}


private extension NSAffineTransformStruct {
    /**
     Creates an affine transformation matrix from translation values.
     The matrix takes the following form:
     
         [ 1  0  tX ]
         [ 0  1  tY ]
         [ 0  0   1 ]
     */
    static func translation(tX tX: CGFloat, tY: CGFloat) -> NSAffineTransformStruct {
        return NSAffineTransformStruct(
            m11: CGFloat(1.0), m12: CGFloat(),
            m21: CGFloat(),    m22: CGFloat(1.0),
            tX: tX, tY: tY
        )
    }
    
    /**
     Creates an affine transformation matrix from scaling values.
     The matrix takes the following form:
     
         [ sX   0  0 ]
         [ 0   sY  0 ]
         [ 0    0  1 ]
     */
    static func scale(sX sX: CGFloat, sY: CGFloat) -> NSAffineTransformStruct {
        return NSAffineTransformStruct(
            m11: sX, m12: CGFloat(),
            m21: CGFloat(), m22: sY,
            tX: CGFloat(), tY: CGFloat()
        )
    }
    
    /**
     Creates an affine transformation matrix from rotation value (angle in radians).
     The matrix takes the following form:
     
         [ cos α   -sin α  0 ]
         [ sin α    cos α  0 ]
         [   0        0    1 ]
     */
    static func rotation(radians angle: CGFloat) -> NSAffineTransformStruct {
        let α = Double(angle)
        
        return NSAffineTransformStruct(
            m11: CGFloat(cos(α)), m12: CGFloat(-sin(α)),
            m21: CGFloat(sin(α)), m22: CGFloat(cos(α)),
            tX: CGFloat(), tY: CGFloat()
        )
    }
    
    /**
     Creates an affine transformation matrix from a rotation value (angle in degrees).
     The matrix takes the following form:
     
         [ cos α   -sin α  0 ]
         [ sin α    cos α  0 ]
         [   0        0    1 ]
     */
    static func rotation(degrees angle: CGFloat) -> NSAffineTransformStruct {
        let α = Double(angle) * M_PI / 180.0
        
        return rotation(radians: CGFloat(α))
    }
    
    /**
     Creates an affine transformation matrix by combining the receiver with `transformStruct`.
     That is, it computes `T * M` and returns the result, where `T` is the receiver's and `M` is
     the `transformStruct`'s affine transformation matrix.
     The resulting matrix takes the following form:
     
                 [ m11_T  m12_T  tX_T ] [ m11_M  m12_M  tX_M ]
         T * M = [ m21_T  m22_T  tY_T ] [ m21_M  m22_M  tY_M ]
                 [   0      0      1  ] [   0      0      1  ]
     
                 [ (m11_T*m11_M + m12_T*m21_M)  (m11_T*m12_M + m12_T*m22_M)  (m11_T*tX_M + m12_T*tY_M + tX_T) ]
               = [ (m21_T*m11_M + m22_T*m21_M)  (m21_T*m12_M + m22_T*m22_M)  (m21_T*tX_M + m22_T*tY_M + tY_T) ]
                 [              0                            0                                  1             ]
     */
    func concat(transformStruct: NSAffineTransformStruct) -> NSAffineTransformStruct {
        let (t, m) = (self, transformStruct)

        return NSAffineTransformStruct(
            m11: (t.m11 * m.m11) + (t.m12 * m.m21), m12: (t.m11 * m.m12) + (t.m12 * m.m22),
            m21: (t.m21 * m.m11) + (t.m22 * m.m21), m22: (t.m21 * m.m12) + (t.m22 * m.m22),
            tX: (t.m11 * m.tX) + (t.m12 * m.tY) + t.tX,
            tY: (t.m21 * m.tX) + (t.m22 * m.tY) + t.tY
        )
    }
    
    /**
     Applies the affine transformation to `toPoint` and returns the result.
     The resulting point takes the following form:
     
         [ x' ]     [ x ]   [ m11  m12  tX ] [ x ]   [ m11*x + m12*y + tX ]
         [ y' ] = T [ y ] = [ m21  m22  tY ] [ y ] = [ m21*x + m22*y + tY ]
         [  1 ]     [ 1 ]   [  0    0    1 ] [ 1 ]   [           1        ]
     */
    func applied(toPoint p: NSPoint) -> NSPoint {
        let x = (m11 * p.x) + (m12 * p.y) + tX
        let y = (m21 * p.x) + (m22 * p.y) + tY
        
        return NSPoint(x: x, y: y)
    }
    
    /**
     Applies the affine transformation to `toSize` and returns the result.
     The resulting size takes the following form:
  
         [ w' ]     [ w ]   [ m11  m12  tX ] [ w ]   [ m11*w + m12*h ]
         [ h' ] = T [ h ] = [ m21  m22  tY ] [ h ] = [ m21*w + m22*h ]
         [  0 ]     [ 0 ]   [  0    0    1 ] [ 1 ]   [       0       ]
     
     Note: Translation has no effect on the size.
     */
    func applied(toSize s: NSSize) -> NSSize {
        let w = (m11 * s.width) + (m12 * s.height)
        let h = (m21 * s.width) + (m22 * s.height)
        
        return NSSize(width: w, height: h)
    }
    
    
    /**
     Returns the inverse affine transformation matrix or `nil` if it has no inverse.
     The receiver's affine transformation matrix can be divided into matrix sub-block as
     
         [ M  t ]
         [ 0  1 ]
     
     where `M` represents the linear map and `t` the translation vector.
     
     The inversion can then be calculated as
     
         [ inv(M)  -inv(M) * t ]
         [   0           1     ]
     
     if `M` is invertible.
     */
    var inverse: NSAffineTransformStruct? {
        get {
            // Calculate determinant of M: det(M)
            let det = (m11 * m22) - (m12 * m21)
            if det == CGFloat() {
                return nil
            }

            let detReciprocal = CGFloat(1.0) / det
            
            // Calculate the inverse of M: inv(M)
            let (invM11, invM12) = (detReciprocal *  m22, detReciprocal * -m12)
            let (invM21, invM22) = (detReciprocal * -m21, detReciprocal *  m11)
            
            // Calculate -inv(M)*t
            let invTX = ((-invM11 * tX) + (-invM12 * tY))
            let invTY = ((-invM21 * tX) + (-invM22 * tY))
            
            return NSAffineTransformStruct(
                m11: invM11, m12: invM12,
                m21: invM21, m22: invM22,
                tX: invTX, tY: invTY
            )
        }
    }
}


