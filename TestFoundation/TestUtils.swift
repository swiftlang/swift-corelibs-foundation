// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

func ensureFiles(_ fileNames: [String]) -> Bool {
    var result = true
    let fm = FileManager.default
    for name in fileNames {
        guard !fm.fileExists(atPath: name) else {
            continue
        }
        
        if name.hasSuffix("/") {
            do {
                try fm.createDirectory(atPath: name, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                print(err)
                return false
            }
        } else {
        
            var isDir: ObjCBool = false
            let dir = NSString(string: name).deletingLastPathComponent
            if !fm.fileExists(atPath: dir, isDirectory: &isDir) {
                do {
                    try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                } catch let err {
                    print(err)
                    return false
                }
            } else if !isDir.boolValue {
                return false
            }
            
            result = result && fm.createFile(atPath: name, contents: nil, attributes: nil)
        }
    }
    return result
}


enum TestError: Error {
    case unexpectedNil
}

extension Optional {
    func unwrapped(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) throws -> Wrapped {
        if let x = self {
            return x
        } else {
            XCTFail("Tried to invoke .unwrapped() on nil in \(file):\(line):\(fn)")
            throw TestError.unexpectedNil
        }
    }
}
