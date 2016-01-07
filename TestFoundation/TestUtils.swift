// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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

func ensureFiles(fileNames: [String]) -> Bool {
    var result = true
    let fm = NSFileManager.defaultManager()
    for name in fileNames {
        guard !fm.fileExistsAtPath(name) else {
            continue
        }
        
        if name.hasSuffix("/") {
            do {
                try fm.createDirectoryAtPath(name, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                print(err)
                return false
            }
        } else {
        
            var isDir: ObjCBool = false
            let dir = name.bridge().stringByDeletingLastPathComponent
            if !fm.fileExistsAtPath(dir, isDirectory: &isDir) {
                do {
                    try fm.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
                } catch let err {
                    print(err)
                    return false
                }
            } else if !isDir {
                return false
            }
            
            result = result && fm.createFileAtPath(name, contents: nil, attributes: nil)
        }
    }
    return result
}