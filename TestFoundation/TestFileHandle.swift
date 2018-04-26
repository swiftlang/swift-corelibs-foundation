// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestFileHandle : XCTestCase {
    static var allTests : [(String, (TestFileHandle) -> () throws -> ())] {
        return [
            ("test_constants", test_constants),
            ("test_pipe", test_pipe),
            ("test_nullDevice", test_nullDevice),
            ("test_truncateFile", test_truncateFile)
        ]
    }

    func test_constants() {
        XCTAssertEqual(FileHandle.readCompletionNotification.rawValue, "NSFileHandleReadCompletionNotification",
                       "\(FileHandle.readCompletionNotification.rawValue) is not equal to NSFileHandleReadCompletionNotification")
    }

    func test_pipe() {
        let pipe = Pipe()
        let inputs = ["Hello", "world", "🐶"]

        for input in inputs {
            let inputData = input.data(using: .utf8)!

            // write onto pipe
            pipe.fileHandleForWriting.write(inputData)

            let outputData = pipe.fileHandleForReading.availableData
            let output = String(data: outputData, encoding: .utf8)

            XCTAssertEqual(output, input)
        }
    }

    func test_nullDevice() {
        let fh = FileHandle.nullDevice

        XCTAssertEqual(fh.fileDescriptor, -1)
        fh.closeFile()
        fh.seek(toFileOffset: 10)
        XCTAssertEqual(fh.offsetInFile, 0)
        XCTAssertEqual(fh.seekToEndOfFile(), 0)
        XCTAssertEqual(fh.readData(ofLength: 15).count, 0)
        fh.synchronizeFile()

        fh.write(Data(bytes: [1,2]))
        fh.seek(toFileOffset: 0)
        XCTAssertEqual(fh.availableData.count, 0)
        fh.write(Data(bytes: [1,2]))
        fh.seek(toFileOffset: 0)
        XCTAssertEqual(fh.readDataToEndOfFile().count, 0)
    }

    func test_truncateFile() {
        mkstemp(template: "test_truncateFile.XXXXXX") { (fh) in
            fh.truncateFile(atOffset: 50)
            XCTAssertEqual(fh.offsetInFile, 50)

            fh.truncateFile(atOffset: 0)
            XCTAssertEqual(fh.offsetInFile, 0)

            fh.truncateFile(atOffset: 100)
            XCTAssertEqual(fh.offsetInFile, 100)

            fh.write(Data(bytes: [1, 2]))
            XCTAssertEqual(fh.offsetInFile, 102)

            fh.seek(toFileOffset: 4)
            XCTAssertEqual(fh.offsetInFile, 4)

            (0..<20).forEach { fh.write(Data(bytes: [$0])) }
            XCTAssertEqual(fh.offsetInFile, 24)

            fh.seekToEndOfFile()
            XCTAssertEqual(fh.offsetInFile, 102)

            fh.truncateFile(atOffset: 10)
            XCTAssertEqual(fh.offsetInFile, 10)

            fh.seek(toFileOffset: 0)
            XCTAssertEqual(fh.offsetInFile, 0)

            let data = fh.readDataToEndOfFile()
            XCTAssertEqual(data.count, 10)
            XCTAssertEqual(data, Data(bytes: [0, 0, 0, 0, 0, 1, 2, 3, 4, 5]))
        }
    }
}
