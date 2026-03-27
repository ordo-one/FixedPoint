# Future: Int128 Upgrade Path

> See also [Interoperability](03-interoperability.md).

---

## When to Upgrade

The `Int64`-backed `FixedPointDecimal` covers all practical financial instrument prices, quantities, and multipliers (range: ±92 billion with 8 decimal places). An `Int128` upgrade would be motivated by:

1. **Accumulated values**: Portfolio-level notional amounts or position sums that exceed 92 billion
2. **Extreme quantities**: High-frequency fill accumulation over extended periods
3. **Cryptocurrency edge cases**: Tokens with extreme unit values combined with 8-decimal precision
4. **Regulatory requirements**: Some jurisdictions may require higher-precision or wider-range reporting

## Recommended Architecture

**Do not widen the hot-path type.** Instead, introduce a separate wide type:

| Type | Backing | Size | Use case |
|---|---|---|---|
| `FixedPointDecimal` | `Int64` | 8 bytes | `Price`, `Quantity`, all hot-path data structures |
| `WideFixedPointDecimal` | `Int128` | 16 bytes | Accumulated values, portfolio totals, reporting |

### Why not widen FixedPointDecimal itself?

Doubling the storage width from 8 to 16 bytes has cascading effects on performance-critical paths:

| Metric | Int64 (8B) | Int128 (16B) | Impact |
|---|---|---|---|
| Values per cache line | 8 | 4 | 2× cache pressure |
| `ContiguousArray` for 5K elements | 40 KB | 80 KB | May exceed L1 cache |
| Wire size per field | 8 bytes | 16 bytes | 2× network/storage |
| Addition cost | ~1 ns | ~2 ns | Acceptable |
| Multiplication cost | ~3 ns (Int128 intermediate) | ~5 ns (needs Int256) | Needs software Int256 |

The 2× cache pressure is the critical concern. Performance-sensitive code depends on dense `ContiguousArray<FixedPointDecimal>` fitting in L1 cache for tight evaluation loops.

## Wide Type Definition

```swift
/// A fixed-point decimal number with 8 fractional digits, backed by a 128-bit integer.
///
/// Range: -170,141,183,460,469,231,731.68742049 to 170,141,183,460,469,231,731.68742049
///
/// Use this type for accumulated values (portfolio totals, position sums) where
/// the ±92 billion range of `FixedPointDecimal` may be insufficient.
/// For hot-path data structures (prices, quantities in arrays), prefer `FixedPointDecimal`.
@frozen
public struct WideFixedPointDecimal: Sendable {
    @usableFromInline
    internal var _storage: Int128

}
```

## Shared Protocol

A protocol enables generic code that works with both widths:

```swift
/// A fixed-point decimal number with 8 fractional decimal digits.
public protocol FixedPointDecimalProtocol: Sendable, Comparable, Hashable,
    AdditiveArithmetic,
    CustomStringConvertible, LosslessStringConvertible, Codable {

    /// The underlying integer storage type.
    associatedtype Storage: FixedWidthInteger & SignedInteger

    /// Whether this value is NaN.
    var isNaN: Bool { get }

    /// Whether this value is finite (not NaN).
    var isFinite: Bool { get }

    /// The sign of this value.
    var sign: FloatingPointSign { get }

    /// The NaN sentinel value.
    static var nan: Self { get }

    /// Creates from a `Double`.
    init(_ double: Double)
}
```

Both `FixedPointDecimal` and `WideFixedPointDecimal` conform to this protocol. Generic algorithms can be written once:

```swift
func midpoint<T: FixedPointDecimalProtocol>(_ a: T, _ b: T) -> T {
    a + (b - a) / T(2)
}
```

## Widening and Narrowing Conversions

### Lossless Widening (Int64 → Int128)

```swift
extension WideFixedPointDecimal {
    /// Lossless widening from `FixedPointDecimal`.
    ///
    /// This conversion always succeeds — every `Int64` value fits in `Int128`.
    @inlinable
    public init(_ value: FixedPointDecimal)
}
```

### Failable Narrowing (Int128 → Int64)

```swift
extension FixedPointDecimal {
    /// Narrowing conversion from `WideFixedPointDecimal`.
    ///
    /// Returns nil if the value exceeds the `Int64` range.
    @inlinable
    public init?(exactly value: WideFixedPointDecimal)

    /// Narrowing conversion that traps on overflow.
    @inlinable
    public init(_ value: WideFixedPointDecimal)
}
```

## Storage Migration (Int64 → Int128)

If the decision is ever made to widen stored `FixedPointDecimal` values from Int64 to Int128:

### Wire Format

```
Current:  8 bytes  (Int64)
Widened: 16 bytes  (Int128, stored as two Int64: low + high)
```

### Migration

The migration is trivial: sign-extend the stored Int64 to Int128.

```swift
// Reading old format (Int64):
let oldValue = reader.readScalar(Int64.self)
let newValue = Int128(oldValue)  // sign-extension, always correct

// Writing new format (Int128):
// The internal storage is widened from Int64 to Int128 via sign-extension.
```

This is simpler than the Decimal → FixedPointDecimal migration because:
- No format conversion needed (just widening)
- No precision mapping
- The sign-extension is mathematically exact

### Backward Compatibility

Old (Int64) readers cannot read new (Int128) values. This requires an ABI version bump, but the migration path follows standard schema change practices.

## Multiplication Considerations for Int128

For `FixedPointDecimal` (Int64), multiplication uses an `Int128` intermediate to hold the full-width product before dividing by the scale factor (10^8).

For `WideFixedPointDecimal` (Int128), multiplication would need an `Int256` intermediate for the same approach.

Swift 6.2 does not provide native `Int256`. Options:

1. **Software Int256**: Implement using `(high: Int128, low: UInt128)` tuple. Straightforward but slower.
2. **Split multiplication**: Use `multipliedFullWidth(by:)` if available on `Int128`, similar to `FixedWidthInteger.multipliedFullWidth`.
3. **Avoid FixedPoint × FixedPoint**: For accumulated values, multiplication is typically `WideFixedPointDecimal * Int` (quantity × integer factor), which doesn't need rescaling and stays in Int128.

Recommendation: option 3 for most use cases. `WideFixedPointDecimal` is primarily for accumulation (summing many `FixedPointDecimal` values), not for price × quantity products where both operands are fixed-point.

## Timeline

The Int128 upgrade is **not currently needed**. The ±92 billion range of `FixedPointDecimal` covers all current and foreseeable instrument prices, quantities, and multipliers. The upgrade path exists as insurance for future requirements.

Recommended triggers for implementing `WideFixedPointDecimal`:
- A concrete use case that exceeds ±92 billion (e.g., accumulated JPY notional)
- A regulatory requirement for wider-range reporting
- Portfolio-level risk calculations that aggregate across many instruments
