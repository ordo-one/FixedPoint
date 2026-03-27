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
    /// Writes the formatted decimal string into a buffer.
    ///
    /// Writes directly into the caller's `UnsafeMutableBufferPointer<UInt8>`
    /// to keep the entire format path allocation-free.
    ///
    /// - Parameters:
    ///   - buffer: The output buffer to write UTF-8 bytes into.
    ///   - offset: The current write position; advanced past the last byte written.
    ///   - fractionDigits: If nil, trailing fractional zeros are trimmed.
    ///     If specified, exactly that many fractional digits are written.
    @usableFromInline
    internal func _writeFormatted(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        startingAt offset: inout Int,
        fractionDigits: Int?
    ) {
        precondition(!isNaN, "_writeFormatted called on NaN; callers must check isNaN first")
        let isNeg = _storage < 0
        let absVal = isNeg ? (0 &- _storage) : _storage
        let intPart = absVal / Self.scaleFactor
        let fracPart = absVal % Self.scaleFactor

        // Sign
        if isNeg {
            buffer[offset] = UInt8(ascii: "-")
            offset &+= 1
        }

        // Integer part: write digits left-to-right using positional division.
        // Standard library String(Int) allocates; this writes directly into
        // the caller's buffer to keep the entire format path allocation-free.
        //
        // Algorithm: for intPart = 4217
        //   1. Count digits: 4 → divisor = 1000
        //   2. Emit 4217/1000 = 4, remainder 217, divisor = 100
        //   3. Emit 217/100  = 2, remainder 17,  divisor = 10
        //   4. Emit 17/10    = 1, remainder 7,   divisor = 1
        //   5. Emit 7/1      = 7, remainder 0,   divisor = 0 → done
        if intPart == 0 {
            buffer[offset] = UInt8(ascii: "0")
            offset &+= 1
        } else {
            var digitCount = 0
            var tmp = intPart
            while tmp > 0 { digitCount &+= 1; tmp /= 10 }
            var divisor: Int64 = 1
            for _ in 1..<digitCount { divisor &*= 10 }

            var remaining = intPart
            while divisor > 0 {
                buffer[offset] = UInt8(remaining / divisor) &+ UInt8(ascii: "0")
                offset &+= 1
                remaining %= divisor
                divisor /= 10
            }
        }

        // Determine how many fractional digits to write
        let digitsToWrite: Int
        if let digits = fractionDigits {
            if digits == 0 { return }
            digitsToWrite = digits
        } else {
            if fracPart == 0 { return }
            // Trim trailing zeros: count significant fractional digits
            var trimmed = fracPart
            var trailingZeros = 0
            while trimmed % 10 == 0 {
                trimmed /= 10
                trailingZeros &+= 1
            }
            digitsToWrite = Self.fractionalDigitCount - trailingZeros
        }

        // Decimal point
        buffer[offset] = UInt8(ascii: ".")
        offset &+= 1

        // Fractional digits: write left-to-right using positional extraction
        let actualDigits = Swift.min(digitsToWrite, Self.fractionalDigitCount)
        var fracDivisor = Self._powerOf10(Self.fractionalDigitCount - 1) // 10_000_000
        for _ in 0..<actualDigits {
            buffer[offset] = UInt8((fracPart / fracDivisor) % 10) &+ UInt8(ascii: "0")
            offset &+= 1
            fracDivisor /= 10
        }

        // Pad with zeros if requested precision exceeds 8
        if digitsToWrite > Self.fractionalDigitCount {
            for _ in Self.fractionalDigitCount..<digitsToWrite {
                buffer[offset] = UInt8(ascii: "0")
                offset &+= 1
            }
        }
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
        return String(unsafeUninitializedCapacity: 24) { buf in
            var offset = 0
            _writeFormatted(into: buf, startingAt: &offset, fractionDigits: nil)
            return offset
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
