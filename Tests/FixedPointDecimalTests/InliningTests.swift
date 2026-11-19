import FixedPointDecimal
import Testing

// `@_noAllocation` rejects any call into another module whose body is not inlinable, so these functions
// stop compiling if an `@inlinable` API starts reaching a non-inlinable internal helper (for example a
// `@usableFromInline` computed property such as `scaleFactor`). That is how allocation-free client code
// sees this module, so the check runs here at compile time rather than as an assertion.

@_noAllocation
private func arithmetic(_ lhs: FixedPointDecimal, _ rhs: FixedPointDecimal) -> FixedPointDecimal {
    (lhs + rhs - rhs) * rhs / rhs
}

@_noAllocation
private func overflowReporting(_ lhs: FixedPointDecimal, _ rhs: FixedPointDecimal) -> Bool {
    lhs.multipliedReportingOverflow(by: rhs).overflow || lhs.dividedReportingOverflow(by: rhs).overflow
}

@_noAllocation
private func comparison(_ lhs: FixedPointDecimal, _ rhs: FixedPointDecimal) -> Bool {
    lhs < rhs && lhs != rhs && FixedPointDecimal.minimum(lhs, rhs) == lhs
}

@_noAllocation
private func conversions(_ value: FixedPointDecimal) -> Int {
    Int(value) + Int(exactly: value)! + Int(Double(value)) + Int(FixedPointDecimal(3))
        + value.numberOfFractionalDigits
}

@_noAllocation
private func rounding(_ value: FixedPointDecimal) -> FixedPointDecimal {
    value.rounded(scale: 2) + value.rounded(scale: 0, .towardZero)
}

@_noAllocation
private func powers(_ value: FixedPointDecimal, _ exponent: Int) -> FixedPointDecimal {
    FixedPointDecimal.pow(value, exponent) + FixedPointDecimal.pow(10, exponent)
}

@_noAllocation
private func wireFormat(_ significand: Int, _ exponent: Int) -> FixedPointDecimal {
    FixedPointDecimal(significand: significand, exponent: exponent)
}

@Suite("Inlining")
struct InliningTests {
    @Test("Arithmetic, comparison and conversions inline across modules")
    func inlineAcrossModules() {
        #expect(arithmetic(2.5, 4) == 2.5)
        #expect(overflowReporting(2.5, 4) == false)
        #expect(comparison(1, 2))
        #expect(conversions(2) == 2 + 2 + 2 + 3 + 0)
        #expect(rounding(1.235) == 2.24)
        #expect(powers(2, 3) == 1008)
        #expect(wireFormat(12345, -2) == 123.45)
    }
}
