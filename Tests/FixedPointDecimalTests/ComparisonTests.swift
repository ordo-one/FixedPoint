import Testing
import FixedPointDecimal

@Suite("Comparison and Ordering")
struct ComparisonTests {

    @Test("Equality")
    func equality() {
        let a: FixedPointDecimal = 123.45
        let b: FixedPointDecimal = 123.45
        #expect(a == b)
    }

    @Test("Inequality")
    func inequality() {
        let a: FixedPointDecimal = 123.45
        let b: FixedPointDecimal = 123.46
        #expect(a != b)
    }

    @Test("Less than")
    func lessThan() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 20
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Less than or equal")
    func lessThanOrEqual() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 10
        #expect(a <= b)
    }

    @Test("Greater than")
    func greaterThan() {
        let a: FixedPointDecimal = 20
        let b: FixedPointDecimal = 10
        #expect(a > b)
    }

    @Test("Negative comparison")
    func negativeComparison() {
        let a: FixedPointDecimal = -5
        let b: FixedPointDecimal = 5
        #expect(a < b)
    }

    @Test("Zero comparison")
    func zeroComparison() {
        let a: FixedPointDecimal = 0
        let b = FixedPointDecimal.zero
        #expect(a == b)
        #expect(!(a < b))
        #expect(!(a > b))
    }

    @Test("Sorting")
    func sorting() {
        var values: [FixedPointDecimal] = [5, 1, 3, 2, 4]
        values.sort()
        let expected: [FixedPointDecimal] = [1, 2, 3, 4, 5]
        #expect(values == expected)
    }

    @Test("Sorting with negatives")
    func sortingWithNegatives() {
        var values: [FixedPointDecimal] = [3, -1, 0, -3, 1]
        values.sort()
        let expected: [FixedPointDecimal] = [-3, -1, 0, 1, 3]
        #expect(values == expected)
    }

    @Test("Hashable — equal values have equal hashes")
    func hashableConsistency() {
        let a: FixedPointDecimal = 123.45
        let b: FixedPointDecimal = 123.45
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable — use in Set")
    func hashableInSet() {
        let values: Set<FixedPointDecimal> = [1, 2, 3, 2, 1]
        #expect(values.count == 3)
    }

    @Test("Hashable — use as Dictionary key")
    func hashableAsDictKey() {
        let price: FixedPointDecimal = 99.95
        var dict: [FixedPointDecimal: String] = [:]
        dict[price] = "test"
        #expect(dict[price] == "test")
    }

    // MARK: - NaN Comparison Semantics

    @Test("NaN is not equal to zero")
    func nanNotEqualToZero() {
        #expect(FixedPointDecimal.nan != .zero)
    }

    @Test("NaN sorts below everything")
    func nanSortsBelowAll() {
        let nan = FixedPointDecimal.nan
        let neg: FixedPointDecimal = -99999
        #expect(nan < neg)
        #expect(!(neg < nan))
    }

    // MARK: - Additional Comparison Edge Cases

    @Test("NaN == NaN is true (sentinel semantics)")
    func nanEqualsNan() {
        #expect(FixedPointDecimal.nan == FixedPointDecimal.nan)
    }

    @Test("min < max")
    func minLessThanMax() {
        #expect(FixedPointDecimal.min < FixedPointDecimal.max)
    }

    @Test("Hashable — NaN values have equal hashes")
    func nanHashConsistency() {
        let a = FixedPointDecimal.nan
        let b = FixedPointDecimal.nan
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Hash Consistency Across Construction Paths (inspired by rust_decimal/shopspring)

    @Test("Values constructed via different paths hash equally")
    func hashConsistencyAcrossConstructors() {
        // Int init vs String init vs Double init
        let fromInt = FixedPointDecimal(42)
        let fromString = FixedPointDecimal("42")!
        let fromDouble = FixedPointDecimal(42.0)
        let fromRaw = FixedPointDecimal(rawValue: 42 * 100_000_000)

        #expect(fromInt == fromString)
        #expect(fromInt == fromDouble)
        #expect(fromInt == fromRaw)

        #expect(fromInt.hashValue == fromString.hashValue)
        #expect(fromInt.hashValue == fromDouble.hashValue)
        #expect(fromInt.hashValue == fromRaw.hashValue)
    }

    @Test("Fractional values from different constructors hash equally")
    func hashConsistencyFractional() {
        let fromString = FixedPointDecimal("123.45")!
        let fromLiteral: FixedPointDecimal = 123.45
        let fromDouble = FixedPointDecimal(123.45)
        let fromParts = FixedPointDecimal(integer: 123, fraction: 45_000_000)

        #expect(fromString == fromLiteral)
        #expect(fromString == fromDouble)
        #expect(fromString == fromParts)

        #expect(fromString.hashValue == fromLiteral.hashValue)
        #expect(fromString.hashValue == fromDouble.hashValue)
        #expect(fromString.hashValue == fromParts.hashValue)
    }

    // MARK: - Comparison Boundary Values (inspired by OpenJDK CompareToTests)

    @Test("Comparison at Int64 boundaries")
    func comparisonAtBoundaries() {
        let max = FixedPointDecimal.max
        let min = FixedPointDecimal.min
        let justBelowMax = FixedPointDecimal(rawValue: Int64.max - 1)
        let justAboveMin = FixedPointDecimal(rawValue: Int64.min + 2)

        #expect(justBelowMax < max)
        #expect(justAboveMin > min)
        #expect(max > min)
        #expect(!(max < min))
        #expect(max != min)
    }

    @Test("Comparison: max == max, min == min")
    func comparisonSelfEquality() {
        #expect(FixedPointDecimal.max == FixedPointDecimal.max)
        #expect(FixedPointDecimal.min == FixedPointDecimal.min)
    }
}
