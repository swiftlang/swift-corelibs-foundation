// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

internal func NSDataDeallocatorVM(_ bytes: UnsafeMutableRawPointer?, _ length: Int) {
    if let b = bytes {
        NSDeallocateMemoryPages(b, length)
    }
}

internal func NSDataDeallocatorUnmap(_ bytes: UnsafeMutableRawPointer?, _ length: Int) {
    if let b = bytes {
        munmap(b, length)
    }
}

internal func NSDataDeallocatorFree(_ bytes: UnsafeMutableRawPointer?, _ length: Int) {
    free(bytes)
}

internal func NSDataDeallocatorNone(_ bytes: UnsafeMutableRawPointer?, _ length: Int) {
}

internal final class NSConcreteData : NSData {
    var _length = 0
    var _bytes: UnsafeMutableRawPointer? = nil
    var _deallocator: ((UnsafeMutableRawPointer?, Int) -> Void)?
    var __copyWillRetain = false
    
    deinit {
        _deallocator?(_bytes, _length)
    }
    
    init(bytes: UnsafeMutableRawPointer?, length: Int, copy: Bool, deallocator: ((UnsafeMutableRawPointer?, Int) -> Void)?) {
        super.init(placeholder:())
        if length == 0 {
            deallocator?(bytes, length)
        } else if !copy {
            _bytes = bytes
            _length = length
            _deallocator = deallocator
        } else {
            _bytes = _NSDataAllocateBytes(length, false)
            _length = length
            _NSFastMemoryMove(_bytes, bytes, length)
            // Set up the deallocator to free the just-allocated bytes.
            _deallocator = NSDataDeallocatorFree
            __copyWillRetain = true
            // The given deallocator should never do anything in this case (since nobody should be passing a deallocator that does something when copy == NO), but we should still invoke it to be safe.
            deallocator?(bytes, length)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for NSConcreteData")
    }
    
    override var length: Int { return _length }
    
    override var bytes: UnsafeRawPointer {
        guard let bytes = _bytes else { return __NSDataNullBytes }
        return UnsafeRawPointer(bytes)
    }
    
    override func _copyWillRetain() -> Bool {
        return __copyWillRetain
    }
    
    override func _isCompact() -> Bool { return true }
    
    override func copy(with zone: NSZone?) -> Any {
        return _copyWillRetain() ? self : super.copy(with: zone)
    }
    
    override func getBytes(_ buffer: UnsafeMutableRawPointer, length: Int) {
        _NSFastMemoryMove(buffer, _bytes, length)
    }
    
    override func getBytes(_ buffer: UnsafeMutableRawPointer, range r: NSRange) {
        var range = r
        if range.length == 0 { return }
        _NSDataCheckBound(self, range.location, 0, _length, true)
        if range.length > _length - range.location { range.length = _length - range.location }
        _NSFastMemoryMove(buffer, _bytes?.advanced(by: range.location), range.length)
    }
    
    override func _providesConcreteBacking() -> Bool { return true }
}
