// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  PerformanceMeter.swift
//  Measures the performance of a block of code and reports the results.
//

/// Describes a type that is capable of measuring some aspect of code performance
/// over time.
internal protocol PerformanceMetric {
    /// Called once per iteration immediately before the tested code is executed. 
    /// The metric should do whatever work is required to begin a new measurement.
    func startMeasuring()

    /// Called once per iteration immediately after the tested code is executed.
    /// The metric should do whatever work is required to finalize measurement.
    func stopMeasuring()

    /// Called once, after all measurements have been taken, to provide feedback
    /// about the collected measurements.
    /// - Returns: Measurement results to present to the user.
    func calculateResults() -> String

    /// Called once, after all measurements have been taken, to determine whether
    /// the measurements should be treated as a test failure or not.
    /// - Returns: A diagnostic message if the results indicate failure, else nil.
    func failureMessage() -> String?
}

/// Protocol used by `PerformanceMeter` to report measurement results
internal protocol PerformanceMeterDelegate {
    /// Reports a string representation of the gathered performance metrics
    /// - Parameter results: The raw measured values, and some derived data such
    ///   as average, and standard deviation
    /// - Parameter file: The source file name where the measurement was invoked
    /// - Parameter line: The source line number where the measurement was invoked
    func recordMeasurements(results: String, file: StaticString, line: Int)

    /// Reports a test failure from the analysis of performance measurements.
    /// This can currently be caused by an unexpectedly large standard deviation
    /// calculated over the data.
    /// - Parameter description: An explanation of the failure
    /// - Parameter file: The source file name where the measurement was invoked
    /// - Parameter line: The source line number where the measurement was invoked
    func recordFailure(description: String, file: StaticString, line: Int)

    /// Reports a misuse of the `PerformanceMeter` API, such as calling `
    /// startMeasuring` multiple times.
    /// - Parameter description: An explanation of the misuse
    /// - Parameter file: The source file name where the misuse occurred
    /// - Parameter line: The source line number where the misuse occurred
    func recordAPIViolation(description: String, file: StaticString, line: Int)
}

/// - Bug: This class is intended to be `internal` but is public to work around
/// a toolchain bug on Linux. See `XCTestCase._performanceMeter` for more info.
public final class PerformanceMeter {
    enum Error: Swift.Error, CustomStringConvertible {
        case noMetrics
        case unknownMetric(metricName: String)
        case startMeasuringAlreadyCalled
        case stopMeasuringAlreadyCalled
        case startMeasuringNotCalled
        case stopBeforeStarting

        var description: String {
            switch self {
            case .noMetrics: return "At least one metric must be provided to measure."
            case .unknownMetric(let name): return "Unknown metric: \(name)"
            case .startMeasuringAlreadyCalled: return "Already called startMeasuring() once this iteration."
            case .stopMeasuringAlreadyCalled: return "Already called stopMeasuring() once this iteration."
            case .startMeasuringNotCalled: return "startMeasuring() must be called during the block."
            case .stopBeforeStarting: return "Cannot stop measuring before starting measuring."
            }
        }
    }

    internal var didFinishMeasuring: Bool {
        return state == .measurementFinished || state == .measurementAborted
    }

    private enum State {
        case iterationUnstarted
        case iterationStarted
        case iterationFinished
        case measurementFinished
        case measurementAborted
    }
    private var state: State = .iterationUnstarted

    private let metrics: [PerformanceMetric]
    private let delegate: PerformanceMeterDelegate
    private let invocationFile: StaticString
    private let invocationLine: Int

    private init(metrics: [PerformanceMetric], delegate: PerformanceMeterDelegate, file: StaticString, line: Int) {
        self.metrics = metrics
        self.delegate = delegate
        self.invocationFile = file
        self.invocationLine = line
    }

    static func measureMetrics(_ metricNames: [String], delegate: PerformanceMeterDelegate, file: StaticString = #file, line: Int = #line, for block: (PerformanceMeter) -> Void) {
        do {
            let metrics = try self.metrics(forNames: metricNames)
            let meter = PerformanceMeter(metrics: metrics, delegate: delegate, file: file, line: line)
            meter.measure(block)
        } catch let e {
            delegate.recordAPIViolation(description: String(describing: e), file: file, line: line)
        }
    }

    func startMeasuring(file: StaticString = #file, line: Int = #line) {
        guard state == .iterationUnstarted else {
            return recordAPIViolation(.startMeasuringAlreadyCalled, file: file, line: line)
        }
        state = .iterationStarted
        metrics.forEach { $0.startMeasuring() }
    }

    func stopMeasuring(file: StaticString = #file, line: Int = #line) {
        guard state != .iterationUnstarted else {
            return recordAPIViolation(.stopBeforeStarting, file: file, line: line)
        }

        guard state != .iterationFinished else {
            return recordAPIViolation(.stopMeasuringAlreadyCalled, file: file, line: line)
        }

        state = .iterationFinished
        metrics.forEach { $0.stopMeasuring() }
    }

    func abortMeasuring() {
        state = .measurementAborted
    }


    private static func metrics(forNames names: [String]) throws -> [PerformanceMetric] {
        guard !names.isEmpty else { throw Error.noMetrics }

        let metricsMapping = [WallClockTimeMetric.name : WallClockTimeMetric.self]

        return try names.map({
            guard let metricType = metricsMapping[$0] else { throw Error.unknownMetric(metricName: $0) }
            return metricType.init()
        })
    }

    private var numberOfIterations: Int {
        return 10
    }

    private func measure(_ block: (PerformanceMeter) -> Void) {
        for _ in (0..<numberOfIterations) {
            state = .iterationUnstarted

            block(self)
            stopMeasuringIfNeeded()

            if state == .measurementAborted { return }

            if state == .iterationUnstarted {
                recordAPIViolation(.startMeasuringNotCalled, file: invocationFile, line: invocationLine)
                return
            }
        }
        state = .measurementFinished

        recordResults()
        recordFailures()
    }

    private func stopMeasuringIfNeeded() {
        if state == .iterationStarted {
            stopMeasuring(file: invocationFile, line: invocationLine)
        }
    }

    private func recordResults() {
        for metric in metrics {
            delegate.recordMeasurements(results: metric.calculateResults(), file: invocationFile, line: invocationLine)
        }
    }

    private func recordFailures() {
        metrics.compactMap({ $0.failureMessage() }).forEach { message in
            delegate.recordFailure(description: message, file: invocationFile, line: invocationLine)
        }
    }

    private func recordAPIViolation(_ error: Error, file: StaticString, line: Int) {
        state = .measurementAborted
        delegate.recordAPIViolation(description: String(describing: error), file: file, line: line)
    }
}
