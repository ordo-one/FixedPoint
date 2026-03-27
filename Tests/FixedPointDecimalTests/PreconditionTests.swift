import Testing
import Foundation
@testable import FixedPointDecimal

@Suite("Precondition Failures")
struct PreconditionTests {

    // MARK: - Initializer Preconditions

    @Test("init(_: BinaryInteger) traps on overflow")
    func initIntegerOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(Int64.max)
        }
    }

    @Test("init(integer:fraction:) traps on negative fraction")
    func initIntegerFractionNegative() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(integer: 0, fraction: -1)
        }
    }

    @Test("init(integer:fraction:) traps on fraction >= scaleFactor")
    func initIntegerFractionTooLarge() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(integer: 0, fraction: 100_000_000)
        }
    }

    @Test("init(integer:fraction:) traps on integer part overflow")
    func initIntegerFractionIntegerOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(integer: Int64.max, fraction: 0)
        }
    }

    @Test("init(significand:exponent:) traps on out-of-range shift")
    func initSignificandExponentOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(significand: 1, exponent: 100)
        }
    }

    @Test("init(significand:exponent:) traps on overflow")
    func initSignificandExponentOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(significand: Int(Int64.max), exponent: 1)
        }
    }

    @Test("init(_ Double) traps on Double.nan")
    func initDoubleNaN() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(Double.nan)
        }
    }

    @Test("init(_ Double) traps on Double.infinity")
    func initDoubleInfinity() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(Double.infinity)
        }
    }

    @Test("init(_ Double) traps on negative infinity")
    func initDoubleNegativeInfinity() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal(-Double.infinity)
        }
    }

    // MARK: - Property Access Preconditions

    @Test("integerPart traps on NaN")
    func integerPartNaN() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.integerPart
        }
    }

    @Test("fractionalPart traps on NaN")
    func fractionalPartNaN() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan.fractionalPart
        }
    }

    @Test("Int32 conversion traps on NaN")
    func int32NaN() async {
        await #expect(processExitsWith: .failure) {
            _ = Int32(FixedPointDecimal.nan)
        }
    }

    @Test("Int32 conversion traps when integer part exceeds Int32 range")
    func int32Overflow() async {
        await #expect(processExitsWith: .failure) {
            let value: FixedPointDecimal = 90000000000
            _ = Int32(value)
        }
    }

    @Test("Int conversion traps on NaN")
    func intNaN() async {
        await #expect(processExitsWith: .failure) {
            _ = Int(FixedPointDecimal.nan)
        }
    }

    @Test("Int64 conversion traps on NaN")
    func int64NaN() async {
        await #expect(processExitsWith: .failure) {
            _ = Int64(FixedPointDecimal.nan)
        }
    }

    // MARK: - Arithmetic Preconditions

    @Test("Addition traps on overflow")
    func additionOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.max + 1
        }
    }

    @Test("Subtraction traps on overflow")
    func subtractionOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.min - 1
        }
    }

    @Test("Multiplication traps on overflow")
    func multiplicationOverflow() async {
        await #expect(processExitsWith: .failure) {
            let a: FixedPointDecimal = 92000000000
            let b: FixedPointDecimal = 2
            _ = a * b
        }
    }

    @Test("Division by zero traps")
    func divisionByZero() async {
        await #expect(processExitsWith: .failure) {
            let a: FixedPointDecimal = 1
            _ = a / FixedPointDecimal.zero
        }
    }

    @Test("Division overflow traps")
    func divisionOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.max / FixedPointDecimal(rawValue: 1) // divide by 0.00000001
        }
    }

    @Test("Remainder by zero traps")
    func remainderByZero() async {
        await #expect(processExitsWith: .failure) {
            let a: FixedPointDecimal = 1
            _ = a % FixedPointDecimal.zero
        }
    }

    // MARK: - Rounding Preconditions

    @Test("rounded(scale:) traps on negative scale")
    func roundedNegativeScale() async {
        await #expect(processExitsWith: .failure) {
            let a: FixedPointDecimal = 1.5
            _ = a.rounded(scale: -1)
        }
    }

    @Test("rounded(scale:) traps on scale > 8")
    func roundedScaleTooLarge() async {
        await #expect(processExitsWith: .failure) {
            let a: FixedPointDecimal = 1.5
            _ = a.rounded(scale: 9)
        }
    }

    // MARK: - FormatStyle Precision Preconditions

    @Test("FixedPointDecimalFormatStyle.init traps on negative fractionDigits")
    func formatStyleNegativeFractionDigits() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimalFormatStyle(fractionDigits: -1)
        }
    }

    @Test("FixedPointDecimalFormatStyle.init traps on fractionDigits > 8")
    func formatStyleFractionDigitsTooLarge() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimalFormatStyle(fractionDigits: 9)
        }
    }

    @Test("FixedPointDecimalFormatStyle.precision traps on negative digits")
    func formatStylePrecisionNegative() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimalFormatStyle().precision(-1)
        }
    }

    @Test("FixedPointDecimalFormatStyle.precision traps on digits > 8")
    func formatStylePrecisionTooLarge() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimalFormatStyle().precision(9)
        }
    }
}
