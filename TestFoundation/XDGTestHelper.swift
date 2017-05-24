import Foundation

let storage = HTTPCookieStorage.shared
let simpleCookie = HTTPCookie(properties: [ 
            .name: "TestCookie",
            .value: "Test @#$%^$&*99",
            .path: "/",
            .domain: "example.com",
            ])!
let rawValue = getenv("XDG_DATA_HOME")
let xdg_data_home = String(utf8String: rawValue!)
storage.setCookie(simpleCookie)
let fm = FileManager.default
let destPath = xdg_data_home! + "/xdgTestHelper/.cookies.shared"
var isDir = false
let exists = fm.fileExists(atPath: destPath, isDirectory: &isDir) 
if (!exists) {
   exit(-1)
} 
