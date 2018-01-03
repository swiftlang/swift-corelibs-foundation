// Foundation/URLSession/TransferState.swift - URLSession & libcurl
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
/// These are libcurl helpers for the URLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: URLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation



extension _NativeProtocol {
    /// State related to an ongoing transfer.
    ///
    /// This contains headers received so far, body data received so far, etc.
    ///
    /// There's a strict 1-to-1 relationship between an `EasyHandle` and a
    /// `TransferState`.
    ///
    /// - TODO: Might move the `EasyHandle` into this `struct` ?
    /// - SeeAlso: `URLSessionTask.EasyHandle`
    internal struct _TransferState {
        /// The URL that's being requested
        let url: URL
        /// Raw headers received.
        let parsedResponseHeader: _ParsedResponseHeader
        /// Once the headers is complete, this will contain the response
        var response: URLResponse?
        /// The body data to be sent in the request
        let requestBodySource: _BodySource?
        /// Body data received
        let bodyDataDrain: _DataDrain
        /// Describes what to do with received body data for this transfer:
    }
}

extension _NativeProtocol {
    enum _DataDrain {
        /// Concatenate in-memory
        case inMemory(NSMutableData?)
        /// Write to file
        case toFile(URL, FileHandle?)
        /// Do nothing. Might be forwarded to delegate
        case ignore
    }
}

extension _NativeProtocol._TransferState {
    /// Transfer state that can receive body data, but will not send body data.
    init(url: URL, bodyDataDrain: _NativeProtocol._DataDrain) {
        self.url = url
        self.parsedResponseHeader = _NativeProtocol._ParsedResponseHeader()
        self.response = nil
        self.requestBodySource = nil
        self.bodyDataDrain = bodyDataDrain
    }
    /// Transfer state that sends body data and can receive body data.
    init(url: URL, bodyDataDrain: _NativeProtocol._DataDrain, bodySource: _BodySource) {
        self.url = url
        self.parsedResponseHeader = _NativeProtocol._ParsedResponseHeader()
        self.response = nil
        self.requestBodySource = bodySource
        self.bodyDataDrain = bodyDataDrain
    }
}
// specific to HTTP protocol
extension _HTTPURLProtocol._TransferState {
    /// Appends a header line
    ///
    /// Will set the complete response once the header is complete, i.e. the
    /// return value's `isHeaderComplete` will then by `true`.
    ///
    /// - Throws: When a parsing error occurs
    func byAppending(headerLine data: Data) throws -> _NativeProtocol._TransferState {
        guard let h = parsedResponseHeader.byAppending(headerLine: data) else {
            throw _Error.parseSingleLineError
        }
        if case .complete(let lines) = h {
            // Header is complete
            let response = lines.createHTTPURLResponse(for: url)
            guard response != nil else {
                throw _Error.parseCompleteHeaderError
            }
            return _NativeProtocol._TransferState(url: url, parsedResponseHeader: _NativeProtocol._ParsedResponseHeader(), response: response, requestBodySource: requestBodySource, bodyDataDrain: bodyDataDrain)
        } else {
            return _NativeProtocol._TransferState(url: url, parsedResponseHeader: h, response: nil, requestBodySource: requestBodySource, bodyDataDrain: bodyDataDrain)
        }
    }
}

extension _NativeProtocol._TransferState {

    enum _Error: Error {
        case parseSingleLineError
        case parseCompleteHeaderError
    }

    var isHeaderComplete: Bool {
        return response != nil
    }
    /// Append body data
    ///
    /// - Important: This will mutate the existing `NSMutableData` that the
    ///     struct may already have in place -- copying the data is too
    ///     expensive. This behaviour
    func byAppending(bodyData buffer: Data) -> _NativeProtocol._TransferState {
        switch bodyDataDrain {
        case .inMemory(let bodyData):
            let data: NSMutableData = bodyData ?? NSMutableData()
            data.append(buffer)
            let drain = _NativeProtocol._DataDrain.inMemory(data)
            return _NativeProtocol._TransferState(url: url, parsedResponseHeader: parsedResponseHeader, response: response, requestBodySource: requestBodySource, bodyDataDrain: drain)
        case .toFile(_, let fileHandle):
             //TODO: Create / open the file for writing
             // Append to the file
             _ = fileHandle!.seekToEndOfFile()
             fileHandle!.write(buffer)
             return self
        case .ignore:
            return self
        }
    }
    /// Sets the given body source on the transfer state.
    ///
    /// This can be used to either set the initial body source, or to reset it
    /// e.g. when restarting a transfer.
    func bySetting(bodySource newSource: _BodySource) -> _NativeProtocol._TransferState {
        return _NativeProtocol._TransferState(url: url, parsedResponseHeader: parsedResponseHeader, response: response, requestBodySource: newSource, bodyDataDrain: bodyDataDrain)
    }
}
