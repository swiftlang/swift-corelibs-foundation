// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch

class TestProgress : XCTestCase {
    static var allTests: [(String, (TestProgress) -> () throws -> Void)] {
        return [
            ("test_totalCompletedChangeAffectsFractionCompleted", test_totalCompletedChangeAffectsFractionCompleted),
            ("test_multipleChildren", test_multipleChildren),
            ("test_indeterminateChildrenAffectFractionCompleted", test_indeterminateChildrenAffectFractionCompleted),
            ("test_indeterminateChildrenAffectFractionCompleted2", test_indeterminateChildrenAffectFractionCompleted2),
            ("test_childCompletionFinishesGroups", test_childCompletionFinishesGroups),
            ("test_childrenAffectFractionCompleted_explicit", test_childrenAffectFractionCompleted_explicit),
            ("test_childrenAffectFractionCompleted_explicit_partial", test_childrenAffectFractionCompleted_explicit_partial),
            ("test_childrenAffectFractionCompleted_explicit_child_already_complete", test_childrenAffectFractionCompleted_explicit_child_already_complete),
            ("test_grandchildrenAffectFractionCompleted", test_grandchildrenAffectFractionCompleted),
            ("test_grandchildrenAffectFractionCompleted_explicit", test_grandchildrenAffectFractionCompleted_explicit),
            ("test_mixedExplicitAndImplicitChildren", test_mixedExplicitAndImplicitChildren),
            ("test_notReturningNaN", test_notReturningNaN),
            ("test_handlers", test_handlers),
            ("test_alreadyCancelled", test_alreadyCancelled),
            ("test_userInfo", test_userInfo),
        ]
    }
    
    func test_totalCompletedChangeAffectsFractionCompleted() {
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 100
        
        // Test self
        parent.completedUnitCount = 50
        XCTAssertEqual(0.5, parent.fractionCompleted, accuracy: 0.01)
        
        parent.completedUnitCount = 0
        // Test child
        parent.becomeCurrent(withPendingUnitCount: 10)
        let child1 = Progress(totalUnitCount: 100)
        child1.completedUnitCount = 50
        
        // half of 10% is done in parent
        XCTAssertEqual(0.05, parent.fractionCompleted, accuracy: 0.01)
        XCTAssertEqual(0.5, child1.fractionCompleted, accuracy: 0.01)
        
        // Up the total amount of work
        parent.totalUnitCount = 200
        
        XCTAssertEqual(0.5 * (10.0 / 200.0) /* 0.025 */, parent.fractionCompleted, accuracy: 0.01)
        XCTAssertEqual(0.5, child1.fractionCompleted, accuracy: 0.01)
        
        // Change the total in the child, doubling total amount of work
        child1.totalUnitCount = 200
        XCTAssertEqual(50.0 / 200.0, child1.fractionCompleted, accuracy: 0.01)
        XCTAssertEqual((50.0 / 200.0) * (10.0 / 200), parent.fractionCompleted, accuracy: 0.01)
        
        // Change the total in the child, the other direction, halving the amount of work
        child1.totalUnitCount = 100
        XCTAssertEqual(50.0 / 100.0, child1.fractionCompleted, accuracy: 0.01)
        XCTAssertEqual((50.0 / 100.0) * (10.0 / 200), parent.fractionCompleted, accuracy: 0.01)
    }
    
    func test_multipleChildren() {
        // Verify that when multiple children are added to one group, they do the right thing
        // n.b. prior to 10.11 / 9.0, this split up the pending unit among all of the children. After that, we give all of the pending unit count to the first child. This is because if you split up the pending unit count, the progress will almost certainly go backwards. API was added to give more explicit control over adding multiple children.
        let progress = Progress(parent: nil)
        progress.totalUnitCount = 100
        
        // Create two children
        progress.becomeCurrent(withPendingUnitCount: 100)
        let child1 = Progress(totalUnitCount: 5)
        let child2 = Progress(totalUnitCount: 5)
        
        XCTAssertEqual(progress.fractionCompleted, 0, accuracy: 0.01)
        
        child2.completedUnitCount = 5
        
        // Child2 does not affect the parent's fraction completed (it should only be child1 that makes a difference)
        XCTAssertEqual(progress.fractionCompleted, 0, accuracy: 0.01)

        let _ = Progress(totalUnitCount: 5)
        XCTAssertEqual(progress.fractionCompleted, 0, accuracy: 0.01)
        
        // Update child #1
        child1.completedUnitCount = 5
        XCTAssertEqual(progress.fractionCompleted, 1.0, accuracy: 0.01)
    }
    
    func test_indeterminateChildrenAffectFractionCompleted() {
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 1000
        
        parent.becomeCurrent(withPendingUnitCount: 100)
        let child1 = Progress(totalUnitCount: 10)
        
        child1.completedUnitCount = 5
        XCTAssertEqual(parent.fractionCompleted, 0.05, accuracy: 0.01)
        
        // Child1 becomes indeterminate
        child1.completedUnitCount = -1
        XCTAssertEqual(parent.fractionCompleted, 0.0, accuracy: 0.01)
        
        // Become determinate
        // childProgress1's completed unit count is 100% of its total of 10 (10)
        // childProgress1 is 10% of the overall unit count (100 / 1000)
        // the overall count done should be 100% of 10% of 1000, or 1.0 * 0.1 * 1000 = 100
        // the overall percentage done should be 100 / 1000 = 0.1
        child1.completedUnitCount = 10
        XCTAssertEqual(parent.fractionCompleted, 0.1, accuracy: 0.01)
        
        // Become indeterminate again
        child1.completedUnitCount = -1
        XCTAssertEqual(parent.fractionCompleted, 0.0, accuracy: 0.01)
        
        parent.resignCurrent()
    }

    func test_indeterminateChildrenAffectFractionCompleted2() {
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 100
        
        parent.becomeCurrent(withPendingUnitCount: 50)
        let child1 = Progress(totalUnitCount: 2)
        parent.resignCurrent()

        parent.becomeCurrent(withPendingUnitCount: 50)
        let child2 = Progress(totalUnitCount: 2)
        parent.resignCurrent()

        XCTAssertEqual(parent.fractionCompleted, 0.0, accuracy: 0.01)

        child1.completedUnitCount = 1
        child2.completedUnitCount = 1
        
        // half done
        XCTAssertEqual(parent.fractionCompleted, 0.5, accuracy: 0.01)
        
        // Move a child to indeterminate
        child1.completedUnitCount = -1
        XCTAssertEqual(parent.fractionCompleted, 0.25, accuracy: 0.01)
        
        // Move it back to determinate
        child1.completedUnitCount = 1
        XCTAssertEqual(parent.fractionCompleted, 0.5, accuracy: 0.01)
    }

    func test_childCompletionFinishesGroups() {
        let root = Progress(totalUnitCount: 2)
        let child1 = Progress(totalUnitCount: 1)
        let child2 = Progress(totalUnitCount: 1)
        
        root.addChild(child1, withPendingUnitCount: 1)
        root.addChild(child2, withPendingUnitCount: 1)
        
        child1.completedUnitCount = 1
        XCTAssertEqual(root.fractionCompleted, 0.5, accuracy: 0.01)
        
        child2.completedUnitCount = 1
        XCTAssertEqual(root.fractionCompleted, 1.0, accuracy: 0.01)
        XCTAssertEqual(root.completedUnitCount, 2)
    }
    
    func test_childrenAffectFractionCompleted_explicit() {
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 100
        
        XCTAssertEqual(parent.fractionCompleted, 0.0)
        
        let child1 = Progress(totalUnitCount: 100)
        parent.addChild(child1, withPendingUnitCount: 10)
        
        child1.completedUnitCount = 50
        
        // let's say some of this work is done inside the become/resign pair
        // half of 10% is done
        XCTAssertEqual(0.05, parent.fractionCompleted)
        
        // ... and the rest is done outside the become/resign pair
        child1.completedUnitCount = 100;
        
        // Now the rest is done
        XCTAssertEqual(0.10, parent.fractionCompleted)
        
        // Add another child
        let child2 = Progress(totalUnitCount: 100)
        parent.addChild(child2, withPendingUnitCount: 90)
        child2.completedUnitCount = 50
        
        XCTAssertEqual(0.10 + 0.9 / 2.0, parent.fractionCompleted)
    }
    
    func test_childrenAffectFractionCompleted_explicit_partial() {
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 2
        
        XCTAssertEqual(parent.fractionCompleted, 0.0)
        
        // Add a child, then update after adding
        let child1 = Progress(totalUnitCount: 100)
        parent.addChild(child1, withPendingUnitCount: 1)
        child1.completedUnitCount = 50
        
        // Half of 50% is done
        XCTAssertEqual(0.25, parent.fractionCompleted)
        
        // Add a new child, but it is already in process
        let child2 = Progress(totalUnitCount: 100)
        child2.completedUnitCount = 50
        parent.addChild(child2, withPendingUnitCount: 1)
        
        // half of 50% is done + half of 50% is done == 50% of overall work is done
        XCTAssertEqual(0.50, parent.fractionCompleted)
    }
    
    func test_childrenAffectFractionCompleted_explicit_child_already_complete() {
        // Adding children who are already partially completed should cause the parent fraction completed to be updated
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 2
        
        XCTAssertEqual(parent.fractionCompleted, 0.0)
        
        // Add a child, then update after adding
        let child1 = Progress(totalUnitCount: 100)
        child1.completedUnitCount = 100
        parent.addChild(child1, withPendingUnitCount: 1)
        
        // all of 50% is done
        XCTAssertEqual(0.5, parent.fractionCompleted)
    }
    
    func test_grandchildrenAffectFractionCompleted_explicit() {
        // The parent's progress is entirely represented by the 1 grandchild
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 100
        
        XCTAssertEqual(parent.fractionCompleted, 0.0)

        let child = Progress(totalUnitCount: 100)
        parent.addChild(child, withPendingUnitCount: 100)
        
        let grandchild = Progress(totalUnitCount: 100)
        child.addChild(grandchild, withPendingUnitCount: 100)
        
        // Now we have parentProgress <- childProgress <- grandchildProgress
        XCTAssertEqual(parent.fractionCompleted, 0.0)

        grandchild.completedUnitCount = 50
        
        XCTAssertEqual(0.50, parent.fractionCompleted)
    }
    
    func test_grandchildrenAffectFractionCompleted() {
        // The parent's progress is entirely represented by the 1 grandchild
        let parent = Progress(parent: nil)
        parent.totalUnitCount = 100
        
        XCTAssertEqual(parent.fractionCompleted, 0.0)
        
        parent.becomeCurrent(withPendingUnitCount: 100)
        let child = Progress(totalUnitCount: 100)
        parent.resignCurrent()
        
        child.becomeCurrent(withPendingUnitCount: 100)
        let grandchild = Progress(totalUnitCount: 100)
        child.resignCurrent()
        
        // Now we have parentProgress <- childProgress <- grandchildProgress
        XCTAssertEqual(parent.fractionCompleted, 0.0)
        
        grandchild.completedUnitCount = 50
        XCTAssertEqual(0.50, parent.fractionCompleted)
    }

    func test_mixedExplicitAndImplicitChildren() {
        let parent = Progress(parent: nil)
        
        parent.totalUnitCount = 3
        
        let child1 = Progress(totalUnitCount: 10)
        let child2 = Progress(totalUnitCount: 10)
        parent.addChild(child1, withPendingUnitCount: 1)
        parent.addChild(child2, withPendingUnitCount: 1)
        
        // child1 is half done. This means the parent is half of 1/3 done.
        child1.completedUnitCount = 5
        XCTAssertEqual(parent.fractionCompleted, (1.0 / 3.0) / 2.0, accuracy: 0.01)
        
        // child2 is half done. This means the parent is (half of 1/3 done) + (half of 1/3 done).
        child2.completedUnitCount = 5
        XCTAssertEqual(parent.fractionCompleted, ((1.0 / 3.0) / 2.0) * 2.0, accuracy: 0.01)
        
        // add an implict child
        parent.becomeCurrent(withPendingUnitCount: 1)
        let child3 = Progress(totalUnitCount: 10)
        parent.resignCurrent()
        
        // Total completed of parent should not change
        XCTAssertEqual(parent.fractionCompleted, ((1.0 / 3.0) / 2.0) * 2.0, accuracy: 0.01)
        
        // child3 is half done. This means the parent is (half of 1/3 done) * 3.
        child3.completedUnitCount = 5
        XCTAssertEqual(parent.fractionCompleted, ((1.0 / 3.0) / 2.0) * 3.0, accuracy: 0.01)
        
        // Finish child3
        child3.completedUnitCount = 10
        XCTAssertTrue(child3.isFinished)
        XCTAssertEqual(parent.fractionCompleted, (((1.0 / 3.0) / 2.0) * 2.0) + (1.0 / 3.0), accuracy: 0.01)
        
        // Finish child2
        child2.completedUnitCount = 10;
        XCTAssertTrue(child2.isFinished)
        XCTAssertEqual(parent.fractionCompleted, ((1.0 / 3.0) / 2.0) + ((1.0 / 3.0) * 2.0), accuracy: 0.01)
        
        // Finish child1
        child1.completedUnitCount = 10;
        XCTAssertTrue(child1.isFinished)
        XCTAssertEqual(parent.fractionCompleted, 1.0, accuracy: 0.01)
        XCTAssertTrue(parent.isFinished)
        XCTAssertEqual(parent.completedUnitCount, parent.totalUnitCount)

    }
    
    func test_notReturningNaN() {
        let p = Progress(parent: nil)
        
        let tests = [(-1, -1, true, 0.0),
                     (0, -1, true, 0.0),
                     (1, -1, true, 0.0),
                     (-1, 0, true, 0.0),
                     (0, 0, true, 0.0),
                     (1, 0, false, 1.0),
                     (-1, 1, true, 0.0),
                     (0, 1, false, 0.0),
                     (1, 1, false, 1.0)]
        
        for t in tests {
            p.completedUnitCount = Int64(t.0)
            p.totalUnitCount = Int64(t.1)
            XCTAssertEqual(t.2, p.isIndeterminate, "failed with \(t)")
            XCTAssertEqual(t.3, p.fractionCompleted,  "failed with \(t)")
        }
    }
    
    func test_handlers() {
        let parent = Progress(parent: nil)
        let parentSema = DispatchSemaphore(value: 0)
        
        let child = Progress(parent: nil)
        let childSema = DispatchSemaphore(value: 0)
        
        parent.addChild(child, withPendingUnitCount: 1)
        
        parent.cancellationHandler = { parentSema.signal() }
        child.cancellationHandler = { childSema.signal() }
        parent.pausingHandler = { parentSema.signal() }
        child.pausingHandler = { childSema.signal() }
        parent.resumingHandler = { parentSema.signal() }
        child.resumingHandler = { childSema.signal() }

        parent.cancel()
        XCTAssertEqual(.success, parentSema.wait(timeout: .now() + .seconds(3)))
        XCTAssertEqual(.success, childSema.wait(timeout: .now() + .seconds(3)))
        
        parent.pause()
        XCTAssertEqual(.success, parentSema.wait(timeout: .now() + .seconds(3)))
        XCTAssertEqual(.success, childSema.wait(timeout: .now() + .seconds(3)))

        parent.resume()
        XCTAssertEqual(.success, parentSema.wait(timeout: .now() + .seconds(3)))
        XCTAssertEqual(.success, childSema.wait(timeout: .now() + .seconds(3)))
    }
    
    func test_alreadyCancelled() {
        let parent = Progress(parent: nil)
        let parentSema = DispatchSemaphore(value: 0)
        let child = Progress(parent: nil)
        let childSema = DispatchSemaphore(value: 0)
        parent.addChild(child, withPendingUnitCount: 1)

        parent.cancel()
        
        parent.cancellationHandler = { parentSema.signal() }
        child.cancellationHandler = { childSema.signal() }
        
        XCTAssertEqual(.success, parentSema.wait(timeout: .now() + .seconds(3)))
        XCTAssertEqual(.success, childSema.wait(timeout: .now() + .seconds(3)))
    }
    
    func test_userInfo() {
        let p = Progress(parent: nil, userInfo: [.estimatedTimeRemainingKey : 1000])
        XCTAssertEqual(p.userInfo[.estimatedTimeRemainingKey] as? Int, 1000)
        
        p.setUserInfoObject(2000, forKey: .fileTotalCountKey)
        XCTAssertEqual(p.userInfo[.fileTotalCountKey] as? Int, 2000)

        p.setUserInfoObject(nil, forKey: .fileTotalCountKey)
        XCTAssertEqual(p.userInfo[.fileTotalCountKey] as? Int, nil)
    }
}
