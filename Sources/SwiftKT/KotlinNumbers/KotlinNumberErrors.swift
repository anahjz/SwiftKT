//
//  KotlinNumberErrors.swift
//  SwiftKT
//
//  Errors used to mirror Kotlin Number/Math exception behavior in a Swifty way.
//

import Foundation

/// Errors that correspond to Kotlin numeric and parsing exceptions when using the Kotlin Number API surface.
public enum KotlinNumberError: Error, Sendable {

    /// Thrown when a radix is outside the valid Kotlin range 2...36 (Kotlin: `IllegalArgumentException`).
    case invalidRadix(_ radix: Int)

    /// Thrown when a string cannot be parsed as a number for a *non-nullable* Kotlin parsing call
    /// (e.g. `String.toInt()`), or when the parsed value overflows the target type
    /// (Kotlin: `NumberFormatException`).
    case invalidFormat(_ value: String)

    /// Thrown when arguments to coercion APIs are invalid (e.g. `coerceIn(min, max)` with `min > max`)
    /// (Kotlin: `IllegalArgumentException`).
    case invalidRange(min: String, max: String)

    /// Thrown when a rounding operation cannot produce a result, e.g. `roundToInt()` on NaN
    /// (Kotlin: `IllegalArgumentException` from kotlin.math).
    case invalidRoundingOperand(_ value: String)
}

