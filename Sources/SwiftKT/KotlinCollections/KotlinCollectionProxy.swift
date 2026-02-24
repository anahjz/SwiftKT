//
//  KotlinCollectionProxy.swift
//  SwiftKT
//
//  Kotlin-style Collection APIs for arbitrary Swift collections, exposed via
//  the `.kotlin` proxy to avoid polluting native types.
//

import Foundation

/// Proxy type that exposes Kotlin Collection extension APIs for a Swift `Collection`.
///
/// Public API mirrors Kotlin stdlib names and nullability as closely as Swift allows.
public struct KotlinCollectionProxy<Base: Collection>: Sendable {

    @usableFromInline
    internal let base: Base

    @usableFromInline
    internal init(_ base: Base) {
        self.base = base
    }
}

// MARK: - Predicates

extension KotlinCollectionProxy {

    /// Kotlin: `all(predicate)`
    public func all(_ predicate: (Base.Element) -> Bool) -> Bool {
        for element in base {
            if !predicate(element) {
                return false
            }
        }
        return true
    }

    /// Kotlin: `any()`
    public func any() -> Bool {
        base.isEmpty == false
    }

    /// Kotlin: `any(predicate)`
    public func any(_ predicate: (Base.Element) -> Bool) -> Bool {
        for element in base {
            if predicate(element) {
                return true
            }
        }
        return false
    }

    /// Kotlin: `none()`
    public func none() -> Bool {
        !any()
    }

    /// Kotlin: `none(predicate)`
    public func none(_ predicate: (Base.Element) -> Bool) -> Bool {
        !any(predicate)
    }

    /// Kotlin: `count()`
    public func count() -> Int {
        base.count
    }

    /// Kotlin: `count(predicate)`
    public func count(_ predicate: (Base.Element) -> Bool) -> Int {
        var c = 0
        for element in base where predicate(element) {
            c += 1
        }
        return c
    }
}

// MARK: - Transformations

extension KotlinCollectionProxy {

    /// Kotlin: `map(transform)`
    public func map<R>(_ transform: (Base.Element) -> R) -> [R] {
        var result: [R] = []
        result.reserveCapacity(base.underestimatedCount)
        for element in base {
            result.append(transform(element))
        }
        return result
    }

    /// Kotlin: `mapIndexed(transform)`
    public func mapIndexed<R>(_ transform: (Int, Base.Element) -> R) -> [R] {
        var result: [R] = []
        result.reserveCapacity(base.underestimatedCount)
        var index = 0
        for element in base {
            result.append(transform(index, element))
            index += 1
        }
        return result
    }

    /// Kotlin: `flatMap(transform)`
    ///
    /// This variant expects the transform to return an `Array` so the result
    /// can be flattened into a single `Array`.
    public func flatMap<R>(_ transform: (Base.Element) -> [R]) -> [R] {
        var result: [R] = []
        for element in base {
            let segment = transform(element)
            result.append(contentsOf: segment)
        }
        return result
    }

    /// Kotlin: `filter(predicate)`
    public func filter(_ predicate: (Base.Element) -> Bool) -> [Base.Element] {
        var result: [Base.Element] = []
        result.reserveCapacity(base.underestimatedCount)
        for element in base where predicate(element) {
            result.append(element)
        }
        return result
    }

    /// Kotlin: `filterNot(predicate)`
    public func filterNot(_ predicate: (Base.Element) -> Bool) -> [Base.Element] {
        var result: [Base.Element] = []
        result.reserveCapacity(base.underestimatedCount)
        for element in base where !predicate(element) {
            result.append(element)
        }
        return result
    }

    /// Kotlin: `filterIndexed(predicate)`
    public func filterIndexed(_ predicate: (Int, Base.Element) -> Bool) -> [Base.Element] {
        var result: [Base.Element] = []
        result.reserveCapacity(base.underestimatedCount)
        var index = 0
        for element in base {
            if predicate(index, element) {
                result.append(element)
            }
            index += 1
        }
        return result
    }
}

// MARK: - Distinct

extension KotlinCollectionProxy where Base.Element: Hashable {

    /// Kotlin: `distinct()`
    ///
    /// Preserves the first occurrence order of each element.
    public func distinct() -> [Base.Element] {
        var seen: Set<Base.Element> = []
        var result: [Base.Element] = []
        result.reserveCapacity(base.underestimatedCount)
        for element in base {
            let (inserted, _) = seen.insert(element)
            if inserted {
                result.append(element)
            }
        }
        return result
    }
}

extension KotlinCollectionProxy {

    /// Kotlin: `distinctBy(selector)`
    ///
    /// - Note: The selected key type `K` must be `Hashable` to enable efficient
    ///         duplicate suppression.
    public func distinctBy<K: Hashable>(_ selector: (Base.Element) -> K) -> [Base.Element] {
        var seen: Set<K> = []
        var result: [Base.Element] = []
        result.reserveCapacity(base.underestimatedCount)
        for element in base {
            let key = selector(element)
            let (inserted, _) = seen.insert(key)
            if inserted {
                result.append(element)
            }
        }
        return result
    }
}

// MARK: - Association / Grouping

extension KotlinCollectionProxy {

    /// Kotlin: `associate(transform)`
    ///
    /// The `transform` closure must return `(key, value)` pairs.
    public func associate<K: Hashable, V>(
        _ transform: (Base.Element) -> (K, V)
    ) -> [K: V] {
        var result: [K: V] = [:]
        for element in base {
            let (key, value) = transform(element)
            result[key] = value
        }
        return result
    }

    /// Kotlin: `associateBy(keySelector)`
    ///
    /// When multiple elements map to the same key, the last one wins, matching Kotlin.
    public func associateBy<K: Hashable>(
        _ keySelector: (Base.Element) -> K
    ) -> [K: Base.Element] {
        var result: [K: Base.Element] = [:]
        for element in base {
            let key = keySelector(element)
            result[key] = element
        }
        return result
    }

    /// Kotlin: `associateBy(keySelector, valueTransform)`
    public func associateBy<K: Hashable, V>(
        _ keySelector: (Base.Element) -> K,
        valueTransform: (Base.Element) -> V
    ) -> [K: V] {
        var result: [K: V] = [:]
        for element in base {
            let key = keySelector(element)
            let value = valueTransform(element)
            result[key] = value
        }
        return result
    }

    /// Kotlin: `associateWith(valueSelector)`
    ///
    /// Requires the elements themselves to be `Hashable` so they can be used as keys.
    public func associateWith<V>(
        _ valueSelector: (Base.Element) -> V
    ) -> [Base.Element: V] where Base.Element: Hashable {
        var result: [Base.Element: V] = [:]
        for element in base {
            let value = valueSelector(element)
            result[element] = value
        }
        return result
    }

    /// Kotlin: `groupBy(keySelector)`
    public func groupBy<K: Hashable>(
        _ keySelector: (Base.Element) -> K
    ) -> [K: [Base.Element]] {
        var result: [K: [Base.Element]] = [:]
        for element in base {
            let key = keySelector(element)
            result[key, default: []].append(element)
        }
        return result
    }

    /// Kotlin: `groupBy(keySelector, valueTransform)`
    public func groupBy<K: Hashable, V>(
        _ keySelector: (Base.Element) -> K,
        valueTransform: (Base.Element) -> V
    ) -> [K: [V]] {
        var result: [K: [V]] = [:]
        for element in base {
            let key = keySelector(element)
            let value = valueTransform(element)
            result[key, default: []].append(value)
        }
        return result
    }
}

// MARK: - Retrieval

extension KotlinCollectionProxy {

    /// Kotlin: `first()`
    ///
    /// - Throws: `KotlinNumberError.invalidFormat` equivalent is not appropriate here;
    ///           we instead surface `KotlinCollectionError.noSuchElement` via fatalError-like
    ///           semantics in future if needed. For now, we model failure as `Error`.
    public func first() throws -> Base.Element {
        guard let first = base.first else {
            throw KotlinCollectionError.noSuchElement
        }
        return first
    }

    /// Kotlin: `first(predicate)`
    public func first(_ predicate: (Base.Element) -> Bool) throws -> Base.Element {
        for element in base where predicate(element) {
            return element
        }
        throw KotlinCollectionError.noSuchElement
    }

    /// Kotlin: `firstOrNull()`
    public func firstOrNull() -> Base.Element? {
        base.first
    }

    /// Kotlin: `firstOrNull(predicate)`
    public func firstOrNull(_ predicate: (Base.Element) -> Bool) -> Base.Element? {
        for element in base where predicate(element) {
            return element
        }
        return nil
    }

    /// Kotlin: `last()`
    public func last() throws -> Base.Element {
        guard let last = base.reversed().first else {
            throw KotlinCollectionError.noSuchElement
        }
        return last
    }

    /// Kotlin: `last(predicate)`
    public func last(_ predicate: (Base.Element) -> Bool) throws -> Base.Element {
        var found: Base.Element?
        for element in base where predicate(element) {
            found = element
        }
        guard let value = found else {
            throw KotlinCollectionError.noSuchElement
        }
        return value
    }

    /// Kotlin: `lastOrNull()`
    public func lastOrNull() -> Base.Element? {
        base.reversed().first
    }

    /// Kotlin: `lastOrNull(predicate)`
    public func lastOrNull(_ predicate: (Base.Element) -> Bool) -> Base.Element? {
        var found: Base.Element?
        for element in base where predicate(element) {
            found = element
        }
        return found
    }

    /// Kotlin: `single()`
    public func single() throws -> Base.Element {
        var iterator = base.makeIterator()
        guard let first = iterator.next() else {
            throw KotlinCollectionError.noSuchElement
        }
        if iterator.next() != nil {
            throw KotlinCollectionError.illegalState("Expected single element but was multiple")
        }
        return first
    }

    /// Kotlin: `singleOrNull()`
    public func singleOrNull() -> Base.Element? {
        var iterator = base.makeIterator()
        guard let first = iterator.next() else {
            return nil
        }
        if iterator.next() != nil {
            return nil
        }
        return first
    }

    /// Kotlin: `getOrNull(index)`
    public func getOrNull(_ index: Int) -> Base.Element? {
        kotlinElementAtOrNil(base, offset: index)
    }
}

// MARK: - Aggregation

extension KotlinCollectionProxy {

    /// Kotlin: `sumOf(selector)` for `Int`.
    public func sumOf(_ selector: (Base.Element) -> Int) -> Int {
        var sum = 0
        for element in base {
            sum &+= selector(element)
        }
        return sum
    }

    /// Kotlin: `sumOf(selector)` for `Int64` / `Long`.
    public func sumOf(_ selector: (Base.Element) -> Int64) -> Int64 {
        var sum: Int64 = 0
        for element in base {
            sum &+= selector(element)
        }
        return sum
    }

    /// Kotlin: `sumOf(selector)` for `Double`.
    public func sumOf(_ selector: (Base.Element) -> Double) -> Double {
        var sum: Double = 0
        for element in base {
            sum += selector(element)
        }
        return sum
    }

    /// Kotlin: `sumOf(selector)` for `Float`.
    public func sumOf(_ selector: (Base.Element) -> Float) -> Float {
        var sum: Float = 0
        for element in base {
            sum += selector(element)
        }
        return sum
    }
}

extension KotlinCollectionProxy where Base.Element: Comparable {

    /// Kotlin: `maxOrNull()`
    public func maxOrNull() -> Base.Element? {
        var iterator = base.makeIterator()
        guard var best = iterator.next() else { return nil }
        while let next = iterator.next() {
            if next > best {
                best = next
            }
        }
        return best
    }

    /// Kotlin: `minOrNull()`
    public func minOrNull() -> Base.Element? {
        var iterator = base.makeIterator()
        guard var best = iterator.next() else { return nil }
        while let next = iterator.next() {
            if next < best {
                best = next
            }
        }
        return best
    }
}

extension KotlinCollectionProxy {

    /// Kotlin: `maxByOrNull(selector)`
    public func maxByOrNull<R: Comparable>(
        _ selector: (Base.Element) -> R
    ) -> Base.Element? {
        var iterator = base.makeIterator()
        guard let first = iterator.next() else { return nil }
        var bestElement = first
        var bestKey = selector(first)
        while let next = iterator.next() {
            let key = selector(next)
            if key > bestKey {
                bestKey = key
                bestElement = next
            }
        }
        return bestElement
    }

    /// Kotlin: `minByOrNull(selector)`
    public func minByOrNull<R: Comparable>(
        _ selector: (Base.Element) -> R
    ) -> Base.Element? {
        var iterator = base.makeIterator()
        guard let first = iterator.next() else { return nil }
        var bestElement = first
        var bestKey = selector(first)
        while let next = iterator.next() {
            let key = selector(next)
            if key < bestKey {
                bestKey = key
                bestElement = next
            }
        }
        return bestElement
    }
}

// MARK: - Windowing / Chunking

extension KotlinCollectionProxy {

    /// Kotlin: `chunked(size)`
    public func chunked(_ size: Int) -> [[Base.Element]] {
        guard size > 0 else {
            kotlinIllegalArgument("chunked(size): size must be > 0")
        }
        let array = Array(base)
        if array.isEmpty {
            return []
        }
        var result: [[Base.Element]] = []
        result.reserveCapacity((array.count + size - 1) / size)
        var index = 0
        while index < array.count {
            let end = min(index + size, array.count)
            result.append(Array(array[index..<end]))
            index += size
        }
        return result
    }

    /// Kotlin: `chunked(size, transform)`
    public func chunked<R>(
        _ size: Int,
        transform: ([Base.Element]) -> R
    ) -> [R] {
        chunked(size).map(transform)
    }

    /// Kotlin: `windowed(size)`
    public func windowed(_ size: Int) -> [[Base.Element]] {
        windowed(size, step: 1, partialWindows: false)
    }

    /// Kotlin: `windowed(size, step)`
    public func windowed(
        _ size: Int,
        step: Int
    ) -> [[Base.Element]] {
        windowed(size, step: step, partialWindows: false)
    }

    /// Kotlin: `windowed(size, step, partialWindows)`
    public func windowed(
        _ size: Int,
        step: Int,
        partialWindows: Bool
    ) -> [[Base.Element]] {
        guard size > 0 else {
            kotlinIllegalArgument("windowed(size): size must be > 0")
        }
        guard step > 0 else {
            kotlinIllegalArgument("windowed(step): step must be > 0")
        }

        let array = Array(base)
        var result: [[Base.Element]] = []
        if array.isEmpty {
            return result
        }

        var index = 0
        while index < array.count {
            let end = index + size
            if end > array.count && !partialWindows {
                break
            }
            let clampedEnd = min(end, array.count)
            if index < clampedEnd {
                result.append(Array(array[index..<clampedEnd]))
            }
            index += step
        }

        return result
    }

    /// Kotlin: `windowed(size, step, partialWindows, transform)`
    public func windowed<R>(
        _ size: Int,
        step: Int,
        partialWindows: Bool,
        transform: ([Base.Element]) -> R
    ) -> [R] {
        windowed(size, step: step, partialWindows: partialWindows).map(transform)
    }
}

// MARK: - Zip

extension KotlinCollectionProxy {

    /// Kotlin: `zip(other)`
    public func zip<Other: Collection>(
        _ other: Other
    ) -> [(Base.Element, Other.Element)] {
        var result: [(Base.Element, Other.Element)] = []
        var it1 = base.makeIterator()
        var it2 = other.makeIterator()
        while let e1 = it1.next(), let e2 = it2.next() {
            result.append((e1, e2))
        }
        return result
    }

    /// Kotlin: `zip(other, transform)`
    public func zip<Other: Collection, R>(
        _ other: Other,
        transform: (Base.Element, Other.Element) -> R
    ) -> [R] {
        var result: [R] = []
        var it1 = base.makeIterator()
        var it2 = other.makeIterator()
        while let e1 = it1.next(), let e2 = it2.next() {
            result.append(transform(e1, e2))
        }
        return result
    }
}

// MARK: - Index-based iteration helper

extension KotlinCollectionProxy {

    /// Kotlin: `forEachIndexed(action)`
    public func forEachIndexed(_ action: (Int, Base.Element) -> Void) {
        kotlinForEachIndexed(base, body: action)
    }
}

