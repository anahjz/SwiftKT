//
//  KotlinNumberTests.swift
//  SwiftKTTests
//
//  Unit tests for Kotlin-style numeric APIs on integers, floating-point types,
//  and String parsing helpers.
//

import XCTest
@testable import SwiftKT

final class KotlinNumberTests: XCTestCase {

    // MARK: - Integer conversions

    func testIntegerToIntegerConversions() {
        let value: Int = 42

        XCTAssertEqual(value.kotlin.toByte(), 42)
        XCTAssertEqual(value.kotlin.toShort(), 42)
        XCTAssertEqual(value.kotlin.toInt(), 42)
        XCTAssertEqual(value.kotlin.toLong(), 42)
        XCTAssertEqual(value.kotlin.toUInt(), 42)
        XCTAssertEqual(value.kotlin.toULong(), 42)
    }

    func testIntegerToIntegerOverflowTruncation() {
        // Use a value that exceeds Int8 range; Kotlin/JVM keeps low 8 bits.
        let value: Int = 130 // 0b1000_0010 → 0x82 → -126 in two's complement Int8
        XCTAssertEqual(value.kotlin.toByte(), -126)

        let longValue: Int64 = Int64(Int32.max) + 1
        let truncated = longValue.kotlin.toInt()
        // In Kotlin: (Int.MAX_VALUE + 1L).toInt() == Int.MIN_VALUE
        XCTAssertEqual(truncated, Int(truncatingIfNeeded: longValue))
    }

    // MARK: - Integer to floating-point

    func testIntegerToFloatingPoint() {
        let value: Int = 123
        XCTAssertEqual(value.kotlin.toFloat(), 123.0)
        XCTAssertEqual(value.kotlin.toDouble(), 123.0)
    }

    // MARK: - Floating-point to integer (toInt / toLong)

    func testFloatingPointToIntegralBasic() {
        let value: Double = 3.99
        XCTAssertEqual(value.kotlin.toInt(), 3)
        XCTAssertEqual(value.kotlin.toLong(), 3)

        let negative: Double = -3.99
        XCTAssertEqual(negative.kotlin.toInt(), -3)
        XCTAssertEqual(negative.kotlin.toLong(), -3)
    }

    func testFloatingPointToIntegralNaNAndInfinity() {
        XCTAssertEqual(Double.nan.kotlin.toInt(), 0)
        XCTAssertEqual(Double.nan.kotlin.toLong(), 0)

        XCTAssertEqual(Double.infinity.kotlin.toInt(), Int.max)
        XCTAssertEqual(Double.infinity.kotlin.toLong(), Int64.max)

        XCTAssertEqual((-Double.infinity).kotlin.toInt(), Int.min)
        XCTAssertEqual((-Double.infinity).kotlin.toLong(), Int64.min)
    }

    // MARK: - Floating-point predicates

    func testFloatingPointPredicates() {
        XCTAssertTrue(Double.nan.kotlin.isNaN())
        XCTAssertFalse(1.0.kotlin.isNaN())

        XCTAssertTrue(Double.infinity.kotlin.isInfinite())
        XCTAssertFalse(1.0.kotlin.isInfinite())

        XCTAssertTrue(1.0.kotlin.isFinite())
        XCTAssertFalse(Double.infinity.kotlin.isFinite())
    }

    // MARK: - Floating-point math helpers

    func testFloatingPointMathHelpers() throws {
        XCTAssertEqual((-3.5).kotlin.absoluteValue, 3.5)
        XCTAssertEqual(3.5.kotlin.absoluteValue, 3.5)

        XCTAssertEqual(3.5.kotlin.sign, 1)
        XCTAssertEqual((-3.5).kotlin.sign, -1)
        XCTAssertEqual(0.0.kotlin.sign, 0)

        XCTAssertEqual(try 2.4.kotlin.roundToInt(), 2)
        XCTAssertEqual(try 2.5.kotlin.roundToInt(), 3)
        XCTAssertEqual(try (-2.5).kotlin.roundToInt(), -2) // ties toward +∞

        XCTAssertEqual(try 2.4.kotlin.roundToLong(), 2)
        XCTAssertEqual(try 2.5.kotlin.roundToLong(), 3)

        XCTAssertThrowsError(try Double.nan.kotlin.roundToInt())
        XCTAssertEqual(try Double.infinity.kotlin.roundToInt(), Int.max)
        XCTAssertEqual(try (-Double.infinity).kotlin.roundToInt(), Int.min)
    }

    // MARK: - String integer parsing

    func testStringToIntParsing() throws {
        XCTAssertEqual(try "42".kotlin.toInt(), 42)
        XCTAssertEqual(try "-42".kotlin.toInt(), -42)
        XCTAssertEqual(try "+42".kotlin.toInt(), 42)
    }

    func testStringToIntParsingRadix() throws {
        XCTAssertEqual(try "2a".kotlin.toInt(radix: 16), 42)
        XCTAssertEqual(try "2A".kotlin.toInt(radix: 16), 42)
        XCTAssertEqual(try "101010".kotlin.toInt(radix: 2), 42)
    }

    func testStringToIntParsingInvalid() {
        XCTAssertThrowsError(try "abc".kotlin.toInt())
        XCTAssertThrowsError(try "".kotlin.toInt())
        XCTAssertThrowsError(try "+".kotlin.toInt())
        XCTAssertThrowsError(try "-".kotlin.toInt())
    }

    func testStringToIntOrNull() throws {
        XCTAssertEqual(try "42".kotlin.toIntOrNull(), 42)
        XCTAssertNil(try "abc".kotlin.toIntOrNull())
        XCTAssertNil(try "".kotlin.toIntOrNull())
    }

    func testStringToIntRadixInvalidRadix() {
        XCTAssertThrowsError(try "10".kotlin.toInt(radix: 1))
        XCTAssertThrowsError(try "10".kotlin.toIntOrNull(radix: 37))
    }

    // MARK: - String long parsing

    func testStringToLongParsing() throws {
        XCTAssertEqual(try "42".kotlin.toLong(), 42)
        XCTAssertEqual(try "-42".kotlin.toLong(), -42)
    }

    func testStringToLongOrNull() throws {
        XCTAssertEqual(try "42".kotlin.toLongOrNull(), 42)
        XCTAssertNil(try "not-a-number".kotlin.toLongOrNull())
    }

    // MARK: - String floating-point parsing

    func testStringToDoubleParsing() throws {
        XCTAssertEqual(try "3.14".kotlin.toDouble(), 3.14, accuracy: 1e-12)
        XCTAssertEqual(try "-3.14".kotlin.toDouble(), -3.14, accuracy: 1e-12)
    }

    func testStringToDoubleOrNull() {
        XCTAssertEqual("3.14".kotlin.toDoubleOrNull(), 3.14)
        XCTAssertNil("abc".kotlin.toDoubleOrNull())
    }

    func testStringToFloatParsing() throws {
        XCTAssertEqual(try "3.14".kotlin.toFloat(), 3.14, accuracy: 1e-4)
    }

    func testStringToFloatOrNull() {
        let value = "3.14".kotlin.toFloatOrNull()
        XCTAssertNotNil(value)
        if let value {
            XCTAssertEqual(value, 3.14, accuracy: 1e-4)
        }
        XCTAssertNil("abc".kotlin.toFloatOrNull())
    }

    // MARK: - Coercion

    func testIntegerCoercion() throws {
        XCTAssertEqual(5.kotlin.coerceAtLeast(10), 10)
        XCTAssertEqual(5.kotlin.coerceAtMost(3), 3)
        XCTAssertEqual(5.kotlin.coerceAtMost(10), 5)

        XCTAssertEqual(try 5.kotlin.coerceIn(min: 0, max: 10), 5)
        XCTAssertEqual(try (-5).kotlin.coerceIn(min: 0, max: 10), 0)
        XCTAssertEqual(try 15.kotlin.coerceIn(min: 0, max: 10), 10)

        XCTAssertThrowsError(try 5.kotlin.coerceIn(min: 10, max: 0))
    }

    // MARK: - Bitwise operations

    func testBitwiseOperations() {
        let a: Int = 0b1010
        let b: Int = 0b1100

        XCTAssertEqual(a.kotlin.and(b), 0b1000)
        XCTAssertEqual(a.kotlin.or(b), 0b1110)
        XCTAssertEqual(a.kotlin.xor(b), 0b0110)

        XCTAssertEqual(a.kotlin.inv(), ~a)

        XCTAssertEqual(a.kotlin.shl(1), a << 1)
        XCTAssertEqual(a.kotlin.shr(1), a >> 1)

        // Logical shift on negative values should fill with zeros.
        let negative: Int32 = -1
        let ushr1 = negative.kotlin.ushr(1)
        XCTAssertEqual(UInt32(bitPattern: ushr1), UInt32(bitPattern: negative) >> 1)
    }

    // MARK: - Comparison

    func testIntegerComparison() {
        XCTAssertEqual(5.kotlin.compareTo(10), -1)
        XCTAssertEqual(10.kotlin.compareTo(5), 1)
        XCTAssertEqual(7.kotlin.compareTo(7), 0)

        XCTAssertTrue(5.kotlin.equals(5))
        XCTAssertFalse(5.kotlin.equals(6))
    }

    func testFloatingPointComparison() {
        XCTAssertEqual(1.0.kotlin.compareTo(2.0), -1)
        XCTAssertEqual(2.0.kotlin.compareTo(1.0), 1)
        XCTAssertEqual(3.0.kotlin.compareTo(3.0), 0)

        // NaN ordering: NaN > any number, NaN == NaN in compareTo.
        XCTAssertEqual(Double.nan.kotlin.compareTo(1.0), 1)
        XCTAssertEqual(1.0.kotlin.compareTo(Double.nan), -1)
        XCTAssertEqual(Double.nan.kotlin.compareTo(Double.nan), 0)
    }

    // MARK: - Range helpers

    func testUntilRangeHelper() {
        let progression = 0.kotlin.until(5)
        let values = Array(progression)
        XCTAssertEqual(values, [0, 1, 2, 3, 4])

        let empty = 5.kotlin.until(5)
        XCTAssertEqual(Array(empty), [])
    }

    func testDownToRangeHelper() {
        let progression = 5.kotlin.downTo(1)
        let values = Array(progression)
        XCTAssertEqual(values, [5, 4, 3, 2, 1])

        let empty = 1.kotlin.downTo(5)
        XCTAssertEqual(Array(empty), [])
    }

    func testStepOnProgression() throws {
        let progression = 0.kotlin.until(10)
        let stepped = try progression.step(2)
        let values = Array(stepped)
        XCTAssertEqual(values, [0, 2, 4, 6, 8])

        let down = 10.kotlin.downTo(0)
        let downStepped = try down.step(3)
        let downValues = Array(downStepped)
        XCTAssertEqual(downValues, [10, 7, 4, 1])

        XCTAssertThrowsError(try progression.step(0))
        XCTAssertThrowsError(try progression.step(-1))
    }
}

