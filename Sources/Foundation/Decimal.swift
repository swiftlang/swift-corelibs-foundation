// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_spi(SwiftCorelibsFoundation) import FoundationEssentials

// MARK: - Bridging

extension Decimal : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDecimalNumber {
        return NSDecimalNumber(decimal: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSDecimalNumber, result: inout Decimal?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSDecimalNumber, result: inout Decimal?) -> Bool {
        result = input.decimalValue
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDecimalNumber?) -> Decimal {
        guard let src = source else {
            return Decimal()
        }
        return src.decimalValue
    }
}

// MARK: - C Functions

public func NSDecimalAdd(_ result: UnsafeMutablePointer<Decimal>, _ lhs: UnsafePointer<Decimal>, _ rhs: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalAdd(result, lhs, rhs, roundingMode)
}

public func NSDecimalSubtract(_ result: UnsafeMutablePointer<Decimal>, _ lhs: UnsafePointer<Decimal>, _ rhs: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalSubtract(result, lhs, rhs, roundingMode)
}

public func NSDecimalMultiply(_ result: UnsafeMutablePointer<Decimal>, _ lhs: UnsafePointer<Decimal>, _ rhs: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalMultiply(result, lhs, rhs, roundingMode)
}

public func NSDecimalDivide(_ result: UnsafeMutablePointer<Decimal>, _ lhs: UnsafePointer<Decimal>, _ rhs: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalDivide(result, lhs, rhs, roundingMode)
}

public func NSDecimalPower(_ result: UnsafeMutablePointer<Decimal>, _ decimal: UnsafePointer<Decimal>, _ exponent: Int, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalPower(result, decimal, exponent, roundingMode)
}

public func NSDecimalMultiplyByPowerOf10(_ result: UnsafeMutablePointer<Decimal>, _ decimal: UnsafePointer<Decimal>, _ power: CShort, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalMultiplyByPowerOf10(result, decimal, power, roundingMode)
}

public func NSDecimalCompare(_ lhs: UnsafePointer<Decimal>, _ rhs: UnsafePointer<Decimal>) -> ComparisonResult {
    _NSDecimalCompare(lhs, rhs)
}

public func NSDecimalRound(_ result: UnsafeMutablePointer<Decimal>, _ decimal: UnsafePointer<Decimal>, _ scale: Int, _ roundingMode: Decimal.RoundingMode) {
    _NSDecimalRound(result, decimal, scale, roundingMode)
}

public func NSDecimalNormalize(_ lhs: UnsafeMutablePointer<Decimal>, _ rhs: UnsafeMutablePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError {
    _NSDecimalNormalize(lhs, rhs, roundingMode)
}

public func NSDecimalIsNotANumber(_ dcm: UnsafePointer<Decimal>) -> Bool {
    return dcm.pointee.isNaN
}

public func NSDecimalCopy(_ destination: UnsafeMutablePointer<Decimal>, _ source: UnsafePointer<Decimal>) {
    destination.pointee = source.pointee
}

public func NSDecimalCompact(_ number: UnsafeMutablePointer<Decimal>) {
    _NSDecimalCompact(number)
}

public func NSDecimalString(_ dcm: UnsafePointer<Decimal>, _ locale: Any?) -> String {
    _NSDecimalString(dcm, locale)
}

public func NSStringToDecimal(_ string: String, processedLength: UnsafeMutablePointer<Int>, result: UnsafeMutablePointer<Decimal>) {
    _NSStringToDecimal(string, processedLength: processedLength, result: result)
}

// MARK: - Scanner

// Could be silently inexact for float and double.
extension Scanner {

    public func scanDecimal(_ dcm: inout Decimal) -> Bool {
        if let result = scanDecimal() {
            dcm = result
            return true
        } else {
            return false
        }
    }
    
    public func scanDecimal() -> Decimal? {
        let string = self._scanString
        
        guard let start = string.index(string.startIndex, offsetBy: _scanLocation, limitedBy: string.endIndex) else {
            return nil
        }
        let substring = string[start..<string.endIndex]
        let view = String(substring).utf8

        let (result, length) = Decimal.decimal(from: view, decimalSeparator: ".".utf8, matchEntireString: false)
        
        _scanLocation = _scanLocation + length
        return result
    }

    // Copied from Scanner.swift
    private func decimalValue(_ ch: unichar) -> UInt16? {
        guard let s = UnicodeScalar(ch), s.isASCII else { return nil }
        guard let value = Character(s).wholeNumberValue else { return nil }
        return UInt16(value)
    }
}
