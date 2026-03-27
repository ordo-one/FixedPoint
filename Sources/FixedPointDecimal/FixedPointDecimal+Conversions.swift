// MARK: - Double Conversions (pure Swift -- no Foundation dependency)

extension FixedPointDecimal {
    /// Creates a value from a `Double`.
    ///
    /// The value is rounded to 8 decimal places using banker's rounding
    /// (round half to even), matching the rounding policy used by all
    /// other entry points (string parsing, `Decimal` conversion, arithmetic).
    ///
    /// This conversion is inherently imprecise due to binary floating-point
    /// representation, but the error is bounded to +/-5x10^-9 (sub-tick
    /// for all practical financial instruments).
    ///
    /// ```swift
    /// let price = FixedPointDecimal(123.45)  // 123.45000000
    /// let half  = FixedPointDecimal(0.5)     // 0.5
    /// ```
    ///
    /// - Parameter value: The `Double` value to convert.
    /// - Precondition: `value` must not be `Double.nan` or infinite.
    @inlinable
    public init(_ value: Double) {
        precondition(!value.isNaN, "Cannot create FixedPointDecimal from Double.nan; use .nan instead")
        precondition(!value.isInfinite, "Cannot create FixedPointDecimal from infinity")
        let scaled = (value * Double(Self.scaleFactor)).rounded(.toNearestOrEven)
        let storage = Int64(scaled)  // traps if out of range — matches Swift Int behavior
        precondition(storage != .min, "Double value \(value) maps to NaN sentinel")
        self._storage = storage
    }

    /// Creates a value from a `Double`, returning `nil` if the result would
    /// overflow or if the input is NaN or infinite.
    ///
    /// ```swift
    /// let v = FixedPointDecimal(exactly: 123.45)    // Optional(123.45)
    /// let bad = FixedPointDecimal(exactly: .nan)     // nil
    /// let inf = FixedPointDecimal(exactly: .infinity) // nil
    /// ```
    ///
    /// - Parameter value: The `Double` value to convert.
    /// - Returns: A `FixedPointDecimal` if the value is representable, otherwise `nil`.
    @inlinable
    public init?(exactly value: Double) {
        if value.isNaN || value.isInfinite { return nil }
        let scaled = (value * Double(Self.scaleFactor)).rounded(.toNearestOrEven)
        // Int64.init(_: Double) traps on out-of-range, so check bounds first.
        // Double cannot exactly represent Int64.max (9223372036854775807),
        // but Double(Int64.max) rounds up to the next representable value.
        let upperBound = Double(sign: .plus, exponent: 63, significand: 1.0) // 2^63 = 9223372036854775808.0
        guard scaled >= Double(Int64.min + 1) && scaled < upperBound else { return nil }
        let storage = Int64(scaled)
        guard storage != .min else { return nil }
        // Verify exactness: round-trip must reproduce the original Double
        guard Double(storage) / Double(Self.scaleFactor) == value else { return nil }
        self._storage = storage
    }

    /// The value as a `Double`. Backwards-compatibility convenience for `Double(self)`.
    ///
    /// Exact for values with 15 or fewer significant digits (all practical
    /// financial values). Returns `Double.nan` for NaN.
    @inlinable
    public var doubleValue: Double {
        if isNaN { return .nan }
        return Double(_storage) / Double(Self.scaleFactor)
    }
}

// MARK: - Integer Conversions

extension Int {
    /// Creates an `Int` from a `FixedPointDecimal`, truncating the fractional part.
    ///
    /// The fractional part is discarded (truncated toward zero),
    /// matching `Int(someDouble)` semantics.
    ///
    /// ```swift
    /// let v = FixedPointDecimal("42.99")!
    /// Int(v)  // 42
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init(_ value: FixedPointDecimal) {
        precondition(!value.isNaN, "Cannot convert NaN to Int")
        self = Int(value.rawValue / FixedPointDecimal.scaleFactor)
    }

    /// Creates an `Int` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN or has a non-zero fractional part.
    ///
    /// ```swift
    /// Int(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int(exactly: FixedPointDecimal("42.5")!)   // nil
    /// Int(exactly: FixedPointDecimal.nan)         // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: FixedPointDecimal) {
        if value.isNaN { return nil }
        guard value.fractionalPart == 0 else { return nil }
        self = Int(value.rawValue / FixedPointDecimal.scaleFactor)
    }
}

extension Int64 {
    /// Creates an `Int64` from a `FixedPointDecimal`, truncating the fractional part.
    ///
    /// The fractional part is discarded (truncated toward zero).
    ///
    /// ```swift
    /// let v = FixedPointDecimal("-7.9")!
    /// Int64(v)  // -7
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init(_ value: FixedPointDecimal) {
        precondition(!value.isNaN, "Cannot convert NaN to Int64")
        self = value.rawValue / FixedPointDecimal.scaleFactor
    }

    /// Creates an `Int64` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN or has a non-zero fractional part.
    ///
    /// ```swift
    /// Int64(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int64(exactly: FixedPointDecimal("42.5")!)   // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int64` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: FixedPointDecimal) {
        if value.isNaN { return nil }
        guard value.fractionalPart == 0 else { return nil }
        self = value.rawValue / FixedPointDecimal.scaleFactor
    }
}

extension Int32 {
    /// Creates an `Int32` from a `FixedPointDecimal`, truncating the fractional part.
    ///
    /// The fractional part is discarded (truncated toward zero).
    /// Traps if the integer part exceeds `Int32` range.
    ///
    /// ```swift
    /// let v = FixedPointDecimal("42.99")!
    /// Int32(v)  // 42
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The integer part must fit in `Int32`.
    @inlinable
    public init(_ value: FixedPointDecimal) {
        precondition(!value.isNaN, "Cannot convert NaN to Int32")
        let intPart = value.rawValue / FixedPointDecimal.scaleFactor
        precondition(intPart >= Int64(Int32.min) && intPart <= Int64(Int32.max),
                     "FixedPointDecimal integer part \(intPart) exceeds Int32 range")
        self = Int32(intPart)
    }

    /// Creates an `Int32` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN, has a non-zero fractional part, or exceeds `Int32` range.
    ///
    /// ```swift
    /// Int32(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int32(exactly: FixedPointDecimal("42.5")!)   // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int32` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: FixedPointDecimal) {
        if value.isNaN { return nil }
        guard value.fractionalPart == 0 else { return nil }
        guard let narrow = Int32(exactly: value.rawValue / FixedPointDecimal.scaleFactor) else { return nil }
        self = narrow
    }
}
