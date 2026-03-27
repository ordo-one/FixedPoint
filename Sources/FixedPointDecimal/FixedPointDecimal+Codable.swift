// MARK: - Codable

/// Conformance to `Codable` for serialization and deserialization.
///
/// Encoding uses a human-readable `String` representation. Decoding accepts
/// `String`, `Int64` (face value), or `Double` for flexibility with external APIs.
///
/// ```swift
/// let price: FixedPointDecimal = "99.95"
/// let data = try JSONEncoder().encode(price)
/// // JSON: "99.95"
/// let decoded = try JSONDecoder().decode(FixedPointDecimal.self, from: data)
/// // decoded == price
/// ```
extension FixedPointDecimal: Codable {
    /// Encodes this value as a human-readable `String` (e.g. `"123.45"`, `"nan"`).
    ///
    /// This produces readable JSON and preserves exact precision for all values
    /// including `.max` (`"92233720368.54775807"`), which cannot round-trip
    /// through a JSON number without precision loss.
    ///
    /// For binary wire formats (FlatBuffers), use the separate `StructSerializable`
    /// protocol which encodes as a raw `Int64` scalar.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Decodes a value from the given decoder.
    ///
    /// Supports multiple input formats for interoperability:
    /// - JSON string `"123.45"` -- parsed as a decimal string
    /// - JSON integer `123` -- interpreted as the face value 123 (not raw storage)
    /// - JSON decimal `123.45` -- converted from `Double`
    /// - JSON string `"nan"` -- decoded as NaN
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: `DecodingError` if the value cannot be decoded.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try String first — our canonical encoding format, also handles "nan"
        if let string = try? container.decode(String.self) {
            guard let parsed = FixedPointDecimal(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid FixedPointDecimal string: \(string)"
                )
            }
            self = parsed
            return
        }

        // Try Int64 — JSON integer, interpreted as FACE VALUE (not raw storage).
        // JSON 123 means the number 123.0, not rawValue 123 (= 0.00000123).
        if let int64 = try? container.decode(Int64.self) {
            let (scaled, overflow) = int64.multipliedReportingOverflow(by: Self.scaleFactor)
            guard !overflow, scaled != .min else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Integer value \(int64) overflows FixedPointDecimal range"
                )
            }
            self._storage = scaled
            return
        }

        // Try Double — JSON numbers with decimal points from external APIs.
        // Uses the rounding init (not exactly:) because JSON doubles are
        // inherently imprecise — rejecting sub-tick rounding would break
        // interoperability with external APIs.
        if let double = try? container.decode(Double.self) {
            // Use the failable rounding initializer to avoid trapping on
            // out-of-range values (e.g. 1e40). NaN/infinity are also rejected.
            guard let parsed = FixedPointDecimal(exactly: double) else {
                // Fallback: try rounding init for in-range but inexact doubles.
                // The exactly: check above rejects both out-of-range AND inexact,
                // but for JSON interop we want to accept inexact-but-in-range.
                guard !double.isNaN, !double.isInfinite else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Double value \(double) cannot be represented as FixedPointDecimal"
                    )
                }
                let scaled = (double * Double(Self.scaleFactor)).rounded(.toNearestOrEven)
                let upperBound = Double(sign: .plus, exponent: 63, significand: 1.0)
                guard scaled >= Double(Int64.min + 1), scaled < upperBound else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Double value \(double) overflows FixedPointDecimal range"
                    )
                }
                let storage = Int64(scaled)
                // Double(Int64.min + 1) == Double(Int64.min) due to precision,
                // so the bounds check above can't distinguish them. Reject the
                // NaN sentinel explicitly.
                guard storage != .min else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Double value \(double) overflows FixedPointDecimal range"
                    )
                }
                self._storage = storage
                return
            }
            self = parsed
            return
        }

        throw DecodingError.typeMismatch(
            FixedPointDecimal.self,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Expected String, Int64, or Double for FixedPointDecimal"
            )
        )
    }
}
