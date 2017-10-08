// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

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
