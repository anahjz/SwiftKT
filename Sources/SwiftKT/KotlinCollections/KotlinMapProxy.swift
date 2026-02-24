//
//  KotlinMapProxy.swift
//  SwiftKT
//
//  Kotlin-style Map APIs for Swift dictionaries, exposed via a proxy to avoid
//  polluting the native `Dictionary` namespace.
//

import Foundation

/// Proxy type that exposes Kotlin `Map` extension APIs for a Swift dictionary.
///
/// Public API mirrors Kotlin stdlib names and nullability as closely as Swift allows.
public struct KotlinMapProxy<Key: Hashable, Value>: Sendable {

    internal let base: [Key: Value]

    internal init(_ base: [Key: Value]) {
        self.base = base
    }
}

// MARK: - Retrieval

extension KotlinMapProxy {

    /// Kotlin: `getOrDefault(key, defaultValue)`
    ///
    /// If the key exists, returns the corresponding value; otherwise returns the
    /// provided default value. Does not mutate the map.
    public func getOrDefault(_ key: Key, defaultValue: Value) -> Value {
        if let value = base[key] {
            return value
        }
        return defaultValue
    }

    /// Kotlin: `getOrElse(key, defaultValue)`
    ///
    /// - Parameter defaultValue: Closure that is evaluated only when the key is absent.
    public func getOrElse(_ key: Key, defaultValue: () -> Value) -> Value {
        if let value = base[key] {
            return value
        }
        return defaultValue()
    }
}

// MARK: - Containment

extension KotlinMapProxy {

    /// Kotlin: `containsKey(key)`
    ///
    /// Uses dictionary key lookup; works even when `Value` is optional.
    public func containsKey(_ key: Key) -> Bool {
        base[key] != nil
    }

    /// Kotlin: `containsValue(value)`
    ///
    /// Requires `Value` to be `Equatable` to compare values.
    public func containsValue(_ value: Value) -> Bool where Value: Equatable {
        for candidate in base.values {
            if candidate == value {
                return true
            }
        }
        return false
    }
}

// MARK: - Filtering

extension KotlinMapProxy {

    /// Kotlin: `filterKeys(predicate)`
    ///
    /// Returns a new dictionary containing entries whose keys satisfy `predicate`.
    public func filterKeys(_ predicate: (Key) -> Bool) -> [Key: Value] {
        var result: [Key: Value] = [:]
        result.reserveCapacity(base.count)
        for (key, value) in base {
            if predicate(key) {
                result[key] = value
            }
        }
        return result
    }

    /// Kotlin: `filterValues(predicate)`
    ///
    /// Returns a new dictionary containing entries whose values satisfy `predicate`.
    public func filterValues(_ predicate: (Value) -> Bool) -> [Key: Value] {
        var result: [Key: Value] = [:]
        result.reserveCapacity(base.count)
        for (key, value) in base {
            if predicate(value) {
                result[key] = value
            }
        }
        return result
    }
}

// MARK: - Transformations

extension KotlinMapProxy {

    /// Kotlin: `mapValues(transform)`
    ///
    /// Returns a new dictionary with the same keys and transformed values.
    public func mapValues<R>(_ transform: (Key, Value) -> R) -> [Key: R] {
        var result: [Key: R] = [:]
        result.reserveCapacity(base.count)
        for (key, value) in base {
            result[key] = transform(key, value)
        }
        return result
    }

    /// Kotlin: `mapKeys(transform)`
    ///
    /// Returns a new dictionary whose keys are the result of applying `transform`
    /// to each entry's key. Values are preserved.
    ///
    /// If `transform` produces duplicate keys, the entry corresponding to the
    /// last key encountered will overwrite earlier ones, matching Kotlin's
    /// "last write wins" semantics.
    public func mapKeys<R: Hashable>(_ transform: (Key, Value) -> R) -> [R: Value] {
        var result: [R: Value] = [:]
        result.reserveCapacity(base.count)
        for (key, value) in base {
            let newKey = transform(key, value)
            kotlinInsertLastWins(into: &result, key: newKey, value: value)
        }
        return result
    }
}

