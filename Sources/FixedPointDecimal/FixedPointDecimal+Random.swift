// MARK: - Random Value Generation

extension FixedPointDecimal {
    /// Returns a random value within the specified range.
    ///
    /// ```swift
    /// let price = FixedPointDecimal.random(in: FixedPointDecimal(10.0) ..< FixedPointDecimal(20.0))
    /// ```
    ///
    /// - Precondition: Neither bound may be NaN.
    /// - Precondition: The range must not be empty.
    @inlinable
    public static func random(in range: Range<FixedPointDecimal>) -> FixedPointDecimal {
        precondition(!range.lowerBound.isNaN && !range.upperBound.isNaN,
                     "Cannot generate random value from a range containing NaN")
        let lower = range.lowerBound.rawValue
        let upper = range.upperBound.rawValue
        precondition(lower < upper, "Range must not be empty")
        let raw = Int64.random(in: lower ..< upper)
        return FixedPointDecimal(rawValue: raw)
    }

    /// Returns a random value within the specified closed range.
    ///
    /// ```swift
    /// let price = FixedPointDecimal.random(in: FixedPointDecimal(10.0) ... FixedPointDecimal(20.0))
    /// ```
    ///
    /// - Precondition: Neither bound may be NaN.
    /// - Precondition: The range bounds must be in order.
    @inlinable
    public static func random(in range: ClosedRange<FixedPointDecimal>) -> FixedPointDecimal {
        precondition(!range.lowerBound.isNaN && !range.upperBound.isNaN,
                     "Cannot generate random value from a range containing NaN")
        let lower = range.lowerBound.rawValue
        let upper = range.upperBound.rawValue
        precondition(lower <= upper, "Range bounds must be in order")
        let raw = Int64.random(in: lower ... upper)
        return FixedPointDecimal(rawValue: raw)
    }
}

// MARK: - FixedWidthInteger exact conversion from FixedPointDecimal

extension FixedWidthInteger where Self: SignedInteger {
    /// Creates an integer from a `FixedPointDecimal`, returning `nil` if the value
    /// is not an exact integer or is out of range.
    public init?(exactly value: FixedPointDecimal) {
        guard !value.isNaN else { return nil }
        let raw = value.rawValue
        let scale = FixedPointDecimal.scaleFactor
        guard raw % scale == 0 else { return nil } // not an exact integer
        let intVal = raw / scale
        guard intVal >= Self.min, intVal <= Self.max else { return nil }
        self.init(intVal)
    }
}

extension FixedWidthInteger where Self: UnsignedInteger {
    /// Creates an unsigned integer from a `FixedPointDecimal`, returning `nil` if the value
    /// is not an exact integer, is negative, or is out of range.
    public init?(exactly value: FixedPointDecimal) {
        guard !value.isNaN else { return nil }
        let raw = value.rawValue
        let scale = FixedPointDecimal.scaleFactor
        guard raw % scale == 0 else { return nil } // not an exact integer
        let intVal = raw / scale
        guard intVal >= 0 else { return nil }
        let uintVal = UInt64(intVal)
        guard uintVal <= Self.max else { return nil }
        self.init(uintVal)
    }
}
