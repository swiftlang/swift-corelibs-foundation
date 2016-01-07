// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
#if os(OSX) || os(iOS)
import Darwin
import SwiftFoundation
#elseif os(Linux)
import Foundation
import Glibc
#endif

func help() -> Int32 {
    print("plutil: [command_option] [other_options] file...\n" +
    "The file '-' means stdin\n" +
    "Command options are (-lint is the default):\n" +
    " -help                         show this message and exit\n" +
    " -lint                         check the property list files for syntax errors\n" +
    " -convert fmt                  rewrite property list files in format\n" +
    "                               fmt is one of: xml1 binary1 json\n" +
    " -p                            print property list in a human-readable fashion\n" +
    "                               (not for machine parsing! this 'format' is not stable)\n" +
    "There are some additional optional arguments that apply to -convert\n" +
    " -s                            be silent on success\n" +
    " -o path                       specify alternate file path name for result;\n" +
    "                               the -o option is used with -convert, and is only\n" +
    "                               useful with one file argument (last file overwrites);\n" +
    "                               the path '-' means stdout\n" +
    " -e extension                  specify alternate extension for converted files\n" +
    " -r                            if writing JSON, output in human-readable form\n" +
    " --                            specifies that all further arguments are file names\n")
    return EXIT_SUCCESS
}

enum ExecutionMode {
    case Help
    case Lint
    case Convert
    case Print
}

enum ConversionFormat {
    case XML1
    case Binary1
    case JSON
}

struct Options {
    var mode: ExecutionMode = .Lint
    var silent: Bool = false
    var output: String?
    var fileExtension: String?
    var humanReadable: Bool?
    var conversionFormat: ConversionFormat?
    var inputs = [String]()
}

enum OptionParseError : ErrorType {
    case UnrecognizedArgument(String)
    case MissingArgument(String)
    case InvalidFormat(String)
}

func parseArguments(args: [String]) throws -> Options {
    var opts = Options()
    var iterator = args.generate()
    while let arg = iterator.next() {
        switch arg {
            case "--":
                while let path = iterator.next() {
                    opts.inputs.append(path)
                }
                break
            case "-s":
                opts.silent = true
                break
            case "-o":
                if let path = iterator.next() {
                    opts.output = path
                } else {
                    throw OptionParseError.MissingArgument("-o requires a path argument")
                }
                break
            case "-convert":
                opts.mode = ExecutionMode.Convert
                if let format = iterator.next() {
                    switch format {
                        case "xml1":
                            opts.conversionFormat = ConversionFormat.XML1
                            break
                        case "binary1":
                            opts.conversionFormat = ConversionFormat.Binary1
                            break
                        case "json":
                            opts.conversionFormat = ConversionFormat.JSON
                            break
                        default:
                            throw OptionParseError.InvalidFormat(format)
                    }
                } else {
                    throw OptionParseError.MissingArgument("-convert requires a format argument of xml1 binary1 json")
                }
                break
            case "-e":
                if let ext = iterator.next() {
                    opts.fileExtension = ext
                } else {
                    throw OptionParseError.MissingArgument("-e requires an extension argument")
                }
            case "-help":
                opts.mode = ExecutionMode.Help
                break
            case "-lint":
                opts.mode = ExecutionMode.Lint
                break
            case "-p":
                opts.mode = ExecutionMode.Print
                break
            default:
                if arg.hasPrefix("-") && arg.utf8.count > 1 {
                    throw OptionParseError.UnrecognizedArgument(arg)
                }
                break
        }
    }
    
    return opts
}


func lint(options: Options) -> Int32 {
    if options.output != nil {
        print("-o is not used with -lint")
        help()
        return EXIT_FAILURE
    }
    
    if options.fileExtension != nil {
        print("-e is not used with -lint")
        help()
        return EXIT_FAILURE
    }
    
    if options.inputs.count < 1 {
        print("No files specified.")
        help()
        return EXIT_FAILURE
    }
    
    let silent = options.silent
    
    var doError = false
    for file in options.inputs {
        let data : NSData?
        if file == "-" {
            // stdin
            data = NSFileHandle.fileHandleWithStandardInput().readDataToEndOfFile()
        } else {
            data = NSData(contentsOfFile: file)
        }
        
        if let d = data {
            do {
                let _ = try NSPropertyListSerialization.propertyListWithData(d, options: [], format: nil)
                if !silent {
                    print("\(file): OK")
                }
            } catch {
                print("\(file): \(error)")
                
            }
            
        } else {
            print("\(file) does not exists or is not readable or is not a regular file")
            doError = true
            continue
        }
    }
    
    if doError {
        return EXIT_FAILURE
    } else {
        return EXIT_SUCCESS
    }
}

func convert(options: Options) -> Int32 {
    print("Unimplemented")
    return EXIT_FAILURE
}

enum DisplayType {
    case Primary
    case Key
    case Value
}

extension Dictionary {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary || type == .Key {
            print("\(indentation)[\n", terminator: "")
        } else {
            print("[\n", terminator: "")
        }
        
        forEach() {
            if let key = $0.0 as? String {
                key.display(indent + 1, type: .Key)
            } else {
                fatalError("plists should have strings as keys but got a \($0.0.dynamicType)")
            }
            print(" => ", terminator: "")
            displayPlist($0.1, indent: indent + 1, type: .Value)
        }
        
        print("\(indentation)]\n", terminator: "")
    }
}

extension Array {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary || type == .Key {
            print("\(indentation)[\n", terminator: "")
        } else {
            print("[\n", terminator: "")
        }
        
        for idx in 0..<count {
            print("\(indentation)  \(idx) => ", terminator: "")
            displayPlist(self[idx], indent: indent + 1, type: .Value)
        }
        
        print("\(indentation)]\n", terminator: "")
    }
}

extension String {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary {
            print("\(indentation)\"\(self)\"\n", terminator: "")
        }
        else if type == .Key {
            print("\(indentation)\"\(self)\"", terminator: "")
        } else {
            print("\"\(self)\"\n", terminator: "")
        }
    }
}

extension Bool {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary {
            print("\(indentation)\"\(self ? "1" : "0")\"\n", terminator: "")
        }
        else if type == .Key {
            print("\(indentation)\"\(self ? "1" : "0")\"", terminator: "")
        } else {
            print("\"\(self ? "1" : "0")\"\n", terminator: "")
        }
    }
}

extension NSNumber {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary {
            print("\(indentation)\"\(self)\"\n", terminator: "")
        }
        else if type == .Key {
            print("\(indentation)\"\(self)\"", terminator: "")
        } else {
            print("\"\(self)\"\n", terminator: "")
        }
    }
}

extension NSData {
    func display(indent: Int = 0, type: DisplayType = .Primary) {
        let indentation = String(count: indent * 2, repeatedValue: Character(" "))
        if type == .Primary {
            print("\(indentation)\"\(self)\"\n", terminator: "")
        }
        else if type == .Key {
            print("\(indentation)\"\(self)\"", terminator: "")
        } else {
            print("\"\(self)\"\n", terminator: "")
        }
    }
}

func displayPlist(plist: Any, indent: Int = 0, type: DisplayType = .Primary) {
    if let val = plist as? Dictionary<String, Any> {
        val.display(indent, type: type)
    } else if let val = plist as? Array<Any> {
        val.display(indent, type: type)
    } else if let val = plist as? String {
        val.display(indent, type: type)
    } else if let val = plist as? Bool {
        val.display(indent, type: type)
    } else if let val = plist as? NSNumber {
        val.display(indent, type: type)
    } else if let val = plist as? NSData {
        val.display(indent, type: type)
    } else {
        fatalError("unhandled type \(plist.dynamicType)")
    }
}

func display(options: Options) -> Int32 {
    if options.inputs.count < 1 {
        print("No files specified.")
        help()
        return EXIT_FAILURE
    }
    
    var doError = false
    for file in options.inputs {
        let data : NSData?
        if file == "-" {
            // stdin
            data = NSFileHandle.fileHandleWithStandardInput().readDataToEndOfFile()
        } else {
            data = NSData(contentsOfFile: file)
        }
        
        if let d = data {
            do {
                let plist = try NSPropertyListSerialization.propertyListWithData(d, options: [], format: nil)
                displayPlist(plist)
            } catch {
                print("\(file): \(error)")
            }
            
        } else {
            print("\(file) does not exists or is not readable or is not a regular file")
            doError = true
            continue
        }
    }
    
    if doError {
        return EXIT_FAILURE
    } else {
        return EXIT_SUCCESS
    }
}

func main() -> Int32 {
    var args = NSProcessInfo.processInfo().arguments
    
    if args.count < 2 {
        print("No files specified.")
        return EXIT_FAILURE
    }
    
    // Throw away process path
    args.removeFirst()
    do {
        let opts = try parseArguments(args)
        switch opts.mode {
            case .Lint:
                return lint(opts)
            case .Convert:
                return convert(opts)
            case .Print:
                return display(opts)
            case .Help:
                return help()
        }
    } catch let err {
        switch err as! OptionParseError {
            case .UnrecognizedArgument(let arg):
                print("unrecognized option: \(arg)")
                help()
                break
            case .InvalidFormat(let format):
                print("unrecognized format \(format)\nformat should be one of: xml1 binary1 json")
                break
            case .MissingArgument(let errorStr):
                print(errorStr)
                break
        }
        return EXIT_FAILURE
    }
}

exit(main())

