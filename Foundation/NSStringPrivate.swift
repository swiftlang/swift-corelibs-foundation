// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal func _NSGetDefaultStringEncoding() -> String.Encoding.RawValue {
    return __NSDefaultStringEncodingFullyInited ? _NSDefaultStringEncoding : _NSDefaultCStringEncoding()
}

internal func _bytesInEncoding(_ str: NSString, _ encoding: String.Encoding, _ fatalOnError: Bool, _ externalRep: Bool, _ lossy: Bool) -> UnsafePointer<Int8>? {
    let theRange = NSMakeRange(0, str.length)
    var cLength = 0
    var used = 0
    var options: NSString.EncodingConversionOptions = []
    if externalRep {
        options.formUnion(.externalRepresentation)
    }
    if lossy {
        options.formUnion(.allowLossy)
    }
    if !str.getBytes(nil, maxLength: Int.max - 1, usedLength: &cLength, encoding: encoding.rawValue, options: options, range: theRange, remaining: nil) {
        if fatalOnError { fatalError("Conversion on encoding failed") }
        return nil
    }
    
    let buffer = malloc(cLength + 1)!.bindMemory(to: Int8.self, capacity: cLength + 1)
    if !str.getBytes(buffer, maxLength: cLength, usedLength: &used, encoding: encoding.rawValue, options: options, range: theRange, remaining: nil) {
        fatalError("Internal inconsistency; previously claimed getBytes returned success but failed with similar invocation")
    }
    
    buffer.advanced(by: cLength).initialize(to: 0)
    NSData(bytesNoCopy: UnsafeMutableRawPointer(mutating: buffer), length: cLength, freeWhenDone: true)._autorelease()
    return UnsafePointer(buffer) // leaked and should be autoreleased via a NSData backing but we cannot here
}

internal func _createRegexForPattern(_ pattern: String, _ options: NSRegularExpression.Options) -> NSRegularExpression? {
    struct local {
        static let __NSRegularExpressionCache: NSCache<NSString, NSRegularExpression> = {
            let cache = NSCache<NSString, NSRegularExpression>()
            cache.name = "NSRegularExpressionCache"
            cache.countLimit = 10
            return cache
        }()
    }
    let key = "\(options):\(pattern)"
    if let regex = local.__NSRegularExpressionCache.object(forKey: key._nsObject) {
        return regex
    }
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: options)
        local.__NSRegularExpressionCache.setObject(regex, forKey: key._nsObject)
        return regex
    } catch {
        
    }
    
    return nil
}

internal func isALineSeparatorTypeCharacter(_ ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x0085 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x0085 || ch == 0x2028 || ch == 0x2029
}

internal func isAParagraphSeparatorTypeCharacter(_ ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x2029 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x2029
}
