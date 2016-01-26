// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public struct NSDataReadingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let DataReadingMappedIfSafe = NSDataReadingOptions(rawValue: UInt(1 << 0))
    public static let DataReadingUncached = NSDataReadingOptions(rawValue: UInt(1 << 1))
    public static let DataReadingMappedAlways = NSDataReadingOptions(rawValue: UInt(1 << 2))
}

public struct NSDataWritingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let DataWritingAtomic = NSDataWritingOptions(rawValue: UInt(1 << 0))
    public static let DataWritingWithoutOverwriting = NSDataWritingOptions(rawValue: UInt(1 << 1))
}

public struct NSDataSearchOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let Backwards = NSDataSearchOptions(rawValue: UInt(1 << 0))
    public static let Anchored = NSDataSearchOptions(rawValue: UInt(1 << 1))
}

public struct NSDataBase64EncodingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let Encoding64CharacterLineLength = NSDataBase64EncodingOptions(rawValue: UInt(1 << 0))
    public static let Encoding76CharacterLineLength = NSDataBase64EncodingOptions(rawValue: UInt(1 << 1))
    public static let EncodingEndLineWithCarriageReturn = NSDataBase64EncodingOptions(rawValue: UInt(1 << 4))
    public static let EncodingEndLineWithLineFeed = NSDataBase64EncodingOptions(rawValue: UInt(1 << 5))
}

public struct NSDataBase64DecodingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let IgnoreUnknownCharacters = NSDataBase64DecodingOptions(rawValue: UInt(1 << 0))
    public static let Anchored = NSDataSearchOptions(rawValue: UInt(1 << 1))
}

private final class _NSDataDeallocator {
    var handler: (UnsafeMutablePointer<Void>, Int) -> Void = {_,_ in }
}

private let __kCFMutable: CFOptionFlags = 0x01
private let __kCFGrowable: CFOptionFlags = 0x02
private let __kCFMutableVarietyMask: CFOptionFlags = 0x03
private let __kCFBytesInline: CFOptionFlags = 0x04
private let __kCFUseAllocator: CFOptionFlags = 0x08
private let __kCFDontDeallocate: CFOptionFlags = 0x10
private let __kCFAllocatesCollectable: CFOptionFlags = 0x20

public class NSData : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    typealias CFType = CFDataRef
    private var _base = _CFInfo(typeID: CFDataGetTypeID())
    private var _length: CFIndex = 0
    private var _capacity: CFIndex = 0
    private var _deallocator: UnsafeMutablePointer<Void> = nil // for CF only
    private var _deallocHandler: _NSDataDeallocator? = _NSDataDeallocator() // for Swift
    private var _bytes: UnsafeMutablePointer<UInt8> = nil
    
    internal var _cfObject: CFType {
        if self.dynamicType === NSData.self || self.dynamicType === NSMutableData.self {
            return unsafeBitCast(self, CFType.self)
        } else {
            return CFDataCreate(kCFAllocatorSystemDefault, unsafeBitCast(self.bytes, UnsafePointer<UInt8>.self), self.length)
        }
    }
    
    public override required convenience init() {
        self.init(bytes: nil, length: 0, copy: false, deallocator: nil)
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let data = object as? NSData {
            return self.isEqualToData(data)
        } else {
            return false
        }
    }
    
    deinit {
        if _bytes != nil {
            _deallocHandler?.handler(_bytes, _length)
        }
        if self.dynamicType === NSData.self || self.dynamicType === NSMutableData.self {
            _CFDeinit(self._cfObject)
        }
    }
    
    internal init(bytes: UnsafeMutablePointer<Void>, length: Int, copy: Bool, deallocator: ((UnsafeMutablePointer<Void>, Int) -> Void)?) {
        super.init()
        let options : CFOptionFlags = (self.dynamicType == NSMutableData.self) ? __kCFMutable | __kCFGrowable : 0x0
        if copy {
            _CFDataInit(unsafeBitCast(self, CFMutableDataRef.self), options, length, UnsafeMutablePointer<UInt8>(bytes), length, false)
            if let handler = deallocator {
                handler(bytes, length)
            }
        } else {
            if let handler = deallocator {
                _deallocHandler!.handler = handler
            }
            // The data initialization should flag that CF should not deallocate which leaves the handler a chance to deallocate instead
            _CFDataInit(unsafeBitCast(self, CFMutableDataRef.self), options | __kCFDontDeallocate, length, UnsafeMutablePointer<UInt8>(bytes), length, true)
        }
    }
    
    public var length: Int {
        return CFDataGetLength(_cfObject)
    }

    public var bytes: UnsafePointer<Void> {
        return UnsafePointer<Void>(CFDataGetBytePtr(_cfObject))
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        return NSMutableData(bytes: UnsafeMutablePointer<Void>(bytes), length: length, copy: true, deallocator: nil)
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        if let aKeyedCoder = aCoder as? NSKeyedArchiver {
            aKeyedCoder._encodePropertyList(self, forKey: "NS.data")
        } else {
            aCoder.encodeBytes(UnsafePointer<UInt8>(self.bytes), length: self.length)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            if let data = aDecoder.decodeDataObject() {
                self.init(data: data)
            } else {
                return nil
            }
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.data") {
            guard let data = aDecoder._decodePropertyListForKey("NS.data") as? NSData else {
                return nil
            }
            self.init(data: data)
        } else {
            var len = 0
            let bytes = aDecoder.decodeBytesForKey("NS.bytes", returnedLength: &len)
            self.init(bytes: bytes, length: len)
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    private func byteDescription(limit limit: Int? = nil) -> String {
        var s = ""
        let buffer = UnsafePointer<UInt8>(bytes)
        var i = 0
        while i < self.length {
            if i > 0 && i % 4 == 0 {
                // if there's a limit, and we're at the barrier where we'd add the ellipses, don't add a space.
                if let limit = limit where self.length > limit && i == self.length - (limit / 2) { /* do nothing */ }
                else { s += " " }
            }
            let byte = buffer[i]
            var byteStr = String(byte, radix: 16, uppercase: false)
            if byte <= 0xf { byteStr = "0\(byteStr)" }
            s += byteStr
            // if we've hit the midpoint of the limit, skip to the last (limit / 2) bytes.
            if let limit = limit where self.length > limit && i == (limit / 2) - 1 {
                s += " ... "
                i = self.length - (limit / 2)
            } else {
                i += 1
            }
        }
        return s
    }
    
    override public var debugDescription: String {
        return "<\(byteDescription(limit: 1024))>"
    }
    
    override public var description: String {
        return "<\(byteDescription())>"
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFDataGetTypeID()
    }
}

extension NSData {
    
    public convenience init(bytes: UnsafePointer<Void>, length: Int) {
        self.init(bytes: UnsafeMutablePointer<Void>(bytes), length: length, copy: true, deallocator: nil)
    }

    public convenience init(bytesNoCopy bytes: UnsafeMutablePointer<Void>, length: Int) {
        self.init(bytes: bytes, length: length, copy: false, deallocator: nil)
    }
    
    public convenience init(bytesNoCopy bytes: UnsafeMutablePointer<Void>, length: Int, freeWhenDone b: Bool) {
        self.init(bytes: bytes, length: length, copy: false) { buffer, length in
            if b {
                free(buffer)
            }
        }
    }

    public convenience init(bytesNoCopy bytes: UnsafeMutablePointer<Void>, length: Int, deallocator: ((UnsafeMutablePointer<Void>, Int) -> Void)?) {
        self.init(bytes: bytes, length: length, copy: false, deallocator: deallocator)
    }
    
    
    internal struct NSDataReadResult {
        var bytes: UnsafeMutablePointer<Void>
        var length: Int
        var deallocator: ((buffer: UnsafeMutablePointer<Void>, length: Int) -> Void)?
    }
    
    internal static func readBytesFromFileWithExtendedAttributes(path: String, options: NSDataReadingOptions) throws -> NSDataReadResult {
        let fd = _CFOpenFile(path, O_RDONLY)
        if fd < 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        defer {
            close(fd)
        }

        var info = stat()
        let ret = withUnsafeMutablePointer(&info) { infoPointer -> Bool in
            if fstat(fd, infoPointer) < 0 {
                return false
            }
            return true
        }
        
        if !ret {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        let length = Int(info.st_size)
        
        if options.contains(.DataReadingMappedAlways) {
            let data = mmap(nil, length, PROT_READ, MAP_PRIVATE, fd, 0)
            
            // Swift does not currently expose MAP_FAILURE
            if data != UnsafeMutablePointer<Void>(bitPattern: -1) {
                return NSDataReadResult(bytes: data, length: length) { buffer, length in
                    munmap(buffer, length)
                }
            }
            
        }
        
        let data = malloc(length)
        var remaining = Int(info.st_size)
        var total = 0
        while remaining > 0 {
            let amt = read(fd, data.advancedBy(total), remaining)
            if amt < 0 {
                break
            }
            remaining -= amt
            total += amt
        }

        if remaining != 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        return NSDataReadResult(bytes: data, length: length) { buffer, length in
            free(buffer)
        }
    }
    
    public convenience init(contentsOfFile path: String, options readOptionsMask: NSDataReadingOptions) throws {
        let readResult = try NSData.readBytesFromFileWithExtendedAttributes(path, options: readOptionsMask)
        self.init(bytes: readResult.bytes, length: readResult.length, copy: false, deallocator: readResult.deallocator)
    }

    public convenience init?(contentsOfFile path: String) {
        do {
            let readResult = try NSData.readBytesFromFileWithExtendedAttributes(path, options: [])
            self.init(bytes: readResult.bytes, length: readResult.length, copy: false, deallocator: readResult.deallocator)
        } catch {
            return nil
        }
    }

    public convenience init(data: NSData) {
        self.init(bytes:data.bytes, length: data.length)
    }
    
    public convenience init(contentsOfURL url: NSURL, options readOptionsMask: NSDataReadingOptions) throws {
        if url.fileURL {
            try self.init(contentsOfFile: url.path!, options: readOptionsMask)
        } else {
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let cond = NSCondition()
            var resError: NSError?
            var resData: NSData?
            let task = session.dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                resData = data
                resError = error
                cond.broadcast()
            })
            task.resume()
            cond.wait()
            if resData == nil {
                throw resError!
            }
            self.init(data: resData!)
        }
    }
    
    public convenience init?(contentsOfURL url: NSURL) {
        do {
            try self.init(contentsOfURL: url, options: [])
        } catch {
            return nil
        }
    }
}

extension NSData {
    public func getBytes(buffer: UnsafeMutablePointer<Void>, length: Int) {
        CFDataGetBytes(_cfObject, CFRangeMake(0, length), UnsafeMutablePointer<UInt8>(buffer))
    }
    
    public func getBytes(buffer: UnsafeMutablePointer<Void>, range: NSRange) {
        CFDataGetBytes(_cfObject, CFRangeMake(range.location, range.length), UnsafeMutablePointer<UInt8>(buffer))
    }
    
    public func isEqualToData(other: NSData) -> Bool {
        if self === other {
            return true
        }
        
        if length != other.length {
            return false
        }
        
        let bytes1 = bytes
        let bytes2 = other.bytes
        if bytes1 == bytes2 {
            return true
        }
        
        return memcmp(bytes1, bytes2, length) == 0
    }
    public func subdataWithRange(range: NSRange) -> NSData {
        if range.length == 0 {
            return NSData()
        }
        if range.location == 0 && range.length == self.length {
            return copyWithZone(nil) as! NSData
        }
        return NSData(bytes: bytes.advancedBy(range.location), length: range.length)
    }
    
    internal func makeTemporaryFileInDirectory(dirPath: String) throws -> (Int32, String) {
        let template = dirPath._nsObject.stringByAppendingPathComponent("tmp.XXXXXX")
        let maxLength = Int(PATH_MAX) + 1
        var buf = [Int8](count: maxLength, repeatedValue: 0)
        template._nsObject.getFileSystemRepresentation(&buf, maxLength: maxLength)
        let fd = mkstemp(&buf)
        if fd == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: dirPath)
        }
        let pathResult = NSFileManager.defaultManager().stringWithFileSystemRepresentation(buf, length: Int(strlen(buf)))
        return (fd, pathResult)
    }
    
    internal class func writeToFileDescriptor(fd: Int32, path: String? = nil, buf: UnsafePointer<Void>, length: Int) throws {
        var bytesRemaining = length
        while bytesRemaining > 0 {
            var bytesWritten : Int
            repeat {
                bytesWritten = write(fd, buf.advancedBy(length - bytesRemaining), bytesRemaining)
            } while (bytesWritten < 0 && errno == EINTR)
            if bytesWritten <= 0 {
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            } else {
                bytesRemaining -= bytesWritten
            }
        }
    }
    
    public func writeToFile(path: String, options writeOptionsMask: NSDataWritingOptions) throws {
        var fd : Int32
        var mode : mode_t? = nil
        let useAuxiliaryFile = writeOptionsMask.contains(.DataWritingAtomic)
        var auxFilePath : String? = nil
        if useAuxiliaryFile {
            // Preserve permissions.
            var info = stat()
            if lstat(path, &info) == 0 {
                mode = info.st_mode
            } else if errno != ENOENT && errno != ENAMETOOLONG {
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            }
            let (newFD, path) = try self.makeTemporaryFileInDirectory(path._nsObject.stringByDeletingLastPathComponent)
            fd = newFD
            auxFilePath = path
            fchmod(fd, 0o666)
        } else {
            var flags = O_WRONLY | O_CREAT | O_TRUNC
            if writeOptionsMask.contains(.DataWritingWithoutOverwriting) {
                flags |= O_EXCL
            }
            fd = _CFOpenFileWithMode(path, flags, 0o666)
        }
        if fd == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
        defer {
            close(fd)
        }

        try self.enumerateByteRangesUsingBlockRethrows { (buf, range, stop) in
            if range.length > 0 {
                do {
                    try NSData.writeToFileDescriptor(fd, path: path, buf: buf, length: range.length)
                    if fsync(fd) < 0 {
                        throw _NSErrorWithErrno(errno, reading: false, path: path)
                    }
                } catch let err {
                    if let auxFilePath = auxFilePath {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(auxFilePath)
                        } catch _ {}
                    }
                    throw err
                }
            }
        }
        if let auxFilePath = auxFilePath {
            if rename(auxFilePath, path) != 0 {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(auxFilePath)
                } catch _ {}
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            }
            if let mode = mode {
                chmod(path, mode)
            }
        }
    }
    
    public func writeToFile(path: String, atomically useAuxiliaryFile: Bool) -> Bool {
        do {
            try writeToFile(path, options: useAuxiliaryFile ? .DataWritingAtomic : [])
        } catch {
            return false
        }
        return true
    }
    
    public func writeToURL(url: NSURL, atomically: Bool) -> Bool {
        if url.fileURL {
            if let path = url.path {
                return writeToFile(path, atomically: atomically)
            }
        }
        return false
    }

    ///    Write the contents of the receiver to a location specified by the given file URL.
    ///
    ///    - parameter url:              The location to which the receiver’s contents will be written.
    ///    - parameter writeOptionsMask: An option set specifying file writing options.
    ///
    ///    - throws: This method returns Void and is marked with the `throws` keyword to indicate that it throws an error in the event of failure.
    ///
    ///      This method is invoked in a `try` expression and the caller is responsible for handling any errors in the `catch` clauses of a `do` statement, as described in [Error Handling](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/ErrorHandling.html#//apple_ref/doc/uid/TP40014097-CH42) in [The Swift Programming Language](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/index.html#//apple_ref/doc/uid/TP40014097) and [Error Handling](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html#//apple_ref/doc/uid/TP40014216-CH7-ID10) in [Using Swift with Cocoa and Objective-C](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/index.html#//apple_ref/doc/uid/TP40014216).
    public func writeToURL(url: NSURL, options writeOptionsMask: NSDataWritingOptions) throws {
        guard let path = url.path where url.fileURL == true else {
            let userInfo = [NSLocalizedDescriptionKey : "The folder at “\(url)” does not exist or is not a file URL.", // NSLocalizedString() not yet available
                            NSURLErrorKey             : url.absoluteString ?? ""] as Dictionary<String, Any>
            throw NSError(domain: NSCocoaErrorDomain, code: 4, userInfo: userInfo)
        }
        try writeToFile(path, options: writeOptionsMask)
    }
    
    public func rangeOfData(dataToFind: NSData, options mask: NSDataSearchOptions, range searchRange: NSRange) -> NSRange {
        guard dataToFind.length > 0 else {return NSRange(location: NSNotFound, length: 0)}
        guard let searchRange = searchRange.toRange() else {fatalError("invalid range")}
        
        precondition(searchRange.endIndex <= self.length, "range outside the bounds of data")
        
        let baseData = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(self.bytes), count: self.length)[searchRange]
        let search = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(dataToFind.bytes), count: dataToFind.length)
        
        let location : Int?
        let anchored = mask.contains(.Anchored)
        if mask.contains(.Backwards) {
            location = NSData.searchSubSequence(search.reverse(), inSequence: baseData.reverse(),anchored : anchored).map {$0.base-search.count}
        } else {
            location = NSData.searchSubSequence(search, inSequence: baseData,anchored : anchored)
        }
        return location.map {NSRange(location: $0, length: search.count)} ?? NSRange(location: NSNotFound, length: 0)
    }
    private static func searchSubSequence<T : CollectionType,T2 : SequenceType where T.Generator.Element : Equatable, T.Generator.Element == T2.Generator.Element, T.SubSequence.Generator.Element == T.Generator.Element>(subSequence : T2, inSequence seq: T,anchored : Bool) -> T.Index? {
        for index in seq.indices {
            if seq.suffixFrom(index).startsWith(subSequence) {
                return index
            }
            if anchored {return nil}
        }
        return nil
    }
    
    internal func enumerateByteRangesUsingBlockRethrows(block: (UnsafePointer<Void>, NSRange, UnsafeMutablePointer<Bool>) throws -> Void) throws {
        var err : ErrorType? = nil
        self.enumerateByteRangesUsingBlock() { (buf, range, stop) -> Void in
            do {
                try block(buf, range, stop)
            } catch let e {
                err = e
            }
        }
        if let err = err {
            throw err
        }
    }

    public func enumerateByteRangesUsingBlock(block: (UnsafePointer<Void>, NSRange, UnsafeMutablePointer<Bool>) -> Void) {
        var stop = false
        withUnsafeMutablePointer(&stop) { stopPointer in
            block(bytes, NSMakeRange(0, length), stopPointer)
        }
    }
}

extension NSData : _CFBridgable { }

extension CFDataRef : _NSBridgable {
    typealias NSType = NSData
    internal var _nsObject: NSType { return unsafeBitCast(self, NSType.self) }
}

extension NSMutableData {
    internal var _cfMutableObject: CFMutableDataRef { return unsafeBitCast(self, CFMutableDataRef.self) }
}

public class NSMutableData : NSData {

    public required convenience init() {
        self.init(bytes: nil, length: 0)
    }
    
    internal override init(bytes: UnsafeMutablePointer<Void>, length: Int, copy: Bool, deallocator: ((UnsafeMutablePointer<Void>, Int) -> Void)?) {
        super.init(bytes: bytes, length: length, copy: copy, deallocator: deallocator)
    }
    
    public var mutableBytes: UnsafeMutablePointer<Void> {
        return UnsafeMutablePointer(CFDataGetMutableBytePtr(_cfMutableObject))
    }
    
    public override var length: Int {
        get {
            return CFDataGetLength(_cfObject)
        }
        set {
            CFDataSetLength(_cfMutableObject, newValue)
        }
    }
    
    public override func copyWithZone(zone: NSZone) -> AnyObject {
        return NSData(data: self)
    }
}

extension NSData {
    
    /* Create an NSData from a Base-64 encoded NSString using the given options. By default, returns nil when the input is not recognized as valid Base-64.
    */
    public convenience init?(base64EncodedString base64String: String, options: NSDataBase64DecodingOptions) {
        let encodedBytes = Array(base64String.utf8)
        guard let decodedBytes = NSData.base64DecodeBytes(encodedBytes, options: options) else {
            return nil
        }
        self.init(bytes: decodedBytes, length: decodedBytes.count)
    }
    
    /* Create a Base-64 encoded NSString from the receiver's contents using the given options.
    */
    public func base64EncodedStringWithOptions(options: NSDataBase64EncodingOptions) -> String {
        var decodedBytes = [UInt8](count: self.length, repeatedValue: 0)
        getBytes(&decodedBytes, length: decodedBytes.count)
        let encodedBytes = NSData.base64EncodeBytes(decodedBytes, options: options)
        let characters = encodedBytes.map { Character(UnicodeScalar($0)) }
        return String(characters)
    }
    
    /* Create an NSData from a Base-64, UTF-8 encoded NSData. By default, returns nil when the input is not recognized as valid Base-64.
    */
    public convenience init?(base64EncodedData base64Data: NSData, options: NSDataBase64DecodingOptions) {
        var encodedBytes = [UInt8](count: base64Data.length, repeatedValue: 0)
        base64Data.getBytes(&encodedBytes, length: encodedBytes.count)
        guard let decodedBytes = NSData.base64DecodeBytes(encodedBytes, options: options) else {
            return nil
        }
        self.init(bytes: decodedBytes, length: decodedBytes.count)
    }
    
    /* Create a Base-64, UTF-8 encoded NSData from the receiver's contents using the given options.
    */
    public func base64EncodedDataWithOptions(options: NSDataBase64EncodingOptions) -> NSData {
        var decodedBytes = [UInt8](count: self.length, repeatedValue: 0)
        getBytes(&decodedBytes, length: decodedBytes.count)
        let encodedBytes = NSData.base64EncodeBytes(decodedBytes, options: options)
        return NSData(bytes: encodedBytes, length: encodedBytes.count)
    }
    
    /**
      The ranges of ASCII characters that are used to encode data in Base64.
      */
    private static let base64ByteMappings: [Range<UInt8>] = [
        65 ..< 91,      // A-Z
        97 ..< 123,     // a-z
        48 ..< 58,      // 0-9
        43 ..< 44,      // +
        47 ..< 48,      // /
    ]
    /**
     Padding character used when the number of bytes to encode is not divisible by 3
     */
    private static let base64Padding : UInt8 = 61 // =
    
    /**
        This method takes a byte with a character from Base64-encoded string
        and gets the binary value that the character corresponds to.
     
        - parameter byte:       The byte with the Base64 character.
        - returns:              Base64DecodedByte value containing the result (Valid , Invalid, Padding)
        */
    private enum Base64DecodedByte {
        case Valid(UInt8)
        case Invalid
        case Padding
    }
    private static func base64DecodeByte(byte: UInt8) -> Base64DecodedByte {
        guard byte != base64Padding else {return .Padding}
        var decodedStart: UInt8 = 0
        for range in base64ByteMappings {
            if range.contains(byte) {
                let result = decodedStart + (byte - range.startIndex)
                return .Valid(result)
            }
            decodedStart += range.endIndex - range.startIndex
        }
        return .Invalid
    }
    
    /**
        This method takes six bits of binary data and encodes it as a character
        in Base64.
 
        The value in the byte must be less than 64, because a Base64 character
        can only represent 6 bits.
 
        - parameter byte:       The byte to encode
        - returns:              The ASCII value for the encoded character.
        */
    private static func base64EncodeByte(byte: UInt8) -> UInt8 {
        assert(byte < 64)
        var decodedStart: UInt8 = 0
        for range in base64ByteMappings {
            let decodedRange = decodedStart ..< decodedStart + (range.endIndex - range.startIndex)
            if decodedRange.contains(byte) {
                return range.startIndex + (byte - decodedStart)
            }
            decodedStart += range.endIndex - range.startIndex
        }
        return 0
    }
    
    
    /**
        This method decodes Base64-encoded data.
     
        If the input contains any bytes that are not valid Base64 characters,
        this will return nil.
 
        - parameter bytes:      The Base64 bytes
        - parameter options:    Options for handling invalid input
        - returns:              The decoded bytes.
        */
    private static func base64DecodeBytes(bytes: [UInt8], options: NSDataBase64DecodingOptions = []) -> [UInt8]? {
        var decodedBytes = [UInt8]()
        decodedBytes.reserveCapacity((bytes.count/3)*2)

        var currentByte : UInt8 = 0
        var validCharacterCount = 0
        var paddingCount = 0
        var index = 0
        
        
        for base64Char in bytes {
            
            let value : UInt8
            
            switch base64DecodeByte(base64Char) {
            case .Valid(let v):
                value = v
                validCharacterCount += 1
            case .Invalid:
                if options.contains(.IgnoreUnknownCharacters) {
                    continue
                } else {
                    return nil
                }
            case .Padding:
                paddingCount += 1
                continue
            }
            
            //padding found in the middle of the sequence is invalid
            if paddingCount > 0 {
                return nil
            }
            
            switch index%4 {
            case 0:
                currentByte = (value << 2)
            case 1:
                currentByte |= (value >> 4)
                decodedBytes.append(currentByte)
                currentByte = (value << 4)
            case 2:
                currentByte |= (value >> 2)
                decodedBytes.append(currentByte)
                currentByte = (value << 6)
            case 3:
                currentByte |= value
                decodedBytes.append(currentByte)
            default:
                fatalError()
            }
            
            index += 1
        }
        
        guard (validCharacterCount + paddingCount)%4 == 0 else {
            //invalid character count
            return nil
        }
        return decodedBytes
    }
    
    
    /**
        This method encodes data in Base64.
     
        - parameter bytes:      The bytes you want to encode
        - parameter options:    Options for formatting the result
        - returns:              The Base64-encoding for those bytes.
        */
    private static func base64EncodeBytes(bytes: [UInt8], options: NSDataBase64EncodingOptions = []) -> [UInt8] {
        var result = [UInt8]()
        result.reserveCapacity((bytes.count/3)*4)
        
        let lineOptions : (lineLength : Int, separator : [UInt8])? = {
            let lineLength: Int
            
            if options.contains(.Encoding64CharacterLineLength) { lineLength = 64 }
            else if options.contains(.Encoding76CharacterLineLength) { lineLength = 76 }
            else {
                return nil
            }
            
            var separator = [UInt8]()
            if options.contains(.EncodingEndLineWithCarriageReturn) { separator.append(13) }
            if options.contains(.EncodingEndLineWithLineFeed) { separator.append(10) }
            
            //if the kind of line ending to insert is not specified, the default line ending is Carriage Return + Line Feed.
            if separator.count == 0 {separator = [13,10]}
            
            return (lineLength,separator)
        }()
        
        var currentLineCount = 0
        let appendByteToResult : (UInt8) -> () = {
            result.append($0)
            currentLineCount += 1
            if let options = lineOptions where currentLineCount == options.lineLength {
                result.appendContentsOf(options.separator)
                currentLineCount = 0
            }
        }
        
        var currentByte : UInt8 = 0
        
        for (index,value) in bytes.enumerate() {
            switch index%3 {
            case 0:
                currentByte = (value >> 2)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 6) >> 2)
            case 1:
                currentByte |= (value >> 4)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 4) >> 2)
            case 2:
                currentByte |= (value >> 6)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 2) >> 2)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
            default:
                fatalError()
            }
        }
        //add padding
        switch bytes.count%3 {
        case 0: break //no padding needed
        case 1:
            appendByteToResult(NSData.base64EncodeByte(currentByte))
            appendByteToResult(self.base64Padding)
            appendByteToResult(self.base64Padding)
        case 2:
            appendByteToResult(NSData.base64EncodeByte(currentByte))
            appendByteToResult(self.base64Padding)
        default:
            fatalError()
        }
        return result
    }
}

extension NSMutableData {

    public func appendBytes(bytes: UnsafePointer<Void>, length: Int) {
        CFDataAppendBytes(_cfMutableObject, UnsafePointer<UInt8>(bytes), length)
    }
    
    public func appendData(other: NSData) {
        appendBytes(other.bytes, length: other.length)
    }
    
    public func increaseLengthBy(extraLength: Int) {
        CFDataSetLength(_cfMutableObject, CFDataGetLength(_cfObject) + extraLength)
    }
    
    public func replaceBytesInRange(range: NSRange, withBytes bytes: UnsafePointer<Void>) {
        CFDataReplaceBytes(_cfMutableObject, CFRangeMake(range.location, range.length), UnsafePointer<UInt8>(bytes), length)
    }
    
    public func resetBytesInRange(range: NSRange) {
        bzero(mutableBytes.advancedBy(range.location), range.length)
    }
    
    public func setData(data: NSData) {
        length = data.length
        replaceBytesInRange(NSMakeRange(0, data.length), withBytes: data.bytes)
    }
    
    public func replaceBytesInRange(range: NSRange, withBytes replacementBytes: UnsafePointer<Void>, length replacementLength: Int) {
        CFDataReplaceBytes(_cfMutableObject, CFRangeMake(range.location, range.length), UnsafePointer<UInt8>(bytes), replacementLength)
    }
}

extension NSMutableData {
    
    public convenience init?(capacity: Int) {
        self.init(bytes: nil, length: 0)
    }
    
    public convenience init?(length: Int) {
        let memory = malloc(length)
        self.init(bytes: memory, length: length, copy: false) { buffer, amount in
            free(buffer)
        }
    }
}
