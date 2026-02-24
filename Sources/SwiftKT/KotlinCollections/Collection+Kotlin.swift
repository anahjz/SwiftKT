//
//  Collection+Kotlin.swift
//  SwiftKT
//
//  Entry point: Collection.kotlin / MutableCollection.kotlinMutable provide
//  the Kotlin stdlib Collection API surface on Swift collections.
//

import Foundation

// MARK: - Collection extension

extension Collection {

    /// Provides the Kotlin standard library Collection API surface.
    ///
    /// Example:
    /// ```swift
    /// [1, 2, 3].kotlin.all { $0 > 0 }   // true
    /// [1, 2, 3].kotlin.map { $0 * 2 }  // [2, 4, 6]
    /// ```
    public var kotlin: KotlinCollectionProxy<Self> {
        KotlinCollectionProxy(self)
    }
}

// MARK: - MutableCollection extension

extension MutableCollection {

    /// Provides the Kotlin standard library mutable Collection API surface.
    ///
    /// Mutable-specific APIs can be added to `KotlinMutableCollectionProxy` in
    /// future milestones. For the current milestone, it simply exposes the same
    /// read-only operations as `KotlinCollectionProxy`.
    public var kotlinMutable: KotlinMutableCollectionProxy<Self> {
        KotlinMutableCollectionProxy(self)
    }
}

