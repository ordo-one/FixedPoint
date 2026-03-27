import Benchmark
import FixedPointDecimal
import Foundation

let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountTotal,
        .instructions,
    ]

    let defaultConfiguration = Benchmark.Configuration(
        metrics: defaultMetrics,
        scalingFactor: .mega
    )

    // MARK: - Addition

    Benchmark("FixedPointDecimal addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("FixedPointDecimal wrapping addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated &+ delta
        }
    }

    Benchmark("Foundation Decimal addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    // MARK: - Subtraction

    Benchmark("FixedPointDecimal subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(99999.99999999)
        let delta = FixedPointDecimal(0.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("FixedPointDecimal wrapping subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(99999.99999999)
        let delta = FixedPointDecimal(0.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated &- delta
        }
    }

    Benchmark("Foundation Decimal subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(string: "99999.99999999")!
        let delta = Foundation.Decimal(string: "0.00000001")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    // MARK: - Multiplication

    Benchmark("FixedPointDecimal multiplication", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(12345.67890123)
        let factor = FixedPointDecimal(1.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated * factor
        }
    }

    Benchmark("FixedPointDecimal wrapping multiplication", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(12345.67890123)
        let factor = FixedPointDecimal(1.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated &* factor
        }
    }

    Benchmark("Foundation Decimal multiplication", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(string: "12345.67890123")!
        let factor = Foundation.Decimal(string: "1.00000001")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated * factor
        }
    }

    // MARK: - Division

    Benchmark("FixedPointDecimal division", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(12345.67890123)
        let divisor = FixedPointDecimal(1.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated / divisor
        }
    }

    Benchmark("Foundation Decimal division", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(string: "12345.67890123")!
        let divisor = Foundation.Decimal(string: "1.00000001")!

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated / divisor
        }
    }

    // MARK: - Comparison

    Benchmark("FixedPointDecimal comparison", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        let threshold = FixedPointDecimal(99999.99999999)
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if accumulated < threshold { count &+= 1 }
            accumulated = accumulated + delta
        }
        blackHole(count)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal comparison", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        let threshold = Foundation.Decimal(string: "99999.99999999")!
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if accumulated < threshold { count &+= 1 }
            accumulated = accumulated + delta
        }
        blackHole(count)
        blackHole(accumulated)
    }

    // MARK: - Equality

    Benchmark("FixedPointDecimal equality", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        let target = FixedPointDecimal(99999.99999999)
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if accumulated == target { count &+= 1 }
            accumulated = accumulated + delta
        }
        blackHole(count)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal equality", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        let threshold = Foundation.Decimal(string: "99999.99999999")!
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            if accumulated == threshold { count &+= 1 }
            accumulated = accumulated + delta
        }
        blackHole(count)
        blackHole(accumulated)
    }

    // MARK: - Hashing

    Benchmark("FixedPointDecimal hash", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        var hashAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(accumulated)
            hashAccumulator ^= hasher.finalize()
            accumulated = accumulated + delta
        }
        blackHole(hashAccumulator)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal hash", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        var hashAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(accumulated)
            hashAccumulator ^= hasher.finalize()
            accumulated = accumulated + delta
        }
        blackHole(hashAccumulator)
        blackHole(accumulated)
    }

    // MARK: - String Formatting

    Benchmark("FixedPointDecimal description", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        var lengthAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            lengthAccumulator &+= accumulated.description.count
            accumulated = accumulated + delta
        }
        blackHole(lengthAccumulator)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal description", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        var lengthAccumulator: Int = 0

        for _ in benchmark.scaledIterations {
            lengthAccumulator &+= accumulated.description.count
            accumulated = accumulated + delta
        }
        blackHole(lengthAccumulator)
        blackHole(accumulated)
    }

    // MARK: - Double Conversion

    Benchmark("FixedPointDecimal to Double", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        var doubleAccumulator: Double = 0

        for _ in benchmark.scaledIterations {
            doubleAccumulator += Double(accumulated)
            accumulated = accumulated + delta
        }
        blackHole(doubleAccumulator)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal to Double", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        var doubleAccumulator: Double = 0

        for _ in benchmark.scaledIterations {
            doubleAccumulator += NSDecimalNumber(decimal: accumulated).doubleValue
            accumulated = accumulated + delta
        }
        blackHole(doubleAccumulator)
        blackHole(accumulated)
    }

    // MARK: - Construction: Constant vs Runtime Parsing

    Benchmark("FixedPointDecimal constant (pre-computed)", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + FixedPointDecimal(12345.67890123)
        }
        blackHole(accumulated)
    }

    Benchmark("FixedPointDecimal runtime string parse", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let s = "12345.67890123"

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + FixedPointDecimal(s)!
        }
        blackHole(accumulated)
    }

    // MARK: - Construction: significand + exponent (wire format)

    Benchmark("FixedPointDecimal init(significand:exponent:)", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + FixedPointDecimal(significand: 12345, exponent: -2)
        }
        blackHole(accumulated)
    }

    // MARK: - Construction: from Double

    Benchmark("FixedPointDecimal init(Double)", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let values: [Double] = [123.45, 0.001, 99999.99, 42.0, 0.12345678]
        var i = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + FixedPointDecimal(values[i % values.count])
            i &+= 1
        }
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal init(Double)", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let values: [Double] = [123.45, 0.001, 99999.99, 42.0, 0.12345678]
        var i = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + Foundation.Decimal(values[i % values.count])
            i &+= 1
        }
        blackHole(accumulated)
    }

    // MARK: - Rounding

    Benchmark("FixedPointDecimal rounded(scale:)", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated.rounded(scale: 2))
            accumulated = accumulated + delta
        }
    }

    Benchmark("Foundation Decimal rounded(scale:)", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        var handler = NSDecimalNumberHandler(
            roundingMode: .bankers, scale: 2,
            raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false)

        for _ in benchmark.scaledIterations {
            var result = Decimal()
            var value = accumulated
            NSDecimalRound(&result, &value, 2, .bankers)
            blackHole(result)
            accumulated = accumulated + delta
        }
        blackHole(handler)
    }

    // MARK: - JSON Encoding

    Benchmark("FixedPointDecimal JSON encode", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(0)
        let delta = FixedPointDecimal(0.00000001)
        let encoder = JSONEncoder()
        var byteCount: Int = 0

        for _ in benchmark.scaledIterations {
            byteCount &+= try encoder.encode(accumulated).count
            accumulated = accumulated + delta
        }
        blackHole(byteCount)
        blackHole(accumulated)
    }

    Benchmark("Foundation Decimal JSON encode", configuration: defaultConfiguration) { benchmark in
        var accumulated = Foundation.Decimal(0)
        let delta = Foundation.Decimal(string: "0.00000001")!
        let encoder = JSONEncoder()
        var byteCount: Int = 0

        for _ in benchmark.scaledIterations {
            byteCount &+= try encoder.encode(accumulated).count
            accumulated = accumulated + delta
        }
        blackHole(byteCount)
        blackHole(accumulated)
    }

    // MARK: - JSON Decoding

    Benchmark("FixedPointDecimal JSON decode", configuration: defaultConfiguration) { benchmark in
        let data = "\"12345.67890123\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            let value = try decoder.decode(FixedPointDecimal.self, from: data)
            blackHole(value)
            count &+= 1
        }
        blackHole(count)
    }

    Benchmark("Foundation Decimal JSON decode", configuration: defaultConfiguration) { benchmark in
        let data = "12345.67890123".data(using: .utf8)!
        let decoder = JSONDecoder()
        var count: Int = 0

        for _ in benchmark.scaledIterations {
            let value = try decoder.decode(Foundation.Decimal.self, from: data)
            blackHole(value)
            count &+= 1
        }
        blackHole(count)
    }
}
