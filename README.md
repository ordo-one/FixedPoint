# FixedPointDecimal

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fordo-one%2FFixedPoint%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ordo-one/FixedPoint)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fordo-one%2FFixedPoint%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ordo-one/FixedPoint)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue.svg)](https://swiftpackageindex.com/ordo-one/FixedPoint/documentation)
[![codecov](https://codecov.io/gh/ordo-one/FixedPoint/branch/main/graph/badge.svg)](https://codecov.io/gh/ordo-one/FixedPoint)

Financial systems need exact decimal arithmetic -- binary floating-point (`Double`) cannot represent
`0.1` exactly, causing accumulation errors. `Foundation.Decimal` solves
exactness but carries inherent overhead: it is a 20-byte variable-precision type whose arithmetic
must operate on a multi-word mantissa, handle variable exponents, and manage intermediate results
that may exceed the mantissa width.

`FixedPointDecimal` takes a different approach: **fix the precision at compile time** (8 fractional
digits) and use a plain `Int64` as the backing store.

```swift
let price: FixedPointDecimal = 123.45
let quantity: FixedPointDecimal = 1000
let notional = price * quantity  // 123450
```

Full [API documentation](https://swiftpackageindex.com/ordo-one/FixedPoint/documentation) is available on the [Swift Package Index](https://swiftpackageindex.com).

## Features

- **Zero heap allocations** for all arithmetic, comparison, conversion, and rounding operations
- **`@frozen`** for cross-module inlining and optimal `ContiguousArray` layout
- **Pure Swift core** -- no Foundation dependency except for `Decimal` conversions
- **Cross-platform** -- Linux + all Apple platforms, x86 + ARM, Swift 6.2
- **Safe by default** -- trapping arithmetic (matching Swift `Int`), with wrapping and overflow-reporting variants
- **NaN support** -- sentinel-based NaN that propagates through all operations
- **Banker's rounding everywhere** -- all entry points (string parsing, `Double` conversion, `Decimal` conversion, arithmetic) use banker's rounding (round half to even). Explicit `rounded(scale:_:)` supports six modes

## Performance

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| Addition | 0.67 ns | 240 ns | **359x** |
| Subtraction | 0.67 ns | 283 ns | **424x** |
| Multiplication | 8 ns | 607 ns | **79x** |
| Division | 8 ns | 1,285 ns | **168x** |
| Comparison (`<`) | 0.33 ns | 300 ns | **901x** |
| Equality (`==`) | 0.34 ns | 317 ns | **943x** |
| Hash | 5 ns | 261 ns | **48x** |
| To Double | 0.49 ns | 271 ns | **551x** |
| String description | 44 ns | 1,045 ns | **24x** |
| JSON encode | 320 ns | 1,215 ns | **3.8x** |
| JSON decode | 457 ns | 831 ns | **1.8x** |
| `init(significand:exponent:)` | 0.41 ns | — | — |
| `init(Double)` | 1.4 ns | 2,319 ns | **1,622x** |
| `rounded(scale:)` | 2 ns | 705 ns | **349x** |

**Zero heap allocations** across all operations. 8 bytes in-memory and on the wire (vs 20 for Decimal).

*Measured on Apple M4 Max, Swift 6.2, p50 wall clock, using [package-benchmark](https://github.com/ordo-one/package-benchmark).
See the full [performance analysis](Sources/FixedPointDecimal/FixedPointDecimal.docc/Performance.md) for instruction counts, allocation breakdowns, and memory layout details.*

## Range and Precision

| Property | Value |
|---|---|
| Fractional digits | 8 (fixed) |
| Minimum value | -92,233,720,368.54775807 |
| Maximum value | 92,233,720,368.54775807 |
| Smallest positive | 0.00000001 |
| Storage | `@frozen` struct, `Int64` (8 bytes) |

Eight fractional digits cover all practical financial instruments: cents (2), mils (3), basis
points (4), FX pips (5), and cryptocurrency satoshis (8). The range (~92 billion) is sufficient
for individual prices and quantities but may require `Int128` backing for aggregated notional
values (see [06-future-128bit.md](Documentation/06-future-128bit.md)).

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/FixedPoint.git", from: "1.0.0"),
]
```

Then add the dependency to your target:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "FixedPointDecimal", package: "FixedPoint"),
    ]
)
```

## Protocol Conformances

**Core (all platforms):**
`Sendable`, `BitwiseCopyable`, `AtomicRepresentable`, `Equatable`, `Hashable`, `Comparable`,
`AdditiveArithmetic`, `Numeric`, `SignedNumeric`, `Strideable`,
`ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `Codable`,
`CustomStringConvertible`, `CustomDebugStringConvertible`, `LosslessStringConvertible`,
`CustomReflectable`

**SwiftUI (macOS/iOS):**
`VectorArithmetic`, `Plottable`

**Foundation (all platforms):**
`Decimal.FormatStyle` forwarding (`.number`, `.percent`, `.currency(code:)` and all modifiers),
plus a dedicated `FixedPointDecimalFormatStyle` conforming to `FormatStyle` and `ParseableFormatStyle`

## Usage

### Arithmetic

```swift
let a: FixedPointDecimal = 10.25
let b: FixedPointDecimal = 3

a + b           // 13.25
a - b           // 7.25
a * b           // 30.75
a / b           // 3.41666667 (banker's rounding)
a % b           // 1.25

// Wrapping (when you need non-trapping overflow — not faster than checked operators)
a &+ b
a &- b
```

Integer and float literals work directly via `ExpressibleByIntegerLiteral` and `ExpressibleByFloatLiteral`:

```swift
a * 100        // integer literal
a * 0.5        // float literal
```

Float literals go through `Double`, but this is safe for all values within `FixedPointDecimal`'s
8-digit fractional range — values like `0.1`, `0.2`, `0.3` all convert correctly because
`round(value * 10^8)` produces the exact integer. For values with more than 15 total significant
digits, use the string initializer: `FixedPointDecimal("12345678901.12345678")`.

### Conversions

```swift
// From/to Double (pure Swift, no Foundation)
let fromDouble: FixedPointDecimal = 123.45
let toDouble = Double(fromDouble)              // 123.45

// From/to Foundation.Decimal (for UI presentation)
let fromDecimal = FixedPointDecimal(someDecimal)
let toDecimal = Decimal(fromDecimal)

// Failable exact conversions (nil if not exactly representable)
let exact = Double(exactly: someFixedPoint)    // Optional(123.45)
let intVal = Int(exactly: someFixedPoint)      // nil if has fractional part

// Truncating integer conversions (matching Int(someDouble) semantics)
let truncated = Int(someFixedPoint)            // truncates fractional part
```

### String Parsing

```swift
let price: FixedPointDecimal = 99.95              // literal syntax
let parsed = FixedPointDecimal("99.95")!        // failable init (runtime)
String(price)                                   // "99.95"
```

### Rounding

```swift
let value: FixedPointDecimal = 123.456789
value.rounded()                                // 123 (integer rounding, banker's)
value.rounded(scale: 2)                        // 123.46 (banker's rounding)
value.rounded(scale: 2, .towardZero)           // 123.45
value.rounded(scale: 0, .up)                   // 124
value.rounded(scale: 0, .toNearestOrAwayFromZero)  // 123 (schoolbook rounding)
```

### SwiftUI Integration

```swift
// FormatStyle for TextField binding
TextField("Price", value: $price, format: .fixedPointDecimal)
price.formatted(.fixedPointDecimal.precision(2))    // "123.46"

// Decimal.FormatStyle forwarding — full locale-aware formatting
price.formatted(.number)                            // "123.45" (default locale)
price.formatted(.number.locale(Locale(identifier: "de_DE")))  // "123,45"
price.formatted(.currency(code: "USD"))             // "$123.45"
price.formatted(.currency(code: "SEK"))             // "123,45 kr"
price.formatted(.percent)                           // "12,345%"

// VectorArithmetic — animated transitions work automatically
struct PriceView: View {
    var price: FixedPointDecimal
    var body: some View {
        Text(price, format: .fixedPointDecimal.precision(2))
    }
}

// Plottable — direct use in Swift Charts
Chart(data) { item in
    LineMark(
        x: .value("Time", item.timestamp),
        y: .value("Price", item.price)  // FixedPointDecimal
    )
}
```

### Codable

Encodes as a human-readable JSON string. Decodes flexibly from String, integer, or floating-point JSON values:

```swift
// Encoding: always a string for precision safety
let data = try JSONEncoder().encode(price)  // "123.45"

// Decoding: accepts multiple formats for interoperability
// "123.45"  -- string (canonical)
// 123       -- integer (face value, not raw storage)
// 123.45    -- floating-point (from external APIs)
let decoded = try JSONDecoder().decode(FixedPointDecimal.self, from: data)
```

### Atomic Operations

`AtomicRepresentable` enables lock-free atomic operations via the `Synchronization` module:

```swift
import Synchronization

let bestBid = Atomic<FixedPointDecimal>(FixedPointDecimal(100.50))
bestBid.store(FixedPointDecimal(100.55), ordering: .releasing)
let current = bestBid.load(ordering: .acquiring)
```

### NaN

```swift
let nan = FixedPointDecimal.nan
nan.isNaN                    // true
nan == nan                   // true (sentinel semantics)
(nan + someValue).isNaN      // true (propagates)
nan.description              // "nan"
```

## Overflow Handling

Default operators trap on overflow, matching Swift `Int`:

```swift
// Trapping (default -- catches bugs in development)
let result = a + b  // traps if overflow

// Overflow-reporting (for defensive checks)
let (value, overflow) = a.addingReportingOverflow(b)

// Wrapping (non-trapping overflow — not faster than checked operators)
let wrapped = a &+ b
```

## Building and Testing

```bash
swift build
swift test        # 541 tests across 14 suites
```

## Benchmarks

Benchmarks use [package-benchmark](https://github.com/ordo-one/package-benchmark) and compare
every operation against `Foundation.Decimal`:

```bash
cd Benchmarks
swift package benchmark
```

Metrics collected: wall clock time, CPU instructions, heap allocations (malloc count).

## Fuzz Testing

Fuzz testing uses [libFuzzer](https://llvm.org/docs/LibFuzzer.html) via Swift's `-sanitize=fuzzer`
flag. This requires the **open-source Swift toolchain on Linux** (not available in Xcode on macOS).

```bash
# Build only
bash Fuzz/run.sh

# Build and run (Ctrl-C to stop)
bash Fuzz/run.sh run

# Run for 60 seconds
bash Fuzz/run.sh run -max_total_time=60

# Debug build (for lldb)
bash Fuzz/run.sh debug run
```

The fuzzer validates invariants across all operations:

- **Arithmetic**: commutativity, NaN propagation, no silent NaN sentinel creation
- **Comparisons**: strict total order (exactly one of `<`, `==`, `>`)
- **Conversions**: String, Double, Decimal, Codable round-trips
- **Rounding**: scale-8 identity, no overflow
- **Hashing**: equal values produce equal hashes

Crash artifacts are saved as `Fuzz/crash-*` files for reproduction.

## Acknowledgments

- Benchmark infrastructure powered by [package-benchmark](https://github.com/ordo-one/package-benchmark)
- Entirely built with [Claude Code](https://claude.ai/code) with careful guidance and coaching

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
