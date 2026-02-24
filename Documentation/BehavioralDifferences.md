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

