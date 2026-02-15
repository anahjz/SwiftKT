//
//  SwiftKTTests.swift
//  SwiftKTTests
//
//  Unit tests for Kotlin String API surface. Replicates Kotlin official docs examples
//  and covers Unicode edge cases, empty/single-char strings, and large strings.
//

import XCTest
@testable import SwiftKT

final class SwiftKTTests: XCTestCase {

    // MARK: - Properties

    func testLength() {
        XCTAssertEqual("".kotlin.length, 0)
        XCTAssertEqual("a".kotlin.length, 1)
        XCTAssertEqual("hello".kotlin.length, 5)
        XCTAssertEqual("café".kotlin.length, 4)
        XCTAssertEqual("👋🏼".kotlin.length, 1) // grapheme cluster
    }

    func testIndices() {
        XCTAssertEqual("".kotlin.indices, 0..<0)
        XCTAssertEqual("ab".kotlin.indices, 0..<2)
    }

    func testLastIndex() {
        XCTAssertEqual("".kotlin.lastIndex, -1)
        XCTAssertEqual("a".kotlin.lastIndex, 0)
        XCTAssertEqual("hello".kotlin.lastIndex, 4)
    }

    // MARK: - Predicates

    func testIsEmpty() {
        XCTAssertTrue("".kotlin.isEmpty())
        XCTAssertFalse(" ".kotlin.isEmpty())
        XCTAssertFalse("a".kotlin.isEmpty())
    }

    func testIsBlank() {
        XCTAssertTrue("".kotlin.isBlank())
        XCTAssertTrue("   ".kotlin.isBlank())
        XCTAssertTrue("\t\n".kotlin.isBlank())
        XCTAssertFalse("  a  ".kotlin.isBlank())
    }

    func testIsNotEmpty() {
        XCTAssertFalse("".kotlin.isNotEmpty())
        XCTAssertTrue("a".kotlin.isNotEmpty())
    }

    func testIsNotBlank() {
        XCTAssertFalse("".kotlin.isNotBlank())
        XCTAssertFalse("   ".kotlin.isNotBlank())
        XCTAssertTrue("  a  ".kotlin.isNotBlank())
    }

    // MARK: - Char access

    func testGet() throws {
        XCTAssertEqual(try "hello".kotlin.get(index: 0), "h")
        XCTAssertEqual(try "hello".kotlin.get(index: 4), "o")
        XCTAssertThrowsError(try "hello".kotlin.get(index: -1)) { err in
            XCTAssertTrue(err is KotlinStringError)
        }
        XCTAssertThrowsError(try "hello".kotlin.get(index: 5)) { err in
            XCTAssertTrue(err is KotlinStringError)
        }
    }

    func testFirstLast() throws {
        XCTAssertEqual(try "hello".kotlin.first(), "h")
        XCTAssertEqual(try "hello".kotlin.last(), "o")
        XCTAssertThrowsError(try "".kotlin.first())
        XCTAssertThrowsError(try "".kotlin.last())
    }

    func testFirstOrNullLastOrNull() {
        XCTAssertEqual("hello".kotlin.firstOrNull(), "h")
        XCTAssertEqual("hello".kotlin.lastOrNull(), "o")
        XCTAssertNil("".kotlin.firstOrNull())
        XCTAssertNil("".kotlin.lastOrNull())
    }

    // MARK: - Search

    func testContains() {
        XCTAssertTrue("hello".kotlin.contains("ell"))
        XCTAssertFalse("hello".kotlin.contains("xyz"))
        XCTAssertTrue("hello".kotlin.contains(Character("e")))
    }

    func testStartsWithEndsWith() {
        XCTAssertTrue("hello".kotlin.startsWith("he"))
        XCTAssertFalse("hello".kotlin.startsWith("lo"))
        XCTAssertTrue("hello".kotlin.endsWith("lo"))
        XCTAssertTrue("hello".kotlin.startsWith("HE", ignoreCase: true))
        XCTAssertTrue("hello".kotlin.endsWith("LO", ignoreCase: true))
    }

    func testIndexOf() {
        XCTAssertEqual("hello".kotlin.indexOf(Character("l")), 2)
        XCTAssertEqual("hello".kotlin.indexOf(Character("z")), -1)
        XCTAssertEqual("hello".kotlin.indexOf("ll"), 2)
        XCTAssertEqual("hello".kotlin.indexOf("ll", startIndex: 3), -1)
        XCTAssertEqual("hello".kotlin.indexOf("l", startIndex: 3), 3)
    }

    func testLastIndexOf() {
        XCTAssertEqual("hello".kotlin.lastIndexOf(Character("l")), 3)
        XCTAssertEqual("hello".kotlin.lastIndexOf("l"), 3)
        XCTAssertEqual("hello".kotlin.lastIndexOf("z"), -1)
    }

    func testRegionMatches() {
        XCTAssertTrue("abcd".kotlin.regionMatches(thisOffset: 1, other: "bcxy", otherOffset: 0, length: 2))
        XCTAssertFalse("abcd".kotlin.regionMatches(thisOffset: 1, other: "BCxy", otherOffset: 0, length: 2))
        XCTAssertTrue("abcd".kotlin.regionMatches(thisOffset: 1, other: "BCxy", otherOffset: 0, length: 2, ignoreCase: true))
    }

    // MARK: - Transform

    func testLowercaseUppercase() {
        XCTAssertEqual("HELLO".kotlin.lowercase(), "hello")
        XCTAssertEqual("hello".kotlin.uppercase(), "HELLO")
    }

    func testCapitalizeDecapitalize() {
        XCTAssertEqual("hello".kotlin.capitalize(), "Hello")
        XCTAssertEqual("Hello".kotlin.decapitalize(), "hello")
        XCTAssertEqual("".kotlin.capitalize(), "")
    }

    func testReplace() {
        XCTAssertEqual("hello".kotlin.replace(oldValue: "l", newValue: "x"), "hexxo")
        XCTAssertEqual("hello".kotlin.replaceFirst(oldValue: "l", newValue: "x"), "hexlo")
    }

    func testReplaceRange() throws {
        XCTAssertEqual(try "hello".kotlin.replaceRange(startIndex: 1, endIndex: 4, replacement: "xx"), "hxxo")
        XCTAssertThrowsError(try "hello".kotlin.replaceRange(startIndex: 1, endIndex: 10, replacement: "x"))
    }

    func testSubstring() {
        XCTAssertEqual("hello".kotlin.substring(startIndex: 1, endIndex: 4), "ell")
        XCTAssertEqual("hello".kotlin.substring(startIndex: 1), "ello")
        XCTAssertEqual("hello".kotlin.substringBefore("l"), "he")
        XCTAssertEqual("hello".kotlin.substringAfter("l"), "lo")
        XCTAssertEqual("hello".kotlin.substringBeforeLast("l"), "hel")
        XCTAssertEqual("hello".kotlin.substringAfterLast("l"), "o")
        XCTAssertEqual("hello".kotlin.substringBefore("z"), "hello")
    }

    func testTrim() {
        XCTAssertEqual("  hello  ".kotlin.trim(), "hello")
        XCTAssertEqual("  hello  ".kotlin.trimStart(), "hello  ")
        XCTAssertEqual("  hello  ".kotlin.trimEnd(), "  hello")
    }

    func testTrimIndent() {
        let multilineText = """
            abc
            def
            """
        XCTAssertEqual(multilineText.kotlin.trimIndent(), "abc\ndef")
    }

    func testTrimMargin() {
        let textWithMargin = "|a\n|b"
        XCTAssertEqual(textWithMargin.kotlin.trimMargin(marginPrefix: "|"), "a\nb")
    }

    // MARK: - Split

    func testSplit() {
        XCTAssertEqual("a-b-c".kotlin.split(delimiter: "-"), ["a", "b", "c"])
        XCTAssertEqual("a-b-c".kotlin.split(delimiter: "-", limit: 2), ["a", "b-c"])
        XCTAssertEqual("hello".kotlin.split(delimiter: "ll"), ["he", "o"])
        XCTAssertEqual("hello".kotlin.lines(), ["hello"])
        XCTAssertEqual("a\nb\nc".kotlin.lines(), ["a", "b", "c"])
    }

    // MARK: - Padding & repeat

    func testPadStartPadEnd() {
        XCTAssertEqual("1".kotlin.padStart(length: 3, padChar: "0"), "001")
        XCTAssertEqual("1".kotlin.padEnd(length: 3, padChar: "0"), "100")
        XCTAssertEqual("abc".kotlin.padStart(length: 2), "abc")
    }

    func testRepeat() {
        XCTAssertEqual("ab".kotlin.repeat(n: 3), "ababab")
        XCTAssertEqual("x".kotlin.repeat(n: 0), "")
        XCTAssertEqual("x".kotlin.repeat(n: 1), "x")
    }

    // MARK: - Regex

    func testToRegex() {
        let regex = "l+".kotlin.toRegex()
        XCTAssertNotNil(regex)
        if let compiledRegex = regex {
            XCTAssertTrue("hello".kotlin.contains(compiledRegex))
        }
        if let pattern = "hel+o".kotlin.toRegex() {
            XCTAssertTrue("helllo".kotlin.matches(pattern))
            XCTAssertTrue("helo".kotlin.matches(pattern))  // one 'l' matches hel+o
            XCTAssertFalse("heo".kotlin.matches(pattern))
        }
    }

    // MARK: - Collection-like

    func testChunked() {
        XCTAssertEqual("123456".kotlin.chunked(size: 2), ["12", "34", "56"])
        XCTAssertEqual("12345".kotlin.chunked(size: 2), ["12", "34", "5"])
    }

    func testWindowed() {
        XCTAssertEqual("12345".kotlin.windowed(size: 2), ["12", "23", "34", "45"])
        XCTAssertEqual("1234".kotlin.windowed(size: 2, step: 2), ["12", "34"])
    }

    func testZip() {
        let zipped = "ab".kotlin.zip("xy")
        XCTAssertEqual(zipped.count, 2)
        XCTAssertEqual(zipped[0].0, "a")
        XCTAssertEqual(zipped[0].1, "x")
    }

    func testFilter() {
        XCTAssertEqual("hello".kotlin.filter { $0 != "l" }, "heo")
        XCTAssertEqual("hello".kotlin.filterNot { $0 == "l" }, "heo")
    }

    func testMap() {
        XCTAssertEqual("abc".kotlin.map { $0 }, "abc")
        let mapped = "abc".kotlin.map { char in
            String(char).uppercased().first ?? char
        }
        XCTAssertEqual(mapped, "ABC")
    }

    func testAllAnyNone() {
        XCTAssertTrue("123".kotlin.all { $0.isNumber })
        XCTAssertFalse("12a".kotlin.all { $0.isNumber })
        XCTAssertTrue("hello".kotlin.any { $0 == "o" })
        XCTAssertTrue("".kotlin.none())
        XCTAssertTrue("hello".kotlin.none { $0 == "z" })
    }

    func testCount() {
        XCTAssertEqual("hello".kotlin.count(), 5)
        XCTAssertEqual("hello".kotlin.count { $0 == "l" }, 2)
    }

    // MARK: - Unicode edge cases

    func testUnicodeGraphemeCluster() {
        let emoji = "👋🏼"
        XCTAssertEqual(emoji.kotlin.length, 1)
        XCTAssertEqual(try emoji.kotlin.first(), Character("👋🏼"))
        XCTAssertEqual(emoji.kotlin.substring(startIndex: 0, endIndex: 1), "👋🏼")
    }

    func testUnicodeAccents() {
        let accentedString = "café"
        XCTAssertEqual(accentedString.kotlin.length, 4)
        XCTAssertEqual(try accentedString.kotlin.get(index: 3), "é")
        XCTAssertEqual(accentedString.kotlin.indexOf("é"), 3)
    }

    func testEmptyAndSingleChar() {
        XCTAssertEqual("".kotlin.length, 0)
        XCTAssertEqual("a".kotlin.length, 1)
        XCTAssertEqual("".kotlin.substring(startIndex: 0, endIndex: 0), "")
        XCTAssertEqual("x".kotlin.repeat(n: 100).kotlin.length, 100)
    }

    // MARK: - Large string

    func testLargeString() {
        let large = String(repeating: "a", count: 10_000)
        XCTAssertEqual(large.kotlin.length, 10_000)
        XCTAssertEqual(large.kotlin.substring(startIndex: 0, endIndex: 100).kotlin.length, 100)
        XCTAssertTrue(large.kotlin.all { $0 == "a" })
    }
}
