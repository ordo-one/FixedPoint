import Testing
@testable import FixedPointDecimal

@Suite("Overflow Behavior")
struct OverflowTests {

    // MARK: - Wrapping Arithmetic

    @Test("Wrapping addition")
    func wrappingAdd() {
        let a = FixedPointDecimal(rawValue: Int64.max - 1)
        let b = FixedPointDecimal(rawValue: 1)
        let result = a &+ b
        #expect(result.rawValue == Int64.max)
    }

    @Test("Wrapping subtraction")
    func wrappingSub() {
        let a = FixedPointDecimal(rawValue: Int64.min + 2)
        let b = FixedPointDecimal(rawValue: 1)
        let result = a &- b
        #expect(result.rawValue == Int64.min + 1)
    }

    @Test("Wrapping multiplication")
    func wrappingMul() {
        let a: FixedPointDecimal = 100
        let b: FixedPointDecimal = 200
        // This should not trap
        let result = a &* b
        #expect(result == 20000 as FixedPointDecimal)
    }

    // MARK: - Overflow-Reporting

    @Test("Addition reporting overflow — no overflow")
    func addReportNoOverflow() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 20
        let (result, overflow) = a.addingReportingOverflow(b)
        #expect(!overflow)
        #expect(result == 30 as FixedPointDecimal)
    }

    @Test("Addition reporting overflow — overflow")
    func addReportOverflow() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: 1)
        let (_, overflow) = a.addingReportingOverflow(b)
        #expect(overflow)
    }

    @Test("Subtraction reporting overflow — no overflow")
    func subReportNoOverflow() {
        let a: FixedPointDecimal = 20
        let b: FixedPointDecimal = 10
        let (result, overflow) = a.subtractingReportingOverflow(b)
        #expect(!overflow)
        #expect(result == 10 as FixedPointDecimal)
    }

    @Test("Subtraction reporting overflow — overflow")
    func subReportOverflow() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)  // avoid NaN sentinel
        let b = FixedPointDecimal(rawValue: 2)  // subtracting 2 from min+1 overflows
        let (_, overflow) = a.subtractingReportingOverflow(b)
        #expect(overflow)
    }

    @Test("Multiplication reporting overflow — no overflow")
    func mulReportNoOverflow() {
        let a: FixedPointDecimal = 100
        let b: FixedPointDecimal = 200
        let (result, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result == 20000 as FixedPointDecimal)
    }

    @Test("Multiplication reporting overflow — overflow")
    func mulReportOverflow() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: Int64.max)
        let (_, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(overflow)
    }

    @Test("Division reporting overflow — division by zero")
    func divReportDivByZero() {
        let a: FixedPointDecimal = 10
        let (_, overflow) = a.dividedReportingOverflow(by: .zero)
        #expect(overflow)
    }

    @Test("Division reporting overflow — no overflow")
    func divReportNoOverflow() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 3
        let (result, overflow) = a.dividedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result == 3.33333333 as FixedPointDecimal)
    }

    // MARK: - NaN with Overflow-Reporting Operators

    @Test("NaN addingReportingOverflow traps (lhs)")
    func nanAddReportingLhs() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.addingReportingOverflow(FixedPointDecimal(42))
        }
    }

    @Test("NaN addingReportingOverflow traps (rhs)")
    func nanAddReportingRhs() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(42).addingReportingOverflow(.nan)
        }
    }

    @Test("NaN subtractingReportingOverflow traps")
    func nanSubReporting() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.subtractingReportingOverflow(FixedPointDecimal(42))
        }
    }

    @Test("NaN multipliedReportingOverflow traps")
    func nanMulReporting() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.multipliedReportingOverflow(by: FixedPointDecimal(42))
        }
    }

    @Test("NaN dividedReportingOverflow traps")
    func nanDivReporting() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.dividedReportingOverflow(by: FixedPointDecimal(42))
        }
    }

    // MARK: - Overflow near boundary

    @Test("Addition that produces NaN sentinel is detected as overflow")
    func additionProducingNaNSentinel() {
        // If adding two values produces exactly Int64.min, that is the NaN sentinel
        let a = FixedPointDecimal(rawValue: Int64.min + 1)  // .min
        let b = FixedPointDecimal(rawValue: -1)
        let (_, overflow) = a.addingReportingOverflow(b)
        // Int64.min + 1 + (-1) = Int64.min, which is NaN sentinel, so overflow = true
        #expect(overflow)
    }

    @Test("Subtraction that produces NaN sentinel is detected as overflow")
    func subtractionProducingNaNSentinel() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)  // .min
        let b = FixedPointDecimal(rawValue: 1)
        let (_, overflow) = a.subtractingReportingOverflow(b)
        // Int64.min + 1 - 1 = Int64.min, which is NaN sentinel
        #expect(overflow)
    }

    @Test("Wrapping addition that wraps around — raw Int64 semantics")
    func wrappingAdditionOverflow() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: 1)
        // Raw wrapping: Int64.max &+ 1 = Int64.min
        let result = a &+ b
        #expect(result.rawValue == Int64.min)
    }

    @Test("Wrapping subtraction that wraps around — raw Int64 semantics")
    func wrappingSubtractionOverflow() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)
        let b = FixedPointDecimal(rawValue: 2)
        let result = a &- b
        #expect(result.rawValue == Int64.max)
    }

    @Test("Wrapping subtraction producing NaN sentinel — raw Int64 semantics")
    func wrappingSubNaNSentinel() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)
        let b = FixedPointDecimal(rawValue: 1)
        let result = a &- b
        // Raw wrapping: (Int64.min + 1) &- 1 = Int64.min = NaN sentinel
        // No sentinel adjustment — caller is responsible
        #expect(result.rawValue == Int64.min)
    }

    @Test("Wrapping multiplication with overflow does not trap")
    func wrappingMulOverflow() {
        let a: FixedPointDecimal = 92000000000
        let b: FixedPointDecimal = 2
        // This overflows in normal *, but &* should not trap
        let _ = a &* b
    }

    // MARK: - Overflow-Reporting: Division Overflow (Not Division by Zero)

    @Test("Division reporting overflow — result exceeds Int64 range")
    func divReportOverflowNotDivByZero() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: 1) // 0.00000001
        let (_, overflow) = a.dividedReportingOverflow(by: b)
        #expect(overflow)
    }

    // MARK: - Overflow-Reporting: NaN Sentinel Detection

    @Test("Addition reporting overflow detects NaN sentinel result")
    func addReportNaNSentinel() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)
        let b = FixedPointDecimal(rawValue: -1)
        let (result, overflow) = a.addingReportingOverflow(b)
        #expect(overflow, "Should detect NaN sentinel as overflow")
        #expect(result.rawValue == Int64.min)
    }

    @Test("Subtraction reporting overflow detects NaN sentinel result")
    func subReportNaNSentinel() {
        let a = FixedPointDecimal(rawValue: Int64.min + 1)
        let b = FixedPointDecimal(rawValue: 1)
        let (result, overflow) = a.subtractingReportingOverflow(b)
        #expect(overflow, "Should detect NaN sentinel as overflow")
        #expect(result.rawValue == Int64.min)
    }

    // MARK: - Division Reporting Overflow from Value (not div by zero)

    @Test("Division by zero returns zero partial value with overflow")
    func divByZeroReporting() {
        let a: FixedPointDecimal = 42
        let (result, overflow) = a.dividedReportingOverflow(by: .zero)
        #expect(overflow)
        #expect(result == .zero)
    }

    // MARK: - Overflow Boundary Tests (Int64.max / scaleFactor)
    //
    // The max integer part is 92233720368 (Int64.max / 10^8 = 92233720368).
    // These tests exercise arithmetic at the exact boundary where results
    // transition from representable to overflow.

    @Test("Addition at exact boundary — max + 0 succeeds")
    func additionAtBoundarySucceeds() {
        let (result, overflow) = FixedPointDecimal.max.addingReportingOverflow(.zero)
        #expect(!overflow)
        #expect(result == .max)
    }

    @Test("Addition at exact boundary — max + leastNonzero overflows")
    func additionAtBoundaryOverflows() {
        let (_, overflow) = FixedPointDecimal.max.addingReportingOverflow(.leastNonzeroMagnitude)
        #expect(overflow)
    }

    @Test("Subtraction at exact boundary — min - 0 succeeds")
    func subtractionAtBoundarySucceeds() {
        let (result, overflow) = FixedPointDecimal.min.subtractingReportingOverflow(.zero)
        #expect(!overflow)
        #expect(result == .min)
    }

    @Test("Subtraction at exact boundary — min - leastNonzero overflows")
    func subtractionAtBoundaryOverflows() {
        let (_, overflow) = FixedPointDecimal.min.subtractingReportingOverflow(.leastNonzeroMagnitude)
        #expect(overflow)
    }

    @Test("Multiplication at boundary — max integer part * 1 succeeds")
    func mulBoundaryMaxTimesOne() {
        let maxInt: FixedPointDecimal = 92233720368  // max integer part, rawValue = 9223372036800000000
        let one: FixedPointDecimal = 1
        let (result, overflow) = maxInt.multipliedReportingOverflow(by: one)
        #expect(!overflow)
        #expect(result == maxInt)
    }

    @Test("Multiplication at boundary — value just above max overflows")
    func mulBoundaryJustAboveMax() {
        // 92233720369 * 1 in raw: 9223372036900000000 > Int64.max
        let a: FixedPointDecimal = 46116860185  // ~half of max integer part
        let two: FixedPointDecimal = 2.00000001  // just over 2
        let (_, overflow) = a.multipliedReportingOverflow(by: two)
        #expect(overflow)
    }

    @Test("Division at boundary — max / 1 succeeds")
    func divBoundaryMaxDivOne() {
        let one: FixedPointDecimal = 1
        let (result, overflow) = FixedPointDecimal.max.dividedReportingOverflow(by: one)
        #expect(!overflow)
        #expect(result == .max)
    }

    @Test("Division at boundary — max / 0.5 overflows")
    func divBoundaryMaxDivHalf() {
        let half: FixedPointDecimal = 0.5
        let (_, overflow) = FixedPointDecimal.max.dividedReportingOverflow(by: half)
        #expect(overflow)
    }

    // MARK: - Boundary Tests (multiplication near overflow)

    @Test("max * 1 succeeds")
    func mulMaxTimesOne() {
        let result = FixedPointDecimal.max * 1
        #expect(result == .max)
    }

    @Test("Large value * 2 overflows at raw storage level")
    func mulLargeTimesTwo() {
        let a = FixedPointDecimal(rawValue: Int64.max / 2 + 1)
        let (_, overflow) = a._storage.multipliedReportingOverflow(by: Int64(2))
        #expect(overflow)
    }

    @Test("min * (-1) gives max")
    func mulMinTimesNegOne() {
        // .min rawValue is Int64.min + 1, negating gives Int64.max which is fine
        let negOne: FixedPointDecimal = -1
        let result = FixedPointDecimal.min * negOne
        #expect(result == .max)
    }

    @Test("max / 1 succeeds")
    func divMaxByOne() {
        let result = FixedPointDecimal.max / 1
        #expect(result == .max)
    }

    // MARK: - Int128 Intermediate Overflow (Multiplication Corner Cases)
    //
    // Multiplication computes Int128(a.raw) * Int128(b.raw) / scaleFactor.
    // These tests verify cases where the Int128 intermediate is enormous
    // but the final scaled result fits in Int64.

    @Test("Mul — large * large where Int128 intermediate is huge but result fits")
    func mulInt128IntermediateFits() {
        // 9.0 * 9.0 = 81.0
        // Int128 intermediate: 900000000 * 900000000 = 810000000000000000 (fits Int64 too)
        let a: FixedPointDecimal = 9
        let b: FixedPointDecimal = 9
        let result = a * b
        #expect(result == 81 as FixedPointDecimal)
    }

    @Test("Mul — max integer * leastNonzero where intermediate overflows Int64 but result fits")
    func mulMaxTimesLeastNonzero() {
        // max = rawValue 9223372036854775807
        // leastNonzero = rawValue 1 (= 0.00000001)
        // Int128 intermediate: 9223372036854775807 * 1 = 9223372036854775807
        // Divided by scaleFactor with banker's rounding:
        // q = 92233720368, r = 54775807, half = 50000000
        // 54775807 > 50000000, so rounds up to 92233720369
        let result = FixedPointDecimal.max * FixedPointDecimal.leastNonzeroMagnitude
        #expect(result.rawValue == 92233720369)
    }

    @Test("Mul — near-max values where Int128 intermediate exceeds Int64 range but result fits")
    func mulNearMaxInt128Fits() {
        // 92233.72036854 * 1000000 would overflow Int64 in intermediate
        // but Int128 handles it: raw 9223372036854 * raw 100000000000000
        // = Int128(922337203685400000000000000000) / 100000000
        // = 9223372036854000000000 — this overflows Int64, so will report overflow
        // Instead test: 30000 * 30000 = 900000000
        // raw: 3000000000000 * 3000000000000 = 9000000000000000000000000 (Int128)
        // / 100000000 = 90000000000000000 — fits Int64
        let a: FixedPointDecimal = 30000
        let b: FixedPointDecimal = 30000
        let (result, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result == 900000000 as FixedPointDecimal)
    }

    @Test("Mul — values whose Int128 product is large but result fits")
    func mulInt128LargeButFits() {
        // sqrt(92233720368) ≈ 303700, so 303700 * 303700 ≈ 92234690000
        // That's just over max. Use 300000 * 300000 = 90000000000 (fits).
        let a: FixedPointDecimal = 300000
        let b: FixedPointDecimal = 300000
        let (result, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result == 90000000000 as FixedPointDecimal)
    }

    @Test("Mul — max * max overflows even with Int128")
    func mulMaxTimesMax() {
        let (_, overflow) = FixedPointDecimal.max.multipliedReportingOverflow(by: .max)
        #expect(overflow)
    }

    @Test("Mul — max * -1 succeeds and equals min + leastNonzero - leastNonzero")
    func mulMaxTimesNegOne() {
        let negOne: FixedPointDecimal = -1
        let result = FixedPointDecimal.max * negOne
        #expect(result.rawValue == -Int64.max)
        #expect(result == FixedPointDecimal.min)
    }

    // MARK: - Int128 Intermediate Overflow (from fpdec test_mul_frac_limt)

    @Test("Mul — max raw * 1.0 where Int128 intermediate is near limit but result fits")
    func mulNearInt128Overflow() {
        // Two values whose raw Int64s multiply to something near Int128 limits
        // but after dividing by scaleFactor (10^8) the result fits in Int64
        let a = FixedPointDecimal(rawValue: Int64.max)          // ~9.22e9
        let b = FixedPointDecimal(rawValue: 100_000_000)        // 1.0
        let (result, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result.rawValue == Int64.max)
    }

    // MARK: - Division Scaling Overflow (from fpdec test_div_internal_overflow)

    @Test("Division where dividend scaling overflows but result fits")
    func divInternalOverflow() {
        // max / max: Int128(Int64.max) * Int128(scaleFactor) overflows Int64
        // but the quotient is 1.0 which fits
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: Int64.max)
        let result = a / b
        #expect(result == 1 as FixedPointDecimal)
    }

    @Test("Division near-max by near-max reversed")
    func divNearMaxReversed() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: Int64.max - 1)
        let result = b / a
        // (Int64.max - 1) * 10^8 / Int64.max ≈ 0.99999999999... rounds to 1
        #expect(result == 1 as FixedPointDecimal)
    }

    // MARK: - Two's Complement Asymmetry (from fpdec test_mul_neg_one_overflow)

    @Test("Multiply .min by -1 — should NOT overflow (result is .max)")
    func mulMinByNegOneDoesNotOverflow() {
        let a = FixedPointDecimal.min  // rawValue = Int64.min + 1
        let negOne: FixedPointDecimal = -1
        let (result, overflow) = a.multipliedReportingOverflow(by: negOne)
        // -(-92233720368.54775807) = 92233720368.54775807 which is .max, should fit
        #expect(!overflow)
        #expect(result == FixedPointDecimal.max)
    }

    // MARK: - Addition Exact Boundary (from fpdec test_checked_add_pos_overflow)

    @Test("Addition just barely overflows — max + rawValue(1)")
    func addJustBarelyOverflows() {
        let a = FixedPointDecimal(rawValue: Int64.max)
        let b = FixedPointDecimal(rawValue: 1)
        let (_, overflow) = a.addingReportingOverflow(b)
        #expect(overflow)
    }

    @Test("Addition just barely fits — (max-1) + rawValue(1)")
    func addJustBarelyFits() {
        let a = FixedPointDecimal(rawValue: Int64.max - 1)
        let b = FixedPointDecimal(rawValue: 1)
        let (result, overflow) = a.addingReportingOverflow(b)
        #expect(!overflow)
        #expect(result.rawValue == Int64.max)
    }
}
