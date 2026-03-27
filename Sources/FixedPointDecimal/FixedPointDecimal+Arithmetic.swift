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

// MARK: - Trapping Arithmetic (default -- matches Swift Int)

extension FixedPointDecimal {
    /// Returns the sum of two values.
    ///
    /// If either operand is NaN, the result is NaN.
    /// Traps on overflow, matching Swift `Int` behavior.
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
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        if lhs.isNaN || rhs.isNaN { return .nan }
        let (result, overflow) = lhs._storage.addingReportingOverflow(rhs._storage)
        precondition(!overflow, "FixedPointDecimal addition overflow")
        precondition(result != .min, "FixedPointDecimal addition produced NaN sentinel")
        return Self(rawValue: result)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow. Propagates NaN.
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
    /// If either operand is NaN, the result is NaN.
    /// Traps on overflow, matching Swift `Int` behavior.
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
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        if lhs.isNaN || rhs.isNaN { return .nan }
        let (result, overflow) = lhs._storage.subtractingReportingOverflow(rhs._storage)
        precondition(!overflow, "FixedPointDecimal subtraction overflow")
        precondition(result != .min, "FixedPointDecimal subtraction produced NaN sentinel")
        return Self(rawValue: result)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow. Propagates NaN.
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
    /// Uses `Int128` intermediate arithmetic to prevent precision loss during
    /// the multiply-then-divide-by-scale-factor operation. The result is
    /// rounded using banker's rounding (round half to even). If either operand
    /// is NaN, the result is NaN. Traps if the final result does not fit in
    /// `Int64`.
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
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self {
        if lhs.isNaN || rhs.isNaN { return .nan }
        let wide = Int128(lhs._storage) * Int128(rhs._storage)
        let scaled = _bankersDiv(wide, Int128(scaleFactor))
        precondition(scaled > Int128(Int64.min) && scaled <= Int128(Int64.max),
                     "FixedPointDecimal multiplication overflow")
        return Self(rawValue: Int64(scaled))
    }

    /// Multiplies the left-hand value by the right-hand value in place.
    ///
    /// Traps on overflow. Propagates NaN.
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
    /// Uses `Int128` intermediate arithmetic for precision. The result is
    /// rounded using banker's rounding (round half to even). If either operand
    /// is NaN, the result is NaN. Traps on division by zero or if the result
    /// does not fit in `Int64`.
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
    /// - Precondition: `rhs` must not be zero.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        if lhs.isNaN || rhs.isNaN { return .nan }
        precondition(rhs._storage != 0, "Division by zero")
        let wide = Int128(lhs._storage) * Int128(scaleFactor)
        let result = _bankersDiv(wide, Int128(rhs._storage))
        precondition(result > Int128(Int64.min) && result <= Int128(Int64.max),
                     "FixedPointDecimal division overflow")
        return Self(rawValue: Int64(result))
    }

    /// Divides the left-hand value by the right-hand value in place.
    ///
    /// Traps on division by zero or overflow. Propagates NaN.
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
    /// If either operand is NaN, the result is NaN.
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
    /// - Precondition: `rhs` must not be zero.
    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        if lhs.isNaN || rhs.isNaN { return .nan }
        precondition(rhs._storage != 0, "Division by zero in remainder")
        return Self(rawValue: lhs._storage % rhs._storage)
    }

    /// Divides the left-hand value by the right-hand value and stores the remainder in place.
    ///
    /// Propagates NaN.
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
