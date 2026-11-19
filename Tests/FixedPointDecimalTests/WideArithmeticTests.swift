@testable import FixedPointDecimal
import Testing

// Differential tests for the 64-bit-piece multiply/divide paths: every result must match the
// straightforward Int128 formulation (`_bankersDiv` on the full-width product or dividend),
// including the overflow flag and the truncated value of the wrapping and reporting forms.

/// SplitMix64: small, seedable, and good enough to spread values over the whole Int64 range.
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private let scale = Int128(100_000_000)

/// A raw value with a random magnitude width (1...63 bits) and sign, so small, typical and
/// near-overflow values are all common rather than almost every value being ~2⁶².
private func randomRaw(_ rng: inout SplitMix64) -> Int64 {
    let bits = Int.random(in: 1 ... 63, using: &rng)
    let magnitude = Int64(bitPattern: rng.next() >> UInt64(64 - bits))
    return Bool.random(using: &rng) ? -magnitude : magnitude
}

private let edgeRaws: [Int64] = {
    let base: [Int64] = [
        0, 1, 2, 3, 49_999_999, 50_000_000, 50_000_001, 99_999_999, 100_000_000, 100_000_001,
        150_000_000, 250_000_000, 3_037_000_499, 3_037_000_500, 1 << 32, (1 << 32) + 1,
        92_233_720_368, 92_233_720_369, 184_467_440_737, 184_467_440_738,
        Int64.max / 100_000_000, Int64.max / 2, Int64.max - 1, Int64.max,
    ]
    return base + base.map { -$0 }
}()

private func referenceProduct(_ lhs: Int64, _ rhs: Int64) -> Int128 {
    FixedPointDecimal._bankersDiv(Int128(lhs) * Int128(rhs), scale)
}

private func referenceQuotient(_ lhs: Int64, _ rhs: Int64) -> Int128 {
    FixedPointDecimal._bankersDiv(Int128(lhs) * scale, Int128(rhs))
}

private func fits(_ value: Int128) -> Bool {
    value > Int128(Int64.min) && value <= Int128(Int64.max)
}

private func checkMultiply(_ lhs: Int64, _ rhs: Int64) {
    let a = FixedPointDecimal(rawValue: lhs)
    let b = FixedPointDecimal(rawValue: rhs)
    let expected = referenceProduct(lhs, rhs)
    let truncated = Int64(truncatingIfNeeded: expected)

    #expect((a &* b).rawValue == truncated, "\(lhs) &* \(rhs)")
    guard !a.isNaN, !b.isNaN else { return }
    let reported = a.multipliedReportingOverflow(by: b)
    #expect(reported.partialValue.rawValue == truncated, "\(lhs) * \(rhs) partial value")
    #expect(reported.overflow == (!fits(expected) || truncated == .min), "\(lhs) * \(rhs) overflow flag")
    if fits(expected) {
        #expect((a * b).rawValue == truncated, "\(lhs) * \(rhs)")
    }
}

private func checkDivide(_ lhs: Int64, _ rhs: Int64) {
    guard rhs != 0, lhs != .min, rhs != .min else { return }
    let a = FixedPointDecimal(rawValue: lhs)
    let b = FixedPointDecimal(rawValue: rhs)
    let expected = referenceQuotient(lhs, rhs)
    let truncated = Int64(truncatingIfNeeded: expected)

    let reported = a.dividedReportingOverflow(by: b)
    #expect(reported.partialValue.rawValue == truncated, "\(lhs) / \(rhs) partial value")
    #expect(reported.overflow == (!fits(expected) || truncated == .min), "\(lhs) / \(rhs) overflow flag")
    if fits(expected) {
        #expect((a / b).rawValue == truncated, "\(lhs) / \(rhs)")
    }
}

@Suite("Wide multiply and divide")
struct WideArithmeticTests {
    @Test("Multiplication matches the Int128 reference on edge values")
    func multiplyEdges() {
        for lhs in edgeRaws + [Int64.min] {
            for rhs in edgeRaws + [Int64.min] {
                checkMultiply(lhs, rhs)
            }
        }
    }

    @Test("Division matches the Int128 reference on edge values")
    func divideEdges() {
        for lhs in edgeRaws {
            for rhs in edgeRaws {
                checkDivide(lhs, rhs)
            }
        }
    }

    @Test("Multiplication matches the Int128 reference on random values")
    func multiplyRandom() {
        var rng = SplitMix64(state: 0x5EED_0001)
        for _ in 0 ..< 200_000 {
            checkMultiply(randomRaw(&rng), randomRaw(&rng))
        }
    }

    @Test("Division matches the Int128 reference on random values")
    func divideRandom() {
        var rng = SplitMix64(state: 0x5EED_0002)
        for _ in 0 ..< 200_000 {
            checkDivide(randomRaw(&rng), randomRaw(&rng))
        }
    }

    @Test("Multiplication rounds exact ties to even")
    func multiplyTies() {
        var rng = SplitMix64(state: 0x5EED_0003)
        for _ in 0 ..< 50_000 {
            // lhs × 50_000_000 leaves a remainder of exactly half the scale when lhs is odd.
            let lhs = randomRaw(&rng) | 1
            let rhs: Int64 = Bool.random(using: &rng) ? 50_000_000 : -50_000_000
            checkMultiply(lhs, rhs)
            checkMultiply(lhs, rhs * 3)
        }
    }

    @Test("Division rounds exact ties to even")
    func divideTies() {
        var rng = SplitMix64(state: 0x5EED_0004)
        for _ in 0 ..< 50_000 {
            // lhs = (2q + 1)·k and rhs = 2k·10⁸ give a raw quotient of exactly q + ½, so every case
            // is a tie; k and q span both the single-divide and the wide path.
            let k = Int64.random(in: 1 ... 40_000_000_000, using: &rng)
            let q = Int64.random(in: 0 ... 1_000_000_000, using: &rng)
            let (lhs, overflow) = (2 * q + 1).multipliedReportingOverflow(by: k)
            guard !overflow else { continue }
            let rhs = 2 * k * 100_000_000
            #expect(referenceQuotient(lhs, rhs) == Int128(q + (q & 1)), "tie \(lhs) / \(rhs)")
            checkDivide(lhs, rhs)
            checkDivide(-lhs, rhs)
            checkDivide(lhs, -rhs)
        }
    }

    @Test("init(significand:exponent:) below the scale matches the Int128 reference")
    func significandNegativeShift() {
        var rng = SplitMix64(state: 0x5EED_0005)
        // Exponents -9 ... -26 divide the significand by 10¹ ... 10¹⁸ with banker's rounding.
        var cases: [(Int64, Int)] = []
        for exponent in -26 ... -9 {
            for significand: Int64 in [0, 1, -1, 5, -5, 15, -15, 25, Int64.max, Int64.min, Int64.min + 1] {
                cases.append((significand, exponent))
            }
            // Exact ties: an odd or even quotient followed by 5 then zeros.
            let shift = -(exponent + 8)
            if shift <= 18 {
                let half = FixedPointDecimal._powerOf10(shift) / 2
                for quotient: Int64 in [0, 1, 2, 3, 12_344, 12_345] {
                    let (scaled, overflow) = quotient.multipliedReportingOverflow(by: FixedPointDecimal._powerOf10(shift))
                    if !overflow, scaled <= Int64.max - half {
                        cases.append((scaled + half, exponent))
                        cases.append((-(scaled + half), exponent))
                    }
                }
            }
        }
        for _ in 0 ..< 100_000 {
            cases.append((Int64(bitPattern: rng.next()), Int.random(in: -26 ... -9, using: &rng)))
        }
        for (significand, exponent) in cases {
            let divisor = Int128(FixedPointDecimal._powerOf10(-(exponent + 8)))
            let expected = FixedPointDecimal._bankersDiv(Int128(significand), divisor)
            let actual = FixedPointDecimal(significand: Int(significand), exponent: exponent)
            #expect(actual.rawValue == Int64(expected), "significand \(significand), exponent \(exponent)")
        }
    }

    @Test("A quotient of exactly UInt64.max that rounds up is reported as overflow")
    func roundingWrapsUInt64Max() {
        // The unrounded magnitude is 2⁶⁴ − 1 and rounding adds 1, which wraps to 0 in 64 bits.
        // Found by search; random operands essentially never land here.
        checkMultiply(200_000_005, 9_223_371_806_270_480_651)
        checkMultiply(-200_000_008, 9_223_371_667_919_909_091)
        checkDivide(5_212_496_472_908_108, 28257)
        checkDivide(-6_097_017_851_242_481, 33052)
    }

    @Test("Division exercises both the single-divide and the wide paths")
    func dividePaths() {
        // |lhs| × 10⁸ < 2⁶⁴ takes the single 64-bit divide; anything larger takes the wide path.
        for lhs: Int64 in [184_467_440_737, 184_467_440_738, 1_000_000_000_000, Int64.max / 3] {
            for rhs: Int64 in [1, 3, 7, 100_000_000, 300_000_000, 1 << 40, (1 << 62) + 1, Int64.max] {
                checkDivide(lhs, rhs)
                checkDivide(-lhs, rhs)
                checkDivide(lhs, -rhs)
            }
        }
    }
}
