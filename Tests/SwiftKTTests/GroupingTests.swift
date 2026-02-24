//
//  GroupingTests.swift
//  SwiftKTTests
//
//  Tests for associate*, groupBy, and related helpers.
//

import XCTest
@testable import SwiftKT

final class GroupingTests: XCTestCase {

    func testAssociate() {
        let values = [1, 2, 3]
        let dict = values.kotlin.associate { ($0, "\($0)") }
        XCTAssertEqual(dict[1], "1")
        XCTAssertEqual(dict[2], "2")
        XCTAssertEqual(dict[3], "3")
    }

    func testAssociateByAndAssociateWith() {
        struct Person: Hashable {
            let id: Int
            let name: String
        }
        let people = [
            Person(id: 1, name: "A"),
            Person(id: 2, name: "B")
        ]

        let byId = people.kotlin.associateBy { $0.id }
        XCTAssertEqual(byId[1]?.name, "A")

        let byIdName = people.kotlin.associateBy({ $0.id }) { $0.name }
        XCTAssertEqual(byIdName[2], "B")

        let withName = people.kotlin.associateWith { $0.name }
        XCTAssertEqual(withName[people[0]], "A")
    }

    func testGroupBy() {
        let values = [1, 2, 3, 4, 5]
        let grouped = values.kotlin.groupBy { $0 % 2 == 0 ? "even" : "odd" }

        XCTAssertEqual(grouped["even"], [2, 4])
        XCTAssertEqual(grouped["odd"], [1, 3, 5])

        let groupedSquares = values.kotlin.groupBy({ $0 % 2 == 0 ? "even" : "odd" }) { $0 * $0 }
        XCTAssertEqual(groupedSquares["even"], [4, 16])
        XCTAssertEqual(groupedSquares["odd"], [1, 9, 25])
    }
}

