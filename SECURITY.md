# Security Policy

## Scope

FixedPointDecimal is a pure computation library — it performs fixed-point decimal arithmetic in memory with no network access, file I/O, or persistent storage. It does not process untrusted input from external sources by default; the caller controls what values are passed.

## Potential Concerns

- **Denial of service**: Very long strings passed to the string parser could cause excessive computation time. Callers processing untrusted input should enforce their own length limits.
- **Overflow**: Arithmetic operators trap on overflow by default (matching Swift `Int`). Use wrapping (`&+`, `&-`) or overflow-reporting methods for untrusted inputs where trapping is undesirable.

## Reporting a Vulnerability

If you discover a security issue, please open a GitHub issue on the project describing the concern.

We aim to respond within 30 days for confirmed vulnerabilities.

## Fuzz Testing

The library is continuously fuzz-tested using libFuzzer with AddressSanitizer, validating that no input combination causes crashes, out-of-bounds access, or invariant violations. See `Fuzz/` for details.
