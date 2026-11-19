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

Benchmarked on Apple M3 Max, macOS 27.2, Swift 6.4.2 (p50 per operation; see <doc:Performance> for x86_64 Linux and instruction counts):

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| Addition | 0.81 ns | 73 ns | **90x** |
| Subtraction | 0.81 ns | 98 ns | **120x** |
| Multiplication | 6.2 ns | 351 ns | **57x** |
| Division | 10.5 ns | 815 ns | **78x** |
| Comparison (`<`) | 0.11 ns (single `cmp`) | 93 ns | **872x** |
| Equality (`==`) | 0.09 ns | 109 ns | **1,178x** |
| String formatting | 23 ns | 515 ns | **22x** |
| JSON decode | 440 ns | 734 ns | **1.7x** |
| `init(significand:exponent:)` | 1.0 ns | — | — |
| `init(Double)` | 1.2 ns | 578 ns | **490x** |
| `rounded(scale:)` | 1.1 ns | 121 ns | **112x** |

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
