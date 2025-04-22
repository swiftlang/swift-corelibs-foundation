//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension String {
    /// Key paths can contain a `.`, but it must be escaped with a backslash `\.`. This function splits up a keypath, honoring the ability to escape a `.`.
    internal func escapedKeyPathSplit() -> [String] {
        let escapesReplaced = self.replacing("\\.", with: "A_DOT_WAS_HERE")
        // Explicitly specify Character(".") to avoid accidentally using an implicit RegexBuilder overload
        let split = escapesReplaced.split(separator: Character("."), omittingEmptySubsequences: false)
        return split.map { $0.replacingOccurrences(of: "A_DOT_WAS_HERE", with: ".") }
    }
}

extension [String] {
    /// Re-create an escaped string, if any of the components contain a `.`.
    internal func escapedKeyPathJoin() -> String {
        let comps = self.map { $0.replacingOccurrences(of: ".", with: "\\.") }
        let joined = comps.joined(separator: ".")
        return joined
    }
}

// MARK: - Get Value at Key Path

func value(atKeyPath: String, in propertyList: Any) -> Any? {
    let comps = atKeyPath.escapedKeyPathSplit()
    return _value(atKeyPath: comps, in: propertyList, remainingKeyPath: comps[comps.startIndex..<comps.endIndex])
}
     
func _value(atKeyPath: [String], in propertyList: Any, remainingKeyPath: ArraySlice<String>) -> Any? {
    if remainingKeyPath.isEmpty {
        // We're there
        return propertyList
    }
    
    guard let key = remainingKeyPath.first, !key.isEmpty else {
        return nil
    }
    
    if let dictionary = propertyList as? [String: Any] {
        if let dictionaryValue = dictionary[key] {
            return _value(atKeyPath: atKeyPath, in: dictionaryValue, remainingKeyPath: remainingKeyPath.dropFirst())
        } else {
            return nil
        }
    } else if let array = propertyList as? [Any] {
        if let lastInt = Int(key), (array.startIndex..<array.endIndex).contains(lastInt) {
            return _value(atKeyPath: atKeyPath, in: array[lastInt], remainingKeyPath: remainingKeyPath.dropFirst())
        } else {
            return nil
        }
    }
    
    return nil
}

// MARK: - Remove Value At Key Path

func removeValue(atKeyPath: String, in propertyList: Any) throws -> Any? {
    let comps = atKeyPath.escapedKeyPathSplit()
    return try _removeValue(atKeyPath: comps, in: propertyList, remainingKeyPath: comps[comps.startIndex..<comps.endIndex])
}

func _removeValue(atKeyPath: [String], in propertyList: Any, remainingKeyPath: ArraySlice<String>) throws -> Any? {
    if remainingKeyPath.isEmpty {
        // We're there
        return nil
    }

    guard let key = remainingKeyPath.first, !key.isEmpty else {
        throw PLUContextError.argument("No value to remove at key path \(atKeyPath.escapedKeyPathJoin())")
    }

    if let dictionary = propertyList as? [String: Any] {
        guard let existing = dictionary[String(key)] else {
            throw PLUContextError.argument("No value to remove at key path \(atKeyPath.escapedKeyPathJoin())")
        }
        
        var new = dictionary
        if let removed = try _removeValue(atKeyPath: atKeyPath, in: existing, remainingKeyPath: remainingKeyPath.dropFirst()) {
            new[key] = removed
        } else {
            new.removeValue(forKey: key)
        }
        return new
    } else if let array = propertyList as? [Any] {
        guard let intKey = Int(key), (array.startIndex..<array.endIndex).contains(intKey) else {
            throw PLUContextError.argument("No value to remove at key path \(atKeyPath.escapedKeyPathJoin())")
        }
        
        let existing = array[intKey]
        
        var new = array
        if let removed = try _removeValue(atKeyPath: atKeyPath, in: existing, remainingKeyPath: remainingKeyPath.dropFirst()) {
            new[intKey] = removed
        } else {
            new.remove(at: intKey)
        }
        return new
    } else {
        // Cannot descend further into the property list, but we have keys remaining in the path
        throw PLUContextError.argument("No value to remove at key path \(atKeyPath.escapedKeyPathJoin())")
    }
}

// MARK: - Insert or Replace Value At Key Path

func insertValue(_ value: Any, atKeyPath: String, in propertyList: Any, replacing: Bool, appending: Bool) throws -> Any {
    let comps = atKeyPath.escapedKeyPathSplit()
    return try _insertValue(value, atKeyPath: comps, in: propertyList, remainingKeyPath: comps[comps.startIndex..<comps.endIndex], replacing: replacing, appending: appending)
}

func _insertValue(_ value: Any, atKeyPath: [String], in propertyList: Any, remainingKeyPath: ArraySlice<String>, replacing: Bool, appending: Bool) throws -> Any {
    // Are we recursing further, or is this the place where we are inserting?
    guard let key = remainingKeyPath.first else {
        throw PLUContextError.argument("Key path not found \(atKeyPath.escapedKeyPathJoin())")
    }
    
    if let dictionary = propertyList as? [String : Any] {
        let existingValue = dictionary[key]
        if remainingKeyPath.count > 1 {
            // Descend
            if let existingValue {
                var new = dictionary
                new[key] = try _insertValue(value, atKeyPath: atKeyPath, in: existingValue, remainingKeyPath: remainingKeyPath.dropFirst(), replacing: replacing, appending: appending)
                return new
            } else {
                throw PLUContextError.argument("Key path not found \(atKeyPath.escapedKeyPathJoin())")
            }
        } else {
            // Insert
            if replacing {
                // Just slam it in
                var new = dictionary
                new[key] = value
                return new
            } else if let existingValue {
                if appending {
                    if var existingValueArray = existingValue as? [Any] {
                        existingValueArray.append(value)
                        var new = dictionary
                        new[key] = existingValueArray
                        return new
                    } else {
                        throw PLUContextError.argument("Appending to a non-array at key path \(atKeyPath.escapedKeyPathJoin())")
                    }
                } else {
                    // Not replacing, already exists, not appending to an array
                    throw PLUContextError.argument("Value already exists at key path \(atKeyPath.escapedKeyPathJoin())")
                }
            } else {
                // Still just slam it in
                var new = dictionary
                new[key] = value
                return new
            }
        }
    } else if let array = propertyList as? [Any] {
        guard let intKey = Int(key) else {
            throw PLUContextError.argument("Unable to index into array with key path \(atKeyPath.escapedKeyPathJoin())")
        }
        
        let containsKey = array.indices.contains(intKey)
        
        if remainingKeyPath.count > 1 {
            // Descend
            if containsKey {
                var new = array
                new[intKey] = try _insertValue(value, atKeyPath: atKeyPath, in: array[intKey], remainingKeyPath: remainingKeyPath.dropFirst(), replacing: replacing, appending: appending)
                return new
            } else {
                throw PLUContextError.argument("Index \(intKey) out of bounds in array at key path \(atKeyPath.escapedKeyPathJoin())")
            }
        } else {
            if appending {
                // Append to the array in this array, at this index
                guard let valueAtKey = array[intKey] as? [Any] else {
                    throw PLUContextError.argument("Attempt to append value to non-array at key path \(atKeyPath.escapedKeyPathJoin())")
                }
                var new = array
                new[intKey] = valueAtKey + [value]
                return new
            } else if containsKey {
                var new = array
                new.insert(value, at: intKey)
                return new
            } else if intKey == array.count {
                // note: the value of the integer can be out of bounds for the array (== the endIndex). We treat that as an append.
                var new = array
                new.append(value)
                return new
            } else {
                throw PLUContextError.argument("Index \(intKey) out of bounds in array at key path \(atKeyPath.escapedKeyPathJoin())")
            }
        }
    } else {
        throw PLUContextError.argument("Unable to insert value at key path \(atKeyPath.escapedKeyPathJoin())")
    }
}
