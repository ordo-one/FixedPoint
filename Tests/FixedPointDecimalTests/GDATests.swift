import Testing
import Foundation
@testable import FixedPointDecimal

/// Tests against the General Decimal Arithmetic (GDA) test suite.
/// Source: https://speleotrove.com/decimal/
/// License: ICU License (see Resources/GDA/LICENSE)
@Suite("General Decimal Arithmetic")
struct GDATests {

    /// Run GDA tests. Tests whose operands lose precision when parsed into
    /// our fixed 8-fractional-digit type are automatically skipped by the
    /// runner. All remaining tests must pass exactly.
    private func runGDA(
        files: [String],
        operations: Set<String>? = nil,
        minPassed: Int = 1,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        var totalSummary = GDATestSummary()

        for filename in files {
            guard let url = Bundle.module.url(forResource: filename, withExtension: "decTest",
                                              subdirectory: "Resources/GDA") else {
                Issue.record("GDA test file not found: \(filename).decTest", sourceLocation: sourceLocation)
                continue
            }
            let summary = try GDATestRunner.run(contentsOf: url, operations: operations)
            totalSummary.passed += summary.passed
            totalSummary.failed += summary.failed
            totalSummary.skipped += summary.skipped
        }

        for failure in totalSummary.failed {
            Issue.record("GDA \(failure.id): \(failure.detail)", sourceLocation: sourceLocation)
        }
        #expect(totalSummary.failed.isEmpty,
                "GDA: \(totalSummary.description)", sourceLocation: sourceLocation)
        #expect(totalSummary.passed >= minPassed,
                "Expected at least \(minPassed) passing tests, got \(totalSummary.passed)",
                sourceLocation: sourceLocation)
    }

    // MARK: - Supported Operations

    @Test("GDA addition")
    func gdaAdd() throws {
        try runGDA(files: ["add", "ddAdd"], operations: ["add"], minPassed: 50)
    }

    @Test("GDA subtraction")
    func gdaSubtract() throws {
        try runGDA(files: ["subtract", "ddSubtract"], operations: ["subtract"], minPassed: 50)
    }

    @Test("GDA multiplication")
    func gdaMultiply() throws {
        try runGDA(files: ["multiply", "ddMultiply"], operations: ["multiply"], minPassed: 50)
    }

    @Test("GDA division")
    func gdaDivide() throws {
        try runGDA(files: ["divide", "ddDivide"], operations: ["divide"], minPassed: 50)
    }

    @Test("GDA remainder")
    func gdaRemainder() throws {
        try runGDA(files: ["remainder", "ddRemainder"], operations: ["remainder"], minPassed: 10)
    }

    @Test("GDA absolute value")
    func gdaAbs() throws {
        try runGDA(files: ["abs", "ddAbs"], operations: ["abs"], minPassed: 10)
    }

    @Test("GDA negation (minus)")
    func gdaMinus() throws {
        try runGDA(files: ["minus", "ddMinus"], operations: ["minus"], minPassed: 10)
    }

    @Test("GDA comparison")
    func gdaCompare() throws {
        try runGDA(files: ["compare", "ddCompare"], operations: ["compare"], minPassed: 50)
    }

    @Test("GDA total order comparison",
          .disabled("GDA comparetotal distinguishes exponent/trailing zeros (e.g., 12.30 vs 12.3) which our fixed-point type does not track"))
    func gdaCompareTotalOrder() throws {
        try runGDA(files: ["comparetotal", "ddCompareTotal"], operations: ["comparetotal"], minPassed: 10)
    }

    @Test("GDA min")
    func gdaMin() throws {
        try runGDA(files: ["min", "ddMin"], operations: ["min"], minPassed: 10)
    }

    @Test("GDA max")
    func gdaMax() throws {
        try runGDA(files: ["max", "ddMax"], operations: ["max"], minPassed: 10)
    }

    @Test("GDA plus (identity)")
    func gdaPlus() throws {
        try runGDA(files: ["plus", "ddPlus"], operations: ["plus"], minPassed: 10)
    }

    // MARK: - Unsupported Operations (ready to enable)

    @Test("GDA square root", .disabled("sqrt not yet implemented"))
    func gdaSqrt() throws {
        try runGDA(files: ["squareroot", "ddSquareRoot"], operations: ["squareroot"], minPassed: 10)
    }

    @Test("GDA exp", .disabled("exp not yet implemented"))
    func gdaExp() throws {
        try runGDA(files: ["exp"], operations: ["exp"], minPassed: 10)
    }

    @Test("GDA ln", .disabled("ln not yet implemented"))
    func gdaLn() throws {
        try runGDA(files: ["ln"], operations: ["ln"], minPassed: 10)
    }

    @Test("GDA log10", .disabled("log10 not yet implemented"))
    func gdaLog10() throws {
        try runGDA(files: ["log10"], operations: ["log10"], minPassed: 10)
    }

    @Test("GDA fused multiply-add", .disabled("fma not yet implemented"))
    func gdaFMA() throws {
        try runGDA(files: ["fma", "ddFMA"], operations: ["fma"], minPassed: 10)
    }

    @Test("GDA power", .disabled("GDA power uses decimal exponents; we only support integer exponents"))
    func gdaPower() throws {
        try runGDA(files: ["power"], operations: ["power"], minPassed: 10)
    }

    @Test("GDA quantize", .disabled("quantize not yet implemented"))
    func gdaQuantize() throws {
        try runGDA(files: ["quantize", "ddQuantize"], operations: ["quantize"], minPassed: 10)
    }
}
