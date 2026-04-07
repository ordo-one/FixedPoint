import Testing
import Foundation
@testable import FixedPointDecimal

@Suite("Type Conversions")
struct ConversionTests {

    // MARK: - Double Round-Trips

    @Test("Double round-trip for simple values")
    func doubleRoundTrip() {
        let values: [Double] = [0, 1, -1, 123.45, -99.99, 0.00000001, 1000000]
        for value in values {
            let fixed = FixedPointDecimal(value)
            let roundTrip = Double(fixed)
            #expect(abs(roundTrip - value) < 1e-7, "Round-trip failed for \(value)")
        }
    }

    @Test("Double convenience initializer")
    func doubleConvenienceInit() {
        let fixed: FixedPointDecimal = 123.45
        let d = Double(fixed)
        #expect(d == 123.45)
    }

    @Test("Exact Double initializer")
    func exactDoubleInit() {
        let fixed: FixedPointDecimal = 1.5
        let d = Double(exactly: fixed)
        #expect(d == 1.5)
    }

    @Test("Double NaN handling")
    func doubleNaN() {
        let nan = FixedPointDecimal.nan
        #expect(Double(nan).isNaN)

        let d = Double(nan)
        #expect(d.isNaN)
    }

    // MARK: - Decimal Round-Trips

    @Test("Decimal round-trip for simple values")
    func decimalRoundTrip() {
        let values = ["0", "1", "-1", "123.45", "-99.99", "0.00000001", "1000000"]
        for str in values {
            let fixed = FixedPointDecimal(str)!
            let decimal = Decimal(fixed)
            let roundTrip = FixedPointDecimal(decimal)
            #expect(roundTrip == fixed, "Round-trip failed for \(str)")
        }
    }

    @Test("Decimal convenience initializer")
    func decimalConvenienceInit() {
        let fixed: FixedPointDecimal = 123.45
        let d = Decimal(fixed)
        #expect(d == Decimal(string: "123.45"))
    }

    @Test("Decimal NaN handling")
    func decimalNaN() {
        let nan = FixedPointDecimal.nan
        #expect(Decimal(nan).isNaN)

        let d = Decimal.nan
        let fixed = FixedPointDecimal(d)
        #expect(fixed.isNaN)
    }

    @Test("Decimal rounding beyond 8 digits")
    func decimalTruncation() {
        let decimal = Decimal(string: "123.123456789")!
        let fixed = FixedPointDecimal(decimal)
        // 9th digit is 9 > 5, rounds up to 123.12345679
        #expect(fixed == 123.12345679 as FixedPointDecimal)
    }

    @Test("Decimal exact initializer — overflow returns nil")
    func decimalExactOverflow() {
        let huge = Decimal(string: "999999999999")!  // > 92 billion
        let result = FixedPointDecimal(exactly: huge)
        #expect(result == nil)
    }

    // MARK: - Integer Conversions

    @Test("Int value truncation")
    func intValue() {
        let value: FixedPointDecimal = 123.99
        #expect(Int(value) == 123)
        #expect(Int64(value) == 123)
    }

    @Test("Negative int value truncation")
    func negativeIntValue() {
        let value: FixedPointDecimal = -5.75
        #expect(Int(value) == -5)
    }

    // MARK: - Cross-Type Conversion

    @Test("FixedPointDecimal -> Double -> FixedPointDecimal round-trip")
    func fixedDoubleFixed() {
        let original: FixedPointDecimal = 99.95
        let d = Double(original)
        let recovered = FixedPointDecimal(d)
        #expect(recovered == original)
    }

    @Test("FixedPointDecimal -> Decimal -> FixedPointDecimal round-trip")
    func fixedDecimalFixed() {
        let original: FixedPointDecimal = 42.12345678
        let d = Decimal(original)
        let recovered = FixedPointDecimal(d)
        #expect(recovered == original)
    }

    // MARK: - Double Conversion Edge Cases

    @Test("Double(FixedPointDecimal.max) — precision check")
    func doubleOfMax() {
        let maxVal = FixedPointDecimal.max
        let d = Double(maxVal)
        #expect(d > 92_233_720_368.0)
        #expect(d < 92_233_720_369.0)
    }

    @Test("Double(FixedPointDecimal.min) — precision check")
    func doubleOfMin() {
        let minVal = FixedPointDecimal.min
        let d = Double(minVal)
        #expect(d < -92_233_720_368.0)
        #expect(d > -92_233_720_369.0)
    }

    @Test("Decimal round-trip for .max")
    func decimalRoundTripMax() {
        let maxVal = FixedPointDecimal.max
        let d = Decimal(maxVal)
        let recovered = FixedPointDecimal(d)
        #expect(recovered == maxVal)
    }

    @Test("Decimal round-trip for .min")
    func decimalRoundTripMin() {
        let minVal = FixedPointDecimal.min
        let d = Decimal(minVal)
        let recovered = FixedPointDecimal(d)
        #expect(recovered == minVal)
    }

    @Test("FixedPointDecimal from Double.zero")
    func fromDoubleZero() {
        let value = FixedPointDecimal(Double.zero)
        #expect(value == .zero)
    }

    @Test("FixedPointDecimal from Double(-0.0)")
    func fromDoubleNegativeZero() {
        let value = FixedPointDecimal(Double(-0.0))
        #expect(value == .zero)
    }

    @Test("Double(exactly:) for NaN returns nil")
    func doubleExactlyNaN() {
        let d = Double(exactly: FixedPointDecimal.nan)
        #expect(d == nil)
    }

    @Test("Decimal(exactly:) returns nil for NaN")
    func decimalExactlyNaN() {
        let d = Decimal(exactly: FixedPointDecimal.nan)
        #expect(d == nil)
    }

    @Test("FixedPointDecimal(exactly: Double) — overflow returns nil")
    func fixedFromDoubleExactlyOverflow() {
        let huge = 1e18
        let result = FixedPointDecimal(exactly: huge)
        #expect(result == nil)
    }

    @Test("Negative int64 value truncation")
    func negativeInt64Value() {
        let value: FixedPointDecimal = -5.75
        #expect(Int64(value) == -5)
    }

    @Test("Int value of zero")
    func intValueZero() {
        #expect(Int(FixedPointDecimal.zero) == 0)
        #expect(Int64(FixedPointDecimal.zero) == 0)
    }

    @Test("Numeric magnitude for positive")
    func magnitudePositive() {
        let value: FixedPointDecimal = 42.5
        #expect(value.magnitude == 42.5 as FixedPointDecimal)
    }

    @Test("Numeric magnitude for negative")
    func magnitudeNegative() {
        let value: FixedPointDecimal = -42.5
        #expect(value.magnitude == 42.5 as FixedPointDecimal)
    }

    @Test("Numeric magnitude for NaN traps")
    func magnitudeNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.magnitude }
    }

    @Test("Numeric magnitude for zero")
    func magnitudeZero() {
        #expect(FixedPointDecimal.zero.magnitude == .zero)
    }

    // MARK: - Decimal Round-Trip for Negative Values with >8 Digits

    @Test("Decimal -> FPD -> Decimal round-trip for negative with >8 fractional digits")
    func decimalRoundTripNegativeOverflow() {
        let decimal = Decimal(string: "-123.123456789")!
        let fixed = FixedPointDecimal(decimal)
        // 9th digit is 9 > 5, rounds away from zero to -123.12345679
        #expect(fixed == -123.12345679 as FixedPointDecimal)
        // Round-trip back to Decimal
        let recovered = Decimal(fixed)
        #expect(recovered == Decimal(string: "-123.12345679"))
    }

    @Test("Decimal -> FPD -> Decimal round-trip for large negative")
    func decimalRoundTripLargeNegative() {
        let decimal = Decimal(string: "-92233720368.54775807")!
        let fixed = FixedPointDecimal(decimal)
        #expect(fixed == FixedPointDecimal.min)
        let recovered = Decimal(fixed)
        let expected = Decimal(string: "-92233720368.54775807")!
        #expect(recovered == expected)
    }

    // MARK: - Decimal(exactly: .nan) Returns nil

    @Test("FixedPointDecimal(exactly: Decimal.nan) returns nil")
    func fixedFromDecimalNaNExactly() {
        let result = FixedPointDecimal(exactly: Decimal.nan)
        #expect(result == nil)
    }

    // MARK: - Double(exactly:) for Value That Can't Round-Trip

    @Test("Double(exactly:) returns nil for value that can't round-trip exactly")
    func doubleExactlyCannotRoundTrip() {
        let max = FixedPointDecimal.max
        let d = Double(exactly: max)
        #expect(d == nil)
    }

    // MARK: - init?(exactly:) with UInt64

    @Test("Exact init from UInt64")
    func exactInitFromUInt64() {
        let value = FixedPointDecimal(exactly: UInt64(42))
        #expect(value != nil)
        #expect(value?.integerPart == 42)
    }

    @Test("Exact init from UInt64 overflow")
    func exactInitFromUInt64Overflow() {
        let value = FixedPointDecimal(exactly: UInt64.max)
        #expect(value == nil)
    }

    // MARK: - Negative Double Conversion

    @Test("Negative Double conversion round-trip")
    func negativeDoubleConversion() {
        let d = -42.123
        let fixed = FixedPointDecimal(d)
        let roundTrip = Double(fixed)
        #expect(abs(roundTrip - d) < 1e-7)
    }

    // MARK: - init?(exactly: Double) Edge Cases

    @Test("init?(exactly: Double) with negative infinity returns nil")
    func exactDoubleNegInfinity() {
        let result = FixedPointDecimal(exactly: -Double.infinity)
        #expect(result == nil)
    }

    @Test("init?(exactly: Double) with negative zero")
    func exactDoubleNegativeZero() {
        let result = FixedPointDecimal(exactly: -0.0)
        #expect(result != nil)
        #expect(result == .zero)
    }

    // MARK: - Parity with Foundation.Decimal

    @Test("FPD -> Double matches Decimal -> Double for financial values")
    func doubleConversionParityWithDecimal() {
        let values = [
            "0", "1", "-1", "0.5", "-0.5",
            "123.45", "-123.45", "99.99", "0.01",
            "0.001", "0.0001", "0.00001",
            "1000", "999999.99", "12345678.12345678",
        ]
        for str in values {
            let fpd = FixedPointDecimal(str)!
            let dec = Decimal(string: str)!
            let fpdDouble = Double(fpd)
            let decDouble = NSDecimalNumber(decimal: dec).doubleValue
            #expect(fpdDouble == decDouble,
                    "Double parity failed for '\(str)': FPD=\(fpdDouble), Decimal=\(decDouble)")
        }
    }

    @Test("FPD -> Double matches Decimal -> Double within ULP for extreme values")
    func doubleConversionParityExtreme() {
        let values = [
            "0.000001", "0.0000001", "0.00000001",
            "92233720368.54775807", "-92233720368.54775807",
        ]
        for str in values {
            let fpd = FixedPointDecimal(str)!
            let dec = Decimal(string: str)!
            let fpdDouble = Double(fpd)
            let decDouble = NSDecimalNumber(decimal: dec).doubleValue
            let relError = Swift.abs(fpdDouble - decDouble) / Swift.max(Swift.abs(fpdDouble), Swift.abs(decDouble), 1e-15)
            #expect(relError < 1e-14,
                    "Double parity exceeded tolerance for '\(str)': FPD=\(fpdDouble), Decimal=\(decDouble), relError=\(relError)")
        }
    }

    @Test("Decimal -> FPD -> Decimal is identity for values within 8 digits")
    func decimalRoundTripParity() {
        let values = [
            "0", "1", "-1", "0.5", "123.45", "-99.99",
            "0.00000001", "-0.00000001", "1000000",
            "42.12345678", "-42.12345678",
            "92233720368.54775807", "-92233720368.54775807",
        ]
        for str in values {
            let dec = Decimal(string: str)!
            let fpd = FixedPointDecimal(dec)
            let recoveredDec = Decimal(fpd)
            #expect(recoveredDec == dec,
                    "Decimal round-trip parity failed for '\(str)': got \(recoveredDec)")
        }
    }

    @Test("FPD string matches Decimal string for integer values")
    func stringParityIntegers() {
        let integers: [Int64] = [0, 1, -1, 42, -42, 1000, -1000, 999999999, -999999999]
        for int in integers {
            let fpd = FixedPointDecimal(int)
            let dec = Decimal(int)
            #expect(fpd.description == "\(dec)",
                    "String parity failed for \(int): FPD='\(fpd.description)', Decimal='\(dec)'")
        }
    }

    @Test("FPD arithmetic matches Decimal arithmetic for addition")
    func additionParityWithDecimal() {
        let pairs: [(String, String)] = [
            ("1.5", "2.5"), ("100", "0.01"), ("-50.25", "50.25"),
            ("0.00000001", "0.00000001"), ("123.456", "789.012"),
        ]
        for (aStr, bStr) in pairs {
            let fpdA = FixedPointDecimal(aStr)!
            let fpdB = FixedPointDecimal(bStr)!
            let fpdResult = fpdA + fpdB

            let decA = Decimal(string: aStr)!
            let decB = Decimal(string: bStr)!
            let decResult = decA + decB

            #expect(Decimal(fpdResult) == decResult,
                    "Addition parity failed: FPD \(aStr)+\(bStr)=\(fpdResult), Decimal=\(decResult)")
        }
    }

    @Test("FPD arithmetic matches Decimal arithmetic for subtraction")
    func subtractionParityWithDecimal() {
        let pairs: [(String, String)] = [
            ("10", "3.5"), ("100.01", "0.01"), ("-50.25", "50.25"),
            ("0.00000002", "0.00000001"), ("1000", "999.999"),
        ]
        for (aStr, bStr) in pairs {
            let fpdA = FixedPointDecimal(aStr)!
            let fpdB = FixedPointDecimal(bStr)!
            let fpdResult = fpdA - fpdB

            let decA = Decimal(string: aStr)!
            let decB = Decimal(string: bStr)!
            let decResult = decA - decB

            #expect(Decimal(fpdResult) == decResult,
                    "Subtraction parity failed: FPD \(aStr)-\(bStr)=\(fpdResult), Decimal=\(decResult)")
        }
    }

    @Test("FPD arithmetic matches Decimal arithmetic for multiplication")
    func multiplicationParityWithDecimal() {
        let pairs: [(String, String)] = [
            ("2", "3"), ("10.5", "2"), ("0.1", "0.1"),
            ("100", "0.01"), ("123.45", "1"),
        ]
        for (aStr, bStr) in pairs {
            let fpdA = FixedPointDecimal(aStr)!
            let fpdB = FixedPointDecimal(bStr)!
            let fpdResult = fpdA * fpdB

            let decA = Decimal(string: aStr)!
            let decB = Decimal(string: bStr)!
            let decResult = decA * decB

            // Compare via string since Decimal may carry extra precision
            let fpdDec = Decimal(fpdResult)
            // Truncate Decimal result to 8 fractional digits for comparison
            let fpdFromDec = FixedPointDecimal(decResult)
            #expect(fpdResult == fpdFromDec,
                    "Multiplication parity failed: FPD \(aStr)*\(bStr)=\(fpdResult) (dec=\(fpdDec)), Decimal=\(decResult)")
        }
    }

    @Test("FPD arithmetic matches Decimal arithmetic for division")
    func divisionParityWithDecimal() {
        let pairs: [(String, String)] = [
            ("10", "2"), ("100", "3"), ("1", "7"),
            ("123.45", "1"), ("99.99", "3"),
        ]
        for (aStr, bStr) in pairs {
            let fpdA = FixedPointDecimal(aStr)!
            let fpdB = FixedPointDecimal(bStr)!
            let fpdResult = fpdA / fpdB

            let decA = Decimal(string: aStr)!
            let decB = Decimal(string: bStr)!
            var decResult = Decimal()
            var decAVar = decA
            var decBVar = decB
            _ = NSDecimalDivide(&decResult, &decAVar, &decBVar, .down)

            // Both truncate, so the first 8 fractional digits should match
            let fpdFromDec = FixedPointDecimal(decResult)
            #expect(fpdResult == fpdFromDec,
                    "Division parity failed: FPD \(aStr)/\(bStr)=\(fpdResult), Decimal(truncated)=\(fpdFromDec)")
        }
    }

    // MARK: - init?(exactly:) Strictness

    @Test("init?(exactly: Double) rejects inexact sub-tick values")
    func exactDoubleRejectsInexact() {
        // 0.000000009 cannot be exactly represented — it rounds to 0.00000001
        #expect(FixedPointDecimal(exactly: 0.000000009) == nil)
        // 1.0/3.0 cannot round-trip exactly through 8-digit fixed-point
        #expect(FixedPointDecimal(exactly: 1.0 / 3.0) == nil)
    }

    @Test("init?(exactly: Double) accepts exact values")
    func exactDoubleAcceptsExact() {
        #expect(FixedPointDecimal(exactly: 0.5) != nil)
        #expect(FixedPointDecimal(exactly: 0.5)?.description == "0.5")
        #expect(FixedPointDecimal(exactly: 0.25) != nil)
        #expect(FixedPointDecimal(exactly: 1.0) != nil)
        #expect(FixedPointDecimal(exactly: 0.0) != nil)
        #expect(FixedPointDecimal(exactly: -0.5) != nil)
        #expect(FixedPointDecimal(exactly: 123.0) != nil)
    }

    @Test("init?(exactly: Decimal) rejects sub-tick fractional values")
    func exactDecimalRejectsSubTick() {
        // 0.000000009 has a 9th fractional digit — beyond 8-digit precision
        let subTick = Decimal(string: "0.000000009")!
        #expect(FixedPointDecimal(exactly: subTick) == nil)
        // 0.123456789 also has 9 digits
        let ninedigits = Decimal(string: "0.123456789")!
        #expect(FixedPointDecimal(exactly: ninedigits) == nil)
    }

    @Test("init?(exactly: Decimal) accepts values within 8 decimal places")
    func exactDecimalAcceptsExact() {
        let exact = Decimal(string: "123.45")!
        #expect(FixedPointDecimal(exactly: exact) != nil)
        #expect(FixedPointDecimal(exactly: exact)?.description == "123.45")
        let eight = Decimal(string: "0.00000001")!
        #expect(FixedPointDecimal(exactly: eight) != nil)
        let zero = Decimal.zero
        #expect(FixedPointDecimal(exactly: zero) != nil)
    }

    // MARK: - Double Init Edge Cases (inspired by swift-foundation parseDouble)

    @Test("init(Double.leastNonzeroMagnitude) rounds to zero")
    func fromDoubleLeastNonzeroMagnitude() {
        let value = FixedPointDecimal(Double.leastNonzeroMagnitude)
        #expect(value == .zero)
    }

    @Test("init(Double.leastNormalMagnitude) rounds to zero")
    func fromDoubleLeastNormalMagnitude() {
        let value = FixedPointDecimal(Double.leastNormalMagnitude)
        #expect(value == .zero)
    }

    @Test("init?(exactly: Double.greatestFiniteMagnitude) returns nil (overflow)")
    func fromDoubleGreatestFiniteMagnitude() {
        let result = FixedPointDecimal(exactly: Double.greatestFiniteMagnitude)
        #expect(result == nil)
    }

    @Test("init?(exactly: Double.leastNonzeroMagnitude) returns nil (sub-tick)")
    func exactDoubleLeastNonzero() {
        let result = FixedPointDecimal(exactly: Double.leastNonzeroMagnitude)
        #expect(result == nil)
    }

    @Test("init?(exactly: Double.infinity) returns nil")
    func exactDoubleInfinity() {
        let result = FixedPointDecimal(exactly: Double.infinity)
        #expect(result == nil)
    }

    @Test("init?(exactly: Double.nan) returns nil")
    func exactDoubleNaN() {
        let result = FixedPointDecimal(exactly: Double.nan)
        #expect(result == nil)
    }

    @Test("init?(exactly: Double.signalingNaN) returns nil")
    func exactDoubleSignalingNaN() {
        let result = FixedPointDecimal(exactly: Double.signalingNaN)
        #expect(result == nil)
    }

    // MARK: - Concrete Int/Int64/Int32 init?(exactly: FixedPointDecimal)

    @Test("Int(exactly:) succeeds for exact integers")
    func intExactlySucceeds() {
        #expect(Int(exactly: FixedPointDecimal(42)) == 42)
        #expect(Int(exactly: FixedPointDecimal(0)) == 0)
        #expect(Int(exactly: FixedPointDecimal(-99)) == -99)
    }

    @Test("Int(exactly:) returns nil for fractional values")
    func intExactlyFractional() {
        #expect(Int(exactly: FixedPointDecimal(42.5)) == nil)
        #expect(Int(exactly: FixedPointDecimal(0.00000001)) == nil)
    }

    @Test("Int(exactly:) returns nil for NaN")
    func intExactlyNaN() {
        #expect(Int(exactly: FixedPointDecimal.nan) == nil)
    }

    @Test("Int64(exactly:) succeeds for exact integers")
    func int64ExactlySucceeds() {
        #expect(Int64(exactly: FixedPointDecimal(42)) == 42)
        #expect(Int64(exactly: FixedPointDecimal(0)) == 0)
        #expect(Int64(exactly: FixedPointDecimal(-99)) == -99)
    }

    @Test("Int64(exactly:) returns nil for fractional values")
    func int64ExactlyFractional() {
        #expect(Int64(exactly: FixedPointDecimal(42.5)) == nil)
        #expect(Int64(exactly: FixedPointDecimal(0.00000001)) == nil)
    }

    @Test("Int64(exactly:) returns nil for NaN")
    func int64ExactlyNaN() {
        #expect(Int64(exactly: FixedPointDecimal.nan) == nil)
    }

    @Test("Int32(exactly:) succeeds for in-range integers")
    func int32ExactlySucceeds() {
        #expect(Int32(exactly: FixedPointDecimal(1000)) == 1000)
        #expect(Int32(exactly: FixedPointDecimal(-1000)) == -1000)
    }

    @Test("Int32(exactly:) returns nil for fractional values")
    func int32ExactlyFractional() {
        #expect(Int32(exactly: FixedPointDecimal(1.5)) == nil)
    }

    @Test("Int32(exactly:) returns nil for out-of-range integers")
    func int32ExactlyOutOfRange() {
        #expect(Int32(exactly: FixedPointDecimal(Int64(Int32.max) + 1)) == nil)
    }

    @Test("Int32(exactly:) returns nil for NaN")
    func int32ExactlyNaN() {
        #expect(Int32(exactly: FixedPointDecimal.nan) == nil)
    }

    // MARK: - FixedWidthInteger generic init?(exactly: FixedPointDecimal)

    @Test("Int16(exactly:) returns nil for NaN")
    func int16ExactlyNaN() {
        #expect(Int16(exactly: FixedPointDecimal.nan) == nil)
    }

    @Test("UInt64(exactly:) succeeds for non-negative integers")
    func uint64ExactlySucceeds() {
        #expect(UInt64(exactly: FixedPointDecimal(42)) == 42)
        #expect(UInt64(exactly: FixedPointDecimal(0)) == 0)
    }

    @Test("UInt64(exactly:) returns nil for negative values")
    func uint64ExactlyNegative() {
        #expect(UInt64(exactly: FixedPointDecimal(-1)) == nil)
    }

    @Test("UInt64(exactly:) returns nil for fractional values")
    func uint64ExactlyFractional() {
        #expect(UInt64(exactly: FixedPointDecimal(1.5)) == nil)
    }

    @Test("UInt64(exactly:) returns nil for NaN")
    func uint64ExactlyNaN() {
        #expect(UInt64(exactly: FixedPointDecimal.nan) == nil)
    }

    @Test("UInt16(exactly:) returns nil for out-of-range values")
    func uint16ExactlyOutOfRange() {
        #expect(UInt16(exactly: FixedPointDecimal(Int64(UInt16.max) + 1)) == nil)
        #expect(UInt16(exactly: FixedPointDecimal(-1)) == nil)
    }

    @Test("FPD negation matches Decimal negation")
    func negationParityWithDecimal() {
        let values = ["0", "1", "-1", "123.45", "-99.99", "0.00000001"]
        for str in values {
            let fpd = FixedPointDecimal(str)!
            let dec = Decimal(string: str)!
            let fpdNeg = fpd == .zero ? fpd : -fpd
            let decNeg = -dec
            #expect(Decimal(fpdNeg) == decNeg,
                    "Negation parity failed for '\(str)': FPD=\(Decimal(fpdNeg)), Decimal=\(decNeg)")
        }
    }
}

// MARK: - Float Literal Precision Tests

@Suite("Float Literal Precision")
struct FloatLiteralPrecisionTests {

    @Test("Float literal basic usage")
    func floatLiteralBasic() {
        let a: FixedPointDecimal = 0.05
        #expect(a == FixedPointDecimal(0.05))

        let b: FixedPointDecimal = 99.95
        #expect(b == FixedPointDecimal(99.95))

        let c: FixedPointDecimal = -0.001
        #expect(c == FixedPointDecimal(-0.001))
    }

    @Test("Classic binary float problem values roundtrip exactly")
    func classicFloatProblemValues() {
        // These values cannot be represented exactly in binary floating point,
        // but they roundtrip exactly through Double → FixedPointDecimal because
        // round(value × 10^8) produces the correct integer.
        let problemValues: [(Double, String)] = [
            (0.1, "0.1"), (0.2, "0.2"), (0.3, "0.3"),
            (0.6, "0.6"), (0.7, "0.7"), (0.8, "0.8"), (0.9, "0.9"),
            (1.1, "1.1"), (1.2, "1.2"), (1.3, "1.3"),
            (2.3, "2.3"), (3.3, "3.3"),
            (0.15, "0.15"), (0.35, "0.35"),
        ]
        for (value, expected) in problemValues {
            let fpd = FixedPointDecimal(value)
            #expect(
                fpd.description == expected,
                "FixedPointDecimal(\(value)) should be \(expected), got \(fpd.description)"
            )
            // Roundtrip: FPD → Double → FPD must be identical
            #expect(FixedPointDecimal(Double(fpd)) == fpd)
        }
    }

    @Test("All single-digit fractions roundtrip exactly (d=1..6)")
    func allSingleDigitFractions() {
        for d in 1...6 {
            let divisor = pow(10.0, Double(d))
            for n in 0..<Int(divisor) {
                let value = Double(n) / divisor
                let fpd = FixedPointDecimal(value)
                let back = Double(fpd)
                #expect(
                    FixedPointDecimal(back) == fpd,
                    "Roundtrip failed for \(n)/10^\(d) = \(value)"
                )
            }
        }
    }

    @Test("Sampled single-digit fractions roundtrip exactly (d=7..8)")
    func sampledSingleDigitFractions() {
        // For d=7 (10M values) sample every 100th; for d=8 (100M values) sample every 1000th.
        // All 110M values (d=7: 10M, d=8: 100M) were verified exhaustively with zero failures
        // but are sampled here to keep test runtime reasonable.
        let configs: [(digits: Int, stride: Int)] = [(7, 100), (8, 1000)]
        for (d, step) in configs {
            let divisor = pow(10.0, Double(d))
            let count = Int(divisor)
            var n = 0
            while n < count {
                let value = Double(n) / divisor
                let fpd = FixedPointDecimal(value)
                let back = Double(fpd)
                #expect(
                    FixedPointDecimal(back) == fpd,
                    "Roundtrip failed for \(n)/10^\(d) = \(value)"
                )
                n += step
            }
        }
    }

    @Test("Systematic fractions with integer parts roundtrip exactly")
    func systematicFractionsWithIntegerParts() {
        let integerParts = [0, 1, 10, 100, 1000, 99999]
        for intPart in integerParts {
            for fracDigits in 1...8 {
                let divisor = pow(10.0, Double(fracDigits))
                // Test representative fractional parts
                for fracNum in [1, 5, 7, 13, 25, 33, 50, 99, 127, 999] {
                    guard Double(fracNum) < divisor else { continue }
                    let value = Double(intPart) + Double(fracNum) / divisor
                    let fpd = FixedPointDecimal(value)
                    #expect(
                        FixedPointDecimal(Double(fpd)) == fpd,
                        "Roundtrip failed for \(intPart) + \(fracNum)/10^\(fracDigits)"
                    )
                }
            }
        }
    }

    @Test("Negative values roundtrip exactly")
    func negativeValues() {
        let values: [Double] = [-0.1, -0.05, -1.5, -99.95, -0.00000001, -12345.67890123]
        for value in values {
            let fpd = FixedPointDecimal(value)
            #expect(
                FixedPointDecimal(Double(fpd)) == fpd,
                "Negative roundtrip failed for \(value)"
            )
        }
    }

    @Test("Float literal in expressions")
    func floatLiteralInExpressions() {
        let price: FixedPointDecimal = 100
        let tick: FixedPointDecimal = 0.05
        #expect(price + tick == 100.05 as FixedPointDecimal)
        #expect(price - tick == 99.95 as FixedPointDecimal)
        #expect(price * 0.01 == 1) // 1% of 100
    }
}
