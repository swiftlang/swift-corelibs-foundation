// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal final class _NSString0 : NSString {
    static let empty = _NSString0(_empty: ())
    init(_empty: ()) {
        super.init()
    }
    
    public required convenience init(stringLiteral value: StaticString) {
        fatalError("Concrete base classes cannot be initialized with \(#function)")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Concrete base classes cannot be initialized with \(#function)")
    }
    
    override func character(at index: Int) -> unichar {
        fatalError("Concrete base classes cannot be initialized with \(#function)")
    }
    
    override var length: Int {
        return 0
    }
    
    override func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        precondition(range.length == 0)
    }
}
