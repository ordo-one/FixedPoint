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
- **NaN support** -- sentinel-based NaN that traps all operations
- **Banker's rounding everywhere** -- all entry points (string parsing, `Double` conversion, `Decimal` conversion, arithmetic) use banker's rounding (round half to even). Explicit `rounded(scale:_:)` supports six modes

## Performance

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| Addition | 0.81 ns | 73 ns | **90x** |
| Subtraction | 0.81 ns | 98 ns | **120x** |
| Multiplication | 6.2 ns | 351 ns | **57x** |
| Division | 10.5 ns | 815 ns | **78x** |
| Comparison (`<`) | 0.11 ns | 93 ns | **872x** |
| Equality (`==`) | 0.09 ns | 109 ns | **1,178x** |
| Hash | 7.2 ns | 112 ns | **16x** |
| To Double | 0.76 ns | 119 ns | **156x** |
| String description | 23 ns | 515 ns | **22x** |
| JSON encode | 305 ns | 723 ns | **2.4x** |
| JSON decode | 440 ns | 734 ns | **1.7x** |
| `init(significand:exponent:)` | 1.0 ns | — | — |
| `init(Double)` | 1.2 ns | 578 ns | **490x** |
| `rounded(scale:)` | 1.1 ns | 121 ns | **112x** |

**Zero heap allocations** in every FixedPointDecimal operation, including `description` (the JSON rows allocate only inside `JSONEncoder`/`JSONDecoder`). 8 bytes in-memory and on the wire (vs 20 for Decimal).

*Measured on Apple M3 Max, macOS 27.2, Swift 6.4.2, p50 wall clock, using [benchmark](https://github.com/ordo-one/benchmark).
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
nan + someValue              // traps (NaN is signalling)
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

Benchmarks use [benchmark](https://github.com/ordo-one/benchmark) and compare
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

- **Arithmetic**: commutativity, NaN trapping, no silent NaN sentinel creation
- **Comparisons**: strict total order (exactly one of `<`, `==`, `>`)
- **Conversions**: String, Double, Decimal, Codable round-trips
- **Rounding**: scale-8 identity, no overflow
- **Hashing**: equal values produce equal hashes

Crash artifacts are saved as `Fuzz/crash-*` files for reproduction.

## Acknowledgments

- Benchmark infrastructure powered by [benchmark](https://github.com/ordo-one/benchmark)
- Entirely built with [Claude Code](https://claude.ai/code) with careful guidance and coaching

### External Test Suite Validation

Arithmetic correctness is validated against three established decimal test suites with **zero failures** across all compatible test vectors:

- **[General Decimal Arithmetic](https://speleotrove.com/decimal/)** (Mike Cowlishaw / IBM) --
  2,492 vectors passed across 12 operations (add, subtract, multiply, divide, remainder, compare, abs, negate, min, max, plus) from 81,300+ total vectors.
  [ICU License](Tests/FixedPointDecimalTests/Resources/GDA/LICENSE).
- **[Fahmy Arithmetic Test Vectors](http://eece.cu.edu.eg/~hfahmy/arith_debug/)** (Cairo University) --
  157 vectors passed for add, multiply, divide. These directed vectors found bugs in IBM decNumber and Intel's decimal library.
  [Permissive with attribution](Tests/FixedPointDecimalTests/Resources/Fahmy/LICENSE).
- **[Intel Decimal Floating-Point Math Library](https://www.intel.com/content/www/us/en/developer/articles/tool/intel-decimal-floating-point-math-library.html)** --
  37 vectors passed for add, subtract, abs, negate with BID64 hex decoding.
  [BSD 3-Clause License](Tests/FixedPointDecimalTests/Resources/Intel/LICENSE).

Vectors are skipped (never failed) when they fall outside our type's domain:
values exceeding our range (~92 billion), operands needing more than 8 fractional digits,
infinity/NaN arithmetic (we trap), overflow/underflow conditions, or non-half_even rounding
on multiply/divide (our arithmetic uses banker's rounding). Rounding-independent operations
(add, subtract, compare, abs, negate, min, max) run with all rounding modes since the result
is exact. See [UPDATING.md](Tests/FixedPointDecimalTests/Resources/UPDATING.md) for how to
refresh the test suites.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
