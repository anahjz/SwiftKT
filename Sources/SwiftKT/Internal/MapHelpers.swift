//
//  MapHelpers.swift
//  SwiftKT
//
//  Internal helpers for Kotlin-style Map operations.
//

import Foundation

/// Internal helper to implement "last write wins" semantics when transforming
/// a map's keys, matching Kotlin's `mapKeys` behavior on `Map`.
@inline(__always)
internal func kotlinInsertLastWins<K: Hashable, V>(
    into dict: inout [K: V],
    key: K,
    value: V
) {
    dict[key] = value
}

