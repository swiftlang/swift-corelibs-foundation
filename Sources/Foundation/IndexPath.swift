//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if DEPLOYMENT_RUNTIME_SWIFT
    
func _NSIndexPathCreateFromIndexes(_ idx1: Int, _ idx2: Int) -> NSObject {
    var indexes = (idx1, idx2)
    return withUnsafeBytes(of: &indexes) { (ptr) -> NSIndexPath in
        return NSIndexPath.init(indexes: ptr.baseAddress!.assumingMemoryBound(to: Int.self), length: 2)
    }
}
    
#else
    
@_exported import Foundation // Clang module
import _SwiftFoundationOverlayShims
    
#endif

extension IndexPath : ReferenceConvertible {
    // MARK: - Bridging Helpers
    public typealias ReferenceType = NSIndexPath
    
    fileprivate init(nsIndexPath: ReferenceType) {
        let count = nsIndexPath.length
        switch count {
        case 0:
            self.init()
        case 1:
            self.init(index: nsIndexPath.index(atPosition: 0))
        default:
            let indexes = Array<Int>(unsafeUninitializedCapacity: count) { buf, initializedCount in
                nsIndexPath.getIndexes(buf.baseAddress!, range: NSRange(location: 0, length: count))
                initializedCount = count
            }
            self.init(indexes: indexes)
        }
    }
    
    fileprivate func makeReference() -> ReferenceType {
        ReferenceType(indexes: Array(self))
    }
}

extension IndexPath : _ObjectiveCBridgeable {
    public static func _getObjectiveCType() -> Any.Type {
        return NSIndexPath.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSIndexPath {
        return makeReference()
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSIndexPath, result: inout IndexPath?) {
        result = IndexPath(nsIndexPath: x)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSIndexPath, result: inout IndexPath?) -> Bool {
        result = IndexPath(nsIndexPath: x)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSIndexPath?) -> IndexPath {
        guard let src = source else { return IndexPath() }
        return IndexPath(nsIndexPath: src)
    }
}

extension NSIndexPath : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(IndexPath(nsIndexPath: self))
    }
}
