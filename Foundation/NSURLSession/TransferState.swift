// Foundation/NSURLSession/TransferState.swift - NSURLSession & libcurl
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
/// The state of a single transfer.
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation
import Dispatch



extension NSURLSessionTask {
    /// State related to an ongoing transfer.
    ///
    /// This contains headers received so far, body data received so far, etc.
    ///
    /// There's a strict 1-to-1 relationship between an `EasyHandle` and a
    /// `TransferState`.
    ///
    /// - TODO: Might move the `EasyHandle` into this `struct` ?
    /// - SeeAlso: `NSURLSessionTask.EasyHandle`
    internal struct TransferState {
        /// The URL that's being requested
        let url: NSURL
        /// Raw headers received.
        let parsedResponseHeader: ParsedResponseHeader
        /// Once the headers is complete, this will contain the response
        let response: NSHTTPURLResponse?
        /// The body data to be sent in the request
        let requestBodySource: HTTPBodySource?
        /// Body data received
        let bodyDataDrain: DataDrain
        /// Describes what to do with received body data for this transfer:
        enum DataDrain {
            /// Concatenate in-memory
            case inMemory(NSMutableData?)
            /// Write to file
            case toFile(NSURL, NSFileHandle?)
            /// Do nothing. Might be forwarded to delegate
            case ignore
        }
    }
}



extension NSURLSessionTask.TransferState {
    /// Transfer state that can receive body data, but will not send body data.
    init(url: NSURL, bodyDataDrain: DataDrain) {
        self.url = url
        self.parsedResponseHeader = NSURLSessionTask.ParsedResponseHeader()
        self.response = nil
        self.requestBodySource = nil
        self.bodyDataDrain = bodyDataDrain
    }
    /// Transfer state that sends body data and can receive body data.
    init(url: NSURL, bodyDataDrain: DataDrain, bodySource: HTTPBodySource) {
        self.url = url
        self.parsedResponseHeader = NSURLSessionTask.ParsedResponseHeader()
        self.response = nil
        self.requestBodySource = bodySource
        self.bodyDataDrain = bodyDataDrain
    }
}

extension NSURLSessionTask.TransferState {
    enum Error: ErrorProtocol {
        case parseSingleLineError
        case parseCompleteHeaderError
    }
    /// Appends a header line
    ///
    /// Will set the complete response once the header is complete, i.e. the
    /// return value's `isHeaderComplete` will then by `true`.
    ///
    /// - Throws: When a parsing error occurs
    @warn_unused_result
    func byAppending(headerLine data: UnsafeBufferPointer<Int8>) throws -> NSURLSessionTask.TransferState {
        guard let h = parsedResponseHeader.byAppending(headerLine: data) else {
            throw Error.parseSingleLineError
        }
        if case .complete(let lines) = h {
            // Header is complete
            let response = lines.createHTTPURLResponse(for: url)
            guard response != nil else {
                throw Error.parseCompleteHeaderError
            }
            return NSURLSessionTask.TransferState(url: url, parsedResponseHeader: NSURLSessionTask.ParsedResponseHeader(), response: response, requestBodySource: requestBodySource, bodyDataDrain: bodyDataDrain)
        } else {
            return NSURLSessionTask.TransferState(url: url, parsedResponseHeader: h, response: nil, requestBodySource: requestBodySource, bodyDataDrain: bodyDataDrain)
        }
    }
    var isHeaderComplete: Bool {
        return response != nil
    }
    /// Append body data
    ///
    /// - Important: This will mutate the existing `NSMutableData` that the
    ///     struct may already have in place -- copying the data is too
    ///     expensive. This behaviour
    @warn_unused_result
    func byAppending(bodyData buffer: UnsafeBufferPointer<Int8>) -> NSURLSessionTask.TransferState {
        switch bodyDataDrain {
        case .inMemory(let bodyData):
            let data: NSMutableData = bodyData ?? NSMutableData()
            guard let bytes = buffer.baseAddress.map({ UnsafePointer<Void>($0) }) else { fatalError() }
            data.appendBytes(bytes, length: buffer.count)
            let drain = DataDrain.inMemory(data)
            return NSURLSessionTask.TransferState(url: url, parsedResponseHeader: parsedResponseHeader, response: response, requestBodySource: requestBodySource, bodyDataDrain: drain)
        case .toFile:
            //TODO: Create / open the file for writing
            // Append to the file
            NSUnimplemented()
        case .ignore:
            return self
        }
    }
    /// Sets the given body source on the transfer state.
    ///
    /// This can be used to either set the initial body source, or to reset it
    /// e.g. when restarting a transfer.
    @warn_unused_result
    func bySetting(bodySource newSource: HTTPBodySource) -> NSURLSessionTask.TransferState {
        return NSURLSessionTask.TransferState(url: url, parsedResponseHeader: parsedResponseHeader, response: response, requestBodySource: newSource, bodyDataDrain: bodyDataDrain)
    }
}


