# Type Design

The complete specification of FixedPointDecimal's structure, semantics, and design rationale.

## Overview

`FixedPointDecimal` is a fixed-point decimal number with 8 fractional digits, backed by a 64-bit signed integer. The value `1.23` is stored internally as `123_000_000`.

```swift
@frozen
public struct FixedPointDecimal: Sendable, BitwiseCopyable {
    internal var _storage: Int64
}
```

## Range

- Minimum: `-92,233,720,368.54775807`
- Maximum: `92,233,720,368.54775807`
- Smallest positive: `0.00000001`

## NaN Semantics

NaN is represented by the sentinel value `Int64.min` (-9,223,372,036,854,775,808).

This value was chosen because:
- It has no valid negation in `Int64` (negating `Int64.min` overflows in two's complement)
- It is outside the range of any practical financial value
- Checking `isNaN` is a single integer comparison

NaN uses **sentinel semantics**, not IEEE 754:
- `NaN == NaN` returns `true` (required for `Hashable` and `Comparable` correctness)
- NaN compares less than all non-NaN values (provides a strict total order for sorting)
- Arithmetic with NaN propagates NaN (any operation involving NaN returns NaN)
- `init(_ decimal: Decimal)` maps `Decimal.nan` to `.nan`; `Decimal(.nan)` returns `Decimal.nan`
- `isFinite` returns `false` for NaN, `true` for all other values
- `sign` returns `.plus` for NaN (NaN is excluded from the negative check)

## Why @frozen?

The `@frozen` attribute guarantees the struct's memory layout will not change, enabling the compiler to:
- Inline field access across module boundaries
- Eliminate retain/release overhead (value semantics, stack-allocated)
- Lay out arrays as contiguous memory (critical for dense `ContiguousArray<FixedPointDecimal>` storage)

The trade-off (inability to add stored properties in future ABI-compatible releases) is acceptable because the type has a single stored property by design.

## Why Trapping Arithmetic by Default?

Financial systems must never silently produce incorrect values. A trapping overflow:
1. Immediately surfaces bugs during development and testing
2. Prevents silent corruption in production
3. Matches Swift standard library convention (`Int + Int` traps on overflow)

Hot-path code can opt into wrapping variants (`&+`, `&-`, `&*`) where the programmer has proven overflow and NaN cannot occur. These perform no validation — no NaN checks, no overflow traps, no sentinel adjustment — matching Swift `Int` wrapping operator semantics exactly.

## Why Int128 Intermediate for Multiplication/Division?

Multiplying two `FixedPointDecimal` values requires computing `(a * b) / 10^8`. Without widening, the internal storage multiplication can overflow `Int64` for values as small as ~9,600 (since 9600 x 10^8 x 9600 x 10^8 > Int64.max).

With `Int128` intermediate:
- Widening to `Int128` before multiplication can represent the full range of products
- Division by the scale factor brings the result back to `Int64` range
- Swift 6.2 provides native `Int128`, so this adds no external dependency

## Rounding Policy

All entry points use a single canonical rounding policy: **banker's rounding** (round half to even, IEEE 754 `roundTiesToEven`). This applies uniformly to:

- **String parsing** — digits beyond 8 fractional places
- **`Double` conversion** — sub-tick rounding from binary floating-point
- **`Decimal` conversion** — precision beyond 8 decimal places
- **Multiplication and division** — when the exact result has more than 8 fractional digits

When the exact result has more than 8 fractional digits, the 9th digit determines rounding:

- If the discarded portion is less than half a ULP: round toward zero (truncate)
- If greater than half a ULP: round away from zero
- If exactly half a ULP: round to the nearest even digit

This is the standard rounding mode for financial arithmetic and matches `Foundation.Decimal`'s default behavior. Having one policy across all entry points means the same decimal input always produces the same stored value regardless of the construction path.

The explicit `rounded(scale:_:)` method supports six rounding modes for user-directed rounding at specific decimal places: `toNearestOrEven` (default), `toNearestOrAwayFromZero`, `towardZero`, `awayFromZero`, `down` (toward -infinity), and `up` (toward +infinity).

## Protocol Conformances

### Core (all platforms)

`Sendable`, `BitwiseCopyable`, `AtomicRepresentable`, `Equatable`, `Hashable`, `Comparable`, `AdditiveArithmetic`, `Numeric`, `SignedNumeric`, `Strideable`, `Codable`, `CustomStringConvertible`, `CustomDebugStringConvertible`, `LosslessStringConvertible`, `CustomReflectable`, `ExpressibleByIntegerLiteral`

### SwiftUI (macOS/iOS)

`VectorArithmetic` (enables animations), `Plottable` (enables Swift Charts)

### Foundation (all platforms)

`FormatStyle`, `ParseableFormatStyle`
