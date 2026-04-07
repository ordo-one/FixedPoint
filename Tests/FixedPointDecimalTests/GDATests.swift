import Testing
import Foundation
@testable import FixedPointDecimal

/// Tests against the General Decimal Arithmetic (GDA) test suite.
/// Source: https://speleotrove.com/decimal/
/// License: ICU License (see Resources/GDA/LICENSE)
@Suite("General Decimal Arithmetic")
struct GDATests {

    /// Run GDA tests, allowing a small number of precision-mismatch failures.
    ///
    /// GDA tests use variable precision (typically 9 or 16 significant digits)
    /// with precision-based rounding. Our type has fixed 8 fractional digits
    /// (~18 significant digits) with banker's rounding to the 8th decimal place.
    /// Some edge cases will produce different results due to these fundamental
    /// differences. The `maxExpectedFailures` parameter allows for these known
    /// precision mismatches while still catching genuine arithmetic bugs.
    private func runGDA(
        files: [String],
        operations: Set<String>? = nil,
        minPassed: Int = 1,
        maxExpectedFailures: Int = 0,
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

        #expect(totalSummary.failed.count <= maxExpectedFailures,
                "GDA: \(totalSummary.description) (max expected: \(maxExpectedFailures))",
                sourceLocation: sourceLocation)
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
        // ~7 precision mismatches: GDA precision-16 rounding vs our 8-fractional-digit rounding
        try runGDA(files: ["multiply", "ddMultiply"], operations: ["multiply"], minPassed: 50,
                   maxExpectedFailures: 10)
    }

    @Test("GDA division")
    func gdaDivide() throws {
        // ~4 precision mismatches in last-digit rounding
        try runGDA(files: ["divide", "ddDivide"], operations: ["divide"], minPassed: 50,
                   maxExpectedFailures: 10)
    }

    @Test("GDA remainder")
    func gdaRemainder() throws {
        // ~3 mismatches: GDA remainder uses round-to-nearest quotient semantics
        try runGDA(files: ["remainder", "ddRemainder"], operations: ["remainder"], minPassed: 10,
                   maxExpectedFailures: 5)
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
        // ~4 mismatches: GDA distinguishes trailing-zero representations (1.0 vs 1.00)
        try runGDA(files: ["compare", "ddCompare"], operations: ["compare"], minPassed: 50,
                   maxExpectedFailures: 5)
    }

    @Test("GDA total order comparison")
    func gdaCompareTotalOrder() throws {
        // ~100 mismatches: GDA total order distinguishes exponent/precision which
        // our fixed-point type does not track (e.g., 1.0 and 1.00 differ in GDA
        // total order but are identical in our representation). Also, GDA total
        // order has specific NaN and negative-zero ordering rules we don't support.
        try runGDA(files: ["comparetotal", "ddCompareTotal"], operations: ["comparetotal"], minPassed: 10,
                   maxExpectedFailures: 110)
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
