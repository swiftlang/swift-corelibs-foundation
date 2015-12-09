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
    public override init() {
        transformStruct = NSAffineTransformStruct(m11: CGFloat(1.0), m12: CGFloat(), m21: CGFloat(), m22: CGFloat(1.0), tX: CGFloat(), tY: CGFloat())
    }
    
    // Translating
    public func translateXBy(deltaX: CGFloat, yBy deltaY: CGFloat) {
        let matrix = transformStruct.matrix3x3
        let translationMatrix = Matrix3x3(CGFloat(1.0), CGFloat(),    deltaX,
                                          CGFloat(),    CGFloat(1.0), deltaY,
                                          CGFloat(),    CGFloat(),    CGFloat(1.0))
        let product = multiplyMatrix3x3(matrix, byMatrix3x3: translationMatrix)
        transformStruct = NSAffineTransformStruct(matrix: product)
    }
    
    // Rotating
    public func rotateByDegrees(angle: CGFloat) { NSUnimplemented() }
    public func rotateByRadians(angle: CGFloat) { NSUnimplemented() }
    
    // Scaling
    public func scaleBy(scale: CGFloat) {
        scaleXBy(scale, yBy: scale)
    }
    
    public func scaleXBy(scaleX: CGFloat, yBy scaleY: CGFloat) {
        let matrix = transformStruct.matrix3x3
        let scaleMatrix = Matrix3x3(scaleX,    CGFloat(), CGFloat(),
                                    CGFloat(), scaleY,    CGFloat(),
                                    CGFloat(), CGFloat(), CGFloat(1.0))
        let product = multiplyMatrix3x3(matrix, byMatrix3x3: scaleMatrix)
        transformStruct = NSAffineTransformStruct(matrix: product)
    }
    
    // Inverting
    public func invert() { NSUnimplemented() }
    
    // Transforming with transform
    public func appendTransform(transform: NSAffineTransform) { NSUnimplemented() }
    public func prependTransform(transform: NSAffineTransform) { NSUnimplemented() }
    
    // Transforming points and sizes
    public func transformPoint(aPoint: NSPoint) -> NSPoint {
        let matrix = transformStruct.matrix3x3
        let vector = Vector3(aPoint.x, aPoint.y, CGFloat(1.0))
        let resultVector = multiplyMatrix3x3(matrix, byVector3: vector)
        return NSMakePoint(resultVector.m1, resultVector.m2)
    }

    public func transformSize(aSize: NSSize) -> NSSize {
        let matrix = transformStruct.matrix3x3
        let vector = Vector3(aSize.width, aSize.height, CGFloat(1.0))
        let resultVector = multiplyMatrix3x3(matrix, byVector3: vector)
        return NSMakeSize(resultVector.m1, resultVector.m2)
    }

    // Transform Struct
    public var transformStruct: NSAffineTransformStruct
}

// Private helper functions and structures for linear algebra operations.
private typealias Vector3 = (m1: CGFloat, m2: CGFloat, m3: CGFloat)
private typealias Matrix3x3 =
    (m11: CGFloat, m12: CGFloat, m13: CGFloat,
     m21: CGFloat, m22: CGFloat, m23: CGFloat,
     m31: CGFloat, m32: CGFloat, m33: CGFloat)

private func multiplyMatrix3x3(matrix: Matrix3x3, byVector3 vector: Vector3) -> Vector3 {
    let x = matrix.m11 * vector.m1 + matrix.m12 * vector.m2 + matrix.m13 * vector.m3
    let y = matrix.m21 * vector.m1 + matrix.m22 * vector.m2 + matrix.m23 * vector.m3
    let z = matrix.m31 * vector.m1 + matrix.m32 * vector.m2 + matrix.m33 * vector.m3

    return Vector3(x, y, z)
}

private func multiplyMatrix3x3(matrix: Matrix3x3, byMatrix3x3 otherMatrix: Matrix3x3) -> Matrix3x3 {
    let column1 = Vector3(otherMatrix.m11, otherMatrix.m21, otherMatrix.m31)
    let newColumn1 = multiplyMatrix3x3(matrix, byVector3: column1)

    let column2 = Vector3(otherMatrix.m12, otherMatrix.m22, otherMatrix.m32)
    let newColumn2 = multiplyMatrix3x3(matrix, byVector3: column2)

    let column3 = Vector3(otherMatrix.m13, otherMatrix.m23, otherMatrix.m33)
    let newColumn3 = multiplyMatrix3x3(matrix, byVector3: column3)

    return Matrix3x3(newColumn1.m1, newColumn2.m1, newColumn3.m1,
                     newColumn1.m2, newColumn2.m2, newColumn3.m2,
                     newColumn1.m3, newColumn2.m3, newColumn3.m3)
}

private extension NSAffineTransformStruct {
    init(matrix: Matrix3x3) {
        self.init(m11: matrix.m11, m12: matrix.m12,
                  m21: matrix.m21, m22: matrix.m22,
                   tX: matrix.m13,  tY: matrix.m23)
    }

    var matrix3x3: Matrix3x3 {
        return Matrix3x3(m11, m12, tX,
                         m21, m22, tY,
                         CGFloat(), CGFloat(), CGFloat())
    }
}
