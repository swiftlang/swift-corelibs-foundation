// This source file is part of the Swift.org open source project
//
// Copyright (c) 2017 - 2018 Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux) || os(Android)
import Foundation
#else
import SwiftFoundation
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

// Used by TestProcess: test_interrupt(), test_suspend_resume()
func signalTest() {

    var signalSet = sigset_t()
    sigemptyset(&signalSet)
    sigaddset(&signalSet, SIGTERM)
    sigaddset(&signalSet, SIGCONT)
    sigaddset(&signalSet, SIGINT)
    sigaddset(&signalSet, SIGALRM)
    guard sigprocmask(SIG_BLOCK, &signalSet, nil) == 0 else {
        fatalError("Cant block signals")
    }
    // Timeout
    alarm(3)

    // On Linux, print() doesnt currently flush the output over the pipe so use
    // write() for now. On macOS, print() works fine.
    write(1, "Ready\n", 6)

    while true {
        var receivedSignal: Int32 = 0
        let ret = sigwait(&signalSet, &receivedSignal)
        guard ret == 0 else {
            fatalError("sigwait() failed")
        }
        switch receivedSignal {
        case SIGINT:
            write(1, "Signal: SIGINT\n", 15)

        case SIGCONT:
            write(1, "Signal: SIGCONT\n", 16)

        case SIGTERM:
            print("Terminated")
            exit(99)

        case SIGALRM:
            print("Timedout")
            exit(127)

        default:
            let msg = "Unexpected signal: \(receivedSignal)"
            fatalError(msg)
        }
    }
}

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

case "--signal-test":
    signalTest()

default:
    fatalError("These arguments are not recognized. Only run this from a unit test.")
}
