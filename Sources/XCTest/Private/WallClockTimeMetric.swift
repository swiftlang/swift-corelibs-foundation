// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  WallClockTimeMetric.swift
//  Performance metric measuring how long it takes code to execute
//

/// This metric uses the system uptime to keep track of how much time passes
/// between starting and stopping measuring.
internal final class WallClockTimeMetric: PerformanceMetric {
    static let name = "org.swift.XCTPerformanceMetric_WallClockTime"

    typealias Measurement = TimeInterval
    private var startTime: TimeInterval?
    var measurements: [Measurement] = []

    func startMeasuring() {
        startTime = currentTime()
    }

    func stopMeasuring() {
        guard let startTime = startTime else { fatalError("Must start measuring before stopping measuring") }
        let stopTime = currentTime()
        measurements.append(stopTime-startTime)
    }

    private let maxRelativeStandardDeviation = 10.0
    private let standardDeviationNegligibilityThreshold = 0.1

    func calculateResults() -> String {
        let results = [
                          String(format: "average: %.3f", measurements.average),
                          String(format: "relative standard deviation: %.3f%%", measurements.relativeStandardDeviation),
                          "values: [\(measurements.map({ String(format: "%.6f", $0) }).joined(separator: ", "))]",
                          "performanceMetricID:\(type(of: self).name)",
                          String(format: "maxPercentRelativeStandardDeviation: %.3f%%", maxRelativeStandardDeviation),
                          String(format: "maxStandardDeviation: %.3f", standardDeviationNegligibilityThreshold),
                          ]
        return "[Time, seconds] \(results.joined(separator: ", "))"
    }

    func failureMessage() -> String? {
        let relativeStandardDeviation = measurements.relativeStandardDeviation
        if (relativeStandardDeviation > maxRelativeStandardDeviation &&
            measurements.standardDeviation > standardDeviationNegligibilityThreshold) {
            return String(format: "The relative standard deviation of the measurements is %.3f%% which is higher than the max allowed of %.3f%%.", relativeStandardDeviation, maxRelativeStandardDeviation)
        }

        return nil
    }

    private func currentTime() -> TimeInterval {
        return ProcessInfo.processInfo.systemUptime
    }
}


private extension Collection where Index: ExpressibleByIntegerLiteral, Iterator.Element == WallClockTimeMetric.Measurement {
    var average: WallClockTimeMetric.Measurement {
        return self.reduce(0, +) / Double(Int(count))
    }

    var standardDeviation: WallClockTimeMetric.Measurement {
        let average = self.average
        let squaredDifferences = self.map({ pow($0 - average, 2.0) })
        let variance = squaredDifferences.reduce(0, +) / Double(Int(count-1))
        return sqrt(variance)
    }

    var relativeStandardDeviation: Double {
        return (standardDeviation*100) / average
    }
}
