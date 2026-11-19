# ``FixedPointDecimal``

A high-performance fixed-point decimal type for Swift, designed for financial systems where exact decimal representation is required and `Foundation.Decimal` is too slow.

@Metadata {
    @Available(macOS, introduced: "15.0")
    @Available(iOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
}

## Overview

`FixedPointDecimal` is an `@frozen` struct backed by `Int64`, storing values with exactly 8 fractional decimal digits (value x 10^8). All arithmetic compiles to native integer instructions with **zero heap allocations**.

```swift
let price: FixedPointDecimal = 123.45
let quantity: FixedPointDecimal = 1000
let notional = price * quantity  // 123450
```

### Performance vs Foundation.Decimal

Benchmarked on Apple M3 Max, macOS 27.2, Swift 6.4.2 (p50 per operation; see <doc:Performance> for more operations and x86_64 Linux):

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| Addition | 0.81 ns | 73 ns | **90x** |
| Multiplication | 6.2 ns | 351 ns | **57x** |
| Division | 10.5 ns | 815 ns | **78x** |
| Comparison | 0.11 ns | 93 ns | **872x** |

All arithmetic operations compile to native integer instructions with zero heap allocations.

### Range and Precision

| Property | Value |
|---|---|
| Fractional digits | 8 (fixed) |
| Minimum value | -92,233,720,368.54775807 |
| Maximum value | 92,233,720,368.54775807 |
| Smallest positive | 0.00000001 |
| Storage | `Int64` (8 bytes) |

## Topics

### Articles

- <doc:GettingStarted>
- <doc:TypeDesign>
- <doc:ComparisonWithAlternatives>
- <doc:Interoperability>
- <doc:Performance>
- <doc:Future128Bit>

### Creating Values

- ``FixedPointDecimal/init()``
- ``FixedPointDecimal/init(integer:fraction:)``

### Special Values

- ``FixedPointDecimal/nan``
- ``FixedPointDecimal/zero``
- ``FixedPointDecimal/max``
- ``FixedPointDecimal/min``
- ``FixedPointDecimal/leastNonzeroMagnitude``
- ``FixedPointDecimal/greatestFiniteMagnitude``
- ``FixedPointDecimal/fractionalDigitCount``
- ``FixedPointDecimal/isNaN``
- ``FixedPointDecimal/isFinite``
- ``FixedPointDecimal/sign``

### Value Access

- ``Swift/Double/init(_:)-swift.type.method``
- ``Swift/Decimal/init(_:)-swift.type.method``
- ``Swift/Int/init(_:)-4k3ov``
- ``Swift/Int64/init(_:)-9f4q3``
- ``Swift/Int32/init(_:)-7wx2p``
- ``FixedPointDecimal/isFinite``
- ``FixedPointDecimal/sign``

### Arithmetic

- ``FixedPointDecimal/+(_:_:)``
- ``FixedPointDecimal/-(_:_:)``
- ``FixedPointDecimal/*(_:_:)-3yclw``
- ``FixedPointDecimal/%(_:_:)``
- ``FixedPointDecimal/-(_:)``

### Overflow Handling

- ``FixedPointDecimal/&+(_:_:)``
- ``FixedPointDecimal/&-(_:_:)``
- ``FixedPointDecimal/&*(_:_:)``
- ``FixedPointDecimal/addingReportingOverflow(_:)``
- ``FixedPointDecimal/subtractingReportingOverflow(_:)``
- ``FixedPointDecimal/multipliedReportingOverflow(by:)``
- ``FixedPointDecimal/dividedReportingOverflow(by:)``

### Rounding

- ``FixedPointDecimal/RoundingMode``
- ``FixedPointDecimal/rounded(scale:_:)``
- ``FixedPointDecimal/round(scale:_:)``

### String Conversion

- ``FixedPointDecimal/description``
- ``FixedPointDecimal/debugDescription``

### Formatting

- ``FixedPointDecimalFormatStyle``
- ``FixedPointDecimalParseStrategy``

