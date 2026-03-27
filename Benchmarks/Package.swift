// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .visionOS(.v2),
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.27.0"),
    ],
    targets: [
        .executableTarget(
            name: "FixedPointDecimalBenchmarks",
            dependencies: [
                .product(name: "FixedPointDecimal", package: "FixedPoint"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks/FixedPointDecimalBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
