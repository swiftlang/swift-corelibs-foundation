// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

open class FileHandle : NSObject, NSSecureCoding {
    internal var _fd: Int32
    internal var _closeOnDealloc: Bool
    internal var _closed: Bool = false
    
    open var availableData: Data {
        return _readDataOfLength(Int.max, untilEOF: false)
    }
    
    open func readDataToEndOfFile() -> Data {
        return readData(ofLength: Int.max)
    }

    open func readData(ofLength length: Int) -> Data {
        return _readDataOfLength(length, untilEOF: true)
    }

    internal func _readDataOfLength(_ length: Int, untilEOF: Bool) -> Data {
        var statbuf = stat()
        var dynamicBuffer: UnsafeMutableRawPointer? = nil
        var total = 0
        if _closed || fstat(_fd, &statbuf) < 0 {
            fatalError("Unable to read file")
        }
        if statbuf.st_mode & S_IFMT != S_IFREG {
            /* We get here on sockets, character special files, FIFOs ... */
            var currentAllocationSize: size_t = 1024 * 8
            dynamicBuffer = malloc(currentAllocationSize)
            var remaining = length
            while remaining > 0 {
                let amountToRead = min(1024 * 8, remaining)
                // Make sure there is always at least amountToRead bytes available in the buffer.
                if (currentAllocationSize - total) < amountToRead {
                    currentAllocationSize *= 2
                    dynamicBuffer = _CFReallocf(dynamicBuffer!, currentAllocationSize)
                    if dynamicBuffer == nil {
                        fatalError("unable to allocate backing buffer")
                    }
                }
                let amtRead = read(_fd, dynamicBuffer!.advanced(by: total), amountToRead)
                if 0 > amtRead {
                    free(dynamicBuffer)
                    fatalError("read failure")
                }
                if 0 == amtRead {
                    break // EOF
                }
                
                total += amtRead
                remaining -= amtRead
                
                if total == length || !untilEOF {
                    break // We read everything the client asked for.
                }
            }
        } else {
            let offset = lseek(_fd, 0, SEEK_CUR)
            if offset < 0 {
                fatalError("Unable to fetch current file offset")
            }
            if off_t(statbuf.st_size) > offset {
                var remaining = size_t(off_t(statbuf.st_size) - offset)
                remaining = min(remaining, size_t(length))
                
                dynamicBuffer = malloc(remaining)
                if dynamicBuffer == nil {
                    fatalError("Malloc failure")
                }
                
                while remaining > 0 {
                    let count = read(_fd, dynamicBuffer!.advanced(by: total), remaining)
                    if count < 0 {
                        free(dynamicBuffer)
                        fatalError("Unable to read from fd")
                    }
                    if count == 0 {
                        break
                    }
                    total += count
                    remaining -= count
                }
            }
        }

        if length == Int.max && total > 0 {
            dynamicBuffer = _CFReallocf(dynamicBuffer!, total)
        }
        
        if total == 0 {
            free(dynamicBuffer)
        }
        else if total > 0 {
            let bytePtr = dynamicBuffer!.bindMemory(to: UInt8.self, capacity: total)
            return Data(bytesNoCopy: bytePtr, count: total, deallocator: .free)
        }
        else {
            assertionFailure("The total number of read bytes must not be negative")
            free(dynamicBuffer)
        }
        
        return Data()
    }
    
    open func write(_ data: Data) {
        data.enumerateBytes() { (bytes, range, stop) in
            do {
                try NSData.write(toFileDescriptor: self._fd, path: nil, buf: UnsafeRawPointer(bytes.baseAddress!), length: bytes.count)
            } catch {
                fatalError("Write failure")
            }
        }
    }
    
    // TODO: Error handling.
    
    open var offsetInFile: UInt64 {
        return UInt64(lseek(_fd, 0, SEEK_CUR))
    }
    
    @discardableResult
    open func seekToEndOfFile() -> UInt64 {
        return UInt64(lseek(_fd, 0, SEEK_END))
    }
    
    open func seek(toFileOffset offset: UInt64) {
        lseek(_fd, off_t(offset), SEEK_SET)
    }

    open func truncateFile(atOffset offset: UInt64) {
        if lseek(_fd, off_t(offset), SEEK_SET) < 0 { fatalError("lseek() failed.") }
        if ftruncate(_fd, off_t(offset)) < 0 { fatalError("ftruncate() failed.") }
    }

    open func synchronizeFile() {
        fsync(_fd)
    }
    
    open func closeFile() {
        if !_closed {
            close(_fd)
            _closed = true
        }
    }
    
    public init(fileDescriptor fd: Int32, closeOnDealloc closeopt: Bool) {
        _fd = fd
        _closeOnDealloc = closeopt
    }
    
    internal init?(path: String, flags: Int32, createMode: Int) {
        _fd = _CFOpenFileWithMode(path, flags, mode_t(createMode))
        _closeOnDealloc = true
        super.init()
        if _fd < 0 {
            return nil
        }
    }
    
    deinit {
        if _fd >= 0 && _closeOnDealloc && !_closed {
            close(_fd)
        }
    }
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}

extension FileHandle {
    
    internal static var _stdinFileHandle: FileHandle = {
        return FileHandle(fileDescriptor: STDIN_FILENO, closeOnDealloc: false)
    }()

    open class var standardInput: FileHandle {
        return _stdinFileHandle
    }
    
    internal static var _stdoutFileHandle: FileHandle = {
        return FileHandle(fileDescriptor: STDOUT_FILENO, closeOnDealloc: false)
    }()

    open class var standardOutput: FileHandle {
        return _stdoutFileHandle
    }
    
    internal static var _stderrFileHandle: FileHandle = {
        return FileHandle(fileDescriptor: STDERR_FILENO, closeOnDealloc: false)
    }()
    
    open class var standardError: FileHandle {
        return _stderrFileHandle
    }

    internal static var _nulldeviceFileHandle: FileHandle = {
        class NullDevice: FileHandle {
            override var availableData: Data {
                return Data()
            }

            override func readDataToEndOfFile() -> Data {
                return Data()
            }

            override func readData(ofLength length: Int) -> Data {
                return Data()
            }

            override func write(_ data: Data) {}

            override var offsetInFile: UInt64 {
                return 0
            }

            override func seekToEndOfFile() -> UInt64 {
                return 0
            }

            override func seek(toFileOffset offset: UInt64) {}

            override func truncateFile(atOffset offset: UInt64) {}

            override func synchronizeFile() {}

            override func closeFile() {}

            deinit {}
        }

        return NullDevice(fileDescriptor: -1, closeOnDealloc: false)
    }()

    open class var nullDevice: FileHandle {
        return _nulldeviceFileHandle
    }

    public convenience init?(forReadingAtPath path: String) {
        self.init(path: path, flags: O_RDONLY, createMode: 0)
    }
    
    public convenience init?(forWritingAtPath path: String) {
        self.init(path: path, flags: O_WRONLY, createMode: 0)
    }
    
    public convenience init?(forUpdatingAtPath path: String) {
        self.init(path: path, flags: O_RDWR, createMode: 0)
    }
    
    internal static func _openFileDescriptorForURL(_ url : URL, flags: Int32, reading: Bool) throws -> Int32 {
        let path = url.path
        let fd = _CFOpenFile(path, flags)
        if fd < 0 {
            throw _NSErrorWithErrno(errno, reading: reading, url: url)
        }
        return fd
    }
    
    public convenience init(forReadingFrom url: URL) throws {
        let fd = try FileHandle._openFileDescriptorForURL(url, flags: O_RDONLY, reading: true)
        self.init(fileDescriptor: fd, closeOnDealloc: true)
    }
    
    public convenience init(forWritingTo url: URL) throws {
        let fd = try FileHandle._openFileDescriptorForURL(url, flags: O_WRONLY, reading: false)
        self.init(fileDescriptor: fd, closeOnDealloc: true)
    }

    public convenience init(forUpdating url: URL) throws {
        let fd = try FileHandle._openFileDescriptorForURL(url, flags: O_RDWR, reading: false)
        self.init(fileDescriptor: fd, closeOnDealloc: true)
    }
}

extension NSExceptionName {
    public static let fileHandleOperationException = NSExceptionName(rawValue: "NSFileHandleOperationException")
}

extension Notification.Name {
    public static let NSFileHandleReadToEndOfFileCompletion = Notification.Name(rawValue: "NSFileHandleReadToEndOfFileCompletionNotification")
    public static let NSFileHandleConnectionAccepted = Notification.Name(rawValue: "NSFileHandleConnectionAcceptedNotification")
    public static let NSFileHandleDataAvailable = Notification.Name(rawValue: "NSFileHandleDataAvailableNotification")
}

extension FileHandle {
    public static let readCompletionNotification = Notification.Name(rawValue: "NSFileHandleReadCompletionNotification")
}

public let NSFileHandleNotificationDataItem: String = "NSFileHandleNotificationDataItem"
public let NSFileHandleNotificationFileHandleItem: String = "NSFileHandleNotificationFileHandleItem"

extension FileHandle {
    open func readInBackgroundAndNotify(forModes modes: [RunLoopMode]?) {
        NSUnimplemented()
    }

    open func readInBackgroundAndNotify() {
        NSUnimplemented()
    }

    open func readToEndOfFileInBackgroundAndNotify(forModes modes: [RunLoopMode]?) {
        NSUnimplemented()
    }

    open func readToEndOfFileInBackgroundAndNotify() {
        NSUnimplemented()
    }
    
    open func acceptConnectionInBackgroundAndNotify(forModes modes: [RunLoopMode]?) {
        NSUnimplemented()
    }

    open func acceptConnectionInBackgroundAndNotify() {
        NSUnimplemented()
    }
    
    open func waitForDataInBackgroundAndNotify(forModes modes: [RunLoopMode]?) {
        NSUnimplemented()
    }

    open func waitForDataInBackgroundAndNotify() {
        NSUnimplemented()
    }
    
    open var readabilityHandler: ((FileHandle) -> Void)? {
        NSUnimplemented()
    }

    open var writeabilityHandler: ((FileHandle) -> Void)? {
        NSUnimplemented()
    }
}

extension FileHandle {
    public convenience init(fileDescriptor fd: Int32) {
        self.init(fileDescriptor: fd, closeOnDealloc: false)
    }
    
    open var fileDescriptor: Int32 {
        return _fd
    }
}

open class Pipe: NSObject {
    private let readHandle: FileHandle
    private let writeHandle: FileHandle
    
    public override init() {
        /// the `pipe` system call creates two `fd` in a malloc'ed area
        var fds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        defer {
            free(fds)
        }
        /// If the operating system prevents us from creating file handles, stop
        guard pipe(fds) == 0 else { fatalError("Could not open pipe file handles") }
        
        /// The handles below auto-close when the `NSFileHandle` is deallocated, so we
        /// don't need to add a `deinit` to this class
        
        /// Create the read handle from the first fd in `fds`
        self.readHandle = FileHandle(fileDescriptor: fds.pointee, closeOnDealloc: true)
        
        /// Advance `fds` by one to create the write handle from the second fd
        self.writeHandle = FileHandle(fileDescriptor: fds.successor().pointee, closeOnDealloc: true)
        
        super.init()
    }
    
    open var fileHandleForReading: FileHandle {
        return self.readHandle
    }
    
    open var fileHandleForWriting: FileHandle {
        return self.writeHandle
    }
}
