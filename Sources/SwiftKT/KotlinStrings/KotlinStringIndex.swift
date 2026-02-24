//
//  KotlinStringIndex.swift
//  SwiftKT
//
//  Kotlin-style index handling for Swift String.
//  Swift uses String.Index (grapheme-based); Kotlin uses Int (code unit / UTF-16 based on platform).
//  We expose Int-based API and convert internally, respecting extended grapheme clusters.
//

import Foundation

// MARK: - Index conversion (internal)

enum KotlinStringIndex {

    /// Converts a Kotlin-style Int index to String.Index.
    /// Returns nil if index is negative or beyond endIndex (Kotlin would throw).
    /// Complexity: O(n) in the index value for forward indexing; Swift String does not have O(1) random access by Int.
    static func stringIndex(for base: String, kotlinIndex: Int) -> String.Index? {
        guard kotlinIndex >= 0 else { return nil }
        let count = base.count
        guard kotlinIndex <= count else { return nil }
        if kotlinIndex == 0 { return base.startIndex }
        if kotlinIndex == count { return base.endIndex }
        return base.index(base.startIndex, offsetBy: kotlinIndex)
    }

    /// Returns the Kotlin-style Int index for a String.Index.
    static func kotlinIndex(for base: String, stringIndex idx: String.Index) -> Int? {
        guard base.startIndex <= idx, idx <= base.endIndex else { return nil }
        return base.distance(from: base.startIndex, to: idx)
    }

    /// Valid range of Kotlin indices: 0..<count (endIndex in Kotlin terms is length, exclusive).
    static func validRange(for base: String) -> Range<Int> {
        0..<base.count
    }
}
