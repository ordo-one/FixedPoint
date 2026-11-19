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
    /// adjustment. The full 128-bit product is divided by the scale factor
    /// with banker's rounding, and the quotient is truncated to `Int64` if it
    /// overflows.
    ///
    /// - Note: `&*` is no faster than checked `*` (the checks are predicted
    ///   branches). Prefer `*` unless you specifically need non-trapping
    ///   overflow behavior.
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
        let (magnitude, _) = _scaledProductMagnitude(lhs._storage, rhs._storage)
        return Self(rawValue: _signed(magnitude, negative: (lhs._storage ^ rhs._storage) < 0))
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
    /// Computes the full 128-bit product, so no precision is lost. Overflow is
    /// reported when the rounded result exceeds `Int64` range. Traps if either
    /// operand is NaN.
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
        let (magnitude, overflow) = Self._scaledProductMagnitude(_storage, other._storage)
        let result = Self._signed(magnitude, negative: (_storage ^ other._storage) < 0)
        return (Self(rawValue: result), overflow || result == .min)
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
        if let magnitude = Self._scaledQuotientMagnitude(_storage, other._storage) {
            return (Self(rawValue: Self._signed(magnitude, negative: (_storage ^ other._storage) < 0)), false)
        }
        // Overflow (rare): compute the full quotient to report its truncated low 64 bits.
        let wide = Int128(_storage) * Int128(Self.scaleFactor)
        let result = Self._bankersDiv(wide, Int128(other._storage))
        return (Self(rawValue: Int64(truncatingIfNeeded: result)), true)
    }
}
