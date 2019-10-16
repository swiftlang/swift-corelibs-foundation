// This source file is part of the Swift.org open source project
//
// Copyright (c) 2015 - 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestProcess : XCTestCase {
    
    func test_exit0() throws {
        let process = Process()
        let executableURL = xdgTestHelperURL()
        if #available(OSX 10.13, *) {
            process.executableURL = executableURL
        } else {
            // Fallback on earlier versions
            process.launchPath = executableURL.path
        }
        XCTAssertEqual(executableURL.path, process.launchPath)
        process.arguments = ["--exit", "0"]
        try process.run()
        process.waitUntilExit()
        
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_exit1() throws {
        let process = Process()
        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--exit", "1"]

        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_exit100() throws {
        let process = Process()
        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--exit", "100"]
        
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 100)
        XCTAssertEqual(process.terminationReason, .exit)
    }
    
    func test_sleep2() throws {
        let process = Process()
        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--sleep", "2"]
        
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(process.terminationReason, .exit)
    }

    func test_terminationReason_uncaughtSignal() throws {
        let process = Process()
        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--signal-self", SIGTERM.description]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, SIGTERM)
        XCTAssertEqual(process.terminationReason, .uncaughtSignal)
    }

    func test_pipe_stdin() throws {
        let process = Process()

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--cat"]
        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        try process.run()
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

    func test_pipe_stdout() throws {
        let process = Process()

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--getcwd"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = nil

        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }

        XCTAssertEqual(string.trimmingCharacters(in: CharacterSet(["\n", "\r"])), FileManager.default.currentDirectoryPath)
    }

    func test_pipe_stderr() throws {
        let process = Process()

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--cat", "invalid_file_name"]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)

        let data = errorPipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        // Ignore messages from malloc debug etc on macOs
        let errMsg = string.trimmingCharacters(in: CharacterSet(["\n"])).components(separatedBy: "\n").last
        XCTAssertEqual(errMsg, "cat: invalid_file_name: No such file or directory")
    }

    func test_pipe_stdout_and_stderr_same_pipe() throws {
        let process = Process()

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--cat", "invalid_file_name"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Clear the environment to stop the malloc debug flags used in Xcode debug being
        // set in the subprocess.
        process.environment = [:]
#if os(Android)
        // In Android, we have to provide at least an LD_LIBRARY_PATH, or
        // xdgTestHelper will not be able to find the Swift libraries.
        if let ldLibraryPath = ProcessInfo.processInfo.environment["LD_LIBRARY_PATH"] {
            process.environment?["LD_LIBRARY_PATH"] = ldLibraryPath
        }
#endif
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)

        let data = pipe.fileHandleForReading.availableData
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }

        // Ignore messages from malloc debug etc on macOS
        let errMsg = string.trimmingCharacters(in: CharacterSet(["\n"])).components(separatedBy: "\n").last
        XCTAssertEqual(errMsg, "cat: invalid_file_name: No such file or directory")
    }

    func test_file_stdout() throws {
        let process = Process()

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--getcwd"]

        let url: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: false)
        _ = FileManager.default.createFile(atPath: url.path, contents: Data())
        defer { _ = try? FileManager.default.removeItem(at: url) }

        let handle: FileHandle = FileHandle(forUpdatingAtPath: url.path)!

        process.standardOutput = handle

        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        handle.seek(toFileOffset: 0)
        let data = handle.readDataToEndOfFile()
        guard let string = String(data: data, encoding: .ascii) else {
            XCTFail("Could not read stdout")
            return
        }
        XCTAssertEqual(string.trimmingCharacters(in: CharacterSet(["\r", "\n"])), FileManager.default.currentDirectoryPath)
    }
    
    func test_passthrough_environment() {
        do {
            let (output, _) = try runTask([xdgTestHelperURL().path, "--env"], environment: nil)
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
            let (output, _) = try runTask([xdgTestHelperURL().path, "--env"], environment: [:])
            let env = try parseEnv(output)
#if os(Windows)
            // On Windows, Path is always passed to the sub process
            XCTAssertEqual(env.count, 1)
#else
            XCTAssertEqual(env.count, 0)
#endif
        } catch {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_custom_environment() {
        do {
            let input = ["HELLO": "WORLD", "HOME": "CUPERTINO"]
            let (output, _) = try runTask([xdgTestHelperURL().path, "--env"], environment: input)
            var env = try parseEnv(output)
#if os(Windows)
            // On Windows, Path is always passed to the sub process, remove it
            // before comparing.
            env.removeValue(forKey: "Path")
#endif
            XCTAssertEqual(env, input)
        } catch {
            XCTFail("Test failed: \(error)")
        }
    }

    func test_current_working_directory() throws {
        let tmpDir = { () -> String in
            // NSTemporaryDirectory might return a final slash, but
            // FileManager.currentDirectoryPath seems to avoid it.
            var dir = NSTemporaryDirectory()
            if (dir.hasSuffix("/") && dir != "/") || dir.hasSuffix("\\") {
               dir.removeLast()
            }
            return dir
        }()

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
            let process = try Process.run(xdgTestHelperURL(), arguments: ["--exit", "123"], terminationHandler: nil)
            process.waitUntilExit()
            XCTAssertEqual(process.terminationReason, .exit)
            XCTAssertEqual(process.terminationStatus, 123)
        } catch {
            XCTFail("Cant execute \(xdgTestHelperURL().path): \(error)")
        }
        XCTAssertEqual(fm.currentDirectoryPath, cwd)

        do {
            let process = Process()
            process.executableURL = xdgTestHelperURL()
            process.arguments = ["--exit", "0"]
            process.currentDirectoryURL = URL(fileURLWithPath: "/.../_no_such_directory", isDirectory: true)
            try process.run()
            XCTFail("Executed \(xdgTestHelperURL().path) with invalid currentDirectoryURL")
            process.terminate()
            process.waitUntilExit()
        } catch {
        }
        XCTAssertEqual(fm.currentDirectoryPath, cwd)

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/..", isDirectory: false)
            process.arguments = []
            process.currentDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
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

        process.executableURL = xdgTestHelperURL()
        process.arguments = ["--cat"]
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
        guard let process = try? Process.run(xdgTestHelperURL(), arguments: ["--cat"]) else {
            XCTFail("Cant run 'cat'")
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

        _ = helper.process.suspend()
        _ = helper.process.resume()
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
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--cat"]
        task.standardInput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_stdout_using_null() {
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--env"]
        task.standardOutput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }

    func test_redirect_stdin_stdout_using_null() {
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--cat"]
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_stderr_using_null() throws {
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--env"]
        task.standardError = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_redirect_all_using_null() throws {
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--cat"]
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }

    func test_redirect_all_using_nil() throws {
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        task.arguments = ["--cat"]
        task.standardInput = nil
        task.standardOutput = nil
        task.standardError = nil
        XCTAssertNoThrow(try task.run())
        task.waitUntilExit()
    }


    func test_plutil() throws {
        let task = Process()

        guard let url = testBundle().url(forAuxiliaryExecutable: "plutil") else {
            throw Error.ExternalBinaryNotFound("plutil")
        }

        task.executableURL = url
        task.arguments = []
        let stdoutPipe = Pipe()
        task.standardOutput = stdoutPipe

        var stdoutData = Data()
        stdoutPipe.fileHandleForReading.readabilityHandler = { fh in
            stdoutData.append(fh.availableData)
        }
        try task.run()
        task.waitUntilExit()
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        if let d = try stdoutPipe.fileHandleForReading.readToEnd() {
            stdoutData.append(d)
        }
        XCTAssertEqual(String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), "No files specified.")
    }


    static var allTests: [(String, (TestProcess) -> () throws -> Void)] {
        var tests = [
            ("test_exit0" , test_exit0),
            ("test_exit1" , test_exit1),
            ("test_exit100" , test_exit100),
            ("test_sleep2", test_sleep2),
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
            ("test_terminate", test_terminate),
            ("test_redirect_stdin_using_null", test_redirect_stdin_using_null),
            ("test_redirect_stdout_using_null", test_redirect_stdout_using_null),
            ("test_redirect_stdin_stdout_using_null", test_redirect_stdin_stdout_using_null),
            ("test_redirect_stderr_using_null", test_redirect_stderr_using_null),
            ("test_redirect_all_using_null", test_redirect_all_using_null),
            ("test_redirect_all_using_nil", test_redirect_all_using_nil),
            ("test_plutil", test_plutil),
        ]

#if !os(Windows)
        // Windows doesn't have signals
        tests += [
            ("test_interrupt", test_interrupt),
            ("test_suspend_resume", test_suspend_resume),
        ]
#endif
        return tests
    }
}

private enum Error: Swift.Error {
    case TerminationStatus(Int32)
    case UnicodeDecodingError(Data)
    case InvalidEnvironmentVariable(String)
    case ExternalBinaryNotFound(String)
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

internal func runTask(_ arguments: [String], environment: [String: String]? = nil, currentDirectoryPath: String? = nil) throws -> (String, String) {
    let process = Process()

    var arguments = arguments
    process.launchPath = arguments.removeFirst()
    process.arguments = arguments
    // Darwin Foundation doesnt allow .environment to be set to nil although the documentation
    // says it is an optional. https://developer.apple.com/documentation/foundation/process/1409412-environment
    if var e = environment {
#if os(Android)
        // In Android, we have to provide at least an LD_LIBRARY_PATH, or
        // xdgTestHelper will not be able to find the Swift libraries.
        if e["LD_LIBRARY_PATH"] == nil {
            if let ldLibraryPath = ProcessInfo.processInfo.environment["LD_LIBRARY_PATH"] {
                e["LD_LIBRARY_PATH"] = ldLibraryPath
            }
        }
#endif
        process.environment = e
    }

    if let dirPath = currentDirectoryPath {
        process.currentDirectoryURL = URL(fileURLWithPath: dirPath, isDirectory: true)
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
    for line in env.components(separatedBy: .newlines) where line != "" {
        guard let range = line.range(of: "=") else {
            throw Error.InvalidEnvironmentVariable(line)
        }
        let key = String(line[..<range.lowerBound])
#if os(Android)
        // NOTE: this works because the results of parseEnv are never checked
        // against the parent environment, where this key will be set. If that
        // ever happen, the checks should be changed.
        if key == "LD_LIBRARY_PATH" {
            continue
        }
#endif
        result[key] = String(line[range.upperBound...])
    }
    return result
}
