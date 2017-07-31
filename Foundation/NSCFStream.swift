// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFStreamEventNone: CFOptionFlags = 0
internal let kCFStreamEventOpenCompleted = CFStreamEventType.openCompleted.rawValue
internal let kCFStreamEventHasBytesAvailable = CFStreamEventType.hasBytesAvailable.rawValue
internal let kCFStreamEventCanAcceptBytes = CFStreamEventType.canAcceptBytes.rawValue
internal let kCFStreamEventErrorOccurred = CFStreamEventType.errorOccurred.rawValue
internal let kCFStreamEventEndEncountered = CFStreamEventType.endEncountered.rawValue
internal let kCFStreamErrorDomainCustom = CFStreamErrorDomain.custom.rawValue
#else
extension CFStreamStatus {
    var rawValue: Int { return self }
    init?(rawValue: Int) {
        self = rawValue
    }
}
extension CFStreamEventType {
    var rawValue: CFOptionFlags { return self }
    init(rawValue: CFOptionFlags) {
        self = rawValue
    }
}
#endif

fileprivate struct _StreamDelegateBox {
    weak var object: StreamDelegate?
}

fileprivate let _streamDelegatesLock = NSLock()
fileprivate var _streamDelegates = [UnsafeMutableRawPointer : _StreamDelegateBox]()

fileprivate func _inputStreamCallbackFunc(_ stream: CFReadStream?, _ type: CFStreamEventType, _ clientCallBackInfo: UnsafeMutableRawPointer?) {
    guard let s = stream,
          let client = clientCallBackInfo else {
        return
    }
    let delegate = _streamDelegatesLock.synchronized { _streamDelegates[client]?.object }
    delegate?.stream(unsafeBitCast(s, to: InputStream.self), handleEvent: Stream.Event.init(rawValue: type.rawValue))
}

fileprivate func _outputStreamCallbackFunc(_ stream: CFWriteStream?, _ type: CFStreamEventType, _ clientCallBackInfo: UnsafeMutableRawPointer?) {
    guard let s = stream,
        let client = clientCallBackInfo else {
            return
    }
    let delegate = _streamDelegatesLock.synchronized { _streamDelegates[client]?.object }
    delegate?.stream(unsafeBitCast(s, to: InputStream.self), handleEvent: Stream.Event.init(rawValue: type.rawValue))
}

internal final class _NSCFInputStream : InputStream {
    deinit {
        if let obj = _CFReadStreamGetClient(unsafeBitCast(self, to: CFReadStream.self)) {
            _streamDelegates[obj] = nil
        }
    }
    
    
    override func open() {
        CFReadStreamOpen(unsafeBitCast(self, to: CFReadStream.self))
    }
    
    override func close() {
        CFReadStreamClose(unsafeBitCast(self, to: CFReadStream.self))
    }
    
    override var delegate: StreamDelegate? {
        get {
            guard let obj = _CFReadStreamGetClient(unsafeBitCast(self, to: CFReadStream.self)) else {
                return nil
            }
            return _streamDelegatesLock.synchronized { _streamDelegates[obj]?.object }
        }
        set {
            if let obj = _CFReadStreamGetClient(unsafeBitCast(self, to: CFReadStream.self)) {
                _streamDelegatesLock.synchronized {
                    _streamDelegates[obj] = nil
                }
            }
            var ctx = CFStreamClientContext()
            ctx.version = 0
            ctx.retain = nil
            ctx.release = nil
            ctx.copyDescription = nil
            if let delegate = newValue {
                let ptr = Unmanaged<AnyObject>.passUnretained(delegate).toOpaque()
                ctx.info = ptr
                _streamDelegatesLock.synchronized {
                    _streamDelegates[ptr] = _StreamDelegateBox(object: delegate)
                }
            } else {
                ctx.info = nil
            }
            
            CFReadStreamSetClient(unsafeBitCast(self, to: CFReadStream.self), CFOptionFlags(bitPattern: kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered), _inputStreamCallbackFunc, &ctx)
        }
    }
    
    override func property(forKey key: Stream.PropertyKey) -> Any? {
        return _SwiftValue.fetch(CFReadStreamCopyProperty(unsafeBitCast(self, to: CFReadStream.self), unsafeBitCast(NSString(string: key.rawValue), to: CFStreamPropertyKey.self)))
    }
    
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        return CFReadStreamSetProperty(unsafeBitCast(self, to: CFReadStream.self), unsafeBitCast(NSString(string: key.rawValue), to: CFStreamPropertyKey.self), _SwiftValue.store(property))
    }
    
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamScheduleWithRunLoop(unsafeBitCast(self, to: CFReadStream.self), aRunLoop.getCFRunLoop(), unsafeBitCast(NSString(string: mode.rawValue), to: CFRunLoopMode.self))
    }
    
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamUnscheduleFromRunLoop(unsafeBitCast(self, to: CFReadStream.self), aRunLoop.getCFRunLoop(), unsafeBitCast(NSString(string: mode.rawValue), to: CFRunLoopMode.self))
    }
    
    override var streamStatus: Stream.Status {
        return Stream.Status(rawValue: UInt(bitPattern: CFReadStreamGetStatus(unsafeBitCast(self, to: CFReadStream.self)).rawValue))!
    }
    
    override var streamError: Error? {
        guard let err = CFReadStreamCopyError(unsafeBitCast(self, to: CFReadStream.self)) else { return nil }
        return err._nsObject
    }
    
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(unsafeBitCast(self, to: CFReadStream.self), buffer, len)
    }
    
    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        let incomingBuffer = CFReadStreamGetBuffer(unsafeBitCast(self, to: CFReadStream.self), 0, len)
        guard len.pointee > 0 else {
            return false
        }
        
        if let incoming = incomingBuffer {
            buffer.pointee = UnsafeMutablePointer(mutating: incoming)
        } else {
            buffer.pointee = nil
        }
        
        return true
    }
    
    override var hasBytesAvailable: Bool {
        return CFReadStreamHasBytesAvailable(unsafeBitCast(self, to: CFReadStream.self))
    }
}

internal final class _NSCFOutputStream : OutputStream {
    override func open() {
        CFWriteStreamOpen(unsafeBitCast(self, to: CFWriteStream.self))
    }
    
    override func close() {
        CFWriteStreamClose(unsafeBitCast(self, to: CFWriteStream.self))
    }
    
    override var delegate: StreamDelegate? {
        get {
            guard let obj = _CFWriteStreamGetClient(unsafeBitCast(self, to: CFWriteStream.self)) else {
                return nil
            }
            return _streamDelegatesLock.synchronized { _streamDelegates[obj]?.object }
        }
        set {
            if let obj = _CFWriteStreamGetClient(unsafeBitCast(self, to: CFWriteStream.self)) {
                _streamDelegatesLock.synchronized {
                    _streamDelegates[obj] = nil
                }
            }
            var ctx = CFStreamClientContext()
            ctx.version = 0
            ctx.retain = nil
            ctx.release = nil
            ctx.copyDescription = nil
            if let delegate = newValue {
                let ptr = Unmanaged<AnyObject>.passUnretained(delegate).toOpaque()
                ctx.info = ptr
                _streamDelegatesLock.synchronized {
                    _streamDelegates[ptr] = _StreamDelegateBox(object: delegate)
                }
            } else {
                ctx.info = nil
            }
            
            CFWriteStreamSetClient(unsafeBitCast(self, to: CFWriteStream.self), CFOptionFlags(bitPattern: kCFStreamEventOpenCompleted | kCFStreamEventCanAcceptBytes | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered), _outputStreamCallbackFunc, &ctx)
        }
    }
    
    
    override func property(forKey key: Stream.PropertyKey) -> Any? {
        return _SwiftValue.fetch(CFWriteStreamCopyProperty(unsafeBitCast(self, to: CFWriteStream.self), unsafeBitCast(NSString(string: key.rawValue), to: CFStreamPropertyKey.self)))
    }
    
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        return CFWriteStreamSetProperty(unsafeBitCast(self, to: CFWriteStream.self), unsafeBitCast(NSString(string: key.rawValue), to: CFStreamPropertyKey.self), _SwiftValue.store(property))
    }
    
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamScheduleWithRunLoop(unsafeBitCast(self, to: CFWriteStream.self), aRunLoop.getCFRunLoop(), unsafeBitCast(NSString(string: mode.rawValue), to: CFRunLoopMode.self))
    }
    
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamUnscheduleFromRunLoop(unsafeBitCast(self, to: CFWriteStream.self), aRunLoop.getCFRunLoop(), unsafeBitCast(NSString(string: mode.rawValue), to: CFRunLoopMode.self))
    }
    
    override var streamStatus: Stream.Status {
        return Stream.Status(rawValue: UInt(bitPattern: CFWriteStreamGetStatus(unsafeBitCast(self, to: CFWriteStream.self)).rawValue))!
    }
    
    override var streamError: Error? {
        guard let err = CFWriteStreamCopyError(unsafeBitCast(self, to: CFWriteStream.self)) else { return nil }
        return err._nsObject
    }
    
    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return CFWriteStreamWrite(unsafeBitCast(self, to: CFWriteStream.self), buffer, len)
    }
    
    override var hasSpaceAvailable: Bool {
        return CFWriteStreamCanAcceptBytes(unsafeBitCast(self, to: CFWriteStream.self))
    }
}

/// Mark -

internal func _CFSwiftInputStreamGetStreamStatus(_ stream: CFTypeRef) -> CFStreamStatus {
    return CFStreamStatus(rawValue: CFIndex(bitPattern: unsafeBitCast(stream, to: InputStream.self).streamStatus.rawValue))!
}

internal func _CFSwiftInputStreamGetCFStreamError(_ stream: CFTypeRef) -> CFStreamError {
    return unsafeBitCast(stream, to: InputStream.self)._cfStreamError
}

internal func _CFSwiftInputStreamGetStreamError(_ stream: CFTypeRef) -> Unmanaged<CFError>? {
    guard let err = unsafeBitCast(stream, to: InputStream.self).streamError else { return nil }
    return Unmanaged.passUnretained((err as! NSError)._cfObject)
}

internal func _CFSwiftInputStreamOpen(_ stream: CFTypeRef) {
    unsafeBitCast(stream, to: InputStream.self).open()
}

internal func _CFSwiftInputStreamClose(_ stream: CFTypeRef) {
    unsafeBitCast(stream, to: InputStream.self).close()
}

internal func _CFSwiftInputStreamHasBytesAvailable(_ stream: CFTypeRef) -> Bool {
    return unsafeBitCast(stream, to: InputStream.self).hasBytesAvailable
}

internal func _CFSwiftInputStreamRead(_ stream: CFTypeRef, _ buffer: UnsafeMutablePointer<UInt8>, _ length: CFIndex) -> CFIndex {
    return unsafeBitCast(stream, to: InputStream.self).read(buffer, maxLength: length)
}

internal func _CFSwiftInputStreamGetBuffer(_ stream: CFTypeRef, _ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, _ length: UnsafeMutablePointer<CFIndex>) -> Bool {
    return unsafeBitCast(stream, to: InputStream.self).getBuffer(buffer, length: length)
}

internal func _CFSwiftInputStreamCopyPropertyForKey(_ stream: CFTypeRef, _ key: CFString) -> Unmanaged<CFTypeRef>? {
    guard let result = _SwiftValue.store(unsafeBitCast(stream, to: InputStream.self).property(forKey: Stream.PropertyKey(rawValue: key._swiftObject))) else { return nil }
    return Unmanaged.passRetained(unsafeBitCast(result, to: CFTypeRef.self))
}

internal func _CFSwiftInputStreamSetPropertyForKey(_ stream: CFTypeRef, _ value: CFTypeRef?, _ key: CFString) -> Bool {
    return unsafeBitCast(stream, to: InputStream.self).setProperty(_SwiftValue.fetch(value), forKey: Stream.PropertyKey(rawValue: key._swiftObject))
}

internal func _CFSwiftInputStreamScheduleWithRunLoop(_ stream: CFTypeRef, _ rl: CFRunLoop, _ mode: CFString) {
    unsafeBitCast(stream, to: InputStream.self).schedule(in: _CFRunLoopGet2(rl) as! RunLoop, forMode: RunLoopMode(rawValue: mode._swiftObject))
}

internal func _CFSwiftInputStreamUnscheduleWithRunLoop(_ stream: CFTypeRef, _ rl: CFRunLoop, _ mode: CFString) {
    unsafeBitCast(stream, to: InputStream.self).remove(from: _CFRunLoopGet2(rl) as! RunLoop, forMode: RunLoopMode(rawValue: mode._swiftObject))
}

/// Mark -

internal func _CFSwiftOutputStreamGetStreamStatus(_ stream: CFTypeRef) -> CFStreamStatus {
    return CFStreamStatus(rawValue: CFIndex(bitPattern: unsafeBitCast(stream, to: OutputStream.self).streamStatus.rawValue))!
}

internal func _CFSwiftOutputStreamGetCFStreamError(_ stream: CFTypeRef) -> CFStreamError {
    return unsafeBitCast(stream, to: OutputStream.self)._cfStreamError
}

internal func _CFSwiftOutputStreamGetStreamError(_ stream: CFTypeRef) -> Unmanaged<CFError>? {
    guard let err = unsafeBitCast(stream, to: OutputStream.self).streamError else { return nil }
    return Unmanaged.passUnretained((err as! NSError)._cfObject)
}

internal func _CFSwiftOutputStreamOpen(_ stream: CFTypeRef) {
    unsafeBitCast(stream, to: OutputStream.self).open()
}

internal func _CFSwiftOutputStreamClose(_ stream: CFTypeRef) {
    unsafeBitCast(stream, to: OutputStream.self).close()
}

internal func _CFSwiftOutputStreamHasSpaceAvailable(_ stream: CFTypeRef) -> Bool {
    return unsafeBitCast(stream, to: OutputStream.self).hasSpaceAvailable
}

internal func _CFSwiftOutputStreamWrite(_ stream: CFTypeRef, _ buffer: UnsafePointer<UInt8>, _ length: CFIndex) -> CFIndex {
    return unsafeBitCast(stream, to: OutputStream.self).write(buffer, maxLength: length)
}

internal func _CFSwiftOutputStreamCopyPropertyForKey(_ stream: CFTypeRef, _ key: CFString) -> Unmanaged<CFTypeRef>? {
    guard let result = _SwiftValue.store(unsafeBitCast(stream, to: OutputStream.self).property(forKey: Stream.PropertyKey(rawValue: key._swiftObject))) else { return nil }
    return Unmanaged.passRetained(unsafeBitCast(result, to: CFTypeRef.self))
}

internal func _CFSwiftOutputStreamSetPropertyForKey(_ stream: CFTypeRef, _ value: CFTypeRef?, _ key: CFString) -> Bool {
    return unsafeBitCast(stream, to: OutputStream.self).setProperty(_SwiftValue.fetch(value), forKey: Stream.PropertyKey(rawValue: key._swiftObject))
}

internal func _CFSwiftOutputStreamScheduleWithRunLoop(_ stream: CFTypeRef, _ rl: CFRunLoop, _ mode: CFString) {
    unsafeBitCast(stream, to: OutputStream.self).schedule(in: _CFRunLoopGet2(rl) as! RunLoop, forMode: RunLoopMode(rawValue: mode._swiftObject))
}

internal func _CFSwiftOutputStreamUnscheduleWithRunLoop(_ stream: CFTypeRef, _ rl: CFRunLoop, _ mode: CFString) {
    unsafeBitCast(stream, to: OutputStream.self).remove(from: _CFRunLoopGet2(rl) as! RunLoop, forMode: RunLoopMode(rawValue: mode._swiftObject))
}
