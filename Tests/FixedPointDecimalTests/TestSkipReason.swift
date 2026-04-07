/// Reason a test vector was skipped by an external test suite runner.
enum TestSkipReason: String, CaseIterable, CustomStringConvertible {
    /// Rounding mode is not half_even (our canonical rounding mode)
    case rounding = "rounding"
    /// Value is outside our representable range (~92 billion with 8 fractional digits)
    case outOfRange = "out-of-range"
    /// Operand has more than 8 fractional digits, would lose precision on input
    case precisionLoss = "precision-loss"
    /// Test expects overflow, division by zero, invalid operation, or underflow (we trap)
    case exceptionFlags = "exception-flags"
    /// Operand or expected result is NaN (we trap on arithmetic with NaN)
    case nan = "NaN"
    /// Operand is zero divisor
    case zeroDivisor = "zero-divisor"
    /// Result overflows our Int64 range during computation
    case overflow = "overflow"
    /// GDA precision setting outside our compatible range (16-18)
    case precision = "precision"
    /// GDA condition flags (overflow, underflow, etc.)
    case condition = "condition"
    /// Unparseable operand or result (infinity, sNaN with payload, etc.)
    case unparseable = "unparseable"
    /// Operation not supported
    case unsupportedOp = "unsupported-op"

    var description: String { rawValue }
}

/// Tracks skip reason counts for test summary output.
struct SkipReasonCounter {
    private var counts: [TestSkipReason: Int] = [:]

    mutating func record(_ reason: TestSkipReason) {
        counts[reason, default: 0] += 1
    }

    mutating func merge(_ other: SkipReasonCounter) {
        for (reason, count) in other.counts {
            counts[reason, default: 0] += count
        }
    }

    var total: Int {
        counts.values.reduce(0, +)
    }

    var description: String {
        guard !counts.isEmpty else { return "" }
        let sorted = counts.sorted { $0.value > $1.value }
        return sorted.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}
