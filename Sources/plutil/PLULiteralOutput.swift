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

import Foundation

internal func swiftLiteralDataWithPropertyList(_ plist: Any, originalFileName: String) throws -> Data {
    let string = try _swiftLiteralDataWithPropertyList(plist, depth: 0, indent: true, originalFilename: originalFileName)
    
    let withNewline = string.appending("\n")
    return withNewline.data(using: .utf8)!
}

internal func objcLiteralDataWithPropertyList(_ plist: Any, originalFileName: String, newFileName: String) throws -> Data {
    let string = try _objcLiteralDataWithPropertyList(plist, depth: 0, indent: true, originalFilename: originalFileName, outputFilename: newFileName)
    
    let withNewline = string.appending(";\n")
    return withNewline.data(using: .utf8)!
}

internal func objcLiteralHeaderDataWithPropertyList(_ plist: Any, originalFileName: String, newFileName: String) throws -> Data {
    let result = try _objCLiteralVaribleWithPropertyList(plist, forHeader: true, originalFilename: originalFileName, outputFilename: newFileName)
    
    // Add final semi-colon
    let withNewline = result.appending(";\n")
    return withNewline.data(using: .utf8)!
}

internal enum LiteralFormat {
    case swift
    case objc
}

internal func propertyListIsValidForLiteralFormat(_ plist: Any, format: LiteralFormat) -> Bool {
    switch format {
        case .swift:
        return PropertyListSerialization.propertyList(plist, isValidFor: .binary)
        case .objc:
        if let _ = plist as? String {
            return true
        } else if let _ = plist as? NSNumber {
            return true
        } else if let array = plist as? [Any] {
            for item in array {
                if !propertyListIsValidForLiteralFormat(item, format: format) {
                    return false
                }
            }
            return true
        } else if let dictionary = plist as? [AnyHashable: Any] {
            for (key, value) in dictionary {
                if !propertyListIsValidForLiteralFormat(key, format: format) {
                    return false
                }
                if !propertyListIsValidForLiteralFormat(value, format: format) {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
}

// MARK: - Helpers

internal func _indentation(forDepth depth: Int, numberOfSpaces: Int = 4) -> String {
    var result = ""
    for _ in 0..<depth {
        let spaces = repeatElement(Character(" "), count: numberOfSpaces)
        result.append(contentsOf: spaces)
    }
    return result
}

private func varName(from file: String) -> String {
    let filenameStem = file.stem
    var varName = filenameStem.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: " ", with: "_")
    let invalidChars = CharacterSet.symbols.union(.controlCharacters)
    while let contained = varName.rangeOfCharacter(from: invalidChars) {
        varName.removeSubrange(contained)
    }
    return varName
}

extension String {
    fileprivate var escapedForQuotesAndEscapes: String {
        var result = self
        let knownCommonEscapes = ["\\b", "\\s", "\"", "\\w", "\\.", "\\|", "\\*", "\\)", "\\("]
        
        for escape in knownCommonEscapes {
            result = result.replacingOccurrences(of: escape, with: "\\\(escape)")
        }
        
        return result
    }
}

// MARK: - ObjC

private func _objcLiteralDataWithPropertyList(_ plist: Any, depth: Int, indent: Bool, originalFilename: String, outputFilename: String) throws -> String {
    var result = ""
    if depth == 0 {
        result.append(try _objCLiteralVaribleWithPropertyList(plist, forHeader: false, originalFilename: originalFilename, outputFilename: outputFilename))
    }
    
    if indent {
        result.append(_indentation(forDepth: depth))
    }
    
    if let num = plist as? NSNumber {
        return result.appending(try num.propertyListFormatted(objCStyle: true))
    } else if let string = plist as? String {
        return result.appending("@\"\(string.escapedForQuotesAndEscapes)\"")
    } else if let array = plist as? [Any] {
        result.append("@[\n")
        for element in array {
            result.append( try _objcLiteralDataWithPropertyList(element, depth: depth + 1, indent: true, originalFilename: originalFilename, outputFilename: outputFilename))
            result.append(",\n")
        }
        result.append(_indentation(forDepth: depth))
        result.append("]")
    } else if let dictionary = plist as? [String : Any] {
        result.append("@{\n")
        let sortedKeys = Array(dictionary.keys).sorted(by: sortDictionaryKeys)
        
        for key in sortedKeys {
            result.append(_indentation(forDepth: depth + 1))
            result.append("@\"\(key)\" : ")
            let value = dictionary[key]!
            let valueString = try _objcLiteralDataWithPropertyList(value, depth: depth + 1, indent: false, originalFilename: originalFilename, outputFilename: outputFilename)
            result.append("\(valueString),\n")
        }
        result.append(_indentation(forDepth: depth))
        result.append("}")
    } else {
        throw PLUContextError.invalidPropertyListObject("Objective-C literal syntax does not support classes of type \(type(of: plist))")
    }
    return result
}

private func _objCLiteralVaribleWithPropertyList(_ plist: Any, forHeader: Bool, originalFilename: String, outputFilename: String) throws -> String {
    let objCName: String
    if let _ = plist as? NSNumber {
        objCName = "NSNumber"
    } else if let _ = plist as? String {
        objCName = "NSString"
    } else if let _ = plist as? [Any] {
        objCName = "NSArray"
    } else if let _ = plist as? [AnyHashable : Any] {
        objCName = "NSDictionary"
    } else {
        throw PLUContextError.invalidPropertyListObject("Objective-C literal syntax does not support classes of type \(type(of: plist))")
    }
    
    var result = ""
    if forHeader {
        result.append("#import <Foundation/Foundation.h>\n\n")
    } else if outputFilename != "-" {
        // Don't emit for stdout
        result.append("#import \"\(outputFilename.lastComponent?.stem ?? "").h\"\n\n")
    }
    
    
    result.append("/// Generated from \(originalFilename.lastComponent ?? "a file")\n")

    // The most common usage will be to generate things that aren't exposed to others via a public header. We default to hidden visibility so as to avoid unintended exported symbols.
    result.append("__attribute__((visibility(\"hidden\")))\n")
    
    if forHeader {
        result.append("extern ")
    }
    
    result.append("\(objCName) * const \(varName(from: originalFilename))")
    
    if !forHeader {
        result.append(" = ")
    }
    
    return result
}

// MARK: - Swift

private func _swiftLiteralDataWithPropertyList(_ plist: Any, depth: Int, indent: Bool, originalFilename: String) throws -> String {
    var result = ""
    if depth == 0 {
        result.append("/// Generated from \(originalFilename.lastComponent ?? "a file")\n")
        // Previous implementation would attempt to determine dynamically if the type annotation was by checking if there was a collection of different types. For now, this just always adds it.
        result.append("let \(varName(from: originalFilename))")
        
        // Dictionaries and Arrays need to check for specific type annotation, in case they contain different types. Other types do not.
        if let dictionary = plist as? [String: Any] {
            var lastType: PlutilExpectType?
            var needsAnnotation = false
            for (_, value) in dictionary {
                if let lastType {
                    if lastType != PlutilExpectType(propertyList: value) {
                        needsAnnotation = true
                        break
                    }
                } else {
                    lastType = PlutilExpectType(propertyList: value)
                }
            }
            
            if needsAnnotation {
                result.append(" : [String : Any]")
            }
        } else if let array = plist as? [Any] {
            var lastType: PlutilExpectType?
            var needsAnnotation = false
            for value in array {
                if let lastType {
                    if lastType != PlutilExpectType(propertyList: value) {
                        needsAnnotation = true
                        break
                    }
                } else {
                    lastType = PlutilExpectType(propertyList: value)
                }
            }
            
            if needsAnnotation {
                result.append(" : [Any]")
            }
        }

        result.append(" = ")
    }
    
    if indent {
        result.append(_indentation(forDepth: depth))
    }
    
    if let num = plist as? NSNumber {
        result.append(try num.propertyListFormatted(objCStyle: false))
    } else if let string = plist as? String {
        // FEATURE: Support triple-quote when string is multi-line.
        // For now, do one simpler thing and replace newlines with literal \n
        let escaped = string.escapedForQuotesAndEscapes.replacingOccurrences(of: "\n", with: "\\n")
        result.append("\"\(escaped)\"")
    } else if let array = plist as? [Any] {
        result.append("[\n")
        for element in array {
            result.append( try _swiftLiteralDataWithPropertyList(element, depth: depth + 1, indent: true, originalFilename: originalFilename))
            result.append(",\n")
        }
        result.append(_indentation(forDepth: depth))
        result.append("]")
    } else if let dictionary = plist as? [String : Any] {
        result.append("[\n")
        let sortedKeys = Array(dictionary.keys).sorted(by: sortDictionaryKeys)
        
        for key in sortedKeys {
            result.append(_indentation(forDepth: depth + 1))
            result.append("\"\(key)\" : ")
            let value = dictionary[key]!
            let valueString = try _swiftLiteralDataWithPropertyList(value, depth: depth + 1, indent: false, originalFilename: originalFilename)
            result.append("\(valueString),\n")
        }
        result.append(_indentation(forDepth: depth))
        result.append("]")
    } else if let data = plist as? Data {
        result.append("Data(bytes: [")
        for byte in data {
            result.append(String(format: "0x%02X", byte))
            result.append(",")
        }
        result.append("])")
    } else if let date = plist as? Date {
        result.append("Date(timeIntervalSinceReferenceDate: \(date.timeIntervalSinceReferenceDate))")
    } else {
        throw PLUContextError.invalidPropertyListObject("Swift literal syntax does not support classes of type \(type(of: plist))")
    }
    return result
}

