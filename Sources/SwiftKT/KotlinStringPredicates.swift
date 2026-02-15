//
//  KotlinStringPredicates.swift
//  SwiftKT
//
//  Kotlin String predicate APIs: isEmpty, isBlank, isNotEmpty, isNotBlank.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - Predicates

    /// Returns true if the string is empty (Kotlin: `isEmpty()`).
    public func isEmpty() -> Bool {
        base.isEmpty
    }

    /// Returns true if the string is empty or consists only of whitespace (Kotlin: `isBlank()`).
    public func isBlank() -> Bool {
        base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns true if the string is not empty (Kotlin: `isNotEmpty()`).
    public func isNotEmpty() -> Bool {
        !base.isEmpty
    }

    /// Returns true if the string has at least one non-whitespace character (Kotlin: `isNotBlank()`).
    public func isNotBlank() -> Bool {
        !base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
