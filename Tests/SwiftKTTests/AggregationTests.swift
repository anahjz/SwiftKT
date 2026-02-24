//
//  AggregationTests.swift
//  SwiftKTTests
//
//  Tests for max/min, maxBy/minBy, sumOf, and predicates on larger collections.
//

import XCTest
@testable import SwiftKT

final class AggregationTests: XCTestCase {

    func testMaxMinOnLargeCollection() {
        let values = Array(1...1_000)
        XCTAssertEqual(values.kotlin.maxOrNull(), 1_000)
        XCTAssertEqual(values.kotlin.minOrNull(), 1)
    }

    func testMaxByMinByCustomStruct() {
        struct Score {
            let name: String
            let value: Int
        }
        let scores = [
            Score(name: "a", value: 1),
            Score(name: "b", value: 10),
            Score(name: "c", value: 5)
        ]

        XCTAssertEqual(scores.kotlin.maxByOrNull { $0.value }?.name, "b")
        XCTAssertEqual(scores.kotlin.minByOrNull { $0.value }?.name, "a")
    }

    func testUnicodeStringsInCollections() {
        let values = ["👋", "café", "こんにちは"]
        XCTAssertTrue(values.kotlin.any { $0.contains("é") })
        XCTAssertTrue(values.kotlin.all { !$0.isEmpty })
        XCTAssertEqual(values.kotlin.count { $0.kotlin.length > 1 }, 2)
    }
}

