//
//  KotlinStringSearch.swift
//  SwiftKT
//
//  Kotlin String search APIs: contains, startsWith, endsWith, indexOf, lastIndexOf, matches, regionMatches.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - contains

    /// Returns true if this string contains the given character (Kotlin: `contains(char)`).
    public func contains(_ char: Character) -> Bool {
        base.contains(char)
    }

    /// Returns true if this string contains the given substring (Kotlin: `contains(string)`).
    public func contains(_ other: String) -> Bool {
        base.contains(other)
    }

    /// Returns true if this string contains the given sequence (Kotlin: `contains(CharSequence)`).
    public func contains(_ other: some StringProtocol) -> Bool {
        base.contains(other)
    }

    /// Returns true if this string contains the given regex pattern (Kotlin: `contains(Regex)`).
    /// Uses NSRegularExpression; behavior may differ slightly from JVM Regex. See documentation.
    public func contains(_ regex: NSRegularExpression) -> Bool {
        let range = NSRange(base.startIndex..., in: base)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    // MARK: - startsWith

    /// Returns true if this string starts with the given prefix (Kotlin: `startsWith(prefix)`).
    public func startsWith(_ prefix: String) -> Bool {
        base.hasPrefix(prefix)
    }

    /// Returns true if this string starts with the given prefix, optionally ignoring case (Kotlin: `startsWith(prefix, ignoreCase)`).
    public func startsWith(_ prefix: String, ignoreCase: Bool) -> Bool {
        if !ignoreCase { return base.hasPrefix(prefix) }
        return base.lowercased().hasPrefix(prefix.lowercased())
    }

    /// Returns true if this string has the given prefix at the specified startIndex (Kotlin: `startsWith(prefix, startIndex)`).
    public func startsWith(_ prefix: String, startIndex: Int) -> Bool {
        guard startIndex >= 0, startIndex <= base.count,
              let start = KotlinStringIndex.stringIndex(for: base, kotlinIndex: startIndex) else {
            return false
        }
        let suffix = base[start...]
        return suffix.hasPrefix(prefix)
    }

    /// Returns true if this string starts with the given character (Kotlin: `startsWith(char)`).
    public func startsWith(_ char: Character) -> Bool {
        base.first == char
    }

    // MARK: - endsWith

    /// Returns true if this string ends with the given suffix (Kotlin: `endsWith(suffix)`).
    public func endsWith(_ suffix: String) -> Bool {
        base.hasSuffix(suffix)
    }

    /// Returns true if this string ends with the given suffix (Kotlin: `endsWith(suffix, ignoreCase)`).
    public func endsWith(_ suffix: String, ignoreCase: Bool) -> Bool {
        if !ignoreCase { return base.hasSuffix(suffix) }
        return base.lowercased().hasSuffix(suffix.lowercased())
    }

    /// Returns true if this string ends with the given character (Kotlin: `endsWith(char)`).
    public func endsWith(_ char: Character) -> Bool {
        base.last == char
    }

    // MARK: - indexOf

    /// Returns the index of the first occurrence of the given character, or -1 if not found (Kotlin: `indexOf(char)`).
    public func indexOf(_ char: Character) -> Int {
        guard let idx = base.firstIndex(of: char) else { return -1 }
        return base.distance(from: base.startIndex, to: idx)
    }

    /// Returns the index of the first occurrence of the given character after startIndex, or -1 (Kotlin: `indexOf(char, startIndex)`).
    public func indexOf(_ char: Character, startIndex: Int) -> Int {
        guard let start = KotlinStringIndex.stringIndex(for: base, kotlinIndex: startIndex),
              startIndex >= 0, startIndex <= base.count else {
            return -1
        }
        let substring = base[start...]
        guard let idx = substring.firstIndex(of: char) else { return -1 }
        return base.distance(from: base.startIndex, to: idx)
    }

    /// Returns the index of the first occurrence of the given string, or -1 if not found (Kotlin: `indexOf(string)`).
    public func indexOf(_ string: String) -> Int {
        guard let range = base.range(of: string) else { return -1 }
        return base.distance(from: base.startIndex, to: range.lowerBound)
    }

    /// Returns the index of the first occurrence of the given string after startIndex, or -1 (Kotlin: `indexOf(string, startIndex)`).
    public func indexOf(_ string: String, startIndex: Int) -> Int {
        guard startIndex >= 0, startIndex <= base.count,
              let start = KotlinStringIndex.stringIndex(for: base, kotlinIndex: startIndex) else {
            return -1
        }
        let searchRange = start..<base.endIndex
        guard let range = base.range(of: string, range: searchRange) else { return -1 }
        return base.distance(from: base.startIndex, to: range.lowerBound)
    }

    // MARK: - lastIndexOf

    /// Returns the index of the last occurrence of the given character, or -1 if not found (Kotlin: `lastIndexOf(char)`).
    public func lastIndexOf(_ char: Character) -> Int {
        guard let idx = base.lastIndex(of: char) else { return -1 }
        return base.distance(from: base.startIndex, to: idx)
    }

    /// Returns the index of the last occurrence of the given character before endIndex (Kotlin: `lastIndexOf(char, endIndex)`).
    public func lastIndexOf(_ char: Character, endIndex: Int) -> Int {
        guard endIndex >= 0, endIndex <= base.count,
              let end = KotlinStringIndex.stringIndex(for: base, kotlinIndex: endIndex) else {
            return -1
        }
        let searchRange = base.startIndex..<end
        guard let idx = base[searchRange].lastIndex(of: char) else { return -1 }
        return base.distance(from: base.startIndex, to: idx)
    }

    /// Returns the index of the last occurrence of the given string, or -1 if not found (Kotlin: `lastIndexOf(string)`).
    public func lastIndexOf(_ string: String) -> Int {
        guard let range = base.range(of: string, options: .backwards) else { return -1 }
        return base.distance(from: base.startIndex, to: range.lowerBound)
    }

    /// Returns the index of the last occurrence of the given string before endIndex (Kotlin: `lastIndexOf(string, endIndex)`).
    public func lastIndexOf(_ string: String, endIndex: Int) -> Int {
        guard endIndex >= 0, endIndex <= base.count,
              let end = KotlinStringIndex.stringIndex(for: base, kotlinIndex: endIndex) else {
            return -1
        }
        let searchRange = base.startIndex..<end
        guard let range = base.range(of: string, options: .backwards, range: searchRange) else { return -1 }
        return base.distance(from: base.startIndex, to: range.lowerBound)
    }

    // MARK: - matches

    /// Returns true if the entire string matches the given regex (Kotlin: `matches(regex)`).
    public func matches(_ regex: NSRegularExpression) -> Bool {
        let range = NSRange(base.startIndex..., in: base)
        guard let match = regex.firstMatch(in: base, options: [], range: range) else { return false }
        return match.range.location == 0 && match.range.length == (base as NSString).length
    }

    // MARK: - regionMatches

    /// Returns true if the region of this string (thisOffset, length) matches the region of other (otherOffset, length), optionally ignoring case (Kotlin: `regionMatches`).
    public func regionMatches(
        thisOffset: Int,
        other: String,
        otherOffset: Int,
        length: Int,
        ignoreCase: Bool = false
    ) -> Bool {
        guard thisOffset >= 0, otherOffset >= 0, length >= 0,
              thisOffset + length <= base.count,
              otherOffset + length <= other.count else {
            return false
        }
        guard let thisStart = KotlinStringIndex.stringIndex(for: base, kotlinIndex: thisOffset),
              let thisEnd = KotlinStringIndex.stringIndex(for: base, kotlinIndex: thisOffset + length),
              let otherStart = KotlinStringIndex.stringIndex(for: other, kotlinIndex: otherOffset),
              let otherEnd = KotlinStringIndex.stringIndex(for: other, kotlinIndex: otherOffset + length) else {
            return false
        }
        let thisSlice = String(base[thisStart..<thisEnd])
        let otherSlice = String(other[otherStart..<otherEnd])
        if ignoreCase {
            return thisSlice.compare(otherSlice, options: .caseInsensitive) == .orderedSame
        }
        return thisSlice == otherSlice
    }
}
