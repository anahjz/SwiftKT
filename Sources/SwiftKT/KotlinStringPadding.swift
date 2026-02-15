//
//  KotlinStringPadding.swift
//  SwiftKT
//
//  Kotlin String padding and repetition: padStart, padEnd, repeat.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - padStart

    /// Pads the string with padChar to length at the start (Kotlin: `padStart(length, padChar)`).
    public func padStart(length: Int, padChar: Character = " ") -> String {
        guard length > base.count else { return base }
        return String(repeating: String(padChar), count: length - base.count) + base
    }

    // MARK: - padEnd

    /// Pads the string with padChar to length at the end (Kotlin: `padEnd(length, padChar)`).
    public func padEnd(length: Int, padChar: Character = " ") -> String {
        guard length > base.count else { return base }
        return base + String(repeating: String(padChar), count: length - base.count)
    }

    // MARK: - repeat

    /// Returns a string repeated n times (Kotlin: `repeat(n)`).
    /// Kotlin throws for n < 0; we return "" for n <= 0 to avoid force unwraps.
    public func `repeat`(n: Int) -> String { // swiftlint:disable:this identifier_name
        guard n > 0 else { return "" }
        return String(repeating: base, count: n)
    }
}
