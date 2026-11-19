# Performance

Benchmark results, methodology, and memory layout analysis.

## Overview

All benchmarks run using [benchmark](https://github.com/ordo-one/benchmark) in release mode, with the `.mega` scaling factor (1,000,000 iterations per sample), or `.kilo` (1,000) for operations that take hundreds of nanoseconds (Foundation.Decimal and JSON) so they still collect a real distribution of samples. Figures are p50 per operation. The first tables are from an Apple M3 Max, macOS 27.2, Swift 6.4.2; x86_64 Linux numbers follow in their own section below.

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

## x86_64 Linux

Measured on an AMD EPYC 9454P (Zen 4), Ubuntu 26.04, Swift 6.4.2: p50 per operation, median of three runs.

### Wall Clock (per operation)

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| **Addition** | 1.3 ns | 118 ns | **88x** |
| **Subtraction** | 1.3 ns | 145 ns | **108x** |
| **Multiplication** | 7.6 ns | 408 ns | **54x** |
| **Division** | 8.0 ns | 949 ns | **118x** |
| **Comparison (`<`)** | 0.25 ns | 136 ns | **540x** |
| **Equality (`==`)** | 0.21 ns | 135 ns | **652x** |
| **Hash** | 26 ns | 168 ns | **6.4x** |
| **To Double** | 1.3 ns | 162 ns | **127x** |
| **String description** | 36 ns | 798 ns | **22x** |
| **JSON encode** | 433 ns | 1,097 ns | **2.5x** |
| **JSON decode** | 456 ns | 886 ns | **1.9x** |
| **`init(significand:exponent:)`** | 1.7 ns | — | — |
| **`init(Double)`** | 2.9 ns | 924 ns | **314x** |
| **`rounded(scale:)`** | 1.6 ns | 190 ns | **119x** |

### Instructions (per operation)

Counted on an Intel Core Ultra 7 265 with the same toolchain, because the EPYC host does not expose
hardware counters to unprivileged processes. The same compiler and target produce the same code on
both, so the counts carry over.

| Operation | FixedPointDecimal | Foundation.Decimal | Ratio |
|---|---|---|---|
| **Addition** | 11 | 1,079 | **98x** |
| **Subtraction** | 11 | 1,542 | **140x** |
| **Multiplication** | 46 | 3,785 | **83x** |
| **Division** | 47 | 9,888 | **210x** |
| **Comparison (`<`)** | 4 | 1,395 | **328x** |
| **Equality (`==`)** | 3 | 1,410 | **434x** |
| **Hash** | 172 | 1,323 | **7.7x** |
| **To Double** | 6 | 1,575 | **274x** |
| **String description** | 628 | 12,591 | **20x** |
| **JSON encode** | 5,439 | 15,516 | **2.9x** |
| **JSON decode** | 6,263 | 10,142 | **1.6x** |
| **`init(significand:exponent:)`** | 24 | — | — |
| **`init(Double)`** | 43 | 6,988 | **162x** |
| **`rounded(scale:)`** | 26 | 2,037 | **78x** |

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
overflow checks add no measurable time and at most one instruction, and their branches are never
taken, so they are perfectly predicted. Prefer the checked operators; use `&+`, `&-` and `&*` only when you
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
