# SwiftKT

A Swift Package that re-implements the **Kotlin standard library String** API surface in Swift. Function and property names match Kotlin exactly so you can port Kotlin code or share mental models across platforms.

- **Swift 5.9+**
- **Swift Package Manager**
- **No external dependencies**
- **SwiftLint compliant**
- **Unicode-safe** (grapheme clusters)
- **Fully documented** with behavioral differences from Kotlin

## Usage

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

## API surface (first milestone)

- **Properties:** `length`, `indices`, `lastIndex`
- **Predicates:** `isEmpty()`, `isBlank()`, `isNotEmpty()`, `isNotBlank()`
- **Search:** `contains`, `startsWith`, `endsWith`, `indexOf`, `lastIndexOf`, `matches`, `regionMatches`
- **Transform:** `lowercase`, `uppercase`, `capitalize`, `decapitalize`, `replace`, `replaceFirst`, `replaceRange`, `substring*`, `trim`, `trimStart`, `trimEnd`, `trimIndent`, `trimMargin`
- **Split:** `split`, `lines`
- **Padding:** `padStart`, `padEnd`, `repeat`
- **Regex:** `toRegex`
- **Collection-like:** `chunked`, `windowed`, `zip`, `filter`, `filterNot`, `map`, `mapIndexed`, `all`, `any`, `none`, `count`
- **Char access:** `get(index:)`, `first()`, `last()`, `firstOrNull()`, `lastOrNull()`

See [Documentation/BehavioralDifferences.md](Documentation/BehavioralDifferences.md) for how SwiftKT differs from Kotlin (Unicode, indexing, regex, locale).
