import Foundation
import Testing
@testable import FixedPointDecimal

@Suite("Property Tests")
struct PropertyTests {

    // MARK: - PRNG (reproduced from MacroConsistencyTests for self-containment)

    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64

        init(seed: UInt64) { self.state = seed }

        mutating func next() -> UInt64 {
            state &+= 0x9e3779b97f4a7c15
            var z = state
            z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return z ^ (z >> 31)
        }
    }

    // MARK: - Helpers

    /// Boundary values used for biased generation.
    private static let boundaryValues: [Int64] = [
        0, 1, -1,
        100_000_000, -100_000_000,            // 1.0, -1.0
        50_000_000, -50_000_000,              // 0.5, -0.5
        99_999_999, -99_999_999,              // 0.99999999
        Int64.max, Int64.min + 1,             // max, min
        Int64.max / 2, (Int64.min + 1) / 2,  // half-range
    ]

    /// Generate a random non-NaN raw value, biased toward boundaries 20% of the time.
    private static func biasedRaw(using rng: inout SplitMix64) -> Int64 {
        if rng.next() % 5 == 0 {
            return boundaryValues[Int(rng.next() % UInt64(boundaryValues.count))]
        }
        var raw = Int64(bitPattern: rng.next())
        if raw == .min { raw &+= 1 }
        return raw
    }

    /// Generate a random FixedPointDecimal.
    private static func randomFPD(using rng: inout SplitMix64) -> FixedPointDecimal {
        FixedPointDecimal(rawValue: biasedRaw(using: &rng))
    }

    /// Convert FPD to Decimal (always exact).
    private static func toDecimal(_ v: FixedPointDecimal) -> Decimal {
        Decimal(v)
    }

    /// Convert Decimal to FPD using the same banker's rounding.
    private static func fromDecimal(_ d: Decimal) -> FixedPointDecimal {
        FixedPointDecimal(d)
    }

    // MARK: - Arithmetic Parity Tests

    @Test("Addition parity with Foundation.Decimal (10k iterations)")
    func additionParity() {
        var rng = SplitMix64(seed: 0xADD0_0001)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)
            let (fpdResult, overflow) = a.addingReportingOverflow(b)
            if overflow { continue }
            valid += 1

            let decResult = Self.toDecimal(a) + Self.toDecimal(b)
            let expected = Self.fromDecimal(decResult)
            #expect(fpdResult == expected,
                    "Addition parity: \(a) + \(b) = \(fpdResult), expected \(expected)")
        }
        #expect(valid >= 10_000, "Not enough valid iterations: \(valid)")
    }

    @Test("Subtraction parity with Foundation.Decimal (10k iterations)")
    func subtractionParity() {
        var rng = SplitMix64(seed: 0x50B0_0002)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)
            let (fpdResult, overflow) = a.subtractingReportingOverflow(b)
            if overflow { continue }
            valid += 1

            let decResult = Self.toDecimal(a) - Self.toDecimal(b)
            let expected = Self.fromDecimal(decResult)
            #expect(fpdResult == expected,
                    "Subtraction parity: \(a) - \(b) = \(fpdResult), expected \(expected)")
        }
        #expect(valid >= 10_000, "Not enough valid iterations: \(valid)")
    }

    @Test("Multiplication parity with Foundation.Decimal (10k iterations)")
    func multiplicationParity() {
        var rng = SplitMix64(seed: 0x6001_0003)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)
            let (fpdResult, overflow) = a.multipliedReportingOverflow(by: b)
            if overflow { continue }
            valid += 1

            let decResult = Self.toDecimal(a) * Self.toDecimal(b)
            let expected = Self.fromDecimal(decResult)
            #expect(fpdResult == expected,
                    "Multiplication parity: \(a) * \(b) = \(fpdResult), expected \(expected)")
        }
        #expect(valid >= 10_000, "Not enough valid iterations: \(valid)")
    }

    @Test("Division parity with Foundation.Decimal (10k iterations)")
    func divisionParity() {
        var rng = SplitMix64(seed: 0xD1D0_0004)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)
            if b == .zero { continue }
            let (fpdResult, overflow) = a.dividedReportingOverflow(by: b)
            if overflow { continue }
            valid += 1

            var decResult = Decimal()
            var decA = Self.toDecimal(a)
            var decB = Self.toDecimal(b)
            _ = NSDecimalDivide(&decResult, &decA, &decB, .bankers)
            let expected = Self.fromDecimal(decResult)
            #expect(fpdResult == expected,
                    "Division parity: \(a) / \(b) = \(fpdResult), expected \(expected)")
        }
        #expect(valid >= 10_000, "Not enough valid iterations: \(valid)")
    }

    @Test("Remainder self-consistency (10k iterations)")
    func remainderConsistency() {
        var rng = SplitMix64(seed: 0x8E60_0005)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)
            if b == .zero { continue }

            // Skip if division overflows (can't verify invariant)
            let (quotient, divOverflow) = a.dividedReportingOverflow(by: b)
            if divOverflow { continue }

            let remainder = a % b

            // Verify: quotient * b + remainder ≈ a
            // The invariant uses the truncated integer quotient, not the rounded one.
            // Since % uses raw Int64 modulo: a.raw = (a.raw / b.raw) * b.raw + (a.raw % b.raw)
            // This is always exact for integer arithmetic.
            let intQuot = a.rawValue / b.rawValue
            let reconstructed = intQuot * b.rawValue + remainder.rawValue
            #expect(reconstructed == a.rawValue,
                    "Remainder invariant: \(a) %% \(b), remainder=\(remainder)")

            valid += 1
        }
        #expect(valid >= 10_000, "Not enough valid iterations: \(valid)")
    }

    // MARK: - Algebraic Property Tests

    @Test("Commutativity: a+b == b+a, a*b == b*a (10k iterations)")
    func commutativity() {
        var rng = SplitMix64(seed: 0xC066_0006)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)

            // Addition commutativity
            let (ab, overflow1) = a.addingReportingOverflow(b)
            if !overflow1 {
                let (ba, overflow2) = b.addingReportingOverflow(a)
                if !overflow2 {
                    #expect(ab == ba, "Add commutativity: \(a)+\(b)")
                }
            }

            // Multiplication commutativity
            let (abm, overflow3) = a.multipliedReportingOverflow(by: b)
            if !overflow3 {
                let (bam, overflow4) = b.multipliedReportingOverflow(by: a)
                if !overflow4 {
                    #expect(abm == bam, "Mul commutativity: \(a)*\(b)")
                }
            }

            valid += 1
        }
        #expect(valid >= 10_000)
    }

    @Test("Identity: a+0==a, a*1==a, a/1==a, a-0==a (10k iterations)")
    func identity() {
        var rng = SplitMix64(seed: 0x1DE0_0007)
        let one = FixedPointDecimal(rawValue: 100_000_000) // 1.0
        for _ in 0..<10_000 {
            let a = Self.randomFPD(using: &rng)
            #expect(a + .zero == a, "a+0 identity for \(a)")
            #expect(a - .zero == a, "a-0 identity for \(a)")

            let (mulResult, mulOvf) = a.multipliedReportingOverflow(by: one)
            if !mulOvf {
                #expect(mulResult == a, "a*1 identity for \(a)")
            }

            let (divResult, divOvf) = a.dividedReportingOverflow(by: one)
            if !divOvf {
                #expect(divResult == a, "a/1 identity for \(a)")
            }
        }
    }

    @Test("Inverse: a-a==0, a/a==1 (10k iterations)")
    func inverse() {
        var rng = SplitMix64(seed: 0x1AF0_0008)
        let one = FixedPointDecimal(rawValue: 100_000_000)
        for _ in 0..<10_000 {
            let a = Self.randomFPD(using: &rng)
            #expect(a - a == .zero, "a-a==0 for \(a)")

            if a != .zero {
                let (result, overflow) = a.dividedReportingOverflow(by: a)
                if !overflow {
                    #expect(result == one, "a/a==1 for \(a)")
                }
            }
        }
    }

    @Test("Negation: -(-a)==a, a+(-a)==0 (10k iterations)")
    func negation() {
        var rng = SplitMix64(seed: 0x2E60_0009)
        for _ in 0..<10_000 {
            let a = Self.randomFPD(using: &rng)
            #expect(-(-a) == a, "Double negation for \(a)")
            #expect(a + (-a) == .zero, "a+(-a)==0 for \(a)")
        }
    }

    // MARK: - Round-Trip Tests

    @Test("String round-trip for random values (10k iterations)")
    func stringRoundTrip() {
        var rng = SplitMix64(seed: 0x5780_000A)
        for _ in 0..<10_000 {
            let raw = Self.biasedRaw(using: &rng)
            let value = FixedPointDecimal(rawValue: raw)
            if value.isNaN {
                let str = value.description
                #expect(str == "nan")
                let reparsed = FixedPointDecimal(str)
                #expect(reparsed?.isNaN == true)
            } else {
                let str = value.description
                let reparsed = FixedPointDecimal(str)
                #expect(reparsed != nil, "Failed to reparse '\(str)'")
                #expect(reparsed?.rawValue == raw,
                        "String round-trip: raw=\(raw), str='\(str)', reparsed=\(String(describing: reparsed))")
            }
        }
    }

    @Test("Codable round-trip for random values (10k iterations)")
    func codableRoundTrip() throws {
        var rng = SplitMix64(seed: 0xC0DA_000B)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for _ in 0..<10_000 {
            let value = Self.randomFPD(using: &rng)
            let data = try encoder.encode(value)
            let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
            #expect(decoded == value,
                    "Codable round-trip failed for \(value)")
        }
    }

    // MARK: - Comparison Consistency

    @Test("Comparison consistency: ordering and hash (10k iterations)")
    func comparisonConsistency() {
        var rng = SplitMix64(seed: 0xC060_000C)
        for _ in 0..<10_000 {
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)

            if a < b {
                #expect(b > a, "Asymmetry: a<b but !(b>a)")
                #expect(a != b, "a<b but a==b")
            } else if a == b {
                #expect(!(a < b), "a==b but a<b")
                #expect(!(b < a), "a==b but b<a")
                #expect(a.hashValue == b.hashValue, "a==b but different hashes")
            } else {
                #expect(b < a, "a>b but !(b<a)")
                #expect(a != b, "a>b but a==b")
            }
        }
    }

    // MARK: - Overflow Detection

    @Test("Overflow detection: no-overflow results match Decimal reference (10k iterations)")
    func overflowDetection() {
        var rng = SplitMix64(seed: 0x0F10_000D)
        var valid = 0
        for _ in 0..<50_000 {
            if valid >= 10_000 { break }
            let a = Self.randomFPD(using: &rng)
            let b = Self.randomFPD(using: &rng)

            // Test addition
            let (addResult, addOvf) = a.addingReportingOverflow(b)
            if !addOvf {
                #expect(!addResult.isNaN,
                        "Non-overflow add produced NaN for \(a)+\(b)")
                let decSum = Self.toDecimal(a) + Self.toDecimal(b)
                #expect(Decimal(addResult) == decSum,
                        "Add overflow detection: \(a)+\(b)")
            }

            valid += 1
        }
        #expect(valid >= 10_000)
    }
}
