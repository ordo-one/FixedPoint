public import Synchronization

/// A fixed-point decimal number with 8 fractional digits, backed by a 64-bit integer.
///
/// `FixedPointDecimal` stores values as a signed 64-bit integer scaled by 10⁸.
/// The value `1.23` is stored internally as `123_000_000`.
///
/// This type provides exact decimal arithmetic for financial calculations,
/// avoiding the overhead of `Foundation.Decimal`'s variable-precision arithmetic
/// while maintaining the precision needed for price and quantity representation.
///
/// ## Range
///
/// - Minimum: `-92_233_720_368.54775807`
/// - Maximum:  `92_233_720_368.54775807`
///
/// ## Precision
///
/// All values are represented with exactly 8 fractional decimal digits.
/// The smallest representable positive value is `0.00000001`.
///
/// ## Performance
///
/// All arithmetic operations compile to native integer instructions.
/// Addition and subtraction are single `add`/`sub` instructions.
/// Comparison is a single integer compare.
/// No heap allocations occur under any circumstances.
///
/// ## Overflow
///
/// Arithmetic operators (`+`, `-`, `*`, `/`) trap on overflow, matching Swift `Int`.
/// Wrapping operators (`&+`, `&-`) and overflow-reporting methods are available
/// for performance-critical code paths.
@frozen
public struct FixedPointDecimal: Sendable, BitwiseCopyable {
    @usableFromInline
    internal var _storage: Int64

    /// The number of fractional decimal digits (always 8).
    @usableFromInline
    internal static var fractionalDigitCount: Int { 8 }

    /// The scale factor: 10⁸ = 100,000,000.
    @usableFromInline
    internal static var scaleFactor: Int64 { 100_000_000 }

    /// Creates a value from its raw scaled integer representation.
    ///
    /// The raw value is the desired decimal value multiplied by 10⁸.
    /// For example, `FixedPointDecimal(rawValue: 123_000_000)` represents `1.23`.
    ///
    /// This initializer is used for binary serialization and interop.
    /// Prefer `FixedPointDecimal("1.23")` or literal syntax for general use.
    @inlinable
    public init(rawValue: Int64) {
        self._storage = rawValue
    }

    /// The raw scaled integer storage (value x 10⁸).
    ///
    /// Useful for binary serialization and interop with C/C++ code.
    @inlinable
    public var rawValue: Int64 { _storage }

    /// Creates a zero value.
    ///
    /// ```swift
    /// let zero = FixedPointDecimal()
    /// zero == .zero  // true
    /// ```
    @inlinable
    public init() {
        self._storage = 0
    }

    // MARK: - Integer initializers

    /// Creates a value from a binary integer.
    ///
    /// Traps if the result would overflow `Int64` after scaling.
    ///
    /// ```swift
    /// let price = FixedPointDecimal(42)   // 42.00000000
    /// let big   = FixedPointDecimal(Int64(1_000_000))  // 1000000.0
    /// ```
    ///
    /// - Parameter value: The integer value to represent.
    /// - Precondition: The scaled result must fit in `Int64`.
    @inlinable
    public init<T: BinaryInteger>(_ value: T) {
        let int64 = Int64(value)
        let (result, overflow) = int64.multipliedReportingOverflow(by: Self.scaleFactor)
        precondition(!overflow, "Integer value \(value) overflows FixedPointDecimal range")
        precondition(result != .min, "Integer value \(value) maps to NaN sentinel")
        self._storage = result
    }

    // init?(exactly:) for BinaryInteger is provided by Numeric conformance
    // in FixedPointDecimal+Numeric.swift

    /// Creates a value from separate integer and fractional parts.
    ///
    /// The `fraction` parameter is the fractional digits scaled by 10⁸.
    ///
    /// ```swift
    /// let v = FixedPointDecimal(integer: 123, fraction: 45_000_000)
    /// // v represents 123.45
    ///
    /// let neg = FixedPointDecimal(integer: -1, fraction: 50_000_000)
    /// // neg represents -1.5
    /// ```
    ///
    /// - Note: `init(integer: -1, fraction: 0)` produces `-1.0`, which is correct.
    ///   However, values like `-0.5` cannot be constructed this way because `-0` equals `0`,
    ///   so the sign is lost. Use `FixedPointDecimal("-0.5")` or
    ///   `FixedPointDecimal(rawValue: -50_000_000)` instead.
    ///
    /// - Parameters:
    ///   - integer: The integer part.
    ///   - fraction: The fractional part, scaled by 10⁸ (0 ..< 100_000_000).
    /// - Precondition: `fraction` must be in `0 ..< 100_000_000`.
    /// - Precondition: The combined result must fit in `Int64`.
    @inlinable
    public init(integer: Int64, fraction: Int64) {
        precondition(fraction >= 0 && fraction < Self.scaleFactor,
                     "Fractional part must be in 0..<\(Self.scaleFactor)")
        let (scaled, overflow) = integer.multipliedReportingOverflow(by: Self.scaleFactor)
        precondition(!overflow, "Integer part \(integer) overflows FixedPointDecimal range")
        if integer >= 0 {
            let (combined, overflow2) = scaled.addingReportingOverflow(fraction)
            precondition(!overflow2, "FixedPointDecimal(integer:fraction:) overflow")
            precondition(combined != .min, "FixedPointDecimal(integer:fraction:) produced NaN sentinel")
            self._storage = combined
        } else {
            let (combined, overflow2) = scaled.subtractingReportingOverflow(fraction)
            precondition(!overflow2, "FixedPointDecimal(integer:fraction:) overflow")
            precondition(combined != .min, "FixedPointDecimal(integer:fraction:) produced NaN sentinel")
            self._storage = combined
        }
    }

    // MARK: - Significand + exponent initializer

    /// Creates a value from an integer significand and a decimal exponent.
    ///
    /// Computes `significand × 10^exponent` using pure integer arithmetic — no
    /// floating-point imprecision. O(1) via lookup table for exponents that
    /// fit the internal representation directly.
    ///
    /// When the significand has more precision than 8 fractional digits can
    /// represent, the excess is rounded using banker's rounding (round half
    /// to even), consistent with all other entry points.
    ///
    /// This is the preferred way to convert exchange wire formats that transmit
    /// prices as `(integer, exponent)` pairs.
    ///
    /// ```swift
    /// FixedPointDecimal(significand: 12345, exponent: -2)   // 123.45
    /// FixedPointDecimal(significand: 500, exponent: 0)      // 500
    /// FixedPointDecimal(significand: 1, exponent: 3)        // 1000
    /// FixedPointDecimal(significand: 1, exponent: -8)       // 0.00000001
    /// ```
    ///
    /// - Parameters:
    ///   - significand: The integer significand.
    ///   - exponent: The decimal exponent (power of 10 to multiply by).
    /// - Precondition: The result must be representable in `FixedPointDecimal`.
    @inlinable
    public init(significand: Int, exponent: Int) {
        // rawValue = significand × 10^(fractionalDigitCount + exponent)
        let shift = Self.fractionalDigitCount + exponent
        let sig = Int64(significand)
        if shift >= 0, shift < Self._pow10Table.count {
            let (result, overflow) = sig.multipliedReportingOverflow(by: Self._pow10Table[shift])
            precondition(!overflow, "FixedPointDecimal(significand: \(significand), exponent: \(exponent)) overflows")
            precondition(result != .min, "FixedPointDecimal(significand:exponent:) produced NaN sentinel")
            self._storage = result
        } else if shift < 0, -shift < Self._pow10Table.count {
            // Negative shift: banker's rounding for sub-scale precision
            let divisor = Self._pow10Table[-shift]
            let result = Self._bankersDiv(Int128(sig), Int128(divisor))
            self._storage = Int64(result)
        } else {
            preconditionFailure(
                "FixedPointDecimal(significand: \(significand), exponent: \(exponent)): " +
                "effective shift \(shift) out of representable range"
            )
        }
    }

    // MARK: - Special values

    /// The NaN (not-a-number) sentinel value.
    ///
    /// Uses `Int64.min` (-9,223,372,036,854,775,808) as the sentinel because:
    /// - It has no valid negation in `Int64` (negating `Int64.min` overflows)
    /// - It is outside the range of any practical financial value
    /// - Checking `.isNaN` is a single integer comparison
    ///
    /// ```swift
    /// let missing: FixedPointDecimal = .nan
    /// missing.isNaN  // true
    /// ```
    @inlinable
    public static var nan: FixedPointDecimal {
        FixedPointDecimal(rawValue: .min)
    }

    /// A Boolean value indicating whether this value is NaN (not-a-number).
    @inlinable
    public var isNaN: Bool {
        _storage == .min
    }

    /// The zero value.
    @inlinable
    public static var zero: FixedPointDecimal {
        FixedPointDecimal(rawValue: 0)
    }

    /// A Boolean value indicating whether this value is finite (not NaN).
    ///
    /// `FixedPointDecimal` has no infinity representation, so all non-NaN
    /// values are finite.
    @inlinable
    public var isFinite: Bool {
        !isNaN
    }

    /// The sign of this value.
    ///
    /// Returns `.minus` for negative values (including negative zero, which
    /// cannot occur in this type), `.plus` for zero and positive values.
    /// NaN returns `.plus`.
    @inlinable
    public var sign: FloatingPointSign {
        _storage < 0 && !isNaN ? .minus : .plus
    }

    /// The largest representable value: `92,233,720,368.54775807`.
    @inlinable
    public static var max: FixedPointDecimal {
        FixedPointDecimal(rawValue: .max)
    }

    /// The smallest representable value: `-92,233,720,368.54775807`.
    ///
    /// `Int64.min` is reserved as the NaN sentinel, so `.min` uses `Int64.min + 1`.
    @inlinable
    public static var min: FixedPointDecimal {
        FixedPointDecimal(rawValue: .min + 1)
    }

    /// The smallest positive value: `0.00000001`.
    @inlinable
    public static var leastNonzeroMagnitude: FixedPointDecimal {
        FixedPointDecimal(rawValue: 1)
    }

    /// The largest finite magnitude: `92,233,720,368.54775807`.
    ///
    /// Equal to ``max`` since all representable values are finite.
    @inlinable
    public static var greatestFiniteMagnitude: FixedPointDecimal {
        FixedPointDecimal(rawValue: .max)
    }

    /// The least (most negative) finite magnitude: `-92,233,720,368.54775807`.
    ///
    /// Equal to ``min`` since all representable values are finite.
    @inlinable
    public static var leastFiniteMagnitude: FixedPointDecimal {
        min
    }

    /// The unit in the last place (ULP): always `0.00000001`.
    ///
    /// Unlike `Double`, where ULP varies across the range, `FixedPointDecimal`
    /// has uniform precision — the distance between any two adjacent
    /// representable values is always `0.00000001`.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public var ulp: FixedPointDecimal {
        precondition(!isNaN, "ulp called on NaN")
        return .leastNonzeroMagnitude
    }

    /// The least representable value greater than this one.
    ///
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The value must be less than `.max`.
    @inlinable
    public var nextUp: FixedPointDecimal {
        precondition(!isNaN, "nextUp called on NaN")
        precondition(self < .max, "nextUp called on .max")
        return FixedPointDecimal(rawValue: _storage + 1)
    }

    /// The greatest representable value less than this one.
    ///
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The value must be greater than `.min`.
    @inlinable
    public var nextDown: FixedPointDecimal {
        precondition(!isNaN, "nextDown called on NaN")
        precondition(self > .min, "nextDown called on .min")
        return FixedPointDecimal(rawValue: _storage - 1)
    }

    // MARK: - Value access

    /// The integer part, truncated toward zero.
    ///
    /// - Precondition: The value must not be NaN.
    @usableFromInline
    internal var integerPart: Int64 {
        precondition(!isNaN, "Cannot access integerPart of NaN")
        return _storage / Self.scaleFactor
    }

    /// The fractional part as a scaled integer (0..<10^8).
    ///
    /// - Precondition: The value must not be NaN.
    @usableFromInline
    internal var fractionalPart: Int64 {
        precondition(!isNaN, "Cannot access fractionalPart of NaN")
        return _storage % Self.scaleFactor
    }

    // MARK: - Fractional digit count

    /// The number of meaningful fractional digits (0–8), excluding trailing zeros.
    ///
    /// Pure integer arithmetic, O(8) worst case, zero allocation.
    ///
    /// ```swift
    /// FixedPointDecimal(123.45).numberOfFractionalDigits       // 2
    /// FixedPointDecimal(100).numberOfFractionalDigits           // 0
    /// FixedPointDecimal(0.00000001).numberOfFractionalDigits    // 8
    /// FixedPointDecimal.nan.numberOfFractionalDigits // 0
    /// ```
    @inlinable
    public var numberOfFractionalDigits: Int {
        guard !isNaN else { return 0 }
        var frac = abs(_storage % Self.scaleFactor)
        if frac == 0 { return 0 }
        var trailingZeros = 0
        while frac % 10 == 0 {
            frac /= 10
            trailingZeros &+= 1
        }
        return Self.fractionalDigitCount - trailingZeros
    }

    // MARK: - Power of 10 helper

    /// Lookup table for 10^0 through 10^18 (the full Int64 range).
    @usableFromInline
    internal static let _pow10Table: [Int64] = [
        1,                          // 10^0
        10,                         // 10^1
        100,                        // 10^2
        1_000,                      // 10^3
        10_000,                     // 10^4
        100_000,                    // 10^5
        1_000_000,                  // 10^6
        10_000_000,                 // 10^7
        100_000_000,                // 10^8
        1_000_000_000,              // 10^9
        10_000_000_000,             // 10^10
        100_000_000_000,            // 10^11
        1_000_000_000_000,          // 10^12
        10_000_000_000_000,         // 10^13
        100_000_000_000_000,        // 10^14
        1_000_000_000_000_000,      // 10^15
        10_000_000_000_000_000,     // 10^16
        100_000_000_000_000_000,    // 10^17
        1_000_000_000_000_000_000,  // 10^18
    ]

    @usableFromInline
    internal static func _powerOf10(_ exponent: Int) -> Int64 {
        precondition(exponent >= 0 && exponent < _pow10Table.count,
                     "Exponent \(exponent) out of range 0...\(_pow10Table.count - 1)")
        return _pow10Table[exponent]
    }

    // MARK: - Integer exponentiation

    /// Raises a value to an integer power.
    ///
    /// Uses repeated multiplication — no floating-point imprecision.
    /// Follows the swift-numerics `ElementaryFunctions` naming convention.
    ///
    /// Negative exponents compute the reciprocal: `pow(x, -n) == 1 / pow(x, n)`.
    /// Returns `.nan` if the base is NaN, or if the result overflows Int64 storage.
    ///
    /// ```swift
    /// FixedPointDecimal.pow(10, 3)     // 1000
    /// FixedPointDecimal.pow(2, 10)     // 1024
    /// FixedPointDecimal.pow(10, -2)    // 0.01
    ///
    /// // In type-inferred context:
    /// let divisor: FixedPointDecimal = .pow(10, 3)
    /// priceFactor /= .pow(10, minorUnits)
    /// ```
    ///
    /// - Parameters:
    ///   - x: The base value.
    ///   - n: The integer exponent (positive, zero, or negative).
    /// - Returns: `x` raised to the power `n`.
    @inlinable
    public static func pow(_ x: FixedPointDecimal, _ n: Int) -> FixedPointDecimal {
        precondition(!x.isNaN, "NaN in FixedPointDecimal pow")

        if n == 0 { return FixedPointDecimal(rawValue: scaleFactor) } // 1
        if n == 1 { return x }

        // Fast path: pow(10, n) via lookup table — O(1) instead of n-1 multiplications.
        if x._storage == 10 &* scaleFactor {
            let shift = fractionalDigitCount + n
            if shift >= 0, shift < _pow10Table.count {
                return FixedPointDecimal(rawValue: _pow10Table[shift])
            }
            precondition(shift < 0, "FixedPointDecimal pow overflow")
            return .zero
        }

        if n < 0 {
            let positive = pow(x, -n)
            precondition(positive != .zero, "Division by zero in FixedPointDecimal pow")
            return FixedPointDecimal(rawValue: scaleFactor) / positive
        }

        // Repeated multiplication — traps on overflow via `*`.
        var result = x
        for _ in 1 ..< n {
            result = result * x
        }
        return result
    }
}

// MARK: - AtomicRepresentable

/// Conformance to `AtomicRepresentable`, enabling lock-free atomic operations
/// via the `Synchronization` module.
///
/// ```swift
/// import Synchronization
///
/// let price = Atomic<FixedPointDecimal>(FixedPointDecimal("100.0")!)
/// price.store(FixedPointDecimal("101.5")!, ordering: .releasing)
/// let current = price.load(ordering: .acquiring)
/// ```
extension FixedPointDecimal: AtomicRepresentable {
    /// The underlying atomic storage type, delegating to `Int64`'s atomic representation.
    public typealias AtomicRepresentation = Int64.AtomicRepresentation

    /// Encodes a `FixedPointDecimal` for atomic storage.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: The atomic representation of the underlying `Int64` storage.
    @inlinable
    public static func encodeAtomicRepresentation(_ value: consuming FixedPointDecimal) -> AtomicRepresentation {
        Int64.encodeAtomicRepresentation(value._storage)
    }

    /// Decodes a `FixedPointDecimal` from atomic storage.
    ///
    /// - Parameter representation: The atomic representation to decode.
    /// - Returns: The `FixedPointDecimal` value.
    @inlinable
    public static func decodeAtomicRepresentation(_ representation: consuming AtomicRepresentation) -> FixedPointDecimal {
        FixedPointDecimal(rawValue: Int64.decodeAtomicRepresentation(representation))
    }
}
