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

extension Data {
    @available(*, unavailable, renamed: "copyBytes(to:count:)")
    public func getBytes<UnsafeMutablePointerVoid: _Pointer>(_ buffer: UnsafeMutablePointerVoid, length: Int) { }
    
    @available(*, unavailable, renamed: "copyBytes(to:from:)")
    public func getBytes<UnsafeMutablePointerVoid: _Pointer>(_ buffer: UnsafeMutablePointerVoid, range: NSRange) { }
}

extension Data {
    // Temporary until SwiftFoundation supports this
    public init(contentsOf url: URL, options: ReadingOptions = []) throws {
        self = try .init(contentsOf: url.path, options: options)
    }

    public func write(to url: URL, options: WritingOptions = []) throws {
        try write(to: url.path, options: options)
    }
}

extension Data {
    public init(referencing d: NSData) {
        self = Data(d)
    }
}

// TODO: Allow bridging via protocol
extension Data /*: _ObjectiveCBridgeable */ {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSData {
        return self.withUnsafeBytes {
            NSData(bytes: $0.baseAddress, length: $0.count)
        }
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSData, result: inout Data?) {
        // We must copy the input because it might be mutable; just like storing a value type in ObjC
        result = Data(input)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSData, result: inout Data?) -> Bool {
        // We must copy the input because it might be mutable; just like storing a value type in ObjC
        result = Data(input)
        return true
    }

//    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSData?) -> Data {
        guard let src = source else { return Data() }
        return Data(src)
    }
}

extension NSData : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(Data._unconditionallyBridgeFromObjectiveC(self))
    }
}
