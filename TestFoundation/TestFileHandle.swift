// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestFileHandle : XCTestCase {
    static var allTests : [(String, (TestFileHandle) -> () throws -> ())] {
        return [
            ("test_constants", test_constants),
            ("test_nullDevice", test_nullDevice),
            ("test_truncate", test_truncate),
        ]
    }

    func test_constants() {
        XCTAssertEqual(FileHandle.readCompletionNotification.rawValue, "NSFileHandleReadCompletionNotification",
                       "\(FileHandle.readCompletionNotification.rawValue) is not equal to NSFileHandleReadCompletionNotification")
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

    func test_truncate() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let filePath = tempDir.appendingPathComponent("temp_file")
        guard fm.createFile(atPath: filePath.path, contents: nil, attributes: nil) else {
            XCTAssertTrue(false, "Unable to create temporary file");
            return
        }
        guard let fh = FileHandle(forWritingAtPath: filePath.path) else {
            XCTAssertTrue(false, "Unable to open temporary file")
            return
        }
        defer { try? fm.removeItem(atPath: filePath.path) }

        for newSize: UInt64 in [0, 100, 5, 1] {
            fh.truncateFile(atOffset: newSize)
            guard let size = (try fm.attributesOfItem(atPath: filePath.path))[.size] as? NSNumber else {
                XCTFail("Cant get size")
                continue
            }
            XCTAssertEqual(newSize, size.uint64Value)
            XCTAssertEqual(newSize, fh.offsetInFile)
        }
    }
}
