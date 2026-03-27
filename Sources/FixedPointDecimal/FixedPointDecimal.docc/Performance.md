# Performance

Benchmark results, methodology, and memory layout analysis.

## Overview

All benchmarks run using [package-benchmark](https://github.com/ordo-one/package-benchmark) in release mode with `.mega` scaling factor (1,000,000 iterations per sample). Measured on Apple M4 Max, macOS 15, Swift 6.2.

## Wall Clock (per operation)

| Operation | FixedPointDecimal | Foundation.Decimal | Speedup |
|---|---|---|---|
| **Addition** | 0.67 ns | 240 ns | **359x** |
| **Subtraction** | 0.67 ns | 283 ns | **424x** |
| **Multiplication** | 8 ns | 607 ns | **79x** |
| **Division** | 8 ns | 1,285 ns | **168x** |
| **Comparison (`<`)** | 0.33 ns | 300 ns | **901x** |
| **Equality (`==`)** | 0.34 ns | 317 ns | **943x** |
| **Hash** | 5 ns | 261 ns | **48x** |
| **To Double** | 0.49 ns | 271 ns | **551x** |
| **String description** | 44 ns | 1,045 ns | **24x** |
| **JSON encode** | 320 ns | 1,215 ns | **3.8x** |
| **JSON decode** | 457 ns | 831 ns | **1.8x** |
| **`init(significand:exponent:)`** | 0.41 ns | — | — |
| **`init(Double)`** | 1.4 ns | 2,319 ns | **1,622x** |
| **`rounded(scale:)`** | 2 ns | 705 ns | **349x** |

## Instructions (per operation)

| Operation | FixedPointDecimal | Foundation.Decimal | Ratio |
|---|---|---|---|
| **Addition** | 13 | 6,923 | **533x** |
| **Subtraction** | 14 | 8,442 | **603x** |
| **Multiplication** | 86 | 18,000 | **209x** |
| **Division** | 88 | 35,000 | **398x** |
| **Comparison (`<`)** | 10 | 8,829 | **883x** |
| **Equality (`==`)** | 10 | 9,056 | **906x** |
| **Hash** | 150 | 7,258 | **48x** |
| **To Double** | 12 | 7,892 | **658x** |
| **String description** | 1,393 | 31,000 | **22x** |
| **JSON encode** | 8,805 | 35,000 | **4x** |
| **JSON decode** | 9,577 | 16,000 | **1.7x** |
| **`init(significand:exponent:)`** | 7 | — | — |
| **`init(Double)`** | 36 | 50,000 | **1,389x** |
| **`rounded(scale:)`** | 44 | 16,000 | **364x** |

## Wrapping Operators (`&+`, `&-`, `&*`)

Wrapping operators perform no validation — no NaN checks, no overflow traps, no sentinel
adjustment — matching Swift `Int` wrapping operator semantics.

### Wall Clock (per operation)

| Operation | Checked | Wrapping | Speedup |
|---|---|---|---|
| **Addition** | 0.67 ns | 0.67 ns | 1.00x |
| **Subtraction** | 0.67 ns | 0.67 ns | 1.00x |
| **Multiplication** | 8 ns | 9 ns | 0.83x (slower) |

### Instructions (per operation)

| Operation | Checked | Wrapping | Reduction |
|---|---|---|---|
| **Addition** | 13 | 9 | **31%** fewer |
| **Subtraction** | 14 | 8 | **43%** fewer |
| **Multiplication** | 86 | 101 | 17% more |

`&+` and `&-` execute fewer instructions but show identical wall clock time — the NaN/overflow
branches in checked `+`/`-` are always-not-taken and perfectly predicted by the CPU.

`&*` is actually slower than checked `*` because the `precondition` in `*` gives the optimizer
proof that the result fits in `Int64`, enabling tighter code generation. Prefer `*` unless
non-trapping overflow behavior is specifically needed.

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
