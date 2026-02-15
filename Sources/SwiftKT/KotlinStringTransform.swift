//
//  KotlinStringTransform.swift
//  SwiftKT
//
//  Kotlin String transformation APIs: case conversion, replace, substring, trim.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - Case conversion

    /// Returns a copy of this string in lowercase (Kotlin: `lowercase()`).
    /// Uses the current locale. Behavior may differ from JVM's default locale.
    public func lowercase() -> String {
        base.lowercased()
    }

    /// Returns a copy of this string in uppercase (Kotlin: `uppercase()`).
    public func uppercase() -> String {
        base.uppercased()
    }

    /// Returns the lowercase form of the first character (Kotlin: `lowercaseChar()`).
    public func lowercaseChar() -> Character {
        guard let first = base.first else { return Character("") }
        return String(first).lowercased().first ?? first
    }

    /// Returns the uppercase form of the first character (Kotlin: `uppercaseChar()`).
    public func uppercaseChar() -> Character {
        guard let first = base.first else { return Character("") }
        return String(first).uppercased().first ?? first
    }

    /// Returns a copy with the first character capitalized (Kotlin: `capitalize()`).
    /// Deprecated in Kotlin 1.5; replaced by replaceFirstChar. We keep for API parity.
    public func capitalize() -> String {
        guard let first = base.first else { return base }
        return first.uppercased() + base.dropFirst()
    }

    /// Returns a copy with the first character lowercased (Kotlin: `decapitalize()`).
    public func decapitalize() -> String {
        guard let first = base.first else { return base }
        return first.lowercased() + base.dropFirst()
    }

    // MARK: - replace

    /// Replaces all occurrences of oldValue with newValue (Kotlin: `replace(oldValue, newValue)`).
    public func replace(oldValue: String, newValue: String) -> String {
        base.replacingOccurrences(of: oldValue, with: newValue)
    }

    /// Replaces the first occurrence of oldValue with newValue (Kotlin: `replaceFirst(oldValue, newValue)`).
    public func replaceFirst(oldValue: String, newValue: String) -> String {
        guard let range = base.range(of: oldValue) else { return base }
        return String(base[..<range.lowerBound]) + newValue + String(base[range.upperBound...])
    }

    /// Replaces the character range [startIndex, endIndex) with replacement (Kotlin: `replaceRange(startIndex, endIndex, replacement)`).
    /// - Throws: KotlinStringError if indices are out of bounds.
    public func replaceRange(startIndex: Int, endIndex: Int, replacement: String) throws -> String {
        guard let start = KotlinStringIndex.stringIndex(for: base, kotlinIndex: startIndex),
              let end = KotlinStringIndex.stringIndex(for: base, kotlinIndex: endIndex),
              startIndex >= 0, endIndex >= startIndex, endIndex <= base.count else {
            throw KotlinStringError.indexOutOfBounds(index: startIndex, length: base.count)
        }
        return String(base[..<start]) + replacement + String(base[end...])
    }

    /// Replaces the range with replacement (Kotlin: `replaceRange(range, replacement)`).
    public func replaceRange(range: Range<Int>, replacement: String) throws -> String {
        try replaceRange(startIndex: range.lowerBound, endIndex: range.upperBound, replacement: replacement)
    }

    // MARK: - substring

    /// Returns substring from startIndex (inclusive) to endIndex (exclusive) (Kotlin: `substring(startIndex, endIndex)`).
    /// Returns String, not Substring, to match Kotlin and avoid view lifetime issues.
    public func substring(startIndex: Int, endIndex: Int) -> String {
        guard startIndex >= 0, endIndex >= startIndex, endIndex <= base.count,
              let start = KotlinStringIndex.stringIndex(for: base, kotlinIndex: startIndex),
              let end = KotlinStringIndex.stringIndex(for: base, kotlinIndex: endIndex) else {
            return ""
        }
        return String(base[start..<end])
    }

    /// Returns substring from startIndex to the end (Kotlin: `substring(startIndex)`).
    public func substring(startIndex: Int) -> String {
        substring(startIndex: startIndex, endIndex: base.count)
    }

    /// Returns substring before the first occurrence of delimiter, or the whole string if delimiter not found (Kotlin: `substringBefore(delimiter)`).
    public func substringBefore(_ delimiter: String) -> String {
        guard let range = base.range(of: delimiter) else { return base }
        return String(base[..<range.lowerBound])
    }

    /// Returns substring after the first occurrence of delimiter, or the whole string if delimiter not found (Kotlin: `substringAfter(delimiter)`).
    public func substringAfter(_ delimiter: String) -> String {
        guard let range = base.range(of: delimiter) else { return base }
        return String(base[range.upperBound...])
    }

    /// Returns substring before the last occurrence of delimiter, or the whole string if not found (Kotlin: `substringBeforeLast(delimiter)`).
    public func substringBeforeLast(_ delimiter: String) -> String {
        guard let range = base.range(of: delimiter, options: .backwards) else { return base }
        return String(base[..<range.lowerBound])
    }

    /// Returns substring after the last occurrence of delimiter, or the whole string if not found (Kotlin: `substringAfterLast(delimiter)`).
    public func substringAfterLast(_ delimiter: String) -> String {
        guard let range = base.range(of: delimiter, options: .backwards) else { return base }
        return String(base[range.upperBound...])
    }

    // MARK: - trim

    /// Removes leading and trailing whitespace (Kotlin: `trim()`).
    public func trim() -> String {
        base.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes leading whitespace (Kotlin: `trimStart()`).
    public func trimStart() -> String {
        String(base.drop(while: { $0.isWhitespace }))
    }

    /// Removes trailing whitespace (Kotlin: `trimEnd()`).
    public func trimEnd() -> String {
        String(base.reversed().drop(while: { $0.isWhitespace }).reversed())
    }

    /// Trims indentation: detects common minimal indent and removes it from every line (Kotlin: `trimIndent()`).
    public func trimIndent() -> String {
        let lines = base.split(separator: "\n", omittingEmptySubsequences: false)
        let nonEmpty = lines.filter { !$0.allSatisfy { $0.isWhitespace } }
        guard !nonEmpty.isEmpty else {
            return base.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let minIndent = nonEmpty.map { line -> Int in
            line.prefix(while: { $0 == " " || $0 == "\t" }).count
        }.min() ?? 0
        return lines.map { line in
            if line.count >= minIndent {
                return String(line.dropFirst(minIndent))
            }
            return String(line)
        }.joined(separator: "\n")
    }

    /// Trims leading margin: removes leading whitespace from each line up to and including the first occurrence of marginPrefix (Kotlin: `trimMargin(marginPrefix)`).
    public func trimMargin(marginPrefix: String = "|") -> String {
        base.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            let trimmed = line.drop(while: { $0.isWhitespace })
            if trimmed.hasPrefix(marginPrefix) {
                return String(trimmed.dropFirst(marginPrefix.count))
            }
            return String(line)
        }.joined(separator: "\n")
    }
}
