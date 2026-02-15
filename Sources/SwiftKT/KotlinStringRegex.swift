//
//  KotlinStringRegex.swift
//  SwiftKT
//
//  Kotlin String regex API: toRegex. Kotlin uses JVM Regex; we use NSRegularExpression.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - toRegex

    /// Compiles this string as a regular expression (Kotlin: `toRegex()`).
    /// Returns nil if the pattern is invalid (Kotlin throws; we use Optional for safety).
    /// Note: Swift/NSRegularExpression may differ from JVM Regex in some edge cases.
    public func toRegex() -> NSRegularExpression? {
        try? NSRegularExpression(pattern: base)
    }

    /// Compiles this string as a regex with the given options (Kotlin: `toRegex(option)`).
    public func toRegex(options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: base, options: options)
    }
}
