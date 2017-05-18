// This source file is part of the Swift.org open source project
//
// Copyright (c) 2017 Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(Linux)
    import Foundation
#else
    import SwiftFoundation
#endif

class XDGCheck {

    static func run() -> Never {
        let storage = HTTPCookieStorage.shared
        let properties = [
            HTTPCookiePropertyKey.name: "TestCookie",
            HTTPCookiePropertyKey.value: "Test @#$%^$&*99",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.domain: "example.com",
            ]
        let simpleCookie = HTTPCookie(properties: properties)
        guard simpleCookie != nil else {
            exit(HelperCheckStatus.cookieStorageNil.rawValue)
        }
        let rawValue = getenv("XDG_CONFIG_HOME")
        guard rawValue != nil else {
            exit(HelperCheckStatus.fail.rawValue)
        }
        let xdg_config_home = String(utf8String: rawValue!)
        storage.setCookie(simpleCookie!)
        let fm = FileManager.default
        let destPath = xdg_config_home! + "/.cookies.shared"
        var isDir = false
        let exists = fm.fileExists(atPath: destPath, isDirectory: &isDir) 
        if (!exists) {
            exit(HelperCheckStatus.cookieStorePathWrong.rawValue)
        }
        exit(HelperCheckStatus.ok.rawValue)
    }
}
