// This source file is part of the Swift.org open source project
//
// Copyright (c) 2015 - 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

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
                   ("test_run", test_run),
                   ("test_preStartEndState", test_preStartEndState),
                   ("test_interrupt", test_interrupt),
                   ("test_terminate", test_terminate),
                   ("test_suspend_resume", test_suspend_resume),
                   ("test_redirect_stdin_using_null", test_redirect_stdin_using_null),
                   ("test_redirect_stdout_using_null", test_redirect_stdout_using_null),
                   ("test_redirect_stdin_stdout_using_null", test_redirect_stdin_stdout_using_null),
                   ("test_redirect_stderr_using_null", test_redirect_stderr_using_null),
                   ("test_redirect_all_using_null", test_redirect_all_using_null),
                   ("test_redirect_all_using_nil", test_redirect_all_using_nil),
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

        let url: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: false)
        _ = FileManager.default.createFile(atPath: url.path, contents: Data())
        defer { _ = try? FileManager.default.removeItem(at: url) }

        let handle: FileHandle = FileHandle(forUpdatingAtPath: url.path)!

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
    
    func test_passthrough_environment() {
        do {
            let (output, _) = try runTask(["/usr/bin/env"], environment: nil)
            let env = try parseEnv(output)
            XCTAssertGreaterThan(env.count, 0)
        } catch {
            // FIXME: SR-9930 parseEnv fails if an environment variable contains
            // a newline.
            // XCTFail("Test failed: \(error)")
        }
    }

    func test_no_environment() {
        do {
            let (output, _) = try runTask(["/usr/bin/env"], environment: [:])
            let env = try parseEnv(output)
            XCTAssertEqual(env.count, 0)
        } catch {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_custom_environment() {
        do {
            let input = ["HELLO": "WORLD", "HOME": "CUPERTINO"]
            let (output, _) = try runTask(["/usr/bin/env"], environment: input)
            let env = try parseEnv(output)
            XCTAssertEqual(env, input)
        } catch {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_current_working_directory() {
        let tmpDir = "/tmp" //.standardizingPath

        let fm = FileManager.default
        let previousWorkingDirectory = fm.currentDirectoryPath

        // Test that getcwd() returns the currentDirectoryPath
        do {
            let (pwd, _) = try runTask([xdgTestHelperURL().path, "--getcwd"], currentDirectoryPath: tmpDir)
            // Check the sub-process used the correct directory
            XCTAssertEqual(pwd.trimmingCharacters(in: .newlines), tmpDir)
        } catch {
            XCTFail("Test failed: \(error)")
        }

        // Test that $PWD by default is set to currentDirectoryPath
        do {
            let (pwd, _) = try runTask([xdgTestHelperURL().path, "--echo-PWD"], currentDirectoryPath: tmpDir)
            // Check the sub-process used the correct directory
            XCTAssertEqual(pwd.trimmingCharacters(in: .newlines), tmpDir)
        } catch {
            XCTFail("Test failed: \(error)")
        }

        // Test that $PWD can be over-ridden
        do {
            var env = ProcessInfo.processInfo.environment
            env["PWD"] = "/bin"
            let (pwd, _) = try runTask([xdgTestHelperURL().path, "--echo-PWD"], environment: env, currentDirectoryPath: tmpDir)
            // Check the sub-process used the correct directory
            XCTAssertEqual(pwd.trimmingCharacters(in: .newlines), "/bin")
        } catch {
            XCTFail("Test failed: \(error)")
        }

        // Test that $PWD can be set to empty
        do {
            var env = ProcessInfo.processInfo.environment
            env["PWD"] = ""
            let (pwd, _) = try runTask([xdgTestHelperURL().path, "--echo-PWD"], environment: env, currentDirectoryPath: tmpDir)
            // Check the sub-process used the correct directory
            XCTAssertEqual(pwd.trimmingCharacters(in: .newlines), "")
        } catch {
            XCTFail("Test failed: \(error)")
        }

        XCTAssertEqual(previousWorkingDirectory, fm.currentDirectoryPath)
    }

    func test_run() {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath

        do {
            let process = try Process.run(URL(fileURLWithPath: "/bin/sh", isDirectory: false), arguments: ["-c", "exit 123"], terminationHandler: nil)
            process.waitUntilExit()
            XCTAssertEqual(process.terminationReason, .exit)
            XCTAssertEqual(process.terminationStatus, 123)
        } catch {
            XCTFail("Cant execute /bin/sh: \(error)")
        }
        XCTAssertEqual(fm.currentDirectoryPath, cwd)

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh", isDirectory: false)
            process.arguments = ["-c", "exit 0"]
            process.currentDirectoryURL = URL(fileURLWithPath: "/.../_no_such_directory", isDirectory: true)
            try process.run()
            XCTFail("Executed /bin/sh with invalid currentDirectoryURL")
            process.terminate()
            process.waitUntilExit()
        } catch {
        }
        XCTAssertEqual(fm.currentDirectoryPath, cwd)

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/..", isDirectory: false)
            process.arguments = []
            process.currentDirectoryURL = URL(fileURLWithPath: "/tmp")
            try process.run()
            XCTFail("Somehow executed a directory!")
            process.terminate()
            process.waitUntilExit()
        } catch {
        }
        XCTAssertEqual(fm.currentDirectoryPath, cwd)
        fm.changeCurrentDirectoryPath(cwd)
    }

    func test_preStartEndState() {
        let process = Process()
        XCTAssertNil(process.executableURL)
        XCTAssertNotNil(process.currentDirectoryURL)
        XCTAssertNil(process.arguments)
        XCTAssertNil(process.environment)
        XCTAssertFalse(process.isRunning)
        XCTAssertEqual(process.processIdentifier, 0)
        XCTAssertEqual(process.qualityOfService, .default)

        process.executableURL = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        _ = try? process.run()
        XCTAssertTrue(process.isRunning)
        XCTAssertTrue(process.processIdentifier > 0)
        process.terminate()
        process.waitUntilExit()
        XCTAssertFalse(process.isRunning)
        XCTAssertTrue(process.processIdentifier > 0)
        XCTAssertEqual(process.terminationReason, .uncaughtSignal)
        XCTAssertEqual(process.terminationStatus, SIGTERM)
    }

    func test_interrupt() {
        let helper = _SignalHelperRunner()
        do {
            try helper.start()
        }  catch {
            XCTFail("Cant run xdgTestHelper: \(error)")
            return
        }
        if !helper.waitForReady() {
            XCTFail("Didnt receive Ready from sub-process")
            return
        }

        let now = DispatchTime.now().uptimeNanoseconds
        let timeout = DispatchTime(uptimeNanoseconds: now + 2_000_000_000)

        var count = 3
        while count > 0 {
            helper.process.interrupt()
            guard helper.semaphore.wait(timeout: timeout) == .success else {
                helper.process.terminate()
                XCTFail("Timedout waiting for signal")
                return
            }

            if helper.sigIntCount == 3 {
                break
            }
            count -= 1
        }
        helper.process.terminate()
        XCTAssertEqual(helper.sigIntCount, 3)
        helper.process.waitUntilExit()
        let terminationReason = helper.process.terminationReason
        XCTAssertEqual(terminationReason, Process.TerminationReason.exit)
        let status = helper.process.terminationStatus
        XCTAssertEqual(status, 99)
    }

    func test_terminate() {
        let cat = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        guard let process = try? Process.run(cat, arguments: []) else {
            XCTFail("Cant run /bin/cat")
            return
        }

        process.terminate()
        process.waitUntilExit()
        let terminationReason = process.terminationReason
        XCTAssertEqual(terminationReason, Process.TerminationReason.uncaughtSignal)
        XCTAssertEqual(process.terminationStatus, SIGTERM)
    }


    func test_suspend_resume() {
        let helper = _SignalHelperRunner()
        do {
            try helper.start()
        }  catch {
            XCTFail("Cant run xdgTestHelper: \(error)")
            return
        }
        if !helper.waitForReady() {
            XCTFail("Didnt receive Ready from sub-process")
            return
        }
        let now = DispatchTime.now().uptimeNanoseconds
        let timeout = DispatchTime(uptimeNanoseconds: now + 2_000_000_000)

        func waitForSemaphore() -> Bool {
            guard helper.semaphore.wait(timeout: timeout) == .success else {
                helper.process.terminate()
                XCTFail("Timedout waiting for signal")
                return false
            }
            return true
        }

        XCTAssertTrue(helper.process.isRunning)
        XCTAssertTrue(helper.process.suspend())
        XCTAssertTrue(helper.process.isRunning)
        XCTAssertTrue(helper.process.resume())
        if waitForSemaphore() == false { return }
        XCTAssertEqual(helper.sigContCount, 1)

        XCTAssertTrue(helper.process.resume())
        XCTAssertTrue(helper.process.suspend())
        XCTAssertTrue(helper.process.resume())
        XCTAssertEqual(helper.sigContCount, 1)

        XCTAssertTrue(helper.process.suspend())
        XCTAssertTrue(helper.process.suspend())
        XCTAssertTrue(helper.process.resume())
        if waitForSemaphore() == false { return }

        helper.process.suspend()
        helper.process.resume()
        if waitForSemaphore() == false { return }
        XCTAssertEqual(helper.sigContCount, 3)

        helper.process.terminate()
        helper.process.waitUntilExit()
        XCTAssertFalse(helper.process.isRunning)
        XCTAssertFalse(helper.process.suspend())
        XCTAssertTrue(helper.process.resume())
        XCTAssertTrue(helper.process.resume())
    }


    func test_redirect_stdin_using_null() {
        let url = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardInput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_stdout_using_null() {
        let url = URL(fileURLWithPath: "/usr/bin/env", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardOutput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }

    func test_redirect_stdin_stdout_using_null() {
        let url = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_stderr_using_null() throws {
        let url = URL(fileURLWithPath: "/usr/bin/env", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardError = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_all_using_null() throws {
        let url = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }

    func test_redirect_all_using_nil() throws {
        let url = URL(fileURLWithPath: "/bin/cat", isDirectory: false)
        let task = Process()
        task.executableURL = url
        task.standardInput = nil
        task.standardOutput = nil
        task.standardError = nil
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }
#endif
}

private enum Error: Swift.Error {
    case TerminationStatus(Int32)
    case UnicodeDecodingError(Data)
    case InvalidEnvironmentVariable(String)
}

// Run xdgTestHelper, wait for 'Ready' from the sub-process, then signal a semaphore.
// Read lines from a pipe and store in a queue.
class _SignalHelperRunner {
    let process = Process()
    let semaphore = DispatchSemaphore(value: 0)

    private let outputPipe = Pipe()
    private let sQueue = DispatchQueue(label: "signal queue")

    private var gotReady = false
    private var bytesIn = Data()
    private var _sigIntCount = 0
    private var _sigContCount = 0
    var sigIntCount: Int { return sQueue.sync { return _sigIntCount } }
    var sigContCount: Int { return sQueue.sync { return _sigContCount } }


    init() {
        process.executableURL = xdgTestHelperURL()
        process.environment = ProcessInfo.processInfo.environment
        process.arguments = ["--signal-test"]
        process.standardOutput = outputPipe.fileHandleForWriting

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fh in
            if let strongSelf = self {
                let newLine = UInt8(ascii: "\n")

                strongSelf.bytesIn.append(fh.availableData)
                if strongSelf.bytesIn.isEmpty {
                    return
                }
                // Split the incoming data into lines.
                while let index = strongSelf.bytesIn.firstIndex(of: newLine) {
                    if index >= strongSelf.bytesIn.startIndex {
                        // don't include the newline when converting to string
                        let line = String(data: strongSelf.bytesIn[strongSelf.bytesIn.startIndex..<index], encoding: String.Encoding.utf8) ?? ""
                        strongSelf.bytesIn.removeSubrange(strongSelf.bytesIn.startIndex...index)

                        if strongSelf.gotReady == false && line == "Ready" {
                            strongSelf.semaphore.signal()
                            strongSelf.gotReady = true;
                        }
                        else if strongSelf.gotReady == true {
                            if line == "Signal: SIGINT" {
                                strongSelf._sigIntCount += 1
                                strongSelf.semaphore.signal()
                            }
                            else if line == "Signal: SIGCONT" {
                                strongSelf._sigContCount += 1
                                strongSelf.semaphore.signal()
                            }
                        }
                    }
                }
            }
        }
    }

    deinit {
        process.terminate()
        process.waitUntilExit()
    }

    func start() throws {
        try process.run()
    }

    func waitForReady() -> Bool {
        let now = DispatchTime.now().uptimeNanoseconds
        let timeout = DispatchTime(uptimeNanoseconds: now + 2_000_000_000)
        guard semaphore.wait(timeout: timeout) == .success else {
            process.terminate()
            return false
        }
        return true
    }
}

#if !os(Android)
internal func runTask(_ arguments: [String], environment: [String: String]? = nil, currentDirectoryPath: String? = nil) throws -> (String, String) {
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

    var stdoutData = Data()
    stdoutPipe.fileHandleForReading.readabilityHandler = { fh in
        stdoutData.append(fh.availableData)
    }

    var stderrData = Data()
    stderrPipe.fileHandleForReading.readabilityHandler = { fh in
        stderrData.append(fh.availableData)
    }

    try process.run()
    process.waitUntilExit()
    stdoutPipe.fileHandleForReading.readabilityHandler = nil
    stderrPipe.fileHandleForReading.readabilityHandler = nil

    // Drain any data remaining in the pipes
#if DARWIN_COMPATIBILITY_TESTS
    // Use old API for now
    stdoutData.append(stdoutPipe.fileHandleForReading.availableData)
    stderrData.append(stderrPipe.fileHandleForReading.availableData)
#else
    if let d = try stdoutPipe.fileHandleForReading.readToEnd() {
        stdoutData.append(d)
    }

    if let d = try stderrPipe.fileHandleForReading.readToEnd() {
        stderrData.append(d)
    }
#endif

    guard process.terminationStatus == 0 else {
        throw Error.TerminationStatus(process.terminationStatus)
    }

    guard let stdout = String(data: stdoutData, encoding: .utf8) else {
        throw Error.UnicodeDecodingError(stdoutData)
    }

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

