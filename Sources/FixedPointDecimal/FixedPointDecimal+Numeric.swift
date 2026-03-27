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
    /// Traps on NaN.
    ///
    /// ```swift
    /// let v = FixedPointDecimal("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    /// - Precondition: The value must not be NaN.
    @inlinable
    public var magnitude: Magnitude {
        precondition(!isNaN, "magnitude called on NaN")
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
    /// Traps if the operand is NaN.
    ///
    /// ```swift
    /// let price = FixedPointDecimal("42.5")!
    /// let neg = -price  // -42.5
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    /// - Precondition: The operand must not be NaN.
    @inlinable
    public prefix static func - (operand: Self) -> Self {
        precondition(!operand.isNaN, "NaN in FixedPointDecimal negation")
        return Self(rawValue: -operand._storage)
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Traps if the value is NaN.
    ///
    /// ```swift
    /// var price = FixedPointDecimal("42.5")!
    /// price.negate()
    /// // price is now -42.5
    /// ```
    /// - Precondition: The value must not be NaN.
    @inlinable
    public mutating func negate() {
        precondition(!isNaN, "NaN in FixedPointDecimal negation")
        _storage = -_storage
    }
}
