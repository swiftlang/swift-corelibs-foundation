// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

open class NSEnumerator : NSObject {
    
    open func nextObject() -> Any? {
        NSRequiresConcreteImplementation()
    }

}

extension NSEnumerator : Sequence {

    public struct Iterator : IteratorProtocol {
        let enumerator : NSEnumerator
        public func next() -> Any? {
            return enumerator.nextObject()
        }
    }

    public func makeIterator() -> Iterator {
        return Iterator(enumerator: self)
    }

}

extension NSEnumerator {

    public var allObjects: [Any] {
        return Array(self)
    }

}

internal class NSGeneratorEnumerator<Base : IteratorProtocol> : NSEnumerator where Base.Element : Any {
    var generator : Base
    init(_ generator: Base) {
        self.generator = generator
    }
    
    override func nextObject() -> Any? {
        return generator.next()
    }
}
