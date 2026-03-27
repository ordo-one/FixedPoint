public import Foundation

// MARK: - Foundation.Decimal Conversions

extension FixedPointDecimal {
    /// Creates a value from a `Foundation.Decimal`.
    ///
    /// Precision beyond 8 decimal places is rounded using banker's rounding
    /// (round half to even). Creates `.nan` if the input is `Decimal.nan`.
    ///
    /// ```swift
    /// let d = Decimal(string: "123.456")!
    /// let v = FixedPointDecimal(d)  // 123.456
    /// ```
    ///
    /// - Parameter decimal: The `Foundation.Decimal` value to convert.
    /// - Precondition: The scaled result must fit in `Int64`.
    public init(_ decimal: Decimal) {
        if decimal.isNaN {
            self = .nan
            return
        }
        var scaled = Decimal()
        var value = decimal
        var factor = Decimal(Self.scaleFactor)
        _ = NSDecimalMultiply(&scaled, &value, &factor, .plain)

        // Banker's rounding (round half to even)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .bankers)

        let int64Value = NSDecimalNumber(decimal: rounded).int64Value

        // Overflow check: round-trip must match
        precondition(Decimal(int64Value) == rounded,
                     "Decimal value \(decimal) overflows FixedPointDecimal range")
        // Guard against NaN sentinel
        precondition(int64Value != .min,
                     "Decimal value \(decimal) maps to NaN sentinel")

        self._storage = int64Value
    }

    /// Creates a value from a `Foundation.Decimal`, returning `nil` on overflow
    /// or if the input is `Decimal.nan`.
    ///
    /// ```swift
    /// let d = Decimal(string: "123.456")!
    /// let v = FixedPointDecimal(exactly: d)  // Optional(123.456)
    ///
    /// let nan = FixedPointDecimal(exactly: Decimal.nan)  // nil
    /// ```
    ///
    /// - Parameter decimal: The `Foundation.Decimal` value to convert.
    /// - Returns: A `FixedPointDecimal` if the value is representable, otherwise `nil`.
    public init?(exactly decimal: Decimal) {
        if decimal.isNaN { return nil }

        var scaled = Decimal()
        var value = decimal
        var factor = Decimal(Self.scaleFactor)
        _ = NSDecimalMultiply(&scaled, &value, &factor, .plain)

        // Verify exactness: scaled value must already be an integer
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        guard scaled == rounded else { return nil }

        let int64Value = NSDecimalNumber(decimal: rounded).int64Value

        // Guard against Int64.min (our NaN sentinel)
        guard int64Value != .min else { return nil }

        // Round-trip check to detect overflow
        guard Decimal(int64Value) == rounded else { return nil }

        self._storage = int64Value
    }

    /// The value as a `Foundation.Decimal`. Backwards-compatibility convenience for `Decimal(self)`.
    ///
    /// This conversion never loses precision because 8 fractional digits
    /// fit easily within `Decimal`'s 38-digit capacity.
    /// Returns `Decimal.nan` for NaN.
    @inlinable
    public var decimalValue: Decimal {
        if isNaN { return Decimal.nan }
        return Decimal(_storage) / Decimal(Self.scaleFactor)
    }
}

// MARK: - Convenience Extensions on Foundation.Decimal

extension Decimal {
    /// Creates a `Decimal` from a `FixedPointDecimal`. Always exact.
    ///
    /// ```swift
    /// let fp: FixedPointDecimal = "99.95"
    /// let d = Decimal(fp)  // Decimal(99.95)
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    @inlinable
    public init(_ value: FixedPointDecimal) {
        self = value.decimalValue
    }

    /// Creates a `Decimal` from a `FixedPointDecimal`, returning `nil` for NaN.
    ///
    /// ```swift
    /// let fp: FixedPointDecimal = "99.95"
    /// let d = Decimal(exactly: fp)  // Optional(Decimal(99.95))
    ///
    /// let nan = Decimal(exactly: FixedPointDecimal.nan)  // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: A `Decimal` if the value is not NaN, otherwise `nil`.
    @inlinable
    public init?(exactly value: FixedPointDecimal) {
        if value.isNaN { return nil }
        self = value.decimalValue
    }
}

// MARK: - Foundation.Decimal FormatStyle forwarding

/// Provides the full `Decimal.FormatStyle` API surface on `FixedPointDecimal`,
/// enabling `.formatted(.number)`, `.formatted(.percent)`, `.formatted(.currency(code:))`,
/// and all their modifiers (`.locale(...)`, `.precision(...)`, `.rounded(...)`, etc.).
///
/// Internally converts to `Foundation.Decimal` and delegates.
extension FixedPointDecimal {
    /// Formats using `Decimal.FormatStyle` (e.g. `.number`, `.number.locale(...)`, `.number.precision(...)`).
    @inlinable public func formatted(_ style: Decimal.FormatStyle) -> String {
        decimalValue.formatted(style)
    }

    /// Formats using `Decimal.FormatStyle.Percent` (e.g. `.percent`).
    @inlinable public func formatted(_ style: Decimal.FormatStyle.Percent) -> String {
        decimalValue.formatted(style)
    }

    /// Formats using `Decimal.FormatStyle.Currency` (e.g. `.currency(code: "USD")`).
    @inlinable public func formatted(_ style: Decimal.FormatStyle.Currency) -> String {
        decimalValue.formatted(style)
    }

    /// Formats using any `FormatStyle` whose input is `Decimal`.
    /// This catches custom format styles like `.bp`, `.permille`, etc.
    public func formatted<S: FormatStyle>(_ style: S) -> S.FormatOutput where S.FormatInput == Decimal {
        decimalValue.formatted(style)
    }
}
