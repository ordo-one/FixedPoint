import Testing
@testable import FixedPointDecimal

@Suite("Arithmetic Operations")
struct ArithmeticTests {

    // MARK: - Addition

    @Test("Addition of positive values")
    func addPositive() {
        let a: FixedPointDecimal = 10.25
        let b: FixedPointDecimal = 5.75
        #expect(a + b == 16 as FixedPointDecimal)
    }

    @Test("Addition with negative")
    func addNegative() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = -3.5
        #expect(a + b == 6.5 as FixedPointDecimal)
    }

    @Test("Addition assignment")
    func addAssign() {
        var a: FixedPointDecimal = 10
        a += 5
        #expect(a == 15 as FixedPointDecimal)
    }

    // MARK: - Subtraction

    @Test("Subtraction")
    func subtract() {
        let a: FixedPointDecimal = 10.5
        let b: FixedPointDecimal = 3.25
        #expect(a - b == 7.25 as FixedPointDecimal)
    }

    @Test("Subtraction resulting in negative")
    func subtractToNegative() {
        let a: FixedPointDecimal = 3
        let b: FixedPointDecimal = 5
        #expect(a - b == -2 as FixedPointDecimal)
    }

    @Test("Subtraction assignment")
    func subtractAssign() {
        var a: FixedPointDecimal = 10
        a -= 3
        #expect(a == 7 as FixedPointDecimal)
    }

    // MARK: - Multiplication

    @Test("Multiplication of simple values")
    func multiplySimple() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 5
        #expect(a * b == 50 as FixedPointDecimal)
    }

    @Test("Multiplication with decimals")
    func multiplyDecimals() {
        let a: FixedPointDecimal = 2.5
        let b: FixedPointDecimal = 4
        #expect(a * b == 10 as FixedPointDecimal)
    }

    @Test("Multiplication of fractional values")
    func multiplyFractional() {
        let a: FixedPointDecimal = 0.1
        let b: FixedPointDecimal = 0.1
        #expect(a * b == 0.01 as FixedPointDecimal)
    }

    @Test("Multiplication with negative")
    func multiplyNegative() {
        let a: FixedPointDecimal = 5
        let b: FixedPointDecimal = -3
        #expect(a * b == -15 as FixedPointDecimal)
    }

    @Test("Multiplication assignment")
    func multiplyAssign() {
        var a: FixedPointDecimal = 10
        a *= 3
        #expect(a == 30 as FixedPointDecimal)
    }

    // MARK: - Division

    @Test("Division of simple values")
    func divideSimple() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 2
        #expect(a / b == 5 as FixedPointDecimal)
    }

    @Test("Division with remainder")
    func divideWithRemainder() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 3
        let result = a / b
        // 10/3 = 3.33333333 (truncated to 8 decimals)
        #expect(result == 3.33333333 as FixedPointDecimal)
    }

    @Test("Division of fractional values")
    func divideFractional() {
        let a: FixedPointDecimal = 1
        let b: FixedPointDecimal = 4
        #expect(a / b == 0.25 as FixedPointDecimal)
    }

    @Test("Division assignment")
    func divideAssign() {
        var a: FixedPointDecimal = 10
        a /= 4
        #expect(a == 2.5 as FixedPointDecimal)
    }

    // MARK: - Mixed-Type Arithmetic

    @Test("Multiplication by Int64")
    func multiplyByInt() {
        let a: FixedPointDecimal = 10.5
        let result = a * 3
        #expect(result == 31.5 as FixedPointDecimal)
    }

    @Test("Integer literal times FixedPointDecimal")
    func intTimesFixed() {
        let a: FixedPointDecimal = 7.25
        let result: FixedPointDecimal = 4 * a
        #expect(result == 29 as FixedPointDecimal)
    }

    @Test("Division by Int64")
    func divideByInt() {
        let a: FixedPointDecimal = 30
        let result = a / 4
        #expect(result == 7.5 as FixedPointDecimal)
    }

    // MARK: - Negation

    @Test("Negation")
    func negation() {
        let a: FixedPointDecimal = 42.5
        let neg = -a
        #expect(neg == -42.5 as FixedPointDecimal)
    }

    @Test("Double negation")
    func doubleNegation() {
        let a: FixedPointDecimal = 42.5
        #expect(-(-a) == a)
    }

    // MARK: - Remainder

    @Test("Remainder")
    func remainder() {
        let a: FixedPointDecimal = 10.3
        let b: FixedPointDecimal = 3
        let result = a % b
        #expect(result == 1.3 as FixedPointDecimal)
    }

    // MARK: - Zero

    @Test("Multiply by zero")
    func multiplyByZero() {
        let a: FixedPointDecimal = 42
        #expect(a * .zero == .zero)
    }

    @Test("Add zero")
    func addZero() {
        let a: FixedPointDecimal = 42
        #expect(a + .zero == a)
    }

    @Test("Subtract from self gives zero")
    func subtractSelf() {
        let a: FixedPointDecimal = 42.123
        #expect(a - a == .zero)
    }

    // MARK: - Precision Edge Cases

    @Test("Multiplication precision: 0.33333333 * 3")
    func multiplyPrecisionRepeating() {
        let a: FixedPointDecimal = 0.33333333
        let b: FixedPointDecimal = 3
        let result = a * b
        // Int128 multiplication: 33333333 * 300000000 = 9999999900000000
        // Divided by scaleFactor: 9999999900000000 / 100000000 = 99999999
        // So the result is 0.99999999, NOT 1
        #expect(result == 0.99999999 as FixedPointDecimal)
    }

    @Test("Division where result is exactly representable")
    func divisionExactlyRepresentable() {
        let a: FixedPointDecimal = 1
        let b: FixedPointDecimal = 8
        #expect(a / b == 0.125 as FixedPointDecimal)
    }

    @Test("Division where result is truncated")
    func divisionTruncated() {
        let a: FixedPointDecimal = 1
        let b: FixedPointDecimal = 7
        let result = a / b
        // 1/7 = 0.14285714285..., truncated to 0.14285714
        #expect(result == 0.14285714 as FixedPointDecimal)
    }

    @Test("Division where result is negative and truncated")
    func divisionNegativeTruncated() {
        let a: FixedPointDecimal = -1
        let b: FixedPointDecimal = 7
        let result = a / b
        #expect(result == -0.14285714 as FixedPointDecimal)
    }

    @Test("Chained operations: (a + b) * c / d")
    func chainedOperations() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 20
        let c: FixedPointDecimal = 3
        let d: FixedPointDecimal = 6
        let result = (a + b) * c / d
        // (10 + 20) * 3 / 6 = 30 * 3 / 6 = 90 / 6 = 15
        #expect(result == 15 as FixedPointDecimal)
    }

    @Test("Chained operations with fractional intermediates")
    func chainedOperationsFractional() {
        let a: FixedPointDecimal = 1.5
        let b: FixedPointDecimal = 2.5
        let c: FixedPointDecimal = 4
        let result = (a + b) * c
        // (1.5 + 2.5) * 4 = 4 * 4 = 16
        #expect(result == 16 as FixedPointDecimal)
    }

    // MARK: - Mixed-Type Arithmetic Edge Cases

    @Test("Multiply by Int64 zero")
    func multiplyByInt64Zero() {
        let a: FixedPointDecimal = 42.5
        let result = a * 0
        #expect(result == .zero)
    }

    @Test("Multiply by Int64 -1")
    func multiplyByInt64NegOne() {
        let a: FixedPointDecimal = 42.5
        let result = a * (-1)
        #expect(result == -42.5 as FixedPointDecimal)
    }

    @Test("Multiply by Int64 1")
    func multiplyByInt64One() {
        let a: FixedPointDecimal = 42.5
        let result = a * 1
        #expect(result == a)
    }

    @Test("Divide by Int64 1")
    func divideByInt64One() {
        let a: FixedPointDecimal = 42.5
        let result = a / 1
        #expect(result == a)
    }

    @Test("Divide by Int64 -1")
    func divideByInt64NegOne() {
        let a: FixedPointDecimal = 42.5
        let result = a / (-1)
        #expect(result == -42.5 as FixedPointDecimal)
    }

    @Test("Divide by Int64 truncation")
    func divideByInt64Truncation() {
        let a: FixedPointDecimal = 10
        let result = a / 3
        // 10 / 3 = 3.33333333... truncated in raw storage
        #expect(result == 3.33333333 as FixedPointDecimal)
    }

    @Test("Divide .min by Int64(-1) produces .max (NaN sentinel not reachable)")
    func divMinByInt64NegOne() {
        // .min rawValue = Int64.min + 1, dividing by -1 gives Int64.max = .max
        let result = FixedPointDecimal.min / (-1)
        #expect(result == FixedPointDecimal.max)
    }

    @Test("Divide .max by Int64(-1) produces .min")
    func divMaxByInt64NegOne() {
        let result = FixedPointDecimal.max / (-1)
        #expect(result == FixedPointDecimal.min)
    }

    @Test("NaN / Int64 traps (guards against Int64.min / -1 overflow)")
    func nanDivByInt64NegOne() async {
        await #expect(processExitsWith: .failure) {
            _ = FixedPointDecimal.nan / (-1)
        }
    }

    // MARK: - Remainder Edge Cases

    @Test("Remainder with negative lhs")
    func remainderNegativeLhs() {
        let a: FixedPointDecimal = -10.3
        let b: FixedPointDecimal = 3
        let result = a % b
        // -10.3 % 3 = -1.3 (Swift truncated remainder semantics)
        #expect(result == -1.3 as FixedPointDecimal)
    }

    @Test("Remainder with negative rhs")
    func remainderNegativeRhs() {
        let a: FixedPointDecimal = 10.3
        let b: FixedPointDecimal = -3
        let result = a % b
        // Remainder sign follows lhs in Swift
        #expect(result == 1.3 as FixedPointDecimal)
    }

    @Test("Remainder with both negative")
    func remainderBothNegative() {
        let a: FixedPointDecimal = -10.3
        let b: FixedPointDecimal = -3
        let result = a % b
        #expect(result == -1.3 as FixedPointDecimal)
    }

    @Test("Remainder where value is exact multiple")
    func remainderExactMultiple() {
        let a: FixedPointDecimal = 9
        let b: FixedPointDecimal = 3
        #expect(a % b == .zero)
    }

    @Test("Remainder assignment")
    func remainderAssignment() {
        var a: FixedPointDecimal = 10.3
        a %= 3
        #expect(a == 1.3 as FixedPointDecimal)
    }

    // MARK: - NaN Trapping in Mixed-Type Arithmetic

    @Test("NaN * Int64 traps")
    func nanTimesInt64() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan * 5 }
    }

    @Test("Int64 * NaN traps")
    func int64TimesNaN() async {
        await #expect(processExitsWith: .failure) { _ = 5 * FixedPointDecimal.nan }
    }

    @Test("NaN / Int64 traps")
    func nanDividedByInt64() async {
        await #expect(processExitsWith: .failure) { _ = FixedPointDecimal.nan / 5 }
    }

    // MARK: - Iterator Aggregation (Sum and Product)

    @Test("Sum of array via reduce")
    func sumArray() {
        let values: [FixedPointDecimal] = [1.5, 2.5, 3, 4]
        let sum = values.reduce(.zero, +)
        #expect(sum == 11 as FixedPointDecimal)
    }

    @Test("Product of array via reduce")
    func productArray() {
        let values: [FixedPointDecimal] = [1.5, 2, 3, 4]
        let one: FixedPointDecimal = 1
        let product = values.reduce(one, *)
        #expect(product == 36 as FixedPointDecimal)
    }

    // MARK: - Mixed-Type Commutativity

    @Test("Multiplication with integer literal is commutative")
    func mulIntCommutative() {
        let d: FixedPointDecimal = 123.456
        let i: FixedPointDecimal = 789
        #expect(d * i == i * d)
    }

    // MARK: - Division Truncation Direction

    @Test("Division truncates toward zero (not floor)")
    func divTruncatesTowardZero() {
        // -10 / 3 should be -3.33333333 (toward zero), not -3.33333334 (floor)
        let a: FixedPointDecimal = -10
        let b: FixedPointDecimal = 3
        let result = a / b
        #expect(result == -3.33333333 as FixedPointDecimal)

        // Verify symmetry: a/b == -((-a)/b)
        #expect(result == -((-a) / b))
    }

    // MARK: - Multiplicative Identity and Zero

    @Test("Multiply by FixedPointDecimal one is identity")
    func mulByFPOne() {
        let values: [FixedPointDecimal] = [0, 42.5, -99.99, .max, .min]
        let one: FixedPointDecimal = 1
        for v in values {
            #expect(v * one == v, "Failed for \(v)")
            #expect(one * v == v, "Failed for \(v)")
        }
    }

    @Test("Multiply by FixedPointDecimal zero gives zero")
    func mulByFPZero() {
        let values: [FixedPointDecimal] = [42.5, -99.99, .max, .min]
        let zero: FixedPointDecimal = 0
        for v in values {
            #expect(v * zero == .zero, "Failed for \(v)")
        }
    }

    // MARK: - Sign Combination Coverage (inspired by swift-foundation)

    @Test("Multiplication sign combinations: pos*pos, pos*neg, neg*pos, neg*neg")
    func mulSignCombinations() {
        let pos: FixedPointDecimal = 3
        let neg: FixedPointDecimal = -3

        #expect(pos * pos == 9 as FixedPointDecimal)      // pos * pos = pos
        #expect(pos * neg == -9 as FixedPointDecimal)     // pos * neg = neg
        #expect(neg * pos == -9 as FixedPointDecimal)     // neg * pos = neg
        #expect(neg * neg == 9 as FixedPointDecimal)      // neg * neg = pos
    }

    @Test("Division sign combinations: pos/pos, pos/neg, neg/pos, neg/neg")
    func divSignCombinations() {
        let pos: FixedPointDecimal = 9
        let neg: FixedPointDecimal = -9
        let three: FixedPointDecimal = 3
        let negThree: FixedPointDecimal = -3

        #expect(pos / three == 3 as FixedPointDecimal)       // pos / pos = pos
        #expect(pos / negThree == -3 as FixedPointDecimal)   // pos / neg = neg
        #expect(neg / three == -3 as FixedPointDecimal)      // neg / pos = neg
        #expect(neg / negThree == 3 as FixedPointDecimal)    // neg / neg = pos
    }

    @Test("Multiplication by zero with all sign variants")
    func mulZeroSignVariants() {
        let one: FixedPointDecimal = 1
        let zero: FixedPointDecimal = 0
        let negOne: FixedPointDecimal = -1
        #expect(one * zero == .zero)
        #expect(zero * negOne == .zero)
        #expect(negOne * zero == .zero)
        #expect(zero * zero == .zero)
    }

    // MARK: - Compound Expression Precision (inspired by swift-foundation SR-13015)

    @Test("Compound expression: (a*b) + (c*(a/d)) preserves precision")
    func compoundExpressionPrecision() {
        let a: FixedPointDecimal = 10
        let b: FixedPointDecimal = 3
        let c: FixedPointDecimal = 5
        let d: FixedPointDecimal = 2
        // (10*3) + (5*(10/2)) = 30 + 5*5 = 30 + 25 = 55
        let result = (a * b) + (c * (a / d))
        #expect(result == 55 as FixedPointDecimal)
    }

    @Test("Compound expression with fractional intermediates")
    func compoundExpressionFractional() {
        let a: FixedPointDecimal = 7
        let b: FixedPointDecimal = 11
        let c: FixedPointDecimal = 3
        let d: FixedPointDecimal = 13
        // (7*11) + (3*(7/13)) = 77 + 3 * 0.53846154 (banker's rounded)
        // 7/13 = 0.538461538... remainder 8 > 6.5, rounds up to 0.53846154
        // 3 * 0.53846154 = 1.61538462
        let result = (a * b) + (c * (a / d))
        #expect(result == 78.61538462 as FixedPointDecimal)
    }

    // MARK: - Division Chain (inspired by swift-foundation repeatingDivision)

    @Test("Division chain: divide then multiply back (banker's rounding)")
    func divisionChainRounding() {
        let a: FixedPointDecimal = 16
        let b: FixedPointDecimal = 9
        let divided = a / b  // 1.777777777... remainder 7 > 4.5, rounds up
        #expect(divided == 1.77777778 as FixedPointDecimal)
        // Multiplying back: 1.77777778 * 9
        let recovered = divided * b
        #expect(recovered == 16.00000002 as FixedPointDecimal)
        #expect(recovered != a) // precision lost
    }

    @Test("Division producing repeating decimal then re-dividing")
    func repeatingDivisionChain() {
        let a: FixedPointDecimal = 16
        let b: FixedPointDecimal = 9
        let ratio = a / b // 1.77777777

        let c: FixedPointDecimal = 1010
        let result = c / ratio
        // 1010 / 1.77777777 — uses Int128 intermediate
        // Exact: 568.125000...
        // With truncated ratio: 1010 / 1.77777777 = 568.12500140...
        // Truncated to 568.12500014
        #expect(result.integerPart == 568)
    }

    // MARK: - Exhaustive Small Integer Arithmetic (inspired by swift-foundation maths)

    @Test("Exhaustive small integer multiplication")
    func exhaustiveSmallMul() {
        for lhs in -5...10 {
            for rhs in -5...10 {
                let a = FixedPointDecimal(Int64(lhs))
                let b = FixedPointDecimal(Int64(rhs))
                let expected = FixedPointDecimal(Int64(lhs * rhs))
                #expect(a * b == expected, "\(lhs) * \(rhs)")
            }
        }
    }

    @Test("Exhaustive small integer addition")
    func exhaustiveSmallAdd() {
        for lhs in -5...10 {
            for rhs in -5...10 {
                let a = FixedPointDecimal(Int64(lhs))
                let b = FixedPointDecimal(Int64(rhs))
                let expected = FixedPointDecimal(Int64(lhs + rhs))
                #expect(a + b == expected, "\(lhs) + \(rhs)")
            }
        }
    }

    @Test("Exhaustive small integer subtraction")
    func exhaustiveSmallSub() {
        for lhs in -5...10 {
            for rhs in -5...10 {
                let a = FixedPointDecimal(Int64(lhs))
                let b = FixedPointDecimal(Int64(rhs))
                let expected = FixedPointDecimal(Int64(lhs - rhs))
                #expect(a - b == expected, "\(lhs) - \(rhs)")
            }
        }
    }

    @Test("Exhaustive small integer division")
    func exhaustiveSmallDiv() {
        let divisors = Array(-5...(-1)) + Array(1...10)
        for lhs in -5...10 {
            for rhs in divisors {
                let a = FixedPointDecimal(Int64(lhs))
                let b = FixedPointDecimal(Int64(rhs))
                let (quot, rem) = lhs.quotientAndRemainder(dividingBy: rhs)
                if rem == 0 {
                    let expected = FixedPointDecimal(Int64(quot))
                    #expect(a / b == expected, "\(lhs) / \(rhs)")
                } else {
                    let result = a / b
                    #expect(result.integerPart == Int64(quot), "\(lhs) / \(rhs) integer part")
                }
            }
        }
    }

    // MARK: - Carry Propagation (inspired by IBM/Cowlishaw & OpenJDK)

    @Test("Addition carry propagation at precision limit")
    func addCarryPropagation() {
        let a = FixedPointDecimal("99999999.99999999")!
        let b: FixedPointDecimal = 0.00000001
        let (result, overflow) = a.addingReportingOverflow(b)
        // 99999999.99999999 + 0.00000001 = 100000000.00000000
        // rawValue = 10000000000000000, fits in Int64
        #expect(!overflow)
        #expect(result == 100000000 as FixedPointDecimal)
    }

    @Test("Subtraction borrow propagation across all digits")
    func subtractBorrowPropagation() {
        let a: FixedPointDecimal = 100000000
        let b: FixedPointDecimal = 0.00000001
        let result = a - b
        #expect(result == FixedPointDecimal("99999999.99999999")!)
    }

    @Test("Near-carry: 0.99999998 + 0.00000001 stays below 1")
    func nearCarryStaysBelow() {
        let a: FixedPointDecimal = 0.99999998
        let b: FixedPointDecimal = 0.00000001
        let result = a + b
        #expect(result == 0.99999999 as FixedPointDecimal)
        #expect(result.integerPart == 0)
    }

    @Test("Carry from fraction to integer: 0.99999999 + 0.00000001 = 1")
    func carryFractionToInteger() {
        let a: FixedPointDecimal = 0.99999999
        let b: FixedPointDecimal = 0.00000001
        let result = a + b
        #expect(result == 1 as FixedPointDecimal)
        #expect(result.integerPart == 1)
        #expect(result.fractionalPart == 0)
    }

    // MARK: - Magnitude Disparity (inspired by IBM/Cowlishaw)

    @Test("Adding tiny value to huge value — tiny operand survives")
    func magnitudeDisparityAdd() {
        let huge: FixedPointDecimal = 92000000000
        let tiny: FixedPointDecimal = 0.00000001
        let result = huge + tiny
        #expect(result == FixedPointDecimal(rawValue: 9200000000000000001))
        #expect(result != huge) // tiny operand must not be lost
    }

    @Test("Addition is commutative for disparate magnitudes")
    func magnitudeDisparityCommutative() {
        let huge: FixedPointDecimal = 92000000000
        let tiny: FixedPointDecimal = 0.00000001
        #expect(huge + tiny == tiny + huge)
    }

    @Test("Subtracting tiny from huge — tiny operand not lost")
    func magnitudeDisparitySub() {
        let huge: FixedPointDecimal = 92000000000
        let tiny: FixedPointDecimal = 0.00000001
        let result = huge - tiny
        #expect(result == FixedPointDecimal(rawValue: 9199999999999999999))
        #expect(result != huge)
    }

    // MARK: - Subtraction Sign Flip (inspired by rust_decimal/shopspring)

    @Test("Subtraction that's internally addition: neg - neg")
    func subtractNegNeg() {
        let a: FixedPointDecimal = -5
        let b: FixedPointDecimal = -3
        #expect(a - b == -2 as FixedPointDecimal)
    }

    @Test("Subtraction causing sign change from positive to negative")
    func subtractSignFlip() {
        let a: FixedPointDecimal = 3
        let b: FixedPointDecimal = 10
        let result = a - b
        #expect(result == -7 as FixedPointDecimal)
        #expect(result.integerPart == -7)
    }

    @Test("Subtraction causing sign change from negative to positive")
    func subtractSignFlipReverse() {
        let a: FixedPointDecimal = -3
        let b: FixedPointDecimal = -10
        let result = a - b
        #expect(result == 7 as FixedPointDecimal)
    }

    // MARK: - Division Rounding Direction Verification (inspired by OpenJDK)

    @Test("Division truncates toward zero — verified via raw value")
    func divisionTruncationDirectionRaw() {
        // 1/3 positive: 0.33333333... truncated to 0.33333333
        let posResult = FixedPointDecimal(1) / FixedPointDecimal(3)
        #expect(posResult.rawValue == 33_333_333)

        // -1/3: should be -0.33333333 (toward zero, not -0.33333334)
        let negResult = FixedPointDecimal(-1) / FixedPointDecimal(3)
        #expect(negResult.rawValue == -33_333_333)

        // Verify symmetry: |pos| == |neg|
        #expect(posResult.rawValue == -negResult.rawValue)
    }

    @Test("Division 1/7 truncation verified against known exact digits")
    func divisionOneSeventh() {
        // 1/7 = 0.142857142857... truncated to 0.14285714
        let result = FixedPointDecimal(1) / FixedPointDecimal(7)
        #expect(result.rawValue == 14_285_714)
    }

    @Test("Division 1/6 banker's rounding verified")
    func divisionOneSixth() {
        // 1/6 = 0.166666666... remainder 6 > half of 6 (3), rounds up
        let result = FixedPointDecimal(1) / FixedPointDecimal(6)
        #expect(result.rawValue == 16_666_667)
    }

    // MARK: - Multiplication Int128 Boundary (inspired by OpenJDK/rust_decimal)

    @Test("Multiplication where Int128 intermediate is near max but result fits")
    func mulInt128NearMaxResultFits() {
        // max * 1 = max: Int128 intermediate = Int64.max * scaleFactor
        // which is huge but result = Int64.max (fits)
        let one: FixedPointDecimal = 1
        let result = FixedPointDecimal.max * one
        #expect(result == .max)
    }

    @Test("Multiplication .min * 1 = .min")
    func mulMinTimesOne() {
        let one: FixedPointDecimal = 1
        let result = FixedPointDecimal.min * one
        #expect(result == .min)
    }

    @Test("Multiplication near-max values: sqrt-ish * sqrt-ish fits")
    func mulNearSqrtMax() {
        // 303700 * 303700 = 92,233,690,000 which is just under max integer part
        let a: FixedPointDecimal = 303700
        let b: FixedPointDecimal = 303700
        let (result, overflow) = a.multipliedReportingOverflow(by: b)
        #expect(!overflow)
        #expect(result.integerPart == 92_233_690_000)
    }

    // MARK: - Catastrophic Cancellation (inspired by IBM/Cowlishaw, .NET)

    @Test("Subtraction of nearly-equal large values produces exact small result")
    func catastrophicCancellation() {
        let a = FixedPointDecimal("10000000.12345679")!
        let b = FixedPointDecimal("10000000.12345678")!
        let result = a - b
        #expect(result == 0.00000001 as FixedPointDecimal)
        #expect(result == FixedPointDecimal.leastNonzeroMagnitude)
    }

    @Test("Catastrophic cancellation with large negative values")
    func catastrophicCancellationNegative() {
        let a = FixedPointDecimal("-99999999.99999998")!
        let b = FixedPointDecimal("-99999999.99999999")!
        let result = a - b
        #expect(result == 0.00000001 as FixedPointDecimal)
    }

    @Test("Near-cancellation preserving small difference")
    func nearCancellation() {
        let a = FixedPointDecimal("92233720368.54775807")!  // .max
        let b = FixedPointDecimal("92233720368.54775806")!
        let result = a - b
        #expect(result == 0.00000001 as FixedPointDecimal)
    }

    // MARK: - Multiplication Truncation Behavior (inspired by IBM rounding.decTest)

    @Test("Multiplication truncates (does not round) the 9th fractional digit")
    func mulTruncatesNinthDigit() {
        // 0.33333333 * 3 = 0.99999999 (Int128: 33333333 * 300000000 = 9999999900000000 / 10^8 = 99999999)
        // If rounding, would be 1.0. With truncation, stays at 0.99999999.
        let a: FixedPointDecimal = 0.33333333
        let three: FixedPointDecimal = 3
        let result = a * three
        #expect(result == 0.99999999 as FixedPointDecimal)
        #expect(result != 1 as FixedPointDecimal)
    }

    @Test("Multiplication truncation when 9th digit is exactly 5")
    func mulTruncationAtExactlyFive() {
        // 0.11111111 * 9 = 0.99999999
        // Int128: 11111111 * 900000000 = 9999999900000000 / 10^8 = 99999999
        let a: FixedPointDecimal = 0.11111111
        let nine: FixedPointDecimal = 9
        let result = a * nine
        #expect(result == 0.99999999 as FixedPointDecimal)

        // 0.5 * 0.00000001 = raw: 50000000 * 1 = 50000000 / 10^8 = 0
        // The 9th digit would be 5, but truncation gives 0
        let half: FixedPointDecimal = 0.5
        let smallest: FixedPointDecimal = 0.00000001
        let tiny = half * smallest
        #expect(tiny == .zero)
    }

    @Test("Multiplication truncation: product with non-zero discarded digits")
    func mulTruncationDiscardedDigits() {
        // 1.23456789 * 1 (if it existed) — but we can only store 8 digits
        // Instead: 0.12345679 * 10 = 1.2345679 (exact, fits)
        // 0.99999999 * 0.99999999 = raw: 99999999 * 99999999 = 9999999800000001 / 10^8 = 99999998
        let a: FixedPointDecimal = 0.99999999
        let b: FixedPointDecimal = 0.99999999
        let result = a * b
        #expect(result.rawValue == 99_999_998) // 0.99999998, not 0.99999999
    }

    // MARK: - Self-Division (inspired by rust_decimal, shopspring)

    @Test("Self-division: x / x = 1 for various values")
    func selfDivision() {
        let values: [FixedPointDecimal] = [
            1, -1, 0.5, -0.5,
            42.12345678, -99.99,
            0.00000001, -0.00000001,
            .max, .min,
            92233720368, 0.00000002,
        ]
        let one: FixedPointDecimal = 1
        for v in values {
            let result = v / v
            #expect(result == one, "Self-division failed for \(v)")
        }
    }

    // MARK: - Remainder Edge Cases (inspired by .NET, Python, IBM)

    @Test("Remainder of max by 1 extracts fractional part")
    func remainderMaxBy1() {
        let one: FixedPointDecimal = 1
        let result = FixedPointDecimal.max % one
        // 92233720368.54775807 % 1 = 0.54775807
        #expect(result == 0.54775807 as FixedPointDecimal)
    }

    @Test("Remainder of min by 1 extracts negative fractional part")
    func remainderMinBy1() {
        let one: FixedPointDecimal = 1
        let result = FixedPointDecimal.min % one
        #expect(result == -0.54775807 as FixedPointDecimal)
    }

    @Test("Remainder of max by max is zero")
    func remainderMaxByMax() {
        #expect(FixedPointDecimal.max % FixedPointDecimal.max == .zero)
    }

    @Test("Remainder of min by min is zero")
    func remainderMinByMin() {
        #expect(FixedPointDecimal.min % FixedPointDecimal.min == .zero)
    }

    @Test("Remainder: large by small")
    func remainderLargeBySmall() {
        let a: FixedPointDecimal = 1000000
        let b: FixedPointDecimal = 0.3
        let result = a % b
        // 1000000 / 0.3 = 3333333.333... -> quotient 3333333, remainder = 1000000 - 999999.9 = 0.1
        #expect(result == 0.1 as FixedPointDecimal)
    }

    @Test("Remainder: small by large is the small value itself")
    func remainderSmallByLarge() {
        let a: FixedPointDecimal = 0.5
        let b: FixedPointDecimal = 1000
        let result = a % b
        #expect(result == 0.5 as FixedPointDecimal)
    }

    @Test("Remainder by 1 extracts fractional part for various values")
    func remainderBy1() {
        let one: FixedPointDecimal = 1
        #expect(FixedPointDecimal(42.12345678) % one == 0.12345678 as FixedPointDecimal)
        #expect(FixedPointDecimal(-42.12345678) % one == -0.12345678 as FixedPointDecimal)
        #expect(one % one == .zero)
        #expect(FixedPointDecimal(0.5) % one == 0.5 as FixedPointDecimal)
    }

    @Test("Zero remainder: 0 % x = 0 for various x")
    func remainderZeroByAnything() {
        let values: [FixedPointDecimal] = [1, -1, 42.5, .max, .min]
        for v in values {
            #expect(.zero % v == .zero, "0 % \(v) should be 0")
        }
    }

    // MARK: - Division by -1 at Boundaries (inspired by .NET, OpenJDK)

    @Test("Division: max / (-1) = min")
    func divMaxByNegOne() {
        let negOne: FixedPointDecimal = -1
        let result = FixedPointDecimal.max / negOne
        #expect(result == FixedPointDecimal.min)
    }

    @Test("Division: min / (-1) = max")
    func divMinByNegOne() {
        let negOne: FixedPointDecimal = -1
        let result = FixedPointDecimal.min / negOne
        #expect(result == FixedPointDecimal.max)
    }

    // MARK: - Division 0/x = 0 (inspired by IBM, shopspring)

    @Test("Division: 0 / x = 0 for various x")
    func divZeroByAnything() {
        let values: [FixedPointDecimal] = [1, -1, 42.5, .max, .min, 0.00000001]
        for v in values {
            #expect(.zero / v == .zero, "0 / \(v) should be 0")
        }
    }

    // MARK: - Multiplication Non-Associativity (inspired by IBM, cockroachdb/apd)

    @Test("Multiplication is not associative due to truncation")
    func mulNonAssociativity() {
        let a: FixedPointDecimal = 0.33333333
        let b: FixedPointDecimal = 0.33333333
        let c: FixedPointDecimal = 9

        // (a * b) * c vs a * (b * c)
        let leftAssoc = (a * b) * c  // 0.33333333 * 0.33333333 = 0.11111110... * 9
        let rightAssoc = a * (b * c) // 0.33333333 * 2.99999997 = ...

        // These differ due to intermediate truncation — the test documents
        // that this non-associativity exists and is expected
        let diff = leftAssoc.rawValue - rightAssoc.rawValue
        #expect(diff != 0, "Expected non-associativity but values were equal")
        // Diff is bounded by the number of truncated digits in intermediate results
        #expect(abs(diff) <= 10, "Non-associativity diff unexpectedly large: \(diff)")
    }

    // MARK: - Near-Overflow Decimal Round-Trip (inspired by .NET, OpenJDK RangeTests)

    @Test("(max - leastNonzero) + leastNonzero = max exactly")
    func nearOverflowDecimalRoundTrip() {
        let almostMax = FixedPointDecimal(rawValue: Int64.max - 1)
        let result = almostMax + FixedPointDecimal.leastNonzeroMagnitude
        #expect(result == FixedPointDecimal.max)
    }

    @Test("(min + leastNonzero) - leastNonzero = min exactly")
    func nearUnderflowDecimalRoundTrip() {
        let almostMin = FixedPointDecimal(rawValue: Int64.min + 2)
        let result = almostMin - FixedPointDecimal.leastNonzeroMagnitude
        #expect(result == FixedPointDecimal.min)
    }

    // MARK: - Self-Subtraction of Extremes (inspired by shopspring)

    @Test("max - max = 0")
    func selfSubMax() {
        #expect(FixedPointDecimal.max - FixedPointDecimal.max == .zero)
    }

    @Test("min - min = 0")
    func selfSubMin() {
        #expect(FixedPointDecimal.min - FixedPointDecimal.min == .zero)
    }

    // MARK: - Sequential Truncation Drift (inspired by ericlagergren #20, IBM)

    @Test("Repeated multiply/divide shows truncation drift")
    func sequentialTruncationDrift() {
        let one: FixedPointDecimal = 1
        let three: FixedPointDecimal = 3
        var value = one
        // Multiply by 3 then divide by 3 ten times
        for _ in 0..<10 {
            value = value * three
            value = value / three
        }
        // Due to truncation in division (1/3 = 0.33333333), value drifts from 1
        // After first round: 3 / 3 = 1 (exact). But with fractional:
        // Let's use a value that actually drifts
        var drifter = one
        for _ in 0..<10 {
            drifter = drifter / three
            drifter = drifter * three
        }
        // 1/3 = 0.33333333, * 3 = 0.99999999
        // 0.99999999 / 3 = 0.33333333, * 3 = 0.99999999
        // Drift stabilizes at 0.99999999 after first iteration
        #expect(drifter == FixedPointDecimal("0.99999999")!)
        #expect(drifter != one) // documents precision loss
    }

    // MARK: - Increment/Decrement by LeastNonzero (inspired by .NET, GCC)

    @Test("Increment by leastNonzero at various values")
    func incrementByLeastNonzero() {
        let least = FixedPointDecimal.leastNonzeroMagnitude
        let one: FixedPointDecimal = 1
        let negOne: FixedPointDecimal = -1
        #expect((.zero + least).rawValue == 1)
        #expect((one + least).rawValue == 100_000_001)
        #expect((negOne + least).rawValue == -99_999_999)
    }

    @Test("Decrement by leastNonzero at various values")
    func decrementByLeastNonzero() {
        let least = FixedPointDecimal.leastNonzeroMagnitude
        let one: FixedPointDecimal = 1
        let negOne: FixedPointDecimal = -1
        #expect((.zero - least).rawValue == -1)
        #expect((one - least).rawValue == 99_999_999)
        #expect((negOne - least).rawValue == -100_000_001)
    }
}
