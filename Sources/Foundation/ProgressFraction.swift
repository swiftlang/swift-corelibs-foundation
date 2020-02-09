// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Implementation note: This file is included in both the framework and the test bundle, in order for us to be able to test it directly. Once @testable support works for Linux we may be able to use it from the framework instead.

internal struct _ProgressFraction : Equatable, CustomDebugStringConvertible {
    var completed : Int64
    var total : Int64
    private(set) var overflowed : Bool
    
    init() {
        completed = 0
        total = 0
        overflowed = false
    }
    
    init(double: Double, overflow: Bool = false) {
        if double == 0 {
            self.completed = 0
            self.total = 1
        } else if double == 1 {
            self.completed = 1
            self.total = 1
        }
        
        (self.completed, self.total) = _ProgressFraction._fromDouble(double)
        self.overflowed = overflow
    }
    
    init(completed: Int64, total: Int64) {
        self.completed = completed
        self.total = total
        self.overflowed = false
    }
    
    // ----
    
    internal mutating func simplify() {
        if self.total == 0 {
            return
        }
        
        (self.completed, self.total) = _ProgressFraction._simplify(completed, total)
    }
    
    internal func simplified() -> _ProgressFraction {
        let simplified = _ProgressFraction._simplify(completed, total)
        return _ProgressFraction(completed: simplified.0, total: simplified.1)
    }
    
    static private func _math(lhs: _ProgressFraction, rhs: _ProgressFraction, whichOperator: (_ lhs : Double, _ rhs : Double) -> Double, whichOverflow : (_ lhs: Int64, _ rhs: Int64) -> (Int64, overflow: Bool)) -> _ProgressFraction {
        // Mathematically, it is nonsense to add or subtract something with a denominator of 0. However, for the purposes of implementing Progress' fractions, we just assume that a zero-denominator fraction is "weightless" and return the other value. We still need to check for the case where they are both nonsense though.
        precondition(!(lhs.total == 0 && rhs.total == 0), "Attempt to add or subtract invalid fraction")
        guard lhs.total != 0 else {
            return rhs
        }
        guard rhs.total != 0 else {
            return lhs
        }
        
        guard !lhs.overflowed && !rhs.overflowed else {
            // If either has overflowed already, we preserve that
            return _ProgressFraction(double: whichOperator(lhs.fractionCompleted, rhs.fractionCompleted), overflow: true)
        }

        if let lcm = _leastCommonMultiple(lhs.total, rhs.total) {
            let result = whichOverflow(lhs.completed * (lcm / lhs.total), rhs.completed * (lcm / rhs.total))
            if result.overflow {
                return _ProgressFraction(double: whichOperator(lhs.fractionCompleted, rhs.fractionCompleted), overflow: true)
            } else {
                return _ProgressFraction(completed: result.0, total: lcm)
            }
        } else {
            // Overflow - simplify and then try again
            let lhsSimplified = lhs.simplified()
            let rhsSimplified = rhs.simplified()
            
            if let lcm = _leastCommonMultiple(lhsSimplified.total, rhsSimplified.total) {
                let result = whichOverflow(lhsSimplified.completed * (lcm / lhsSimplified.total), rhsSimplified.completed * (lcm / rhsSimplified.total))
                if result.overflow {
                    // Use original lhs/rhs here
                    return _ProgressFraction(double: whichOperator(lhs.fractionCompleted, rhs.fractionCompleted), overflow: true)
                } else {
                    return _ProgressFraction(completed: result.0, total: lcm)
                }
            } else {
                // Still overflow
                return _ProgressFraction(double: whichOperator(lhs.fractionCompleted, rhs.fractionCompleted), overflow: true)
            }
        }
    }
    
    static internal func +(lhs: _ProgressFraction, rhs: _ProgressFraction) -> _ProgressFraction {
        return _math(lhs: lhs, rhs: rhs, whichOperator: +, whichOverflow: { $0.addingReportingOverflow($1) })
    }
    
    static internal func -(lhs: _ProgressFraction, rhs: _ProgressFraction) -> _ProgressFraction {
        return _math(lhs: lhs, rhs: rhs, whichOperator: -, whichOverflow: { $0.subtractingReportingOverflow($1) })
    }
    
    static internal func *(lhs: _ProgressFraction, rhs: _ProgressFraction) -> _ProgressFraction {
        guard !lhs.overflowed && !rhs.overflowed else {
            // If either has overflowed already, we preserve that
            return _ProgressFraction(double: rhs.fractionCompleted * rhs.fractionCompleted, overflow: true)
        }

        let newCompleted = lhs.completed.multipliedReportingOverflow(by: rhs.completed)
        let newTotal = lhs.total.multipliedReportingOverflow(by: rhs.total)
        
        if newCompleted.overflow || newTotal.overflow {
            // Try simplifying, then do it again
            let lhsSimplified = lhs.simplified()
            let rhsSimplified = rhs.simplified()
            
            let newCompletedSimplified = lhsSimplified.completed.multipliedReportingOverflow(by: rhsSimplified.completed)
            let newTotalSimplified = lhsSimplified.total.multipliedReportingOverflow(by: rhsSimplified.total)
            
            if newCompletedSimplified.overflow || newTotalSimplified.overflow {
                // Still overflow
                return _ProgressFraction(double: lhs.fractionCompleted * rhs.fractionCompleted, overflow: true)
            } else {
                return _ProgressFraction(completed: newCompletedSimplified.0, total: newTotalSimplified.0)
            }
        } else {
            return _ProgressFraction(completed: newCompleted.0, total: newTotal.0)
        }
    }
    
    static internal func /(lhs: _ProgressFraction, rhs: Int64) -> _ProgressFraction {
        guard !lhs.overflowed else {
            // If lhs has overflowed, we preserve that
            return _ProgressFraction(double: lhs.fractionCompleted / Double(rhs), overflow: true)
        }
        
        let newTotal = lhs.total.multipliedReportingOverflow(by: rhs)
        
        if newTotal.overflow {
            let simplified = lhs.simplified()
            
            let newTotalSimplified = simplified.total.multipliedReportingOverflow(by: rhs)
            
            if newTotalSimplified.overflow {
                // Still overflow
                return _ProgressFraction(double: lhs.fractionCompleted / Double(rhs), overflow: true)
            } else {
                return _ProgressFraction(completed: lhs.completed, total: newTotalSimplified.0)
            }
        } else {
            return _ProgressFraction(completed: lhs.completed, total: newTotal.0)
        }
    }
    
    static internal func ==(lhs: _ProgressFraction, rhs: _ProgressFraction) -> Bool {
        if lhs.isNaN || rhs.isNaN {
            // NaN fractions are never equal
            return false
        } else if lhs.completed == rhs.completed && lhs.total == rhs.total {
            return true
        } else if lhs.total == rhs.total {
            // Direct comparison of numerator
            return lhs.completed == rhs.completed
        } else if lhs.completed == 0 && rhs.completed == 0 {
            return true
        } else if lhs.completed == lhs.total && rhs.completed == rhs.total {
            // Both finished (1)
            return true
        } else if (lhs.completed == 0 && rhs.completed != 0) || (lhs.completed != 0 && rhs.completed == 0) {
            // One 0, one not 0
            return false
        } else {
            // Cross-multiply
            let left = lhs.completed.multipliedReportingOverflow(by: rhs.total)
            let right = lhs.total.multipliedReportingOverflow(by: rhs.completed)
            
            if !left.overflow && !right.overflow {
                if left.0 == right.0 {
                    return true
                }
            } else {
                // Try simplifying then cross multiply again
                let lhsSimplified = lhs.simplified()
                let rhsSimplified = rhs.simplified()
                
                let leftSimplified = lhsSimplified.completed.multipliedReportingOverflow(by: rhsSimplified.total)
                let rightSimplified = lhsSimplified.total.multipliedReportingOverflow(by: rhsSimplified.completed)

                if !leftSimplified.overflow && !rightSimplified.overflow {
                    if leftSimplified.0 == rightSimplified.0 {
                        return true
                    }
                } else {
                    // Ok... fallback to doubles. This doesn't use an epsilon
                    return lhs.fractionCompleted == rhs.fractionCompleted
                }
            }
        }
        
        return false
    }
    
    // ----
    
    internal var isIndeterminate : Bool {
        return completed < 0 || total < 0 || (completed == 0 && total == 0)
    }
    
    internal var isFinished : Bool {
        return ((completed >= total) && completed > 0 && total > 0) || (completed > 0 && total == 0)
    }
    
    internal var fractionCompleted : Double {
        if isIndeterminate {
            // Return something predictable
            return 0.0
        } else if total == 0 {
            // When there is nothing to do, you're always done
            return 1.0
        } else {
            return Double(completed) / Double(total)
        }
    }
    
    internal var isNaN : Bool {
        return total == 0
    }
    
    internal var debugDescription : String {
        return "\(completed) / \(total) (\(fractionCompleted))"
    }
    
    // ----
    
    private static func _fromDouble(_ d : Double) -> (Int64, Int64) {
        // This simplistic algorithm could someday be replaced with something better.
        // Basically - how many 1/Nths is this double?
        // And we choose to use 131072 for N
        let denominator : Int64 = 131072
        let numerator = Int64(d / (1.0 / Double(denominator)))
        return (numerator, denominator)
    }
    
    private static func _greatestCommonDivisor(_ inA : Int64, _ inB : Int64) -> Int64 {
        // This is Euclid's algorithm. There are faster ones, like Knuth, but this is the simplest one for now.
        var a = inA
        var b = inB
        repeat {
            let tmp = b
            b = a % b
            a = tmp
        } while (b != 0)
        return a
    }
    
    private static func _leastCommonMultiple(_ a : Int64, _ b : Int64) -> Int64? {
        // This division always results in an integer value because gcd(a,b) is a divisor of a.
        // lcm(a,b) == (|a|/gcd(a,b))*b == (|b|/gcd(a,b))*a
        let result = (a / _greatestCommonDivisor(a, b)).multipliedReportingOverflow(by: b)
        if result.overflow {
            return nil
        } else {
            return result.0
        }
    }
    
    private static func _simplify(_ n : Int64, _ d : Int64) -> (Int64, Int64) {
        let gcd = _greatestCommonDivisor(n, d)
        return (n / gcd, d / gcd)
    }
    
}
