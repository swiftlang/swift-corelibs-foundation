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

func help() {
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
}

func lint(args : [String]) {
    var silent = false
    // Be nice and filter the rest of the arguments for other optional arguments
    let filteredArgs = args.filter { arg in
        switch arg {
            case "--":
                return false
            
            case "-s":
                silent = true
                return false
            
            case "-o":
                print("-o is not used with -lint")
                help()
                exit(EXIT_FAILURE)
            
            case "-e":
                print("-e is not used with -lint")
                help()
                exit(EXIT_FAILURE)

            default:
                if arg.hasPrefix("-") && arg.utf8.count > 1 {
                    print("unrecognized option \(arg)")
                    help()
                    exit(EXIT_FAILURE)
                }
                return true
        }
        return true
    }
    
    if filteredArgs.count < 1 {
        print("No files specified.")
        help()
        exit(EXIT_FAILURE)
    }
    
    var doError = false
    for file in filteredArgs {
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
        exit(EXIT_FAILURE)
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
    
    let command = args[0]
    switch command {
        case "-help":
            help()
            return EXIT_SUCCESS

        case "-lint":
            // Throw away command arg
            args.removeFirst()
            lint(args)
        
        default:
            // Default is to lint
            lint(args)
    }
    
    return EXIT_SUCCESS
    
}

exit(main())

