import Testing
import Foundation
@testable import FixedPointDecimal

/// Tests against Intel Decimal Floating-Point Math Library test vectors.
/// Source: https://netlib.org/misc/intel/
/// License: BSD 3-Clause (see Resources/Intel/LICENSE)
///
/// Test vectors are pre-filtered to bid64 arithmetic operations.
/// The runner decodes BID64 hex-encoded operands and skips vectors
/// whose values fall outside our representable range.
@Suite("Intel Decimal64")
struct IntelTests {

    private func runIntel(
        operations: Set<String>,
        minPassed: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        guard let url = Bundle.module.url(forResource: "readtest_bid64", withExtension: "in",
                                          subdirectory: "Resources/Intel") else {
            Issue.record("Intel test file not found: readtest_bid64.in", sourceLocation: sourceLocation)
            return
        }
        let summary = try IntelTestRunner.run(contentsOf: url, operations: operations)

        for failure in summary.failed {
            Issue.record("Intel line \(failure.line): \(failure.detail)", sourceLocation: sourceLocation)
        }
        #expect(summary.failed.isEmpty,
                "Intel: \(summary.description)", sourceLocation: sourceLocation)
        #expect(summary.passed >= minPassed,
                "Expected at least \(minPassed) passing tests, got \(summary.passed) (\(summary.description))",
                sourceLocation: sourceLocation)
    }

    // MARK: - Supported Operations

    @Test("Intel bid64 addition")
    func intelAdd() throws {
        try runIntel(operations: ["bid64_add"], minPassed: 1)
    }

    @Test("Intel bid64 subtraction")
    func intelSub() throws {
        try runIntel(operations: ["bid64_sub"], minPassed: 1)
    }

    @Test("Intel bid64 multiplication")
    func intelMul() throws {
        // Most BID64 mul vectors max out significand precision; few pass the filter
        try runIntel(operations: ["bid64_mul"])
    }

    @Test("Intel bid64 division")
    func intelDiv() throws {
        // Most BID64 div vectors max out significand precision; few pass the filter
        try runIntel(operations: ["bid64_div"])
    }

    @Test("Intel bid64 abs")
    func intelAbs() throws {
        try runIntel(operations: ["bid64_abs"], minPassed: 1)
    }

    @Test("Intel bid64 negate")
    func intelNegate() throws {
        try runIntel(operations: ["bid64_negate"], minPassed: 1)
    }
}
