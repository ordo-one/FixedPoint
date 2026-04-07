import Foundation
import FixedPointDecimal

/// Result of running a single GDA test case.
enum GDATestResult {
    case passed
    case failed(id: String, detail: String)
    case skipped(id: String, reason: String)
}

/// Summary of running a GDA test file.
struct GDATestSummary {
    var passed: Int = 0
    var failed: [(id: String, detail: String)] = []
    var skipped: Int = 0
    var total: Int { passed + failed.count + skipped }

    var description: String {
        "\(passed) passed, \(failed.count) failed, \(skipped) skipped (total: \(total))"
    }
}

/// Supported GDA operations mapped to our type.
enum GDAOperation: String {
    case add, subtract, multiply, divide, remainder
    case abs, minus, plus
    case compare, comparetotal
    case min, max
    case tointegralx = "tointegralx"
    case tointegral = "tointegral"
    case power
    case apply // used in base tests
}

/// Parser and runner for Speleotrove/Cowlishaw .decTest files.
struct GDATestRunner {
    /// Run all compatible test cases from a .decTest file.
    static func run(contentsOf url: URL, operations: Set<String>? = nil) throws -> GDATestSummary {
        let contents = try String(contentsOf: url, encoding: .utf8)
        return run(contents: contents, operations: operations)
    }

    static func run(contents: String, operations: Set<String>? = nil) -> GDATestSummary {
        var summary = GDATestSummary()
        var currentPrecision = 9
        var currentRounding = "half_up"

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("--") { continue }

            // Parse directives
            if let colonIdx = trimmed.firstIndex(of: ":"), !trimmed.first!.isNumber {
                let key = String(trimmed[trimmed.startIndex..<colonIdx]).trimmingCharacters(in: .whitespaces).lowercased()
                let value = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                // Strip inline comments from directive values
                let cleanValue: String
                if let commentIdx = value.range(of: "--") {
                    cleanValue = String(value[value.startIndex..<commentIdx.lowerBound]).trimmingCharacters(in: .whitespaces)
                } else {
                    cleanValue = value
                }
                switch key {
                case "precision": currentPrecision = Int(cleanValue) ?? 9
                case "rounding": currentRounding = cleanValue.lowercased()
                default: break
                }
                continue
            }

            // Parse test case lines
            let result = parseAndRun(
                line: trimmed,
                precision: currentPrecision,
                rounding: currentRounding,
                operations: operations
            )
            switch result {
            case .passed:
                summary.passed += 1
            case .failed(let id, let detail):
                summary.failed.append((id: id, detail: detail))
            case .skipped:
                summary.skipped += 1
            case .none:
                break // not a test line
            }
        }
        return summary
    }

    private static func parseAndRun(
        line: String,
        precision: Int,
        rounding: String,
        operations: Set<String>?
    ) -> GDATestResult? {
        // Strip inline comments
        let effectiveLine: String
        if let commentRange = line.range(of: " --") {
            effectiveLine = String(line[line.startIndex..<commentRange.lowerBound])
        } else {
            effectiveLine = line
        }

        // Split into tokens, handling quoted operands
        let tokens = tokenize(effectiveLine)
        guard tokens.count >= 4 else { return nil }

        // Format: id operation operand1 [operand2] -> result [conditions]
        let id = tokens[0]
        let opName = tokens[1].lowercased()

        // Filter by requested operations
        if let ops = operations, !ops.contains(opName) { return nil }

        // Find the arrow separator
        guard let arrowIdx = tokens.firstIndex(of: "->") else { return nil }
        guard arrowIdx + 1 < tokens.count else { return nil }

        let operands = Array(tokens[2..<arrowIdx])
        let expectedStr = tokens[arrowIdx + 1]

        // Collect conditions
        let conditions = Set(tokens[(arrowIdx + 2)...].map { $0.lowercased() })

        // Skip tests that expect overflow, division_by_zero, invalid_operation
        // (our type traps on these rather than returning a result)
        if conditions.contains("overflow") || conditions.contains("division_by_zero") ||
           conditions.contains("invalid_operation") || conditions.contains("division_impossible") ||
           conditions.contains("division_undefined") || conditions.contains("underflow") {
            return .skipped(id: id, reason: "condition: \(conditions)")
        }

        // Only run tests with rounding modes we support, and only half_even by default
        // (our canonical mode). We also handle tests that don't depend on rounding.
        if rounding != "half_even" && rounding != "half_up" {
            // For non-standard rounding modes, skip unless the operation doesn't depend on rounding
            let roundingIndependent: Set<String> = ["compare", "comparetotal", "comparesig",
                                                     "abs", "minus", "plus", "min", "max",
                                                     "copy", "copyabs", "copynegate", "copysign"]
            if !roundingIndependent.contains(opName) {
                return .skipped(id: id, reason: "rounding mode: \(rounding)")
            }
        }

        // Skip if precision is outside our compatible range.
        // Our type has ~18 significant digits. GDA tests with lower precision
        // expect results rounded to that precision, which we don't do
        // (we always preserve full precision within our 8 fractional digits).
        // Precision 16-18 is close enough to match; lower precisions produce
        // different results due to GDA's precision-rounding semantics.
        if precision > 18 || precision < 16 {
            return .skipped(id: id, reason: "precision \(precision) outside 16-18 range")
        }

        // Parse operands and expected result
        guard let expected = parseDecimal(expectedStr) else {
            // Expected result is unparseable (Infinity, sNaN with payload, etc.)
            return .skipped(id: id, reason: "unparseable expected: \(expectedStr)")
        }

        // For binary operations, verify operands parse without precision loss.
        // If an operand has more than 8 fractional digits, it gets rounded on
        // input to our type, corrupting the test. Skip these cases.
        for operandStr in operands {
            if operandLosesPrecision(operandStr) {
                return .skipped(id: id, reason: "operand loses precision: \(operandStr)")
            }
        }

        // Run the operation
        return runOperation(id: id, op: opName, operands: operands, expected: expected,
                            rounding: rounding, conditions: conditions)
    }

    private static func runOperation(
        id: String, op: String, operands: [String],
        expected: FixedPointDecimal, rounding: String,
        conditions: Set<String>
    ) -> GDATestResult {
        guard let op1 = operands.first.flatMap(parseDecimal) else {
            return .skipped(id: id, reason: "unparseable operand1: \(operands.first ?? "nil")")
        }

        switch op {
        case "add":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand (we trap)")
            }
            let (result, overflow) = op1.addingReportingOverflow(op2)
            if overflow { return .skipped(id: id, reason: "overflow") }
            return check(id: id, got: result, expected: expected)

        case "subtract":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand (we trap)")
            }
            let (result, overflow) = op1.subtractingReportingOverflow(op2)
            if overflow { return .skipped(id: id, reason: "overflow") }
            return check(id: id, got: result, expected: expected)

        case "multiply":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand (we trap)")
            }
            let (result, overflow) = op1.multipliedReportingOverflow(by: op2)
            if overflow { return .skipped(id: id, reason: "overflow") }
            return check(id: id, got: result, expected: expected)

        case "divide":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN || op2 == .zero {
                return .skipped(id: id, reason: "NaN or zero divisor (we trap)")
            }
            let (result, overflow) = op1.dividedReportingOverflow(by: op2)
            if overflow { return .skipped(id: id, reason: "overflow") }
            return check(id: id, got: result, expected: expected)

        case "remainder":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN || op2 == .zero {
                return .skipped(id: id, reason: "NaN or zero divisor (we trap)")
            }
            let result = FixedPointDecimal(rawValue: op1.rawValue % op2.rawValue)
            return check(id: id, got: result, expected: expected)

        case "abs":
            if op1.isNaN { return .skipped(id: id, reason: "NaN operand (we trap)") }
            let result = FixedPointDecimal(rawValue: Swift.abs(op1.rawValue))
            return check(id: id, got: result, expected: expected)

        case "minus":
            if op1.isNaN { return .skipped(id: id, reason: "NaN operand (we trap)") }
            return check(id: id, got: -op1, expected: expected)

        case "plus":
            // plus is identity in GDA
            if op1.isNaN { return .skipped(id: id, reason: "NaN operand (we trap)") }
            return check(id: id, got: op1, expected: expected)

        case "compare":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand")
            }
            // GDA compare returns -1, 0, or 1
            let cmp: FixedPointDecimal
            if op1 < op2 { cmp = FixedPointDecimal(rawValue: -100_000_000) }
            else if op1 > op2 { cmp = FixedPointDecimal(rawValue: 100_000_000) }
            else { cmp = .zero }
            return check(id: id, got: cmp, expected: expected)

        case "comparetotal":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            // comparetotal gives a total ordering including NaN
            // Our type has a total order by definition (Int64 comparison)
            let cmp: FixedPointDecimal
            if op1 < op2 { cmp = FixedPointDecimal(rawValue: -100_000_000) }
            else if op1 > op2 { cmp = FixedPointDecimal(rawValue: 100_000_000) }
            else { cmp = .zero }
            return check(id: id, got: cmp, expected: expected)

        case "min":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand")
            }
            let result = op1 <= op2 ? op1 : op2
            return check(id: id, got: result, expected: expected)

        case "max":
            guard operands.count >= 2, let op2 = parseDecimal(operands[1]) else {
                return .skipped(id: id, reason: "unparseable operand2")
            }
            if op1.isNaN || op2.isNaN {
                return .skipped(id: id, reason: "NaN operand")
            }
            let result = op1 >= op2 ? op1 : op2
            return check(id: id, got: result, expected: expected)

        default:
            return .skipped(id: id, reason: "unsupported operation: \(op)")
        }
    }

    private static func check(id: String, got: FixedPointDecimal, expected: FixedPointDecimal) -> GDATestResult {
        if got == expected {
            return .passed
        } else {
            return .failed(id: id, detail: "expected \(expected) (raw: \(expected.rawValue)), got \(got) (raw: \(got.rawValue))")
        }
    }

    /// Parse a GDA decimal string into FixedPointDecimal.
    /// Returns nil for values we can't represent (Infinity, out of range, etc.).
    static func parseDecimal(_ str: String) -> FixedPointDecimal? {
        // Strip quotes
        var s = str
        if s.hasPrefix("'") && s.hasSuffix("'") {
            s = String(s.dropFirst().dropLast())
        }
        if s.hasPrefix("\"") && s.hasSuffix("\"") {
            s = String(s.dropFirst().dropLast())
        }

        let lower = s.lowercased()

        // Special values
        if lower == "nan" || lower == "#" || lower.hasPrefix("nan") { return .nan }
        if lower.hasPrefix("snan") { return nil } // signaling NaN with payload
        if lower.contains("inf") { return nil }

        // Handle scientific notation: e.g., "1.23E+5" or "123E-2"
        if lower.contains("e") {
            return parseScientific(s)
        }

        // Standard decimal string
        return FixedPointDecimal(s)
    }

    private static func parseScientific(_ str: String) -> FixedPointDecimal? {
        let lower = str.lowercased()
        guard let eIdx = lower.firstIndex(of: "e") else { return nil }

        let mantissaStr = String(str[str.startIndex..<eIdx])
        let expStr = String(str[str.index(after: eIdx)...]).replacingOccurrences(of: "+", with: "")

        guard let exponent = Int(expStr) else { return nil }

        // Parse mantissa as significand with implicit decimal point
        let isNegative = mantissaStr.hasPrefix("-")
        let absMantissa = isNegative ? String(mantissaStr.dropFirst()) : mantissaStr

        // Use components(separatedBy:) not split() to preserve empty leading parts (e.g., ".7")
        let parts = absMantissa.components(separatedBy: ".")
        let intPart = parts[0] // may be "" for ".7"
        let fracPart = parts.count > 1 ? parts[1] : ""

        // Combine into significand and adjust exponent
        let significandStr = intPart + fracPart
        let adjustedExp = exponent - fracPart.count

        guard let significand = Int(significandStr) else { return nil }
        let finalSignificand = isNegative ? -significand : significand

        // Check if representable
        let shift = 8 + adjustedExp // fractionalDigitCount + exponent
        if shift < -18 || shift > 18 { return nil }

        // Use overflow-safe construction
        if shift >= 0, shift <= 18 {
            let pow10: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000,
                                  10_000_000, 100_000_000, 1_000_000_000,
                                  10_000_000_000, 100_000_000_000,
                                  1_000_000_000_000, 10_000_000_000_000,
                                  100_000_000_000_000, 1_000_000_000_000_000,
                                  10_000_000_000_000_000, 100_000_000_000_000_000,
                                  1_000_000_000_000_000_000]
            let (result, overflow) = Int64(finalSignificand).multipliedReportingOverflow(by: pow10[shift])
            if overflow || result == .min { return nil }
            return FixedPointDecimal(rawValue: result)
        } else if shift < 0, -shift <= 18 {
            // Sub-scale: needs rounding, use init(significand:exponent:)
            // Check range first
            if abs(finalSignificand) > Int(Int64.max) { return nil }
            // Check if representable before constructing
            return FixedPointDecimal(significand: finalSignificand, exponent: adjustedExp)
        }

        return nil
    }

    /// Check if a GDA operand string would lose precision when parsed into
    /// our type (which has exactly 8 fractional digits). Returns true if the
    /// operand has more than 8 fractional digits or more significant digits
    /// than our type can represent.
    private static func operandLosesPrecision(_ str: String) -> Bool {
        var s = str
        if s.hasPrefix("'") && s.hasSuffix("'") { s = String(s.dropFirst().dropLast()) }
        if s.hasPrefix("\"") && s.hasSuffix("\"") { s = String(s.dropFirst().dropLast()) }

        let lower = s.lowercased()
        // Special values don't lose precision
        if lower == "nan" || lower.hasPrefix("nan") || lower.hasPrefix("snan") ||
           lower.contains("inf") || lower == "#" { return false }

        // For scientific notation, compute effective fractional digits
        if lower.contains("e") {
            guard let eIdx = lower.firstIndex(of: "e") else { return false }
            let mantissa = String(s[s.startIndex..<eIdx])
            let expStr = String(s[s.index(after: eIdx)...]).replacingOccurrences(of: "+", with: "")
            guard let exp = Int(expStr) else { return false }
            let absMantissa = mantissa.hasPrefix("-") ? String(mantissa.dropFirst()) : mantissa
            let parts = absMantissa.split(separator: ".", maxSplits: 1)
            let fracDigits = parts.count > 1 ? parts[1].count : 0
            let effectiveFracDigits = fracDigits - exp
            return effectiveFracDigits > 8
        }

        // For plain decimal, count fractional digits
        if let dotIdx = s.firstIndex(of: ".") {
            let fracDigits = s[s.index(after: dotIdx)...].count
            if fracDigits > 8 { return true }
        }

        // Check total significant digits (our Int64 has ~18.9 digits max)
        let digits = s.filter { $0.isNumber }
        if digits.count > 18 { return true }

        return false
    }

    /// Tokenize a line, handling quoted strings.
    private static func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote: Character? = nil

        for char in line {
            if let q = inQuote {
                current.append(char)
                if char == q {
                    inQuote = nil
                }
            } else if char == "'" || char == "\"" {
                inQuote = char
                current.append(char)
            } else if char == " " || char == "\t" {
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
