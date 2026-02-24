//
//  KotlinCollectionProxyTests.swift
//  SwiftKTTests
//
//  Core tests for Kotlin-style collection predicates, retrieval, and transforms.
//

import XCTest
@testable import SwiftKT

final class KotlinCollectionProxyTests: XCTestCase {

    // MARK: - Predicates

    func testAllAnyNoneOnInts() {
        let values = [1, 2, 3]

        XCTAssertTrue(values.kotlin.all { $0 > 0 })
        XCTAssertFalse(values.kotlin.all { $0 > 1 })

        XCTAssertTrue(values.kotlin.any { $0 == 2 })
        XCTAssertFalse(values.kotlin.any { $0 == 4 })

        XCTAssertFalse(values.kotlin.none { $0 == 1 })
        XCTAssertTrue(values.kotlin.none { $0 == 42 })
    }

    func testCountAndCountPredicate() {
        let values = [1, 2, 2, 3]
        XCTAssertEqual(values.kotlin.count(), 4)
        XCTAssertEqual(values.kotlin.count { $0 == 2 }, 2)
    }

    // MARK: - Transformations

    func testMapAndMapIndexed() {
        let values = ["a", "b", "c"]
        XCTAssertEqual(values.kotlin.map { $0.uppercased() }, ["A", "B", "C"])

        let indexed = values.kotlin.mapIndexed { index, element in
            "\(index):\(element)"
        }
        XCTAssertEqual(indexed, ["0:a", "1:b", "2:c"])
    }

    func testFlatMap() {
        let values = ["ab", "cd"]
        let chars = values.kotlin.flatMap { Array($0) }
        XCTAssertEqual(chars, ["a", "b", "c", "d"])
    }

    func testFilterVariants() {
        let values = [1, 2, 3, 4]

        XCTAssertEqual(values.kotlin.filter { $0 % 2 == 0 }, [2, 4])
        XCTAssertEqual(values.kotlin.filterNot { $0 % 2 == 0 }, [1, 3])

        let indexed = values.kotlin.filterIndexed { index, element in
            index % 2 == 0 && element > 1
        }
        XCTAssertEqual(indexed, [3])
    }

    // MARK: - Distinct

    func testDistinctAndDistinctBy() {
        let values = [1, 2, 2, 3, 3, 3]
        XCTAssertEqual(values.kotlin.distinct(), [1, 2, 3])

        struct Person: Hashable {
            let id: Int
            let name: String
        }
        let people = [
            Person(id: 1, name: "A"),
            Person(id: 1, name: "A2"),
            Person(id: 2, name: "B")
        ]
        let distinctById = people.kotlin.distinctBy { $0.id }
        XCTAssertEqual(distinctById.map(\.id), [1, 2])
    }

    // MARK: - Retrieval

    func testFirstLastSingle() throws {
        let values = [1, 2, 3]

        XCTAssertEqual(try values.kotlin.first(), 1)
        XCTAssertEqual(try values.kotlin.last(), 3)

        XCTAssertEqual(try values.kotlin.first { $0 > 1 }, 2)
        XCTAssertEqual(try values.kotlin.last { $0 < 3 }, 2)

        XCTAssertEqual([42].kotlin.firstOrNull(), 42)
        XCTAssertNil([Int]().kotlin.firstOrNull())

        XCTAssertEqual([42].kotlin.lastOrNull(), 42)
        XCTAssertNil([Int]().kotlin.lastOrNull())

        XCTAssertEqual(try [42].kotlin.single(), 42)
        XCTAssertEqual([42].kotlin.singleOrNull(), 42)
        XCTAssertNil([Int]().kotlin.singleOrNull())
        XCTAssertNil([1, 2].kotlin.singleOrNull())
    }

    func testSingleThrowsOnEmptyOrMany() {
        XCTAssertThrowsError(try [Int]().kotlin.single())
        XCTAssertThrowsError(try [1, 2].kotlin.single())
    }

    func testGetOrNull() {
        let values = ["a", "b", "c"]
        XCTAssertEqual(values.kotlin.getOrNull(0), "a")
        XCTAssertEqual(values.kotlin.getOrNull(2), "c")
        XCTAssertNil(values.kotlin.getOrNull(-1))
        XCTAssertNil(values.kotlin.getOrNull(3))
    }

    // MARK: - Aggregation

    func testSumOf() {
        struct Item { let value: Int }
        let items = [Item(value: 1), Item(value: 2), Item(value: 3)]

        XCTAssertEqual(items.kotlin.sumOf { $0.value }, 6)
        XCTAssertEqual(items.kotlin.sumOf { Int64($0.value) }, 6)
        XCTAssertEqual(items.kotlin.sumOf { Double($0.value) }, 6.0)
        XCTAssertEqual(items.kotlin.sumOf { Float($0.value) }, 6.0)
    }

    func testMaxMin() {
        let values = [3, 1, 4, 2]

        XCTAssertEqual(values.kotlin.maxOrNull(), 4)
        XCTAssertEqual(values.kotlin.minOrNull(), 1)
        XCTAssertNil([Int]().kotlin.maxOrNull())
        XCTAssertNil([Int]().kotlin.minOrNull())
    }

    func testMaxByMinBy() {
        struct Person {
            let name: String
            let age: Int
        }
        let people = [
            Person(name: "A", age: 30),
            Person(name: "B", age: 20),
            Person(name: "C", age: 40)
        ]

        XCTAssertEqual(people.kotlin.maxByOrNull { $0.age }?.name, "C")
        XCTAssertEqual(people.kotlin.minByOrNull { $0.age }?.name, "B")
        XCTAssertNil([Person]().kotlin.maxByOrNull { $0.age })
    }

    // MARK: - Zip

    func testZip() {
        let a = [1, 2, 3]
        let b = ["a", "b"]

        let zipped = a.kotlin.zip(b)
        XCTAssertEqual(zipped.count, 2)
        XCTAssertEqual(zipped[0].0, 1)
        XCTAssertEqual(zipped[0].1, "a")

        let mapped = a.kotlin.zip(b) { i, s in "\(i):\(s)" }
        XCTAssertEqual(mapped, ["1:a", "2:b"])
    }
}

