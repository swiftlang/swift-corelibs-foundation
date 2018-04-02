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
#elseif os(Linux)
import Glibc
#endif

#if os(macOS) || os(iOS)
fileprivate let _NSPageSize = Int(vm_page_size)
#elseif os(Linux) || os(Android)
fileprivate let _NSPageSize = Int(getpagesize())
#endif

public func NSPageSize() -> Int {
    return _NSPageSize
}

public func NSRoundUpToMultipleOfPageSize(_ size: Int) -> Int {
    let ps = NSPageSize()
    return (size + ps - 1) & ~(ps - 1)
}

public func NSRoundDownToMultipleOfPageSize(_ size: Int) -> Int {
    return size & ~(NSPageSize() - 1)
}


func NSCopyMemoryPages(_ source: UnsafeRawPointer, _ dest: UnsafeMutableRawPointer, _ bytes: Int) {
#if os(macOS) || os(iOS)
    if vm_copy(mach_task_self_, vm_address_t(bitPattern: source), vm_size_t(bytes), vm_address_t(bitPattern: dest)) != KERN_SUCCESS {
        memmove(dest, source, bytes)
    }
#else
    memmove(dest, source, bytes)
#endif
}
