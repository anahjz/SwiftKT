//
//  KotlinNumberRange.swift
//  SwiftKT
//
//  Minimal range/progression type used to mirror Kotlin's `until`, `downTo`, and `step`
//  helpers for integer types.
//

import Foundation

/// Sequence that models Kotlin's `IntRange` / `LongRange` / `IntProgression` in a lightweight way.
///
/// - `start`: first value in the progression.
/// - `endInclusive`: last value that may be produced.
/// - `step`: stride between successive elements; must be non-zero.
public struct KotlinNumberProgression<T>: Sequence where T: Strideable & Comparable, T.Stride: SignedInteger {

    public let start: T
    public let endInclusive: T
    public let step: T.Stride

    public init(start: T, endInclusive: T, step: T.Stride) {
        precondition(step != 0, "step must be non-zero")
        self.start = start
        self.endInclusive = endInclusive
        self.step = step
    }

    public func makeIterator() -> AnyIterator<T> {
        var current = start
        let step = self.step
        let end = endInclusive

        return AnyIterator {
            if step > 0 {
                if current > end { return nil }
            } else {
                if current < end { return nil }
            }
            let value = current
            current = current.advanced(by: step)
            return value
        }
    }

    /// Kotlin: `step(n)`
    ///
    /// Returns a new progression with the same bounds but a different (positive) step.
    /// Negative or zero steps are rejected to match Kotlin's `IllegalArgumentException`.
    public func step(_ newStep: T.Stride) throws -> KotlinNumberProgression<T> {
        guard newStep > 0 else {
            throw KotlinNumberError.invalidRange(
                min: "step",
                max: "must be positive"
            )
        }
        let effectiveStep = (step > 0) ? newStep : -newStep
        return KotlinNumberProgression(start: start, endInclusive: endInclusive, step: effectiveStep)
    }
}

