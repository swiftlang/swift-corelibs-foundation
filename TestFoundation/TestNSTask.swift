// This source file is part of the Swift.org open source project
//
// Copyright (c) 2015 - 2016 Apple Inc. and the Swift project authors
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
import CoreFoundation

class TestNSTask : XCTestCase {
    static var allTests: [(String, (TestNSTask) -> () throws -> Void)] {
        return [
                   ("test_exit0" , test_exit0),
                   ("test_exit1" , test_exit1),
                   ("test_exit100" , test_exit100),
                   ("test_sleep2", test_sleep2),
                   ("test_sleep2_exit1", test_sleep2_exit1),
                   ("test_pipe_stdin", test_pipe_stdin),
                   ("test_pipe_stdout", test_pipe_stdout),
                   ("test_pipe_stderr", test_pipe_stderr),
                   // disabled for now
                   // ("test_pipe_stdout_and_stderr_same_pipe", test_pipe_stdout_and_stderr_same_pipe),
                   ("test_file_stdout", test_file_stdout),
                   // disabled for now
                   // ("test_passthrough_environment", test_passthrough_environment),
                   // ("test_no_environment", test_no_environment),
                   // ("test_custom_environment", test_custom_environment),
        ]
    }
    
    func test_exit0() {
        
        let task = Task()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 0"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)
    }
    
    func test_exit1() {
        
        let task = Task()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 1"]

        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)
    }
    
    func test_exit100() {
        
        let task = Task()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 100"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 100)
    }
    
    func test_sleep2() {
        
        let task = Task()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sleep 2"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)
    }
    
    func test_sleep2_exit1() {
        
        let task = Task()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sleep 2; exit 1"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)
    }


    func test_pipe_stdin() {
        let task = Task()

        task.launchPath = "/bin/cat"

        let outputPipe = Pipe()
        task.standardOutput = outputPipe

        let inputPipe = Pipe()
        task.standardInput = inputPipe

        task.launch()

        inputPipe.fileHandleForWriting.write("Hello, 🐶.\n".data(using: .utf8)!)

        // Close the input pipe to send EOF to cat.
        inputPipe.fileHandleForWriting.closeFile()

        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)

        let data = outputPipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertEqual(string, "Hello, 🐶.\n")
    }

    func test_pipe_stdout() {
        let task = Task()

        task.launchPath = "/usr/bin/which"
        task.arguments = ["which"]

        let pipe = Pipe()
        task.standardOutput = pipe

        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertEqual(string, "/usr/bin/which\n")
    }

    func test_pipe_stderr() {
        let task = Task()

        task.launchPath = "/bin/cat"
        task.arguments = ["invalid_file_name"]

        let errorPipe = Pipe()
        task.standardError = errorPipe

        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)

        let data = errorPipe.fileHandleForReading.availableData
        guard let _ = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        // testing the return value of an external process is does not port well, and may change.
        // XCTAssertEqual(string, "/bin/cat: invalid_file_name: No such file or directory\n")
    }

    func test_pipe_stdout_and_stderr_same_pipe() {
        let task = Task()

        task.launchPath = "/bin/cat"
        task.arguments = ["invalid_file_name"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertEqual(string, "/bin/cat: invalid_file_name: No such file or directory\n")
    }

    func test_file_stdout() {
        let task = Task()

        task.launchPath = "/usr/bin/which"
        task.arguments = ["which"]

        mkstemp(template: "TestNSTask.XXXXXX") { handle in
            task.standardOutput = handle

            task.launch()
            task.waitUntilExit()
            XCTAssertEqual(task.terminationStatus, 0)

            handle.seek(toFileOffset: 0)
            let data = handle.readDataToEndOfFile()
            guard let string = String(data: data, encoding: .ascii) else {
                XCTFail("Could not read stdout")
                return
            }
            XCTAssertEqual(string, "/usr/bin/which\n")
        }
    }
    
    func test_passthrough_environment() {
        do {
            let output = try runTask(["/usr/bin/env"], environment: nil)
            let env = try parseEnv(output)
            XCTAssertGreaterThan(env.count, 0)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_no_environment() {
        do {
            let output = try runTask(["/usr/bin/env"], environment: [:])
            let env = try parseEnv(output)
            XCTAssertEqual(env.count, 0)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_custom_environment() {
        do {
            let input = ["HELLO": "WORLD", "HOME": "CUPERTINO"]
            let output = try runTask(["/usr/bin/env"], environment: input)
            let env = try parseEnv(output)
            XCTAssertEqual(env, input)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }
}

private func mkstemp(template: String, body: @noescape (FileHandle) throws -> Void) rethrows {
    let url = try! URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TestNSTask.XXXXXX")
    var buffer = [Int8](repeating: 0, count: Int(PATH_MAX))
    try url.withUnsafeFileSystemRepresentation {
        switch mkstemp(UnsafeMutablePointer(mutating: $0)) {
        case -1: XCTFail("Could not create temporary file")
        case let fd:
            defer { unlink(&buffer) }
            try body(FileHandle(fileDescriptor: fd, closeOnDealloc: true))
        }
    }
    
}

private enum Error: Swift.Error {
    case TerminationStatus(Int32)
    case UnicodeDecodingError(Data)
    case InvalidEnvironmentVariable(String)
}

private func runTask(_ arguments: [String], environment: [String: String]? = nil) throws -> String {
    let task = Task()

    var arguments = arguments
    task.launchPath = arguments.removeFirst()
    task.arguments = arguments
    task.environment = environment

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()

    guard task.terminationStatus == 0 else {
        throw Error.TerminationStatus(task.terminationStatus)
    }

    let data = pipe.fileHandleForReading.availableData
    guard let output = String(data: data, encoding: .utf8) else {
        throw Error.UnicodeDecodingError(data)
    }

    return output
}

private func parseEnv(_ env: String) throws -> [String: String] {
    var result = [String: String]()
    for line in env.components(separatedBy: "\n") where line != "" {
        guard let range = line.range(of: "=") else {
            throw Error.InvalidEnvironmentVariable(line)
        }
        result[line.substring(to: range.lowerBound)] = line.substring(from: range.upperBound)
    }
    return result
}


