import Testing
@testable import FixedPointDecimal

@Suite("Basic Initialization and Properties")
struct BasicTests {

    @Test("Zero initialization")
    func zeroInit() {
        let zero = FixedPointDecimal()
        #expect(zero.rawValue == 0)
        #expect(zero == .zero)
        #expect(!zero.isNaN)
        #expect(zero == .zero)
    }

    @Test("Raw value initialization")
    func rawValueInit() {
        let value = FixedPointDecimal(rawValue: 123_456_789_00)
        #expect(value.rawValue == 123_456_789_00)
    }

    @Test("Integer initialization")
    func integerInit() {
        let value = FixedPointDecimal(42)
        #expect(value.rawValue == 42 * 100_000_000)
        #expect(value.integerPart == 42)
        #expect(value.fractionalPart == 0)
    }

    @Test("Negative integer initialization")
    func negativeIntegerInit() {
        let value = FixedPointDecimal(-100)
        #expect(value.rawValue == -100 * 100_000_000)
        #expect(value.integerPart == -100)
    }

    @Test("Exact integer initialization")
    func exactIntegerInit() {
        let value = FixedPointDecimal(exactly: 42)
        #expect(value != nil)
        #expect(value?.integerPart == 42)

        // Overflow
        let overflow = FixedPointDecimal(exactly: Int64.max)
        #expect(overflow == nil)
    }

    @Test("Integer and fraction initialization")
    func integerFractionInit() {
        let value = FixedPointDecimal(integer: 123, fraction: 45_000_000)
        #expect(value.integerPart == 123)
        #expect(value.fractionalPart == 45_000_000)

        let neg = FixedPointDecimal(integer: -1, fraction: 25_000_000)
        #expect(neg.integerPart == -1)
        #expect(neg.fractionalPart == -25_000_000)
    }

    @Test("Double initialization")
    func doubleInit() {
        let value = FixedPointDecimal(123.45)
        #expect(value.integerPart == 123)
        #expect(value.fractionalPart == 45_000_000)
    }

    @Test("Exact double initialization")
    func exactDoubleInit() {
        let value = FixedPointDecimal(exactly: 123.45)
        #expect(value != nil)

        let nan = FixedPointDecimal(exactly: Double.nan)
        #expect(nan == nil)

        let inf = FixedPointDecimal(exactly: Double.infinity)
        #expect(inf == nil)
    }

    @Test("NaN")
    func nan() {
        let nan = FixedPointDecimal.nan
        #expect(nan.isNaN)
        #expect(nan.rawValue == Int64.min)
        #expect(nan != .zero)
    }

    @Test("Special values")
    func specialValues() {
        #expect(FixedPointDecimal.max.rawValue == Int64.max)
        #expect(FixedPointDecimal.min.rawValue == Int64.min + 1)
        #expect(FixedPointDecimal.leastNonzeroMagnitude.rawValue == 1)
        #expect(FixedPointDecimal.greatestFiniteMagnitude.rawValue == Int64.max)
    }

    @Test("Integer part and fractional part")
    func parts() {
        let value: FixedPointDecimal = 123.456
        #expect(value.integerPart == 123)
        #expect(value.fractionalPart == 45_600_000)

        let neg: FixedPointDecimal = -5.75
        #expect(neg.integerPart == -5)
        #expect(neg.fractionalPart == -75_000_000)
    }

    @Test("Double value conversion")
    func doubleValue() {
        let value: FixedPointDecimal = 123.45
        #expect(Double(value) == 123.45)

        let nan = FixedPointDecimal.nan
        #expect(Double(nan).isNaN)
    }

    @Test("Int32 conversion truncates fractional part")
    func int32Conversion() {
        let value: FixedPointDecimal = 99.99
        #expect(Int32(value) == 99)

        let neg: FixedPointDecimal = -5.5
        #expect(Int32(neg) == -5)
    }

    @Test("Scale factor is correct")
    func scaleFactor() {
        #expect(FixedPointDecimal.scaleFactor == 100_000_000)
        #expect(FixedPointDecimal.fractionalDigitCount == 8)
    }

    @Test("init(integer:fraction:) max integer with fraction")
    func integerFractionMaxIntegerWithFraction() {
        // Max representable integer part is 92233720368
        // 92233720368 * 100_000_000 = 9223372036800000000
        // Adding fraction 54775807 gives 9223372036854775807 = Int64.max
        let value = FixedPointDecimal(integer: 92_233_720_368, fraction: 54_775_807)
        #expect(value == FixedPointDecimal.max)
    }

    @Test("init(integer:fraction:) negative max integer with fraction")
    func integerFractionNegativeMaxWithFraction() {
        // -92233720368 * 100_000_000 = -9223372036800000000
        // Subtracting 54775807 gives -9223372036854775807 = Int64.min + 1 = .min
        let value = FixedPointDecimal(integer: -92_233_720_368, fraction: 54_775_807)
        #expect(value == FixedPointDecimal.min)
    }

    @Test("init from BinaryInteger UInt32")
    func initFromUInt32() {
        let value = FixedPointDecimal(UInt32(42))
        #expect(value.integerPart == 42)
    }

    @Test("init from BinaryInteger Int8")
    func initFromInt8() {
        let value = FixedPointDecimal(Int8(-5))
        #expect(value.integerPart == -5)
    }
}
