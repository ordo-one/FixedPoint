// MARK: - Strideable

/// Conformance to `Strideable`, enabling `stride(from:to:by:)` and range operations.
extension FixedPointDecimal: Strideable {
    public typealias Stride = FixedPointDecimal
}

extension FixedPointDecimal {
    /// Returns the distance from this value to the given value.
    ///
    /// ```swift
    /// let a = FixedPointDecimal("10.0")!
    /// let b = FixedPointDecimal("13.5")!
    /// a.distance(to: b)  // 3.5
    /// ```
    ///
    /// - Parameter other: The value to compute the distance to.
    /// - Returns: The distance from `self` to `other` (i.e., `other - self`).
    @inlinable
    public func distance(to other: Self) -> Self {
        other - self
    }

    /// Returns a value that is offset from this value by the given distance.
    ///
    /// ```swift
    /// let a = FixedPointDecimal("10.0")!
    /// let b = FixedPointDecimal("0.5")!
    /// a.advanced(by: b)  // 10.5
    /// ```
    ///
    /// - Parameter n: The distance to advance.
    /// - Returns: A value offset by `n` from this value (i.e., `self + n`).
    @inlinable
    public func advanced(by n: Self) -> Self {
        self + n
    }
}
