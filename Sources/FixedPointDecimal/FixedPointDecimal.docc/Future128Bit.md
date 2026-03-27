# Future: Int128 Upgrade Path

Architecture for widening to Int128 backing when the Int64 range is insufficient.

## Overview

The `Int64`-backed `FixedPointDecimal` covers all practical financial instrument prices, quantities, and multipliers (range: +/-92 billion with 8 decimal places). An `Int128` upgrade would be motivated by:

1. **Accumulated values**: Portfolio-level notional amounts exceeding 92 billion
2. **Extreme quantities**: High-frequency fill accumulation over extended periods
3. **Cryptocurrency edge cases**: Tokens with extreme unit values
4. **Regulatory requirements**: Higher-precision or wider-range reporting

## Recommended Architecture

**Do not widen the hot-path type.** Instead, introduce a separate wide type:

| Type | Backing | Size | Use case |
|---|---|---|---|
| `FixedPointDecimal` | `Int64` | 8 bytes | `Price`, `Quantity`, all hot-path data |
| `WideFixedPointDecimal` | `Int128` | 16 bytes | Accumulated values, portfolio totals |

### Why Not Widen FixedPointDecimal?

Doubling storage from 8 to 16 bytes has cascading hot-path effects:

| Metric | Int64 (8B) | Int128 (16B) | Impact |
|---|---|---|---|
| Values per cache line | 8 | 4 | 2x cache pressure |
| ContiguousArray for 5K instruments | 40 KB | 80 KB | May exceed L1 cache |
| FlatBuffers wire size | 1.2 MB | 2.4 MB | 2x network/storage |

## Wide Type Definition

```swift
@frozen
public struct WideFixedPointDecimal: Sendable {
    internal var _storage: Int128
}
```

Range: +/-170,141,183,460,469,231,731 with 8 decimal places.

## Shared Protocol

A protocol enables generic code across both widths:

```swift
public protocol FixedPointDecimalProtocol: Sendable, Comparable, Hashable,
    AdditiveArithmetic, Numeric, SignedNumeric, Strideable {

    associatedtype Storage: FixedWidthInteger & SignedInteger
    var isNaN: Bool { get }
    var isFinite: Bool { get }
    var sign: FloatingPointSign { get }
    static var nan: Self { get }
}
```

## Widening and Narrowing

```swift
// Lossless widening (always succeeds)
let wide = WideFixedPointDecimal(someFixedPoint)

// Failable narrowing (nil if out of range)
let narrow = FixedPointDecimal(exactly: someWide)
```

## Timeline

The Int128 upgrade is **not currently needed**. The +/-92 billion range covers all current and foreseeable use cases. This upgrade path exists as insurance for future requirements.

Recommended triggers:
- A concrete use case exceeding +/-92 billion (e.g., accumulated JPY notional)
- A regulatory requirement for wider-range reporting
- Portfolio-level risk calculations aggregating across many instruments
