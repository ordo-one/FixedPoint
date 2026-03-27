import Testing
import FixedPointDecimal

@Suite("Integer Exponentiation")
struct PowTests {
    // MARK: - pow

    @Test("pow base cases")
    func powBaseCases() {
        #expect(FixedPointDecimal.pow(10, 0) == 1)
        #expect(FixedPointDecimal.pow(10, 1) == 10)
        #expect(FixedPointDecimal.pow(FixedPointDecimal(2.5), 1) == 2.5)
    }

    @Test("pow positive exponents")
    func powPositive() {
        #expect(FixedPointDecimal.pow(10, 2) == 100)
        #expect(FixedPointDecimal.pow(10, 3) == 1000)
        #expect(FixedPointDecimal.pow(2, 10) == 1024)
        #expect(FixedPointDecimal.pow(3, 4) == 81)
    }

    @Test("pow negative exponents")
    func powNegative() {
        #expect(FixedPointDecimal.pow(10, -1) == 0.1)
        #expect(FixedPointDecimal.pow(10, -2) == 0.01)
        #expect(FixedPointDecimal.pow(2, -1) == 0.5)
        #expect(FixedPointDecimal.pow(4, -2) == 0.0625)
    }

    @Test("pow with one")
    func powWithOne() {
        #expect(FixedPointDecimal.pow(1, 0) == 1)
        #expect(FixedPointDecimal.pow(1, 100) == 1)
        #expect(FixedPointDecimal.pow(1, -100) == 1)
    }

    @Test("pow NaN traps")
    func powNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(.nan, 2) }
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(.nan, 0) }
    }

    @Test("pow zero base")
    func powZeroBase() {
        #expect(FixedPointDecimal.pow(0, 1) == 0)
        #expect(FixedPointDecimal.pow(0, 5) == 0)
        #expect(FixedPointDecimal.pow(0, 0) == 1) // 0^0 = 1 by convention
    }

    @Test("pow zero base negative exponent traps")
    func powZeroBaseNegativeExponent() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(0, -1) }
    }

    @Test("pow type inference in context")
    func powTypeInference() {
        let divisor: FixedPointDecimal = .pow(10, 3)
        #expect(divisor == 1000)
    }

    @Test("pow large powers of 10")
    func powLargePowersOf10() {
        #expect(FixedPointDecimal.pow(10, 8) == 100000000 as FixedPointDecimal)
        #expect(FixedPointDecimal.pow(10, 10) == 10000000000 as FixedPointDecimal)
    }

    @Test("pow fractional bases")
    func powFractionalBases() {
        #expect(FixedPointDecimal.pow(FixedPointDecimal(5.4), 2) == 29.16)
        #expect(FixedPointDecimal.pow(FixedPointDecimal(1.1), 3) == 1.331)
        #expect(FixedPointDecimal.pow(FixedPointDecimal(0.5), 3) == 0.125)
        #expect(FixedPointDecimal.pow(FixedPointDecimal(2.5), 2) == 6.25)
    }

    @Test("pow negative fractional bases")
    func powNegativeFractionalBases() {
        #expect(FixedPointDecimal.pow(FixedPointDecimal(-2.0), 2) == 4.0)
        #expect(FixedPointDecimal.pow(FixedPointDecimal(-2.0), 3) == -8.0)
    }

    @Test("pow overflow traps")
    func powOverflow() async {
        // Int64 max raw value is ~9.2×10^18, so 10^11 × 10^8 (scale) overflows
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(10, 11) }
        // Large base to large power
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(FixedPointDecimal(1000000), 4) }
        // Negative exponent where positive overflows
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(FixedPointDecimal(1000000), -4) }
    }

    @Test("pow overflow boundary — largest non-overflowing power of 10")
    func powOverflowBoundary() {
        // 10^10 = 10_000_000_000 — rawValue = 10^18, fits in Int64
        let p10 = FixedPointDecimal.pow(10, 10)
        #expect(p10 == 10000000000 as FixedPointDecimal)

        // 10^11 would be rawValue = 10^19, overflows Int64 — tested in powOverflow
    }

    // MARK: - numberOfFractionalDigits

    @Test("numberOfFractionalDigits basic")
    func fractionalDigitsBasic() {
        #expect(FixedPointDecimal(123.45).numberOfFractionalDigits == 2)
        #expect(FixedPointDecimal(1.5).numberOfFractionalDigits == 1)
        #expect(FixedPointDecimal(0.001).numberOfFractionalDigits == 3)
        #expect(FixedPointDecimal(99.99999999).numberOfFractionalDigits == 8)
    }

    @Test("numberOfFractionalDigits zero fractional part")
    func fractionalDigitsZero() {
        #expect(FixedPointDecimal(100).numberOfFractionalDigits == 0)
        #expect(FixedPointDecimal(0).numberOfFractionalDigits == 0)
        #expect(FixedPointDecimal(1).numberOfFractionalDigits == 0)
        #expect(FixedPointDecimal(-42).numberOfFractionalDigits == 0)
    }

    @Test("numberOfFractionalDigits NaN")
    func fractionalDigitsNaN() {
        #expect(FixedPointDecimal.nan.numberOfFractionalDigits == 0)
    }

    @Test("numberOfFractionalDigits negative values")
    func fractionalDigitsNegative() {
        #expect(FixedPointDecimal(-1.23).numberOfFractionalDigits == 2)
        #expect(FixedPointDecimal(-0.1).numberOfFractionalDigits == 1)
    }

    @Test("numberOfFractionalDigits trailing zeros trimmed")
    func fractionalDigitsTrailingZeros() {
        // 1.50 has fractional part 50000000, trailing zeros = 6, digits = 8 - 6 = 2... wait
        // Actually 1.5 → rawValue = 150000000, frac = 50000000
        // 50000000 / 10 = 5000000 (1), / 10 = 500000 (2), ... / 10 = 5 (7), stop
        // trailingZeros = 7, digits = 8 - 7 = 1. Correct: "1.5" has 1 fractional digit.
        #expect(FixedPointDecimal(1.50).numberOfFractionalDigits == 1)
        #expect(FixedPointDecimal(1.10).numberOfFractionalDigits == 1)
        #expect(FixedPointDecimal(1.00000001).numberOfFractionalDigits == 8)
    }

    @Test("numberOfFractionalDigits smallest value")
    func fractionalDigitsSmallest() {
        let smallest = FixedPointDecimal(rawValue: 1) // 0.00000001
        #expect(smallest.numberOfFractionalDigits == 8)
    }

    // MARK: - init(significand:exponent:)

    @Test("significand+exponent basic conversions")
    func significandExponentBasic() {
        #expect(FixedPointDecimal(significand: 12345, exponent: -2) == 123.45 as FixedPointDecimal)
        #expect(FixedPointDecimal(significand: 500, exponent: 0) == 500)
        #expect(FixedPointDecimal(significand: 1, exponent: 3) == 1000)
        #expect(FixedPointDecimal(significand: 1, exponent: -8) == 0.00000001 as FixedPointDecimal)
    }

    @Test("significand+exponent negative significand")
    func significandExponentNegative() {
        #expect(FixedPointDecimal(significand: -12345, exponent: -2) == -123.45 as FixedPointDecimal)
        #expect(FixedPointDecimal(significand: -1, exponent: 0) == -1)
    }

    @Test("significand+exponent zero")
    func significandExponentZero() {
        #expect(FixedPointDecimal(significand: 0, exponent: 0) == .zero)
        #expect(FixedPointDecimal(significand: 0, exponent: 5) == .zero)
        #expect(FixedPointDecimal(significand: 0, exponent: -3) == .zero)
    }

    @Test("significand+exponent exchange wire format examples")
    func significandExponentWireFormat() {
        // Optiq-style: price 123.45 sent as (12345, -2)
        #expect(FixedPointDecimal(significand: 12345, exponent: -2) == 123.45 as FixedPointDecimal)
        // Price 10.50 sent as (1050, -2)
        #expect(FixedPointDecimal(significand: 1050, exponent: -2) == 10.50 as FixedPointDecimal)
        // Quantity 1000 sent as (1, 3)
        #expect(FixedPointDecimal(significand: 1, exponent: 3) == 1000)
        // Sub-penny price 0.0001 sent as (1, -4)
        #expect(FixedPointDecimal(significand: 1, exponent: -4) == 0.0001 as FixedPointDecimal)
    }

    @Test("significand+exponent precision loss for deep negative exponents")
    func significandExponentPrecisionLoss() {
        // exponent -10 means shift = 8 + (-10) = -2, so divide by 100
        // 12345 / 100 = 123 (truncated) → 0.00000123
        let value = FixedPointDecimal(significand: 12345, exponent: -10)
        #expect(value == FixedPointDecimal(rawValue: 123))
    }

    // MARK: - pow(10, n) fast path

    @Test("pow(10, n) positive exponents via lookup table")
    func pow10Positive() {
        let ten: FixedPointDecimal = 10
        #expect(FixedPointDecimal.pow(ten, 0) == 1)
        #expect(FixedPointDecimal.pow(ten, 1) == 10)
        #expect(FixedPointDecimal.pow(ten, 2) == 100)
        #expect(FixedPointDecimal.pow(ten, 3) == 1000)
        #expect(FixedPointDecimal.pow(ten, 4) == 10000)
        #expect(FixedPointDecimal.pow(ten, 5) == 100000)
        #expect(FixedPointDecimal.pow(ten, 6) == 1000000)
        #expect(FixedPointDecimal.pow(ten, 7) == 10000000)
        #expect(FixedPointDecimal.pow(ten, 8) == 100000000)
        #expect(FixedPointDecimal.pow(ten, 9) == 1000000000)
        #expect(FixedPointDecimal.pow(ten, 10) == 10000000000)
    }

    @Test("pow(10, n) negative exponents via lookup table")
    func pow10Negative() {
        let ten: FixedPointDecimal = 10
        #expect(FixedPointDecimal.pow(ten, -1) == 0.1)
        #expect(FixedPointDecimal.pow(ten, -2) == 0.01)
        #expect(FixedPointDecimal.pow(ten, -3) == 0.001)
        #expect(FixedPointDecimal.pow(ten, -4) == 0.0001)
        #expect(FixedPointDecimal.pow(ten, -5) == 0.00001)
        #expect(FixedPointDecimal.pow(ten, -6) == 0.000001)
        #expect(FixedPointDecimal.pow(ten, -7) == 0.0000001)
        #expect(FixedPointDecimal.pow(ten, -8) == 0.00000001)
    }

    @Test("pow(10, -9) below representable precision returns zero")
    func pow10BelowPrecision() {
        let ten: FixedPointDecimal = 10
        #expect(FixedPointDecimal.pow(ten, -9) == .zero)
    }

    @Test("pow(10, 11) overflows traps")
    func pow10Overflow() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.pow(10, 11) }
    }

    @Test("pow(10, n) fast path matches general path for all valid exponents")
    func pow10MatchesGeneral() {
        let ten: FixedPointDecimal = 10
        for exponent in -8...10 {
            let fast = FixedPointDecimal.pow(ten, exponent)
            if exponent >= 0 {
                var manual: FixedPointDecimal = 1
                for _ in 0..<exponent {
                    let (product, _) = manual.multipliedReportingOverflow(by: ten)
                    manual = product
                }
                #expect(fast == manual, "pow(10, \(exponent)): fast=\(fast) manual=\(manual)")
            } else {
                let positive = FixedPointDecimal.pow(ten, -exponent)
                let one: FixedPointDecimal = 1
                let (manual, _) = one.dividedReportingOverflow(by: positive)
                #expect(fast == manual, "pow(10, \(exponent)): fast=\(fast) manual=\(manual)")
            }
        }
    }
}
