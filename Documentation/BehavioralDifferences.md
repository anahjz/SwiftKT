# Behavioral Differences: SwiftKT vs Kotlin

This document describes where SwiftKT’s behavior intentionally or necessarily differs from Kotlin’s standard library **String** and **Number** APIs.

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

## 7. Summary table (String)

| Topic              | Kotlin (JVM)     | SwiftKT                           |
|--------------------|------------------|-----------------------------------|
| Length             | UTF-16 code units| Grapheme cluster count            |
| Index type         | Int (code unit)  | Int (grapheme offset)             |
| Out-of-bounds      | Exception        | `KotlinStringError` or safe value |
| Case conversion    | Default locale   | Current Swift locale              |
| Regex engine       | java.util.regex  | NSRegularExpression               |
| Invalid regex      | Throws           | Returns `nil`                     |
| Substring type     | String           | String (never Substring in API)   |
| Null / not found   | null / -1        | nil / -1                          |

These differences are the main ones to keep in mind when porting Kotlin String code to Swift using SwiftKT.

---

## 8. Numbers and numeric conversions

### 8.1 Integer width and mapping

- **Kotlin:** Distinct primitive widths: `Byte` (8‑bit), `Short` (16‑bit), `Int` (32‑bit), `Long` (64‑bit), with fixed ranges on all platforms.
- **Swift:** `Int` and `UInt` are pointer-sized (64‑bit on Apple platforms), with fixed-width variants (`Int8`, `Int16`, `Int32`, `Int64`, etc.).

**SwiftKT mapping:**

- Kotlin `Int`   → primarily modeled by Swift `Int`
- Kotlin `Long`  → Swift `Int64`
- Kotlin `Short` → Swift `Int16`
- Kotlin `Byte`  → Swift `Int8`
- Kotlin `UInt` / `ULong` → Swift `UInt` / `UInt64`

Most APIs are generic over `BinaryInteger` and adopt Kotlin’s *narrowing* and *widening* semantics using truncation (for narrow targets) and sign‑preserving widening.

### 8.2 Integer narrowing conversions (`toByte`, `toShort`, `toInt`, `toLong`, `toUInt`, `toULong`)

- **Kotlin (JVM):** Narrowing integer conversions (e.g. `Long.toInt()`, `Int.toByte()`) keep the least‑significant bits in two’s complement representation. No exceptions are thrown; overflow wraps.
- **SwiftKT:** Uses `truncatingIfNeeded` for all integer‑to‑integer conversions in `KotlinNumberProxy`, which:
  - Preserves the least‑significant bits in two’s complement.
  - Matches Kotlin/JVM behavior for all bit patterns.

**Effect:**

- Overflow **never traps** for integer‑to‑integer conversions on the proxy; values wrap just like Kotlin.

### 8.3 Floating‑point to integer conversions (`toInt`, `toLong`, etc.)

- **Kotlin:** For `Double`/`Float` to integer (`toInt`, `toLong`, etc.):
  - Truncates toward zero.
  - NaN maps to `0`.
  - Values below the target range clamp to the type’s `MIN_VALUE`.
  - Values above the target range clamp to the type’s `MAX_VALUE`.
- **Swift:** Direct integer initializers from floating‑point trap on overflow and use rounding toward zero.

**SwiftKT behavior (in `KotlinFloatingPointProxy`):**

- Truncates toward zero using Swift’s integer initialization but **only after**:
  - Mapping NaN → `0`.
  - Clamping values below `min` to `min`, and above `max` to `max`.

This avoids traps while matching Kotlin’s documented behavior.

### 8.4 Floating‑point rounding (`roundToInt`, `roundToLong`)

- **Kotlin (`kotlin.math.roundToInt` / `roundToLong`):**
  - Rounds to the nearest integer; ties (x.5) round toward **positive infinity** (Java’s `Math.round` semantics).
  - NaN throws `IllegalArgumentException`.
  - ±infinity clamp to integer min/max.
- **Swift:** `rounded()` without an explicit rule uses “toNearestOrAwayFromZero”, which differs for negative ties.

**SwiftKT behavior:**

- Implements Kotlin rounding semantics manually:
  - For `x >= 0`: uses `floor(x + 0.5)`.
  - For `x < 0`: uses `ceil(x - 0.5)`.
  - NaN throws `KotlinNumberError.invalidRoundingOperand`.
  - ±infinity and out‑of‑range results clamp to the corresponding integer min/max.

### 8.5 NaN and comparison (`compareTo`)

- **Kotlin (Double/Float primitives):**
  - Comparisons are based on IEEE 754; NaN is unordered with respect to all values, but `compareTo` is specified via platform intrinsics and usually mirrors `Double.compare`/`Float.compare`.
  - In practice on the JVM, `compareTo` treats NaN as greater than any finite value, and NaN compares equal to NaN in that context.
- **Swift:** Relational operators follow IEEE 754:
  - Any comparison with NaN using `<`, `>`, `==` is `false` (except `!=`).

**SwiftKT behavior (in `KotlinFloatingPointProxy.compareTo`):**

- Follows the “NaN is greater, NaN equals NaN in compareTo” rule:
  - `NaN.compareTo(x)` → `> 0` for finite `x`.
  - `x.compareTo(NaN)` → `< 0` for finite `x`.
  - `NaN.compareTo(NaN)` → `0`.
- For finite values, ordering matches Swift’s `<`/`>` semantics.

### 8.6 Hash codes (`hashCode`)

- **Kotlin:** `hashCode()` for numbers is stable by spec across runs for the same value.
- **Swift:** `hashValue` is not guaranteed to be stable across processes or Swift versions.

**SwiftKT behavior:**

- `hashCode()` on numeric proxies delegates to `hashValue`.
- This may differ from Kotlin/JVM where hash codes are stable across launches; use only for in‑process hashing, not for persistent keys.

### 8.7 Parsing (`String.toInt`, `toIntOrNull`, `toLong`, `toDouble`, etc.)

- **Kotlin:**
  - `String.toInt(radix)` / `toLong(radix)`:
    - Throw `NumberFormatException` on invalid format or overflow.
    - Throw `IllegalArgumentException` on invalid radix (outside 2..36).
  - `String.toIntOrNull(radix)` / `toLongOrNull(radix)`:
    - Return `null` on invalid format or overflow.
    - Still throw `IllegalArgumentException` on invalid radix.
  - `String.toDouble()` / `toFloat()`:
    - Throw `NumberFormatException` on invalid format.
    - `toDoubleOrNull()` / `toFloatOrNull()` return `null` instead of throwing.
- **Swift:** Standard initializers like `Int("123")`/`Double("3.14")` return `nil` instead of throwing, and have no built‑in radix‑validated integer parser that throws.

**SwiftKT behavior (in `KotlinStringProxy`):**

- Integer parsing (`toInt`, `toLong`, `toIntOrNull`, `toLongOrNull`):
  - Validate radix and throw `KotlinNumberError.invalidRadix` if not in `2...36`.
  - Implement manual digit‑by‑digit parsing with:
    - Optional leading `+` / `-`.
    - Radix‑aware digit validation for `0‑9`, `a‑z`, `A‑Z`.
    - Overflow detection using `multipliedReportingOverflow` / `addingReportingOverflow`.
  - `toInt` / `toLong`:
    - Throw `KotlinNumberError.invalidFormat` on invalid digits or overflow.
  - `toIntOrNull` / `toLongOrNull`:
    - Return `nil` for invalid digits or overflow.
    - Still throw `KotlinNumberError.invalidRadix` for invalid radix to mirror Kotlin.
- Floating‑point parsing (`toDouble`, `toFloat`, `toDoubleOrNull`, `toFloatOrNull`):
  - Use Swift’s `Double`/`Float` initializers.
  - `toDouble` / `toFloat` throw `KotlinNumberError.invalidFormat` when the initializer returns `nil`.
  - `toDoubleOrNull` / `toFloatOrNull` return optional values directly, matching Kotlin’s nullable contract.

### 8.8 Bitwise operations (`and`, `or`, `xor`, `inv`, `shl`, `shr`, `ushr`)

- **Kotlin:** All integer types support bitwise operations; shift counts are masked by `bitWidth - 1` (e.g. for `Int`, shift by `32` is equivalent to shift by `0`).
- **Swift:** Shifts with counts outside `0..<bitWidth` are a precondition failure (trap).

**SwiftKT behavior (in `KotlinNumberProxy` for `FixedWidthInteger`):**

- All bitwise operators (`and`, `or`, `xor`, `inv`) delegate to Swift’s `&`, `|`, `^`, `~`.
- Shift operations:
  - Mask shift counts using `bitCount & (bitWidth - 1)` to avoid traps and to mirror Kotlin masking behavior.
  - `shl`/`shr` use Swift’s `<<`/`>>` on the signed value.
  - `ushr`:
    - Converts the value to the unsigned `Magnitude` representation.
    - Performs a right shift on the magnitude.
    - Reconstructs the signed type via `truncatingIfNeeded`, giving a logical (zero‑filling) shift.

These differences are the main ones to keep in mind when porting Kotlin String and Number code to Swift using SwiftKT.

---

## 9. Collections

### 9.1 Indexing and iteration

- **Kotlin:** `List` and array types typically support O(1) integer indexing; many collection APIs are defined on `Iterable` but specialized implementations for lists use random access internally.
- **Swift:** `Collection` indices are abstract; integer indexing is not guaranteed and can be O(n) unless the type is `RandomAccessCollection`.

**SwiftKT behavior:**

- All index-based Kotlin-style APIs (`getOrNull(index)`, `mapIndexed`, `filterIndexed`, `forEachIndexed`) use linear iteration from `startIndex`, counting an `Int` offset.
- This matches the complexity of Kotlin’s `Iterable` implementations and is correct for all `Collection` types at the cost of O(n) index lookups.

### 9.2 Exceptions vs thrown errors

- **Kotlin:** Throws:
  - `NoSuchElementException` for `first()`, `last()`, `single()` on empty collections.
  - `IllegalArgumentException` for invalid arguments (e.g. `chunked(0)`, `windowed(size=0)`).
  - `IndexOutOfBoundsException` for invalid indices.
- **Swift:** Collection APIs typically use preconditions (`fatalError` / `preconditionFailure`) rather than typed exceptions.

**SwiftKT behavior:**

- `first()`, `last()`, `single()` and their predicate variants:
  - Throw `KotlinCollectionError.noSuchElement` when no matching element exists.
- `single()` on collections with more than one element:
  - Throws `KotlinCollectionError.illegalState("Expected single element but was multiple")`.
- Programmer errors such as:
  - `chunked(size: 0)`
  - `windowed(size: 0, step: 0)`
  - `windowed(step: 0, ...)`
  use `kotlinIllegalArgument`, which calls `preconditionFailure` with an explanatory message, mirroring Kotlin’s `IllegalArgumentException`.

### 9.3 Ordering and dictionaries

- **Kotlin:** `groupBy` and `associate*` functions return `Map`. On the JVM, `LinkedHashMap` is used so iteration order preserves insertion order for keys.
- **Swift:** `Dictionary` preserves insertion order for keys in current standard library implementations, but this is not a guaranteed part of the ABI across all platforms and versions.

**SwiftKT behavior:**

- `associate`, `associateBy`, `associateWith`, and `groupBy` all return native `Dictionary` values.
- In practice, insertion order is preserved when iterating these dictionaries, matching Kotlin’s observable behavior, but this is not formally guaranteed by the Swift language.
- When multiple elements map to the same key, the **last** element wins (overwrites previous), matching Kotlin.

### 9.4 Windowing and chunking

- **Kotlin:** `chunked` and `windowed` on `Iterable` allocate intermediate lists but are optimized for lists internally.
- **SwiftKT:** Both `chunked` and `windowed` operate on a single `Array` copy of the base collection:
  - `chunked(size)`:
    - Size must be > 0 (otherwise precondition failure via `kotlinIllegalArgument`).
    - Returns trailing partial chunk, just like Kotlin.
  - `windowed(size, step, partialWindows)`:
    - `size` and `step` must be > 0 (otherwise precondition failure).
    - `partialWindows` determines whether trailing partial windows are included.
  - Transform variants `chunked(size, transform)` and `windowed(..., transform)` simply map over the produced slices.

### 9.5 Distinct and hashing

- **Kotlin:** `distinct()` and `distinctBy()` rely on hash sets and equality; ordering of first occurrences is preserved.
- **SwiftKT:** Uses `Set` for `distinct()` and `distinctBy(selector)`:
  - Preserves the **first** occurrence of each element or key.
  - Requires `Hashable` keys for `distinctBy` to keep complexity near O(n).

### 9.6 Sum aggregation

- **Kotlin:** `sumOf` is generic over numeric types and uses platform-specific widening rules.
- **SwiftKT:** Implements a small, explicit overload set:
  - `sumOf(selector: (Element) -> Int) -> Int`
  - `sumOf(selector: (Element) -> Int64) -> Int64`
  - `sumOf(selector: (Element) -> Double) -> Double`
  - `sumOf(selector: (Element) -> Float) -> Float`
- Integer variants use wrapping addition (`&+`) to mirror Kotlin/JVM overflow semantics; floating-point variants use normal `+` and follow IEEE 754 rules.

### 9.7 Nullability and Optionals

- **Kotlin:** `firstOrNull()`, `lastOrNull()`, `singleOrNull()`, `maxOrNull()`, `minOrNull()`, `maxByOrNull`, `minByOrNull` return nullable types that are `null` when no element exists.
- **SwiftKT:** All of these return `Optional` (`Element?`) in the same situations. No force unwrap is used; callers must handle the optional results explicitly.

---

## 10. Maps

### 10.1 Dictionary vs Map

- **Kotlin:** `Map<K, V>` is an interface, commonly backed by `LinkedHashMap` on the JVM, which preserves insertion order.
- **Swift:** `Dictionary<Key, Value>` is a concrete value type. Since Swift 5, the standard library preserves insertion order for keys, but this is a library detail rather than a hard language guarantee.

**SwiftKT behavior:**

- `KotlinMapProxy<Key, Value>` wraps a Swift `[Key: Value]` and exposes Kotlin-style `Map` APIs (e.g. `getOrDefault`, `getOrElse`, `containsKey`, `containsValue`, `filterKeys`, `filterValues`, `mapValues`, `mapKeys`).
- Ordering when iterating a dictionary created by these operations matches Swift’s dictionary insertion order, which in practice aligns with Kotlin’s `LinkedHashMap` behavior.

### 10.2 getOrDefault / getOrElse

- **Kotlin:**
  - `getOrDefault(key, defaultValue)`:
    - Returns `map[key]` if present, otherwise `defaultValue`.
  - `getOrElse(key) { default }`:
    - Returns `map[key]` if present.
    - Otherwise, evaluates the lambda and returns its result (lazy).
- **SwiftKT:**
  - `getOrDefault(_ key: Key, defaultValue: Value) -> Value`:
    - Uses `base[key]` and returns `defaultValue` when `nil`.
    - Works correctly even when `Value` itself is optional, because `base[key]` is `Value?` and `.some(nil)` is distinguishable from `nil`.
  - `getOrElse(_ key: Key, defaultValue: () -> Value) -> Value`:
    - Evaluates `defaultValue` **only** when `base[key]` is `nil`.

### 10.3 containsKey / containsValue

- **Kotlin:**
  - `containsKey(key)` uses key lookup.
  - `containsValue(value)` scans all values with equality checks.
- **SwiftKT:**
  - `containsKey(_ key: Key) -> Bool`:
    - Implemented via `base[key] != nil`, which is true even when `Value` is an optional holding `nil`. This matches Kotlin’s semantics that “key is present” is independent of stored value.
  - `containsValue(_ value: Value) -> Bool where Value: Equatable`:
    - Iterates `base.values` and compares each value via `==`.
    - Only available when `Value` conforms to `Equatable`; this is stricter than Kotlin, which can rely on platform equality for arbitrary types.

### 10.4 Filtering and transformations

- **Kotlin:**
  - `filterKeys`, `filterValues` produce a `Map` with the same value or key type respectively.
  - `mapValues` keeps keys and transforms values.
  - `mapKeys` transforms keys and keeps values; when key collisions occur, the entry with the last key wins.
- **SwiftKT:**
  - `filterKeys(_ predicate: (Key) -> Bool) -> [Key: Value]`
  - `filterValues(_ predicate: (Value) -> Bool) -> [Key: Value]`
  - `mapValues(_ transform: (Key, Value) -> R) -> [Key: R]`
  - `mapKeys(_ transform: (Key, Value) -> R) -> [R: Value] where R: Hashable`
    - On key collisions in `mapKeys`, the value from the **last** element in the original dictionary iteration overwrites previous ones, matching Kotlin’s “last write wins” semantics.

### 10.5 Optional values

- **Kotlin:** `Map<K, V?>` is common; keys can exist with a `null` value.
- **SwiftKT:** Dictionaries may store `Optional` values (`[Key: Value?]`):
  - `getOrDefault` respects existing keys whose value is `nil` (returns `.some(nil)`), and falls back only when the key is absent.
  - `containsKey` uses `base[key] != nil` so keys with `nil` values are still considered present, mirroring Kotlin.


