// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal import CoreFoundation

extension CFKeyedArchiverUID : _NSBridgeable {
    typealias NSType = _NSKeyedArchiverUID
    
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
}

final internal class _NSKeyedArchiverUID : NSObject, Sendable {
    typealias CFType = CFKeyedArchiverUID
    internal let _base = _CFInfo(typeID: _CFKeyedArchiverUIDGetTypeID())
    internal let value : UInt32
    
    internal var _cfObject : CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    override var _cfTypeID: CFTypeID {
        return _CFKeyedArchiverUIDGetTypeID()
    }

    override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject as CFTypeRef?))
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        // no need to compare these?
        return false
    }
    
    init(value : UInt32) {
        self.value = value
    }
    
    deinit {
        _CFDeinit(self)
    }
}
