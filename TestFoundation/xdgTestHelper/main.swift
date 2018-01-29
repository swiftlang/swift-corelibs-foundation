// This source file is part of the Swift.org open source project
//
// Copyright (c) 2017 Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC
import Foundation
#elseif os(Linux) || os(Android)
@testable import Foundation
#else
@testable import SwiftFoundation
#endif

enum HelperCheckStatus : Int32 {
    case ok                 = 0
    case fail               = 1
    case cookieStorageNil   = 20
    case cookieStorePathWrong
}


class XDGCheck {
    static func run() -> Never {
        let storage = HTTPCookieStorage.shared
        let properties: [HTTPCookiePropertyKey: String] = [
            .name: "TestCookie",
            .value: "Test @#$%^$&*99",
            .path: "/",
            .domain: "example.com",
            ]

        guard let simpleCookie = HTTPCookie(properties: properties) else {
            exit(HelperCheckStatus.cookieStorageNil.rawValue)
        }
        guard let rawValue = getenv("XDG_DATA_HOME"), let xdg_data_home = String(utf8String: rawValue) else {
            exit(HelperCheckStatus.fail.rawValue)
        }

        storage.setCookie(simpleCookie)
        let fm = FileManager.default

        guard let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            exit(HelperCheckStatus.fail.rawValue)
        }
        let destPath = xdg_data_home + "/" + bundleName + "/.cookies.shared"
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: destPath, isDirectory: &isDir)
        if (!exists) {
            print("Expected cookie path: ", destPath)
            exit(HelperCheckStatus.cookieStorePathWrong.rawValue)
        }
        exit(HelperCheckStatus.ok.rawValue)
    }
}

// -----

#if !DEPLOYMENT_RUNTIME_OBJC
struct NSURLForPrintTest {
    enum Method: String {
        case NSSearchPath
        case FileManagerDotURLFor
        case FileManagerDotURLsFor
    }
    
    enum Identifier: String {
        case desktop
        case download
        case publicShare
        case documents
        case music
        case pictures
        case videos
    }
    
    let method: Method
    let identifier: Identifier
    
    func run() {
        let directory: FileManager.SearchPathDirectory
        
        switch identifier {
        case .desktop:
            directory = .desktopDirectory
        case .download:
            directory = .downloadsDirectory
        case .publicShare:
            directory = .sharedPublicDirectory
        case .documents:
            directory = .documentDirectory
        case .music:
            directory = .musicDirectory
        case .pictures:
            directory = .picturesDirectory
        case .videos:
            directory = .moviesDirectory
        }
        
        switch method {
        case .NSSearchPath:
            print(NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first!)
        case .FileManagerDotURLFor:
            print(try! FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false).path)
        case .FileManagerDotURLsFor:
            print(FileManager.default.urls(for: directory, in: .userDomainMask).first!.path)
        }
    }
}
#endif

// -----

var arguments = ProcessInfo.processInfo.arguments.dropFirst().makeIterator()

guard let arg = arguments.next() else {
    fatalError("The unit test must specify the correct number of flags and arguments.")
}

switch arg {
case "--xdgcheck":
    XDGCheck.run()
    
case "--getcwd":
    print(FileManager.default.currentDirectoryPath)

case "--echo-PWD":
    print(ProcessInfo.processInfo.environment["PWD"] ?? "")
    
#if !DEPLOYMENT_RUNTIME_OBJC
case "--nspathfor":
    guard let methodString = arguments.next(),
        let method = NSURLForPrintTest.Method(rawValue: methodString),
        let identifierString = arguments.next(),
        let identifier = NSURLForPrintTest.Identifier(rawValue: identifierString) else {
        fatalError("Usage: --nspathfor <METHOD> <DIRECTORY NAME>")
    }
    
    let test = NSURLForPrintTest(method: method, identifier: identifier)
    test.run()
#endif
    
default:
    fatalError("These arguments are not recognized. Only run this from a unit test.")
}

