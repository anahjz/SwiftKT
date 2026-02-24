//
//  KotlinNumberProxy.swift
//  SwiftKT
//
//  Entry point: BinaryInteger.kotlin provides the Kotlin Number API surface
//  for integer-like types (Int, Int64, Int32, Int16, Int8, UInt*, etc.).
//

import Foundation

// MARK: - BinaryInteger extension

extension BinaryInteger {

    /// Provides the Kotlin-style numeric API surface for integer types.
    ///
    /// Example:
    /// ```swift
    /// let value: Int = 42
    /// value.kotlin.toLong()     // Int64(42)
    /// value.kotlin.toString(16) // "2a"
    /// value.kotlin.coerceIn(min: 0, max: 10) // 10
    /// ```
    public var kotlin: KotlinNumberProxy<Self> {
        KotlinNumberProxy(self)
    }
}

// MARK: - KotlinNumberProxy

/// Proxy type that exposes Kotlin-style Number APIs for integer types.
///
/// The generic `T` typically corresponds to one of:
/// - `Int`   (Kotlin: `Int`)
/// - `Int64` (Kotlin: `Long`)
/// - `Int32` (platform/interop)
/// - `Int16` (Kotlin: `Short`)
/// - `Int8`  (Kotlin: `Byte`)
/// - Unsigned variants like `UInt`, `UInt64`, etc. where Kotlin has unsigned types.
public struct KotlinNumberProxy<T: BinaryInteger>: Sendable {

    /// Underlying integer value.
    internal let base: T

    internal init(_ base: T) {
        self.base = base
    }
}

// MARK: - Conversions: integral to integral

extension KotlinNumberProxy {

    /// Kotlin: `toByte()`
    ///
    /// Uses two's-complement truncation semantics to match Kotlin/JVM narrowing conversions.
    public func toByte() -> Int8 {
        Int8(truncatingIfNeeded: base)
    }

    /// Kotlin: `toShort()`
    ///
    /// Uses two's-complement truncation semantics to match Kotlin/JVM narrowing conversions.
    public func toShort() -> Int16 {
        Int16(truncatingIfNeeded: base)
    }

    /// Kotlin: `toInt()`
    ///
    /// For types that already use `Int` as their Swift representation this is effectively an identity.
    /// For wider or narrower types this uses truncating semantics to mirror Kotlin/JVM behavior.
    public func toInt() -> Int {
        Int(truncatingIfNeeded: base)
    }

    /// Kotlin: `toLong()`
    ///
    /// Maps Kotlin `Long` semantics to Swift `Int64` using truncating semantics for narrower types.
    public func toLong() -> Int64 {
        Int64(truncatingIfNeeded: base)
    }

    /// Kotlin: `toUInt()` (where applicable).
    ///
    /// Uses truncating semantics to mirror Kotlin's unsigned widening/narrowing behavior.
    public func toUInt() -> UInt {
        UInt(truncatingIfNeeded: base)
    }

    /// Kotlin: `toULong()` (where applicable).
    ///
    /// Uses truncating semantics to mirror Kotlin's unsigned widening/narrowing behavior.
    public func toULong() -> UInt64 {
        UInt64(truncatingIfNeeded: base)
    }
}

// MARK: - Conversions: integral to floating point

extension KotlinNumberProxy {

    /// Kotlin: `toFloat()`
    ///
    /// Uses the Swift standard library conversion, which matches Kotlin/JVM semantics
    /// for all finite values representable in `Float`.
    public func toFloat() -> Float {
        Float(base)
    }

    /// Kotlin: `toDouble()`
    ///
    /// Uses the Swift standard library conversion, which matches Kotlin/JVM semantics
    /// for all finite values representable in `Double`.
    public func toDouble() -> Double {
        Double(base)
    }
}

// MARK: - String representations

extension KotlinNumberProxy {

    /// Kotlin: `toString()`
    ///
    /// Uses base-10 representation, matching Kotlin's default.
    public func toString() -> String {
        String(base)
    }

    /// Kotlin: `toString(radix: Int)`
    ///
    /// - Parameter radix: The base in which to render the number. Must be in `2...36`.
    /// - Throws: `KotlinNumberError.invalidRadix` if the radix is out of range.
    public func toString(radix: Int) throws -> String {
        guard (2...36).contains(radix) else {
            throw KotlinNumberError.invalidRadix(radix)
        }

        if base == 0 {
            return "0"
        }

        let isNegative = T.isSigned && base < 0
        let magnitude: T.Magnitude = isNegative ? base.magnitude : base.magnitude

        var value = magnitude
        var digits: [UInt8] = []
        digits.reserveCapacity(32)

        let radixMagnitude = T.Magnitude(radix)
        let zeroChar = UInt8(UnicodeScalar("0").value)
        let aChar = UInt8(UnicodeScalar("a").value)

        while value > 0 {
            let (quotient, remainder) = value.quotientAndRemainder(dividingBy: radixMagnitude)
            let digit = Int(remainder)
            let ascii: UInt8
            if digit < 10 {
                ascii = zeroChar &+ UInt8(digit)
            } else {
                ascii = aChar &+ UInt8(digit - 10)
            }
            digits.append(ascii)
            value = quotient
        }

        if isNegative {
            digits.append(UInt8(UnicodeScalar("-").value))
        }

        // digits were collected least-significant first; reverse to produce the final string.
        digits.reverse()

        return String(bytes: digits, encoding: .utf8) ?? String(base)
    }
}

// MARK: - Comparison, equality, and hashing

extension KotlinNumberProxy where T: Comparable {

    /// Kotlin: `compareTo(other)`
    ///
    /// Returns:
    /// - `< 0` if `self < other`
    /// - `0`  if `self == other`
    /// - `> 0` if `self > other`
    public func compareTo(_ other: T) -> Int {
        if base < other { return -1 }
        if base > other { return 1 }
        return 0
    }

    /// Kotlin: `equals(other)`
    ///
    /// For numbers this is value equality.
    public func equals(_ other: T) -> Bool {
        base == other
    }

    /// Kotlin: `hashCode()`
    ///
    /// Uses Swift's `hashValue` as the integer hash code. Note that `hashValue`
    /// is not guaranteed to be stable across process launches, which differs from
    /// Kotlin/JVM's stable `hashCode()`; see documentation for details.
    public func hashCode() -> Int {
        base.hashValue
    }
}

// MARK: - Coercion helpers

extension KotlinNumberProxy where T: Comparable {

    /// Kotlin: `coerceAtLeast(min)`
    public func coerceAtLeast(_ minimumValue: T) -> T {
        base < minimumValue ? minimumValue : base
    }

    /// Kotlin: `coerceAtMost(max)`
    public func coerceAtMost(_ maximumValue: T) -> T {
        base > maximumValue ? maximumValue : base
    }

    /// Kotlin: `coerceIn(min, max)`
    ///
    /// - Throws: `KotlinNumberError.invalidRange` if `min > max`, matching Kotlin's
    ///           `IllegalArgumentException` behavior.
    public func coerceIn(min minimumValue: T, max maximumValue: T) throws -> T {
        guard minimumValue <= maximumValue else {
            throw KotlinNumberError.invalidRange(
                min: String(describing: minimumValue),
                max: String(describing: maximumValue)
            )
        }
        if base < minimumValue { return minimumValue }
        if base > maximumValue { return maximumValue }
        return base
    }
}

// MARK: - Bitwise operations (integer-only)

extension KotlinNumberProxy where T: FixedWidthInteger {

    /// Kotlin: `and(other)`
    public func and(_ other: T) -> T {
        base & other
    }

    /// Kotlin: `or(other)`
    public func or(_ other: T) -> T {
        base | other
    }

    /// Kotlin: `xor(other)`
    public func xor(_ other: T) -> T {
        base ^ other
    }

    /// Kotlin: `inv()`
    ///
    /// Bitwise inversion (two's complement).
    public func inv() -> T {
        ~base
    }

    /// Kotlin: `shl(bitCount)`
    ///
    /// Left shift. Kotlin masks the shift distance by the bit-width of the type;
    /// we mirror this behavior using `& (bitWidth - 1)`.
    public func shl(_ bitCount: Int) -> T {
        let masked = bitMaskShift(bitCount)
        return base << masked
    }

    /// Kotlin: `shr(bitCount)`
    ///
    /// Arithmetic right shift (sign-preserving).
    public func shr(_ bitCount: Int) -> T {
        let masked = bitMaskShift(bitCount)
        return base >> masked
    }

    /// Kotlin: `ushr(bitCount)`
    ///
    /// Logical right shift (zero-filling), even for signed types.
    ///
    /// Implemented by converting through the magnitude (unsigned) representation.
    public func ushr(_ bitCount: Int) -> T {
        let masked = bitMaskShift(bitCount)
        let magnitude = T.Magnitude(truncatingIfNeeded: base)
        let shifted = magnitude >> masked
        return T(truncatingIfNeeded: shifted)
    }

    private func bitMaskShift(_ bitCount: Int) -> Int {
        guard bitCount != 0 else { return 0 }
        let width = T.bitWidth
        // Kotlin masks shift counts using `bitCount & (bitWidth - 1)`.
        let mask = width &- 1
        return bitCount & mask
    }
}

// MARK: - Integer math helpers

extension KotlinNumberProxy where T: SignedInteger & FixedWidthInteger {

    /// Kotlin: `absoluteValue`
    public var absoluteValue: T {
        base.magnitude > T.Magnitude(T.max) ? base : (base < 0 ? -base : base)
    }

    /// Kotlin: `sign`
    ///
    /// Returns:
    /// - `-1` if value is negative
    /// - `0`  if value is zero
    /// - `1`  if value is positive
    public var sign: Int {
        if base == 0 { return 0 }
        return base < 0 ? -1 : 1
    }
}

// MARK: - Range helpers: until, downTo, step

extension KotlinNumberProxy where T: Strideable & Comparable, T.Stride: SignedInteger {

    /// Kotlin: `until(end)` (e.g. `0.until(10)` → 0..9)
    ///
    /// Returns an increasing progression from `base` up to but *excluding* `end`.
    public func until(_ end: T) -> KotlinNumberProgression<T> {
        if base >= end {
            // Empty progression: start > end with positive step.
            let last = base.advanced(by: -1)
            return KotlinNumberProgression(start: base, endInclusive: last, step: 1)
        }
        let last = end.advanced(by: -1)
        return KotlinNumberProgression(start: base, endInclusive: last, step: 1)
    }

    /// Kotlin: `downTo(end)` (e.g. `10.downTo(0)` → 10, 9, ..., 0)
    ///
    /// Returns a decreasing progression from `base` down to `end` (inclusive).
    public func downTo(_ end: T) -> KotlinNumberProgression<T> {
        if base <= end {
            // Empty progression: start < end with negative step.
            return KotlinNumberProgression(start: base, endInclusive: end, step: -1)
        }
        return KotlinNumberProgression(start: base, endInclusive: end, step: -1)
    }
}


