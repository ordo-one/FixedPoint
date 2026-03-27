#if canImport(Foundation)
import Testing
import Foundation
@testable import FixedPointDecimal

@Suite("FormatStyle")
struct FormatStyleTests {

    @Test("Default format — trailing zeros trimmed")
    func defaultFormat() {
        let value: FixedPointDecimal = 123.45
        #expect(value.formatted() == "123.45")
    }

    @Test("Default format — integer")
    func defaultFormatInteger() {
        let value: FixedPointDecimal = 100
        #expect(value.formatted() == "100")
    }

    @Test("Format with fixed precision")
    func fixedPrecision() {
        let value: FixedPointDecimal = 123.45
        #expect(value.formatted(.fixedPointDecimal.precision(2)) == "123.45")
        #expect(value.formatted(.fixedPointDecimal.precision(4)) == "123.4500")
        #expect(value.formatted(.fixedPointDecimal.precision(0)) == "123")
    }

    @Test("Format NaN")
    func formatNaN() {
        let nan = FixedPointDecimal.nan
        #expect(nan.formatted(.fixedPointDecimal) == "nan")
    }

    @Test("Format negative")
    func formatNegative() {
        let value: FixedPointDecimal = -42.5
        #expect(value.formatted(.fixedPointDecimal.precision(2)) == "-42.50")
    }

    @Test("Parse strategy")
    func parseStrategy() throws {
        let strategy = FixedPointDecimalParseStrategy()
        let result = try strategy.parse("123.45")
        #expect(result == 123.45 as FixedPointDecimal)
    }

    @Test("Parse strategy — invalid input throws")
    func parseStrategyInvalid() {
        let strategy = FixedPointDecimalParseStrategy()
        #expect(throws: (any Error).self) {
            _ = try strategy.parse("not-a-number")
        }
    }

    // MARK: - Precision 8 (Full)

    @Test("Format with precision 8 pads to full fractional width")
    func precisionFull() {
        let value: FixedPointDecimal = 1.5
        #expect(value.formatted(.fixedPointDecimal.precision(8)) == "1.50000000")
    }

    // MARK: - Precision 1

    @Test("Format with precision 1 — rounds, not truncates")
    func precision1() {
        let value: FixedPointDecimal = 123.456
        #expect(value.formatted(.fixedPointDecimal.precision(1)) == "123.5")
    }

    // MARK: - NaN with Precision

    @Test("Format NaN with precision returns nan")
    func formatNaNWithPrecision() {
        let nan = FixedPointDecimal.nan
        #expect(nan.formatted(.fixedPointDecimal.precision(2)) == "nan")
        #expect(nan.formatted(.fixedPointDecimal.precision(0)) == "nan")
    }

    // MARK: - Precision 8 (Exact)

    @Test("Format with precision 8 shows all digits")
    func precision8() {
        let value: FixedPointDecimal = 1.23456789
        #expect(value.formatted(.fixedPointDecimal.precision(8)) == "1.23456789")
    }

    @Test("Format zero with precision 2")
    func formatZeroWithPrecision() {
        let value = FixedPointDecimal.zero
        #expect(value.formatted(.fixedPointDecimal.precision(2)) == "0.00")
    }

    @Test("Format negative zero-fractional with precision")
    func formatNegativeSmallWithPrecision() {
        let value: FixedPointDecimal = -0.001
        #expect(value.formatted(.fixedPointDecimal.precision(4)) == "-0.0010")
    }

    // MARK: - FormatStyle Round-Trip (format then parse)

    @Test("FormatStyle round-trip through format and parse")
    func formatStyleRoundTrip() throws {
        let style = FixedPointDecimalFormatStyle()
        let values: [FixedPointDecimal] = [0, 1, -1, 123.45, -99.99, 0.00000001]
        for value in values {
            let formatted = style.format(value)
            let parsed = try style.parseStrategy.parse(formatted)
            #expect(parsed == value, "Round-trip failed for \(value): formatted as '\(formatted)'")
        }
    }

    @Test("FormatStyle precision round-trip")
    func formatStylePrecisionRoundTrip() throws {
        let style = FixedPointDecimalFormatStyle(fractionDigits: 8)
        let values: [FixedPointDecimal] = [123.45, 0.00000001, 42]
        for value in values {
            let formatted = style.format(value)
            let parsed = try style.parseStrategy.parse(formatted)
            #expect(parsed == value, "Precision round-trip failed for \(value)")
        }
    }

    // MARK: - Formatting Parity with Foundation.Decimal

    @Test("Formatting matches Decimal for financial values")
    func formattingMatchesDecimal() {
        let values: [(String, String)] = [
            ("0", "0"),
            ("1", "1"),
            ("123.45", "123.45"),
            ("-42.5", "-42.5"),
            ("0.00000001", "0.00000001"),
            ("99999.99", "99999.99"),
            ("1000000", "1000000"),
        ]
        for (input, expected) in values {
            let fpd = FixedPointDecimal(input)!
            let decimal = Decimal(fpd)
            let fpdStr = fpd.description
            #expect(fpdStr == expected, "FPD formatted '\(input)' as '\(fpdStr)', expected '\(expected)'")
            let recovered = FixedPointDecimal(decimal)
            #expect(recovered == fpd, "Decimal round-trip failed for '\(input)'")
        }
    }

    @Test("Formatted precision matches banker's rounding")
    func formattedPrecisionMatchesBankersRounding() {
        let value: FixedPointDecimal = 123.456
        let precisions = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        for p in precisions {
            let formatted = value.formatted(.fixedPointDecimal.precision(p))
            let decimal = Decimal(string: formatted)!
            let reparsed = FixedPointDecimal(decimal)
            let rounded = value.rounded(scale: p)  // default: banker's rounding
            #expect(reparsed == rounded,
                    "Precision \(p): formatted '\(formatted)', reparsed \(reparsed), expected \(rounded)")
        }
    }
}
#endif

// MARK: - Plottable

#if canImport(SwiftUI) && canImport(Charts)
import Testing
@testable import FixedPointDecimal

@Suite("Plottable")
struct PlottableTests {

    @Test("Plottable primitivePlottable returns doubleValue")
    func plottablePrimitive() {
        let value: FixedPointDecimal = 123.45
        #expect(value.primitivePlottable == Double(value))
    }

    @Test("Plottable primitivePlottable for NaN")
    func plottableNaN() {
        #expect(FixedPointDecimal.nan.primitivePlottable.isNaN)
    }

    @Test("Plottable init from primitivePlottable round-trip")
    func plottableRoundTrip() {
        let original: FixedPointDecimal = 42.5
        let primitive = original.primitivePlottable
        let recovered = FixedPointDecimal(primitivePlottable: primitive)
        #expect(recovered == original)
    }

    @Test("Plottable init from NaN primitivePlottable returns nil")
    func plottableFromNaN() {
        let result = FixedPointDecimal(primitivePlottable: Double.nan)
        #expect(result == nil)
    }
}
#endif
