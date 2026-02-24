//
//  KotlinStringCollection.swift
//  SwiftKT
//
//  Kotlin String collection-like APIs: chunked, windowed, zip, filter, map, all, any, none, count.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - chunked

    /// Splits this string into chunks of the given size (Kotlin: `chunked(size)`).
    /// Last chunk may be smaller. Returns [String].
    public func chunked(size: Int) -> [String] {
        guard size > 0 else { return [] }
        var result: [String] = []
        var idx = base.startIndex
        while idx < base.endIndex {
            let end = base.index(idx, offsetBy: size, limitedBy: base.endIndex) ?? base.endIndex
            result.append(String(base[idx..<end]))
            idx = end
        }
        return result
    }

    /// Splits into chunks of the given size, transforming each chunk with transform (Kotlin: `chunked(size, transform)`).
    public func chunked<T>(size: Int, transform: (String) -> T) -> [T] {
        chunked(size: size).map(transform)
    }

    // MARK: - windowed

    /// Returns a list of sliding windows of the given size (Kotlin: `windowed(size)`).
    public func windowed(size: Int, step: Int = 1, partialWindows: Bool = false) -> [String] {
        guard size > 0, step > 0 else { return [] }
        var result: [String] = []
        var idx = base.startIndex
        while idx < base.endIndex {
            guard let end = base.index(idx, offsetBy: size, limitedBy: base.endIndex) else {
                if partialWindows && idx < base.endIndex {
                    result.append(String(base[idx...]))
                }
                break
            }
            result.append(String(base[idx..<end]))
            if let next = base.index(idx, offsetBy: step, limitedBy: base.endIndex) {
                idx = next
            } else {
                break
            }
        }
        return result
    }

    // MARK: - zip

    /// Zips this string with other character-by-character (Kotlin: `zip(other)`).
    /// Returns [(Character, Character)]; length is min of the two.
    public func zip(_ other: String) -> [(Character, Character)] {
        Array(Swift.zip(base, other))
    }

    /// Zips with transform (Kotlin: `zip(other, transform)`).
    public func zip<T>(_ other: String, transform: (Character, Character) -> T) -> [T] {
        Swift.zip(base, other).map(transform)
    }

    // MARK: - filter

    /// Returns a string containing only characters that match the predicate (Kotlin: `filter(predicate)`).
    public func filter(_ predicate: (Character) -> Bool) -> String {
        String(base.filter(predicate))
    }

    /// Returns a string containing only characters that do NOT match the predicate (Kotlin: `filterNot(predicate)`).
    public func filterNot(_ predicate: (Character) -> Bool) -> String {
        String(base.filter { !predicate($0) })
    }

    // MARK: - map

    /// Returns a string of characters transformed by transform (Kotlin: `map(transform)`).
    public func map(_ transform: (Character) -> Character) -> String {
        String(base.map(transform))
    }

    /// Returns a list of values from transform (Kotlin: `map(transform)` returning list).
    public func map<T>(_ transform: (Character) -> T) -> [T] {
        base.map(transform)
    }

    /// Returns a list of values from transform with index (Kotlin: `mapIndexed(transform)`).
    public func mapIndexed<T>(_ transform: (Int, Character) -> T) -> [T] {
        base.enumerated().map { transform($0.offset, $0.element) }
    }

    /// Returns a string from mapIndexed with Character output (Kotlin: `mapIndexed(transform)` to string).
    public func mapIndexed(_ transform: (Int, Character) -> Character) -> String {
        String(base.enumerated().map { transform($0.offset, $0.element) })
    }

    // MARK: - all / any / none

    /// Returns true if all characters match the predicate (Kotlin: `all(predicate)`).
    public func all(_ predicate: (Character) -> Bool) -> Bool {
        base.allSatisfy(predicate)
    }

    /// Returns true if at least one character matches the predicate (Kotlin: `any(predicate)`).
    public func any(_ predicate: (Character) -> Bool) -> Bool {
        base.contains(where: predicate)
    }

    /// Returns true if no characters match the predicate (Kotlin: `none(predicate)`).
    public func none(_ predicate: (Character) -> Bool) -> Bool {
        !base.contains(where: predicate)
    }

    /// Returns true if string is empty (Kotlin: `any()` overload).
    public func any() -> Bool {
        !base.isEmpty
    }

    /// Returns true if no character matches (Kotlin: `none()` overload).
    public func none() -> Bool {
        base.isEmpty
    }

    // MARK: - count

    /// Returns the number of characters (Kotlin: `count()`).
    public func count() -> Int {
        base.count
    }

    /// Returns the number of characters that match the predicate (Kotlin: `count(predicate)`).
    public func count(_ predicate: (Character) -> Bool) -> Int {
        base.filter(predicate).count
    }
}
