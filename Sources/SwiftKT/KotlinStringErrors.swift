//
//  KotlinStringErrors.swift
//  SwiftKT
//
//  Errors used to mirror Kotlin exception behavior where Swift cannot use exceptions for control flow.
//

import Foundation

/// Errors that correspond to Kotlin exceptions when using the Kotlin String API surface.
public enum KotlinStringError: Error, Sendable {

    /// Thrown when an index is out of bounds (Kotlin: StringIndexOutOfBoundsException).
    case indexOutOfBounds(index: Int, length: Int)

    /// Thrown when a required match or condition is not met (e.g. invalid regex).
    case invalidArgument(String)
}
