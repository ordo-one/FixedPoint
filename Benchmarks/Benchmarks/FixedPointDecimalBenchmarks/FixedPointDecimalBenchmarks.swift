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

    // MARK: - Independent operations over operand tables
    //
    // The benchmarks above chain each result into the next call, so they measure latency on one
    // value sequence. These run independent operations over 1024 operand pairs, in two data
    // shapes, because whether the banker's-rounding step is predictable depends on the data:
    // price × whole quantity is exact (remainder 0, never rounds), arbitrary 8-digit values round
    // up or down at random. Synthetic data from a fixed seed.

    let tableSize = 1024
    var generator = BenchmarkRandom(seed: 0x00F1_DE0D)
    // Prices with 2 decimals (0.01 ... 9 999.99) and whole quantities (1 ... 10 000): exact products.
    let prices = (0 ..< tableSize).map { _ in
        FixedPointDecimal(rawValue: Int64(generator.next(upTo: 999_999) + 1) * 1_000_000)
    }
    let quantities = (0 ..< tableSize).map { _ in
        FixedPointDecimal(rawValue: Int64(generator.next(upTo: 10_000) + 1) * 100_000_000)
    }
    // Arbitrary 8-digit values: factors in 0 ... 100 000 and 0 ... 1 000; dividends up to
    // 1 000 000 (mostly the wide 128-bit path) over divisors in 0.01 ... 1 000.
    let factorsA = (0 ..< tableSize).map { _ in FixedPointDecimal(rawValue: Int64(generator.next(upTo: 10_000_000_000_000))) }
    let factorsB = (0 ..< tableSize).map { _ in FixedPointDecimal(rawValue: Int64(generator.next(upTo: 100_000_000_000))) }
    let dividends = (0 ..< tableSize).map { _ in FixedPointDecimal(rawValue: Int64(generator.next(upTo: 100_000_000_000_000))) }
    let divisors = (0 ..< tableSize).map { _ in
        FixedPointDecimal(rawValue: Int64(generator.next(upTo: 100_000_000_000) + 1_000_000))
    }

    Benchmark("FixedPointDecimal multiplication table exact (price × quantity)",
              configuration: defaultConfiguration) { benchmark in
        for i in benchmark.scaledIterations {
            blackHole(prices[i & (tableSize - 1)] * quantities[i & (tableSize - 1)])
        }
    }

    Benchmark("FixedPointDecimal multiplication table inexact", configuration: defaultConfiguration) { benchmark in
        for i in benchmark.scaledIterations {
            blackHole(factorsA[i & (tableSize - 1)] * factorsB[i & (tableSize - 1)])
        }
    }

    Benchmark("FixedPointDecimal division table inexact", configuration: defaultConfiguration) { benchmark in
        for i in benchmark.scaledIterations {
            blackHole(dividends[i & (tableSize - 1)] / divisors[i & (tableSize - 1)])
        }
    }

    Benchmark("FixedPointDecimal division table exact (notional ÷ quantity)",
              configuration: defaultConfiguration) { benchmark in
        for i in benchmark.scaledIterations {
            let index = i & (tableSize - 1)
            blackHole((prices[index] * quantities[index]) / quantities[index])
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

    // Runtime exponents, so the power-of-10 lookup can't be constant-folded.
    Benchmark("FixedPointDecimal init(significand:exponent:) runtime exponent",
              configuration: defaultConfiguration) { benchmark in
        let exponents = [-10, -8, -6, -4, -2, 0, 1, 2]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(FixedPointDecimal(significand: 12345, exponent: exponents[i % exponents.count]))
            i &+= 1
        }
    }

    // MARK: - pow(10, n) vs pow(x, n)

    Benchmark("FixedPointDecimal pow(10, n)", configuration: defaultConfiguration) { benchmark in
        let ten: FixedPointDecimal = 10
        let exponents = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(FixedPointDecimal.pow(ten, exponents[i % exponents.count]))
            i &+= 1
        }
    }

    Benchmark("FixedPointDecimal pow(2, n)", configuration: defaultConfiguration) { benchmark in
        let two: FixedPointDecimal = 2
        let exponents = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(FixedPointDecimal.pow(two, exponents[i % exponents.count]))
            i &+= 1
        }
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

    // Runtime scales, so the power-of-10 lookup can't be constant-folded.
    Benchmark("FixedPointDecimal rounded(scale:) runtime scale", configuration: defaultConfiguration) { benchmark in
        var accumulated: FixedPointDecimal = 123.45678912
        let delta = FixedPointDecimal(0.00000001)
        let scales = [0, 1, 2, 3, 4, 5, 6, 7]
        var i = 0

        for _ in benchmark.scaledIterations {
            blackHole(accumulated.rounded(scale: scales[i % scales.count]))
            accumulated = accumulated + delta
            i &+= 1
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

/// SplitMix64, so the operand tables are the same on every run and machine.
struct BenchmarkRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    /// A value in `0 ..< bound` (modulo bias is irrelevant here).
    mutating func next(upTo bound: UInt64) -> UInt64 { next() % bound }
}
