# SwiftKT

A Swift Package that re-implements **Kotlin standard library** APIs in Swift: **String**, **Number**, **Collection**, and **Map**. Function and property names match Kotlin so you can port Kotlin code or share mental models across platforms.

- **Swift 5.9+**
- **Swift Package Manager**
- **No external dependencies**
- **SwiftLint compliant**
- **Unicode-safe** where applicable (e.g. grapheme clusters for String)
- **Fully documented** with [behavioral differences](Documentation/BehavioralDifferences.md) from Kotlin

**When to use:** Porting Kotlin code to Swift, keeping cross-platform (e.g. Android + iOS) APIs aligned, or preferring Kotlin-style names and semantics in Swift.

## Usage

### String

Access Kotlin-style String APIs via the `.kotlin` proxy:

```swift
import SwiftKT

// Predicates
"  ".kotlin.isBlank()        // true
"hello".kotlin.isNotEmpty()  // true

// Search
"hello".kotlin.indexOf("l")           // 2
"hello".kotlin.startsWith("he")       // true
"hello".kotlin.regionMatches(thisOffset: 1, other: "bcxy", otherOffset: 0, length: 2)  // true

// Transform
"  hello  ".kotlin.trim()             // "hello"
"hello".kotlin.substringBefore("l")  // "he"
"hello".kotlin.replace(oldValue: "l", newValue: "x")  // "hexxo"

// Split & padding
"a-b-c".kotlin.split(delimiter: "-")  // ["a", "b", "c"]
"1".kotlin.padStart(length: 3, padChar: "0")  // "001"
"ab".kotlin.repeat(n: 3)               // "ababab"

// Regex (returns Optional; use optional binding)
if let regex = "l+".kotlin.toRegex() {
    "hello".kotlin.contains(regex)  // true
}

// Collection-like
"123456".kotlin.chunked(size: 2)      // ["12", "34", "56"]
"hello".kotlin.filter { $0 != "l" }   // "heo"
"hello".kotlin.count { $0 == "l" }    // 2
```

### Number

Use `.kotlin` on numeric types for conversions, parsing, coercion, bitwise ops, and range helpers:

```swift
5.kotlin.toLong()                      // 5
42.kotlin.toString(radix: 16)         // "2a"
try 3.14.kotlin.roundToInt()           // 3
"99".kotlin.toIntOrNull()              // 99 (Optional)
(-2).kotlin.coerceAtLeast(0)           // 0
10.kotlin.until(15).step(2)           // 10, 12, 14
```

### Collection

Use `.kotlin` on any `Collection` for predicates, transformations, retrieval, aggregation, chunking, and zip:

```swift
[1, 2, 3].kotlin.all { $0 > 0 }       // true
[1, 2, 3].kotlin.firstOrNull()         // 1
[1, 2, 3].kotlin.chunked(size: 2)     // [[1, 2], [3]]
[1, 2, 3].kotlin.sumOf { $0 }         // 6
```

### Map

Use `.kotlinMap` on a `Dictionary` for Kotlin-style map APIs:

```swift
let map = ["a": 1, "b": 2]
map.kotlinMap.getOrDefault("a", defaultValue: 0)  // 1
map.kotlinMap.getOrDefault("z", defaultValue: 0)  // 0
map.kotlinMap.getOrElse("z") { 42 }              // 42 (lazy)
map.kotlinMap.containsKey("a")                    // true
map.kotlinMap.mapValues { _, v in v * 2 }        // ["a": 2, "b": 4]
```

See [Documentation/BehavioralDifferences.md](Documentation/BehavioralDifferences.md) for Numbers, Collections, and Maps (indexing, ordering, exceptions, optional values).

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/anahjz/SwiftKT.git", from: "1.0.0")
]
```

Then add `SwiftKT` to your target dependencies.

### CocoaPods (binary)

```ruby
pod 'SwiftKT-Binary', '~> 1.0'
```

## API surface

### String (`.kotlin` on `String`)
- **Properties:** `length`, `indices`, `lastIndex`
- **Predicates:** `isEmpty()`, `isBlank()`, `isNotEmpty()`, `isNotBlank()`
- **Search:** `contains`, `startsWith`, `endsWith`, `indexOf`, `lastIndexOf`, `matches`, `regionMatches`
- **Transform:** `lowercase`, `uppercase`, `capitalize`, `decapitalize`, `replace`, `replaceFirst`, `replaceRange`, `substring*`, `trim`, `trimStart`, `trimEnd`, `trimIndent`, `trimMargin`
- **Split:** `split`, `lines`
- **Padding:** `padStart`, `padEnd`, `repeat`
- **Regex:** `toRegex`
- **Collection-like:** `chunked`, `windowed`, `zip`, `filter`, `filterNot`, `map`, `mapIndexed`, `all`, `any`, `none`, `count`
- **Char access:** `get(index:)`, `first()`, `last()`, `firstOrNull()`, `lastOrNull()`

### Number (`.kotlin` on `BinaryInteger` / `BinaryFloatingPoint`)
- **Conversions:** `toByte()`, `toShort()`, `toInt()`, `toLong()`, `toFloat()`, `toDouble()`, `toString()`, `toString(radix:)`
- **Parsing:** `String.kotlin.toInt()`, `toIntOrNull()`, `toLong()`, `toLongOrNull()`, `toDouble()`, `toDoubleOrNull()`, `toFloat()`, `toFloatOrNull()`
- **Comparison:** `compareTo()`, `equals()`, `hashCode()`
- **Coercion:** `coerceAtLeast()`, `coerceAtMost()`, `coerceIn()`
- **Ranges:** `until()`, `downTo()`, `step()`
- **Bitwise (integers):** `and()`, `or()`, `xor()`, `inv()`, `shl()`, `shr()`, `ushr()`
- **Floating-point:** `isNaN()`, `isInfinite()`, `isFinite()`, `absoluteValue`, `sign`, `roundToInt()`, `roundToLong()`

### Collection (`.kotlin` on `Collection`)
- **Predicates:** `all()`, `any()`, `none()`, `count()` / `count(predicate:)`
- **Transform:** `map()`, `mapIndexed()`, `flatMap()`, `filter()`, `filterNot()`, `filterIndexed()`, `distinct()`, `distinctBy()`
- **Association / grouping:** `associate()`, `associateBy()`, `associateWith()`, `groupBy()`
- **Retrieval:** `first()`, `firstOrNull()`, `last()`, `lastOrNull()`, `single()`, `singleOrNull()`, `getOrNull(index:)`
- **Aggregation:** `sumOf()`, `maxOrNull()`, `minOrNull()`, `maxByOrNull()`, `minByOrNull()`
- **Windowing:** `chunked()`, `windowed()`
- **Zip:** `zip()`, `zip(transform:)`
- **Index-based:** `forEachIndexed()`

### Map (`.kotlinMap` on `Dictionary`)
- **Retrieval:** `getOrDefault()`, `getOrElse()`
- **Containment:** `containsKey()`, `containsValue()`
- **Filtering:** `filterKeys()`, `filterValues()`
- **Transform:** `mapValues()`, `mapKeys()`

See [Documentation/BehavioralDifferences.md](Documentation/BehavioralDifferences.md) for how SwiftKT differs from Kotlin (Unicode, indexing, regex, locale, numbers, collections, maps).
