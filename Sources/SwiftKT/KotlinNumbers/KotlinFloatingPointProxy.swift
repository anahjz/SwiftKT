//
//  KotlinFloatingPointProxy.swift
//  SwiftKT
//
//  Entry point: BinaryFloatingPoint.kotlin provides the Kotlin Number API surface
//  for floating-point types (Double, Float).
//

import Foundation

// MARK: - BinaryFloatingPoint extension

extension BinaryFloatingPoint {

    /// Provides the Kotlin-style numeric API surface for floating-point types.
    ///
    /// Example:
    /// ```swift
    /// let value: Double = 3.14
    /// value.kotlin.toInt()        // 3
    /// value.kotlin.roundToInt()   // 3
    /// value.kotlin.isFinite()     // true
    /// ```
    public var kotlin: KotlinFloatingPointProxy<Self> {
        KotlinFloatingPointProxy(self)
    }
}

// MARK: - KotlinFloatingPointProxy

/// Proxy type that exposes Kotlin-style Number APIs for floating-point types.
///
/// The generic `T` typically corresponds to:
/// - `Double` (Kotlin: `Double`)
/// - `Float`  (Kotlin: `Float`)
public struct KotlinFloatingPointProxy<T: BinaryFloatingPoint>: Sendable {

    internal let base: T

    internal init(_ base: T) {
        self.base = base
    }
}

// MARK: - Conversions: floating point to integral

extension KotlinFloatingPointProxy {

    /// Kotlin: `toByte()`
    ///
    /// Semantics:
    /// - Truncates toward zero.
    /// - NaN maps to 0.
    /// - Out-of-range values are clamped to `Int8.min` / `Int8.max`.
    public func toByte() -> Int8 {
        convertToIntegral(Int8.self)
    }

    /// Kotlin: `toShort()`
    public func toShort() -> Int16 {
        convertToIntegral(Int16.self)
    }

    /// Kotlin: `toInt()`
    public func toInt() -> Int {
        convertToIntegral(Int.self)
    }

    /// Kotlin: `toLong()`
    public func toLong() -> Int64 {
        convertToIntegral(Int64.self)
    }

    /// Kotlin: `toUInt()` (where applicable).
    public func toUInt() -> UInt {
        convertToUnsignedIntegral(UInt.self)
    }

    /// Kotlin: `toULong()` (where applicable).
    public func toULong() -> UInt64 {
        convertToUnsignedIntegral(UInt64.self)
    }

    private func convertToIntegral<I: FixedWidthInteger & SignedInteger>(_ type: I.Type) -> I {
        if base.isNaN {
            return 0
        }
        let minValue = T(I.min)
        let maxValue = T(I.max)
        if base <= minValue {
            return I.min
        }
        if base >= maxValue {
            return I.max
        }
        // Swift's integer-from-float conversion truncates toward zero, matching Kotlin.
        return I(base)
    }

    private func convertToUnsignedIntegral<U: FixedWidthInteger & UnsignedInteger>(_ type: U.Type) -> U {
        if base.isNaN || base <= 0 {
            return 0
        }
        let maxValue = T(U.max)
        if base >= maxValue {
            return U.max
        }
        return U(base)
    }
}

// MARK: - Conversions: floating point to floating point

extension KotlinFloatingPointProxy {

    /// Kotlin: `toFloat()` (on Double).
    public func toFloat() -> Float {
        Float(base)
    }

    /// Kotlin: `toDouble()` (on Float).
    public func toDouble() -> Double {
        Double(base)
    }
}

// MARK: - Comparison, equality, and hashing

extension KotlinFloatingPointProxy where T: Comparable {

    /// Kotlin: `compareTo(other)`
    ///
    /// Mirrors Kotlin/Java's `Double.compare` / `Float.compare` semantics as closely as practical:
    /// - Regular finite values are ordered by magnitude.
    /// - NaN is considered greater than all other numeric values.
    /// - Two NaN values compare as equal (0).
    public func compareTo(_ other: T) -> Int {
        let a = base
        let b = other

        let aNaN = a.isNaN
        let bNaN = b.isNaN

        if aNaN || bNaN {
            if aNaN && bNaN { return 0 }
            return aNaN ? 1 : -1
        }

        if a < b { return -1 }
        if a > b { return 1 }
        return 0
    }

    /// Kotlin: `equals(other)`
    ///
    /// Uses Swift's `==` which follows IEEE 754 semantics for primitives.
    public func equals(_ other: T) -> Bool {
        base == other
    }

    /// Kotlin: `hashCode()`
    ///
    /// Uses Swift's `hashValue` as the integer hash code; NaN values with different
    /// payloads may produce different hashes, which we document as a difference.
    public func hashCode() -> Int {
        base.hashValue
    }
}

// MARK: - Floating-point predicates

extension KotlinFloatingPointProxy {

    /// Kotlin: `isNaN()`
    public func isNaN() -> Bool {
        base.isNaN
    }

    /// Kotlin: `isInfinite()`
    public func isInfinite() -> Bool {
        base.isInfinite
    }

    /// Kotlin: `isFinite()`
    public func isFinite() -> Bool {
        base.isFinite
    }
}

// MARK: - Floating-point math helpers

extension KotlinFloatingPointProxy {

    /// Kotlin: `absoluteValue`
    public var absoluteValue: T {
        base.magnitude
    }

    /// Kotlin: `sign`
    ///
    /// Returns:
    /// - `-1.0` if value is negative
    /// - `0.0`  if value is zero
    /// - `1.0`  if value is positive
    /// - NaN    if the value is NaN (mirroring Kotlin `sign` for NaN).
    public var sign: T {
        if base.isNaN {
            return base
        }
        if base == 0 {
            return 0
        }
        return base < 0 ? -1 : 1
    }

    /// Kotlin: `roundToInt()`
    ///
    /// Semantics:
    /// - Rounds to the nearest Int using Kotlin's `roundToInt` rules:
    ///   - Ties (x.5) round toward positive infinity.
    /// - NaN throws `KotlinNumberError.invalidRoundingOperand`.
    /// - ±infinity clamp to `Int.max` / `Int.min`.
    /// - Values outside the Int range clamp to `Int.max` / `Int.min`.
    public func roundToInt() throws -> Int {
        try roundToIntegral(Int.self)
    }

    /// Kotlin: `roundToLong()`
    public func roundToLong() throws -> Int64 {
        try roundToIntegral(Int64.self)
    }

    private func roundToIntegral<I: FixedWidthInteger & SignedInteger>(_ type: I.Type) throws -> I {
        // Perform rounding in Double space to mirror Java's Math.round behavior:
        // round(x) = floor(x + 0.5), which rounds ties toward +∞.
        let d = Double(base)

        if d.isNaN {
            throw KotlinNumberError.invalidRoundingOperand(String(describing: base))
        }
        if d == .infinity {
            return I.max
        }
        if d == -.infinity {
            return I.min
        }

        let rounded = floor(d + 0.5)

        let minValue = Double(I.min)
        let maxValue = Double(I.max)
        if rounded <= minValue {
            return I.min
        }
        if rounded >= maxValue {
            return I.max
        }
        return I(rounded)
    }
}

