# Interoperability

Converting between FixedPointDecimal, Foundation.Decimal, and Double.

## Overview

The system has three numeric domains, each with a clear role:

```
Double                       Numerical computation
   | init(_: Double)         (pricing models, analytics)
   v
FixedPointDecimal            Core financial types:
   | Decimal(x)              Price, Quantity, etc.
   v                         Hot paths, storage, wire format
Foundation.Decimal           UI display, user input,
                             formatting, localization
```

**Rule**: `FixedPointDecimal` is the canonical type for financial data. Conversions to/from `Double` and `Foundation.Decimal` happen at the edges -- never in performance-critical paths.

## Double Conversions

### Creating from Double

```swift
let price: FixedPointDecimal = 123.45        // rounded to 8 decimals
let safe = FixedPointDecimal(exactly: 1.5) // Optional -- nil if overflow
```

The maximum error is +/-5 x 10^-9, which is sub-tick for all practical financial instruments.

### Converting to Double

```swift
let d = Double(somePrice)                  // exact for <= 15 significant digits
let d2 = Double(exactly: somePrice)        // nil if not exactly representable
```

## Foundation.Decimal Conversions

### Creating from Decimal

```swift
let price = FixedPointDecimal(someDecimal)        // rounds beyond 8 digits (banker's rounding)
let safe = FixedPointDecimal(exactly: someDecimal) // nil if precision > 8 digits, overflow, or NaN
```

Precision beyond 8 decimal places is rounded using banker's rounding (round half to even). The `exactly` variant returns `nil` if the value has any precision beyond 8 decimal places, ensuring no silent rounding occurs.

### Converting to Decimal

```swift
let dec = Decimal(somePrice)               // always exact
let dec2 = Decimal(exactly: somePrice)     // nil for NaN
```

This conversion is always exact -- 8 fractional digits fit easily within Decimal's 38-digit capacity.

## NaN Interoperability

| Source | Target | Behavior |
|---|---|---|
| `Decimal.nan` | `FixedPointDecimal` | `init(_:)` maps to `.nan`; `init?(exactly:)` returns `nil` |
| `FixedPointDecimal.nan` | `Decimal` | `Decimal(x)` returns `Decimal.nan` |
| `Double.nan` | `FixedPointDecimal` | `init(_:)` traps; `init?(exactly:)` returns `nil` |
| `FixedPointDecimal.nan` | `Double` | `Double(x)` returns `Double.nan` |

## Anti-Patterns

### Do NOT convert in hot paths

```swift
// BAD: Converting on every iteration
for item in items {
    let price = FixedPointDecimal(someDecimal) // Decimal->FPD every time!
}

// GOOD: Convert once, use FixedPointDecimal throughout
let price = FixedPointDecimal(someDecimal)
for item in items {
    // use price directly
}
```

### Do NOT use Double as an intermediary

```swift
// BAD: precision loss
let double = Double(truncating: decimal)
let fixed = FixedPointDecimal(double)

// GOOD: direct conversion
let fixed = FixedPointDecimal(decimal)
```

## Platform Considerations

The `FixedPointDecimal` core type has zero Foundation dependency. Only `FixedPointDecimal+Decimal.swift` imports Foundation, and it uses only the public `Decimal` API (`NSDecimalMultiply`, `NSDecimalNumber(decimal:).int64Value`), which is available on all platforms including Linux via swift-foundation.
