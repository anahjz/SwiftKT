//
//  IndexingHelpers.swift
//  SwiftKT
//
//  Helpers for safe, generic indexing over arbitrary Collections without assuming
//  random-access indices.
//

import Foundation

/// Returns the element at the given integer offset from the start of the collection,
/// or `nil` if the offset is out of bounds.
///
/// This is O(n) in the offset value for non-random-access collections, matching
/// the cost characteristics of Kotlin's `Iterable`-based operations.
internal func kotlinElementAtOrNil<C: Collection>(
    _ collection: C,
    offset: Int
) -> C.Element? {
    guard offset >= 0 else { return nil }
    var index = collection.startIndex
    var i = 0
    while index != collection.endIndex {
        if i == offset {
            return collection[index]
        }
        collection.formIndex(after: &index)
        i += 1
    }
    return nil
}

/// Iterates over a collection yielding `(index, element)` pairs where `index`
/// is a zero-based `Int` offset, without assuming random access.
@usableFromInline
internal func kotlinForEachIndexed<C: Collection>(
    _ collection: C,
    body: (Int, C.Element) -> Void
) {
    var idx = 0
    for element in collection {
        body(idx, element)
        idx += 1
    }
}

