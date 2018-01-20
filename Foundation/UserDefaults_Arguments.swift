// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

fileprivate let propertyListPrefixes: Set<Character> = [ "{", "[", "(", "<", "\"" ]

internal extension UserDefaults {
    static func _parseArguments(_ arguments: [String]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        let count = arguments.count
        
        var index = 0
        while index < count - 1 { // We're looking for pairs, so stop at the second-to-last argument.
            let current = arguments[index]
            let next = arguments[index + 1]
            if current.hasPrefix("-") && !next.hasPrefix("-") {
                // Match what Darwin does, which is to check whether the first argument is one of the characters that make up a NeXTStep-style or XML property list: open brace, open parens, open bracket, open angle bracket, or double quote. If it is, attempt parsing it as a plist; otherwise, just use the argument value as a String.
                
                let keySubstring = current[current.index(after: current.startIndex)...]
                if !keySubstring.isEmpty {
                    let key = String(keySubstring)
                    let value = next.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    var parsed = false
                    if let prefix = value.first, propertyListPrefixes.contains(prefix) {
                        if let data = value.data(using: .utf8),
                            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
                            let plistNS = plistValueAsNSObject(plist) {
                            
                            // If we can parse that argument as a plist, use the parsed value.
                            parsed = true
                            result[key] = plistNS
                            
                        }
                    }
                    
                    if !parsed, let valueNS = plistValueAsNSObject(value) {
                        result[key] = valueNS
                    }
                }
                
                index += 1 // Skip both the key and the value on this loop.
            }
            
            index += 1
        }
        
        return result
    }
}
