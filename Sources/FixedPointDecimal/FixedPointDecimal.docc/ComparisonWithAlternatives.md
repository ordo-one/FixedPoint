# Comparison with Alternatives

How FixedPointDecimal compares to Foundation.Decimal, Double, and a future Int128 variant.

## Overview

| Characteristic | FixedPointDecimal | Foundation.Decimal | Double |
|---|---|---|---|
| **Storage size** | 8 bytes | 20 bytes (Swift struct) | 8 bytes |
| **Binary size** | 8 bytes (raw Int64) | 20 bytes | 8 bytes |
| **Heap allocations** | Never | Variable-precision intermediates | Never |
| **Arithmetic basis** | Native integer instructions | Variable-length multi-word decimal | IEEE 754 binary floating-point |

## Performance

Benchmarked on Apple M4 Max, macOS 15, Swift 6.2:

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| Addition | 0.67 ns | 240 ns | **359x** |
| Subtraction | 0.67 ns | 283 ns | **424x** |
| Multiplication | 8 ns (Int128 intermediate) | 607 ns | **79x** |
| Division | 8 ns (Int128 intermediate) | 1,285 ns | **168x** |
| Comparison (`<`) | 0.33 ns (single `cmp`) | 300 ns | **901x** |
| Equality (`==`) | 0.34 ns | 317 ns | **943x** |
| String formatting | 44 ns | 1,045 ns | **24x** |
| JSON decode | 457 ns | 831 ns | **1.8x** |
| `init(significand:exponent:)` | 0.41 ns | — | — |
| `init(Double)` | 1.4 ns | 2,319 ns | **1,622x** |
| `rounded(scale:)` | 2 ns | 705 ns | **349x** |

## Precision and Range

| Property | FixedPointDecimal | Foundation.Decimal | Double |
|---|---|---|---|
| Decimal precision | Exactly 8 fractional digits | Up to 38 significant digits | ~15-17 significant digits (binary) |
| Exact decimal arithmetic | Yes (within 8 digits) | Yes (within 38 digits) | No (binary approximation) |
| Maximum value | 92,233,720,368 | 3.4 x 10^38 | 1.8 x 10^308 |
| NaN support | Sentinel (`Int64.min`) | Native `.isNaN` | IEEE 754 NaN |

## Why 8 Decimal Places Is Sufficient

Financial markets operate with the following typical precisions:

| Market | Typical precision | Example |
|---|---|---|
| Equities | 2-4 decimal places | EUR 123.45, SEK 1234.50 |
| FX spot | 4-5 decimal places | EUR/USD 1.12345 |
| FX forwards | 5-6 decimal places | 1.123456 |
| Bonds | 2-6 decimal places | 99.875, 101.123456 |
| Commodity futures | 2-4 decimal places | 75.42 |
| Cryptocurrency | Up to 8 decimal places | 1 satoshi = 0.00000001 BTC |

8 decimal places covers all of these with room to spare.

## Range Adequacy

With `Int64` backing, the maximum absolute value is ~92 billion.

| Use case | Typical range | Fits? |
|---|---|---|
| Equity prices | 0.01 - 500,000 | Yes |
| FX rates | 0.0001 - 50,000 | Yes |
| Bond prices | 0 - 200 | Yes |
| Order quantities | 0 - 1,000,000,000 | Yes |
| Notional amounts | 0 - 10,000,000,000 | Yes |

For accumulated portfolio-level values that could exceed this, see <doc:Future128Bit>.

## Overflow Behavior

| Type | Default overflow | Reporting API | Wrapping API |
|---|---|---|---|
| **FixedPointDecimal** | Traps (precondition failure) | `addingReportingOverflow`, etc. | `&+`, `&-`, `&*` |
| **Foundation.Decimal** | Silent truncation / `.lossOfPrecision` | NSDecimalNumber CalculationError | N/A |
| **Double** | Silent overflow to +/-Infinity | N/A (IEEE 754) | N/A |
| **Swift Int** | Traps (precondition failure) | `addingReportingOverflow`, etc. | `&+`, `&-`, `&*` |

`FixedPointDecimal` matches Swift `Int` overflow semantics exactly.
