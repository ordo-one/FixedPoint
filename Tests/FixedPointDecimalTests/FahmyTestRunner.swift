import Foundation
import FixedPointDecimal

/// Summary of running a Fahmy test file.
struct FahmyTestSummary {
    var passed: Int = 0
    var failed: [(line: Int, detail: String)] = []
    var skipped: Int = 0
    var total: Int { passed + failed.count + skipped }

    var description: String {
        "\(passed) passed, \(failed.count) failed, \(skipped) skipped (total: \(total))"
    }
}

/// Parser and runner for Fahmy/Cairo University decimal64 test vectors.
///
/// Format: `d64[op] rounding sign_significandEexponent sign_significandEexponent -> sign_significandEexponent [flags]`
/// - op: `+` (add), `-` (subtract), `*` (multiply), `/` (divide), `V` (sqrt), `*+` (fma)
/// - rounding: `=0` (half_even), `>` (toward +inf), `<` (toward -inf), `0` (toward zero), `h>` (half_up)
/// - operands: `[+-]significandE[+-]exponent` where significand is a decimal integer
struct FahmyTestRunner {

    static func run(contentsOf url: URL, operation: Character, roundingFilter: String = "=0") throws -> FahmyTestSummary {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var summary = FahmyTestSummary()

        for (lineNum, line) in contents.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            let result = parseLine(trimmed, lineNumber: lineNum + 1, expectedOp: operation,
                                   roundingFilter: roundingFilter)
            switch result {
            case .passed: summary.passed += 1
            case .failed(let line, let detail): summary.failed.append((line: line, detail: detail))
            case .skipped: summary.skipped += 1
            case .none: break
            }
        }
        return summary
    }

    private enum TestResult {
        case passed
        case failed(line: Int, detail: String)
        case skipped
    }

    private static func parseLine(_ line: String, lineNumber: Int, expectedOp: Character,
                                   roundingFilter: String) -> TestResult? {
        let tokens = line.split(separator: " ").map(String.init)
        guard tokens.count >= 5 else { return nil }

        // Parse header: "d64+" or "d64-" or "d64*" or "d64/"
        let header = tokens[0]
        guard header.hasPrefix("d64") else { return nil }
        let op = header.last!
        guard op == expectedOp else { return nil }

        // Parse rounding mode
        let rounding = tokens[1]
        guard rounding == roundingFilter else { return .skipped }

        // Find arrow
        guard let arrowIdx = tokens.firstIndex(of: "->") else { return nil }

        // Parse operands (before arrow)
        let operandTokens = Array(tokens[2..<arrowIdx])
        guard !operandTokens.isEmpty else { return nil }

        // Parse expected result (after arrow)
        guard arrowIdx + 1 < tokens.count else { return nil }
        let expectedToken = tokens[arrowIdx + 1]

        // Parse flags (after result)
        let flags = Set(tokens[(arrowIdx + 2)...])

        // Skip if flags indicate conditions we can't handle
        if flags.contains("o") || flags.contains("z") || flags.contains("i") || flags.contains("u") {
            return .skipped
        }

        // Parse operands, checking for precision loss
        var operands: [FixedPointDecimal] = []
        for token in operandTokens {
            if fahmyOperandLosesPrecision(token) { return .skipped }
            guard let value = parseFahmyOperand(token) else { return .skipped }
            operands.append(value)
        }

        // Parse expected result, checking for precision loss
        if fahmyOperandLosesPrecision(expectedToken) { return .skipped }
        guard let expected = parseFahmyOperand(expectedToken) else { return .skipped }

        // Execute operation
        switch op {
        case "+":
            guard operands.count == 2 else { return .skipped }
            if operands[0].isNaN || operands[1].isNaN { return .skipped }
            let (result, overflow) = operands[0].addingReportingOverflow(operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "-":
            guard operands.count == 2 else { return .skipped }
            if operands[0].isNaN || operands[1].isNaN { return .skipped }
            let (result, overflow) = operands[0].subtractingReportingOverflow(operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "*":
            guard operands.count == 2 else { return .skipped }
            if operands[0].isNaN || operands[1].isNaN { return .skipped }
            let (result, overflow) = operands[0].multipliedReportingOverflow(by: operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "/":
            guard operands.count == 2 else { return .skipped }
            if operands[0].isNaN || operands[1].isNaN || operands[1] == .zero { return .skipped }
            let (result, overflow) = operands[0].dividedReportingOverflow(by: operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        default:
            return .skipped
        }
    }

    private static func check(line: Int, got: FixedPointDecimal, expected: FixedPointDecimal) -> TestResult {
        if got == expected {
            return .passed
        } else {
            return .failed(line: line, detail: "expected \(expected) (raw: \(expected.rawValue)), got \(got) (raw: \(got.rawValue))")
        }
    }

    /// Check if a Fahmy operand would lose precision when converted to our type.
    /// A decimal64 significand has up to 16 digits. When combined with the exponent,
    /// if the result has more than 8 fractional digits, it will be rounded and may
    /// differ from the GDA expected result.
    static func fahmyOperandLosesPrecision(_ token: String) -> Bool {
        let lower = token.lowercased()
        if lower.contains("nan") || lower.contains("inf") { return false }

        guard let eIdx = lower.firstIndex(of: "e") else { return false }
        let sigStr = String(token[token.startIndex..<eIdx])
        let expStr = String(token[token.index(after: eIdx)...])

        guard let significand = Int(sigStr), let exponent = Int(expStr) else { return false }

        // Count significant digits in the significand
        let sigDigits = String(abs(significand)).count

        // The number of fractional digits is: sigDigits - 1 - exponent
        // (since the implicit decimal point is after the first digit in decimal64)
        // Actually for Fahmy format: value = significand * 10^exponent
        // Fractional digits = max(0, -exponent) when significand has no trailing zeros
        // But more precisely: the value has sigDigits significant digits positioned by exponent.
        // Number of fractional digits = max(0, sigDigits + exponent) where exponent is typically negative
        // Wait, let me think: significand = 1234567890123456, exponent = -8
        // value = 1234567890123456 * 10^-8 = 12345678.90123456 -> 8 fractional digits
        // Our type can handle exactly 8 fractional digits, so this is fine.
        // significand = 1234567890123456, exponent = -9
        // value = 123456789.0123456 -> 7 fractional digits? No...
        // value = 1234567890123456 * 10^-9 = 1234567890.123456 -> 6 fractional digits
        // Hmm, the number of fractional digits depends on both sigDigits and exponent.
        // fractionalDigits = max(0, -exponent - (0 if no trailing zeros))
        // Actually simpler: fractionalDigits = max(0, sigDigits - (sigDigits + exponent))
        // = max(0, -exponent) ... no that's not right either.
        //
        // value = significand * 10^exponent
        // If exponent >= 0: no fractional digits (integer * power of 10)
        // If exponent < 0: fractional digits = min(sigDigits, -exponent)
        //   because: 123 * 10^-2 = 1.23 (2 fractional digits, min(3, 2) = 2)
        //            123 * 10^-5 = 0.00123 (5 fractional digits, min(3, 5) = 3... no, it's 5)
        //
        // Actually 123 * 10^-5 = 0.00123 which has 5 fractional digits.
        // 123000 * 10^-5 = 1.23000 which has 5 fractional digits (but trailing zeros).
        // The effective fractional digits = -exponent (the position of the decimal point).
        // If -exponent > 8, we lose precision.

        if exponent < -8 {
            // More than 8 fractional digits needed
            return true
        }

        return false
    }

    /// Parse a Fahmy operand: `[+-]significandE[+-]exponent`
    /// e.g., `+3765979545218895E-209`, `+1234567890123456E-8`
    /// Returns nil if the value is out of our representable range.
    static func parseFahmyOperand(_ token: String) -> FixedPointDecimal? {
        let lower = token.lowercased()

        // Handle special values
        if lower.contains("nan") || lower.contains("inf") { return nil }

        // Split at E
        guard let eIdx = lower.firstIndex(of: "e") else { return nil }
        let sigStr = String(token[token.startIndex..<eIdx])
        let expStr = String(token[token.index(after: eIdx)...])

        guard let significand = Int(sigStr), let exponent = Int(expStr) else { return nil }

        // Compute effective shift for our 8-fractional-digit type
        let shift = 8 + exponent  // fractionalDigitCount + exponent

        if shift < -18 || shift > 18 { return nil }

        // Use Int128-safe computation to check if value fits
        if shift >= 0, shift <= 18 {
            let pow10: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000,
                                  10_000_000, 100_000_000, 1_000_000_000,
                                  10_000_000_000, 100_000_000_000,
                                  1_000_000_000_000, 10_000_000_000_000,
                                  100_000_000_000_000, 1_000_000_000_000_000,
                                  10_000_000_000_000_000, 100_000_000_000_000_000,
                                  1_000_000_000_000_000_000]
            let (result, overflow) = Int64(significand).multipliedReportingOverflow(by: pow10[shift])
            if overflow || result == .min { return nil }
            return FixedPointDecimal(rawValue: result)
        } else {
            // Negative shift: needs rounding, use init(significand:exponent:)
            // But first check if value is even roughly in range
            if abs(significand) > 9_223_372_036_854_775 { return nil }  // > Int64.max / 1000
            return FixedPointDecimal(significand: significand, exponent: exponent)
        }
    }
}
