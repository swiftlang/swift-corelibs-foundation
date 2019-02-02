// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class FileHandle : NSObject, NSSecureCoding {
#if os(Windows)
    private var _handle: HANDLE

    @available(windows, unavailable, message: "Cannot perform non-owning handle to fd conversion")
    open var fileDescriptor: Int32 {
        NSUnsupported()
    }

    private func _checkFileHandle() {
        precondition(_handle != INVALID_HANDLE_VALUE, "Invalid file handle")
    }

#else
    private var _fd: Int32

    open var fileDescriptor: Int32 {
        return _fd
    }

    private func _checkFileHandle() {
        precondition(_fd >= 0, "Bad file descriptor")
    }
#endif

    private var _closeOnDealloc: Bool


    open var readabilityHandler: ((FileHandle) -> Void)? = {
      (FileHandle) -> Void in NSUnimplemented()
    }

    open var writeabilityHandler: ((FileHandle) -> Void)? = {
      (FileHandle) -> Void in NSUnimplemented()
    }

    open var availableData: Data {
        _checkFileHandle()
        do {
            let readResult = try _readDataOfLength(Int.max, untilEOF: false)
            return readResult.toData()
        } catch {
            fatalError("\(error)")
        }
    }
    
    open func readDataToEndOfFile() -> Data {
        _checkFileHandle()
        return readData(ofLength: Int.max)
    }

    open func readData(ofLength length: Int) -> Data {
        _checkFileHandle()
        do {
            let readResult = try _readDataOfLength(length, untilEOF: true)
            return readResult.toData()
        } catch {
            fatalError("\(error)")
        }
    }

    internal func _readDataOfLength(_ length: Int, untilEOF: Bool, options: NSData.ReadingOptions = []) throws -> NSData.NSDataReadResult {
#if os(Windows)

        if length == 0 && !untilEOF {
          // Nothing requested, return empty response
          return NSData.NSDataReadResult(bytes: nil, length: 0, deallocator: nil)
        }

        var fiFileInfo: BY_HANDLE_FILE_INFORMATION = BY_HANDLE_FILE_INFORMATION()
        if GetFileInformationByHandle(_handle, &fiFileInfo) == FALSE {
          throw NSError(domain: NSPOSIXErrorDomain, code: Int(GetLastError()),
                        userInfo: nil)
        }

        if fiFileInfo.dwFileAttributes & DWORD(FILE_ATTRIBUTE_NORMAL) == FILE_ATTRIBUTE_NORMAL {
          if options.contains(.alwaysMapped) {
            let hMapping: HANDLE =
                CreateFileMappingA(_handle, nil, DWORD(PAGE_READONLY), 0, 0, nil)
            if hMapping == HANDLE(bitPattern: 0) {
              fatalError("CreateFileMappingA failed")
            }

            let szFileSize: UInt64 = (UInt64(fiFileInfo.nFileSizeHigh) << 32) | UInt64(fiFileInfo.nFileSizeLow << 0)
            let szMapSize: UInt64 = Swift.min(UInt64(length), szFileSize)
            let pData: UnsafeMutableRawPointer =
                MapViewOfFile(hMapping, DWORD(FILE_MAP_READ), 0, 0, szMapSize)

            return NSData.NSDataReadResult(bytes: pData, length: Int(szMapSize)) { buffer, length in
              if UnmapViewOfFile(buffer) == FALSE {
                fatalError("UnmapViewOfFile failed")
              }
              if CloseHandle(hMapping) == FALSE {
                fatalError("CloseHandle failed")
              }
            }
          }
        }

        let blockSize: Int = 8 * 1024
        var allocated: Int = blockSize
        var buffer: UnsafeMutableRawPointer = malloc(allocated)!
        var total: Int = 0

        while total < length {
          let remaining = length - total
          let BytesToRead: DWORD = DWORD(min(blockSize, remaining))

          if (allocated - total) < BytesToRead {
            allocated *= 2
            buffer = _CFReallocf(buffer, allocated)
          }

          var BytesRead: DWORD = 0
          if ReadFile(_handle, buffer.advanced(by: total), BytesToRead, &BytesRead, nil) == FALSE {
            free(buffer)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(GetLastError()), userInfo: nil)
          }
          total += Int(BytesRead)
          if BytesRead == 0 || !untilEOF {
            break
          }
        }

        if total == 0 {
          free(buffer)
          return NSData.NSDataReadResult(bytes: nil, length: 0, deallocator: nil)
        }

        buffer = _CFReallocf(buffer, total)
        let data = buffer.bindMemory(to: UInt8.self, capacity: total)
        return NSData.NSDataReadResult(bytes: data, length: total) { buffer, length in
          free(buffer)
        }
#else
        if length == 0 && !untilEOF {
            // Nothing requested, return empty response
            return NSData.NSDataReadResult(bytes: nil, length: 0, deallocator: nil)
        }

        var statbuf = stat()
        if fstat(_fd, &statbuf) < 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }

        let readBlockSize: Int
        if statbuf.st_mode & S_IFMT == S_IFREG {
            // TODO: Should files over a certain size always be mmap()'d?
            if options.contains(.alwaysMapped) {
                // Filesizes are often 64bit even on 32bit systems
                let mapSize = min(length, Int(clamping: statbuf.st_size))
                let data = mmap(nil, mapSize, PROT_READ, MAP_PRIVATE, _fd, 0)
                // Swift does not currently expose MAP_FAILURE
                if data != UnsafeMutableRawPointer(bitPattern: -1) {
                    return NSData.NSDataReadResult(bytes: data!, length: mapSize) { buffer, length in
                        munmap(buffer, length)
                    }
                }
            }

            if statbuf.st_blksize > 0 {
                readBlockSize = Int(clamping: statbuf.st_blksize)
            } else {
                readBlockSize = 1024 * 8
            }
        } else {
            /* We get here on sockets, character special files, FIFOs ... */
            readBlockSize = 1024 * 8
        }
        var currentAllocationSize = readBlockSize
        var dynamicBuffer = malloc(currentAllocationSize)!
        var total = 0

        while total < length {
            let remaining = length - total
            let amountToRead = min(readBlockSize, remaining)
            // Make sure there is always at least amountToRead bytes available in the buffer.
            if (currentAllocationSize - total) < amountToRead {
                currentAllocationSize *= 2
                dynamicBuffer = _CFReallocf(dynamicBuffer, currentAllocationSize)
            }
            let amtRead = read(_fd, dynamicBuffer.advanced(by: total), amountToRead)
            if amtRead < 0 {
                free(dynamicBuffer)
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            }
            total += amtRead
            if amtRead == 0 || !untilEOF { // If there is nothing more to read or we shouldnt keep reading then exit
                break
            }
        }

        if total == 0 {
            free(dynamicBuffer)
            return NSData.NSDataReadResult(bytes: nil, length: 0, deallocator: nil)
        }
        dynamicBuffer = _CFReallocf(dynamicBuffer, total)
        let bytePtr = dynamicBuffer.bindMemory(to: UInt8.self, capacity: total)
        return NSData.NSDataReadResult(bytes: bytePtr, length: total) { buffer, length in
            free(buffer)
        }
#endif
    }

    open func write(_ data: Data) {
        _checkFileHandle()
#if os(Windows)
      data.enumerateBytes() { (bytes, range, stop) in
        do {
          try NSData.write(toHandle: self._handle, path: nil,
                           buf: UnsafeRawPointer(bytes.baseAddress!),
                           length: bytes.count)
        } catch {
          fatalError("Write failure")
        }
      }
#else
        data.enumerateBytes() { (bytes, range, stop) in
            do {
                try NSData.write(toFileDescriptor: self._fd, path: nil, buf: UnsafeRawPointer(bytes.baseAddress!), length: bytes.count)
            } catch {
                fatalError("Write failure")
            }
        }
#endif
    }

    // TODO: Error handling.

    open var offsetInFile: UInt64 {
        _checkFileHandle()
#if os(Windows)
        var liPointer: LARGE_INTEGER = LARGE_INTEGER(QuadPart: 0)
        if SetFilePointerEx(_handle, LARGE_INTEGER(QuadPart: 0),
                            &liPointer, DWORD(FILE_CURRENT)) == FALSE {
          fatalError("SetFilePointerEx failed")
        }
        return UInt64(liPointer.QuadPart)
#else
        return UInt64(lseek(_fd, 0, SEEK_CUR))
#endif
    }

    @discardableResult
    open func seekToEndOfFile() -> UInt64 {
        _checkFileHandle()
#if os(Windows)
        var liPointer: LARGE_INTEGER = LARGE_INTEGER(QuadPart: 0)
        if SetFilePointerEx(_handle, LARGE_INTEGER(QuadPart: 0),
                            &liPointer, DWORD(FILE_END)) == FALSE {
          fatalError("SetFilePointerEx failed")
        }
        return UInt64(liPointer.QuadPart)
#else
        return UInt64(lseek(_fd, 0, SEEK_END))
#endif
    }

    open func seek(toFileOffset offset: UInt64) {
        _checkFileHandle()
#if os(Windows)
        if SetFilePointerEx(_handle, LARGE_INTEGER(QuadPart: LONGLONG(offset)),
                            nil, DWORD(FILE_BEGIN)) == FALSE {
          fatalError("SetFilePointerEx failed")
        }
#else
        lseek(_fd, off_t(offset), SEEK_SET)
#endif
    }

    open func truncateFile(atOffset offset: UInt64) {
        _checkFileHandle()
#if os(Windows)
        if SetFilePointerEx(_handle, LARGE_INTEGER(QuadPart: LONGLONG(offset)),
                            nil, DWORD(FILE_BEGIN)) == FALSE {
          fatalError("SetFilePointerEx failed")
        }
        if SetEndOfFile(_handle) == FALSE {
          fatalError("SetEndOfFile failed")
        }
#else
        if lseek(_fd, off_t(offset), SEEK_SET) < 0 { fatalError("lseek() failed.") }
        if ftruncate(_fd, off_t(offset)) < 0 { fatalError("ftruncate() failed.") }
#endif
    }

    open func synchronizeFile() {
        _checkFileHandle()
#if os(Windows)
        if FlushFileBuffers(_handle) == FALSE {
          fatalError("FlushFileBuffers failed: \(GetLastError())")
        }
#else
        fsync(_fd)
#endif
    }

    open func closeFile() {
#if os(Windows)
        if _handle != INVALID_HANDLE_VALUE {
          if CloseHandle(_handle) == FALSE {
            fatalError("CloseHandle failed")
          }
          _handle = INVALID_HANDLE_VALUE
        }
#else
        if _fd >= 0 {
            close(_fd)
            _fd = -1
        }
#endif
    }

#if os(Windows)
    public init(handle: HANDLE, closeOnDealloc closeopt: Bool) {
      _handle = handle
      _closeOnDealloc = closeopt
    }

    public init(fileDescriptor fd: Int32, closeOnDealloc closeopt: Bool) {
      if (closeopt) {
        var handle: HANDLE?
          if DuplicateHandle(GetCurrentProcess(),
                             HANDLE(bitPattern: _get_osfhandle(fd))!,
                             GetCurrentProcess(), &handle,
                             DWORD(DUPLICATE_SAME_ACCESS), FALSE, 0) == FALSE {
            fatalError("DuplicateHandle() failed")
          }
        _close(fd)
        _handle = handle!
        _closeOnDealloc = true
      } else {
        _handle = HANDLE(bitPattern: _get_osfhandle(fd))!
        _closeOnDealloc = false
      }
    }

    public convenience init(fileDescriptor fd: Int32) {
      self.init(handle: HANDLE(bitPattern: _get_osfhandle(fd))!,
                closeOnDealloc: false)
    }

    internal convenience init?(path: String, flags: Int32, createMode: Int) {
      self.init(fileDescriptor: _CFOpenFileWithMode(path, flags,
                                                    mode_t(createMode)),
                closeOnDealloc: true)
      if _handle == INVALID_HANDLE_VALUE { return nil }
    }
#else
    public init(fileDescriptor fd: Int32, closeOnDealloc closeopt: Bool) {
        _fd = fd
        _closeOnDealloc = closeopt
    }

    public convenience init(fileDescriptor fd: Int32) {
        self.init(fileDescriptor: fd, closeOnDealloc: false)
    }

    internal init?(path: String, flags: Int32, createMode: Int) {
        _fd = _CFOpenFileWithMode(path, flags, mode_t(createMode))
        _closeOnDealloc = true
        super.init()
        if _fd < 0 {
            return nil
        }
    }
#endif

    deinit {
      guard _closeOnDealloc == true else { return }
#if os(Windows)
        if _handle != INVALID_HANDLE_VALUE {
          if CloseHandle(_handle) == FALSE {
            fatalError("CloseHandle failed")
          }
          _handle = INVALID_HANDLE_VALUE
        }
#else
        if _fd >= 0 {
            close(_fd)
            _fd = -1
        }
#endif
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
    open func readInBackgroundAndNotify(forModes modes: [RunLoop.Mode]?) {
        NSUnimplemented()
    }

    open func readInBackgroundAndNotify() {
        NSUnimplemented()
    }

    open func readToEndOfFileInBackgroundAndNotify(forModes modes: [RunLoop.Mode]?) {
        NSUnimplemented()
    }

    open func readToEndOfFileInBackgroundAndNotify() {
        NSUnimplemented()
    }
    
    open func acceptConnectionInBackgroundAndNotify(forModes modes: [RunLoop.Mode]?) {
        NSUnimplemented()
    }

    open func acceptConnectionInBackgroundAndNotify() {
        NSUnimplemented()
    }
    
    open func waitForDataInBackgroundAndNotify(forModes modes: [RunLoop.Mode]?) {
        NSUnimplemented()
    }

    open func waitForDataInBackgroundAndNotify() {
        NSUnimplemented()
    }
}

open class Pipe: NSObject {
    public let fileHandleForReading: FileHandle
    public let fileHandleForWriting: FileHandle

    public override init() {
#if os(Windows)
        var hReadPipe: HANDLE?
        var hWritePipe: HANDLE?
        if CreatePipe(&hReadPipe, &hWritePipe, nil, 0) == FALSE {
          fatalError("CreatePipe failed")
        }
        self.fileHandleForReading = FileHandle(handle: hReadPipe!,
                                               closeOnDealloc: true)
        self.fileHandleForWriting = FileHandle(handle: hWritePipe!,
                                               closeOnDealloc: true)
#else
        /// the `pipe` system call creates two `fd` in a malloc'ed area
        var fds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        defer {
            fds.deallocate()
        }
        /// If the operating system prevents us from creating file handles, stop
        let ret = pipe(fds)
        switch (ret, errno) {
        case (0, _):
            self.fileHandleForReading = FileHandle(fileDescriptor: fds.pointee, closeOnDealloc: true)
            self.fileHandleForWriting = FileHandle(fileDescriptor: fds.successor().pointee, closeOnDealloc: true)

        case (-1, EMFILE), (-1, ENFILE):
            // Unfortunately this initializer does not throw and isnt failable so this is only
            // way of handling this situation.
            self.fileHandleForReading = FileHandle(fileDescriptor: -1, closeOnDealloc: false)
            self.fileHandleForWriting = FileHandle(fileDescriptor: -1, closeOnDealloc: false)

        default:
            fatalError("Error calling pipe(): \(errno)")
        }
#endif
        super.init()
    }
}
