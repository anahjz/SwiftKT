//
//  KotlinStringNumberParsing.swift
//  SwiftKT
//
//  Numeric parsing APIs on `KotlinStringProxy` that mirror Kotlin's `String.toInt()`,
//  `String.toIntOrNull()`, `String.toLong()`, etc.
//

import Foundation

// MARK: - Internal helpers

enum KotlinIntegerParseMode {
    case strict      // throw on invalid format
    case orNull      // return nil on invalid format
}

/// Parse a signed integer string using Kotlin-like semantics.
///
/// - Parameters:
///   - string: Source string (no trimming is performed; Kotlin does not trim).
///   - radix: Base in 2...36. Throws on invalid radix.
///   - mode: Whether to throw on invalid format (`strict`) or return nil (`orNull`).
internal func kotlinParseInteger<T>(
    _ string: String,
    radix: Int,
    mode: KotlinIntegerParseMode
) throws -> T? where T: FixedWidthInteger & SignedInteger {
    guard (2...36).contains(radix) else {
        throw KotlinNumberError.invalidRadix(radix)
    }

    if string.isEmpty {
        switch mode {
        case .strict:
            throw KotlinNumberError.invalidFormat(string)
        case .orNull:
            return nil
        }
    }

    var index = string.startIndex
    var isNegative = false

    let first = string[index]
    if first == "-" {
        isNegative = true
        index = string.index(after: index)
    } else if first == "+" {
        index = string.index(after: index)
    }

    if index == string.endIndex {
        switch mode {
        case .strict:
            throw KotlinNumberError.invalidFormat(string)
        case .orNull:
            return nil
        }
    }

    let zeroScalar = UnicodeScalar("0").value
    let aScalar = UnicodeScalar("a").value
    let AScalar = UnicodeScalar("A").value

    var result = T(0)
    let radixT = T(radix)

    while index < string.endIndex {
        let scalar = string[index].unicodeScalars.first!
        let value: Int

        let v = scalar.value
        if v >= zeroScalar && v <= zeroScalar + 9 {
            value = Int(v - zeroScalar)
        } else if v >= AScalar && v <= AScalar + 25 {
            value = Int(v - AScalar) + 10
        } else if v >= aScalar && v <= aScalar + 25 {
            value = Int(v - aScalar) + 10
        } else {
            switch mode {
            case .strict:
                throw KotlinNumberError.invalidFormat(string)
            case .orNull:
                return nil
            }
        }

        if value >= radix {
            switch mode {
            case .strict:
                throw KotlinNumberError.invalidFormat(string)
            case .orNull:
                return nil
            }
        }

        // Detect overflow by checking before multiplying/adding.
        // Kotlin on JVM wraps; here we treat overflow as invalid format for strict parsing.
        let digit = T(value)

        let multiplied = result.multipliedReportingOverflow(by: radixT)
        if multiplied.overflow {
            switch mode {
            case .strict:
                throw KotlinNumberError.invalidFormat(string)
            case .orNull:
                return nil
            }
        }

        let added = multiplied.partialValue.addingReportingOverflow(digit)
        if added.overflow {
            switch mode {
            case .strict:
                throw KotlinNumberError.invalidFormat(string)
            case .orNull:
                return nil
            }
        }

        result = added.partialValue
        index = string.index(after: index)
    }

    return isNegative ? -result : result
}

// MARK: - KotlinStringProxy numeric parsing

extension KotlinStringProxy {

    // MARK: Int

    /// Kotlin: `String.toInt()`
    ///
    /// - Throws: `KotlinNumberError.invalidFormat` for malformed numbers or overflow,
    ///           `KotlinNumberError.invalidRadix` for invalid radix.
    public func toInt(radix: Int = 10) throws -> Int {
        guard let value: Int = try kotlinParseInteger(base, radix: radix, mode: .strict) else {
            // Strict mode never returns nil; this is a safety net.
            throw KotlinNumberError.invalidFormat(base)
        }
        return value
    }

    /// Kotlin: `String.toIntOrNull()`
    ///
    /// Returns `nil` for malformed numbers or overflow, but still throws
    /// `KotlinNumberError.invalidRadix` for invalid radix to mirror Kotlin behavior.
    public func toIntOrNull(radix: Int = 10) throws -> Int? {
        try kotlinParseInteger(base, radix: radix, mode: .orNull)
    }

    // MARK: Long

    /// Kotlin: `String.toLong()`
    public func toLong(radix: Int = 10) throws -> Int64 {
        guard let value: Int64 = try kotlinParseInteger(base, radix: radix, mode: .strict) else {
            throw KotlinNumberError.invalidFormat(base)
        }
        return value
    }

    /// Kotlin: `String.toLongOrNull()`
    public func toLongOrNull(radix: Int = 10) throws -> Int64? {
        try kotlinParseInteger(base, radix: radix, mode: .orNull)
    }

    // MARK: Double / Float

    /// Kotlin: `String.toDouble()`
    public func toDouble() throws -> Double {
        guard let value = Double(base) else {
            throw KotlinNumberError.invalidFormat(base)
        }
        return value
    }

    /// Kotlin: `String.toDoubleOrNull()`
    public func toDoubleOrNull() -> Double? {
        Double(base)
    }

    /// Kotlin: `String.toFloat()`
    public func toFloat() throws -> Float {
        guard let value = Float(base) else {
            throw KotlinNumberError.invalidFormat(base)
        }
        return value
    }

    /// Kotlin: `String.toFloatOrNull()`
    public func toFloatOrNull() -> Float? {
        Float(base)
    }
}

