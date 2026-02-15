//
//  KotlinStringSplit.swift
//  SwiftKT
//
//  Kotlin String splitting APIs: split, lines.
//

import Foundation

extension KotlinStringProxy {

    // MARK: - split

    /// Splits this string around matches of the given delimiter (Kotlin: `split(delimiter)`).
    /// Returns [String]; empty segments are included when limit allows.
    public func split(delimiter: Character, limit: Int = 0) -> [String] {
        let parts = base.split(separator: delimiter, omittingEmptySubsequences: false)
        if limit > 0 {
            let joined = parts.prefix(limit - 1)
            let rest = parts.dropFirst(limit - 1)
            if rest.isEmpty {
                return joined.map(String.init)
            }
            let restJoined = rest.map(String.init).joined(separator: String(delimiter))
            return joined.map(String.init) + [restJoined]
        }
        return parts.map(String.init)
    }

    /// Splits this string around matches of the given string delimiter (Kotlin: `split(delimiter: String)`).
    public func split(delimiter: String, limit: Int = 0) -> [String] {
        if delimiter.isEmpty {
            return limit > 0 ? Array(base.map(String.init).prefix(limit)) : base.map(String.init)
        }
        var result: [String] = []
        var remaining = base
        var count = 0
        while count + 1 != limit, let range = remaining.range(of: delimiter) {
            result.append(String(remaining[..<range.lowerBound]))
            remaining = String(remaining[range.upperBound...])
            count += 1
        }
        result.append(remaining)
        return result
    }

    /// Splits by regex (Kotlin: `split(regex)`). Returns [String].
    public func split(regex: NSRegularExpression, limit: Int = 0) -> [String] {
        let nsString = base as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        var matches: [NSRange] = []
        regex.enumerateMatches(in: base, options: [], range: fullRange) { match, _, _ in
            guard let m = match else { return }
            matches.append(m.range)
        }
        if matches.isEmpty {
            return [base]
        }
        var result: [String] = []
        var start = 0
        for (_, m) in matches.enumerated() {
            if limit > 0 && result.count + 1 >= limit {
                result.append(nsString.substring(from: start))
                return result
            }
            result.append(nsString.substring(with: NSRange(location: start, length: m.location - start)))
            start = m.location + m.length
        }
        result.append(nsString.substring(from: start))
        return result
    }

    /// Splits by character predicate (Kotlin: `split(predicate)`). Returns [String].
    public func split(where predicate: (Character) -> Bool) -> [String] {
        base.split(whereSeparator: predicate).map(String.init)
    }

    // MARK: - lines

    /// Splits this string into lines (Kotlin: `lines()`). Uses \n, \r\n, \r.
    public func lines() -> [String] {
        base.components(separatedBy: .newlines)
    }
}
