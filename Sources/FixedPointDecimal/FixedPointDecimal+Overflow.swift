// MARK: - Wrapping Arithmetic (for hot paths)

extension FixedPointDecimal {
    /// Returns the sum of two values, wrapping on overflow.
    ///
    /// Unlike `+`, this operator performs no validation: no NaN checks, no
    /// overflow traps, no sentinel adjustment — just a raw wrapping add on
    /// the underlying `Int64` storage. This matches Swift standard library
    /// semantics where `&+` is a single CPU instruction with no guards.
    ///
    /// - Important: If either operand is NaN, the result is undefined.
    ///   The caller is responsible for ensuring operands are valid.
    ///
    /// - Parameters:
    ///   - lhs: The first addend.
    ///   - rhs: The second addend.
    /// - Returns: The wrapping sum of `lhs` and `rhs`.
    @inlinable
    public static func &+ (lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs._storage &+ rhs._storage)
    }

    /// Returns the difference of two values, wrapping on overflow.
    ///
    /// Unlike `-`, this operator performs no validation: no NaN checks, no
    /// overflow traps, no sentinel adjustment — just a raw wrapping subtract
    /// on the underlying `Int64` storage.
    ///
    /// - Important: If either operand is NaN, the result is undefined.
    ///   The caller is responsible for ensuring operands are valid.
    ///
    /// - Parameters:
    ///   - lhs: The minuend.
    ///   - rhs: The subtrahend.
    /// - Returns: The wrapping difference of `lhs` and `rhs`.
    @inlinable
    public static func &- (lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs._storage &- rhs._storage)
    }

    /// Returns the product of two values, wrapping on overflow.
    ///
    /// Unlike `*`, this operator performs no NaN checks or sentinel
    /// adjustment. Uses `Int128` intermediate arithmetic with banker's
    /// rounding and truncates to `Int64` if the result overflows.
    ///
    /// - Note: Unlike `&+` and `&-`, wrapping multiplication is actually
    ///   slower than checked `*` in benchmarks. The `precondition` in `*`
    ///   gives the optimizer proof that the result fits in `Int64`, enabling
    ///   tighter code generation. Prefer `*` unless you specifically need
    ///   non-trapping overflow behavior.
    ///
    /// - Important: If either operand is NaN, the result is undefined.
    ///   The caller is responsible for ensuring operands are valid.
    ///
    /// - Parameters:
    ///   - lhs: The first factor.
    ///   - rhs: The second factor.
    /// - Returns: The wrapping product of `lhs` and `rhs`.
    @inlinable
    public static func &* (lhs: Self, rhs: Self) -> Self {
        let wide = Int128(lhs._storage) * Int128(rhs._storage)
        let scaled = _bankersDiv(wide, Int128(scaleFactor))
        return Self(rawValue: Int64(truncatingIfNeeded: scaled))
    }
}

// MARK: - Overflow-Reporting Arithmetic

extension FixedPointDecimal {
    /// Returns the sum of this value and the given value, along with a Boolean
    /// indicating whether overflow occurred in the operation.
    ///
    /// Traps if either operand is NaN.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "50.0"
    /// let b: FixedPointDecimal = "25.0"
    /// let (sum, overflow) = a.addingReportingOverflow(b)
    /// // sum == 75.0, overflow == false
    /// ```
    ///
    /// - Parameter other: The value to add.
    /// - Returns: A tuple containing the partial sum and a Boolean overflow flag.
    /// - Precondition: Neither operand may be NaN.
    @inlinable
    public func addingReportingOverflow(_ other: Self) -> (partialValue: Self, overflow: Bool) {
        precondition(!isNaN && !other.isNaN, "NaN in FixedPointDecimal addition")
        let (result, overflow) = _storage.addingReportingOverflow(other._storage)
        return (Self(rawValue: result), overflow || result == .min)
    }

    /// Returns the difference of this value and the given value, along with a
    /// Boolean indicating whether overflow occurred in the operation.
    ///
    /// Traps if either operand is NaN.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "50.0"
    /// let b: FixedPointDecimal = "25.0"
    /// let (diff, overflow) = a.subtractingReportingOverflow(b)
    /// // diff == 25.0, overflow == false
    /// ```
    ///
    /// - Parameter other: The value to subtract.
    /// - Returns: A tuple containing the partial difference and a Boolean overflow flag.
    /// - Precondition: Neither operand may be NaN.
    @inlinable
    public func subtractingReportingOverflow(_ other: Self) -> (partialValue: Self, overflow: Bool) {
        precondition(!isNaN && !other.isNaN, "NaN in FixedPointDecimal subtraction")
        let (result, overflow) = _storage.subtractingReportingOverflow(other._storage)
        return (Self(rawValue: result), overflow || result == .min)
    }

    /// Returns the product of this value and the given value, along with a Boolean
    /// indicating whether overflow occurred in the operation.
    ///
    /// Uses `Int128` intermediate arithmetic. Overflow is reported when the scaled
    /// result exceeds `Int64` range. Traps if either operand is NaN.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.0"
    /// let b: FixedPointDecimal = "5.0"
    /// let (product, overflow) = a.multipliedReportingOverflow(by: b)
    /// // product == 50.0, overflow == false
    /// ```
    ///
    /// - Parameter other: The value to multiply by.
    /// - Returns: A tuple containing the partial product and a Boolean overflow flag.
    /// - Precondition: Neither operand may be NaN.
    @inlinable
    public func multipliedReportingOverflow(by other: Self) -> (partialValue: Self, overflow: Bool) {
        precondition(!isNaN && !other.isNaN, "NaN in FixedPointDecimal multiplication")
        let wide = Int128(_storage) * Int128(other._storage)
        let scaled = Self._bankersDiv(wide, Int128(Self.scaleFactor))
        let fits = scaled > Int128(Int64.min) && scaled <= Int128(Int64.max)
        let result = Int64(truncatingIfNeeded: scaled)
        return (Self(rawValue: result), !fits || result == .min)
    }

    /// Returns the quotient of this value divided by the given value, along with
    /// a Boolean indicating whether overflow occurred in the operation.
    ///
    /// Overflow is reported for division by zero or when the result exceeds
    /// `Int64` range. Traps if either operand is NaN.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "100.0"
    /// let b: FixedPointDecimal = "3.0"
    /// let (quotient, overflow) = a.dividedReportingOverflow(by: b)
    /// // quotient == 33.33333333, overflow == false
    ///
    /// let (_, divByZero) = a.dividedReportingOverflow(by: .zero)
    /// // divByZero == true
    /// ```
    ///
    /// - Parameter other: The value to divide by.
    /// - Returns: A tuple containing the partial quotient and a Boolean overflow flag.
    /// - Precondition: Neither operand may be NaN.
    @inlinable
    public func dividedReportingOverflow(by other: Self) -> (partialValue: Self, overflow: Bool) {
        precondition(!isNaN && !other.isNaN, "NaN in FixedPointDecimal division")
        guard other._storage != 0 else {
            return (.zero, true)
        }
        let wide = Int128(_storage) * Int128(Self.scaleFactor)
        let result = Self._bankersDiv(wide, Int128(other._storage))
        let fits = result > Int128(Int64.min) && result <= Int128(Int64.max)
        let truncated = Int64(truncatingIfNeeded: result)
        return (Self(rawValue: truncated), !fits || truncated == .min)
    }
}
