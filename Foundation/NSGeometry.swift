// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

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

extension CGPoint {
    public static var zero: CGPoint {
        return CGPoint(x: CGFloat(0), y: CGFloat(0))
    }
    
    public init(x: Int, y: Int) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
    
    public init(x: Double, y: Double) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
}

extension CGPoint: Equatable {
    public static func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension CGPoint: NSSpecialValueCoding {
    init(bytes: UnsafeRawPointer) {
        self.x = bytes.load(as: CGFloat.self)
        self.y = bytes.load(fromByteOffset: MemoryLayout<CGFloat>.stride, as: CGFloat.self)
    }
    
    init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        self = aDecoder.decodePoint(forKey: "NS.pointval")
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self, forKey: "NS.pointval")
    }
    
    static func objCType() -> String {
        return "{CGPoint=dd}"
    }

    func getValue(_ value: UnsafeMutableRawPointer) {
        value.initializeMemory(as: CGPoint.self, repeating: self, count: 1)
    }

    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? CGPoint {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.x.hashValue &+ self.y.hashValue
    }
    
     var description: String {
        return NSStringFromPoint(self)
    }
}

extension CGPoint : Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
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

extension CGSize {
    public static var zero: CGSize {
        return CGSize(width: CGFloat(0), height: CGFloat(0))
    }
    
    public init(width: Int, height: Int) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
    
    public init(width: Double, height: Double) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}

extension CGSize: Equatable {
    public static func ==(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension CGSize: NSSpecialValueCoding {
    init(bytes: UnsafeRawPointer) {
        self.width = bytes.load(as: CGFloat.self)
        self.height = bytes.load(fromByteOffset: MemoryLayout<CGFloat>.stride, as: CGFloat.self)
    }
    
    init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        self = aDecoder.decodeSize(forKey: "NS.sizeval")
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self, forKey: "NS.sizeval")
    }
    
    static func objCType() -> String {
        return "{CGSize=dd}"
    }
    
    func getValue(_ value: UnsafeMutableRawPointer) {
        value.initializeMemory(as: CGSize.self, repeating: self, count: 1)
    }
    
    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? CGSize {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.width.hashValue &+ self.height.hashValue
    }
    
    var description: String {
        return NSStringFromSize(self)
    }
}

extension CGSize : Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let width = try container.decode(CGFloat.self)
        let height = try container.decode(CGFloat.self)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
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

extension CGRect {
    public static var zero: CGRect {
        return CGRect(origin: CGPoint(), size: CGSize())
    }
    
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
}

extension CGRect {
    public static let null = CGRect(x: CGFloat.infinity,
                                    y: CGFloat.infinity,
                                    width: CGFloat(0),
                                    height: CGFloat(0))
    
    public static let infinite = CGRect(x: -CGFloat.greatestFiniteMagnitude / 2,
                                        y: -CGFloat.greatestFiniteMagnitude / 2,
                                        width: CGFloat.greatestFiniteMagnitude,
                                        height: CGFloat.greatestFiniteMagnitude)

    public var width: CGFloat { return abs(self.size.width) }
    public var height: CGFloat { return abs(self.size.height) }

    public var minX: CGFloat { return self.origin.x + min(self.size.width, 0) }
    public var midX: CGFloat { return (self.minX + self.maxX) * 0.5 }
    public var maxX: CGFloat { return self.origin.x + max(self.size.width, 0) }

    public var minY: CGFloat { return self.origin.y + min(self.size.height, 0) }
    public var midY: CGFloat { return (self.minY + self.maxY) * 0.5 }
    public var maxY: CGFloat { return self.origin.y + max(self.size.height, 0) }

    public var isEmpty: Bool { return self.isNull || self.size.width == 0 || self.size.height == 0 }
    public var isInfinite: Bool { return self == .infinite }
    public var isNull: Bool { return self.origin.x == .infinity || self.origin.y == .infinity }

    public func contains(_ point: CGPoint) -> Bool {
        if self.isNull || self.isEmpty { return false }

        return (self.minX..<self.maxX).contains(point.x) && (self.minY..<self.maxY).contains(point.y)
    }

    public func contains(_ rect2: CGRect) -> Bool {
        return self.union(rect2) == self
    }

    public var standardized: CGRect {
        if self.isNull { return .null }

        return CGRect(x: self.minX,
                      y: self.minY,
                      width: self.width,
                      height: self.height)
    }

    public var integral: CGRect {
        if self.isNull { return self }

        let standardized = self.standardized
        let x = standardized.origin.x.rounded(.down)
        let y = standardized.origin.y.rounded(.down)
        let width = (standardized.origin.x + standardized.size.width).rounded(.up) - x
        let height = (standardized.origin.y + standardized.size.height).rounded(.up) - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized

        rect.origin.x += dx
        rect.origin.y += dy
        rect.size.width -= 2 * dx
        rect.size.height -= 2 * dy

        if rect.size.width < 0 || rect.size.height < 0 {
            return .null
        }

        return rect
    }

    public func union(_ r2: CGRect) -> CGRect {
        if self.isNull {
            return r2
        }
        else if r2.isNull {
            return self
        }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let minX = min(rect1.minX, rect2.minX)
        let minY = min(rect1.minY, rect2.minY)
        let maxX = max(rect1.maxX, rect2.maxX)
        let maxY = max(rect1.maxY, rect2.maxY)

        return CGRect(x: minX,
                      y: minY,
                      width: maxX - minX,
                      height: maxY - minY)
    }

    public func intersection(_ r2: CGRect) -> CGRect {
        if self.isNull || r2.isNull { return .null }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let rect1SpanH = rect1.minX...rect1.maxX
        let rect1SpanV = rect1.minY...rect1.maxY

        let rect2SpanH = rect2.minX...rect2.maxX
        let rect2SpanV = rect2.minY...rect2.maxY

        if !rect1SpanH.overlaps(rect2SpanH) || !rect1SpanV.overlaps(rect2SpanV) {
            return .null
        }

        let overlapH = rect1SpanH.clamped(to: rect2SpanH)
        let overlapV = rect1SpanV.clamped(to: rect2SpanV)

        return CGRect(x: overlapH.lowerBound,
                      y: overlapV.lowerBound,
                      width: overlapH.upperBound - overlapH.lowerBound,
                      height: overlapV.upperBound - overlapV.lowerBound)
    }

    public func intersects(_ r2: CGRect) -> Bool {
        return !self.intersection(r2).isNull
    }

    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized
        rect.origin.x += dx
        rect.origin.y += dy
        return rect
    }

    public func divided(atDistance: CGFloat, from fromEdge: CGRectEdge) -> (slice: CGRect, remainder: CGRect) {
        if self.isNull { return (.null, .null) }

        let splitLocation: CGFloat
        switch fromEdge {
        case .minXEdge: splitLocation = min(max(atDistance, 0), self.width)
        case .maxXEdge: splitLocation = min(max(self.width - atDistance, 0), self.width)
        case .minYEdge: splitLocation = min(max(atDistance, 0), self.height)
        case .maxYEdge: splitLocation = min(max(self.height - atDistance, 0), self.height)
        }

        let rect = self.standardized
        var rect1 = rect
        var rect2 = rect

        switch fromEdge {
        case .minXEdge: fallthrough
        case .maxXEdge:
            rect1.size.width = splitLocation
            rect2.origin.x = rect1.maxX
            rect2.size.width = rect.width - splitLocation
        case .minYEdge: fallthrough
        case .maxYEdge:
            rect1.size.height = splitLocation
            rect2.origin.y = rect1.maxY
            rect2.size.height = rect.height - splitLocation
        }

        switch fromEdge {
        case .minXEdge: fallthrough
        case .minYEdge: return (rect1, rect2)
        case .maxXEdge: fallthrough
        case .maxYEdge: return (rect2, rect1)
        }
    }
}

extension CGRect: Equatable {
    public static func ==(lhs: CGRect, rhs: CGRect) -> Bool {
        if lhs.isNull && rhs.isNull { return true }

        let r1 = lhs.standardized
        let r2 = rhs.standardized
        return r1.origin == r2.origin && r1.size == r2.size
    }
}

extension CGRect : Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let origin = try container.decode(CGPoint.self)
        let size = try container.decode(CGSize.self)
        self.init(origin: origin, size: size)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(origin)
        try container.encode(size)
    }
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
    init(bytes: UnsafeRawPointer) {
        self.origin = CGPoint(
            x: bytes.load(as: CGFloat.self),
            y: bytes.load(fromByteOffset: 1 * MemoryLayout<CGFloat>.stride, as: CGFloat.self))
        self.size = CGSize(
            width: bytes.load(fromByteOffset: 2 * MemoryLayout<CGFloat>.stride, as: CGFloat.self),
            height: bytes.load(fromByteOffset: 3 * MemoryLayout<CGFloat>.stride, as: CGFloat.self))
    }

    init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        self = aDecoder.decodeRect(forKey: "NS.rectval")
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self, forKey: "NS.rectval")
    }
    
    static func objCType() -> String {
        return "{CGRect={CGPoint=dd}{CGSize=dd}}"
    }
    
    func getValue(_ value: UnsafeMutableRawPointer) {
        value.initializeMemory(as: CGRect.self, repeating: self, count: 1)
    }
    
    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? CGRect {
            return other == self
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.origin.hash &+ self.size.hash
    }
    
    var description: String {
        return NSStringFromRect(self)
    }
}

public enum NSRectEdge : UInt {
    
    case minX
    case minY
    case maxX
    case maxY
}

public enum CGRectEdge : UInt32 {
    
    case minXEdge
    case minYEdge
    case maxXEdge
    case maxYEdge
}

extension NSRectEdge {
    public init(rectEdge: CGRectEdge) {
        switch rectEdge {
        case .minXEdge: self = .minX
        case .minYEdge: self = .minY
        case .maxXEdge: self = .maxX
        case .maxYEdge: self = .maxY
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
    init(bytes: UnsafeRawPointer) {
        self.top = bytes.load(as: CGFloat.self)
        self.left = bytes.load(fromByteOffset: MemoryLayout<CGFloat>.stride, as: CGFloat.self)
        self.bottom = bytes.load(fromByteOffset: 2 * MemoryLayout<CGFloat>.stride, as: CGFloat.self)
        self.right = bytes.load(fromByteOffset: 3 * MemoryLayout<CGFloat>.stride, as: CGFloat.self)
    }

    init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        self.top = aDecoder._decodeCGFloatForKey("NS.edgeval.top")
        self.left = aDecoder._decodeCGFloatForKey("NS.edgeval.left")
        self.bottom = aDecoder._decodeCGFloatForKey("NS.edgeval.bottom")
        self.right = aDecoder._decodeCGFloatForKey("NS.edgeval.right")
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder._encodeCGFloat(self.top, forKey: "NS.edgeval.top")
        aCoder._encodeCGFloat(self.left, forKey: "NS.edgeval.left")
        aCoder._encodeCGFloat(self.bottom, forKey: "NS.edgeval.bottom")
        aCoder._encodeCGFloat(self.right, forKey: "NS.edgeval.right")
    }
    
    static func objCType() -> String {
        return "{NSEdgeInsets=dddd}"
    }
    
    func getValue(_ value: UnsafeMutableRawPointer) {
        value.initializeMemory(as: NSEdgeInsets.self, repeating: self, count: 1)
    }
    
    func isEqual(_ aValue: Any) -> Bool {
        if let other = aValue as? NSEdgeInsets {
            return other.top == self.top && other.left == self.left &&
                other.bottom == self.bottom && other.right == self.right
        } else {
            return false
        }
    }
    
    var hash: Int {
        return self.top.hashValue &+ self.left.hashValue &+ self.bottom.hashValue &+ self.right.hashValue
    }
    
    var description: String {
        return ""
    }
}

public struct AlignmentOptions : OptionSet {
    public var rawValue : UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    
    public static let alignMinXInward = AlignmentOptions(rawValue: 1 << 0)
    public static let alignMinYInward = AlignmentOptions(rawValue: 1 << 1)
    public static let alignMaxXInward = AlignmentOptions(rawValue: 1 << 2)
    public static let alignMaxYInward = AlignmentOptions(rawValue: 1 << 3)
    public static let alignWidthInward = AlignmentOptions(rawValue: 1 << 4)
    public static let alignHeightInward = AlignmentOptions(rawValue: 1 << 5)
    
    public static let alignMinXOutward = AlignmentOptions(rawValue: 1 << 8)
    public static let alignMinYOutward = AlignmentOptions(rawValue: 1 << 9)
    public static let alignMaxXOutward = AlignmentOptions(rawValue: 1 << 10)
    public static let alignMaxYOutward = AlignmentOptions(rawValue: 1 << 11)
    public static let alignWidthOutward = AlignmentOptions(rawValue: 1 << 12)
    public static let alignHeightOutward = AlignmentOptions(rawValue: 1 << 13)
    
    public static let alignMinXNearest = AlignmentOptions(rawValue: 1 << 16)
    public static let alignMinYNearest = AlignmentOptions(rawValue: 1 << 17)
    public static let alignMaxXNearest = AlignmentOptions(rawValue: 1 << 18)
    public static let alignMaxYNearest = AlignmentOptions(rawValue: 1 << 19)
    public static let alignWidthNearest = AlignmentOptions(rawValue: 1 << 20)
    public static let alignHeightNearest = AlignmentOptions(rawValue: 1 << 21)

    // pass this if the rect is in a flipped coordinate system. This allows 0.5 to be treated in a visually consistent way.
    public static let alignRectFlipped = AlignmentOptions(rawValue: 1 << 63)
    
    // convenience combinations
    public static let alignAllEdgesInward: AlignmentOptions = [.alignMinXInward, .alignMaxXInward, .alignMinYInward, .alignMaxYInward]
    public static let alignAllEdgesOutward: AlignmentOptions = [.alignMinXOutward, .alignMaxXOutward, .alignMinYOutward, .alignMaxYOutward]
    public static let alignAllEdgesNearest: AlignmentOptions = [.alignMinXNearest, .alignMaxXNearest, .alignMinYNearest, .alignMaxYNearest]
}

public let NSZeroPoint: NSPoint = NSPoint()
public let NSZeroSize: NSSize = NSSize()
public let NSZeroRect: NSRect = NSRect()
public let NSEdgeInsetsZero: NSEdgeInsets = NSEdgeInsets()

public func NSMakePoint(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    return NSPoint(x: x, y: y)
}

public func NSMakeSize(_ w: CGFloat, _ h: CGFloat) -> NSSize {
    return NSSize(width: w, height: h)
}

public func NSMakeRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    return NSRect(origin: NSPoint(x: x, y: y), size: NSSize(width: w, height: h))
}

public func NSMaxX(_ aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.x.native + aRect.size.width.native) }

public func NSMaxY(_ aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.y.native + aRect.size.height.native) }

public func NSMidX(_ aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.x.native + (aRect.size.width.native / 2)) }

public func NSMidY(_ aRect: NSRect) -> CGFloat { return CGFloat(aRect.origin.y.native + (aRect.size.height.native / 2)) }

public func NSMinX(_ aRect: NSRect) -> CGFloat { return aRect.origin.x }

public func NSMinY(_ aRect: NSRect) -> CGFloat { return aRect.origin.y }

public func NSWidth(_ aRect: NSRect) -> CGFloat { return aRect.size.width }

public func NSHeight(_ aRect: NSRect) -> CGFloat { return aRect.size.height }

public func NSRectFromCGRect(_ cgrect: CGRect) -> NSRect { return cgrect }

public func NSRectToCGRect(_ nsrect: NSRect) -> CGRect { return nsrect }

public func NSPointFromCGPoint(_ cgpoint: CGPoint) -> NSPoint { return cgpoint }

public func NSPointToCGPoint(_ nspoint: NSPoint) -> CGPoint { return nspoint }

public func NSSizeFromCGSize(_ cgsize: CGSize) -> NSSize { return cgsize }

public func NSSizeToCGSize(_ nssize: NSSize) -> CGSize { return nssize }

public func NSEdgeInsetsMake(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> NSEdgeInsets {
    return NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
}

public func NSEqualPoints(_ aPoint: NSPoint, _ bPoint: NSPoint) -> Bool { return aPoint == bPoint }

public func NSEqualSizes(_ aSize: NSSize, _ bSize: NSSize) -> Bool { return aSize == bSize }

public func NSEqualRects(_ aRect: NSRect, _ bRect: NSRect) -> Bool { return aRect == bRect }

public func NSIsEmptyRect(_ aRect: NSRect) -> Bool { return (aRect.size.width.native <= 0) || (aRect.size.height.native <= 0) }

public func NSEdgeInsetsEqual(_ aInsets: NSEdgeInsets, _ bInsets: NSEdgeInsets) -> Bool {
    return (aInsets.top == bInsets.top) && (aInsets.left == bInsets.left) && (aInsets.bottom == bInsets.bottom) && (aInsets.right == bInsets.right)
}

public func NSInsetRect(_ aRect: NSRect, _ dX: CGFloat, _ dY: CGFloat) -> NSRect {
    let x = CGFloat(aRect.origin.x.native + dX.native)
    let y = CGFloat(aRect.origin.y.native + dY.native)
    let w = CGFloat(aRect.size.width.native - (dX.native * 2))
    let h = CGFloat(aRect.size.height.native - (dY.native * 2))
    return NSMakeRect(x, y, w, h)
}

public func NSIntegralRect(_ aRect: NSRect) -> NSRect {
    if aRect.size.height.native <= 0 || aRect.size.width.native <= 0 {
        return NSZeroRect
    }
    
    return NSIntegralRectWithOptions(aRect, [.alignMinXOutward, .alignMaxXOutward, .alignMinYOutward, .alignMaxYOutward])
}
public func NSIntegralRectWithOptions(_ aRect: NSRect, _ opts: AlignmentOptions) -> NSRect {
    let listOfOptionsIsInconsistentErrorMessage = "List of options is inconsistent"
    
    if opts.contains(.alignRectFlipped) {
        NSUnimplemented()
    }

    var width = CGFloat.NativeType.nan
    var height = CGFloat.NativeType.nan
    var minX = CGFloat.NativeType.nan
    var minY = CGFloat.NativeType.nan
    var maxX = CGFloat.NativeType.nan
    var maxY = CGFloat.NativeType.nan

    if aRect.size.height.native < 0 {
        height = 0
    }
    if aRect.size.width.native < 0 {
        width = 0
    }
    

    if opts.contains(.alignWidthInward) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = floor(aRect.size.width.native)
    }
    if opts.contains(.alignHeightInward) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = floor(aRect.size.height.native)
    }
    if opts.contains(.alignWidthOutward) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = ceil(aRect.size.width.native)
    }
    if opts.contains(.alignHeightOutward) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = ceil(aRect.size.height.native)
    }
    if opts.contains(.alignWidthNearest) && width != 0 {
        guard width.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        width = round(aRect.size.width.native)
    }
    if opts.contains(.alignHeightNearest) && height != 0 {
        guard height.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        height = round(aRect.size.height.native)
    }

    
    if opts.contains(.alignMinXInward) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = ceil(aRect.origin.x.native)
    }
    if opts.contains(.alignMinYInward) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = ceil(aRect.origin.y.native)
    }
    if opts.contains(.alignMaxXInward) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = floor(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.alignMaxYInward) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = floor(aRect.origin.y.native + aRect.size.height.native)
    }

    
    if opts.contains(.alignMinXOutward) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = floor(aRect.origin.x.native)
    }
    if opts.contains(.alignMinYOutward) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = floor(aRect.origin.y.native)
    }
    if opts.contains(.alignMaxXOutward) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = ceil(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.alignMaxYOutward) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = ceil(aRect.origin.y.native + aRect.size.height.native)
    }
    

    if opts.contains(.alignMinXNearest) {
        guard minX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minX = round(aRect.origin.x.native)
    }
    if opts.contains(.alignMinYNearest) {
        guard minY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        minY = round(aRect.origin.y.native)
    }
    if opts.contains(.alignMaxXNearest) {
        guard maxX.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxX = round(aRect.origin.x.native + aRect.size.width.native)
    }
    if opts.contains(.alignMaxYNearest) {
        guard maxY.isNaN else { fatalError(listOfOptionsIsInconsistentErrorMessage) }
        maxY = round(aRect.origin.y.native + aRect.size.height.native)
    }
    
    var resultOriginX = CGFloat.NativeType.nan
    var resultOriginY = CGFloat.NativeType.nan
    var resultWidth = CGFloat.NativeType.nan
    var resultHeight = CGFloat.NativeType.nan
    
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

public func NSUnionRect(_ aRect: NSRect, _ bRect: NSRect) -> NSRect {
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

public func NSIntersectionRect(_ aRect: NSRect, _ bRect: NSRect) -> NSRect {
    if NSMaxX(aRect) <= NSMinX(bRect) || NSMaxX(bRect) <= NSMinX(aRect) || NSMaxY(aRect) <= NSMinY(bRect) || NSMaxY(bRect) <= NSMinY(aRect) {
        return NSZeroRect
    }
    let x = max(NSMinX(aRect), NSMinX(bRect))
    let y = max(NSMinY(aRect), NSMinY(bRect))
    let width = min(NSMaxX(aRect), NSMaxX(bRect)) - x
    let height = min(NSMaxY(aRect), NSMaxY(bRect)) - y
    return NSMakeRect(x, y, width, height)
}

public func NSOffsetRect(_ aRect: NSRect, _ dX: CGFloat, _ dY: CGFloat) -> NSRect {
    var result = aRect
    result.origin.x += dX
    result.origin.y += dY
    return result
}

public func NSDivideRect(_ inRect: NSRect, _ slice: UnsafeMutablePointer<NSRect>, _ rem: UnsafeMutablePointer<NSRect>, _ amount: CGFloat, _ edge: NSRectEdge) {
    if NSIsEmptyRect(inRect) {
        slice.pointee = NSZeroRect
        rem.pointee = NSZeroRect
        return
    }

    let width = NSWidth(inRect)
    let height = NSHeight(inRect)

    switch (edge, amount) {
    case (.minX, let amount) where amount > width:
        slice.pointee = inRect
        rem.pointee = NSMakeRect(NSMaxX(inRect), NSMinY(inRect), CGFloat(0.0), height)

    case (.minX, _):
        slice.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), amount, height)
        rem.pointee = NSMakeRect(NSMaxX(slice.pointee), NSMinY(inRect), NSMaxX(inRect) - NSMaxX(slice.pointee), height)

    case (.minY, let amount) where amount > height:
        slice.pointee = inRect
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMaxY(inRect), width, CGFloat(0.0))

    case (.minY, _):
        slice.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, amount)
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMaxY(slice.pointee), width, NSMaxY(inRect) - NSMaxY(slice.pointee))

    case (.maxX, let amount) where amount > width:
        slice.pointee = inRect
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), CGFloat(0.0), height)

    case (.maxX, _):
        slice.pointee = NSMakeRect(NSMaxX(inRect) - amount, NSMinY(inRect), amount, height)
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), NSMinX(slice.pointee) - NSMinX(inRect), height)

    case (.maxY, let amount) where amount > height:
        slice.pointee = inRect
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, CGFloat(0.0))

    case (.maxY, _):
        slice.pointee = NSMakeRect(NSMinX(inRect), NSMaxY(inRect) - amount, width, amount)
        rem.pointee = NSMakeRect(NSMinX(inRect), NSMinY(inRect), width, NSMinY(slice.pointee) - NSMinY(inRect))
    }
}

public func NSPointInRect(_ aPoint: NSPoint, _ aRect: NSRect) -> Bool {
    return NSMouseInRect(aPoint, aRect, true)
}

public func NSMouseInRect(_ aPoint: NSPoint, _ aRect: NSRect, _ flipped: Bool) -> Bool {
    if flipped {
        return aPoint.x >= NSMinX(aRect) && aPoint.y >= NSMinX(aRect) && aPoint.x < NSMaxX(aRect) && aPoint.y < NSMaxY(aRect)
    }
    return aPoint.x >= NSMinX(aRect) && aPoint.y > NSMinY(aRect) && aPoint.x < NSMaxX(aRect) && aPoint.y <= NSMaxY(aRect)
}

public func NSContainsRect(_ aRect: NSRect, _ bRect: NSRect) -> Bool {
    return !NSIsEmptyRect(bRect) && NSMaxX(bRect) <= NSMaxX(aRect) && NSMinX(bRect) >= NSMinX(aRect) &&
        NSMaxY(bRect) <= NSMaxY(aRect) && NSMinY(bRect) >= NSMinY(aRect)
}

public func NSIntersectsRect(_ aRect: NSRect, _ bRect: NSRect) -> Bool {
    return !(NSIsEmptyRect(aRect) || NSIsEmptyRect(bRect) ||
        NSMaxX(aRect) <= NSMinX(bRect) || NSMaxX(bRect) <= NSMinX(aRect) || NSMaxY(aRect) <= NSMinY(bRect) || NSMaxY(bRect) <= NSMinY(aRect))
}

public func NSStringFromPoint(_ aPoint: NSPoint) -> String {
    return "{\(aPoint.x.native), \(aPoint.y.native)}"
}

public func NSStringFromSize(_ aSize: NSSize) -> String {
    return "{\(aSize.width.native), \(aSize.height.native)}"
}

public func NSStringFromRect(_ aRect: NSRect) -> String {
    let originString = NSStringFromPoint(aRect.origin)
    let sizeString = NSStringFromSize(aRect.size)
    
    return "{\(originString), \(sizeString)}"
}

private func _scanDoublesFromString(_ aString: String, number: Int) -> [Double] {
    let scanner = Scanner(string: aString)
    var digitSet = CharacterSet.decimalDigits
    digitSet.insert(charactersIn: "-")
    var result = [Double](repeating: 0.0, count: number)
    var index = 0

    let _ = scanner.scanUpToCharactersFromSet(digitSet)
    while !scanner.isAtEnd && index < number {
        if let num = scanner.scanDouble() {
            result[index] = num
        }
        let _ = scanner.scanUpToCharactersFromSet(digitSet)
        index += 1
    }

    return result
}

public func NSPointFromString(_ aString: String) -> NSPoint {
    if aString.isEmpty {
        return NSZeroPoint
    }

    let parsedNumbers = _scanDoublesFromString(aString, number: 2)
    
    let x = parsedNumbers[0]
    let y = parsedNumbers[1]
    let result = NSMakePoint(CGFloat(x), CGFloat(y))
    
    return result
}

public func NSSizeFromString(_ aString: String) -> NSSize {
    if aString.isEmpty {
        return NSZeroSize
    }
    let parsedNumbers = _scanDoublesFromString(aString, number: 2)
    
    let w = parsedNumbers[0]
    let h = parsedNumbers[1]
    let result = NSMakeSize(CGFloat(w), CGFloat(h))
    
    return result
}

public func NSRectFromString(_ aString: String) -> NSRect {
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
    
    public func encode(_ point: NSPoint) {
        self._encodeCGFloat(point.x)
        self._encodeCGFloat(point.y)
    }
    
    public func decodePoint() -> NSPoint {
        return NSPoint(x: _decodeCGFloat(), y: _decodeCGFloat())
    }
    
    public func encode(_ size: NSSize) {
        self._encodeCGFloat(size.width)
        self._encodeCGFloat(size.height)
    }
    
    public func decodeSize() -> NSSize {
        return NSSize(width: _decodeCGFloat(), height: _decodeCGFloat())
    }
    
    public func encode(_ rect: NSRect) {
        self.encode(rect.origin)
        self.encode(rect.size)
    }
    
    public func decodeRect() -> NSRect {
        return NSRect(origin: decodePoint(), size: decodeSize())
    }
}

extension NSCoder {
    
    public func encode(_ point: NSPoint, forKey key: String) {
        self.encode(NSStringFromPoint(point)._bridgeToObjectiveC(), forKey: key)
    }
    
    public func encode(_ size: NSSize, forKey key: String) {
        self.encode(NSStringFromSize(size)._bridgeToObjectiveC(), forKey: key)
    }
    
    public func encode(_ rect: NSRect, forKey key: String) {
        self.encode(NSStringFromRect(rect)._bridgeToObjectiveC(), forKey: key)
    }
    
    public func decodePoint(forKey key: String) -> NSPoint {
        if let string = self.decodeObject(of: NSString.self, forKey: key) {
            return NSPointFromString(String._unconditionallyBridgeFromObjectiveC(string))
        } else {
            return NSPoint()
        }
    }
    
    public func decodeSize(forKey key: String) -> NSSize {
        if let string = self.decodeObject(of: NSString.self, forKey: key) {
            return NSSizeFromString(String._unconditionallyBridgeFromObjectiveC(string))
        } else {
            return NSSize()
        }
    }
    
    public func decodeRect(forKey key: String) -> NSRect {
        if let string = self.decodeObject(of: NSString.self, forKey: key) {
            return NSRectFromString(String._unconditionallyBridgeFromObjectiveC(string))
        } else {
            return NSRect()
        }
    }
}

private extension NSCoder {
    func _encodeCGFloat(_ value: CGFloat) {
        guard let keyedArchiver = self as? NSKeyedArchiver else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        keyedArchiver._encodeValue(NSNumber(value: value.native))
    }
    
    func _decodeCGFloat() -> CGFloat {
        guard let keyedUnarchiver = self as? NSKeyedUnarchiver else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard let result : NSNumber = keyedUnarchiver._decodeValue() else {
            return CGFloat(0.0)
        }
        return CGFloat(result.doubleValue)
    }
    
    func _encodeCGFloat(_ value: CGFloat, forKey key: String) {
        self.encode(value.native, forKey: key)
    }
    
    func _decodeCGFloatForKey(_ key: String) -> CGFloat {
        return CGFloat(self.decodeDouble(forKey: key))
    }
}
