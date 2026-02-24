//
//  ExceptionHelpers.swift
//  SwiftKT
//
//  Helpers to mirror Kotlin exception semantics using Swift's precondition and error types.
//

import Foundation

/// Mirrors Kotlin's `IllegalArgumentException` using `preconditionFailure` in Swift.
///
/// Use this only where Kotlin would unconditionally throw for programmer error
/// (e.g. invalid `size` in `chunked(size)`), and where returning an Optional
/// or throwing a domain-specific Error would hide programmer mistakes.
@inline(__always)
internal func kotlinIllegalArgument(_ message: @autoclosure () -> String) -> Never {
    preconditionFailure(message())
}

