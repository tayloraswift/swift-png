// swift-tools-version:5.8
import PackageDescription

let package:Package = .init(name: "swift-png",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(name: "LZ77", targets: ["LZ77"]),
        .library(name: "PNG", targets: ["PNG"]),

        .executable(name: "compression-benchmark", targets: ["PNGCompressionBenchmarks"]),
        .executable(name: "decompression-benchmark", targets: ["PNGDecompressionBenchmarks"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stackotter/swift-hash", .upToNextMinor(from: "0.6.4")),
        .package(url: "https://github.com/tayloraswift/swift-grammar", .upToNextMinor(
            from: "0.4.0")),
    ],
    targets: [
        .target(name: "LZ77",
            dependencies: [
                .product(name: "CRC", package: "swift-hash"),
            ]),

        .target(name: "PNG",
            dependencies: [
                .target(name: "LZ77"),
            ]),

        .target(name: "PNGInspection",
            dependencies: [
                .target(name: "PNG"),
            ]),

        .executableTarget(name: "LZ77Tests",
            dependencies: [
                .target(name: "LZ77"),
                .product(name: "Testing_", package: "swift-grammar"),
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]),

        .executableTarget(name: "PNGTests",
            dependencies: [
                .target(name: "PNG"),
                .product(name: "Testing_", package: "swift-grammar"),
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]),

        .executableTarget(name: "PNGIntegrationTests",
            dependencies: [
                .target(name: "PNG"),
                .product(name: "Testing_", package: "swift-grammar"),
            ],
            exclude: [
                "PngSuite.LICENSE",
                "PngSuite.README",
                "Inputs/",
                "Outputs/",
                "RGBA/",
            ]),

        .executableTarget(name: "PNGCompressionTests",
            dependencies: [
                .target(name: "PNG"),
                .product(name: "Testing_", package: "swift-grammar"),
            ]),

        .executableTarget(name: "PNGCompressionBenchmarks",
            dependencies: [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/Compression/Swift"),

        .executableTarget(name: "PNGDecompressionBenchmarks",
            dependencies: [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/Decompression/Swift"),
    ],
    swiftLanguageVersions: [.v5]
)

for target:PackageDescription.Target in package.targets
{
    {
        var settings:[PackageDescription.SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("BareSlashRegexLiterals"))
        settings.append(.enableUpcomingFeature("ConciseMagicFile"))
        settings.append(.enableUpcomingFeature("ExistentialAny"))

        //  settings.append(.unsafeFlags(["-parse-as-library"], .when(platforms: [.windows])))

        $0 = settings
    } (&target.swiftSettings)
}
