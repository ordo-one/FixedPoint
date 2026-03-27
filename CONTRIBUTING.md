# Contributing

Contributions are welcome. Bug reports, performance improvements, and quality enhancements are particularly valued.

## Getting Started

```bash
swift build              # Debug build
swift test               # Run all tests (541 tests across 14 suites)
cd Benchmarks && swift package benchmark  # Run benchmark suite (release build)
```

## Before Submitting a PR

1. **All tests pass** — `swift test` must be green.
2. **Benchmarks checked** — If your change touches arithmetic, rounding, or conversions, run `cd Benchmarks && swift package benchmark` before and after. Include the comparison in your PR description. Do not submit performance changes that show no improvement.
3. **Lint clean** — Run `swiftlint` locally. The project has a `.swiftlint.yml` configuration with zero violations.
4. **Focused scope** — One concern per PR. Bug fix, feature, or refactor — not all three.

## Testing

Tests use the **Swift Testing** framework (`@Test` macro, `#expect()` assertions). Test files are in `Tests/FixedPointDecimalTests/` and cover:

- `ArithmeticTests.swift` — Addition, subtraction, multiplication, division, remainder
- `BasicTests.swift` — Initialization, NaN, special values, properties
- `CodableTests.swift` — JSON encoding/decoding, multi-format input
- `ComparisonTests.swift` — Ordering, equality, hashing
- `ConversionTests.swift` — Double, Decimal, Int conversions, float literal precision
- `EdgeCaseTests.swift` — Boundary conditions, max/min, overflow boundaries
- `FormatStyleTests.swift` — FormatStyle, currency, locale formatting
- `OverflowTests.swift` — Wrapping, reporting, trapping overflow
- `PowTests.swift` — Integer exponentiation, positive/negative exponents, edge cases
- `PreconditionTests.swift` — Precondition trap validation
- `PropertyTests.swift` — Randomized property-based tests (commutativity, identity, parity with Decimal)
- `RoundingTests.swift` — All 6 rounding modes, scale values, edge cases
- `StringTests.swift` — Parsing, formatting, round-trips

Run a specific test suite:

```bash
swift test --filter RoundingTests
```

## Fuzz Testing

Fuzz testing uses libFuzzer (Linux only, requires open-source Swift toolchain):

```bash
bash Fuzz/run.sh run -max_total_time=60
```

## Documentation

All public APIs must have DocC documentation (`///` comments). Include:
- A summary line
- Parameter descriptions
- Return value description
- A usage example for non-trivial APIs

Preview generated documentation:

```bash
swift package generate-documentation --target FixedPointDecimal
```

## Code Style

- SwiftLint is configured in the repo. Follow the existing patterns.
- Don't add comments for self-evident code. Do add comments for non-obvious algorithmic choices.
- Don't add features or abstractions beyond what's needed for the current change.
- Public API additions need DocC documentation (triple-slash comments).
- All arithmetic operations must remain `@inlinable` with zero heap allocations.

## Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add support for rounding to nearest tick
fix: correct banker's rounding for negative midpoint values
perf: reduce instruction count for multiplication
docs: update comparison table with latest benchmarks
test: add edge cases for Int32 overflow
```

Breaking changes append `!`: `feat!: rename RoundingMode cases to match FloatingPointRoundingRule`

## Performance

All arithmetic, comparison, and conversion operations are designed for zero heap allocations. Changes that introduce per-call allocations need strong justification and benchmark evidence.

## Questions

Open an issue for discussion before starting large changes. This saves everyone time.
