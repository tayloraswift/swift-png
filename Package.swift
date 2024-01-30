// swift-tools-version:5.5
import PackageDescription

let package:Package = .init(name: "swift-png",
    platforms: [.macOS(.v10_15)],
    products:
    [
        .library(   name: "LZ77",                       targets: ["LZ77"]),
        .library(   name: "PNG",                        targets: ["PNG"]),

        .executable(name: "PNGTests",                   targets: ["PNGTests"]),
        .executable(name: "PNGIntegrationTests",        targets: ["PNGIntegrationTests"]),
        .executable(name: "PNGCompressionTests",        targets: ["PNGCompressionTests"]),

        .executable(name: "compression-benchmark",      targets: ["PNGCompressionBenchmarks"]),
        .executable(name: "decompression-benchmark",    targets: ["PNGDecompressionBenchmarks"]),
    ],
    dependencies:
    [
        .package(url: "https://github.com/tayloraswift/swift-hash", .upToNextMinor(
            from: "0.5.0")),
        .package(url: "https://github.com/tayloraswift/swift-grammar", .upToNextMinor(
            from: "0.3.4")),
    ],
    targets:
    [
        .target(name: "LZ77"),

        .target(name: "PNG",
            dependencies:
            [
                .target(name: "LZ77"),
                .product(name: "CRC", package: "swift-hash"),
            ]),

        .target(name: "PNGInspection",
            dependencies:
            [
                .target(name: "PNG"),
            ]),

        .executableTarget(name: "LZ77Tests",
            dependencies:
            [
                .target(name: "LZ77"),
                .product(name: "Testing", package: "swift-grammar"),
            ],
            swiftSettings:
            [
                .define("DEBUG", .when(configuration: .debug))
            ]),

        .executableTarget(name: "PNGTests",
            dependencies:
            [
                .target(name: "PNG"),
                .product(name: "Testing", package: "swift-grammar"),
            ],
            swiftSettings:
            [
                .define("DEBUG", .when(configuration: .debug))
            ]),

        .executableTarget(name: "PNGIntegrationTests",
            dependencies:
            [
                .target(name: "PNG"),
                .product(name: "Testing", package: "swift-grammar"),
            ],
            exclude:
            [
                "PngSuite.LICENSE",
                "PngSuite.README",
                "Inputs/",
                "Outputs/",
                "RGBA/",
            ]),

        .executableTarget(name: "PNGCompressionTests",
            dependencies:
            [
                .target(name: "PNG"),
                .product(name: "Testing", package: "swift-grammar"),
            ]),

        .executableTarget(name: "PNGCompressionBenchmarks",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/Compression/Swift"),

        .executableTarget(name: "PNGDecompressionBenchmarks",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/Decompression/Swift"),
    ],
    swiftLanguageVersions: [.v5]
)
