// MARK: - AdditiveArithmetic

/// Conformance to `AdditiveArithmetic`, providing `+`, `-`, and `.zero`.
///
/// The `+` and `-` operators are defined in ``FixedPointDecimal+Arithmetic.swift``.
extension FixedPointDecimal: AdditiveArithmetic {
    // + and - are defined in FixedPointDecimal+Arithmetic.swift
    // .zero is provided below
}

// MARK: - Numeric & SignedNumeric

/// Conformance to `Numeric` and `SignedNumeric`, providing `*`, `magnitude`, and negation.
///
/// All arithmetic operators are defined in ``FixedPointDecimal+Arithmetic.swift``.
extension FixedPointDecimal: Numeric {}
extension FixedPointDecimal: SignedNumeric {}

// MARK: - Magnitude & Negation

extension FixedPointDecimal {
    /// The magnitude type, matching `Double`'s convention where
    /// `Magnitude == Self`.
    public typealias Magnitude = FixedPointDecimal

    /// The absolute value of this instance.
    ///
    /// Returns NaN for NaN, matching `Double.nan.magnitude` behavior.
    ///
    /// ```swift
    /// let v = FixedPointDecimal("-5.0")!
    /// v.magnitude  // 5.0
    /// FixedPointDecimal.nan.magnitude.isNaN  // true
    /// ```
    @inlinable
    public var magnitude: Magnitude {
        if isNaN { return .nan }
        return FixedPointDecimal(rawValue: abs(_storage))
    }

    /// Creates a new instance from the given integer, if it can be represented
    /// exactly within the fixed-point range.
    ///
    /// Returns `nil` if the value cannot be converted to `Int64` or if
    /// scaling by 10⁸ would overflow.
    ///
    /// ```swift
    /// let v = FixedPointDecimal(exactly: 42)     // Optional(42.0)
    /// let big = FixedPointDecimal(exactly: Int64.max)  // nil (overflow)
    /// ```
    ///
    /// - Parameter source: The integer value to represent.
    /// - Returns: A `FixedPointDecimal` if the value fits, otherwise `nil`.
    @inlinable
    public init?<T: BinaryInteger>(exactly source: T) {
        guard let int64 = Int64(exactly: source) else { return nil }
        let (result, overflow) = int64.multipliedReportingOverflow(by: Self.scaleFactor)
        guard !overflow, result != .min else { return nil }
        self._storage = result
    }

    // * and *= are defined in FixedPointDecimal+Arithmetic.swift

    /// Returns the additive inverse of this value.
    ///
    /// Returns NaN if the operand is NaN, matching the behavior of all
    /// arithmetic operators on this type.
    ///
    /// ```swift
    /// let price = FixedPointDecimal("42.5")!
    /// let neg = -price  // -42.5
    /// (-FixedPointDecimal.nan).isNaN  // true
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value, or NaN if the operand is NaN.
    @inlinable
    public prefix static func - (operand: Self) -> Self {
        if operand.isNaN { return .nan }
        return Self(rawValue: -operand._storage)
    }

    /// Replaces this value with its additive inverse.
    ///
    /// If the value is NaN, this is a no-op (NaN is preserved).
    ///
    /// ```swift
    /// var price = FixedPointDecimal("42.5")!
    /// price.negate()
    /// // price is now -42.5
    /// ```
    @inlinable
    public mutating func negate() {
        if isNaN { return }
        _storage = -_storage
    }
}
