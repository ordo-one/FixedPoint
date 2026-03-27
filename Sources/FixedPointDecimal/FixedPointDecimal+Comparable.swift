// MARK: - Equatable

extension FixedPointDecimal: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// NaN compares equal to itself, using sentinel semantics (not IEEE 754).
    /// This is required for `Hashable` and `Comparable` protocol correctness
    /// (strict total order).
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.5"
    /// let b: FixedPointDecimal = "10.5"
    /// a == b  // true
    ///
    /// FixedPointDecimal.nan == .nan  // true (sentinel semantics)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if the two values have the same raw storage.
    /// - Complexity: O(1) -- single integer comparison.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._storage == rhs._storage
    }
}

// MARK: - Comparable

extension FixedPointDecimal: Comparable {
    /// Returns a Boolean value indicating whether the first value is less than
    /// the second.
    ///
    /// NaN (`Int64.min`) compares less than all non-NaN values, providing
    /// a strict total order suitable for sorting.
    ///
    /// ```swift
    /// let a: FixedPointDecimal = "10.0"
    /// let b: FixedPointDecimal = "20.0"
    /// a < b  // true
    ///
    /// FixedPointDecimal.nan < a  // true (NaN sorts before all values)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if `lhs` is strictly less than `rhs`.
    /// - Complexity: O(1) -- single integer comparison.
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - Hashable

extension FixedPointDecimal: Hashable {
    /// Hashes the raw storage value into the given hasher.
    ///
    /// Two values that compare equal with `==` always produce the same hash,
    /// satisfying the `Hashable` contract.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_storage)
    }
}
