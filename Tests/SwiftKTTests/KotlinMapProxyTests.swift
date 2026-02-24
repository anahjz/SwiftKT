//
//  KotlinMapProxyTests.swift
//  SwiftKTTests
//
//  Tests for Kotlin-style Map APIs on Swift dictionaries.
//

import XCTest
@testable import SwiftKT

final class KotlinMapProxyTests: XCTestCase {

    // MARK: - Retrieval

    func testGetOrDefaultExistingAndMissing() {
        let map = ["a": 1, "b": 2]

        XCTAssertEqual(map.kotlinMap.getOrDefault("a", defaultValue: 0), 1)
        XCTAssertEqual(map.kotlinMap.getOrDefault("c", defaultValue: 0), 0)

        let optionalMap: [String: Int?] = ["a": nil]
        XCTAssertNil(optionalMap.kotlinMap.getOrDefault("a", defaultValue: 42))
        XCTAssertEqual(optionalMap.kotlinMap.getOrDefault("b", defaultValue: 42), 42)
    }

    func testGetOrElseLazyExecution() {
        var evaluated = false
        let map = ["a": 1]

        let value1 = map.kotlinMap.getOrElse("a") {
            evaluated = true
            return 42
        }
        XCTAssertEqual(value1, 1)
        XCTAssertFalse(evaluated)

        let value2 = map.kotlinMap.getOrElse("b") {
            evaluated = true
            return 42
        }
        XCTAssertEqual(value2, 42)
        XCTAssertTrue(evaluated)
    }

    // MARK: - Containment

    func testContainsKey() {
        let map = ["a": 1, "b": 2]
        XCTAssertTrue(map.kotlinMap.containsKey("a"))
        XCTAssertFalse(map.kotlinMap.containsKey("c"))

        let optionalMap: [String: Int?] = ["a": nil]
        XCTAssertTrue(optionalMap.kotlinMap.containsKey("a"))
        XCTAssertFalse(optionalMap.kotlinMap.containsKey("b"))
    }

    func testContainsValue() {
        let map = ["a": 1, "b": 2, "c": 2]
        XCTAssertTrue(map.kotlinMap.containsValue(1))
        XCTAssertTrue(map.kotlinMap.containsValue(2))
        XCTAssertFalse(map.kotlinMap.containsValue(3))
    }

    // MARK: - Filtering

    func testFilterKeys() {
        let map = ["a": 1, "b": 2, "c": 3]
        let filtered = map.kotlinMap.filterKeys { $0 != "b" }

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered["a"], 1)
        XCTAssertEqual(filtered["c"], 3)
        XCTAssertNil(filtered["b"])
    }

    func testFilterValues() {
        let map = ["a": 1, "b": 2, "c": 2]
        let filtered = map.kotlinMap.filterValues { $0 == 2 }

        XCTAssertEqual(filtered.count, 2)
        XCTAssertNil(filtered["a"])
        XCTAssertEqual(filtered["b"], 2)
        XCTAssertEqual(filtered["c"], 2)
    }

    // MARK: - Transformations

    func testMapValues() {
        let map = ["a": 1, "b": 2]
        let doubled = map.kotlinMap.mapValues { _, value in value * 2 }

        XCTAssertEqual(doubled["a"], 2)
        XCTAssertEqual(doubled["b"], 4)
        XCTAssertNil(doubled["c"])
        // Ensure original unchanged
        XCTAssertEqual(map["a"], 1)
    }

    func testMapKeysWithCollisionsLastWins() {
        let map = ["a": 1, "b": 2, "c": 3]
        // Map all keys to their length; "a", "b", "c" all length 1.
        let mapped = map.kotlinMap.mapKeys { key, _ in key.count }

        // There should be exactly one entry with key 1. Value is from one of the entries
        // (Swift Dictionary iteration order is unspecified, so "last" is arbitrary).
        XCTAssertEqual(mapped.count, 1)
        XCTAssertTrue([1, 2, 3].contains(mapped[1] ?? -1))
    }

    // MARK: - Optional values

    func testOptionalValues() {
        let map: [String: Int?] = [
            "a": 1,
            "b": nil
        ]

        XCTAssertTrue(map.kotlinMap.containsKey("a"))
        XCTAssertTrue(map.kotlinMap.containsKey("b"))
        XCTAssertFalse(map.kotlinMap.containsKey("c"))

        XCTAssertEqual(map.kotlinMap.getOrDefault("a", defaultValue: nil), 1)
        XCTAssertNil(map.kotlinMap.getOrDefault("b", defaultValue: 42))
    }

    // MARK: - Large map sanity

    func testLargeMapBehavior() {
        let count = 10_000
        var map: [Int: Int] = [:]
        for i in 0..<count {
            map[i] = i
        }

        XCTAssertEqual(map.kotlinMap.getOrDefault(count - 1, defaultValue: -1), count - 1)
        XCTAssertEqual(map.kotlinMap.filterKeys { $0 % 2 == 0 }.count, count / 2)
    }
}

