import Foundation
import FixedPointDecimal

/// Summary of running Intel test vectors.
struct IntelTestSummary {
    var passed: Int = 0
    var failed: [(line: Int, detail: String)] = []
    var skipped: Int = 0
    var total: Int { passed + failed.count + skipped }

    var description: String {
        "\(passed) passed, \(failed.count) failed, \(skipped) skipped (total: \(total))"
    }
}

/// Parser and runner for Intel Decimal Floating-Point Math Library test vectors.
///
/// Format: `function_name rounding_mode operand1 [operand2] [operand3] expected_result expected_status`
/// - Operands can be hex BID64 in brackets `[hex]` or decimal strings
/// - Rounding: 0=nearest-even, 1=down, 2=up, 3=toward-zero, 4=nearest-away
/// - Status: two-digit hex exception flags
struct IntelTestRunner {

    static func run(contentsOf url: URL, operations: Set<String>? = nil,
                    roundingFilter: Int = 0) throws -> IntelTestSummary {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var summary = IntelTestSummary()

        for (lineNum, line) in contents.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("--") || trimmed.hasPrefix("#") { continue }

            let result = parseLine(trimmed, lineNumber: lineNum + 1, operations: operations,
                                   roundingFilter: roundingFilter)
            switch result {
            case .passed: summary.passed += 1
            case .failed(let ln, let detail): summary.failed.append((line: ln, detail: detail))
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

    private static func parseLine(_ line: String, lineNumber: Int,
                                   operations: Set<String>?,
                                   roundingFilter: Int) -> TestResult? {
        // Tokenize, handling bracketed hex values as single tokens
        let tokens = tokenize(line)
        guard tokens.count >= 4 else { return nil }

        let funcName = tokens[0]

        // Filter by operation
        if let ops = operations, !ops.contains(funcName) { return nil }

        // Parse rounding mode
        guard let rounding = Int(tokens[1]) else { return nil }
        guard rounding == roundingFilter else { return .skipped }

        // Parse status (last token)
        let statusHex = tokens.last!
        guard let status = UInt8(statusHex, radix: 16) else { return nil }

        // Skip if status indicates conditions we trap on
        // Bit 0: invalid, Bit 1: denormalized, Bit 2: division by zero,
        // Bit 3: overflow, Bit 4: underflow, Bit 5: inexact
        let invalid = status & 0x01 != 0
        let divByZero = status & 0x04 != 0
        let overflow = status & 0x08 != 0
        let underflow = status & 0x10 != 0
        if invalid || divByZero || overflow || underflow { return .skipped }

        // Determine operand count based on function
        let opTokens: [String]
        let expectedToken: String

        if funcName.contains("abs") || funcName.contains("negate") {
            // Unary: funcName rounding op1 result status
            guard tokens.count >= 5 else { return nil }
            opTokens = [tokens[2]]
            expectedToken = tokens[3]
        } else {
            // Binary: funcName rounding op1 op2 result status
            guard tokens.count >= 6 else { return nil }
            opTokens = [tokens[2], tokens[3]]
            expectedToken = tokens[4]
        }

        // Parse operands, checking for precision loss
        var operands: [FixedPointDecimal] = []
        for token in opTokens {
            if bid64OperandLosesPrecision(token) { return .skipped }
            guard let value = parseIntelOperand(token) else { return .skipped }
            if value.isNaN { return .skipped }
            operands.append(value)
        }

        // Parse expected result, checking for precision loss
        if bid64OperandLosesPrecision(expectedToken) { return .skipped }
        guard let expected = parseIntelOperand(expectedToken) else { return .skipped }
        if expected.isNaN { return .skipped }

        // Execute operation
        return executeOp(funcName: funcName, operands: operands, expected: expected, lineNumber: lineNumber)
    }

    private static func executeOp(funcName: String, operands: [FixedPointDecimal],
                                   expected: FixedPointDecimal, lineNumber: Int) -> TestResult {
        switch funcName {
        case "bid64_add":
            guard operands.count == 2 else { return .skipped }
            let (result, overflow) = operands[0].addingReportingOverflow(operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_sub":
            guard operands.count == 2 else { return .skipped }
            let (result, overflow) = operands[0].subtractingReportingOverflow(operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_mul":
            guard operands.count == 2 else { return .skipped }
            let (result, overflow) = operands[0].multipliedReportingOverflow(by: operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_div":
            guard operands.count == 2 else { return .skipped }
            if operands[1] == .zero { return .skipped }
            let (result, overflow) = operands[0].dividedReportingOverflow(by: operands[1])
            if overflow { return .skipped }
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_rem":
            guard operands.count == 2 else { return .skipped }
            if operands[1] == .zero { return .skipped }
            let result = FixedPointDecimal(rawValue: operands[0].rawValue % operands[1].rawValue)
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_abs":
            guard operands.count == 1 else { return .skipped }
            let result = FixedPointDecimal(rawValue: abs(operands[0].rawValue))
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_negate":
            guard operands.count == 1 else { return .skipped }
            return check(line: lineNumber, got: -operands[0], expected: expected)

        case "bid64_quiet_equal":
            guard operands.count == 2 else { return .skipped }
            let cmp: FixedPointDecimal = operands[0] == operands[1] ?
                FixedPointDecimal(rawValue: 100_000_000) : .zero
            return check(line: lineNumber, got: cmp, expected: expected)

        case "bid64_quiet_less":
            guard operands.count == 2 else { return .skipped }
            let cmp: FixedPointDecimal = operands[0] < operands[1] ?
                FixedPointDecimal(rawValue: 100_000_000) : .zero
            return check(line: lineNumber, got: cmp, expected: expected)

        case "bid64_quiet_greater":
            guard operands.count == 2 else { return .skipped }
            let cmp: FixedPointDecimal = operands[0] > operands[1] ?
                FixedPointDecimal(rawValue: 100_000_000) : .zero
            return check(line: lineNumber, got: cmp, expected: expected)

        case "bid64_minnum":
            guard operands.count == 2 else { return .skipped }
            let result = operands[0] <= operands[1] ? operands[0] : operands[1]
            return check(line: lineNumber, got: result, expected: expected)

        case "bid64_maxnum":
            guard operands.count == 2 else { return .skipped }
            let result = operands[0] >= operands[1] ? operands[0] : operands[1]
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

    // MARK: - Precision Loss Detection

    /// Check if a BID64-encoded operand would lose precision when decoded to our type.
    /// BID64 has 16 significant digits; our type has 8 fixed fractional digits (~18 sig digits).
    /// When a BID64 significand uses all 16 digits AND the value requires more than 8 fractional
    /// digits in our representation, the decoded value may differ from the Intel expected result.
    static func bid64OperandLosesPrecision(_ token: String) -> Bool {
        if !token.hasPrefix("[") || !token.hasSuffix("]") {
            // Decimal string: check fractional digits
            return GDATestRunner.operandLosesPrecision(token)
        }

        // Decode BID64 to check
        let hex = String(token.dropFirst().dropLast())
        guard let bits = UInt64(hex, radix: 16) else { return false }

        let highBits = (bits >> 61) & 0b11
        let exponent: Int
        let significand: UInt64

        if highBits == 0b11 {
            let top3 = (bits >> 60) & 0b111
            if top3 >= 0b110 { return false } // Infinity/NaN
            let expBits = ((bits >> 59) & 0b11) << 8 | ((bits >> 51) & 0xFF)
            exponent = Int(expBits) - 398
            significand = (1 << 53) | (bits & ((1 << 51) - 1))
        } else {
            let expBits = (bits >> 53) & 0x3FF
            exponent = Int(expBits) - 398
            significand = bits & ((1 << 53) - 1)
        }

        if significand == 0 { return false }

        // Check if the value has more than 8 fractional digits
        if exponent < -8 { return true }

        // Check if the significand maxes out BID64 precision (16 digits)
        // AND the result would have more significant digits than BID64 can represent
        let sigDigits = String(significand).count
        if sigDigits >= 16 && exponent < 0 {
            // The value has maximum BID64 precision with fractional digits.
            // Our computation might produce a result with more precision than
            // the Intel expected result (which is also limited to 16 sig digits).
            return true
        }

        return false
    }

    // MARK: - BID64 Decoder

    /// Parse an Intel test operand. Can be:
    /// - Bracketed hex: `[31c0000000000000]` -> BID64 encoded
    /// - Decimal string: `-0.0110E-5` or `+8898.E5` or `0`
    static func parseIntelOperand(_ token: String) -> FixedPointDecimal? {
        if token.hasPrefix("[") && token.hasSuffix("]") {
            let hex = String(token.dropFirst().dropLast())
            return decodeBID64(hex: hex)
        } else {
            return GDATestRunner.parseDecimal(token)
        }
    }

    /// Decode a BID64 (Binary Integer Decimal, 64-bit) hex string to FixedPointDecimal.
    ///
    /// BID64 format (IEEE 754-2008):
    /// - Sign: bit 63
    /// - If bits [62:61] == 0b11:
    ///   - If bits [62:60] == 0b111: Infinity (110) or NaN (111)
    ///   - Else: Exponent = (bits[61:60] << 8) | bits[57:50], Significand = (0b100 << 50) | bits[49:0]
    /// - Else:
    ///   - Exponent = bits[62:53] (10 bits)
    ///   - Significand = bits[52:0] (53 bits)
    /// - Exponent bias: 398
    /// - Value = (-1)^sign * significand * 10^(exponent - 398)
    static func decodeBID64(hex: String) -> FixedPointDecimal? {
        guard let bits = UInt64(hex, radix: 16) else { return nil }

        let sign = (bits >> 63) & 1
        let highBits = (bits >> 61) & 0b11

        let exponent: Int
        let significand: UInt64

        if highBits == 0b11 {
            // Check for infinity or NaN
            let top3 = (bits >> 60) & 0b111
            if top3 >= 0b110 {
                // Infinity (0b110) or NaN (0b111)
                return nil
            }
            // Special encoding for large significands
            let expBits = ((bits >> 59) & 0b11) << 8 | ((bits >> 51) & 0xFF)
            exponent = Int(expBits) - 398
            significand = (1 << 53) | (bits & ((1 << 51) - 1))
        } else {
            // Normal encoding
            let expBits = (bits >> 53) & 0x3FF
            exponent = Int(expBits) - 398
            significand = bits & ((1 << 53) - 1)
        }

        // Check for zero
        if significand == 0 { return .zero }

        // Check significand is valid (must be <= 9999999999999999 for decimal64)
        if significand > 9_999_999_999_999_999 { return nil }

        let signedSig = sign == 1 ? -Int(significand) : Int(significand)

        // Convert to our type: value = significand * 10^exponent
        // Our raw storage = significand * 10^(exponent + 8)
        let shift = 8 + exponent

        if shift < -18 || shift > 18 { return nil }

        if shift >= 0, shift <= 18 {
            let pow10: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000,
                                  10_000_000, 100_000_000, 1_000_000_000,
                                  10_000_000_000, 100_000_000_000,
                                  1_000_000_000_000, 10_000_000_000_000,
                                  100_000_000_000_000, 1_000_000_000_000_000,
                                  10_000_000_000_000_000, 100_000_000_000_000_000,
                                  1_000_000_000_000_000_000]
            let (result, overflow) = Int64(signedSig).multipliedReportingOverflow(by: pow10[shift])
            if overflow || result == .min { return nil }
            return FixedPointDecimal(rawValue: result)
        } else if shift < 0 {
            // Needs rounding - check precision loss
            if -exponent > 8 { return nil }  // More than 8 fractional digits
            return FixedPointDecimal(significand: signedSig, exponent: exponent)
        }

        return nil
    }

    /// Tokenize an Intel test line, keeping bracketed hex as single tokens.
    private static func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inBracket = false

        for char in line {
            if char == "[" {
                inBracket = true
                current.append(char)
            } else if char == "]" {
                inBracket = false
                current.append(char)
            } else if (char == " " || char == "\t") && !inBracket {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}
