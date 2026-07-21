// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

import CoreFoundation

private func requireHashable<T: Hashable>(_: T.Type) {}

@main
struct TestCFObjectHashable {
    static func main() {
        requireHashable(CFDictionary.self)
        requireHashable(CFMutableDictionary.self)
        requireHashable(CFArray.self)
        requireHashable(CFMutableArray.self)
        requireHashable(CFSet.self)
        requireHashable(CFMutableSet.self)
        requireHashable(CFString.self)
        requireHashable(CFMutableString.self)
        requireHashable(CFData.self)
        requireHashable(CFMutableData.self)

        let lhs = CFDictionaryCreate(nil, nil, nil, 0, nil, nil)!
        let rhs = CFDictionaryCreate(nil, nil, nil, 0, nil, nil)!

        precondition(lhs == rhs)
        precondition(Set([lhs, rhs]).count == 1)
    }
}
