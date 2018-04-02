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

class TestProcess : XCTestCase {
    static var allTests: [(String, (TestProcess) -> () throws -> Void)] {
#if os(Android)
	return []
#else
        return [
                   ("test_exit0" , test_exit0),
                   ("test_exit1" , test_exit1),
                   ("test_exit100" , test_exit100),
                   ("test_sleep2", test_sleep2),
                   ("test_sleep2_exit1", test_sleep2_exit1),
                   ("test_terminationReason_uncaughtSignal", test_terminationReason_uncaughtSignal),
                   ("test_pipe_stdin", test_pipe_stdin),
                   ("test_pipe_stdout", test_pipe_stdout),
                   ("test_pipe_stderr", test_pipe_stderr),
                   ("test_current_working_directory", test_current_working_directory),
                   ("test_pipe_stdout_and_stderr_same_pipe", test_pipe_stdout_and_stderr_same_pipe),
                   ("test_file_stdout", test_file_stdout),
                   ("test_passthrough_environment", test_passthrough_environment),
                   ("test_no_environment", test_no_environment),
                   ("test_custom_environment", test_custom_environment),
        ]
#endif
    }
    
#if !os(Android)
    func test_exit0() {
        
        let process = Process()
        
        let executablePath = "/bin/bash"
        if #available(OSX 10.13, *) {
            process.executableURL = URL(fileURLWithPath: executablePath)
        } else {
            // Fallback on earlier versions
            process.launchPath = executablePath
        }
        XCTAssertEqual(executablePath, process.launchPath)

        process.arguments = ["-c", "exit 0"]
        process.launch()
        process.waitUntilExit()
        
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_exit1() {
        
        let process = Process()
        
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "exit 1"]

        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_exit100() {
        
        let process = Process()
        
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "exit 100"]
        
        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 100)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_sleep2() {
        
        let process = Process()
        
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "sleep 2"]
        
        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_sleep2_exit1() {
        
        let process = Process()
        
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "sleep 2; exit 1"]
        
        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)
        XCTAssertEqual(process.terminationReason, .exit)
    }

    func test_terminationReason_uncaughtSignal() {
        let process = Process()

        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "kill -TERM $$"]

        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 15)
        XCTAssertEqual(process.terminationReason, .uncaughtSignal)
    }

    func test_pipe_stdin() {
        let process = Process()

        process.launchPath = "/bin/cat"

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        let inputPipe = Pipe()
        process.standardInput = inputPipe

        process.launch()

        inputPipe.fileHandleForWriting.write("Hello, 🐶.\n".data(using: .utf8)!)

        // Close the input pipe to send EOF to cat.
        inputPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let data = outputPipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertEqual(string, "Hello, 🐶.\n")
    }

    func test_pipe_stdout() {
        let process = Process()

        process.launchPath = "/usr/bin/which"
        process.arguments = ["which"]

        let pipe = Pipe()
        process.standardOutput = pipe

        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertTrue(string.hasSuffix("/which\n"))
    }

    func test_pipe_stderr() {
        let process = Process()

        process.launchPath = "/bin/cat"
        process.arguments = ["invalid_file_name"]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)

        let data = errorPipe.fileHandleForReading.availableData
        guard let _ = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        // testing the return value of an external process does not port well, and may change.
        // XCTAssertEqual(string, "/bin/cat: invalid_file_name: No such file or directory\n")
    }

    func test_pipe_stdout_and_stderr_same_pipe() {
        let process = Process()

        process.launchPath = "/bin/cat"
        process.arguments = ["invalid_file_name"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Clear the environment to stop the malloc debug flags used in Xcode debug being
        // set in the subprocess.
        process.environment = [:]
        process.launch()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }

        // Remove the leading '/bin/' since on macOS '/bin/cat' just outputs 'cat:'
        let searchStr = "/bin/"
        let errMsg = string.replacingOccurrences(of: searchStr, with: "", options: [.literal, .anchored],
                                              range: searchStr.startIndex..<searchStr.endIndex)
        XCTAssertEqual(errMsg, "cat: invalid_file_name: No such file or directory\n")
    }

    func test_file_stdout() {
        let process = Process()

        process.launchPath = "/usr/bin/which"
        process.arguments = ["which"]

        mkstemp(template: "TestProcess.XXXXXX") { handle in
            process.standardOutput = handle

            process.launch()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0)

            handle.seek(toFileOffset: 0)
            let data = handle.readDataToEndOfFile()
            guard let string = String(data: data, encoding: .ascii) else {
                XCTFail("Could not read stdout")
                return
            }
            XCTAssertTrue(string.hasSuffix("/which\n"))
        }
    }
    
    func test_passthrough_environment() {
        do {
            let (output, _) = try runTask(["/usr/bin/env"], environment: nil)
            let env = try parseEnv(output)
            XCTAssertGreaterThan(env.count, 0)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_no_environment() {
        do {
            let (output, _) = try runTask(["/usr/bin/env"], environment: [:])
            let env = try parseEnv(output)
            XCTAssertEqual(env.count, 0)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_custom_environment() {
        do {
            let input = ["HELLO": "WORLD", "HOME": "CUPERTINO"]
            let (output, _) = try runTask(["/usr/bin/env"], environment: input)
            let env = try parseEnv(output)
            XCTAssertEqual(env, input)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_current_working_directory() {
        do {
            let previousWorkingDirectory = FileManager.default.currentDirectoryPath

            // Darwin Foundation requires the full path to the executable (.launchPath)
            let (output, _) = try runTask(["/bin/bash", "-c", "pwd"], currentDirectoryPath: "/bin")
            XCTAssertEqual(output.trimmingCharacters(in: .newlines), "/bin")
            XCTAssertEqual(previousWorkingDirectory, FileManager.default.currentDirectoryPath)
        } catch let error {
            XCTFail("Test failed: \(error)")
        }
    }
#endif
}

private func mkstemp(template: String, body: (FileHandle) throws -> Void) rethrows {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TestProcess.XXXXXX")
    
    try url.withUnsafeFileSystemRepresentation {
        switch mkstemp(UnsafeMutablePointer(mutating: $0!)) {
        case -1: XCTFail("Could not create temporary file")
        case let fd:
            defer { url.withUnsafeFileSystemRepresentation { _ = unlink($0!) } }
            try body(FileHandle(fileDescriptor: fd, closeOnDealloc: true))
        }
    }
    
}

private enum Error: Swift.Error {
    case TerminationStatus(Int32)
    case UnicodeDecodingError(Data)
    case InvalidEnvironmentVariable(String)
}

#if !os(Android)
private func runTask(_ arguments: [String], environment: [String: String]? = nil, currentDirectoryPath: String? = nil) throws -> (String, String) {
    let process = Process()

    var arguments = arguments
    process.launchPath = arguments.removeFirst()
    process.arguments = arguments
    // Darwin Foundation doesnt allow .environment to be set to nil although the documentation
    // says it is an optional. https://developer.apple.com/documentation/foundation/process/1409412-environment
    if let e = environment {
        process.environment = e
    }

    if let directoryPath = currentDirectoryPath {
        process.currentDirectoryPath = directoryPath
    }

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.launch()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw Error.TerminationStatus(process.terminationStatus)
    }

    let stdoutData = stdoutPipe.fileHandleForReading.availableData
    guard let stdout = String(data: stdoutData, encoding: .utf8) else {
        throw Error.UnicodeDecodingError(stdoutData)
    }

    let stderrData = stderrPipe.fileHandleForReading.availableData
    guard let stderr = String(data: stderrData, encoding: .utf8) else {
        throw Error.UnicodeDecodingError(stderrData)
    }

    return (stdout, stderr)
}

private func parseEnv(_ env: String) throws -> [String: String] {
    var result = [String: String]()
    for line in env.components(separatedBy: "\n") where line != "" {
        guard let range = line.range(of: "=") else {
            throw Error.InvalidEnvironmentVariable(line)
        }
        result[String(line[..<range.lowerBound])] = String(line[range.upperBound...])
    }
    return result
}
#endif

