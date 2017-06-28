//
//  NSSwiftString.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 6/25/17.
//  Copyright © 2017 Apple. All rights reserved.
//

internal final class _NSSwiftString : NSString {
    var _storage: String
    
    init(_string string: String) {
        _storage = string
        super.init()
    }
    
    public required convenience init(stringLiteral value: StaticString) {
        fatalError("Concrete base classes cannot be initialized with \(#function)")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Concrete base classes cannot be initialized with \(#function)")
    }
    
    override func character(at index: Int) -> unichar {
        let start = _storage.utf16.startIndex
        return _storage.utf16[start.advanced(by: index)]
    }
    
    override var length: Int {
        return _storage.utf16.count
    }
    
    override func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        _storage.withCString(encodedAs: Unicode.UTF16.self) {
            buffer.assign(from: $0.advanced(by: range.location), count: range.length)
        }
    }
    
    override func _fastCharacterContents() -> UnsafePointer<unichar>? {
        if _storage._core.hasContiguousStorage && _storage._core.elementWidth == 2 {
            return UnsafePointer<unichar>(_storage._core.startUTF16)
        }
        return nil
    }
    
    override func _fastCStringContents(_ nullTerminationRequired: Bool) -> UnsafePointer<Int8>? {
        if _storage._core.hasContiguousStorage && _storage._core.elementWidth == 1 {
            return UnsafeRawPointer(_storage._core.startASCII).assumingMemoryBound(to: Int8.self)
        }
        return nil
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object else { return false }
        if let str = other as? String {
            return _storage == str
        } else if let str = other as? _NSSwiftString {
            return _storage == str._storage
        }
        return super.isEqual(other)
    }
    
    override func isEqual(to aString: String) -> Bool {
        return _storage == aString
    }
}
