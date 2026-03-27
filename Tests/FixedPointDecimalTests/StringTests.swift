import Testing
@testable import FixedPointDecimal

@Suite("String Parsing and Formatting")
struct StringTests {

    // MARK: - Parsing
    // Note: These tests use `String` variables to force the failable `init?(_ description:)`
    // path instead of `init(stringLiteral:)` which traps on invalid input.

    @Test("Parse simple integer")
    func parseInteger() {
        let s: String = "123"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == 123)
        #expect(value?.fractionalPart == 0)
    }

    @Test("Parse decimal")
    func parseDecimal() {
        let s: String = "123.45"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == 123)
        #expect(value?.fractionalPart == 45_000_000)
    }

    @Test("Parse negative")
    func parseNegative() {
        let s: String = "-42.5"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == -42)
    }

    @Test("Parse with leading dot")
    func parseLeadingDot() {
        let s: String = ".5"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == 0)
        #expect(value?.fractionalPart == 50_000_000)
    }

    @Test("Parse negative with leading dot")
    func parseNegativeLeadingDot() {
        let s: String = "-.5"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == 0)
        #expect(value?.fractionalPart == -50_000_000)
    }

    @Test("Parse zero")
    func parseZero() {
        let s: String = "0"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == .zero)
    }

    @Test("Parse with trailing zeros")
    func parseTrailingZeros() {
        let s1: String = "123.45000000"
        let s2: String = "123.45"
        #expect(FixedPointDecimal(s1) == FixedPointDecimal(s2))
    }

    @Test("Parse 8 decimal places")
    func parseFull8() {
        let s: String = "1.23456789"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.rawValue == 1_23456789)
    }

    @Test("Parse with banker's rounding beyond 8 digits")
    func parseRoundingBeyond8() {
        // 9th digit is 9 (> 5) → rounds up
        let s1: String = "1.123456789999"
        let value = FixedPointDecimal(s1)
        #expect(value != nil)
        #expect(value == FixedPointDecimal("1.12345679"))

        // 9th digit is 5 with trailing non-zero → rounds up
        #expect(FixedPointDecimal("1.123456785001") == FixedPointDecimal("1.12345679"))

        // 9th digit is 5, no trailing digits, 8th digit even → stays (round to even)
        #expect(FixedPointDecimal("1.123456785") == FixedPointDecimal("1.12345678"))

        // 9th digit is 5, no trailing digits, 8th digit odd → rounds up (round to even)
        #expect(FixedPointDecimal("1.123456795") == FixedPointDecimal("1.12345680"))

        // 9th digit < 5 → truncates
        #expect(FixedPointDecimal("1.123456784") == FixedPointDecimal("1.12345678"))
    }

    @Test("Parse with plus sign")
    func parsePlusSign() {
        let s: String = "+42"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.integerPart == 42)
    }

    @Test("Parse NaN")
    func parseNaN() {
        let s1: String = "nan"
        let value = FixedPointDecimal(s1)
        #expect(value != nil)
        #expect(value?.isNaN == true)

        let s2: String = "NaN"
        let value2 = FixedPointDecimal(s2)
        #expect(value2 != nil)
        #expect(value2?.isNaN == true)
    }

    @Test("Parse invalid strings return nil")
    func parseInvalid() {
        let empty: String = ""
        let abc: String = "abc"
        let doubleDot: String = "12.34.56"
        let doubleDash: String = "--5"
        let alphaNum: String = "12abc"
        #expect(FixedPointDecimal(empty) == nil)
        #expect(FixedPointDecimal(abc) == nil)
        #expect(FixedPointDecimal(doubleDot) == nil)
        #expect(FixedPointDecimal(doubleDash) == nil)
        #expect(FixedPointDecimal(alphaNum) == nil)
    }

    @Test("Parse smallest positive value")
    func parseSmallest() {
        let s: String = "0.00000001"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.rawValue == 1)
    }

    // MARK: - Formatting

    @Test("Format integer")
    func formatInteger() {
        let value: FixedPointDecimal = 100
        #expect(value.description == "100")
    }

    @Test("Format decimal with trimmed zeros")
    func formatTrimmedZeros() {
        let value: FixedPointDecimal = 123.45
        #expect(value.description == "123.45")
    }

    @Test("Format all 8 digits")
    func formatAll8() {
        let value: FixedPointDecimal = 0.00000001
        #expect(value.description == "0.00000001")
    }

    @Test("Format negative")
    func formatNegative() {
        let value: FixedPointDecimal = -42.5
        #expect(value.description == "-42.5")
    }

    @Test("Format zero")
    func formatZero() {
        #expect(FixedPointDecimal.zero.description == "0")
    }

    @Test("Format NaN")
    func formatNaN() {
        #expect(FixedPointDecimal.nan.description == "nan")
    }

    @Test("Debug description")
    func debugDescription() {
        let value: FixedPointDecimal = 42
        let debug = value.debugDescription
        #expect(debug.contains("FixedPointDecimal"))
        #expect(debug.contains("42"))
        #expect(debug.contains("rawValue"))
    }

    // MARK: - String Round-Trip

    @Test("String round-trip (LosslessStringConvertible)")
    func stringRoundTrip() {
        let values = ["0", "1", "-1", "123.45", "-99.99", "0.00000001", "92233720368.54775807"]
        for str in values {
            let parsed = FixedPointDecimal(str)!
            let formatted = String(parsed)
            let reparsed = FixedPointDecimal(formatted)
            #expect(reparsed == parsed, "Round-trip failed for '\(str)': formatted as '\(formatted)'")
        }
    }

    // MARK: - Literals

    @Test("Integer initialization via literal")
    func integerLiteral() {
        let price: FixedPointDecimal = 42
        #expect(price == FixedPointDecimal(integerValue: 42))
    }

    // MARK: - String Parsing Edge Cases

    @Test("Parse leading zeros: 007.5")
    func parseLeadingZeros() {
        let s: String = "007.5"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == 7.5 as FixedPointDecimal)
    }

    @Test("Parse many decimal places: banker's rounded to 8")
    func parseManyDecimalPlaces() {
        // 9th digit is 9 (> 5) → rounds up
        let s: String = "1.123456789012345"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == FixedPointDecimal("1.12345679"))
    }

    @Test("Parse maximum representable value")
    func parseMaxValue() {
        let s: String = "92233720368.54775807"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == FixedPointDecimal.max)
    }

    @Test("Parse minimum representable value")
    func parseMinValue() {
        let s: String = "-92233720368.54775807"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == FixedPointDecimal.min)
    }

    @Test("Parse negative zero: -0")
    func parseNegativeZero() {
        let s: String = "-0"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == .zero)
        #expect(value == FixedPointDecimal.zero)
    }

    @Test("Parse just a dot returns nil")
    func parseJustDot() {
        let s: String = "."
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Parse only minus sign returns nil")
    func parseOnlyMinus() {
        let s: String = "-"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Parse only plus sign returns nil")
    func parseOnlyPlus() {
        let s: String = "+"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Parse whitespace returns nil")
    func parseWhitespace() {
        let s1: String = " 123"
        let s2: String = "123 "
        let s3: String = " "
        #expect(FixedPointDecimal(s1) == nil)
        #expect(FixedPointDecimal(s2) == nil)
        #expect(FixedPointDecimal(s3) == nil)
    }

    @Test("Parse value just beyond max returns nil")
    func parseBeyondMax() {
        let s: String = "92233720369"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Parse negative zero with fractional: -0.5")
    func parseNegativeZeroFraction() {
        let s: String = "-0.5"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.rawValue == -50_000_000)
        #expect(value?.description == "-0.5")
    }

    @Test("Parse 0.0 is zero")
    func parseZeroPointZero() {
        let s: String = "0.0"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == .zero)
    }

    @Test("Parse negative leading dot: -.01")
    func parseNegativeLeadingDotSmall() {
        let s: String = "-.01"
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value?.rawValue == -1_000_000)
    }

    @Test("Format min value round-trips through string")
    func formatMinRoundTrip() {
        let min = FixedPointDecimal.min
        let str = min.description
        let reparsed = FixedPointDecimal(str)
        #expect(reparsed == min)
    }

    // MARK: - Trailing Dot

    @Test("Parse trailing dot: 123.")
    func parseTrailingDot() {
        let s: String = "123."
        let value = FixedPointDecimal(s)
        #expect(value != nil)
        #expect(value == 123 as FixedPointDecimal)
    }

    // MARK: - Non-Digit Characters in Fraction

    @Test("Parse fraction with non-digit returns nil")
    func parseFractionNonDigit() {
        let s: String = "123.4a5"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Parse extra digits beyond 8 with non-digit returns nil")
    func parseExtraDigitsBeyond8NonDigit() {
        let s: String = "1.12345678x"
        #expect(FixedPointDecimal(s) == nil)
    }

    // MARK: - String That Would Produce NaN Sentinel

    @Test("Parse string whose negation produces Int64.min returns nil")
    func parseNaNSentinelViaString() {
        let s: String = "-92233720368.54775808"
        #expect(FixedPointDecimal(s) == nil)
    }

    // MARK: - Formatting of .min (uses wrapping negation for abs)

    @Test("Format .min description uses wrapping subtraction correctly")
    func formatMinDescription() {
        let min = FixedPointDecimal.min
        let desc = min.description
        #expect(desc == "-92233720368.54775807")
    }

    // MARK: - UnsafeBufferPointer<UInt8> Parsing

    @Test("Parse via UnsafeBufferPointer<UInt8> — simple decimal")
    func parseBufferSimple() {
        var str = "123.45"
        str.withUTF8 {
            let value = FixedPointDecimal($0)
            #expect(value != nil)
            #expect(value == 123.45 as FixedPointDecimal)
        }
    }

    @Test("Parse via UnsafeBufferPointer<UInt8> — negative value")
    func parseBufferNegative() {
        var str = "-42.5"
        str.withUTF8 {
            let value = FixedPointDecimal($0)
            #expect(value != nil)
            #expect(value?.rawValue == -4_250_000_000)
        }
    }

    @Test("Parse via UnsafeBufferPointer<UInt8> — NaN")
    func parseBufferNaN() {
        var str = "nan"
        str.withUTF8 {
            let value = FixedPointDecimal($0)
            #expect(value != nil)
            #expect(value?.isNaN == true)
        }
    }

    @Test("Parse via UnsafeBufferPointer<UInt8> — invalid returns nil")
    func parseBufferInvalid() {
        var str = "abc"
        str.withUTF8 { #expect(FixedPointDecimal($0) == nil) }
    }

    @Test("Parse via UnsafeBufferPointer<UInt8> — empty returns nil")
    func parseBufferEmpty() {
        var str = ""
        str.withUTF8 { #expect(FixedPointDecimal($0) == nil) }
    }

    @Test("Parse via UnsafeBufferPointer<UInt8> — matches String init")
    func parseBufferMatchesString() {
        let cases = ["0", "1", "-1", "123.45", ".5", "0.00000001",
                     "92233720368.54775807", "-92233720368.54775807", "nan"]
        for str in cases {
            let stringResult = FixedPointDecimal(str)
            var copy = str
            copy.withUTF8 {
                let bufResult = FixedPointDecimal($0)
                #expect(bufResult == stringResult,
                        "Buffer and String parse differ for '\(str)': \(String(describing: bufResult)) vs \(String(describing: stringResult))")
            }
        }
    }

    // MARK: - String Round-Trip for All Special Values (inspired by rust_decimal/OpenJDK)

    @Test("String round-trip for all special values")
    func stringRoundTripSpecialValues() {
        let specials: [FixedPointDecimal] = [
            .zero, .max, .min, .leastNonzeroMagnitude,
            0.00000001, -0.00000001,
            1, -1,
            FixedPointDecimal("99999999.99999999")!, FixedPointDecimal("-99999999.99999999")!,
        ]
        for value in specials {
            let str = value.description
            let reparsed = FixedPointDecimal(str)
            #expect(reparsed == value, "Round-trip failed for \(str)")
        }
    }

    @Test("NaN string round-trip")
    func nanStringRoundTrip() {
        let str = FixedPointDecimal.nan.description
        #expect(str == "nan")
        let reparsed = FixedPointDecimal(str)
        #expect(reparsed != nil)
        #expect(reparsed!.isNaN)
    }

    // MARK: - Malformed String Rejection (inspired by OpenJDK StringConstructor & rust_decimal)

    @Test("Reject double dots")
    func parseDoubleDot() {
        let s: String = "1..2"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Reject double minus")
    func parseDoubleMinus() {
        let s: String = "--1"
        #expect(FixedPointDecimal(s) == nil)
    }

    @Test("Reject sign in body")
    func parseSignInBody() {
        let s1: String = "1-2"
        let s2: String = "1+2"
        #expect(FixedPointDecimal(s1) == nil)
        #expect(FixedPointDecimal(s2) == nil)
    }

    @Test("Reject letters mixed with digits")
    func parseLettersInDigits() {
        let cases: [String] = ["12a34", "abc", "1.2.3", "1e5", "0xFF", "NAN1"]
        for s in cases {
            #expect(FixedPointDecimal(s) == nil, "Should reject '\(s)'")
        }
    }

    @Test("Reject empty string")
    func parseEmptyString() {
        let s: String = ""
        #expect(FixedPointDecimal(s) == nil)
    }
}
