# Behavioral Differences: SwiftKT vs Kotlin String

This document describes where SwiftKT’s behavior intentionally or necessarily differs from Kotlin’s standard library String API.

---

## 1. Unicode and indexing

### Grapheme clusters

- **Kotlin (JVM):** `String` is UTF-16 based. `length` is the number of UTF-16 code units. Indexing is by code unit.
- **Swift:** `String` is grapheme-cluster (Unicode scalar) based. `length` on `KotlinStringProxy` is `String.count`, i.e. the number of extended grapheme clusters.

**Effect:**

- Emoji and other multi-code-unit graphemes (e.g. `"café"` with composed `é`) have one “character” in Swift but may be 2+ code units in Kotlin.
- `"👋🏼".kotlin.length` is `1` in SwiftKT; on the JVM the same string has a larger `length`.
- Index-based APIs (`get(index:)`, `substring(startIndex:endIndex:)`, etc.) operate on grapheme indices in SwiftKT. Results can differ from Kotlin when the string contains multi-unit graphemes.

### Index bounds and negative indices

- **Kotlin:** Negative indices or indices `>= length` throw (e.g. `StringIndexOutOfBoundsException`).
- **SwiftKT:** Out-of-bounds or negative indices either return a safe value (e.g. `-1` for “not found”) or throw `KotlinStringError.indexOutOfBounds`. We do not use C-style negative indexing.

---

## 2. Case conversion

- **Kotlin (JVM):** Default case conversion is locale-sensitive (e.g. `Locale.getDefault()`).
- **Swift:** `lowercased()` / `uppercased()` use the current locale.

So:

- `lowercase()` / `uppercase()` in SwiftKT are locale-sensitive in the same way as the rest of the Swift environment, which may not match the JVM default locale.
- Edge cases (e.g. Turkish `"i".uppercased()`) can differ between Kotlin and SwiftKT if locales differ.

---

## 3. Regex

- **Kotlin:** Uses the JVM `java.util.regex` API.
- **SwiftKT:** Uses `NSRegularExpression` (ICU-backed on Apple platforms).

So:

- Most common patterns behave the same.
- Subtle differences can appear in:
  - Character classes and Unicode handling
  - Lookahead / lookbehind
  - Capturing group semantics and replacement
- **Kotlin:** `toRegex()` throws on invalid pattern.
- **SwiftKT:** `toRegex()` returns `nil` on invalid pattern (no throw) to avoid force unwraps and to align with Swift style.

---

## 4. Substring type

- **Kotlin:** Substring operations return new `String` instances.
- **Swift:** `String` subscript and some operations yield `Substring`, a view into the original `String`.

SwiftKT’s public API always returns `String` (e.g. `substring(startIndex:endIndex:)`, `substringBefore(_:)`, etc.), so you get Kotlin-like behavior and no `Substring` lifetime issues.

---

## 5. Nullability

- **Kotlin:** Uses nullable types (e.g. `firstOrNull()`, `lastOrNull()`).
- **Swift:** No null; we use `Optional`.

So:

- `firstOrNull()` / `lastOrNull()` return `Character?`; use optional binding or `nil` checks as in normal Swift.

---

## 6. Performance

- **Indexing:** Kotlin can use O(1) code-unit indexing. Swift `String` does not offer O(1) indexing by integer; index operations may be O(n) in the index value. Large strings and heavy index-based use can be slower in SwiftKT than on the JVM.
- **Copying:** Substring and replace operations in SwiftKT create new `String` values as in Kotlin; we avoid unnecessary copies but do not expose `Substring` in the public API.

---

## 7. Summary table

| Topic              | Kotlin (JVM)     | SwiftKT                          |
|--------------------|------------------|-----------------------------------|
| Length             | UTF-16 code units| Grapheme cluster count            |
| Index type         | Int (code unit)  | Int (grapheme offset)             |
| Out-of-bounds      | Exception        | `KotlinStringError` or safe value |
| Case conversion    | Default locale   | Current Swift locale              |
| Regex engine       | java.util.regex  | NSRegularExpression              |
| Invalid regex      | Throws           | Returns `nil`                     |
| Substring type     | String           | String (never Substring in API)   |
| Null / not found   | null / -1        | nil / -1                          |

These differences are the main ones to keep in mind when porting Kotlin String code to Swift using SwiftKT.
