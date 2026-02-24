//
//  WindowingTests.swift
//  SwiftKTTests
//
//  Tests for chunked and windowed operations on collections.
//

import XCTest
@testable import SwiftKT

final class WindowingTests: XCTestCase {

    func testChunkedBasic() {
        let values = [1, 2, 3, 4, 5]
        XCTAssertEqual(values.kotlin.chunked(2), [[1, 2], [3, 4], [5]])
        XCTAssertEqual(values.kotlin.chunked(3), [[1, 2, 3], [4, 5]])
    }

    func testChunkedTransform() {
        let values = [1, 2, 3, 4]
        let sums = values.kotlin.chunked(2) { chunk in
            chunk.reduce(0, +)
        }
        XCTAssertEqual(sums, [3, 7])
    }

    func testWindowedDefaults() {
        let values = [1, 2, 3, 4]
        XCTAssertEqual(values.kotlin.windowed(2), [[1, 2], [2, 3], [3, 4]])
    }

    func testWindowedStepAndPartial() {
        let values = [1, 2, 3, 4, 5]
        XCTAssertEqual(values.kotlin.windowed(2, step: 2), [[1, 2], [3, 4]])

        let partial = values.kotlin.windowed(3, step: 2, partialWindows: true)
        XCTAssertEqual(partial, [[1, 2, 3], [3, 4, 5], [5]])
    }
}

