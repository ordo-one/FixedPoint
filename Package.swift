// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FixedPointDecimal",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "FixedPointDecimal",
            targets: ["FixedPointDecimal"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FixedPointDecimal"
        ),
        .testTarget(
            name: "FixedPointDecimalTests",
            dependencies: ["FixedPointDecimal"]
        ),
    ]
)

for target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
        $0 = settings
    }(&target.swiftSettings)
}
