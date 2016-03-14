// Foundation/NSURLSession/HTTPBodySource.swift - NSURLSession & libcurl
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation
import Dispatch



internal extension NSData {
    /// Turn `dispatch_data_t` into `NSData`
    convenience init(dispatchData: dispatch_data_t) {
        //TODO: Should do this through an NSData subclass to avoid copying
        var bytes: UnsafePointer<Void>? = nil
        var length = 0
        let map = dispatch_data_create_map(dispatchData, &bytes, &length)
        guard (0 == length) || (bytes != nil) else { fatalError() }
        self.init(bytes: bytes, length: length)
        let _ = dispatch_data_get_size(map) // Keep `map` valid
    }
}
/// Turn `NSData` into `dispatch_data_t`
internal func createDispatchData(_ data: NSData) -> dispatch_data_t {
    //TODO: Avoid copying data
    return dispatch_data_create(data.bytes, data.length, nil, nil)
    /*
     let c = data.copy() as! NSData
     let info = Unmanaged<NSData>.passRetained(c)
     let destructor = {
     info.release()
     }
     let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)!
     return dispatch_data_create(c.bytes, c.length, nil, destructor)
     */
}

/// Copy data from `dispatch_data_t` into memory pointed to by an `UnsafeMutableBufferPointer`.
internal func copyDispatchData<T>(_ data: dispatch_data_t, infoBuffer buffer: UnsafeMutableBufferPointer<T>) {
    precondition(dispatch_data_get_size(data) <= (buffer.count * sizeof(T)))
    let byteBuffer = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(buffer.baseAddress), count: buffer.count * sizeof(T))
    let _ = dispatch_data_apply(data) { (_, offset, fromBuffer, size) -> Bool in
        guard let target = byteBuffer.baseAddress.map({ $0.advanced(by: offset) }) else { fatalError() }
        memcpy(target, fromBuffer, size)
        return true
    }
}

/// Split `dispatch_data_t` into `(head, tail)` pair.
internal func split(dispatchData data: dispatch_data_t, atPosition position: Int) -> (dispatch_data_t,dispatch_data_t) {
    let length = dispatch_data_get_size(data)
    let head = dispatch_data_create_subrange(data, 0, position)
    let tail = dispatch_data_create_subrange(data, position, length - position)
    return (head, tail)
}

/// A (non-blocking) source for HTTP body data.
internal protocol HTTPBodySource: class {
    /// Get the next chunck of data.
    ///
    /// - Returns: `.data` until the source is exhausted, at which point it will
    /// return `.done`. Since this is non-blocking, it will return `.retryLater`
    /// if no data is available at this point, but will be available later.
    func getNextChunk(withLength length: Int) -> HTTPBodySourceDataChunk
}
internal enum HTTPBodySourceDataChunk {
    case data(dispatch_data_t)
    /// The source is depleted.
    case done
    /// Retry later to get more data.
    case retryLater
    case error
}

/// A HTTP body data source backed by `dispatch_data_t`.
internal final class HTTPBodyDataSource {
    private var data: dispatch_data_t
    init(data: dispatch_data_t) {
        self.data = data
    }
}
extension HTTPBodyDataSource : HTTPBodySource {
    enum Error : ErrorProtocol {
        case unableToRewindData
    }
    func getNextChunk(withLength length: Int) -> HTTPBodySourceDataChunk {
        let remaining = dispatch_data_get_size(data)
        if remaining == 0 {
            return .done
        } else if remaining <= length {
            let r = data
            data = dispatch_data_create(nil, 0, nil, nil)
            return .data(r)
        } else {
            let (chunk, remainder) = split(dispatchData: data, atPosition: length)
            data = remainder
            return .data(chunk)
        }
    }
}


/// A HTTP body data source backed by a file.
///
/// This allows non-blocking streaming of file data to the remote server.
///
/// The source reads data using a `dispatch_io_t` channel, and hence reading
/// file data is non-blocking. It has a local buffer that it fills as calls
/// to `getNextChunk(withLength:)` drain it.
///
/// - Note: Calls to `getNextChunk(withLength:)` and callbacks from libdispatch
/// should all happen on the same (serial) queue, and hence this code doesn't
/// have to be thread safe.
internal final class HTTPBodyFileSource {
    private let fileURL: NSURL
    private let channel: dispatch_io_t
    private let workQueue: dispatch_queue_t
    private let dataAvailableHandler: () -> ()
    private var hasActiveReadHandler = false
    private var availableChunk: Chunk = .empty
    /// Create a new data source backed by a file.
    ///
    /// - Parameter fileURL: the file to read from
    /// - Parameter workQueue: the queue that it's safe to call
    ///     `getNextChunk(withLength:)` on, and that the `dataAvailableHandler`
    ///     will be called on.
    /// - Parameter dataAvailableHandler: Will be called when data becomes
    ///     available. Reading data is done in a non-blocking way, such that
    ///     no data may be available even if there's more data in the file.
    ///     if `getNextChunk(withLength:)` returns `.retryLater`, this handler
    ///     will be called once data becomes available.
    init(fileURL: NSURL, workQueue: dispatch_queue_t, dataAvailableHandler: () -> ()) {
        guard fileURL.fileURL else { fatalError("The body data URL must be a file URL.") }
        self.fileURL = fileURL
        self.workQueue = workQueue
        self.dataAvailableHandler = dataAvailableHandler
        self.channel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, fileURL.fileSystemRepresentation, O_RDONLY, 0, workQueue, nil)
        dispatch_io_set_high_water(self.channel, CFURLSessionMaxWriteSize)
    }
    private enum Chunk {
        /// Nothing has been read, yet
        case empty
        /// An error has occured while reading
        case errorDetected(CInt)
        /// Data has been read
        case data(dispatch_data_t)
        /// All data has been read from the file (EOF).
        case done(dispatch_data_t?)
    }
}

private extension HTTPBodyFileSource {
    private var desiredBufferLength: Int { return 3 * CFURLSessionMaxWriteSize }
    /// Enqueue a dispatch I/O read to fill the buffer.
    ///
    /// - Note: This is a no-op if the buffer is full, or if a read operation
    /// is already enqueued.
    private func readNextChunk() {
        // libcurl likes to use a buffer of size CFURLSessionMaxWriteSize, we'll
        // try to keep 3 x of that around in the `chunk` buffer.
        guard availableByteCount < desiredBufferLength else { return }
        guard !hasActiveReadHandler else { return } // We're already reading
        hasActiveReadHandler = true
        
        let lengthToRead = desiredBufferLength - availableByteCount
        dispatch_io_read(channel, 0, lengthToRead, workQueue) { (done: Bool, data: dispatch_data_t?, errno: CInt) in
            let wasEmpty = self.availableByteCount == 0
            self.hasActiveReadHandler = !done
            
            switch (done, data, errno) {
            case (true, _, errno) where errno != 0:
                self.availableChunk = .errorDetected(errno)
            case (true, .some(let d), 0) where dispatch_data_get_size(d) == 0:
                self.append(data: d, endOfFile: true)
            case (true, .some(let d), 0):
                self.append(data: d, endOfFile: false)
            case (false, .some(let d), 0):
                self.append(data: d, endOfFile: false)
            default:
                fatalError("Invalid arguments to dispatch_io_read(3) callback.")
            }
            
            if wasEmpty && (0 < self.availableByteCount) {
                self.dataAvailableHandler()
            }
        }
    }
    private func append(data: dispatch_data_t, endOfFile: Bool) {
        switch availableChunk {
        case .empty:
            availableChunk = endOfFile ? .done(data) : .data(data)
        case .errorDetected:
            break
        case .data(let oldData):
            let c = dispatch_data_create_concat(oldData, data)
            availableChunk = endOfFile ? .done(c) : .data(c)
        case .done:
            fatalError("Trying to append data, but end-of-file was already detected.")
        }
    }
    private var availableByteCount: Int {
        switch availableChunk {
        case .empty: return 0
        case .errorDetected: return 0
        case .data(let d): return dispatch_data_get_size(d)
        case .done(.some(let d)): return dispatch_data_get_size(d)
        case .done(.none): return 0
        }
    }
}

extension HTTPBodyFileSource : HTTPBodySource {
    func getNextChunk(withLength length: Int) -> HTTPBodySourceDataChunk {
        switch availableChunk {
        case .empty:
            readNextChunk()
            return .retryLater
        case .errorDetected:
            return .error
        case .data(let data):
            let l = min(length, dispatch_data_get_size(data))
            let (head, tail) = split(dispatchData: data, atPosition: l)
            
            availableChunk = (dispatch_data_get_size(tail) == 0) ? .empty : .data(tail)
            readNextChunk()
            
            if dispatch_data_get_size(head) == 0 {
                return .retryLater
            } else {
                return .data(head)
            }
        case .done(.some(let data)):
            let l = min(length, dispatch_data_get_size(data))
            let (head, tail) = split(dispatchData: data, atPosition: l)
            availableChunk = (dispatch_data_get_size(tail) == 0) ? .done(nil) : .done(tail)
            if (dispatch_data_get_size(head) == 0) {
                return .done
            } else {
                return .data(head)
            }
        case .done(.none):
            return .done
        }
    }
}
