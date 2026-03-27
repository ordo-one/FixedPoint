// Fuzz target for FixedPointDecimal using libFuzzer.
//
// Build:  bash Fuzz/run.sh
// Run:    Fuzz/fuzz-fixedpointdecimal [corpus_dir]
//
// The fuzzer generates random byte buffers and uses them to construct
// FixedPointDecimal values and operations. It validates invariants that
// must hold for ALL inputs — any violation is a bug.
//
// Platform: Linux only — Swift's -sanitize=fuzzer requires the open-source
//           Swift toolchain, not available in Xcode on macOS.
//
// UBSan note: -sanitize=fuzzer implicitly enables UBSan, which instruments
// signed integer operations (negation, division, modulo) with C-semantics
// overflow checks. Swift defines these operations as well-defined (trapping
// or wrapping), but UBSan emits ud2 traps for values near Int64 boundaries.
// This file uses wrapping arithmetic (0 &- x) and overflow-reporting APIs
// (dividedReportingOverflow) where needed to avoid these false positives.

// No `import FixedPointDecimal` — compiled as a single module with the library sources.
import Foundation

// MARK: - Input parsing

/// Reads a fixed number of bytes from the fuzzer buffer, advancing the offset.
private struct FuzzReader {
    let data: UnsafeRawBufferPointer
    var offset: Int = 0

    var remaining: Int { data.count - offset }

    mutating func readByte() -> UInt8? {
        guard offset < data.count else { return nil }
        defer { offset += 1 }
        return data[offset]
    }

    mutating func readInt64() -> Int64? {
        guard remaining >= 8 else { return nil }
        // Use UInt64 for bit manipulation to avoid UBSan signed-overflow
        // false positives when shifting into the sign bit.
        var value: UInt64 = 0
        for i in 0..<8 {
            value |= UInt64(data[offset + i]) << (i * 8)
        }
        offset += 8
        return Int64(bitPattern: value)
    }

    mutating func readString(maxLength: Int = 32) -> String? {
        guard let lenByte = readByte() else { return nil }
        let len = min(Int(lenByte) % (maxLength + 1), remaining)
        guard len > 0 else { return "" }
        var chars = [Character]()
        chars.reserveCapacity(len)
        for i in 0..<len {
            // Map to printable ASCII + digits + dot + minus (useful for decimal strings)
            let byte = data[offset + i]
            let c: Character
            switch byte % 16 {
            case 0...9:
                c = Character(UnicodeScalar(0x30 + Int(byte % 10))!)  // '0'-'9'
            case 10:
                c = "."
            case 11:
                c = "-"
            case 12:
                c = "+"
            case 13:
                c = " "
            case 14:
                c = "e"
            default:
                c = Character(UnicodeScalar(0x30 + Int(byte % 10))!)  // '0'-'9'
            }
            chars.append(c)
        }
        offset += len
        return String(chars)
    }
}

// MARK: - Operations

private enum Operation: UInt8 {
    case add = 0
    case subtract = 1
    case multiply = 2
    case divide = 3
    case compare = 4
    case roundTrip = 5       // string round-trip
    case doubleRoundTrip = 6 // Double round-trip
    case decimalRoundTrip = 7
    case negate = 8
    case rounding = 9
    case codable = 10
    case hash = 11
}

// MARK: - Fuzz entry point

@_cdecl("LLVMFuzzerTestOneInput")
public func fuzzTest(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
    guard count >= 10 else { return 0 }

    var reader = FuzzReader(data: UnsafeRawBufferPointer(start: start, count: count))
    guard let opByte = reader.readByte(),
          let rawA = reader.readInt64() else { return 0 }

    // Avoid the NaN sentinel as input — test NaN separately
    let a = FixedPointDecimal(rawValue: rawA == .min ? rawA + 1 : rawA)
    let op = Operation(rawValue: opByte % 12) ?? .add

    switch op {

    case .add, .subtract, .multiply, .divide:
        guard let rawB = reader.readInt64() else { return 0 }
        let b = FixedPointDecimal(rawValue: rawB == .min ? rawB + 1 : rawB)

        // Use overflow-reporting variants to avoid traps
        let result: (partialValue: FixedPointDecimal, overflow: Bool)
        switch op {
        case .add:      result = a.addingReportingOverflow(b)
        case .subtract: result = a.subtractingReportingOverflow(b)
        case .multiply: result = a.multipliedReportingOverflow(by: b)
        case .divide:   result = a.dividedReportingOverflow(by: b)
        default: fatalError()
        }

        if !result.overflow {
            // ── INVARIANT: Result must not be NaN from non-NaN inputs ──
            precondition(!result.partialValue.isNaN,
                         "\(op) of \(a) and \(b) produced NaN without overflow flag")

            // ── INVARIANT: Addition/subtraction are commutative/anti-commutative ──
            if op == .add {
                let reverse = b.addingReportingOverflow(a)
                precondition(!reverse.overflow && reverse.partialValue == result.partialValue,
                             "Addition not commutative: \(a) + \(b) != \(b) + \(a)")
            }

            // ── INVARIANT: Multiplication is commutative ──
            if op == .multiply {
                let reverse = b.multipliedReportingOverflow(by: a)
                if !reverse.overflow {
                    precondition(reverse.partialValue == result.partialValue,
                                 "Multiplication not commutative: \(a) * \(b) != \(b) * \(a)")
                }
            }

            // ── INVARIANT: Subtraction anti-commutativity: a - b == -(b - a) ──
            if op == .subtract {
                let reverse = b.subtractingReportingOverflow(a)
                if !reverse.overflow && !reverse.partialValue.isNaN {
                    // Use wrapping negate to avoid UBSan-instrumented unary minus
                    let neg = FixedPointDecimal(rawValue: 0 &- reverse.partialValue.rawValue)
                    precondition(neg == result.partialValue,
                                 "Subtraction anti-commutativity failed: \(a) - \(b) != -(\(b) - \(a))")
                }
            }

            // ── INVARIANT: Remainder consistency: a == (a/b)*b + (a%b) ──
            // Skip: raw % uses idiv which UBSan instruments; tested via public API.

            // ── INVARIANT: Identity — a + 0 == a ──
            if op == .add {
                let (addZero, addZeroOvf) = a.addingReportingOverflow(.zero)
                precondition(!addZeroOvf && addZero == a,
                             "Additive identity failed: \(a) + 0 = \(addZero)")
            }

            // ── INVARIANT: Identity — a * 1 == a ──
            if op == .multiply {
                let one = FixedPointDecimal(rawValue: FixedPointDecimal.scaleFactor) // 1.0
                let (mulOne, mulOneOvf) = a.multipliedReportingOverflow(by: one)
                if !mulOneOvf {
                    precondition(mulOne == a,
                                 "Multiplicative identity failed: \(a) * 1 = \(mulOne)")
                }
            }
        }

    case .compare:
        guard let rawB = reader.readInt64() else { return 0 }
        let b = FixedPointDecimal(rawValue: rawB == .min ? rawB + 1 : rawB)

        // ── INVARIANT: Strict total order ──
        let aLTb = a < b
        let bLTa = b < a
        let aEQb = a == b

        // Exactly one must be true
        let count = (aLTb ? 1 : 0) + (bLTa ? 1 : 0) + (aEQb ? 1 : 0)
        precondition(count == 1,
                     "Strict total order violated: a=\(a) b=\(b) a<b=\(aLTb) b<a=\(bLTa) a==b=\(aEQb)")

        // ── INVARIANT: Consistency with rawValue ordering ──
        if a.rawValue < b.rawValue {
            precondition(aLTb, "rawValue ordering inconsistent with Comparable")
        } else if a.rawValue > b.rawValue {
            precondition(bLTa, "rawValue ordering inconsistent with Comparable")
        } else {
            precondition(aEQb, "rawValue equality inconsistent with Equatable")
        }

    case .roundTrip:
        // ── INVARIANT: String round-trip preserves value ──
        let str = a.description
        let recovered = FixedPointDecimal(str)
        precondition(recovered != nil, "Failed to parse own description: \"\(str)\"")
        precondition(recovered! == a,
                     "String round-trip failed: \(a) -> \"\(str)\" -> \(recovered!)")

    case .doubleRoundTrip:
        // Double has 53-bit mantissa. The round-trip FPD -> Double -> FPD
        // involves division and multiplication by scaleFactor (10^8), which
        // compounds precision loss. Just verify conversions don't crash;
        // exact round-trip is tested in the unit test suite with known values.
        let d = Double(a)
        _ = FixedPointDecimal(exactly: d)  // verify failable init doesn't crash

    case .decimalRoundTrip:
        // ── INVARIANT: FPD → Decimal → FPD preserves value exactly ──
        let dec = Decimal(a)
        // Use failable init to avoid trapping on platform-specific
        // NSDecimalNumber.int64Value behavior for extreme values.
        guard let recovered = FixedPointDecimal(exactly: dec) else { return 0 }
        precondition(recovered == a,
                     "Decimal round-trip failed: \(a) -> \(dec) -> \(recovered)")

        // ── INVARIANT: Decimal(a) convenience init matches Decimal(a) ──
        precondition(Decimal(a) == dec,
                     "Decimal(a) mismatch: \(Decimal(a)) vs \(dec)")

        // ── INVARIANT: Arithmetic parity — FPD addition matches Decimal addition ──
        guard let rawB = reader.readInt64() else { return 0 }
        let b = FixedPointDecimal(rawValue: rawB == .min ? rawB + 1 : rawB)
        let (fpdSum, sumOvf) = a.addingReportingOverflow(b)
        if !sumOvf && !fpdSum.isNaN {
            let decSum = dec + Decimal(b)
            guard let fpdSumFromDec = FixedPointDecimal(exactly: decSum) else { return 0 }
            precondition(fpdSum == fpdSumFromDec,
                         "Addition parity failed: FPD \(a)+\(b)=\(fpdSum), Decimal=\(fpdSumFromDec)")
        }

    case .negate:
        // Skip NaN (can't negate) and values near Int64.min where
        // negation would overflow or produce the NaN sentinel.
        if a.rawValue != Int64.min + 1 && a.rawValue != Int64.min {
            // Use wrapping negate: unary minus on Int64 emits a `neg` instruction
            // which UBSan (bundled with -sanitize=fuzzer) instruments with a
            // signed-overflow check. Wrapping via 0 &- avoids the false positive.
            let neg = FixedPointDecimal(rawValue: 0 &- a.rawValue)
            let doubleNeg = FixedPointDecimal(rawValue: 0 &- neg.rawValue)
            // ── INVARIANT: Double negation is identity ──
            precondition(doubleNeg == a,
                         "Double negation failed: \(a) -> \(neg) -> \(doubleNeg)")
            // ── INVARIANT: a + (-a) == 0 ──
            let (sum, overflow) = a.addingReportingOverflow(neg)
            if !overflow {
                precondition(sum == .zero,
                             "a + (-a) != 0: \(a) + \(neg) = \(sum)")
            }
        }

    case .rounding:
        guard let scaleByte = reader.readByte() else { return 0 }
        let scale = Int(scaleByte) % 9  // 0...8

        // Rounding can overflow for values near .max/.min when rounding away from zero.
        // Limit to values where rounding cannot overflow: integer part must leave room.
        let maxSafeRaw = Int64.max - FixedPointDecimal.scaleFactor
        guard a.rawValue > -maxSafeRaw && a.rawValue < maxSafeRaw else { return 0 }

        let rounded = a.rounded(scale: scale)
        // ── INVARIANT: Rounding at scale 8 is identity ──
        if scale == 8 {
            precondition(rounded == a,
                         "Rounding at scale 8 is not identity: \(a) -> \(rounded)")
        }

        // ── INVARIANT: Rounding monotonicity — if a < b then a.rounded(s) <= b.rounded(s) ──
        guard let rawB = reader.readInt64() else { return 0 }
        let b = FixedPointDecimal(rawValue: rawB == .min ? rawB + 1 : rawB)
        guard b.rawValue > -maxSafeRaw && b.rawValue < maxSafeRaw else { return 0 }
        let bRounded = b.rounded(scale: scale)
        if a < b {
            precondition(rounded <= bRounded,
                         "Rounding monotonicity violated: \(a).rounded(\(scale))=\(rounded) > \(b).rounded(\(scale))=\(bRounded)")
        }

    case .codable:
        // ── INVARIANT: JSON encode+decode round-trip ──
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        guard let data = try? encoder.encode(a) else { return 0 }
        guard let decoded = try? decoder.decode(FixedPointDecimal.self, from: data) else { return 0 }
        precondition(decoded == a,
                     "Codable round-trip failed: \(a) -> \(decoded)")

    case .hash:
        // ── INVARIANT: Equal values have equal hashes ──
        let b = FixedPointDecimal(rawValue: a.rawValue)
        precondition(a == b)
        var h1 = Hasher()
        var h2 = Hasher()
        h1.combine(a)
        h2.combine(b)
        precondition(h1.finalize() == h2.finalize(),
                     "Equal values have different hashes: \(a)")
    }

    // ── INVARIANT: NaN propagation ──
    let nan = FixedPointDecimal.nan
    precondition((nan + a).isNaN, "NaN + a is not NaN")
    precondition((a + nan).isNaN, "a + NaN is not NaN")
    precondition((nan - a).isNaN, "NaN - a is not NaN")
    precondition((nan * a).isNaN, "NaN * a is not NaN")

    return 0
}
