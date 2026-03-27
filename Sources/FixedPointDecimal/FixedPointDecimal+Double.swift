// MARK: - Convenience Extensions on Double

extension Double {
    /// Creates a `Double` from a `FixedPointDecimal`.
    ///
    /// Exact for values with 15 or fewer significant digits.
    /// Returns `Double.nan` if the input is NaN.
    ///
    /// ```swift
    /// let fp: FixedPointDecimal = "123.45"
    /// let d = Double(fp)  // 123.45
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    @inlinable
    public init(_ value: FixedPointDecimal) {
        self = value.doubleValue
    }

    /// Creates a `Double` from a `FixedPointDecimal`, returning `nil` if the
    /// value cannot be exactly represented as a `Double`.
    ///
    /// A round-trip check verifies the conversion is lossless. Returns `nil`
    /// for NaN. In practice this always succeeds for values within the typical
    /// financial range, since `Double` has sufficient precision for all values
    /// with fewer than 16 significant digits.
    ///
    /// ```swift
    /// let fp: FixedPointDecimal = "123.45"
    /// let d = Double(exactly: fp)  // Optional(123.45)
    ///
    /// let nan = Double(exactly: FixedPointDecimal.nan)  // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: A `Double` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: FixedPointDecimal) {
        if value.isNaN { return nil }
        let result = value.doubleValue
        // Round-trip check: verify the Double represents the value exactly
        let roundTrip = (result * Double(FixedPointDecimal.scaleFactor)).rounded()
        guard let roundTripInt = Int64(exactly: roundTrip),
              roundTripInt == value.rawValue else { return nil }
        self = result
    }
}
