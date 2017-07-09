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

fileprivate var nullBytes: (Int) = (0)
internal let __NSDataNullBytes: UnsafeRawPointer = {
    return withUnsafeBytes(of: &nullBytes) {
        return $0.baseAddress!
    }
}()

internal let VM_OPS_THRESHOLD = NSPageSize() * 4

internal let SUBRANGE_THRESHOLD = 64
internal let SUBRANGE_THRESHOLD_FOR_MUTABLE_DATA = 4 * 1024 * 8

#if arch(x86_64) || arch(arm64)
internal let NSDATA_MAX_SIZE = 1 << 62
#else
internal let NSDATA_MAX_SIZE = 1 << 30
#endif


internal func _NSFastMemoryMove(_ dst: UnsafeMutableRawPointer?, _ src: UnsafeRawPointer?, _ n: Int) {
    var num = n
    var dest = dst
    var source = src
    if VM_OPS_THRESHOLD <= num && ((UInt(bitPattern: source) | UInt(bitPattern: dest)) & (UInt(NSPageSize()) - 1)) == 0 {
        let pages = NSRoundUpToMultipleOfPageSize(num)
        NSCopyMemoryPages(source, dest, pages)
        source = source?.advanced(by: pages)
        dest = dest?.advanced(by: pages)
        num -= pages
    }
    if num > 0 { memmove(dest, source, num) }
}

internal func _NSDataCheckOverflow(_ data: NSData, _ targetLoc: Int, _ targetLen: Int, _ _cmd: StaticString = #function) {
    if targetLoc > Int.max - targetLen {  
        fatalError("\(_NSMethodExceptionProem(data, _cmd)): range \(NSStringFromRange(NSMakeRange(targetLoc, targetLen))) causes integer overflow")
    }
}

internal func _NSDataCheckSize(_ data: NSData, _ size: Int, _ message: String, _ _cmd: StaticString = #function) {
    if (NSDATA_MAX_SIZE < size) {
        fatalError("\(_NSMethodExceptionProem(data, _cmd)): absurd \(message): \(size), maximum size: \(NSDATA_MAX_SIZE) bytes")
    }
}

internal func _NSDataCheckBound(_ data: NSData, _ targetLoc: Int, _ targetLen: Int, _ dataLen: Int, _ strict: Bool,  _ _cmd: StaticString = #function) {
    _NSDataCheckOverflow(data, targetLoc, targetLen, _cmd)
    if (strict && dataLen <= targetLoc + targetLen) || (!strict && dataLen < targetLoc + targetLen) {
        if targetLen == 0 {
            fatalError("\(_NSMethodExceptionProem(data, _cmd)): location \(targetLoc) exceeds data length \(dataLen)")
        } else {
            fatalError("\(_NSMethodExceptionProem(data, _cmd)): range \(NSStringFromRange(NSMakeRange(targetLoc, targetLen))) exceeds data length \(dataLen)")
        }
    }
}

internal func _NSDataAllocateBytes(_ length: Int, _ clear: Bool) -> UnsafeMutableRawPointer? {
    return clear ? calloc(length, 1) : malloc(length)
}

internal func _NSDataShouldAllocateCleared(_ size: Int) -> Bool {
    // Only "large" (> 64K in 32-bit, > 128K in 64-bit, in SnowLeopard) allocations will be vm_allocate'd, giving us cheaply zero-filled pages. However, malloc_zone_calloc does not guarantee that it will vm_allocate every time. It may possibly use a cached memory block, which it must bzero. Hence, we should only pass YES to _NSDataAllocateBytes when we are willing to pay this cost immeidately and when this function also returns YES. In 64-bit, auto_zone also uses a similar caching technique regardless of the requested size, so we should always defer clearing by returning NO.
    // These magic numbers may become stale through future revisions to malloc or auto_zone. They should be vigilantly updated.
    return (size > (128 * 1024))
}
