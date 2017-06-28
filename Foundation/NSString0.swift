//
//  NSString0.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 6/26/17.
//  Copyright © 2017 Apple. All rights reserved.
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
