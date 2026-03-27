# Getting Started with FixedPointDecimal

Create, manipulate, and convert fixed-point decimal values for financial calculations.

## Overview

`FixedPointDecimal` provides exact decimal arithmetic backed by a single `Int64`, delivering orders-of-magnitude better performance than `Foundation.Decimal` for latency-sensitive code paths.

## Creating Values

### Creating Values

The most convenient way to create values is using Swift literal syntax, which
the literal at compile time and produces a constant with zero runtime overhead:

```swift
let price: FixedPointDecimal = 42            // integer literal
let rate: FixedPointDecimal = 123.45         // decimal literal
let bid: FixedPointDecimal = 99.95           // decimal literal
let missing = FixedPointDecimal("nan")    // NaN sentinel
```

### From Strings (Failable)

For user input or untrusted data, use the failable string initializer:

```swift
let price = FixedPointDecimal("123.45")    // Optional(123.45)
let bad = FixedPointDecimal("abc")         // nil
let nan = FixedPointDecimal("nan")         // Optional(.nan)
```

### From Other Types

```swift
let fromInt: FixedPointDecimal = 42          // 42.00000000
let fromDouble: FixedPointDecimal = 3.14     // 3.14000000
let fromDecimal = FixedPointDecimal(someFoundationDecimal)
```

## Arithmetic

All operators match Swift `Int` behavior -- they trap on overflow:

```swift
let a: FixedPointDecimal = 10.25
let b: FixedPointDecimal = 3

a + b           // 13.25
a - b           // 7.25
a * b           // 30.75
a / b           // 3.41666667 (banker's rounding)
a % b           // 1.25

// Integer and float literals resolved at compile time
a * 100         // 1025
a * 0.5         // 5.125
```

For performance-critical hot paths where overflow and NaN are proven impossible:

```swift
// Wrapping operators (no validation, no NaN checks — raw Int64 semantics)
a &+ b
a &- b
a &* b

// Overflow-reporting
let (sum, overflow) = a.addingReportingOverflow(b)
```

## Rounding

Six rounding modes are available:

```swift
let value: FixedPointDecimal = 123.456789
value.rounded(scale: 2)                    // 123.46 (banker's rounding)
value.rounded(scale: 2, .towardZero)      // 123.45
value.rounded(scale: 0, .up)              // 124
```

## Conversions

```swift
// To/from Double (pure Swift, no Foundation)
let d = Double(somePrice)                 // 123.45
let fromD: FixedPointDecimal = 123.45

// To/from Foundation.Decimal (for UI display)
let dec = Decimal(somePrice)              // always exact
let fromDec = FixedPointDecimal(someDecimal)

// To integer (truncates fractional part, matching Int(someDouble))
let i = Int(somePrice)                    // 123
```

## NaN Support

A sentinel-based NaN value propagates through all operations:

```swift
let missing = FixedPointDecimal.nan
missing.isNaN                              // true
(missing + someValue).isNaN                // true (propagates)
missing == .nan                            // true (sentinel semantics)
```

## Codable

Encodes as a human-readable JSON string, decodes flexibly:

```swift
let data = try JSONEncoder().encode(price) // "123.45"
let decoded = try JSONDecoder().decode(
    FixedPointDecimal.self, from: data
)
```

## Atomic Operations

Lock-free atomic operations via the `Synchronization` module:

```swift
import Synchronization

let bestBid = Atomic<FixedPointDecimal>(FixedPointDecimal(100.50))
bestBid.store(FixedPointDecimal(100.55), ordering: .releasing)
let current = bestBid.load(ordering: .acquiring)
```
