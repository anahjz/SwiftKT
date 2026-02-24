//
//  KotlinMutableCollectionProxy.swift
//  SwiftKT
//
//  Mutable collection proxy. For this milestone we primarily expose the same
//  read-only operations as `KotlinCollectionProxy`, while reserving room for
//  future mutable operations (`add`, `removeIf`, etc.).
//

import Foundation

/// Proxy type that exposes Kotlin MutableCollection APIs for a Swift `MutableCollection`.
public struct KotlinMutableCollectionProxy<Base: MutableCollection>: Sendable {

    internal var base: Base

    internal init(_ base: Base) {
        self.base = base
    }
}

// Reuse all read-only operations from KotlinCollectionProxy by wrapping the base.

extension KotlinMutableCollectionProxy {

    /// Shared read-only Kotlin Collection APIs via a view proxy.
    public var readOnly: KotlinCollectionProxy<Base> {
        KotlinCollectionProxy(base)
    }
}

