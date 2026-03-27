#if canImport(SwiftUI)
public import SwiftUI

// MARK: - VectorArithmetic (enables SwiftUI animations)

/// Conformance to `VectorArithmetic`, enabling SwiftUI animation interpolation.
///
/// ```swift
/// // In a SwiftUI view, animated transitions between prices work automatically:
/// struct PriceView: View {
///     var price: FixedPointDecimal
///     var body: some View {
///         Text(price.description)
///     }
/// }
/// ```
extension FixedPointDecimal: VectorArithmetic {
    /// Scales the raw value by a `Double` factor. Used by SwiftUI's animation system.
    ///
    /// The result is clamped to the valid range (`Int64.min + 1 ... Int64.max`)
    /// to avoid producing the NaN sentinel. NaN values are left unchanged.
    ///
    /// - Parameter rhs: The scaling factor.
    @inlinable
    public mutating func scale(by rhs: Double) {
        if isNaN { return }
        let scaled = Double(rawValue) * rhs
        if scaled >= Double(Int64.max) {
            self = Self(rawValue: .max)
        } else if scaled <= Double(Int64.min + 1) {
            self = Self(rawValue: .min + 1)  // clamp to valid min, avoid NaN sentinel
        } else {
            let v = Int64(scaled.rounded())
            self = Self(rawValue: v == .min ? .min + 1 : v)
        }
    }

    /// The squared magnitude of the raw storage, used by SwiftUI for
    /// animation interpolation.
    ///
    /// Returns `Double.nan` for NaN values.
    @inlinable
    public var magnitudeSquared: Double {
        if isNaN { return .nan }
        let d = Double(rawValue)
        return d * d
    }
}
#endif

#if canImport(SwiftUI) && canImport(Charts)
public import Charts

// MARK: - Plottable (enables Swift Charts)

/// Conformance to `Plottable`, enabling direct use in Swift Charts.
///
/// ```swift
/// Chart(data) { item in
///     LineMark(
///         x: .value("Time", item.timestamp),
///         y: .value("Price", item.price)  // FixedPointDecimal
///     )
/// }
/// ```
extension FixedPointDecimal: Plottable {
    /// The `Double` representation used for plotting.
    public var primitivePlottable: Double {
        Double(self)
    }

    /// Creates a value from its plottable `Double` representation.
    ///
    /// Returns `nil` if the `Double` cannot be exactly represented.
    ///
    /// - Parameter primitivePlottable: The `Double` value from the chart.
    public init?(primitivePlottable: Double) {
        self.init(exactly: primitivePlottable)
    }
}
#endif

#if canImport(Foundation)
public import Foundation

// MARK: - FormatStyle

/// A format style for `FixedPointDecimal` values.
///
/// Conforms to both `FormatStyle` and `ParseableFormatStyle`, making it
/// compatible with SwiftUI's `TextField` and `Text` views.
///
/// ```swift
/// let price: FixedPointDecimal = "123.45"
/// price.formatted(.fixedPointDecimal)                     // "123.45"
/// price.formatted(.fixedPointDecimal.precision(2))        // "123.45"
/// price.formatted(.fixedPointDecimal.precision(4))        // "123.4500"
///
/// // In SwiftUI:
/// TextField("Price", value: $price, format: .fixedPointDecimal)
/// ```
public struct FixedPointDecimalFormatStyle: Sendable {
    /// The number of fractional digits to display.
    /// If nil, trailing zeros are trimmed (default behavior).
    public var fractionDigits: Int?

    /// Creates a format style.
    ///
    /// - Parameter fractionDigits: The number of fractional digits to display
    ///   (0–8). If nil, trailing zeros are trimmed.
    /// - Precondition: `fractionDigits` must be in `0...8` if specified.
    public init(fractionDigits: Int? = nil) {
        if let digits = fractionDigits {
            precondition(digits >= 0 && digits <= FixedPointDecimal.fractionalDigitCount,
                         "fractionDigits must be in 0...\(FixedPointDecimal.fractionalDigitCount), got \(digits)")
        }
        self.fractionDigits = fractionDigits
    }

    /// Returns a style that displays exactly the specified number of fractional digits.
    ///
    /// ```swift
    /// let style = FixedPointDecimalFormatStyle().precision(4)
    /// style.format(FixedPointDecimal("1.5")!)  // "1.5000"
    /// ```
    ///
    /// - Parameter digits: The number of fractional digits to display (0–8).
    /// - Returns: A new style with the specified precision.
    /// - Precondition: `digits` must be in `0...8`.
    public func precision(_ digits: Int) -> Self {
        precondition(digits >= 0 && digits <= FixedPointDecimal.fractionalDigitCount,
                     "precision must be in 0...\(FixedPointDecimal.fractionalDigitCount), got \(digits)")
        var copy = self
        copy.fractionDigits = digits
        return copy
    }
}

extension FixedPointDecimalFormatStyle: FormatStyle {
    /// Formats a `FixedPointDecimal` value as a `String`.
    ///
    /// When `fractionDigits` is specified, the value is first rounded to that
    /// scale using banker's rounding (round half to even), then formatted with
    /// exactly that many fractional digits. This matches Foundation's
    /// `Decimal.FormatStyle` behavior.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: The formatted string representation.
    public func format(_ value: FixedPointDecimal) -> String {
        if value.isNaN { return "nan" }

        guard let digits = fractionDigits else {
            // Default: use description (trimmed trailing zeros)
            return value.description
        }

        // Round to requested precision using banker's rounding, then format
        let rounded = value.rounded(scale: digits)
        let desc = rounded.description
        guard let dotIndex = desc.firstIndex(of: ".") else {
            return digits > 0 ? desc + "." + String(repeating: "0", count: digits) : desc
        }
        let fracPart = desc[desc.index(after: dotIndex)...]
        let currentDigits = fracPart.count
        if currentDigits == digits {
            return desc
        } else if currentDigits < digits {
            return desc + String(repeating: "0", count: digits - currentDigits)
        } else {
            // After rounding, this branch handles trailing-zero trimming
            // in description that left fewer digits than we need to show
            let truncEnd = desc.index(dotIndex, offsetBy: digits + 1)
            return digits > 0 ? String(desc[...desc.index(before: truncEnd)]) : String(desc[..<dotIndex])
        }
    }
}

extension FixedPointDecimalFormatStyle: ParseableFormatStyle {
    /// The parse strategy used to convert strings back to `FixedPointDecimal` values.
    public var parseStrategy: FixedPointDecimalParseStrategy {
        FixedPointDecimalParseStrategy()
    }
}

/// A parse strategy for `FixedPointDecimal` values.
///
/// Parses decimal strings using the same rules as `FixedPointDecimal.init(_:)` for `String`.
///
/// ```swift
/// let strategy = FixedPointDecimalParseStrategy()
/// let value = try strategy.parse("123.45")  // FixedPointDecimal(123.45)
/// ```
public struct FixedPointDecimalParseStrategy: ParseStrategy, Sendable {
    /// Parses a string into a `FixedPointDecimal`.
    ///
    /// - Parameter value: The string to parse.
    /// - Returns: The parsed `FixedPointDecimal` value.
    /// - Throws: `CocoaError(.formatting)` if the string is not a valid decimal.
    public func parse(_ value: String) throws -> FixedPointDecimal {
        guard let result = FixedPointDecimal(value) else {
            throw CocoaError(.formatting)
        }
        return result
    }
}

// MARK: - Integration with FormatStyle protocol

extension FixedPointDecimal {
    /// Formats this value using the given format style.
    ///
    /// ```swift
    /// let price: FixedPointDecimal = "123.45"
    /// price.formatted(.fixedPointDecimal.precision(4))  // "123.4500"
    /// ```
    ///
    /// - Parameter style: The format style to use.
    /// - Returns: The formatted string.
    public func formatted(_ style: FixedPointDecimalFormatStyle) -> String {
        style.format(self)
    }

    /// Formats this value using the default format style (trailing zeros trimmed).
    ///
    /// ```swift
    /// let price: FixedPointDecimal = "123.45000000"
    /// price.formatted()  // "123.45"
    /// ```
    ///
    /// - Returns: The formatted string with trailing zeros trimmed.
    public func formatted() -> String {
        description
    }
}

extension FormatStyle where Self == FixedPointDecimalFormatStyle {
    /// A format style for `FixedPointDecimal` values.
    ///
    /// ```swift
    /// let price: FixedPointDecimal = "99.95"
    /// price.formatted(.fixedPointDecimal)  // "99.95"
    /// ```
    public static var fixedPointDecimal: FixedPointDecimalFormatStyle {
        FixedPointDecimalFormatStyle()
    }
}

#endif
