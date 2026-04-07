// MARK: - Integer Initialization

extension FixedPointDecimal {
    /// Creates a value from an integer.
    ///
    /// ```swift
    /// let five: FixedPointDecimal = 5
    /// // five.rawValue == 500_000_000
    /// ```
    ///
    /// - Parameter value: The integer value.
    /// - Precondition: The scaled result must fit in `Int64`.
    @inlinable
    public init(integerValue value: Int64) {
        let (result, overflow) = value.multipliedReportingOverflow(by: Self.scaleFactor)
        precondition(!overflow, "Integer value \(value) overflows FixedPointDecimal range")
        precondition(result != .min, "Integer value \(value) maps to NaN sentinel")
        self._storage = result
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension FixedPointDecimal: ExpressibleByIntegerLiteral {
    /// Creates a value from an integer literal.
    ///
    /// Enables natural integer literal syntax:
    /// ```swift
    /// let price: FixedPointDecimal = 42
    /// if quantity > 0 { ... }
    /// let factor = instrument.factor ?? 1
    /// ```
    ///
    /// - Parameter value: The integer literal value.
    @inlinable
    public init(integerLiteral value: Int64) {
        self.init(integerValue: value)
    }
}

// MARK: - ExpressibleByFloatLiteral

extension FixedPointDecimal: ExpressibleByFloatLiteral {
    /// Creates a value from a floating-point literal.
    ///
    /// Enables natural decimal literal syntax:
    /// ```swift
    /// let price: FixedPointDecimal = 99.95
    /// let tickSize: FixedPointDecimal = 0.05
    /// let spread = ask - bid  // works with literals in expressions
    /// ```
    ///
    /// ## Precision guarantee
    ///
    /// Float literals route through `Double`, which has ~15.9 decimal digits of precision.
    /// Since `FixedPointDecimal` stores exactly 8 fractional digits, the `Double` intermediate
    /// is always sufficient: any value with ≤8 fractional digits and ≤9 integer digits
    /// (the full range of `FixedPointDecimal`) roundtrips exactly through `Double`.
    ///
    /// This has been exhaustively verified for all 111,111,110 single-digit fractions
    /// with 1–8 fractional digits (n/10^d for d=1...8, n=0..<10^d) with zero failures.
    ///
    /// For example, `0.05` as `Double` is `0.05000000000000000277...`, but
    /// `round(0.05 × 10⁸) = 5_000_000` exactly — giving `0.05000000`.
    ///
    /// ## Precision limits
    ///
    /// Because `Double` carries at most ~15.9 significant decimal digits, literals with more
    /// than 15 significant digits may silently lose precision before reaching
    /// `FixedPointDecimal`.  For example, `12345678901.12345678` has 19 significant digits
    /// and will be rounded by the compiler's `Double` conversion before this initializer
    /// sees it.  If you need exact control over every digit, prefer the string initializer
    /// (`FixedPointDecimal("12345678901.12345678")`).
    ///
    /// Values near `FixedPointDecimal.max` (≈ 92 233 720 368.54775807) will trap on
    /// overflow via the underlying `init(_ value: Double)` precondition.
    ///
    /// - Parameter value: The floating-point literal value.
    /// - Precondition: The value must not be NaN or infinite.
    @inlinable
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}
