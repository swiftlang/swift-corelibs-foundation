// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSEnumerator : NSObject {
    
    public func nextObject() -> AnyObject? {
        NSRequiresConcreteImplementation()
    }

}

extension NSEnumerator : SequenceType {

    public struct Generator : GeneratorType {
        let enumerator : NSEnumerator
        public func next() -> AnyObject? {
            return enumerator.nextObject()
        }
    }

    public func generate() -> Generator {
        return Generator(enumerator: self)
    }

}

extension NSEnumerator {

    public var allObjects: [AnyObject] {
        return Array(self)
    }

}

internal class NSGeneratorEnumerator<Base : GeneratorType where Base.Element : AnyObject> : NSEnumerator {
    var generator : Base
    init(_ generator: Base) {
        self.generator = generator
    }
    
    override func nextObject() -> AnyObject? {
        return generator.next()
    }
}
