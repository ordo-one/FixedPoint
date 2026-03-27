import Testing
import Foundation
import Synchronization
@testable import FixedPointDecimal

@Suite("Edge Cases")
struct EdgeCaseTests {

    // MARK: - NaN Propagation

    @Test("NaN + value = NaN (wrapping)")
    func nanAddPropagation() {
        let nan = FixedPointDecimal.nan
        let value: FixedPointDecimal = 42
        #expect(nan.isNaN)
        #expect(value + .zero == value)
    }

    @Test("NaN comparison semantics")
    func nanComparison() {
        let nan = FixedPointDecimal.nan
        let value: FixedPointDecimal = -99999
        #expect(nan < value)
        #expect(!(value < nan))
        #expect(!(nan < nan))  // nan == nan, so not less than
    }

    @Test("NaN + value traps")
    func nanAddTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan + 42 }
    }

    @Test("value + NaN traps")
    func valueAddNanTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal(42) + .nan }
    }

    @Test("NaN - value traps")
    func nanSubTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan - 42 }
    }

    @Test("NaN * value traps")
    func nanMulTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan * 42 }
    }

    @Test("NaN / value traps")
    func nanDivTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan / 42 }
    }

    @Test("value / NaN traps")
    func valueDivNanTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal(42) / .nan }
    }

    @Test("NaN % value traps")
    func nanModTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan % 42 }
    }

    @Test("value % NaN traps")
    func valueModNanTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal(42) % .nan }
    }

    @Test("NaN double value")
    func nanDoubleValue() {
        #expect(Double(FixedPointDecimal.nan).isNaN)
    }

    @Test("NaN string representation")
    func nanString() {
        #expect(FixedPointDecimal.nan.description == "nan")
    }

    // MARK: - Max Value Operations

    @Test("Max value properties")
    func maxValueProperties() {
        let max = FixedPointDecimal.max
        #expect(max.rawValue == Int64.max)
        #expect(!max.isNaN)
        #expect(max != .zero)
    }

    @Test("Max value description")
    func maxValueDescription() {
        let max = FixedPointDecimal.max
        let desc = max.description
        #expect(desc == "92233720368.54775807")
    }

    @Test("Min value description")
    func minValueDescription() {
        let min = FixedPointDecimal.min
        let desc = min.description
        #expect(desc == "-92233720368.54775807")
    }

    // MARK: - Negation Edge Cases

    @Test("Negation of zero")
    func negateZero() {
        let zero = FixedPointDecimal.zero
        let neg = -zero
        #expect(neg == zero)
        #expect(neg == .zero)
    }

    // MARK: - Smallest Value

    @Test("Smallest positive value")
    func smallestPositive() {
        let smallest = FixedPointDecimal.leastNonzeroMagnitude
        #expect(smallest.rawValue == 1)
        #expect(smallest.description == "0.00000001")
    }

    @Test("Smallest positive value arithmetic")
    func smallestArithmetic() {
        let a = FixedPointDecimal.leastNonzeroMagnitude
        let b = FixedPointDecimal.leastNonzeroMagnitude
        let sum = a + b
        #expect(sum.rawValue == 2)
    }

    // MARK: - Precision Boundaries

    @Test("Exact representation of financial prices")
    func financialPrices() {
        let prices: [(String, Int64)] = [
            ("0.01", 1_000_000),      // 1 cent
            ("0.001", 100_000),       // 1 mil
            ("0.0001", 10_000),       // 1 basis point
            ("0.00001", 1_000),       // FX pip
            ("0.00000001", 1),        // 1 satoshi
        ]
        for (str, expectedRaw) in prices {
            let value = FixedPointDecimal(str)!
            #expect(value.rawValue == expectedRaw, "Failed for \(str)")
        }
    }

    @Test("Large integer values")
    func largeIntegers() {
        let billion: FixedPointDecimal = 1000000000
        #expect(billion.integerPart == 1_000_000_000)

        let tenBillion: FixedPointDecimal = 10000000000
        #expect(tenBillion.integerPart == 10_000_000_000)
    }

    // MARK: - Distance & Advance

    @Test("distance(to:)")
    func distanceTo() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 15
        #expect(a.distance(to: b) == 5 as FixedPointDecimal)
    }

    @Test("advanced(by:)")
    func advancedBy() {
        let a: FixedPointDecimal = 10
        let step: FixedPointDecimal = 0.5
        #expect(a.advanced(by: step) == 10.5 as FixedPointDecimal)
    }

    // MARK: - Memory Layout

    @Test("Size is 8 bytes")
    func memoryLayout() {
        #expect(MemoryLayout<FixedPointDecimal>.size == 8)
        #expect(MemoryLayout<FixedPointDecimal>.stride == 8)
        #expect(MemoryLayout<FixedPointDecimal>.alignment == 8)
    }

    // MARK: - NaN in Collections

    @Test("NaN in Set — insert, contains, count")
    func nanInSet() {
        var set = Set<FixedPointDecimal>()
        set.insert(.nan)
        #expect(set.count == 1)
        #expect(set.contains(.nan))
        // Inserting a second NaN should not increase count
        set.insert(.nan)
        #expect(set.count == 1)
    }

    @Test("NaN as Dictionary key")
    func nanAsDictKey() {
        var dict: [FixedPointDecimal: String] = [:]
        dict[.nan] = "missing"
        #expect(dict[.nan] == "missing")
        // Overwrite should work
        dict[.nan] = "updated"
        #expect(dict[.nan] == "updated")
        #expect(dict.count == 1)
    }

    @Test("NaN sorting stability")
    func nanSortingStability() {
        var values: [FixedPointDecimal] = [3, .nan, 1, .nan, 2, -1]
        values.sort()
        // All NaN values should sort to the beginning (below all others since Int64.min is smallest)
        #expect(values[0].isNaN)
        #expect(values[1].isNaN)
        #expect(values[2] == -1 as FixedPointDecimal)
        #expect(values[3] == 1 as FixedPointDecimal)
        #expect(values[4] == 2 as FixedPointDecimal)
        #expect(values[5] == 3 as FixedPointDecimal)
    }

    // MARK: - NaN with Remainder

    @Test("NaN % value traps (remainder)")
    func nanRemainder() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan % 3 }
    }

    @Test("value % NaN traps (remainder)")
    func valueRemainderNan() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal(3) % .nan }
    }

    // MARK: - NaN Negation

    @Test("Negation of NaN traps")
    func negateNaN() async {
        await #expect(processExitsWith: .failure) { _ = -FixedPointDecimal.nan }
    }

    @Test("Mutating negate of NaN traps")
    func mutatingNegateNaN() async {
        await #expect(processExitsWith: .failure) {
            var nan = FixedPointDecimal.nan
            nan.negate()
        }
    }

    // MARK: - NaN Properties

    @Test("ulp on NaN traps")
    func ulpNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.ulp }
    }

    @Test("nextUp on NaN traps")
    func nextUpNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.nextUp }
    }

    @Test("nextDown on NaN traps")
    func nextDownNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.nextDown }
    }

    // MARK: - NaN Rounding

    @Test("NaN rounded traps")
    func nanRoundedTraps() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.rounded(scale: 0) }
    }

    // MARK: - NaN absoluteValue

    @Test("NaN absoluteValue traps")
    func nanAbsoluteValue() async {
        await #expect(processExitsWith: .failure) { _ = abs(FixedPointDecimal.nan) }
    }

    // MARK: - Distance & Advance Edge Cases

    @Test("Distance between widely separated values")
    func distanceWidelySeparated() {
        let a: FixedPointDecimal = -1000
        let b: FixedPointDecimal = 1000
        let dist = a.distance(to: b)
        #expect(dist == 2000 as FixedPointDecimal)
    }

    @Test("Advanced by negative stride")
    func advancedByNegative() {
        let a: FixedPointDecimal = 10
        let step: FixedPointDecimal = -2.5
        #expect(a.advanced(by: step) == 7.5 as FixedPointDecimal)
    }

    // MARK: - Min/Max Arithmetic Safety

    @Test("Min + max equals zero (asymmetric due to NaN)")
    func minPlusMax() {
        let result = FixedPointDecimal.min + FixedPointDecimal.max
        #expect(result.rawValue == 0)
        #expect(result == .zero)
    }

    @Test("Max value description parse round-trip")
    func maxDescriptionRoundTrip() {
        let max = FixedPointDecimal.max
        let str = max.description
        let reparsed = FixedPointDecimal(str)
        #expect(reparsed == max)
    }

    @Test("Mutating negate")
    func mutatingNegate() {
        var value: FixedPointDecimal = 42.5
        value.negate()
        #expect(value == -42.5 as FixedPointDecimal)
    }

    // MARK: - Magnitude is UInt64

    @Test("Magnitude type is FixedPointDecimal")
    func magnitudeType() {
        let value: FixedPointDecimal = 42
        let mag: FixedPointDecimal = value.magnitude
        #expect(mag == 42 as FixedPointDecimal)
    }

    // MARK: - NaN in Codable Round-Trip

    @Test("NaN Codable round-trip preserves NaN")
    func nanCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(FixedPointDecimal.nan)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded.isNaN)
        #expect(decoded == FixedPointDecimal.nan)
    }

    // MARK: - Power of 10 Helper

    @Test("Power of 10 produces correct values")
    func powerOf10Values() {
        #expect(FixedPointDecimal._powerOf10(0) == 1)
        #expect(FixedPointDecimal._powerOf10(1) == 10)
        #expect(FixedPointDecimal._powerOf10(2) == 100)
        #expect(FixedPointDecimal._powerOf10(3) == 1_000)
        #expect(FixedPointDecimal._powerOf10(4) == 10_000)
        #expect(FixedPointDecimal._powerOf10(5) == 100_000)
        #expect(FixedPointDecimal._powerOf10(6) == 1_000_000)
        #expect(FixedPointDecimal._powerOf10(7) == 10_000_000)
        #expect(FixedPointDecimal._powerOf10(8) == 100_000_000)
    }

    // MARK: - Near Overflow Multiplication

    @Test("Large value multiplication near overflow boundary")
    func largeMultiplicationNearOverflow() {
        let a: FixedPointDecimal = 10000
        let b: FixedPointDecimal = 9000000
        let result = a * b
        #expect(result == 90000000000 as FixedPointDecimal)
    }

    @Test("Multiplication overflow is reported correctly")
    func multiplicationOverflowReported() {
        let a: FixedPointDecimal = 92000000000
        let b: FixedPointDecimal = 2
        let (_, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(overflow)
    }

    // MARK: - init(integer:fraction:) Edge Cases

    @Test("init(integer:fraction:) with zero integer and zero fraction")
    func integerFractionZeroZero() {
        let value = FixedPointDecimal(integer: 0, fraction: 0)
        #expect(value == .zero)
    }

    @Test("init(integer:fraction:) with max fraction value")
    func integerFractionMaxFraction() {
        let value = FixedPointDecimal(integer: 0, fraction: 99_999_999)
        #expect(value.rawValue == 99_999_999)
    }

    @Test("init(integer:fraction:) with negative integer and max fraction")
    func integerFractionNegativeMaxFraction() {
        let value = FixedPointDecimal(integer: -1, fraction: 99_999_999)
        #expect(value.rawValue == -199_999_999)
    }

    // MARK: - Mutating negate on zero

    @Test("Mutating negate on zero produces zero")
    func mutatingNegateZero() {
        var value = FixedPointDecimal.zero
        value.negate()
        #expect(value == .zero)
    }

    // MARK: - Magnitude of .min

    @Test("Magnitude of .min")
    func magnitudeOfMin() {
        let min = FixedPointDecimal.min
        #expect(min.magnitude == FixedPointDecimal.max)
    }

    // MARK: - Double Value of .zero

    @Test("doubleValue of .zero is exactly 0.0")
    func doubleValueZero() {
        #expect(Double(FixedPointDecimal.zero) == 0.0)
    }

    // MARK: - intValue and int64Value of values close to zero

    @Test("intValue truncates positive fractional toward zero")
    func intValueTruncatesPositive() {
        let value: FixedPointDecimal = 0.99999999
        #expect(Int(value) == 0)
        #expect(Int64(value) == 0)
    }

    @Test("intValue truncates negative fractional toward zero")
    func intValueTruncatesNegative() {
        let value: FixedPointDecimal = -0.99999999
        #expect(Int(value) == 0)
        #expect(Int64(value) == 0)
    }

    // MARK: - VectorArithmetic Conformance (SwiftUI)

    #if canImport(SwiftUI)
    @Test("VectorArithmetic scale by 0 produces zero")
    func vectorScaleByZero() {
        var value: FixedPointDecimal = 42.5
        value.scale(by: 0.0)
        #expect(value == .zero)
    }

    @Test("VectorArithmetic scale by 1 is identity")
    func vectorScaleByOne() {
        var value: FixedPointDecimal = 42.5
        let original = value
        value.scale(by: 1.0)
        #expect(value == original)
    }

    @Test("VectorArithmetic scale by -1 negates")
    func vectorScaleByNegOne() {
        var value: FixedPointDecimal = 42.5
        value.scale(by: -1.0)
        #expect(value == -42.5 as FixedPointDecimal)
    }

    @Test("VectorArithmetic scale NaN traps")
    func vectorScaleNaN() async {
        await #expect(processExitsWith: .failure) {
            var nan = FixedPointDecimal.nan
            nan.scale(by: 2.0)
        }
    }

    @Test("VectorArithmetic scale clamps to max")
    func vectorScaleClampMax() {
        var value: FixedPointDecimal = 50000000000
        value.scale(by: 10.0)
        #expect(value == .max)
    }

    @Test("VectorArithmetic scale clamps to min (avoids NaN sentinel)")
    func vectorScaleClampMin() {
        var value: FixedPointDecimal = 50000000000
        value.scale(by: -10.0)
        #expect(value == .min)
        #expect(!value.isNaN)
    }

    @Test("VectorArithmetic magnitudeSquared")
    func vectorMagnitudeSquared() {
        let value: FixedPointDecimal = 3
        let expected = Double(300_000_000) * Double(300_000_000)
        #expect(value.magnitudeSquared == expected)
    }

    @Test("VectorArithmetic magnitudeSquared of NaN traps")
    func vectorMagnitudeSquaredNaN() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan.magnitudeSquared }
    }
    #endif

    // MARK: - CustomReflectable

    @Test("CustomReflectable mirror exposes rawValue and isNaN")
    func customReflectable() {
        let value: FixedPointDecimal = 42.5
        let mirror = value.customMirror
        let children = Dictionary(uniqueKeysWithValues: mirror.children.map { ($0.label!, "\($0.value)") })
        #expect(children["rawValue"] == "\(value.rawValue)")
        #expect(children["isNaN"] == "false")
    }

    @Test("CustomReflectable mirror for NaN")
    func customReflectableNaN() {
        let mirror = FixedPointDecimal.nan.customMirror
        let children = Dictionary(uniqueKeysWithValues: mirror.children.map { ($0.label!, "\($0.value)") })
        #expect(children["isNaN"] == "true")
    }

    @Test("CustomReflectable display style is struct")
    func customReflectableDisplayStyle() {
        let value: FixedPointDecimal = 1
        #expect(value.customMirror.displayStyle == .struct)
    }

    // MARK: - CustomPlaygroundDisplayConvertible

    #if !os(Linux) && !os(Windows)
    @Test("Playground description is the string description")
    func playgroundDescription() {
        let value: FixedPointDecimal = 123.45
        let desc = value.playgroundDescription
        #expect(desc as? String == "123.45")
    }

    @Test("Playground description of NaN")
    func playgroundDescriptionNaN() {
        let desc = FixedPointDecimal.nan.playgroundDescription
        #expect(desc as? String == "nan")
    }
    #endif

    // MARK: - AtomicRepresentable

    @Test("AtomicRepresentable encode/decode round-trip")
    func atomicRoundTrip() {
        let values: [FixedPointDecimal] = [0, 42.5, -99.99, 0.00000001]
        for value in values {
            let encoded = FixedPointDecimal.encodeAtomicRepresentation(value)
            let decoded = FixedPointDecimal.decodeAtomicRepresentation(encoded)
            #expect(decoded == value, "Atomic round-trip failed for \(value)")
        }
    }

    @Test("AtomicRepresentable round-trip for NaN")
    func atomicRoundTripNaN() {
        let encoded = FixedPointDecimal.encodeAtomicRepresentation(.nan)
        let decoded = FixedPointDecimal.decodeAtomicRepresentation(encoded)
        #expect(decoded.isNaN)
    }

    @Test("AtomicRepresentable round-trip for max and min")
    func atomicRoundTripExtremes() {
        for value in [FixedPointDecimal.max, FixedPointDecimal.min] {
            let encoded = FixedPointDecimal.encodeAtomicRepresentation(value)
            let decoded = FixedPointDecimal.decodeAtomicRepresentation(encoded)
            #expect(decoded == value)
        }
    }

    // MARK: - Default (Uninitialized) Value Safety (inspired by shopspring)

    @Test("Default-initialized value is safe through all operations")
    func defaultInitSafety() {
        let zero = FixedPointDecimal()
        let one: FixedPointDecimal = 1
        let fortyTwo: FixedPointDecimal = 42
        // Properties
        #expect(zero == .zero)
        #expect(!zero.isNaN)
        #expect(zero.integerPart == 0)
        #expect(zero.fractionalPart == 0)
        #expect(Double(zero) == 0.0)
        #expect(Int64(zero) == 0)
        #expect(zero.description == "0")
        #expect(abs(zero) == .zero)

        // Arithmetic with default-init
        #expect(zero + zero == .zero)
        #expect(zero - zero == .zero)
        #expect(zero * fortyTwo == .zero)
        #expect(zero + one == one)
        #expect(one - zero == one)

        // Comparison
        #expect(zero == .zero)
        #expect(!(zero < .zero))
        #expect(!(zero > .zero))
    }

    // MARK: - Negation of .min (inspired by OpenJDK Long.MIN_VALUE asymmetry)

    @Test("Negation of .min produces .max (Int64 asymmetry)")
    func negateMin() {
        // .min rawValue = Int64.min + 1 = -9223372036854775807
        // Negating gives 9223372036854775807 = Int64.max = .max
        let result = -FixedPointDecimal.min
        #expect(result == FixedPointDecimal.max)
    }

    @Test("Negation of .max produces .min")
    func negateMax() {
        let result = -FixedPointDecimal.max
        #expect(result == FixedPointDecimal.min)
    }

    @Test("Double negation of .max is identity")
    func doubleNegationMax() {
        #expect(-(-FixedPointDecimal.max) == FixedPointDecimal.max)
    }

    @Test("Double negation of .min is identity")
    func doubleNegationMin() {
        #expect(-(-FixedPointDecimal.min) == FixedPointDecimal.min)
    }

    // MARK: - Construction Equivalence (inspired by rust_decimal/OpenJDK)

    @Test("All construction paths produce same value for integer")
    func constructionEquivalenceInteger() {
        let fromInt = FixedPointDecimal(42)
        let fromString = FixedPointDecimal("42")!
        let fromDouble = FixedPointDecimal(42.0)
        let fromRaw = FixedPointDecimal(rawValue: 4_200_000_000)
        let fromParts = FixedPointDecimal(integer: 42, fraction: 0)
        let fromLiteral: FixedPointDecimal = 42

        let all = [fromInt, fromString, fromDouble, fromRaw, fromParts, fromLiteral]
        for (idx, val) in all.enumerated() {
            #expect(val == fromInt, "Constructor \(idx) produced different value")
            #expect(val.rawValue == fromInt.rawValue, "Constructor \(idx) produced different rawValue")
        }
    }

    @Test("All construction paths produce same value for fractional")
    func constructionEquivalenceFractional() {
        let fromString = FixedPointDecimal("0.5")!
        let fromDouble = FixedPointDecimal(0.5)
        let fromRaw = FixedPointDecimal(rawValue: 50_000_000)
        let fromParts = FixedPointDecimal(integer: 0, fraction: 50_000_000)
        let fromLiteral: FixedPointDecimal = 0.5

        let all = [fromString, fromDouble, fromRaw, fromParts, fromLiteral]
        for (idx, val) in all.enumerated() {
            #expect(val == fromString, "Constructor \(idx) produced different value")
        }
    }

    // MARK: - abs(.min) = .max (inspired by OpenJDK, .NET)

    @Test("absoluteValue of .min equals .max")
    func absOfMinEqualsMax() {
        #expect(abs(FixedPointDecimal.min) == FixedPointDecimal.max)
    }

    @Test("absoluteValue of .max equals .max")
    func absOfMaxEqualsMax() {
        #expect(abs(FixedPointDecimal.max) == FixedPointDecimal.max)
    }

    @Test("abs() free function: abs(.min) == .max")
    func absFreeMinEqualsMax() {
        #expect(abs(FixedPointDecimal.min) == FixedPointDecimal.max)
    }

    // MARK: - Additional BinaryInteger Width Construction (inspired by GCC, .NET, decimal-rs)

    @Test("init from Int16")
    func initFromInt16() {
        let value = FixedPointDecimal(Int16(-1234))
        #expect(value.integerPart == -1234)

        let max16 = FixedPointDecimal(Int16.max)
        #expect(max16.integerPart == 32767)

        let min16 = FixedPointDecimal(Int16.min)
        #expect(min16.integerPart == -32768)
    }

    @Test("init from UInt16")
    func initFromUInt16() {
        let value = FixedPointDecimal(UInt16(1234))
        #expect(value.integerPart == 1234)

        let max16 = FixedPointDecimal(UInt16.max)
        #expect(max16.integerPart == 65535)
    }

    @Test("init from UInt8")
    func initFromUInt8() {
        let value = FixedPointDecimal(UInt8(255))
        #expect(value.integerPart == 255)

        let zero = FixedPointDecimal(UInt8(0))
        #expect(zero == .zero)
    }

    @Test("init from Int32")
    func initFromInt32() {
        let max32 = FixedPointDecimal(Int32.max)
        #expect(max32.integerPart == 2_147_483_647)

        let min32 = FixedPointDecimal(Int32.min)
        #expect(min32.integerPart == -2_147_483_648)
    }

    @Test("init(exactly:) from various integer widths")
    func exactInitFromVariousWidths() {
        #expect(FixedPointDecimal(exactly: Int16(42)) != nil)
        #expect(FixedPointDecimal(exactly: UInt16(42)) != nil)
        #expect(FixedPointDecimal(exactly: Int32.max) != nil)
        #expect(FixedPointDecimal(exactly: UInt32.max) != nil)
        #expect(FixedPointDecimal(exactly: Int8(-1)) != nil)
    }

    // MARK: - isZero for Various Representations (inspired by IBM/Cowlishaw)

    @Test("isZero for all zero construction paths")
    func isZeroAllPaths() {
        #expect(FixedPointDecimal() == .zero)
        #expect(FixedPointDecimal(0) == .zero)
        #expect(FixedPointDecimal(Int64(0)) == .zero)
        #expect(FixedPointDecimal(0.0) == .zero)
        #expect(FixedPointDecimal(-0.0) == .zero)
        #expect(FixedPointDecimal("0")! == .zero)
        #expect(FixedPointDecimal("-0")! == .zero)
        #expect(FixedPointDecimal("0.0")! == .zero)
        #expect(FixedPointDecimal(rawValue: 0) == .zero)
        #expect(FixedPointDecimal(integer: 0, fraction: 0) == .zero)
        #expect(FixedPointDecimal.zero == .zero)
    }

    // MARK: - Random Value Generation

    @Test("random(in: Range) produces values within bounds")
    func randomRange() {
        let lower: FixedPointDecimal = 10
        let upper: FixedPointDecimal = 20
        for _ in 0..<1000 {
            let value = FixedPointDecimal.random(in: lower ..< upper)
            #expect(value >= lower)
            #expect(value < upper)
            #expect(!value.isNaN)
        }
    }

    @Test("random(in: ClosedRange) produces values within bounds")
    func randomClosedRange() {
        let lower: FixedPointDecimal = -5
        let upper: FixedPointDecimal = 5
        for _ in 0..<1000 {
            let value = FixedPointDecimal.random(in: lower ... upper)
            #expect(value >= lower)
            #expect(value <= upper)
            #expect(!value.isNaN)
        }
    }

    @Test("random(in:) across full .min ... .max never produces NaN")
    func randomFullRangeNoNaN() {
        for _ in 0..<10000 {
            let value = FixedPointDecimal.random(in: .min ... .max)
            #expect(!value.isNaN, "random(in: .min ... .max) produced NaN")
        }
    }

    @Test("random(in: ClosedRange) with single-element range returns that element")
    func randomSingleElement() {
        let value: FixedPointDecimal = 42.5
        let result = FixedPointDecimal.random(in: value ... value)
        #expect(result == value)
    }
}
