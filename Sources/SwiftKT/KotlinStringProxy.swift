//
//  KotlinStringProxy.swift
//  SwiftKT
//
//  Entry point: String.kotlin provides the Kotlin String API surface.
//  All Kotlin String functions and properties are implemented on KotlinStringProxy.
//

import Foundation

// MARK: - String extension

extension String {

    /// Provides the Kotlin standard library String API surface.
    /// Use this to call Kotlin-named methods on Swift String.
    ///
    /// Example:
    /// ```swift
    /// "hello".kotlin.isBlank()  // false
    /// "  ".kotlin.isBlank()     // true
    /// ```
    public var kotlin: KotlinStringProxy {
        KotlinStringProxy(self)
    }
}

// MARK: - KotlinStringProxy

/// Proxy type that exposes Kotlin String API on a Swift String.
/// Function and property names match Kotlin exactly for familiarity when porting code.
public struct KotlinStringProxy: Sendable {

    /// The underlying Swift string. Internal so extension files can implement Kotlin API.
    internal let base: String

    internal init(_ base: String) {
        self.base = base
    }

    // MARK: - Properties (Kotlin: length, indices, lastIndex)

    /// The number of characters in this string (Kotlin: `length`).
    /// In Swift this is the extended grapheme cluster count; equivalent to Kotlin's character count.
    /// Note: Kotlin on JVM uses UTF-16 code units for `length`; we use grapheme count. See documentation.
    public var length: Int {
        base.count
    }

    /// The range of valid indices (0..<length). Kotlin: `indices`.
    public var indices: Range<Int> {
        0..<base.count
    }

    /// The index of the last character, or -1 if the string is empty. Kotlin: `lastIndex`.
    public var lastIndex: Int {
        base.isEmpty ? -1 : base.count - 1
    }

    // MARK: - Char access (Kotlin: get(index), first(), last(), firstOrNull(), lastOrNull())

    /// Returns the character at the given index (Kotlin: `get(index)`).
    /// - Throws: `KotlinStringError.indexOutOfBounds` if index is negative or >= length.
    public func get(index: Int) throws -> Character {
        guard let stringIndex = KotlinStringIndex.stringIndex(for: base, kotlinIndex: index),
              stringIndex < base.endIndex else {
            throw KotlinStringError.indexOutOfBounds(index: index, length: base.count)
        }
        return base[stringIndex]
    }

    /// Returns the first character (Kotlin: `first()`).
    /// - Throws: NoSuchElementException in Kotlin when empty; we throw KotlinStringError.
    public func first() throws -> Character {
        guard let character = base.first else {
            throw KotlinStringError.indexOutOfBounds(index: 0, length: 0)
        }
        return character
    }

    /// Returns the last character (Kotlin: `last()`).
    /// - Throws: NoSuchElementException in Kotlin when empty; we throw KotlinStringError.
    public func last() throws -> Character {
        guard let character = base.last else {
            throw KotlinStringError.indexOutOfBounds(index: -1, length: 0)
        }
        return character
    }

    /// Returns the first character, or nil if the string is empty (Kotlin: `firstOrNull()`).
    public func firstOrNull() -> Character? {
        base.first
    }

    /// Returns the last character, or nil if the string is empty (Kotlin: `lastOrNull()`).
    public func lastOrNull() -> Character? {
        base.last
    }
}
