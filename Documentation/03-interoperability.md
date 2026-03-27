# Interoperability — Decimal & Double Conversions

> See also [Future Int128](06-future-128bit.md).

---

## Conversion Architecture

The system has three numeric domains, each with a clear role:

```
┌─────────────────────────────┐
│   Double                    │  Numerical computation
│   (binary floating-point)   │  (pricing models, analytics)
└──────────┬──────────────────┘
           │ init(_: Double)
           ▼
┌─────────────────────────────┐
│   FixedPointDecimal         │  Core financial types:
│   (Int64 × 10^8)            │  Price, Quantity, etc.
│                             │  Hot paths, storage, wire format
└──────────┬──────────────────┘
           │ Decimal(x)
           ▼
┌─────────────────────────────┐
│   Foundation.Decimal        │  UI display, user input,
│   (128-bit mantissa)        │  formatting, localization
└─────────────────────────────┘
```

**Rule**: `FixedPointDecimal` is the canonical type for financial data. Conversions to/from `Double` and `Foundation.Decimal` happen at the edges — never in performance-critical paths.

## Conversion from Double

### Use case: Numerical computation results

Pricing models, analytics, and statistical computations typically produce `Double` results. These must be converted to `FixedPointDecimal` for downstream use:

```swift
let computedValue: Double = pricingModel.compute(...)
let price = FixedPointDecimal(computedValue)
```

### Precision analysis

`Double` has ~15–17 significant decimal digits. Converting to `FixedPointDecimal` (8 fractional digits) rounds to the nearest 10^-8:

| Double value | FixedPointDecimal | Error |
|---|---|---|
| `123.456789012345` | `123.45678901` | ~2.3 × 10^-11 |
| `0.00000001` | `0.00000001` | 0 (exact) |
| `99999.99999999` | `99999.99999999` | 0 (exact) |
| `0.1` | `0.10000000` | ~5.6 × 10^-18 |

The maximum error is ±5 × 10^-9, which is strictly sub-tick for all practical financial instruments (smallest tick size is typically 0.00000001 for cryptocurrency).

### Implementation Notes

The `init(_ value: Double)` initializer:
- Traps if the input is NaN or infinite (use `.nan` directly instead)
- Rounds the value to 8 decimal places using the internal scale factor (10^8)
- Traps if the scaled result would overflow `Int64`

### Reverse: FixedPointDecimal to Double

```swift
let d = Double(somePrice)               // exact for <= 15 significant digits
let d2 = Double(exactly: somePrice)     // nil if not exactly representable
```

## Conversion from Foundation.Decimal

### Use case: UI presentation and user input

`Foundation.Decimal` is commonly used for:
- Displaying prices via `.formatted()` and `NSDecimalNumber`
- Parsing user-entered quantities in `TextField`
- Localized number display

```swift
// Receiving a FixedPointDecimal for display:
let price: FixedPointDecimal = ...
let displayDecimal: Decimal = Decimal(price)  // exact

// Converting user input back:
let userInput: Decimal = textFieldDecimalValue
let orderPrice = FixedPointDecimal(userInput)      // banker's rounds beyond 8 digits
```

### Precision analysis

Converting `FixedPointDecimal` → `Decimal` is always exact: 8 fractional digits fit easily within Decimal's 38-digit capacity.

Converting `Decimal` → `FixedPointDecimal` rounds beyond 8 decimal places using banker's rounding (round half to even):

| Decimal value | FixedPointDecimal | Precision loss |
|---|---|---|
| `123.45` | `123.45000000` | None |
| `0.123456789012` | `0.12345679` | `≤ 5 × 10^-9` rounded |
| `99999999999.99` | overflow → nil | Value exceeds Int64 range |
| `.nan` | `.nan` | Mapped to sentinel |

This rounding is acceptable because no financial instrument has tick sizes smaller than 10^-8.

### Implementation Notes

The `init(_ decimal: Decimal)` initializer:
- Maps `Decimal.nan` to `.nan`
- Scales the value by 10^8 and applies banker's rounding (round half to even)
- Traps if the scaled result would overflow the `Int64` range

The reverse conversion (`Decimal(somePrice)`) is always exact -- 8 fractional digits fit easily within Decimal's 38-digit capacity.

## Platform Considerations

### Linux

On Linux, `Foundation.Decimal` is provided by `swift-foundation` (formerly `swift-corelibs-foundation`). The `NSDecimalNumber` bridging class has different behavior:

- Direct field access (`_mantissa`, `_exponent`) may not be available (see: [swift-foundation#934](https://github.com/apple/swift-foundation/issues/934))
- `NSDecimalNumber.int64Value` works but involves different code paths

**Mitigation**: The `FixedPointDecimal` core type has zero Foundation dependency. Only the conversion file (`FixedPointDecimal+Decimal.swift`) imports Foundation, and it uses only the public `Decimal` API (`NSDecimalMultiply`, `NSDecimalNumber(decimal:).int64Value`), which is available on all platforms.

### macOS

On macOS, `Decimal` conversions use Foundation's `NSDecimalMultiply`/`NSDecimalRound` C API. This overhead is acceptable because conversions should happen only in cold paths (UI display, user input, configuration loading) — not in performance-critical code.

## NaN Interoperability

| Source | Target | Behavior |
|---|---|---|
| `Decimal.nan` | `FixedPointDecimal` | `init(_:)` maps to `.nan`; `init?(exactly:)` returns `nil` |
| `FixedPointDecimal.nan` | `Decimal` | `Decimal(x)` returns `Decimal.nan`; `Decimal(exactly:)` returns `nil` |
| `Double.nan` | `FixedPointDecimal` | `init(_:)` traps; `init?(exactly:)` returns `nil` |
| `FixedPointDecimal.nan` | `Double` | `Double(x)` returns `Double.nan`; `Double(exactly:)` returns `nil` |

## Anti-patterns

### Do NOT convert in hot paths

```swift
// BAD: Converting on every iteration
for item in items {
    let price = FixedPointDecimal(someDecimal)  // Decimal→FPD every time!
    total += price
}

// GOOD: Convert once, use FixedPointDecimal throughout
let price = FixedPointDecimal(someDecimal)  // convert once
for item in items {
    total += price
}
```

### Do NOT use Double as an intermediary for Decimal conversion

```swift
// BAD: Double as intermediary loses precision
let decimal: Decimal = ...
let double = Double(truncating: decimal)  // precision loss!
let fixed = FixedPointDecimal(double)     // error compounds

// GOOD: Direct conversion
let fixed = FixedPointDecimal(decimal)
```
