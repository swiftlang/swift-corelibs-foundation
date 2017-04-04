import Foundation
import XCTest

let storage = HTTPCookieStorage.shared
let simpleCookie = HTTPCookie(properties: [ 
            .name: "TestCookie",
            .value: "Test @#$%^$&*99",
            .path: "/",
            .domain: "example.com",
            ])!
let rawValue = getenv("XDG_CONFIG_HOME")        
let xdg_config_home = String(utf8String: rawValue!)
storage.setCookie(simpleCookie)
XCTAssertEqual(storage.cookies!.count, 1)
let fm = FileManager.default
let destPath = xdg_config_home! + "/.cookies.shared"
var isDir = false
let exists = fm.fileExists(atPath: destPath, isDirectory: &isDir) 
XCTAssertTrue(exists)
