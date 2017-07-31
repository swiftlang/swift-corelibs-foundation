// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal final class NSSubrangeData : NSData {
    var _range: NSRange
    var _data: NSData
    
    init(_ data: NSData, range: NSRange) {
        if let sdata = data as? NSSubrangeData {
            _range = NSMakeRange(sdata._range.location + range.location, range.length)
            _data = sdata._data
        } else {
            _range = range
            _data = data.copy(with: nil) as! NSData
        }
        super.init(placeholder: ())
    }
    
    override func _isCompact() -> Bool {
        return _data._isCompact()
    }
    
    override func _providesConcreteBacking() -> Bool {
        return _data._providesConcreteBacking()
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var length: Int { return _range.length }
    
    override var bytes: UnsafeRawPointer { return _data.bytes.advanced(by: _range.location) }
}

