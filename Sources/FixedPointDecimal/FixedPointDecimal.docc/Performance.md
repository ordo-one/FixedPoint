# Performance

Benchmark results, methodology, and memory layout analysis.

## Overview

All benchmarks run using [benchmark](https://github.com/ordo-one/benchmark) in release mode, with the `.mega` scaling factor (1,000,000 iterations per sample), or `.kilo` (1,000) for operations that take hundreds of nanoseconds (Foundation.Decimal and JSON) so they still collect a real distribution of samples. Figures are p50 per operation, measured on Apple M3 Max, macOS 27.2, Swift 6.4.2.

Foundation.Decimal timings depend heavily on the Foundation version: the Swift reimplementation in recent releases is several times faster than older ones, so the ratios below are smaller than in earlier versions of this page.

## Wall Clock (per operation)

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| **Addition** | 0.81 ns | 73 ns | **90x** |
| **Subtraction** | 0.81 ns | 98 ns | **120x** |
| **Multiplication** | 6.2 ns | 351 ns | **57x** |
| **Division** | 10.5 ns | 815 ns | **78x** |
| **Comparison (`<`)** | 0.11 ns | 93 ns | **872x** |
| **Equality (`==`)** | 0.09 ns | 109 ns | **1,178x** |
| **Hash** | 7.2 ns | 112 ns | **16x** |
| **To Double** | 0.76 ns | 119 ns | **156x** |
| **String description** | 23 ns | 515 ns | **22x** |
| **JSON encode** | 305 ns | 723 ns | **2.4x** |
| **JSON decode** | 440 ns | 734 ns | **1.7x** |
| **`init(significand:exponent:)`** | 1.0 ns | — | — |
| **`init(Double)`** | 1.2 ns | 578 ns | **490x** |
| **`rounded(scale:)`** | 1.1 ns | 121 ns | **112x** |

## Instructions (per operation)

| Operation | FixedPointDecimal | Foundation.Decimal | Ratio |
|---|---|---|---|
| **Addition** | 9 | 1,175 | **130x** |
| **Subtraction** | 8 | 1,678 | **210x** |
| **Multiplication** | 28 | 3,910 | **142x** |
| **Division** | 74 | 9,544 | **129x** |
| **Comparison (`<`)** | 2 | 1,571 | **897x** |
| **Equality (`==`)** | 1.4 | 1,779 | **1,292x** |
| **Hash** | 145 | 1,499 | **10x** |
| **To Double** | 3 | 2,245 | **690x** |
| **String description** | 516 | 11,223 | **22x** |
| **JSON encode** | 6,136 | 15,213 | **2.5x** |
| **JSON decode** | 8,995 | 13,804 | **1.5x** |
| **`init(significand:exponent:)`** | 21 | — | — |
| **`init(Double)`** | 28 | 7,283 | **260x** |
| **`rounded(scale:)`** | 23 | 2,079 | **90x** |

## Wrapping Operators (`&+`, `&-`, `&*`)

Wrapping operators perform no validation — no NaN checks, no overflow traps, no sentinel
adjustment — matching Swift `Int` wrapping operator semantics.

### Wall Clock (per operation)

| Operation | Checked | Wrapping | Speedup |
|---|---|---|---|
| **Addition** | 0.81 ns | 0.81 ns | 1.00x |
| **Subtraction** | 0.81 ns | 0.81 ns | 1.00x |
| **Multiplication** | 6.2 ns | 6.2 ns | 1.00x |

### Instructions (per operation)

| Operation | Checked | Wrapping |
|---|---|---|
| **Addition** | 9 | 9 |
| **Subtraction** | 8 | 8 |
| **Multiplication** | 28 | 27 |

The checked operators cost the same as the wrapping ones in these benchmarks: the NaN and
overflow checks add no measurable time or instructions, and their branches are never taken, so
they are perfectly predicted. Prefer the checked operators; use `&+`, `&-` and `&*` only when you
specifically need wrapping instead of trapping on overflow.

## Zero Heap Allocations

`FixedPointDecimal` performs **zero heap allocations** across all arithmetic, comparison, conversion, rounding, and string formatting operations.

For latency-sensitive applications processing thousands of values per tick, eliminating these allocations removes a significant source of jitter.

## Memory Layout

| Type | Size | Stride | Values per cache line (64B) |
|---|---|---|---|
| FixedPointDecimal | 8 bytes | 8 bytes | **8** |
| Foundation.Decimal | 20 bytes | 24 bytes | **2** |

For `ContiguousArray` with 5K elements:
- **FixedPointDecimal**: 40 KB (fits in L1 cache)
- **Foundation.Decimal**: 120 KB (exceeds L1, spills to L2)

## Wire Size

| Type | Per-field size |
|---|---|
| FixedPointDecimal (as `Int64` scalar) | 8 bytes |
| Foundation.Decimal (as struct) | 20 bytes |

This compounds across messages containing multiple price/quantity fields.

## Reproducing Benchmarks

```bash
cd Benchmarks
swift package benchmark
```
