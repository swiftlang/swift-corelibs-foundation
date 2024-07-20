// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestCase+Performance.swift
//  Methods on XCTestCase for testing the performance of code blocks.
//

public struct XCTPerformanceMetric : RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension XCTPerformanceMetric {
    /// Records wall clock time in seconds between `startMeasuring`/`stopMeasuring`.
    static let wallClockTime = XCTPerformanceMetric(rawValue: WallClockTimeMetric.name)
}

/// The following methods are called from within a test method to carry out 
/// performance testing on blocks of code.
public extension XCTestCase {

    /// The names of the performance metrics to measure when invoking `measure(block:)`. 
    /// Returns `XCTPerformanceMetric_WallClockTime` by default. Subclasses can
    /// override this to change the behavior of `measure(block:)`
    class var defaultPerformanceMetrics: [XCTPerformanceMetric] {
        return [.wallClockTime]
    }

    /// Call from a test method to measure resources (`defaultPerformanceMetrics`)
    /// used by the block in the current process.
    ///
    ///     func testPerformanceOfMyFunction() {
    ///         measure {
    ///             // Do that thing you want to measure.
    ///             MyFunction();
    ///         }
    ///     }
    ///
    /// - Parameter block: A block whose performance to measure.
    /// - Bug: The `block` param should have no external label, but there seems
    ///   to be a swiftc bug that causes issues when such a parameter comes
    ///   after a defaulted arg. See https://bugs.swift.org/browse/SR-1483 This
    ///   API incompatibility with Apple XCTest can be worked around in practice 
    ///   by using trailing closure syntax when calling this method.
    /// - Note: Whereas Apple XCTest determines the file and line number of
    ///   measurements by using symbolication, this implementation opts to take
    ///   `file` and `line` as parameters instead. As a result, the interface to
    ///   these methods are not exactly identical between these environments. To 
    ///   ensure compatibility of tests between swift-corelibs-xctest and Apple
    ///   XCTest, it is not recommended to pass explicit values for `file` and `line`.
    func measure(file: StaticString = #file, line: Int = #line, block: () -> Void) {
        measureMetrics(type(of: self).defaultPerformanceMetrics,
                       automaticallyStartMeasuring: true,
                       file: file,
                       line: line,
                       for: block)
    }

    /// Call from a test method to measure resources (XCTPerformanceMetrics) used
    /// by the block in the current process. Each metric will be measured across 
    /// calls to the block. The number of times the block will be called is undefined
    /// and may change in the future. For one example of why, as long as the requested
    /// performance metrics do not interfere with each other the API will measure 
    /// all metrics across the same calls to the block. If the performance metrics
    /// may interfere the API will measure them separately.
    ///
    ///     func testMyFunction2_WallClockTime() {
    ///         measureMetrics(type(of: self).defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
    ///
    ///             // Do setup work that needs to be done for every iteration but
    ///             // you don't want to measure before the call to `startMeasuring()`
    ///             SetupSomething();
    ///             self.startMeasuring()
    ///
    ///             // Do that thing you want to measure.
    ///             MyFunction()
    ///             self.stopMeasuring()
    ///
    ///             // Do teardown work that needs to be done for every iteration 
    ///             // but you don't want to measure after the call to `stopMeasuring()`
    ///             TeardownSomething()
    ///         }
    ///     }
    ///
    /// Caveats:
    /// * If `true` was passed for `automaticallyStartMeasuring` and `startMeasuring()`
    ///   is called anyway, the test will fail.
    /// * If `false` was passed for `automaticallyStartMeasuring` then `startMeasuring()`
    ///   must be called once and only once before the end of the block or the test will fail.
    /// * If `stopMeasuring()` is called multiple times during the block the test will fail.
    ///
    /// - Parameter metrics: An array of Strings (XCTPerformanceMetrics) to measure. 
    ///     Providing an unrecognized string is a test failure.
    /// - Parameter automaticallyStartMeasuring: If `false`, `XCTestCase` will 
    ///     not take any measurements until -startMeasuring is called.
    /// - Parameter block: A block whose performance to measure.
    /// - Note: Whereas Apple XCTest determines the file and line number of
    ///   measurements by using symbolication, this implementation opts to take
    ///   `file` and `line` as parameters instead. As a result, the interface to
    ///   these methods are not exactly identical between these environments. To
    ///   ensure compatibility of tests between swift-corelibs-xctest and Apple
    ///   XCTest, it is not recommended to pass explicit values for `file` and `line`.
    func measureMetrics(_ metrics: [XCTPerformanceMetric], automaticallyStartMeasuring: Bool, file: StaticString = #file, line: Int = #line, for block: () -> Void) {
        guard _performanceMeter == nil else {
            return recordAPIViolation(description: "Can only record one set of metrics per test method.", file: file, line: line)
        }

        PerformanceMeter.measureMetrics(metrics.map({ $0.rawValue }), delegate: self, file: file, line: line) { meter in
            self._performanceMeter = meter
            if automaticallyStartMeasuring {
                meter.startMeasuring(file: file, line: line)
            }
            block()
        }
    }

    /// Call this from within a measure block to set the beginning of the critical 
    /// section. Measurement of metrics will start at this point.
    /// - Note: Whereas Apple XCTest determines the file and line number of
    ///   measurements by using symbolication, this implementation opts to take
    ///   `file` and `line` as parameters instead. As a result, the interface to
    ///   these methods are not exactly identical between these environments. To
    ///   ensure compatibility of tests between swift-corelibs-xctest and Apple
    ///   XCTest, it is not recommended to pass explicit values for `file` and `line`.
    func startMeasuring(file: StaticString = #file, line: Int = #line) {
        guard let performanceMeter = _performanceMeter, !performanceMeter.didFinishMeasuring else {
            return recordAPIViolation(description: "Cannot start measuring. startMeasuring() is only supported from a block passed to measureMetrics(...).", file: file, line: line)
        }
        performanceMeter.startMeasuring(file: file, line: line)
    }

    /// Call this from within a measure block to set the ending of the critical 
    /// section. Measurement of metrics will stop at this point.
    /// - Note: Whereas Apple XCTest determines the file and line number of
    ///   measurements by using symbolication, this implementation opts to take
    ///   `file` and `line` as parameters instead. As a result, the interface to
    ///   these methods are not exactly identical between these environments. To
    ///   ensure compatibility of tests between swift-corelibs-xctest and Apple
    ///   XCTest, it is not recommended to pass explicit values for `file` and `line`.
    func stopMeasuring(file: StaticString = #file, line: Int = #line) {
        guard let performanceMeter = _performanceMeter, !performanceMeter.didFinishMeasuring else {
            return recordAPIViolation(description: "Cannot stop measuring. stopMeasuring() is only supported from a block passed to measureMetrics(...).", file: file, line: line)
        }
        performanceMeter.stopMeasuring(file: file, line: line)
    }
}

extension XCTestCase: PerformanceMeterDelegate {
    internal func recordAPIViolation(description: String, file: StaticString, line: Int) {
        recordFailure(withDescription: "API violation - \(description)",
                      inFile: String(describing: file),
                      atLine: line,
                      expected: false)
    }

    internal func recordMeasurements(results: String, file: StaticString, line: Int) {
        XCTestObservationCenter.shared.testCase(self, didMeasurePerformanceResults: results, file: file, line: line)
    }

    internal func recordFailure(description: String, file: StaticString, line: Int) {
        recordFailure(withDescription: "failed: " + description, inFile: String(describing: file), atLine: line, expected: true)
    }
}
