// MARK: - Rounding

extension FixedPointDecimal {
    /// Rounding modes for ``rounded(scale:_:)`` and ``round(scale:_:)``.
    ///
    /// These cases match the naming of Swift's `FloatingPointRoundingRule`.
    ///
    /// ```swift
    /// let v: FixedPointDecimal = "1.235"
    /// v.rounded(scale: 2, .towardZero)         // 1.23
    /// v.rounded(scale: 2, .awayFromZero)       // 1.24
    /// v.rounded(scale: 2, .toNearestOrEven)    // 1.24
    /// ```
    public enum RoundingMode: Sendable {
        /// Round toward negative infinity.
        case down
        /// Round toward positive infinity.
        case up
        /// Round toward zero (truncate).
        case towardZero
        /// Round away from zero.
        case awayFromZero
        /// Round half to even (banker's rounding). This is the default mode.
        case toNearestOrEven
        /// Round half away from zero (schoolbook rounding).
        case toNearestOrAwayFromZero
    }

    /// Returns this value rounded to the specified number of fractional decimal digits.
    ///
    /// Traps on NaN.
    ///
    /// ```swift
    /// let price = FixedPointDecimal("123.456789")!
    /// price.rounded(scale: 2)                          // 123.46
    /// price.rounded(scale: 2, .towardZero)             // 123.45
    /// price.rounded(scale: 0)                          // 123
    /// price.rounded(scale: 4, .up)                     // 123.4568
    /// ```
    ///
    /// - Parameters:
    ///   - scale: The number of fractional digits to keep (0...8). Default is 0.
    ///   - mode: The rounding mode. Default is `.toNearestOrEven`.
    /// - Returns: The rounded value.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: `scale` must be in `0...8`.
    @inlinable
    public func rounded(scale: Int = 0, _ mode: RoundingMode = .toNearestOrEven) -> Self {
        precondition(scale >= 0 && scale <= Self.fractionalDigitCount,
                     "Scale must be in 0...\(Self.fractionalDigitCount)")
        precondition(!isNaN, "NaN in FixedPointDecimal rounding")
        guard scale < Self.fractionalDigitCount else { return self }

        let divisor = Self._powerOf10(Self.fractionalDigitCount - scale)
        let (quotient, remainder) = _storage.quotientAndRemainder(dividingBy: divisor)

        if remainder == 0 { return Self(rawValue: quotient * divisor) }

        let rounded: Int64
        switch mode {
        case .towardZero:
            // Toward zero
            rounded = quotient

        case .awayFromZero:
            // Away from zero
            if _storage > 0 {
                rounded = quotient + 1
            } else {
                rounded = quotient - 1
            }

        case .down:
            // Toward negative infinity
            if remainder < 0 {
                rounded = quotient - 1
            } else {
                rounded = quotient
            }

        case .up:
            // Toward positive infinity
            if remainder > 0 {
                rounded = quotient + 1
            } else {
                rounded = quotient
            }

        case .toNearestOrEven:
            let absRemainder = abs(remainder)
            let half = divisor / 2
            if absRemainder > half {
                // Round away from zero
                rounded = _storage > 0 ? quotient + 1 : quotient - 1
            } else if absRemainder < half {
                // Round toward zero
                rounded = quotient
            } else {
                // Exactly half — round to even
                if quotient.isMultiple(of: 2) {
                    rounded = quotient
                } else {
                    rounded = _storage > 0 ? quotient + 1 : quotient - 1
                }
            }

        case .toNearestOrAwayFromZero:
            let absRemainder = abs(remainder)
            let half = divisor / 2
            if absRemainder >= half {
                // Round away from zero (half goes away from zero)
                rounded = _storage > 0 ? quotient + 1 : quotient - 1
            } else {
                // Round toward zero
                rounded = quotient
            }
        }

        let (result, overflow) = rounded.multipliedReportingOverflow(by: divisor)
        precondition(!overflow, "FixedPointDecimal rounding overflow")
        precondition(result != .min, "FixedPointDecimal rounding produced NaN sentinel")
        return Self(rawValue: result)
    }

    /// Rounds this value in place to the specified number of fractional decimal digits.
    ///
    /// ```swift
    /// var price = FixedPointDecimal("123.456789")!
    /// price.round(scale: 2)
    /// // price is now 123.46
    /// ```
    ///
    /// - Parameters:
    ///   - scale: The number of fractional digits to keep (0...8). Default is 0.
    ///   - mode: The rounding mode. Default is `.toNearestOrEven`.
    /// - Precondition: `scale` must be in `0...8`.
    @inlinable
    public mutating func round(scale: Int = 0, _ mode: RoundingMode = .toNearestOrEven) {
        self = rounded(scale: scale, mode)
    }

    // MARK: - Double-compatible rounding (to integer)

    /// Returns this value rounded to an integer using the specified rounding mode.
    ///
    /// Matches `Double.rounded(_:)` — equivalent to `rounded(scale: 0, mode)`.
    ///
    /// ```swift
    /// let price: FixedPointDecimal = 123.75
    /// price.rounded(.toNearestOrEven)      // 124
    /// price.rounded(.towardZero)           // 123
    /// price.rounded(.up)                   // 124
    /// price.rounded(.down)                 // 123
    /// ```
    ///
    /// - Parameter mode: The rounding mode. Default is `.toNearestOrEven`.
    /// - Returns: The value rounded to an integer.
    @inlinable
    public func rounded(_ mode: RoundingMode = .toNearestOrEven) -> Self {
        rounded(scale: 0, mode)
    }

    /// Rounds this value to an integer in place using the specified rounding mode.
    ///
    /// Matches `Double.round(_:)` — equivalent to `round(scale: 0, mode)`.
    ///
    /// - Parameter mode: The rounding mode. Default is `.toNearestOrEven`.
    @inlinable
    public mutating func round(_ mode: RoundingMode = .toNearestOrEven) {
        self = rounded(scale: 0, mode)
    }
}

// MARK: - abs() free function

/// Returns the absolute value of a `FixedPointDecimal`.
///
/// Traps on NaN.
///
/// ```swift
/// let v: FixedPointDecimal = "-42.5"
/// abs(v)  // 42.5
/// ```
///
/// - Parameter value: The value whose absolute value is returned.
/// - Returns: The absolute value of `value`.
/// - Precondition: The value must not be NaN.
@inlinable
public func abs(_ value: FixedPointDecimal) -> FixedPointDecimal {
    precondition(!value.isNaN, "abs called on NaN")
    return FixedPointDecimal(rawValue: abs(value._storage))
}
