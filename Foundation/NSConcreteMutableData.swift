// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal func _NSMutableDataGrowBytes(_ data: NSConcreteMutableData, _ newLength: Int, _ clear: Bool, _ _cmd: StaticString = #function) {
    let cap = data._capacity
    
    // Don't let the capacity calculation overflow.
    var additionalCapacity = (newLength >> (VM_OPS_THRESHOLD <= newLength ? 2 : 1))
    if Int.max - additionalCapacity < newLength {
        additionalCapacity = 0 // Allocating Int.max bytes probably isn't going to succeed, so just try allocating the minimum.
    }
    
    var newCapacity = Swift.max(cap, newLength + additionalCapacity)
    let origLength = data.length
    var allocateCleared = clear && _NSDataShouldAllocateCleared(newCapacity)
    
    var newBytes: UnsafeMutableRawPointer?
    
    if data._bytes == nil {
        newBytes = _NSDataAllocateBytes(newCapacity, allocateCleared)
        if(newBytes == nil) {
            /* Try again with minimum length */
            allocateCleared = clear && _NSDataShouldAllocateCleared(newLength)
            newBytes = _NSDataAllocateBytes(newLength, allocateCleared)
        }
    } else {
        let tryCalloc = (origLength == 0 || (newLength / origLength) >= 4)
        if allocateCleared && tryCalloc {
            newBytes = _NSDataAllocateBytes(newCapacity, true)
            if(newBytes != nil) {
                _NSFastMemoryMove(newBytes, data._bytes, origLength)
                data._freeBytes()
            }
        }
        /* Where calloc/memmove/free fails, realloc might succeed */
        if newBytes == nil {
            allocateCleared = false
            newBytes = realloc(data._bytes, newCapacity)
        }
        
        /* Try again with minimum length */
        if newBytes == nil {
            newCapacity = newLength
            allocateCleared = clear && _NSDataShouldAllocateCleared(newCapacity)
            if allocateCleared && tryCalloc {
                newBytes = _NSDataAllocateBytes(newCapacity, true)
                if newBytes != nil {
                    _NSFastMemoryMove(newBytes, data._bytes, origLength)
                    data._freeBytes()
                }
            }
            if newBytes == nil {
                allocateCleared = false
                newBytes = realloc(data._bytes, newCapacity)
            }
        }
    }
    if newBytes == nil {
        /* Could not allocate bytes */
        fatalError("\(_NSMethodExceptionProem(data, _cmd)): unable to allocate memory for length \(newLength)")
    }
    if origLength < newLength && clear && !allocateCleared {
        memset(newBytes!.advanced(by: origLength), 0, newLength - origLength)
    }
    /* _length set by caller */
    data._bytes = newBytes
    data._capacity = newCapacity
    data._hasVM = false
    /* Realloc/memset doesn't zero out the entire capacity, so we must be safe and clear next time we grow the length */
    data._needToZero = !allocateCleared
}

internal final class NSConcreteMutableData : NSMutableData {
    var _needToZero = false
    var _hasVM = false
    var _length = 0
    var _capacity = 0
    var _bytes: UnsafeMutableRawPointer? = nil
    
    override init(placeholder: ()) {
        super.init(placeholder: ())
    }
    
    convenience init?(_capacity numItems: Int) {
        self.init(placeholder: ())
        _NSDataCheckSize(self, numItems, "capacity");
        var capacity = (numItems < 1024 * 1024 * 1024) ? numItems + (numItems >> 2) : numItems
        if (VM_OPS_THRESHOLD <= capacity) {
            capacity = NSRoundUpToMultipleOfPageSize(capacity)
        }
        guard let bytes = _NSDataAllocateBytes(capacity, false) else { return nil }
        _length = 0
        _hasVM = false
        _bytes = bytes
        _capacity = capacity
        _needToZero = true
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func _freeBytes() {
        if let b = _bytes {
            if _hasVM {
                NSDeallocateMemoryPages(b, _capacity)
            } else {
                free(b)
            }
        }
    }
    
    override func _isCompact() -> Bool {
        return true
    }
    
    override func _providesConcreteBacking() -> Bool {
        return true
    }
    
    override var length: Int {
        get {
            return _length
        }
        set {
            _NSDataCheckSize(self, newValue, "length");
            let origLength = _length;
            let newLength = newValue
            if _capacity < newLength || _bytes == nil {
                _NSMutableDataGrowBytes(self, newLength, true)
            } else if (origLength < newLength && _needToZero) {
                memset(_bytes!.advanced(by: origLength), 0, newLength - origLength)
            } else if (newLength < origLength) {
                _needToZero = true
            }
            _length = newLength;
        }
    }
    
    override var bytes: UnsafeRawPointer {
        guard let bytes = _bytes else { return __NSDataNullBytes }
        return UnsafeRawPointer(bytes)
    }
    
    override var mutableBytes: UnsafeMutableRawPointer {
        return _bytes!
    }
    
    override func append(_ bytes: UnsafeRawPointer, length: Int) {
        guard length != 0 else { return }
        var srcBuf = UnsafeMutableRawPointer(mutating: bytes)
        let origLength = _length
        _NSDataCheckOverflow(self, origLength, length)
        let newLength = origLength + length
        var srcBufNeedsFree = false
        if _capacity < newLength || _bytes == nil {
            if _bytes != nil && bytes < UnsafeRawPointer(_bytes!).advanced(by: _capacity) && UnsafeRawPointer(_bytes!) < bytes.advanced(by: length) {
                // The source and destination overlap. Copy the bytes into a new buffer so they remain valid after realloc.
                srcBuf = malloc(length)
                srcBufNeedsFree = true
                _NSFastMemoryMove(srcBuf, bytes, length)
            }
            _NSMutableDataGrowBytes(self, newLength, false)
        }
        _length = newLength
        _NSFastMemoryMove(_bytes!.advanced(by: origLength), srcBuf, length)
        if srcBufNeedsFree { free(srcBuf) }
    }
    
    override func append(_ other: Data) {
        other.enumerateBytes { (bytes, _, _) in
            if bytes.count > 0 { append(bytes.baseAddress!, length: bytes.count) }
        }
    }
    
    override func increaseLength(by extraLength: Int) {
        guard extraLength != 0 else { return }
        _NSDataCheckSize(self, extraLength, "extra length")
        let origLength = _length;
        _NSDataCheckOverflow(self, origLength, extraLength)
        let newLength = origLength + extraLength
        if _capacity < newLength || _bytes == nil {
            _NSMutableDataGrowBytes(self, newLength, true)
        } else if (_needToZero) {
            memset(_bytes!.advanced(by: origLength), 0, extraLength)
        }
        _length = newLength
    }
    
    override func replaceBytes(in range: NSRange, withBytes bytes: UnsafeRawPointer) {
        guard range.length != 0 else { return }
        var srcBuf = UnsafeMutableRawPointer(mutating: bytes)
        _NSDataCheckBound(self, range.location, 0, _length, false)
        _NSDataCheckOverflow(self, range.location, range.length)
        var srcBufNeedsFree = false
        if (_length < range.location + range.length) {
            let newLength = range.location + range.length
            if (_capacity < newLength) {
                if _bytes != nil && bytes < UnsafeRawPointer(_bytes!).advanced(by: _capacity) && UnsafeRawPointer(_bytes!) < bytes.advanced(by: range.length) {
                    // The source and destination overlap. Copy the bytes into a new buffer so they remain valid after realloc.
                    srcBuf = malloc(range.length)
                    srcBufNeedsFree = true
                    _NSFastMemoryMove(srcBuf, bytes, range.length)
                }
                _NSMutableDataGrowBytes(self, newLength, false)
            }
            _length = newLength
        }
        _NSFastMemoryMove(_bytes!.advanced(by: range.location), srcBuf, range.length)
        if srcBufNeedsFree { free(srcBuf) }
    }
    
    override func resetBytes(in range: NSRange) {
        guard range.length != 0 else { return }
        _NSDataCheckBound(self, range.location, 0, _length, false)
        _NSDataCheckOverflow(self, range.location, range.length)
        if _length < range.location + range.length {
            let newLength = range.location + range.length
            if _capacity < newLength {
                _NSMutableDataGrowBytes(self, newLength, false)
            }
            _length = newLength
        }
        memset(_bytes!.advanced(by: range.location), 0, range.length)
    }
}
