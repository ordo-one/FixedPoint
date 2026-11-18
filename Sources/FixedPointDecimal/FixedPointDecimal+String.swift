// MARK: - UTF-8 Parsing

extension FixedPointDecimal {
    /// Creates a value by parsing UTF-8 encoded decimal bytes.
    ///
    /// Accepts formats: `"123.45"`, `"-0.001"`, `"1000"`, `".5"`, `"-.5"`,
    /// `"nan"`, `"NaN"`. Digits beyond 8 fractional places are rounded using
    /// banker's rounding (round half to even).
    /// Returns `nil` for invalid formats or values outside the representable range.
    ///
    /// This is the primary parsing entry point, operating directly on UTF-8 bytes
    /// for zero-copy parsing from any byte source.
    ///
    /// ```swift
    /// let price = FixedPointDecimal("123.45")   // Optional(123.45)
    /// let neg   = FixedPointDecimal("-0.001")   // Optional(-0.001)
    /// let whole = FixedPointDecimal("1000")     // Optional(1000.0)
    /// let bad   = FixedPointDecimal("abc")      // nil
    /// let nan   = FixedPointDecimal("nan")      // Optional(.nan)
    /// ```
    ///
    /// - Parameter utf8: The UTF-8 bytes to parse.
    /// - Returns: A `FixedPointDecimal` if parsing succeeds, otherwise `nil`.
    @inlinable
    public init?(_ utf8: UnsafeBufferPointer<UInt8>) {
        guard !utf8.isEmpty else { return nil }

        // Handle NaN: "nan" or "NaN"
        if utf8.count == 3 {
            let a = utf8[0], b = utf8[1], c = utf8[2]
            if b == UInt8(ascii: "a") &&
                ((a == UInt8(ascii: "n") && c == UInt8(ascii: "n")) ||
                 (a == UInt8(ascii: "N") && c == UInt8(ascii: "N"))) {
                self = .nan
                return
            }
        }

        var pos = 0

        // Parse sign
        let isNegative: Bool
        switch utf8[pos] {
        case UInt8(ascii: "-"):
            isNegative = true
            pos &+= 1
        case UInt8(ascii: "+"):
            isNegative = false
            pos &+= 1
        default:
            isNegative = false
        }

        guard pos < utf8.count else { return nil }

        // Find decimal point
        var dotPos = -1
        for i in pos..<utf8.count {
            if utf8[i] == UInt8(ascii: ".") {
                dotPos = i
                break
            }
        }

        let intEnd = dotPos >= 0 ? dotPos : utf8.count
        let fracStart = dotPos >= 0 ? dotPos &+ 1 : utf8.count

        // Reject bare dot with no digits on either side
        guard intEnd > pos || fracStart < utf8.count else { return nil }

        // Parse integer part
        var integerValue: Int64 = 0
        for i in pos..<intEnd {
            let digit = utf8[i] &- UInt8(ascii: "0")
            guard digit < 10 else { return nil }
            let (r1, o1) = integerValue.multipliedReportingOverflow(by: 10)
            guard !o1 else { return nil }
            let (r2, o2) = r1.addingReportingOverflow(Int64(digit))
            guard !o2 else { return nil }
            integerValue = r2
        }

        // Parse fractional part (up to 8 digits, zero-padded)
        var fractionValue: Int64 = 0
        let maxFractionDigits = Self.fractionalDigitCount
        var digitCount = 0
        var fracPos = fracStart
        while fracPos < utf8.count, digitCount < maxFractionDigits {
            let digit = utf8[fracPos] &- UInt8(ascii: "0")
            guard digit < 10 else { return nil }
            fractionValue = fractionValue &* 10 &+ Int64(digit)
            digitCount &+= 1
            fracPos &+= 1
        }
        // Pad remaining digits with zeros
        while digitCount < maxFractionDigits {
            fractionValue &*= 10
            digitCount &+= 1
        }

        // Banker's rounding on excess digits (round half to even)
        var roundingDigit: UInt8 = 0
        var hasTrailingNonZero = false
        if fracPos < utf8.count {
            roundingDigit = utf8[fracPos] &- UInt8(ascii: "0")
            guard roundingDigit < 10 else { return nil }
            fracPos &+= 1
            while fracPos < utf8.count {
                let d = utf8[fracPos] &- UInt8(ascii: "0")
                guard d < 10 else { return nil }
                if d != 0 { hasTrailingNonZero = true }
                fracPos &+= 1
            }
        }
        if roundingDigit > 5 || (roundingDigit == 5 && hasTrailingNonZero) {
            fractionValue &+= 1
        } else if roundingDigit == 5 && !hasTrailingNonZero && fractionValue % 2 != 0 {
            fractionValue &+= 1 // exactly half — round to even
        }
        // Handle carry from rounding
        if fractionValue >= Self.scaleFactor {
            fractionValue &-= Self.scaleFactor
            let (newInt, o) = integerValue.addingReportingOverflow(1)
            guard !o else { return nil }
            integerValue = newInt
        }

        // Combine
        let (scaled, overflow) = integerValue.multipliedReportingOverflow(by: Self.scaleFactor)
        guard !overflow else { return nil }
        let (combined, overflow2) = scaled.addingReportingOverflow(fractionValue)
        guard !overflow2 else { return nil }

        if isNegative {
            // Guard against negating Int64.min
            guard combined != .min else { return nil }
            self._storage = -combined
        } else {
            self._storage = combined
        }
    }
}

// MARK: - String Parsing

extension FixedPointDecimal {
    /// Creates a value by parsing a decimal string.
    ///
    /// Delegates to the `UnsafeBufferPointer<UInt8>` initializer via
    /// the string's contiguous UTF-8 bytes.
    ///
    /// - Parameter description: The string to parse.
    /// - Returns: A `FixedPointDecimal` if parsing succeeds, otherwise `nil`.
    @inlinable
    public init?(_ description: String) {
        var str = description
        var result: FixedPointDecimal?
        str.withUTF8 { result = FixedPointDecimal($0) }
        guard let result else { return nil }
        self = result
    }
}

// MARK: - Internal Formatting Helper

extension FixedPointDecimal {
    /// The scratch space `_writeDescription(into:)` needs.
    ///
    /// The longest description is 21 bytes: a sign, 11 integer digits,
    /// a decimal point and 8 fractional digits.
    internal static var _descriptionCapacity: Int { 24 }

    /// Writes the decimal text right-aligned into a scratch buffer.
    ///
    /// The integer digits end just before index 15, the decimal point (when
    /// there is a fraction) is index 15 and the fractional digits follow, so
    /// no digit count is needed up front. Digits are produced two at a time
    /// from a table of the pairs "00" through "99", and trailing fractional
    /// zeros are trimmed by scanning the bytes already written.
    ///
    /// - Parameter buffer: Scratch space of at least `_descriptionCapacity` bytes.
    /// - Returns: The range of `buffer` that holds the UTF-8 text.
    /// - Precondition: The value must not be NaN.
    internal func _writeDescription(into buffer: UnsafeMutablePointer<UInt8>) -> Range<Int> {
        precondition(!isNaN, "_writeDescription called on NaN; callers must check isNaN first")
        let pairs: StaticString = """
        0001020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849\
        5051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899
        """
        let pair = pairs.utf8Start
        let magnitude = _storage.magnitude
        var intPart = magnitude / UInt64(Self.scaleFactor)
        var fracPart = UInt32(truncatingIfNeeded: magnitude % UInt64(Self.scaleFactor))

        // Fractional part: all 8 digits, then drop the trailing zeros.
        var end = 15
        if fracPart != 0 {
            var index = 24
            for _ in 0 ..< 4 {
                let quotient = fracPart / 100
                let twoDigits = Int(truncatingIfNeeded: fracPart &- quotient &* 100)
                index &-= 2
                buffer[index] = pair[2 &* twoDigits]
                buffer[index &+ 1] = pair[2 &* twoDigits &+ 1]
                fracPart = quotient
            }
            end = 24
            while buffer[end &- 1] == UInt8(ascii: "0") { end &-= 1 }
            buffer[15] = UInt8(ascii: ".")
        }

        // Integer part, right to left.
        var start = 15
        while intPart >= 100 {
            let quotient = intPart / 100
            let twoDigits = Int(truncatingIfNeeded: intPart &- quotient &* 100)
            start &-= 2
            buffer[start] = pair[2 &* twoDigits]
            buffer[start &+ 1] = pair[2 &* twoDigits &+ 1]
            intPart = quotient
        }
        if intPart >= 10 {
            let twoDigits = Int(truncatingIfNeeded: intPart)
            start &-= 2
            buffer[start] = pair[2 &* twoDigits]
            buffer[start &+ 1] = pair[2 &* twoDigits &+ 1]
        } else {
            start &-= 1
            buffer[start] = UInt8(truncatingIfNeeded: intPart) &+ UInt8(ascii: "0")
        }

        if _storage < 0 {
            start &-= 1
            buffer[start] = UInt8(ascii: "-")
        }
        return start ..< end
    }
}

// MARK: - CustomStringConvertible

extension FixedPointDecimal: CustomStringConvertible {
    /// A string representation with trailing fractional zeros trimmed.
    ///
    /// Returns `"nan"` for NaN values.
    ///
    /// ```swift
    /// FixedPointDecimal("123.45000000")!.description  // "123.45"
    /// FixedPointDecimal("100")!.description            // "100"
    /// FixedPointDecimal("0.00000001")!.description     // "0.00000001"
    /// FixedPointDecimal.nan.description                 // "nan"
    /// ```
    public var description: String {
        if isNaN { return "nan" }
        // The text is built on the stack and the string is created at its exact
        // length, so a result that fits a small string (15 bytes on 64-bit
        // platforms) needs no heap allocation.
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: Self._descriptionCapacity) { scratch in
            let buffer = scratch.baseAddress.unsafelyUnwrapped
            let range = _writeDescription(into: buffer)
            let text = UnsafeBufferPointer(start: buffer + range.lowerBound, count: range.count)
            return String(decoding: text, as: UTF8.self) // swiftlint:disable:this optional_data_string_conversion
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension FixedPointDecimal: CustomDebugStringConvertible {
    /// A debug string including the type name and raw storage value.
    ///
    /// ```swift
    /// let v: FixedPointDecimal = "123.45"
    /// v.debugDescription  // "FixedPointDecimal(123.45, rawValue: 12345000000)"
    /// ```
    public var debugDescription: String {
        "FixedPointDecimal(\(description), rawValue: \(_storage))"
    }
}

// MARK: - LosslessStringConvertible

extension FixedPointDecimal: LosslessStringConvertible {
    // init?(_ description: String) is already defined above.
    // description property is already defined above.
}

// MARK: - CustomPlaygroundDisplayConvertible

#if !os(Linux) && !os(Windows)
extension FixedPointDecimal: CustomPlaygroundDisplayConvertible {
    /// The value shown in Xcode Playgrounds and Swift Playgrounds inline results.
    ///
    /// Displays the decimal string directly (e.g. `123.45`) instead of
    /// the raw struct representation.
    public var playgroundDescription: Any {
        description
    }
}
#endif

// MARK: - CustomReflectable

extension FixedPointDecimal: CustomReflectable {
    /// A mirror that exposes the decimal value and raw storage for LLDB
    /// and Swift playgrounds.
    ///
    /// ```swift
    /// let v: FixedPointDecimal = "123.45"
    /// dump(v)
    /// // ▿ 123.45
    /// //   - rawValue: 12345000000
    /// //   - isNaN: false
    /// ```
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "rawValue": _storage,
                "isNaN": isNaN,
            ],
            displayStyle: .struct
        )
    }
}
