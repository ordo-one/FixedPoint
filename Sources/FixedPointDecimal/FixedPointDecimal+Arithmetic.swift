// MARK: - Banker's Rounding Division

extension FixedPointDecimal {
    /// Int128 division with banker's rounding (round half to even).
    ///
    /// When the remainder is exactly half the divisor, the quotient is rounded
    /// to the nearest even value. This is the standard rounding mode for
    /// financial arithmetic (IEEE 754 "roundTiesToEven").
    @inlinable
    static func _bankersDiv(_ numerator: Int128, _ denominator: Int128) -> Int128 {
        let (q, r) = numerator.quotientAndRemainder(dividingBy: denominator)
        if r == 0 { return q }

        let twoAbsR = r.magnitude &* 2
        let absDenom = denominator.magnitude

        // Round away from zero if remainder > 0.5, or exactly 0.5 and quotient is odd
        if twoAbsR > absDenom || (twoAbsR == absDenom && q & 1 != 0) {
            return q + (((numerator >= 0) == (denominator >= 0)) ? 1 : -1)
        }

        return q
    }
}

// MARK: - Wide Multiply and Divide Helpers

// `*` and `/` need a 128-bit intermediate, but the quotient they keep always fits in 64 bits
// (anything larger overflows). Dividing a full `Int128` by an `Int128` compiles to a call into the
// generic compiler-rt routine (`__divti3`), which costs more than the rest of the operation put
// together. These helpers work on unsigned magnitudes with 64-bit pieces instead, so the common
// case needs no runtime call; the signed result is rebuilt by the operator.

extension FixedPointDecimal {
    /// Divides the unsigned 128-bit value `high:low` by the scale factor (10⁸).
    ///
    /// Schoolbook long division in 32-bit digits. Because 10⁸ < 2³², every partial dividend fits
    /// in 64 bits, and each step is a 64-bit division by a constant, which compiles to a
    /// multiply-high and shift rather than a divide instruction or a runtime call.
    @inlinable @inline(__always)
    internal static func _divideByScaleFactor(
        high: UInt64,
        low: UInt64
    ) -> (quotient: (high: UInt64, low: UInt64), remainder: UInt64) {
        let divisor = UInt64(scaleFactor)
        let quotientHigh = high / divisor
        let upper = (high % divisor) << 32 | low >> 32
        let lower = (upper % divisor) << 32 | low & 0xFFFF_FFFF
        return ((quotientHigh, (upper / divisor) << 32 | lower / divisor), lower % divisor)
    }

    /// `|lhs × rhs| / 10⁸`, rounded half to even, for multiplication of raw storage values.
    ///
    /// - Returns: The low 64 bits of the rounded magnitude, and whether the rounded magnitude
    ///   exceeds `Int64.max`. The low bits are what the truncating (`&*`) form needs.
    @inlinable @inline(__always)
    internal static func _scaledProductMagnitude(_ lhs: Int64, _ rhs: Int64) -> (magnitude: UInt64, overflow: Bool) {
        let (high, low) = lhs.magnitude.multipliedFullWidth(by: rhs.magnitude)
        let ((quotientHigh, quotient), remainder) = _divideByScaleFactor(high: high, low: low)
        let half = UInt64(scaleFactor) / 2
        let roundUp = remainder > half || (remainder == half && quotient & 1 != 0)
        let (rounded, carry) = quotient.addingReportingOverflow(roundUp ? 1 : 0)
        return (rounded, quotientHigh != 0 || carry || rounded > UInt64(Int64.max))
    }

    /// `|lhs| × 10⁸ / |rhs|`, rounded half to even, for division of raw storage values.
    ///
    /// - Returns: The rounded magnitude, or `nil` when it exceeds `Int64.max`.
    /// - Precondition: `rhs != 0`.
    @inlinable @inline(__always)
    internal static func _scaledQuotientMagnitude(_ lhs: Int64, _ rhs: Int64) -> UInt64? {
        let divisor = rhs.magnitude
        let (high, low) = lhs.magnitude.multipliedFullWidth(by: UInt64(scaleFactor))
        let quotient: UInt64
        let remainder: UInt64
        if high == 0 {
            // |lhs| < 2⁶⁴ / 10⁸ (values below about 1844.67): a single 64-bit divide.
            (quotient, remainder) = low.quotientAndRemainder(dividingBy: divisor)
        } else if high < divisor {
            // A 128-by-64 divide whose quotient fits in 64 bits. On x86_64 compiler-rt does this
            // with one `divq`; on arm64 (no such instruction) it was measured as fast as an
            // inlined Knuth algorithm D, so one implementation serves both.
            (quotient, remainder) = divisor.dividingFullWidth((high, low))
        } else {
            return nil // the quotient needs more than 64 bits
        }
        // remainder < divisor ≤ 2⁶³, so doubling it cannot overflow.
        let twiceRemainder = remainder &<< 1
        let roundUp = twiceRemainder > divisor || (twiceRemainder == divisor && quotient & 1 != 0)
        let (rounded, carry) = quotient.addingReportingOverflow(roundUp ? 1 : 0)
        return carry || rounded > UInt64(Int64.max) ? nil : rounded
    }

    /// Applies the sign of `lhs × rhs` (or `lhs / rhs`) to a magnitude, truncating to 64 bits.
    @inlinable @inline(__always)
    internal static func _signed(_ magnitude: UInt64, negative: Bool) -> Int64 {
        Int64(bitPattern: negative ? 0 &- magnitude : magnitude)
    }
}

// MARK: - Trapping Arithmetic (default -- matches Swift Int)

extension FixedPointDecimal {
    /// Returns the sum of two values.
    ///
    /// Traps if either operand is NaN or if the result overflows,
    /// matching Swift `Int` behavior.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.5"
    /// let b: FixedPointDecimal = "3.25"
    /// let sum = a + b  // 13.75
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The first addend.
    ///   - rhs: The second addend.
    /// - Returns: The sum of `lhs` and `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal addition")
        let (result, overflow) = lhs._storage.addingReportingOverflow(rhs._storage)
        precondition(!overflow, "FixedPointDecimal addition overflow")
        precondition(result != .min, "FixedPointDecimal addition produced NaN sentinel")
        return Self(rawValue: result)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow or NaN.
    ///
    /// ```swift
    /// var total: FixedPointDecimal = "100.0"
    /// total += FixedPointDecimal("0.50")!
    /// // total is now 100.5
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Returns the difference of two values.
    ///
    /// Traps if either operand is NaN or if the result overflows,
    /// matching Swift `Int` behavior.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.5"
    /// let b: FixedPointDecimal = "3.25"
    /// let diff = a - b  // 7.25
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The minuend.
    ///   - rhs: The subtrahend.
    /// - Returns: The difference of `lhs` and `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal subtraction")
        let (result, overflow) = lhs._storage.subtractingReportingOverflow(rhs._storage)
        precondition(!overflow, "FixedPointDecimal subtraction overflow")
        precondition(result != .min, "FixedPointDecimal subtraction produced NaN sentinel")
        return Self(rawValue: result)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow or NaN.
    ///
    /// ```swift
    /// var balance: FixedPointDecimal = "100.0"
    /// balance -= FixedPointDecimal("25.50")!
    /// // balance is now 74.5
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to subtract.
    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    /// Returns the product of two values.
    ///
    /// The full 128-bit product is divided by the scale factor (10⁸), so no
    /// precision is lost, and the result is rounded using banker's rounding
    /// (round half to even). Traps if either operand is NaN or if the result
    /// does not fit in `Int64`.
    ///
    /// ```swift
    /// let price: FixedPointDecimal = "12.50"
    /// let qty: FixedPointDecimal = "3.0"
    /// let total = price * qty  // 37.5
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The first factor.
    ///   - rhs: The second factor.
    /// - Returns: The product of `lhs` and `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal multiplication")
        let (magnitude, overflow) = _scaledProductMagnitude(lhs._storage, rhs._storage)
        precondition(!overflow, "FixedPointDecimal multiplication overflow")
        return Self(rawValue: _signed(magnitude, negative: (lhs._storage ^ rhs._storage) < 0))
    }

    /// Multiplies the left-hand value by the right-hand value in place.
    ///
    /// Traps on overflow or NaN.
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The multiplier.
    @inlinable
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    /// Returns the quotient of two values.
    ///
    /// The dividend is widened to 128 bits (`lhs` × 10⁸) before dividing, so no
    /// precision is lost, and the result is rounded using banker's rounding
    /// (round half to even). Traps if either operand is NaN, on division by
    /// zero, or if the result does not fit in `Int64`.
    ///
    /// ```swift
    /// let total: FixedPointDecimal = "100.0"
    /// let parts: FixedPointDecimal = "3.0"
    /// let each = total / parts  // 33.33333333
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The dividend.
    ///   - rhs: The divisor.
    /// - Returns: The quotient of `lhs` divided by `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: `rhs` must not be zero.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal division")
        precondition(rhs._storage != 0, "Division by zero")
        guard let magnitude = _scaledQuotientMagnitude(lhs._storage, rhs._storage) else {
            preconditionFailure("FixedPointDecimal division overflow")
        }
        return Self(rawValue: _signed(magnitude, negative: (lhs._storage ^ rhs._storage) < 0))
    }

    /// Divides the left-hand value by the right-hand value in place.
    ///
    /// Traps on division by zero, overflow, or NaN.
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The divisor.
    @inlinable
    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

// MARK: - Mixed-Type Arithmetic (FixedPointDecimal × Integer)

// Note: Mixed-type Int64 operators (FixedPointDecimal * Int64, Int64 * FixedPointDecimal,
// FixedPointDecimal / Int64) were removed to avoid operator ambiguity with
// ExpressibleByIntegerLiteral. Use integer literals directly instead:
//   price * 100      (100 inferred as FixedPointDecimal via integerLiteral)
//   price / 4        (4 inferred as FixedPointDecimal via integerLiteral)
// For Int64 variables, convert explicitly:
//   price * FixedPointDecimal(someInt64Var)

// MARK: - Remainder

extension FixedPointDecimal {
    /// Returns the remainder of dividing the first value by the second.
    ///
    /// The sign of the result matches the sign of the dividend (`lhs`).
    /// Traps if either operand is NaN.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.0"
    /// let b: FixedPointDecimal = "3.0"
    /// let r = a % b  // 1.0
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The dividend.
    ///   - rhs: The divisor.
    /// - Returns: The remainder of `lhs` divided by `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: `rhs` must not be zero.
    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal remainder")
        precondition(rhs._storage != 0, "Division by zero in remainder")
        return Self(rawValue: lhs._storage % rhs._storage)
    }

    /// Divides the left-hand value by the right-hand value and stores the remainder in place.
    ///
    /// Traps on NaN.
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The divisor.
    /// - Precondition: `rhs` must not be zero.
    @inlinable
    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }
}
