import Testing
import Foundation
@testable import FixedPointDecimal

/// Tests against Fahmy/Cairo University decimal64 test vectors.
/// Source: http://eece.cu.edu.eg/~hfahmy/arith_debug/
/// License: Permissive with attribution (see Resources/Fahmy/LICENSE)
///
/// These directed test vectors found bugs in IBM decNumber and Intel's
/// decimal floating-point library. Only vectors whose operands and results
/// fit within FixedPointDecimal's range are executed; the rest are skipped.
@Suite("Fahmy Decimal64")
struct FahmyTests {

    private func runFahmy(
        file: String,
        operation: Character,
        minPassed: Int = 1,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        guard let url = Bundle.module.url(forResource: file, withExtension: "txt",
                                          subdirectory: "Resources/Fahmy") else {
            Issue.record("Fahmy test file not found: \(file).txt", sourceLocation: sourceLocation)
            return
        }
        let summary = try FahmyTestRunner.run(contentsOf: url, operation: operation)

        print("  Fahmy [\(file)]: \(summary.description)")

        for failure in summary.failed {
            Issue.record("Fahmy line \(failure.line): \(failure.detail)", sourceLocation: sourceLocation)
        }
        #expect(summary.failed.isEmpty,
                "Fahmy: \(summary.description)", sourceLocation: sourceLocation)
        #expect(summary.passed >= minPassed,
                "Expected at least \(minPassed) passing tests, got \(summary.passed) (\(summary.description))",
                sourceLocation: sourceLocation)
    }

    // MARK: - Supported Operations

    @Test("Fahmy d64 addition")
    func fahmyAdd() throws {
        // Pre-filtered to vectors with exponents in [-24, 2]; of those,
        // ~34 pass the precision-loss and range checks with half_even rounding
        try runFahmy(file: "d64_add", operation: "+", minPassed: 20)
    }

    @Test("Fahmy d64 multiplication")
    func fahmyMul() throws {
        try runFahmy(file: "d64_mul", operation: "*", minPassed: 1)
    }

    @Test("Fahmy d64 division")
    func fahmyDiv() throws {
        try runFahmy(file: "d64_div", operation: "/", minPassed: 1)
    }

    // MARK: - Unsupported Operations

    @Test("Fahmy d64 sqrt", .disabled("sqrt not yet implemented"))
    func fahmySqrt() throws {
        // Would need d64_sqrt.txt from http://eece.cu.edu.eg/~hfahmy/arith_debug/2011_03_d64_sqrt.zip
    }

    @Test("Fahmy d64 fma", .disabled("fma not yet implemented"))
    func fahmyFMA() throws {
        // Would need d64_fma.txt from http://eece.cu.edu.eg/~hfahmy/arith_debug/2010_07_d64_fma.zip
    }
}
