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

// TODO: It's not clear who is responsibile for defining these CGTypes, but we'll do it here.

public struct CGFloat {
    /// The native type used to store the CGFloat, which is Float on
    /// 32-bit architectures and Double on 64-bit architectures.
    /// We assume 64 bit for now
    public typealias NativeType = Double
    public init() {
        self.native = 0.0
    }
    public init(_ value: Float) {
        self.native = NativeType(value)
    }
    public init(_ value: Double) {
        self.native = NativeType(value)
    }
    /// The native value.
    public var native: NativeType
    
    private var hash: Int {
        return Int(self.native._toBitPattern())
    }
}

extension CGFloat: Comparable { }

public func ==(lhs: CGFloat, rhs: CGFloat) -> Bool {
    return lhs.native == rhs.native
}

public func <(lhs: CGFloat, rhs: CGFloat) -> Bool {
    return lhs.native < rhs.native
}

public func *(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs.native * rhs.native)
}

public func +(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs.native + rhs.native)
}

public func -(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs.native - rhs.native)
}

public func /(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs.native / rhs.native)
}

prefix public func -(x: CGFloat) -> CGFloat {
    return CGFloat(-x.native)
}

public func +=(inout lhs: CGFloat, rhs: CGFloat) {
    lhs.native = lhs.native + rhs.native
}

extension Double {
    public init(_ value: CGFloat) {
        self = Double(value.native)
    }
}

public struct CGPoint {
    public var x: CGFloat
    public var y: CGFloat
    public init() {
        self.init(x: CGFloat(), y: CGFloat())
    }
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

extension CGPoint: Equatable { }

public func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

extension CGPoint: NSSpecialValueCoding {
    init(bytes: UnsafePointer<Void>) {
        let buffer = UnsafePointer<CGFloat>(bytes)

        self.x = buffer.memory
        self.y = buffer.advancedBy(1).memory
    }
    
    init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            self = aDecoder.decodePointForKey("NS.pointval")
        } else {
            self = aDecoder.decodePoint()
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodePoint(self, forKey: "NS.pointval")
        } else {
            aCoder.encodePoint(self)
        }
    }
    
    static func objCType() -> String {
        return "{CGPoint=dd}"
    }

    func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<CGPoint>(value).memory = self
    }

    func isEqual(aValue: Any) -> Bool {
        if let other = aValue as? CGPoint {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.x.hash &+ self.y.hash
    }
    
     var description: String? {
        return NSStringFromPoint(self)
    }
}

public struct CGSize {
    public var width: CGFloat
    public var height: CGFloat
    public init() {
        self.init(width: CGFloat(), height: CGFloat())
    }
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

extension CGSize: Equatable { }

public func ==(lhs: CGSize, rhs: CGSize) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
}

extension CGSize: NSSpecialValueCoding {
    init(bytes: UnsafePointer<Void>) {
        let buffer = UnsafePointer<CGFloat>(bytes)

        self.width = buffer.memory
        self.height = buffer.advancedBy(1).memory
    }
    
    init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            self = aDecoder.decodeSizeForKey("NS.sizeval")
        } else {
            self = aDecoder.decodeSize()
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeSize(self, forKey: "NS.sizeval")
        } else {
            aCoder.encodeSize(self)
        }
    }
    
    static func objCType() -> String {
        return "{CGSize=dd}"
    }
    
    func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<CGSize>(value).memory = self
    }
    
    func isEqual(aValue: Any) -> Bool {
        if let other = aValue as? CGSize {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.width.hash &+ self.height.hash
    }
    
    var description: String? {
        return NSStringFromSize(self)
    }
}

public struct CGRect {
    public var origin: CGPoint
    public var size: CGSize
    public init() {
        self.init(origin: CGPoint(), size: CGSize())
    }
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
}

extension CGRect: Equatable { }

public func ==(lhs: CGRect, rhs: CGRect) -> Bool {
    return lhs.origin == rhs.origin && lhs.size == rhs.size
}

public typealias NSPoint = CGPoint

public typealias NSPointPointer = UnsafeMutablePointer<NSPoint>
public typealias NSPointArray = UnsafeMutablePointer<NSPoint>

public typealias NSSize = CGSize

public typealias NSSizePointer = UnsafeMutablePointer<NSSize>
public typealias NSSizeArray = UnsafeMutablePointer<NSSize>

public typealias NSRect = CGRect

public typealias NSRectPointer = UnsafeMutablePointer<NSRect>
public typealias NSRectArray = UnsafeMutablePointer<NSRect>

extension CGRect: NSSpecialValueCoding {
    init(bytes: UnsafePointer<Void>) {
        let buffer = UnsafePointer<CGFloat>(bytes)

        self.origin = CGPoint(x: buffer.memory, y: buffer.advancedBy(1).memory)
        self.size = CGSize(width: buffer.advancedBy(2).memory, height: buffer.advancedBy(3).memory)
    }

    init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            self = aDecoder.decodeRectForKey("NS.rectval")
        } else {
            self = aDecoder.decodeRect()
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeRect(self, forKey: "NS.rectval")
        } else {
            aCoder.encodeRect(self)
        }
    }
    
    static func objCType() -> String {
        return "{CGRect={CGPoint=dd}{CGSize=dd}}"
    }
    
    func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<CGRect>(value).memory = self
    }
    
    func isEqual(aValue: Any) -> Bool {
        if let other = aValue as? CGRect {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.origin.hash &+ self.size.hash
    }
    
    var description: String? {
        return NSStringFromRect(self)
    }
}

public enum NSRectEdge : UInt {
    
    case MinX
    case MinY
    case MaxX
    case MaxY
}

public enum CGRectEdge : UInt32 {
    
    case MinXEdge
    case MinYEdge
    case MaxXEdge
    case MaxYEdge
}

extension NSRectEdge {
    public init(rectEdge: CGRectEdge) {
        switch rectEdge {
        case .MinXEdge: self = .MinX
        case .MinYEdge: self = .MinY
        case .MaxXEdge: self = .MaxX
        case .MaxYEdge: self = .MaxY
        }
    }
}


public struct NSEdgeInsets {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init() {
        self.init(top: CGFloat(), left: CGFloat(), bottom: CGFloat(), right: CGFloat())
    }

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

extension NSEdgeInsets: NSSpecialValueCoding {
    init(bytes: UnsafePointer<Void>) {
        let buffer = UnsafePointer<CGFloat>(bytes)

        self.top = buffer.memory
        self.left = buffer.advancedBy(1).memory
        self.bottom = buffer.advancedBy(2).memory
        self.right = buffer.advancedBy(3).memory
    }

    init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            self.top = aDecoder._decodeCGFloatForKey("NS.edgeval.top")
            self.left = aDecoder._decodeCGFloatForKey("NS.edgeval.left")
            self.bottom = aDecoder._decodeCGFloatForKey("NS.edgeval.bottom")
            self.right = aDecoder._decodeCGFloatForKey("NS.edgeval.right")
        } else {
            NSUnimplemented()
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder._encodeCGFloat(self.top, forKey: "NS.edgeval.top")
            aCoder._encodeCGFloat(self.left, forKey: "NS.edgeval.left")
            aCoder._encodeCGFloat(self.bottom, forKey: "NS.edgeval.bottom")
            aCoder._encodeCGFloat(self.right, forKey: "NS.edgeval.right")
        } else {
            NSUnimplemented()
        }
    }
    
    static func objCType() -> String {
        return "{NSEdgeInsets=dddd}"
    }
    
    func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<NSEdgeInsets>(value).memory = self
    }
    
    func isEqual(aValue: Any) -> Bool {
        if let other = aValue as? NSEdgeInsets {
            return other.top == self.top && other.left == self.left &&
                other.bottom == self.bottom && other.right == self.right
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.top.hash &+ self.left.hash &+ self.bottom.hash &+ self.right.hash
    }
    
    var description: String? {
        return nil
    }
}

public struct NSAlignmentOptions : OptionSetType {
    public var rawValue : UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    
    public static let AlignMinXInward = NSAlignmentOptions(rawValue: 1 << 0)
    public static let AlignMinYInward = NSAlignmentOptions(rawValue: 1 << 1)
    public static let AlignMaxXInward = NSAlignmentOptions(rawValue: 1 << 2)
    public static let AlignMaxYInward = NSAlignmentOptions(rawValue: 1 << 3)
    public static let AlignWidthInward = NSAlignmentOptions(rawValue: 1 << 4)
    public static let AlignHeightInward = NSAlignmentOptions(rawValue: 1 << 5)
    
    public static let AlignMinXOutward = NSAlignmentOptions(rawValue: 1 << 8)
    public static let AlignMinYOutward = NSAlignmentOptions(rawValue: 1 << 9)
    public static let AlignMaxXOutward = NSAlignmentOptions(rawValue: 1 << 10)
    public static let AlignMaxYOutward = NSAlignmentOptions(rawValue: 1 << 11)
    public static let AlignWidthOutward = NSAlignmentOptions(rawValue: 1 << 12)
    public static let AlignHeightOutward = NSAlignmentOptions(rawValue: 1 << 13)
    
    public static let AlignMinXNearest = NSAlignmentOptions(rawValue: 1 << 16)
    public static let AlignMinYNearest = NSAlignmentOptions(rawValue: 1 << 17)
    public static let AlignMaxXNearest = NSAlignmentOptions(rawValue: 1 << 18)
    public static let AlignMaxYNearest = NSAlignmentOptions(rawValue: 1 << 19)
    public static let AlignWidthNearest = NSAlignmentOptions(rawValue: 1 << 20)
    public static let AlignHeightNearest = NSAlignmentOptions(rawValue: 1 << 21)

    // pass this if the rect is in a flipped coordinate system. This allows 0.5 to be treated in a visually consistent way.
    public static let AlignRectFlipped = NSAlignmentOptions(rawValue: 1 << 63)
    
    // convenience combinations
    public static let AlignAllEdgesInward = [NSAlignmentOptions.AlignMinXInward, NSAlignmentOptions.AlignMaxXInward, NSAlignmentOptions.AlignMinYInward, NSAlignmentOptions.AlignMaxYInward]
    public static let AlignAllEdgesOutward = [NSAlignmentOptions.AlignMinXOutward, NSAlignmentOptions.AlignMaxXOutward, NSAlignmentOptions.AlignMinYOutward, NSAlignmentOptions.AlignMaxYOutward]
    public static let AlignAllEdgesNearest = [NSAlignmentOptions.AlignMinXNearest, NSAlignmentOptions.AlignMaxXNearest, NSAlignmentOptions.AlignMinYNearest, NSAlignmentOptions.AlignMaxYNearest]
}

public let NSZeroPoint: NSPoint = NSPoint()
public let NSZeroSize: NSSize = NSSize()
public let NSZeroRect: NSRect = NSRect()
public let NSEdgeInsetsZero: NSEdgeInsets = NSEdgeInsets()

public func NSMakePoint(x: CGFloat, _ y: CGFloat) -> NSPoint {
    return NSPoint(x: x, y: y)
}

public func NSMakeSize(w: CGFloat, _ h: CGFloat) -> NSSize {
    return NSSize(width: w, height: h)
}

public func NSMakeRect(x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    return NSRect(origin: NSPoint(x: x, y: y), size: NSSize(width: w, height: h))
}

public func NSMaxX(aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.x.native + aRect.size.width.native) }

public func NSMaxY(aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.y.native + aRect.size.height.native) }

public func NSMidX(aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.x.native + (aRect.size.width.native / 2)) }

public func NSMidY(aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.y.native + (aRect.size.height.native / 2)) }

public func NSMinX(aRect: NSRect) -> CGFloat { return aRect.origin.x }

public func NSMinY(aRect: NSRect) -> CGFloat { return aRect.origin.y }

public func NSWidth(aRect: NSRect) -> CGFloat { return aRect.size.width }

public func NSHeight(aRect: NSRect) -> CGFloat { return aRect.size.height }

public func NSRectFromCGRect(cgrect: CGRect) -> NSRect { return cgrect }

public func NSRectToCGRect(nsrect: NSRect) -> CGRect { return nsrect }

public func NSPointFromCGPoint(cgpoint: CGPoint) -> NSPoint { return cgpoint }

public func NSPointToCGPoint(nspoint: NSPoint) -> CGPoint { return nspoint }

public func NSSizeFromCGSize(cgsize: CGSize) -> NSSize { return cgsize }

public func NSSizeToCGSize(nssize: NSSize) -> CGSize { return nssize }

public func NSEdgeInsetsMake(top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> NSEdgeInsets {
    return NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
}

public func NSEqualPoints(aPoint: NSPoint, _ bPoint: NSPoint) -> Bool { return aPoint == bPoint }

public func NSEqualSizes(aSize: NSSize, _ bSize: NSSize) -> Bool { return aSize == bSize }

public func NSEqualRects(aRect: NSRect, _ bRect: NSRect) -> Bool { return aRect == bRect }

public func NSIsEmptyRect(aRect: NSRect) -> Bool { return (aRect.size.width.native <= 0) || (aRect.size.height.native <= 0) }

public func NSEdgeInsetsEqual(aInsets: NSEdgeInsets, _ bInsets: NSEdgeInsets) -> Bool {
    return (aInsets.top == bInsets.top) && (aInsets.left == bInsets.left) && (aInsets.bottom == bInsets.bottom) && (aInsets.right == bInsets.right)
}

public func NSInsetRect(aRect: NSRect, _ dX: CGFloat, _ dY: CGFloat) -> NSRect {
    let x = CGFloat(aRect.origin.x.native + dX.native)
    let y = CGFloat(aRect.origin.y.native + dY.native)
    let w = CGFloat(aRect.size.width.native - (dX.native * 2))
    let h = CGFloat(aRect.size.height.native - (dY.native * 2))
    return NSMakeRect(x, y, w, h)
}

public func NSIntegralRect(aRect: NSRect) -> NSRect {
    if aRect.size.height.native <= 0 || aRect.size.width.native <= 0 {
        return NSZeroRect
    }
    
    return NSIntegralRectWithOptions(aRect, [.AlignMinXOutward, .AlignMaxXOutward, .AlignMinYOutward, .AlignMaxYOutward])
}
public func NSIntegralRectWithOptions(aRect: NSRect, _ opts: NSAlignmentOptions) -> NSRect {
    let listOfOptionsIsInconsistentErrorMessage = "List of options is inconsistent"
    
    if opts.contains(.AlignRectFlipped) {
        NSUnimplemented()
    }

    var width = Double.NaN
    var height = Double.NaN
    var minX = Double.NaN
    var minY = Double.NaN
    var maxX = Double.NaN
    var maxY = Double.NaN

    if aRect.size.height.native < 0 {
        height = 0
    }
    if aRect.size.width.native < 0 {
        width = 0
    }
    

    if opts.contains(.AlignWidthInward) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = floor(aRect.size.width.native)
    }
    if opts.contains(.AlignHeightInward) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = floor(aRect.size.height.native)
    }
    if opts.contains(.AlignWidthOutward) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = ceil(aRect.size.width.native)
    }
    if opts.contains(.AlignHeightOutward) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = ceil(aRect.size.height.native)
    }
    if opts.contains(.AlignWidthNearest) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = round(aRect.size.width.native)
    }
    if opts.contains(.AlignHeightNearest) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = round(aRect.size.height.native)
    }

    
    if opts.contains(.AlignMinXInward) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = ceil(aRect.origin.x.native)
    }
    if opts.contains(.AlignMinYInward) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = ceil(aRect.origin.y.native)
    }
    if opts.contains(.AlignMaxXInward) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = floor(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.AlignMaxYInward) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = floor(aRect.origin.y.native + aRect.size.height.native)
    }

    
    if opts.contains(.AlignMinXOutward) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = floor(aRect.origin.x.native)
    }
    if opts.contains(.AlignMinYOutward) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = floor(aRect.origin.y.native)
    }
    if opts.contains(.AlignMaxXOutward) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = ceil(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.AlignMaxYOutward) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = ceil(aRect.origin.y.native + aRect.size.height.native)
    }
    

    if opts.contains(.AlignMinXNearest) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = round(aRect.origin.x.native)
    }
    if opts.contains(.AlignMinYNearest) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = round(aRect.origin.y.native)
    }
    if opts.contains(.AlignMaxXNearest) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = round(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.AlignMaxYNearest) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = round(aRect.origin.y.native + aRect.size.height.native)
    }
    
    var resultOriginX = Double.NaN
    var resultOriginY = Double.NaN
    var resultWidth = Double.NaN
    var resultHeight = Double.NaN
    
    if !minX.isNaN {
        resultOriginX = minX
    }
    if !width.isNaN {
        resultWidth = width
    }
    if !maxX.isNaN {
        if width.isNaN {
            guard resultWidth.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
            resultWidth = maxX - minX
        } else {
            guard resultOriginX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
            resultOriginX = maxX - width
        }
    }
    
    
    if !minY.isNaN {
        resultOriginY = minY
    }
    if !height.isNaN {
        resultHeight = height
    }
    if !maxY.isNaN {
        if height.isNaN {
            guard resultHeight.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
            resultHeight = maxY - minY
        } else {
            guard resultOriginY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
            resultOriginY = maxY - height
        }
    }
    
    if resultOriginX.isNaN || resultOriginY.isNaN
        || resultHeight.isNaN || resultWidth.isNaN {
        fatalError(listOfOptionsIsInconsistentErrorMessage)
    }
    
    var result = NSZeroRect
    result.origin.x.native = resultOriginX
    result.origin.y.native = resultOriginY
    result.size.width.native = resultWidth
    result.size.height.native = resultHeight
    
    return result
}

public func NSUnionRect(aRect: NSRect, _ bRect: NSRect) -> NSRect {
    let isEmptyFirstRect = NSIsEmptyRect(aRect)
    let isEmptySecondRect = NSIsEmptyRect(bRect)
    if isEmptyFirstRect && isEmptySecondRect {
        return NSZeroRect
    } else if isEmptyFirstRect {
        return bRect
    } else if isEmptySecondRect {
        return aRect
    }
    let x = min(NSMinX(aRect), NSMinX(bRect))
    let y = min(NSMinY(aRect), NSMinY(bRect))
    let width = max(NSMaxX(aRect), NSMaxX(bRect)) - x
    let height = max(NSMaxY(aRect), NSMaxY(bRect)) - y
    return NSMakeRect(x, y, width, height)
}

public func NSIntersectionRect(aRect: NSRect, _ bRect: NSRect) -> NSRect {
    if NSMaxX(aRect) <= NSMinX(bRect) || NSMaxX(bRect) <= NSMinX(aRect) || NSMaxY(aRect) <= NSMinY(bRect) || NSMaxY(bRect) <= NSMinY(aRect) {
        return NSZeroRect
    }
    let x = max(NSMinX(aRect), NSMinX(bRect))
    let y = max(NSMinY(aRect), NSMinY(bRect))
    let width = min(NSMaxX(aRect), NSMaxX(bRect)) - x
    let height = min(NSMaxY(aRect), NSMaxY(bRect)) - y
    return NSMakeRect(x, y, width, height)
}

public func NSOffsetRect(aRect: NSRect, _ dX: CGFloat, _ dY: CGFloat) -> NSRect {
    var result = aRect
    result.origin.x += dX
    result.origin.y += dY
    return result
}

public func NSDivideRect(inRect: NSRect, _ slice: UnsafeMutablePointer<NSRect>, _ rem: UnsafeMutablePointer<NSRect>, _ amount: CGFloat, _ edge: NSRectEdge) {
    if NSIsEmptyRect(inRect) {
        slice.memory = NSZeroRect
        rem.memory = NSZeroRect
        return
    }

    let width = NSWidth(inRect)
    let height = NSHeight(inRect)

    switch (edge, amount) {
    case (.MinX, let amount) where amount > width:
        slice.memory = inRect
        rem.memory = NSMakeRect(NSMaxX(inRect), NSMinY(inRect), CGFloat(0.0), height)

    case (.MinX, _):
        slice.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), amount, height)
        rem.memory = NSMakeRect(NSMaxX(slice.memory), NSMinY(inRect), NSMaxX(inRect) - NSMaxX(slice.memory), height)

    case (.MinY, let amount) where amount > height:
        slice.memory = inRect
        rem.memory = NSMakeRect(NSMinX(inRect), NSMaxY(inRect), width, CGFloat(0.0))

    case (.MinY, _):
        slice.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, amount)
        rem.memory = NSMakeRect(NSMinX(inRect), NSMaxY(slice.memory), width, NSMaxY(inRect) - NSMaxY(slice.memory))

    case (.MaxX, let amount) where amount > width:
        slice.memory = inRect
        rem.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), CGFloat(0.0), height)

    case (.MaxX, _):
        slice.memory = NSMakeRect(NSMaxX(inRect) - amount, NSMinY(inRect), amount, height)
        rem.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), NSMinX(slice.memory) - NSMinX(inRect), height)

    case (.MaxY, let amount) where amount > height:
        slice.memory = inRect
        rem.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, CGFloat(0.0))

    case (.MaxY, _):
        slice.memory = NSMakeRect(NSMinX(inRect), NSMaxY(inRect) - amount, width, amount)
        rem.memory = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, NSMinY(slice.memory) - NSMinY(inRect))
    }
}

public func NSPointInRect(aPoint: NSPoint, _ aRect: NSRect) -> Bool {
    return NSMouseInRect(aPoint, aRect, true)
}

public func NSMouseInRect(aPoint: NSPoint, _ aRect: NSRect, _ flipped: Bool) -> Bool {
    if flipped {
        return aPoint.x >= NSMinX(aRect) && aPoint.y >= NSMinX(aRect) && aPoint.x < NSMaxX(aRect) && aPoint.y < NSMaxY(aRect)
    }
    return aPoint.x >= NSMinX(aRect) && aPoint.y > NSMinY(aRect) && aPoint.x < NSMaxX(aRect) && aPoint.y <= NSMaxY(aRect)
}

public func NSContainsRect(aRect: NSRect, _ bRect: NSRect) -> Bool {
    return !NSIsEmptyRect(bRect) && NSMaxX(bRect) <= NSMaxX(aRect) && NSMinX(bRect) >= NSMinX(aRect) &&
        NSMaxY(bRect) <= NSMaxY(aRect) && NSMinY(bRect) >= NSMinY(aRect)
}

public func NSIntersectsRect(aRect: NSRect, _ bRect: NSRect) -> Bool {
    return !(NSIsEmptyRect(aRect) || NSIsEmptyRect(bRect) ||
        NSMaxX(aRect) <= NSMinX(bRect) || NSMaxX(bRect) <= NSMinX(aRect) || NSMaxY(aRect) <= NSMinY(bRect) || NSMaxY(bRect) <= NSMinY(aRect))
}

public func NSStringFromPoint(aPoint: NSPoint) -> String {
    return "{\(aPoint.x.native), \(aPoint.y.native)}"
}

public func NSStringFromSize(aSize: NSSize) -> String {
    return "{\(aSize.width.native), \(aSize.height.native)}"
}

public func NSStringFromRect(aRect: NSRect) -> String {
    let originString = NSStringFromPoint(aRect.origin)
    let sizeString = NSStringFromSize(aRect.size)
    
    return "{\(originString), \(sizeString)}"
}

private func _scanDoublesFromString(aString: String, number: Int) -> [Double] {
    let scanner = NSScanner(string: aString)
    let digitSet = NSMutableCharacterSet.decimalDigitCharacterSet()
    digitSet.addCharactersInString("-")
    var result = [Double](count: number, repeatedValue: 0.0)
    var index = 0
    
    scanner.scanUpToCharactersFromSet(digitSet)
    while !scanner.atEnd && index < number {
        if let num = scanner.scanDouble() {
            result[index] = num
        }
        scanner.scanUpToCharactersFromSet(digitSet)
        index += 1
    }
    
    return result
}

public func NSPointFromString(aString: String) -> NSPoint {
    if aString.isEmpty {
        return NSZeroPoint
    }

    let parsedNumbers = _scanDoublesFromString(aString, number: 2)
    
    let x = parsedNumbers[0]
    let y = parsedNumbers[1]
    let result = NSMakePoint(CGFloat(x), CGFloat(y))
    
    return result
}

public func NSSizeFromString(aString: String) -> NSSize {
    if aString.isEmpty {
        return NSZeroSize
    }
    let parsedNumbers = _scanDoublesFromString(aString, number: 2)
    
    let w = parsedNumbers[0]
    let h = parsedNumbers[1]
    let result = NSMakeSize(CGFloat(w), CGFloat(h))
    
    return result
}

public func NSRectFromString(aString: String) -> NSRect {
    if aString.isEmpty {
        return NSZeroRect
    }
    
    let parsedNumbers = _scanDoublesFromString(aString, number: 4)
    
    let x = parsedNumbers[0]
    let y = parsedNumbers[1]
    let w = parsedNumbers[2]
    let h = parsedNumbers[3]
    
    let result = NSMakeRect(CGFloat(x), CGFloat(y), CGFloat(w), CGFloat(h))
    
    return result
}

extension NSValue {
    public convenience init(point: NSPoint) {
        self.init()
        self._concreteValue = NSSpecialValue(point)
    }
    
    public convenience init(size: NSSize) {
        self.init()
        self._concreteValue = NSSpecialValue(size)
    }
    
    public convenience init(rect: NSRect) {
        self.init()
        self._concreteValue = NSSpecialValue(rect)
    }
    
    public convenience init(edgeInsets insets: NSEdgeInsets) {
        self.init()
        self._concreteValue = NSSpecialValue(insets)
    }
    
    public var pointValue: NSPoint {
        let specialValue = self._concreteValue as! NSSpecialValue
        return specialValue._value as! NSPoint
    }
    
    public var sizeValue: NSSize {
        let specialValue = self._concreteValue as! NSSpecialValue
        return specialValue._value as! NSSize
    }
    
    public var rectValue: NSRect {
        let specialValue = self._concreteValue as! NSSpecialValue
        return specialValue._value as! NSRect
    }
    
    public var edgeInsetsValue: NSEdgeInsets {
        let specialValue = self._concreteValue as! NSSpecialValue
        return specialValue._value as! NSEdgeInsets
    }
}

extension NSCoder {
    
    public func encodePoint(point: NSPoint) {
        self._encodeCGFloat(point.x)
        self._encodeCGFloat(point.y)
    }
    
    public func decodePoint() -> NSPoint {
        return NSPoint(x: _decodeCGFloat(), y: _decodeCGFloat())
    }
    
    public func encodeSize(size: NSSize) {
        self._encodeCGFloat(size.width)
        self._encodeCGFloat(size.height)
    }
    
    public func decodeSize() -> NSSize {
        return NSSize(width: _decodeCGFloat(), height: _decodeCGFloat())
    }
    
    public func encodeRect(rect: NSRect) {
        self.encodePoint(rect.origin)
        self.encodeSize(rect.size)
    }
    
    public func decodeRect() -> NSRect {
        return NSRect(origin: decodePoint(), size: decodeSize())
    }
}

extension NSCoder {
    
    public func encodePoint(point: NSPoint, forKey key: String) {
        self.encodeObject(NSStringFromPoint(point).bridge(), forKey: key)
    }
    
    public func encodeSize(size: NSSize, forKey key: String) {
        self.encodeObject(NSStringFromSize(size).bridge(), forKey: key)
    }
    
    public func encodeRect(rect: NSRect, forKey key: String) {
        self.encodeObject(NSStringFromRect(rect).bridge(), forKey: key)
    }
    
    public func decodePointForKey(key: String) -> NSPoint {
        if let string = self.decodeObjectOfClass(NSString.self, forKey: key) {
            return NSPointFromString(string.bridge())
        } else {
            return NSPoint()
        }
    }
    
    public func decodeSizeForKey(key: String) -> NSSize {
        if let string = self.decodeObjectOfClass(NSString.self, forKey: key) {
            return NSSizeFromString(string.bridge())
        } else {
            return NSSize()
        }
    }
    
    public func decodeRectForKey(key: String) -> NSRect {
        if let string = self.decodeObjectOfClass(NSString.self, forKey: key) {
            return NSRectFromString(string.bridge())
        } else {
            return NSRect()
        }
    }
}

private extension NSCoder {
    func _encodeCGFloat(value: CGFloat) {
        if let keyedArchiver = self as? NSKeyedArchiver {
            keyedArchiver._encodeValue(NSNumber(double: value.native))
        } else {
            NSUnimplemented()
        }
    }
    
    func _decodeCGFloat() -> CGFloat {
        if let keyedUnarchiver = self as? NSKeyedUnarchiver {
            guard let result : NSNumber = keyedUnarchiver._decodeValue() else {
                return CGFloat(0.0)
            }
            return CGFloat(result.doubleValue)
        } else {
            NSUnimplemented()
        }
    }
    
    func _encodeCGFloat(value: CGFloat, forKey key: String) {
        self.encodeDouble(value.native, forKey: key)
    }
    
    func _decodeCGFloatForKey(key: String) -> CGFloat {
        return CGFloat(self.decodeDoubleForKey(key))
    }
}
