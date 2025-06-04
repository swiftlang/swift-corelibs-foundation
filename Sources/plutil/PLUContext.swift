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

@_spi(BooleanCheckingForPLUtil)
import Foundation

func help(_ name: String) -> String {
    name +
"""
: [command_option] [other_options] file...
The file '-' means stdin
Running in Swift mode
Command options are (-lint is the default):
 -help                         show this message and exit
 -lint                         check the property list files for syntax errors
 -convert fmt                  rewrite property list files in format
                               fmt is one of: xml1 binary1 json swift objc
                               note: objc can additionally create a header by adding -header
 -insert keypath -type value   insert a value into the property list before writing it out
                               keypath is a key-value coding key path, with one extension:
                               a numerical path component applied to an array will act on the object at that index in the array
                               or insert it into the array if the numerical path component is the last one in the key path
                               type is one of: bool, integer, float, date, string, data, xml, json
                               -bool: YES if passed "YES" or "true", otherwise NO
                               -integer: any valid 64 bit integer
                               -float: any valid 64 bit float
                               -string: UTF8 encoded string
                               -date: a date in XML property list format, not supported if outputting JSON
                               -data: a base-64 encoded string
                               -xml: an XML property list, useful for inserting compound values
                               -json: a JSON fragment, useful for inserting compound values
                               -dictionary: inserts an empty dictionary, does not use value
                               -array: inserts an empty array, does not use value
                               
                               optionally, -append may be specified if the keypath references an array to append to the
                               end of the array
                               value YES, NO, a number, a date, or a base-64 encoded blob of data
 -replace keypath -type value  same as -insert, but it will overwrite an existing value
 -remove keypath               removes the value at 'keypath' from the property list before writing it out
 -extract keypath fmt          outputs the value at 'keypath' in the property list as a new plist of type 'fmt'
                               fmt is one of: xml1 binary1 json raw
                               an additional "-expect type" option can be provided to test that
                               the value at the specified keypath is of the specified "type", which
                               can be one of: bool, integer, float, string, date, data, dictionary, array
                               
                               when fmt is raw: 
                                   the following is printed to stdout for each value type:
                                       bool: the string "true" or "false"
                                       integer: the numeric value
                                       float: the numeric value
                                       string: as UTF8-encoded string
                                       date: as RFC3339-encoded string in UTC timezone
                                       data: as base64-encoded string
                                       dictionary: each key on a new line
                                       array: the count of items in the array
                                   by default, the output is to stdout unless -o is specified
 -type keypath                 outputs the type of the value at 'keypath' in the property list
                               can be one of: bool, integer, float, string, date, data, dictionary, array
 -create fmt                   creates an empty plist of the specified format
                               file may be '-' for stdout
 -p                            print property list in a human-readable fashion
                               (not for machine parsing! this 'format' is not stable)
There are some additional optional arguments that apply to the -convert, -insert, -remove, -replace, and -extract verbs:
 -s                            be silent on success
 -o path                       specify alternate file path name for result;
                               the -o option is used with -convert, and is only
                               useful with one file argument (last file overwrites);
                               the path '-' means stdout
 -e extension                  specify alternate extension for converted files
 -r                            if writing JSON, output in human-readable form
 -n                            prevent printing a terminating newline if it is not part of the format, such as with raw
 --                            specifies that all further arguments are file names

"""
}

enum PLUCommand {
    case lint(LintCommand)
    case help(HelpCommand)
    case convert(ConvertCommand)
    case insertOrReplace(InsertCommand)
    case remove(RemoveCommand)
    case extractOrType(ExtractCommand)
    case print(PrintCommand)
    case create(CreateCommand)
    
    func execute() throws -> Bool {
        return switch self {
        case .lint(let cmd): try cmd.execute()
        case .help(let cmd): try cmd.execute()
        case .convert(let cmd): try cmd.execute()
        case .insertOrReplace(let cmd): try cmd.execute()
        case .remove(let cmd): try cmd.execute()
        case .extractOrType(let cmd): try cmd.execute()
        case .print(let cmd): try cmd.execute()
        case .create(let cmd): try cmd.execute()
        }
    }
    
    /// Initialize a command with a set of arguments.
    init(arguments inArguments: [String], outputFileHandle: FileHandle, errorFileHandle: FileHandle) throws {
        // Some argument parsing is done here, then the rest is done inside each command using a combination of `PLUContextArguments` and its own custom argument handling.
        // The format of the arguments is bespoke to plutil and does not follow standard argument parsing rules.
        
        var arguments = inArguments
        
        // Get the process path, for help
        guard let path = arguments.popFirst() else {
            throw PLUContextError.argument("No files specified.")
        }
                
        // The command should be the second argument passed
        guard let specifiedCommand = arguments.popFirst() else {
            throw PLUContextError.argument("No files specified.")
        }
        
        switch specifiedCommand {
        case "-help":
            let processName = path.lastComponent ?? "plutil"
            self = .help(HelpCommand(name: processName, output: outputFileHandle))
        case "-lint":
            self = .lint(LintCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments))
        case "-convert":
            guard let inFormat = arguments.popFirst() else {
                throw PLUContextError.argument("Missing format specifier for command.")
            }
            
            let format = try PlutilEmissionFormat(argumentValue: inFormat)
            
            if arguments.first == "-header" {
                // header isn't supported for any other convert command
                guard format == .objc else {
                    throw PLUContextError.argument("-header is only valid for objc literal conversions.")
                }
                
                // throw away the -header arg
                arguments.removeFirst()
                self = .convert(ConvertCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, specifiedFormat: format, outputObjCHeader: true))
            } else {
                self = .convert(ConvertCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, specifiedFormat: format, outputObjCHeader: false))
            }
        case "-p":
            self = .print(PrintCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments))
        case "-insert":
            self = .insertOrReplace(InsertCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, replace: false))
        case "-replace":
            self = .insertOrReplace(InsertCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, replace: true))
        case "-remove":
            guard let keyPath = arguments.popFirst() else {
                throw PLUContextError.argument("'Remove' requires a key path.")
            }
                        
            self = .remove(RemoveCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, keyPath: keyPath))
        case "-extract":
            guard let keyPath = arguments.popFirst() else {
                throw PLUContextError.argument("'Extract' requires a key path and a plist format.")
            }
            
            guard let inFormat = arguments.popFirst() else {
                throw PLUContextError.argument("'Extract' requires a key path and a plist format.")
            }
            
            let format = try PlutilEmissionFormat(argumentValue: inFormat)

            if arguments.first == "-expect" {
                // Throw away -expect
                arguments.removeFirst()
                
                guard let inExpect = arguments.popFirst() else {
                    throw PLUContextError.argument("-expect requires a type argument.")
                }
                
                guard let expect = PlutilExpectType(rawValue: inExpect) else {
                    throw PLUContextError.argument("-expect type [\(inExpect)] not valid.")
                }
                
                self = .extractOrType(ExtractCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, keyPath: keyPath, specifiedFormat: format, expectType: expect))
            } else {
                self = .extractOrType(ExtractCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, keyPath: keyPath, specifiedFormat: format, expectType: nil))
            }
        case "-type":
            // This is a special case of 'extract' that verifies the type of the value at the key path
            guard let keyPath = arguments.popFirst() else {
                throw PLUContextError.argument("'Extract' requires a key path and a plist format.")
            }
            
            if arguments.first == "-expect" {
                // Throw away -expect
                arguments.removeFirst()
                
                guard let inExpect = arguments.popFirst() else {
                    throw PLUContextError.argument("-expect requires a type argument.")
                }
                
                guard let expect = PlutilExpectType(rawValue: inExpect) else {
                    throw PLUContextError.argument("-expect type [\(inExpect)] not valid.")
                }
                
                self = .extractOrType(ExtractCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, keyPath: keyPath, specifiedFormat: .type, expectType: expect))
            } else {
                self = .extractOrType(ExtractCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, keyPath: keyPath, specifiedFormat: .type, expectType: nil))
            }
        case "-create":
            guard let inFormat = arguments.popFirst() else {
                throw PLUContextError.argument("'Create' requires a plist format.")
            }
            
            // Historical meaning for "NoConversion" here is xml
            let format = try PlutilEmissionFormat(argumentValue: inFormat) ?? .xml
         
            self = .create(CreateCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: arguments, format: format))
        default:
            // Use lint by default. Restore the name of the file we popped off thinking it was the command name.
            self = .lint(LintCommand(output: outputFileHandle, errorOutput: errorFileHandle, arguments: [specifiedCommand] + arguments))
        }
    }
}

/// An enum representing the possible plist emission formats. If initialized with a raw value, and the result is `nil`, treat that as no conversion.
enum PlutilEmissionFormat {
    case openStep
    case xml
    case binary
    case json
    case swift
    case objc
    case raw
    case type
    
    var propertyListFormat: PropertyListSerialization.PropertyListFormat {
        switch self {
        case .xml: .xml
        default: .binary
        }
    }
        
    init?(argumentValue: String) throws {
        if argumentValue == "NoConversion" {
            return nil
        } else {
            self = switch argumentValue {
            case "openStep": .openStep
            case "xml1": .xml
            case "binary1": .binary
            case "json": .json
            case "swift": .swift
            case "objc": .objc
            case "raw": .raw
            case "type": .type // aka "EmissionFormat"
            default:
                throw PLUContextError.argument("Unknown format specifier: \(argumentValue)")
            }
        }
    }
}

extension NSNumber {
    enum BetterSwiftType {
        case `true`
        case `false`
        case signed
        case unsigned
        case double
        case float
        case other
    }
    
    var betterSwiftType: BetterSwiftType {
        if let booleanValue = _exactBoolValue {
            if booleanValue {
                return .true
            } else {
                return .false
            }
        }
        switch UInt8(self.objCType.pointee) {
        case UInt8(ascii: "c"), UInt8(ascii: "s"), UInt8(ascii: "i"), UInt8(ascii: "l"), UInt8(ascii: "q"):
            return .signed
        case UInt8(ascii: "C"), UInt8(ascii: "S"), UInt8(ascii: "I"), UInt8(ascii: "L"), UInt8(ascii: "Q"):
            return .unsigned
        case UInt8(ascii: "d"):
            return .double
        case UInt8(ascii: "f"):
            return .float
        default:
            // Something else
            return .other
        }
    }
    
    /// This number formatted for raw, Swift, or ObjC output. Raw and Swift output are the same.
    func propertyListFormatted(objCStyle: Bool) throws -> String {
        // For now, use the Objective-C based formatting API for consistency with pre-Swift plutil.
        let formatted = switch betterSwiftType {
        case .true:
            objCStyle ? "YES" : "true"
        case .false:
            objCStyle ? "NO" : "false"
        case .signed:
            String(format: "%lld", int64Value)
        case .unsigned:
            String(format: "%llu", uint64Value)
        case .double:
            // TODO: We know this should be %lf - but for now we use %f for compatibility with the ObjC implementation.
            String(format: "%f", doubleValue)
        case .float:
            String(format: "%f", doubleValue)
        case .other:
            throw PLUContextError.invalidPropertyListObject("Incorrect numeric type for literal \(objCType)")
        }
        
        if objCStyle {
            return "@\(formatted)"
        } else {
            return formatted
        }
    }
}

enum PlutilExpectType : String {
    case `any` = "(any)"
    case boolean = "bool"
    case integer = "integer"
    case float = "float"
    case string = "string"
    case array = "array"
    case dictionary = "dictionary"
    case date = "date"
    case data = "data"
    
    init(propertyList: Any) {
        if let num = propertyList as? NSNumber {
            switch num.betterSwiftType {
            case .true, .false:
                self = .boolean
            case .signed, .unsigned:
                self = .integer
            case .double, .float:
                self = .float
            case .other:
                self = .any
            }
        } else if propertyList is String {
            self = .string
        } else if propertyList is [Any] {
            self = .array
        } else if propertyList is [AnyHashable: Any] {
            self = .dictionary
        } else if propertyList is Date {
            self = .date
        } else if propertyList is Data {
            self = .data
        } else {
            // Something else
            self = .any
        }
    }
    
    var description: String {
        rawValue
    }
}

enum PLUContextError : Error {
    case argument(String)
    case invalidPropertyListObject(String)
    case invalidPropertyList(plistError: NSError, jsonError: NSError)
    
    var description: String {
        switch self {
            case .argument(let description):
                return description
            case .invalidPropertyListObject(let description):
                return description
            case .invalidPropertyList(let plistError, let jsonError):
                let plistErrorMessage = plistError.userInfo[NSDebugDescriptionErrorKey] ?? "<unknown error>"
                let jsonErrorMessage = jsonError.userInfo[NSDebugDescriptionErrorKey] ?? "<unknown error>"

                return "Property List error: \(plistErrorMessage) / JSON error: \(jsonErrorMessage)"
        }
    }
}

extension Array {
    // [String] does not have SubSequence == Self, so `Collection`'s `popFirst` is unavailable.
    // We're dealing with tiny arrays, so just deal with the potentially not-O(1) behavior of removeFirst.
    mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
}

#if FOUNDATION_FRAMEWORK
// This should be Foundation API, but it's not yet. Since this is an executable and not a framework we can use the retroactive conformance until it is ready.
extension FileHandle : @retroactive TextOutputStream {
    public func write(_ string: String) {
        write(string.data(using: .utf8)!)
    }
}
#else
extension FileHandle : TextOutputStream {
    public func write(_ string: String) {
        write(string.data(using: .utf8)!)
    }
}
#endif

extension FileHandle {
    func write(_ string: String, aboutPath path: String) {
        let fixedPath = path == "-" ? "<stdin>" : path
        write("\(fixedPath): \(string)")
        write("\n")
    }
    
    func write(_ error: Error, aboutPath path: String) {
        let fixedPath = path == "-" ? "<stdin>" : path
        write("\(fixedPath): ")
        if let pluError = error as? PLUContextError {
            // Don't localize these
            write(pluError.description)
        } else {
            let debugDescription = (error as NSError).userInfo[NSDebugDescriptionErrorKey]
            write("(\(debugDescription ?? error.localizedDescription))")
        }
        write("\n")
    }

}

// MARK: - Commands


struct LintCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    
    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)
        
        // lint validates some of its arguments
        if let _ = parsedArguments.outputFileName {
            throw PLUContextError.argument("-o is not used with -lint.")
        }
        
        if let _ = parsedArguments.outputFileExtension {
            throw PLUContextError.argument("-e is not used with -lint.")
        }
        
        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data = try readPath(path)
                let _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                
                // FEATURE: This linting option has never linted JSON, but it could. Optionally -- since property lists are not actually JSON.
                if !(parsedArguments.silent ?? false) {
                    output.write("OK", aboutPath: path)
                }
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        
        return !oneError
    }
}

struct HelpCommand {
    let name: String
    let output: FileHandle
    func execute() throws -> Bool {
        output.write(help(name))
        return true
    }
}

struct ConvertCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    /// `nil` means no conversion.
    let specifiedFormat: PlutilEmissionFormat?
    let outputObjCHeader: Bool

    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)

        var oneError = false
        for path in parsedArguments.paths {
            
            do {
                let fileData = try readPath(path)
                let (plist, existingFormat) = try readPropertyList(fileData)
                
                let outputFormat = specifiedFormat ?? existingFormat
                
                try writePropertyList(plist, path: path, standardOutput: output, outputFormat: outputFormat, outputName: parsedArguments.outputFileName, extensionName: parsedArguments.outputFileExtension, originalKeyPath: nil, readable: parsedArguments.readable, terminatingNewline: parsedArguments.terminatingNewline, outputObjCHeader: outputObjCHeader)
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        
        return !oneError
    }
}

struct InsertCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    let replace: Bool

    func execute() throws -> Bool {
        // First argument must be the key path
        var remainingArguments = arguments

        guard let keyPath = remainingArguments.popFirst() else {
            throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value.")
        }
        
        // Second argument must be the type
        guard let type = remainingArguments.popFirst() else {
            throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value.")
        }
        
        var value: Any
        
        switch type {
        case "-bool":
            guard let boolValue = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            if boolValue.lowercased() == "true" || boolValue.lowercased() == "yes" {
                value = NSNumber(value: true)
            } else {
                value = NSNumber(value: false)
            }
        case "-integer":
            guard let integerValue = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            value = NSNumber(value: (integerValue as NSString).integerValue)
        case "-date":
            guard let dateValue = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            // Hack to parse dates just like plists do
            let xmlPlistDateString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>value</key><date>\(dateValue)</date></dict></plist>"
            let xmlPlistData = xmlPlistDateString.data(using: .utf8)!
            let xmlPlistDict = try? PropertyListSerialization.propertyList(from: xmlPlistData, format: nil)
            value = (xmlPlistDict as! [String: Any])["value"]!
        case "-data":
            guard let dataValue = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            
            guard let data = Data(base64Encoded: dataValue, options: .ignoreUnknownCharacters) else {
                throw PLUContextError.argument("Invalid base64 data in argument")
            }
            
            value = data
        case "-float":
            guard let floatValue = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            value = NSNumber(value: (floatValue as NSString).doubleValue)
        case "-xml":
            guard let xmlString = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            
            do {
                value = try PropertyListSerialization.propertyList(from: xmlString.data(using: .utf8)!, format: nil)
            } catch {
                throw PLUContextError.argument("Unable to parse xml property list: \(error)")
            }
        case "-json":
            guard let jsonString = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            
            do {
                value = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: [.allowFragments, .mutableLeaves, .mutableContainers])
            } catch {
                throw PLUContextError.argument("Unable to parse JSON: \(error)")
            }
        case "-string":
            guard let string = remainingArguments.popFirst() else {
                throw PLUContextError.argument("'Insert' and 'Replace' require a key path, a type, and a value2.")
            }
            value = string
        case "-dictionary":
            // No next argument required
            value = Dictionary<String, Any>()
        case "-array":
            // No next argument required
            value = Array<Any>()
        default:
            throw PLUContextError.argument("Unknown insert or replace type \(type)")
        }
        
        var append = false
        if let next = remainingArguments.first, next == "-append" {
            remainingArguments.removeFirst()
            if replace == false {
                append = true
            }
        }

        // Remaining arguments are append and path names
        let parsedArguments = try PLUContextArguments(arguments: remainingArguments)

        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data = try readPath(path)
                let (inputPropertyList, outputFormat) = try readPropertyList(data)
                
                let propertyList = try insertValue(value, atKeyPath: keyPath, in: inputPropertyList, replacing: replace, appending: append)
                
                try writePropertyList(propertyList, path: path, standardOutput: output, outputFormat: outputFormat, outputName: parsedArguments.outputFileName, extensionName: parsedArguments.outputFileExtension, originalKeyPath: keyPath, readable: parsedArguments.readable, terminatingNewline: parsedArguments.terminatingNewline, outputObjCHeader: false)
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        return !oneError
    }
}

struct RemoveCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    let keyPath: String
    
    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)
        
        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data = try readPath(path)
                let (inputPropertyList, outputFormat) = try readPropertyList(data)
                
                guard let propertyList = try removeValue(atKeyPath: keyPath, in: inputPropertyList) else {
                    throw PLUContextError.argument("Removing value resulted in an empty property list at \(keyPath)")
                }
                                
                try writePropertyList(propertyList, path: path, standardOutput: output, outputFormat: outputFormat, outputName: parsedArguments.outputFileName, extensionName: parsedArguments.outputFileExtension, originalKeyPath: keyPath, readable: parsedArguments.readable, terminatingNewline: parsedArguments.terminatingNewline, outputObjCHeader: false)
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        return !oneError
    }
}

struct ExtractCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    let keyPath: String
    let specifiedFormat: PlutilEmissionFormat?
    let expectType: PlutilExpectType?

    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)
        
        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data = try readPath(path)
                let (inputPropertyList, existingFormat) = try readPropertyList(data)
                
                let outputFormat = specifiedFormat ?? existingFormat

                guard let propertyList = value(atKeyPath: keyPath, in: inputPropertyList) else {
                    throw PLUContextError.argument("Could not extract value, error: No value at that key path or invalid key path: \(keyPath)")
                }
                                
                if let expectType {
                    let actualType = PlutilExpectType(propertyList: propertyList)
                    if actualType != expectType {
                        throw PLUContextError.invalidPropertyListObject("Value at [\(keyPath)] expected to be \(expectType) but is \(actualType)")
                    }
                }
                
                try writePropertyList(propertyList, path: path, standardOutput: output, outputFormat: outputFormat, outputName: parsedArguments.outputFileName, extensionName: parsedArguments.outputFileExtension, originalKeyPath: keyPath, readable: parsedArguments.readable, terminatingNewline: parsedArguments.terminatingNewline, outputObjCHeader: false)
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        return !oneError
    }
}

struct PrintCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]

    func prettyPrint(_ value: Any, indent: Int, spacing: Int) throws -> String {
        var result = ""
        if let dictionary = value as? [String: Any] {
            let sortedKeys = Array(dictionary.keys).sorted(by: sortDictionaryKeys)
            
            result.append("{\n")
            for key in sortedKeys {
                let value = dictionary[key]!
                result.append(_indentation(forDepth: indent, numberOfSpaces: 1))
                result.append("\"\(key)\" => ")
                result.append(try prettyPrint(value, indent: indent + spacing, spacing: spacing))
            }
            result.append(_indentation(forDepth: indent - spacing, numberOfSpaces: 1))
            result.append("}\n")
        } else if let array = value as? [Any] {
            result.append("[\n")
            for (index, value) in array.enumerated() {
                result.append(_indentation(forDepth: indent, numberOfSpaces: 1))
                result.append("\(index) => ")
                result.append(try prettyPrint(value, indent: indent + spacing, spacing: spacing))
            }
            result.append(_indentation(forDepth: indent - spacing, numberOfSpaces: 1))
            result.append("]\n")
        } else if let string = value as? String {
            result.append("\"\(string)\"\n")
        } else if let data = value as? Data {
            let count = data.count
            result.append("{length = \(count), bytes = 0x")
            if count > 24 {
                for i in stride(from: 0, to: 16, by: 2) {
                    result.append(String(data[i], radix: 16))
                }
                result.append("... ")
                for i in (count - 8)..<count {
                    result.append(String(data[i], radix: 16))
                }
            } else {
                for i in 0..<count {
                    result.append(String(data[i], radix: 16))
                }
            }
            result.append("}\n")
        } else if let date = value as? Date {
            let description = date.description
            result.append("\(description)\n")
        } else if let bool = value as? NSNumber, bool.betterSwiftType == .false {
            result.append("false\n")
        } else if let bool = value as? NSNumber, bool.betterSwiftType == .true {
            result.append("true\n")
        } else if let number = value as? NSNumber {
            let description = number.description
            result.append("\(description)\n")
        } else {
            throw PLUContextError.argument("Unknown property list type")
        }
        return result
    }
    
    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)
        
        // print validates a few more of its arguments than the other commands
        if let _ = parsedArguments.outputFileName {
            throw PLUContextError.argument("-o is not used with -p.")
        }
        
        if let _ = parsedArguments.outputFileExtension {
            throw PLUContextError.argument("-e is not used with -p.")
        }
        
        if let _ = parsedArguments.silent {
            // We print a message but just continue on; not an error
            errorOutput.write("-s doesn't make a lot of sense with -p.\n")
        }

        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data = try readPath(path)
                var canContainInfoPlist = false
                
#if FOUNDATION_FRAMEWORK
                // Only Darwin executables can contain Info.plist content in their mach-o segment. This function copies it out of the segment and parses it with CFPropertyList.
                let embeddedPListResult = _CFBundleCopyInfoDictionaryForExecutableFileData(data as NSData, &canContainInfoPlist)
                if let embeddedPListResult {
                    // consume the retain here
                    let cf = embeddedPListResult
                    if let dict = cf as? [String : Any] {
                        let result = try prettyPrint(dict, indent: 2, spacing: 2)
                        output.write(result)
                    } else {
                        // This really should not be possible, but it's difficult to prove that from all of the casting going on in the CF path
                        oneError = true
                        throw PLUContextError.argument("\(path): file was executable or library type but embedded Info.plist did not contain String keys")
                    }
                    continue
                } else if canContainInfoPlist {
                    throw PLUContextError.invalidPropertyListObject("file was executable or library type but did not contain an embedded Info.plist")
                }
#endif
                let (plist, _) = try readPropertyList(data)
                let result = try prettyPrint(plist, indent: 2, spacing: 2)
                output.write(result)
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        
        return !oneError
    }
}

struct CreateCommand {
    let output: FileHandle
    let errorOutput: FileHandle
    let arguments: [String]
    let format: PlutilEmissionFormat
    
    func execute() throws -> Bool {
        let parsedArguments = try PLUContextArguments(arguments: arguments)

        var oneError = false
        for path in parsedArguments.paths {
            do {
                let data: Data
                
                switch format {
                case .json:
                    data = try JSONSerialization.data(withJSONObject: [:], options: parsedArguments.readable ? [.prettyPrinted, .sortedKeys] : [])
                case .xml:
                    data = try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
                case .binary:
                    data = try PropertyListSerialization.data(fromPropertyList: [:], format: .binary, options: 0)
                case .swift:
                    // Somewhat useless, but historically what plutil provides
                    data =
                    """
                    /// Generated from -
                    let - = [
                        ]
                    """.data(using: .utf8)!
                case .objc:
                    // Somewhat useless, but historically what plutil provides
                    data =
                    """
                    /// Generated from -
                    __attribute__((visibility("hidden")))
                    NSDictionary * const _ = @{
                    };
                    """.data(using: .utf8)!
                case .raw:
                    // Somewhat useless, but historically what plutil provides
                    data = "\n".data(using: .utf8)!
                case .type:
                    let type = PlutilExpectType(propertyList: [:])
                    data = type.rawValue.data(using: .utf8)!
                case .openStep:
                    throw PLUContextError.argument("Cannot create open step property lists")
                }
                
                if path == "-" {
                    try output.write(contentsOf: data)
                    if parsedArguments.terminatingNewline && (format == .raw || format == .type) {
                        output.write("\n")
                    }
                } else {
                    try data.write(to: path.url)
                }
            } catch {
                oneError = true
                errorOutput.write(error, aboutPath: path)
                // Continue on
            }
        }
        
        return !oneError
    }
}

// MARK: -

/// Read from a path, or stdin. Returns the path name to use for errors, and the data.
func readPath(_ path: String) throws -> Data {
    if path == "-" {
        let stdinData = try FileHandle.standardInput.readToEnd()
        guard let stdinData else {
            throw CocoaError(.fileReadUnknown, userInfo: [NSDebugDescriptionErrorKey: "Unable to read file from standard input"])
        }
        return stdinData
    } else {
        guard !path.isEmpty else {
            throw PLUContextError.argument("Empty path specified")
        }
        
        return try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    }
}

func readPropertyList(_ fileData: Data) throws -> (Any, PlutilEmissionFormat) {
    let plist: Any
    let format: PlutilEmissionFormat
    
    do {
        var existingFormat: PropertyListSerialization.PropertyListFormat = .xml
        
        plist = try PropertyListSerialization.propertyList(from: fileData, options: [], format: &existingFormat)
        
        switch existingFormat {
        case .binary: format = .binary
        case .openStep: format = .openStep
        case .xml: format = .xml
        @unknown default:
            fatalError("Unknown property list format \(existingFormat)")
        }
    } catch let plistError as NSError {
        // Try JSON
        do {
            plist = try JSONSerialization.jsonObject(with: fileData, options: [.mutableContainers, .mutableLeaves])
            
            format = .json
        } catch let jsonError as NSError {
            throw PLUContextError.invalidPropertyList(plistError: plistError, jsonError: jsonError)
        }
    }

    return (plist, format)
}

func writePropertyList(_ plist: Any, path: String, standardOutput: FileHandle, outputFormat: PlutilEmissionFormat, outputName: String?, extensionName: String?, originalKeyPath: String?, readable: Bool, terminatingNewline: Bool, outputObjCHeader: Bool) throws {
    
    // Verify that we have string keys in all dictionaries
    guard validatePropertyListKeyType(plist) else {
        throw PLUContextError.invalidPropertyListObject("Dictionaries are required to have string keys in property lists")
    }

    let newPath = fixPath(path, format: outputFormat, outputName: outputName, extensionName: extensionName)
    var outputData: Data?

    switch outputFormat {
    case .xml, .binary:
        guard PropertyListSerialization.propertyList(plist, isValidFor: outputFormat.propertyListFormat) else {
            throw PLUContextError.invalidPropertyListObject("Invalid object in plist for property list format")
        }
        
        outputData = try PropertyListSerialization.data(fromPropertyList: plist, format: outputFormat.propertyListFormat, options: 0)
        
    case .swift:
        guard propertyListIsValidForLiteralFormat(plist, format: .swift) else {
            throw PLUContextError.invalidPropertyListObject("Input contains an object that cannot be represented in Swift literal syntax")
        }
        
        outputData = try swiftLiteralDataWithPropertyList(plist, originalFileName: path)
    case .objc:
        guard propertyListIsValidForLiteralFormat(plist, format: .objc) else {
            throw PLUContextError.invalidPropertyListObject("Input contains an object that cannot be represented in Obj-C literal syntax")
        }
        
        outputData = try objcLiteralDataWithPropertyList(plist, originalFileName: path, newFileName: newPath)
        
    case .json:
        guard JSONSerialization.isValidJSONObject(plist) else {
            throw PLUContextError.invalidPropertyListObject("Invalid object in plist for JSON format")
        }
        
        outputData = try JSONSerialization.data(withJSONObject: plist, options: readable ? [.prettyPrinted, .sortedKeys] : [])
        
    case .raw:
        guard propertyListIsValidForRawFormat(plist) else {
            let actualType = PlutilExpectType(propertyList: plist)
            throw PLUContextError.invalidPropertyListObject("Value at \(originalKeyPath ?? "unknown key path") is a \(actualType) type and cannot be extracted in raw format")
        }
        
        let output = try rawStringWithPropertyList(plist)
        outputData = output.data(using: .utf8)
    case .type:
        outputData = PlutilExpectType(propertyList: plist).description.data(using: .utf8)!
    case .openStep:
        throw PLUContextError.invalidPropertyListObject("Conversion to OpenStep format is not supported")
    }

    guard let outputData else {
        throw PLUContextError.invalidPropertyListObject("Unknown data creation error")
    }

    if outputName == "-" || (outputName == nil && (outputFormat == .raw || outputFormat == .type)) {
        // Write to stdout
        try standardOutput.write(contentsOf: outputData)
        
        if terminatingNewline && (outputFormat == .raw || outputFormat == .type) {
            standardOutput.write("\n")
        }
    } else {
        try outputData.write(to: newPath.url)
        
        if outputFormat == .objc && outputObjCHeader {
            let headerData = try objcLiteralHeaderDataWithPropertyList(plist, originalFileName: path, newFileName: newPath)
            
            var headerDataPath = newPath
            headerDataPath.replaceExtension(with: "h")
            try headerData.write(to: headerDataPath.url)
        }
    }
}

// MARK: -

func fixPath(_ path: String, format: PlutilEmissionFormat, outputName: String?, extensionName: String?) -> String {
    if let outputName {
        // Just use it
        return outputName
    }
    
    var result = path
    if let extensionName {
        result.replaceExtension(with: extensionName)
    }

    // the rest of plutil expects formats to be convertable from each other...
    // if a user forgot to add a `-o` option we should not overwrite the original plist
    switch format {
    case .objc:
        result.replaceExtension(with: "m")
    case .swift:
        result.replaceExtension(with: "swift")
    default:
        break
    }
    
    return result
}

// MARK: - Type Output

func validatePropertyListKeyType(_ plist: Any) -> Bool {
    if plist is NSNumber { return true }
    else if plist is Date { return true }
    else if plist is Data { return true }
    else if plist is String { return true }
    else if let sub = plist as? [Any] {
        for subPlist in sub {
            if !validatePropertyListKeyType(subPlist) { return false }
        }
        return true
    } else if let sub = plist as? [String: Any] {
        for (_, v) in sub {
            if !validatePropertyListKeyType(v) { return false }
        }
        return true
    } else {
        // Unknown property list type?
        return false
    }
}

func propertyListIsValidForRawFormat(_ propertyList: Any) -> Bool {
    if propertyList is NSNumber {
        // Here, allow any number
        return true
    } else if propertyList is String {
        return true
    } else if propertyList is [Any] {
        return true
    } else if propertyList is [AnyHashable: Any] {
        return true
    } else if propertyList is Date {
        return true
    } else if propertyList is Data {
        return true
    } else {
        return false
    }
}

/// Output the property list in "raw" string format. Does not descend into collections like array or dictionary.
func rawStringWithPropertyList(_ propertyList: Any) throws -> String {
    if let num = propertyList as? NSNumber {
        return try num.propertyListFormatted(objCStyle: false)
    } else if let string = propertyList as? String {
        return string
    } else if let array = propertyList as? [Any] {
        // Just outputs the number of elements
        return "\(array.count)"
    } else if let dictionary = propertyList as? [String: Any] {
        // Just outputs keys
        let sortedKeys = dictionary.keys.sorted(by: sortDictionaryKeys)
        return sortedKeys.joined(separator: "\n")
    } else if let date = propertyList as? Date {
        return date.formatted(.iso8601)
    } else if let data = propertyList as? Data {
        return data.base64EncodedString()
    } else {
        throw PLUContextError.invalidPropertyListObject("Raw syntax does not support classes of type \(type(of: propertyList))")
    }
}

// MARK: - Standard Key Sorting

func sortDictionaryKeys(key1: String, key2: String) -> Bool {
    let locale = Locale(identifier: "")
    let order = key1.compare(key2, options: [.numeric, .caseInsensitive, .forcedOrdering], range: nil, locale: locale)
    return order == .orderedAscending
}

// MARK: -

// Adapted from FilePath, until Foundation can depend on System on all platforms
extension String {
    /// e.g., `.h` -> `.m`
    mutating func replaceExtension(with ext: String) {
        if let r = _extensionRange() {
            replaceSubrange(r, with: ext)
        }
    }
    
    var url: URL {
        URL(filePath: self)
    }

    // The index of the `.` denoting an extension
    internal func _extensionIndex() -> Index? {
        guard self != "." && self != ".." else {
            return nil
        }
        
        guard let idx = utf8.lastIndex(of: UInt8(ascii: ".")), idx != startIndex else {
            return nil
        }
        
        return idx
    }
    
    internal func _extensionRange() -> Range<Index>? {
        guard let idx = _extensionIndex() else { return nil }
        return index(after: idx) ..< endIndex
    }
    
    internal func _stemRange() -> Range<Index> {
        startIndex ..< (_extensionIndex() ?? endIndex)
    }

    var stem: String {
        guard let last = lastComponent else { return "" }
        return String(last[last._stemRange()])
    }
    
    var lastComponent: String? {
        // Delegate this to URL
        URL(fileURLWithPath: self).lastPathComponent
    }
}
