import Testing
import FixedPointDecimal

@Suite("Rounding")
struct RoundingTests {

    // MARK: - Scale-Based Rounding

    @Test("Round to 0 decimal places (toNearestOrEven)")
    func roundToZero() {
        #expect(FixedPointDecimal(123.45).rounded() == 123 as FixedPointDecimal)
        #expect(FixedPointDecimal(123.55).rounded() == 124 as FixedPointDecimal)
        #expect(FixedPointDecimal(-123.45).rounded() == -123 as FixedPointDecimal)
    }

    @Test("Round to 2 decimal places")
    func roundToTwo() {
        #expect(FixedPointDecimal(123.456).rounded(scale: 2) == 123.46 as FixedPointDecimal)
        #expect(FixedPointDecimal(123.454).rounded(scale: 2) == 123.45 as FixedPointDecimal)
    }

    @Test("Banker's rounding (half to even)")
    func bankersRounding() {
        // 0.5 rounds to 0 (even)
        #expect(FixedPointDecimal(0.5).rounded() == 0 as FixedPointDecimal)
        // 1.5 rounds to 2 (even)
        #expect(FixedPointDecimal(1.5).rounded() == 2 as FixedPointDecimal)
        // 2.5 rounds to 2 (even)
        #expect(FixedPointDecimal(2.5).rounded() == 2 as FixedPointDecimal)
        // 3.5 rounds to 4 (even)
        #expect(FixedPointDecimal(3.5).rounded() == 4 as FixedPointDecimal)
    }

    @Test("Round down (toward zero)")
    func roundDown() {
        #expect(FixedPointDecimal(1.99).rounded(scale: 0, .towardZero) == 1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.99).rounded(scale: 0, .towardZero) == -1 as FixedPointDecimal)
    }

    @Test("Round up (away from zero)")
    func roundUp() {
        #expect(FixedPointDecimal(1.01).rounded(scale: 0, .awayFromZero) == 2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.01).rounded(scale: 0, .awayFromZero) == -2 as FixedPointDecimal)
    }

    @Test("Round floor (toward negative infinity)")
    func roundFloor() {
        #expect(FixedPointDecimal(1.99).rounded(scale: 0, .down) == 1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.01).rounded(scale: 0, .down) == -2 as FixedPointDecimal)
    }

    @Test("Round ceiling (toward positive infinity)")
    func roundCeiling() {
        #expect(FixedPointDecimal(1.01).rounded(scale: 0, .up) == 2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.99).rounded(scale: 0, .up) == -1 as FixedPointDecimal)
    }

    @Test("Round toNearestOrAwayFromZero (schoolbook rounding)")
    func roundToNearestOrAwayFromZero() {
        // Half rounds away from zero (unlike banker's which rounds to even)
        #expect(FixedPointDecimal(0.5).rounded(scale: 0, .toNearestOrAwayFromZero) == 1 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.5).rounded(scale: 0, .toNearestOrAwayFromZero) == 2 as FixedPointDecimal)
        #expect(FixedPointDecimal(2.5).rounded(scale: 0, .toNearestOrAwayFromZero) == 3 as FixedPointDecimal)
        #expect(FixedPointDecimal(3.5).rounded(scale: 0, .toNearestOrAwayFromZero) == 4 as FixedPointDecimal)
        // Negative half rounds away from zero (toward -infinity)
        #expect(FixedPointDecimal(-0.5).rounded(scale: 0, .toNearestOrAwayFromZero) == -1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.5).rounded(scale: 0, .toNearestOrAwayFromZero) == -2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-2.5).rounded(scale: 0, .toNearestOrAwayFromZero) == -3 as FixedPointDecimal)
        // Non-half values round normally
        #expect(FixedPointDecimal(1.4).rounded(scale: 0, .toNearestOrAwayFromZero) == 1 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.6).rounded(scale: 0, .toNearestOrAwayFromZero) == 2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.4).rounded(scale: 0, .toNearestOrAwayFromZero) == -1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.6).rounded(scale: 0, .toNearestOrAwayFromZero) == -2 as FixedPointDecimal)
        // Scale 2
        #expect(FixedPointDecimal(1.235).rounded(scale: 2, .toNearestOrAwayFromZero) == 1.24 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.245).rounded(scale: 2, .toNearestOrAwayFromZero) == 1.25 as FixedPointDecimal)
    }

    @Test("Round at full precision is identity")
    func roundFullPrecision() {
        let value: FixedPointDecimal = 123.45678901
        #expect(value.rounded(scale: 8) == value)
    }

    @Test("Round already-rounded value is identity")
    func roundAlreadyRounded() {
        let value: FixedPointDecimal = 123
        #expect(value.rounded() == value)
    }

    @Test("Mutating round")
    func mutatingRound() {
        var value: FixedPointDecimal = 123.456
        value.round(scale: 2)
        #expect(value == 123.46 as FixedPointDecimal)
    }

    // MARK: - Absolute Value

    @Test("Absolute value of positive")
    func absPositive() {
        let value: FixedPointDecimal = 42.5
        #expect(abs(value) == value)
    }

    @Test("Absolute value of negative")
    func absNegative() {
        let value: FixedPointDecimal = -42.5
        #expect(abs(value) == 42.5 as FixedPointDecimal)
    }

    @Test("Absolute value of zero")
    func absZero() {
        #expect(abs(FixedPointDecimal.zero) == .zero)
    }

    @Test("Absolute value of NaN traps")
    func absNaN() async {
        await #expect(processExitsWith: .failure) { _ = abs(FixedPointDecimal.nan) }
    }

    // MARK: - Rounding at Every Scale

    @Test("Round at scale 1")
    func roundScale1() {
        #expect(FixedPointDecimal(1.25).rounded(scale: 1) == 1.2 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.35).rounded(scale: 1) == 1.4 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.15).rounded(scale: 1) == 1.2 as FixedPointDecimal)
    }

    @Test("Round at scale 3")
    func roundScale3() {
        #expect(FixedPointDecimal(1.23456).rounded(scale: 3) == 1.235 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.23450).rounded(scale: 3) == 1.234 as FixedPointDecimal)
    }

    @Test("Round at scale 4")
    func roundScale4() {
        #expect(FixedPointDecimal(1.23456).rounded(scale: 4) == 1.2346 as FixedPointDecimal)
    }

    @Test("Round at scale 5")
    func roundScale5() {
        #expect(FixedPointDecimal(1.234565).rounded(scale: 5) == 1.23456 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.234575).rounded(scale: 5) == 1.23458 as FixedPointDecimal)
    }

    @Test("Round at scale 6")
    func roundScale6() {
        #expect(FixedPointDecimal(1.2345675).rounded(scale: 6) == 1.234568 as FixedPointDecimal)
    }

    @Test("Round at scale 7")
    func roundScale7() {
        #expect(FixedPointDecimal(1.23456785).rounded(scale: 7) == 1.2345678 as FixedPointDecimal)
        #expect(FixedPointDecimal(1.23456795).rounded(scale: 7) == 1.2345680 as FixedPointDecimal)
    }

    // MARK: - Rounding Negative Values

    @Test("Round negative with down mode at each scale")
    func roundNegativeDown() {
        #expect(FixedPointDecimal(-1.99).rounded(scale: 0, .towardZero) == -1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.99).rounded(scale: 1, .towardZero) == -1.9 as FixedPointDecimal)
    }

    @Test("Round negative with up mode")
    func roundNegativeUp() {
        #expect(FixedPointDecimal(-1.01).rounded(scale: 0, .awayFromZero) == -2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.01).rounded(scale: 1, .awayFromZero) == -1.1 as FixedPointDecimal)
    }

    @Test("Round negative with floor mode")
    func roundNegativeFloor() {
        #expect(FixedPointDecimal(-1.01).rounded(scale: 0, .down) == -2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.01).rounded(scale: 1, .down) == -1.1 as FixedPointDecimal)
    }

    @Test("Round negative with ceiling mode")
    func roundNegativeCeiling() {
        #expect(FixedPointDecimal(-1.99).rounded(scale: 0, .up) == -1 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.99).rounded(scale: 1, .up) == -1.9 as FixedPointDecimal)
    }

    @Test("Round negative with toNearestOrEven mode")
    func roundNegativeBankers() {
        #expect(FixedPointDecimal(-0.5).rounded() == 0 as FixedPointDecimal)
        #expect(FixedPointDecimal(-1.5).rounded() == -2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-2.5).rounded() == -2 as FixedPointDecimal)
        #expect(FixedPointDecimal(-3.5).rounded() == -4 as FixedPointDecimal)
    }

    // MARK: - Banker's Rounding Correctness at Various Scales

    @Test("Banker's rounding at scale 2 — exactly half")
    func bankersScale2() {
        // 1.225 rounds to 1.22 (even)
        #expect(FixedPointDecimal(1.225).rounded(scale: 2) == 1.22 as FixedPointDecimal)
        // 1.235 rounds to 1.24 (even)
        #expect(FixedPointDecimal(1.235).rounded(scale: 2) == 1.24 as FixedPointDecimal)
        // 1.245 rounds to 1.24 (even)
        #expect(FixedPointDecimal(1.245).rounded(scale: 2) == 1.24 as FixedPointDecimal)
        // 1.255 rounds to 1.26 (even)
        #expect(FixedPointDecimal(1.255).rounded(scale: 2) == 1.26 as FixedPointDecimal)
    }

    @Test("Rounding zero value at every mode")
    func roundZeroAllModes() {
        let zero = FixedPointDecimal.zero
        #expect(zero.rounded(scale: 0, .towardZero) == zero)
        #expect(zero.rounded(scale: 0, .awayFromZero) == zero)
        #expect(zero.rounded(scale: 0, .down) == zero)
        #expect(zero.rounded(scale: 0, .up) == zero)
        #expect(zero.rounded(scale: 0, .toNearestOrEven) == zero)
    }

    // MARK: - Floor/Ceiling Identity When Already Rounded

    @Test("Floor of value already on boundary is identity")
    func floorIdentity() {
        let value: FixedPointDecimal = -2
        #expect(value.rounded(scale: 0, .down) == value)
        let pos: FixedPointDecimal = 3
        #expect(pos.rounded(scale: 0, .down) == pos)
    }

    @Test("Ceiling of value already on boundary is identity")
    func ceilingIdentity() {
        let value: FixedPointDecimal = 3
        #expect(value.rounded(scale: 0, .up) == value)
        let neg: FixedPointDecimal = -2
        #expect(neg.rounded(scale: 0, .up) == neg)
    }

    // MARK: - Up/Down Identity When Already Rounded

    @Test("Up mode of value already on boundary is identity")
    func upIdentity() {
        let value: FixedPointDecimal = 5
        #expect(value.rounded(scale: 0, .awayFromZero) == value)
    }

    @Test("Down mode of value already on boundary is identity")
    func downIdentity() {
        let value: FixedPointDecimal = 5
        #expect(value.rounded(scale: 0, .towardZero) == value)
    }

    // MARK: - Negative Banker's Rounding at Scale 2

    @Test("Banker's rounding negative at scale 2 — exactly half")
    func bankersNegativeScale2() {
        // -1.225 rounds to -1.22 (even)
        #expect(FixedPointDecimal(-1.225).rounded(scale: 2) == -1.22 as FixedPointDecimal)
        // -1.235 rounds to -1.24 (even)
        #expect(FixedPointDecimal(-1.235).rounded(scale: 2) == -1.24 as FixedPointDecimal)
        // -1.245 rounds to -1.24 (even)
        #expect(FixedPointDecimal(-1.245).rounded(scale: 2) == -1.24 as FixedPointDecimal)
        // -1.255 rounds to -1.26 (even)
        #expect(FixedPointDecimal(-1.255).rounded(scale: 2) == -1.26 as FixedPointDecimal)
    }

    // MARK: - All Modes at Scale 2 With Negative Values

    @Test("All rounding modes for negative value at scale 2")
    func allModesNegativeScale2() {
        let value: FixedPointDecimal = -1.456
        #expect(value.rounded(scale: 2, .towardZero) == -1.45 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .awayFromZero) == -1.46 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .down) == -1.46 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .up) == -1.45 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .toNearestOrEven) == -1.46 as FixedPointDecimal)
    }

    // MARK: - All Modes at Scale 4

    @Test("All rounding modes at scale 4")
    func allModesScale4() {
        let value: FixedPointDecimal = 1.23456
        #expect(value.rounded(scale: 4, .towardZero) == 1.2345 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .awayFromZero) == 1.2346 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .down) == 1.2345 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .up) == 1.2346 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .toNearestOrEven) == 1.2346 as FixedPointDecimal)
    }

    @Test("All rounding modes at scale 4 negative")
    func allModesScale4Negative() {
        let value: FixedPointDecimal = -1.23456
        #expect(value.rounded(scale: 4, .towardZero) == -1.2345 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .awayFromZero) == -1.2346 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .down) == -1.2346 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .up) == -1.2345 as FixedPointDecimal)
        #expect(value.rounded(scale: 4, .toNearestOrEven) == -1.2346 as FixedPointDecimal)
    }

    // MARK: - Rounding .max and .min

    @Test("Rounding .max at scale 0")
    func roundMaxScale0() {
        let max = FixedPointDecimal.max // 92233720368.54775807
        let rounded = max.rounded(scale: 0, .towardZero)
        #expect(rounded == 92233720368 as FixedPointDecimal)
    }

    @Test("Rounding .min at scale 0")
    func roundMinScale0() {
        let min = FixedPointDecimal.min // -92233720368.54775807
        let rounded = min.rounded(scale: 0, .towardZero)
        #expect(rounded == -92233720368 as FixedPointDecimal)
    }

    @Test("Rounding leastNonzeroMagnitude down to scale 0")
    func roundLeastNonzeroDown() {
        let v = FixedPointDecimal.leastNonzeroMagnitude // 0.00000001
        #expect(v.rounded(scale: 0, .towardZero) == .zero)
        #expect(v.rounded(scale: 0, .awayFromZero) == 1 as FixedPointDecimal)
        #expect(v.rounded(scale: 0, .down) == .zero)
        #expect(v.rounded(scale: 0, .up) == 1 as FixedPointDecimal)
        #expect(v.rounded(scale: 0, .toNearestOrEven) == .zero)
    }

    // MARK: - Exact Midpoint Rounding (inspired by IBM/Cowlishaw test vectors)
    //
    // The gold-standard decimal test suite tests values at exactly 0.5 ULP,
    // just above, and just below, for both odd and even last digits.

    @Test("All rounding modes at exact 0.5 midpoint — even last digit")
    func exactMidpointEvenLastDigit() {
        // 2.5 — last retained digit is 2 (even)
        let value: FixedPointDecimal = 2.5
        #expect(value.rounded(scale: 0, .toNearestOrEven) == 2 as FixedPointDecimal)  // banker's: round to even
        #expect(value.rounded(scale: 0, .towardZero) == 2 as FixedPointDecimal)             // toward zero
        #expect(value.rounded(scale: 0, .awayFromZero) == 3 as FixedPointDecimal)               // away from zero
        #expect(value.rounded(scale: 0, .down) == 2 as FixedPointDecimal)            // toward -inf
        #expect(value.rounded(scale: 0, .up) == 3 as FixedPointDecimal)          // toward +inf
    }

    @Test("All rounding modes at exact 0.5 midpoint — odd last digit")
    func exactMidpointOddLastDigit() {
        // 3.5 — last retained digit is 3 (odd)
        let value: FixedPointDecimal = 3.5
        #expect(value.rounded(scale: 0, .toNearestOrEven) == 4 as FixedPointDecimal)  // banker's: round to even
        #expect(value.rounded(scale: 0, .towardZero) == 3 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .awayFromZero) == 4 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .down) == 3 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .up) == 4 as FixedPointDecimal)
    }

    @Test("All rounding modes at exact 0.5 midpoint — negative even")
    func exactMidpointNegativeEven() {
        let value: FixedPointDecimal = -2.5
        #expect(value.rounded(scale: 0, .toNearestOrEven) == -2 as FixedPointDecimal) // banker's: round to even
        #expect(value.rounded(scale: 0, .towardZero) == -2 as FixedPointDecimal)            // toward zero
        #expect(value.rounded(scale: 0, .awayFromZero) == -3 as FixedPointDecimal)              // away from zero
        #expect(value.rounded(scale: 0, .down) == -3 as FixedPointDecimal)           // toward -inf
        #expect(value.rounded(scale: 0, .up) == -2 as FixedPointDecimal)         // toward +inf
    }

    @Test("All rounding modes at exact 0.5 midpoint — negative odd")
    func exactMidpointNegativeOdd() {
        let value: FixedPointDecimal = -3.5
        #expect(value.rounded(scale: 0, .toNearestOrEven) == -4 as FixedPointDecimal) // banker's: round to even
        #expect(value.rounded(scale: 0, .towardZero) == -3 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .awayFromZero) == -4 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .down) == -4 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .up) == -3 as FixedPointDecimal)
    }

    @Test("Rounding just above and just below 0.5 midpoint")
    func justAboveAndBelowMidpoint() {
        // Just below 2.5: 2.49999999
        let below: FixedPointDecimal = 2.49999999
        #expect(below.rounded(scale: 0, .toNearestOrEven) == 2 as FixedPointDecimal)
        #expect(below.rounded(scale: 0, .awayFromZero) == 3 as FixedPointDecimal)
        #expect(below.rounded(scale: 0, .towardZero) == 2 as FixedPointDecimal)

        // Just above 2.5: 2.50000001
        let above: FixedPointDecimal = 2.50000001
        #expect(above.rounded(scale: 0, .toNearestOrEven) == 3 as FixedPointDecimal)
        #expect(above.rounded(scale: 0, .towardZero) == 2 as FixedPointDecimal)
        #expect(above.rounded(scale: 0, .awayFromZero) == 3 as FixedPointDecimal)
    }

    @Test("Midpoint rounding at scale 2 — all modes for x.xx5")
    func midpointAtScale2AllModes() {
        // 1.125 — last retained digit is 2 (even), discarded is exactly 5
        let value: FixedPointDecimal = 1.125
        #expect(value.rounded(scale: 2, .toNearestOrEven) == 1.12 as FixedPointDecimal) // banker's: even
        #expect(value.rounded(scale: 2, .towardZero) == 1.12 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .awayFromZero) == 1.13 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .down) == 1.12 as FixedPointDecimal)
        #expect(value.rounded(scale: 2, .up) == 1.13 as FixedPointDecimal)

        // 1.135 — last retained digit is 3 (odd), discarded is exactly 5
        let odd: FixedPointDecimal = 1.135
        #expect(odd.rounded(scale: 2, .toNearestOrEven) == 1.14 as FixedPointDecimal)   // banker's: round up to even
        #expect(odd.rounded(scale: 2, .towardZero) == 1.13 as FixedPointDecimal)
        #expect(odd.rounded(scale: 2, .awayFromZero) == 1.14 as FixedPointDecimal)
    }

    // MARK: - Carry Propagation at Precision Limits (inspired by IBM/Cowlishaw)

    @Test("Rounding causes carry propagation across all digits")
    func roundingCarryPropagation() {
        // 9.99999999 rounded up to scale 0 = 10
        let value: FixedPointDecimal = 9.99999999
        #expect(value.rounded(scale: 0, .awayFromZero) == 10 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .up) == 10 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .toNearestOrEven) == 10 as FixedPointDecimal)
    }

    @Test("Rounding negative causes carry propagation")
    func roundingNegativeCarryPropagation() {
        let value: FixedPointDecimal = -9.99999999
        #expect(value.rounded(scale: 0, .awayFromZero) == -10 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .down) == -10 as FixedPointDecimal)
        #expect(value.rounded(scale: 0, .toNearestOrEven) == -10 as FixedPointDecimal)
    }

    @Test("Carry propagation at scale 7: 0.99999995 rounds to 1.0")
    func carryPropagationScale7() {
        let value: FixedPointDecimal = 0.99999995
        #expect(value.rounded(scale: 7, .toNearestOrEven) == 1 as FixedPointDecimal)
    }
}
