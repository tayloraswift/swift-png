// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "PNG",
    products:
    [
        .library(   name: "png",                        targets: ["PNG"]),
        .executable(name: "unit-test",                  targets: ["PNGUnitTests"]),
        .executable(name: "integration-test",           targets: ["PNGIntegrationTests"]),
        .executable(name: "compression-test",           targets: ["PNGCompressionTests"]),
        .executable(name: "compression-benchmark",      targets: ["PNGCompressionBenchmarks"]), 
        .executable(name: "decompression-benchmark",    targets: ["PNGDecompressionBenchmarks"]), 
    ],
    targets: 
    [
        .target(name: "PNG",                        dependencies: [],       path: "sources/png"),
        
        .target(name: "PNGUnitTests",               dependencies: ["PNG"],  path: "tests/unit"),
        .target(name: "PNGIntegrationTests",        dependencies: ["PNG"],  path: "tests/integration"),
        .target(name: "PNGCompressionTests",        dependencies: ["PNG"],  path: "tests/compression"),
        .target(name: "PNGCompressionBenchmarks",   dependencies: ["PNG"],  path: "benchmarks/encode/swift"), 
        .target(name: "PNGDecompressionBenchmarks", dependencies: ["PNG"],  path: "benchmarks/decode/swift"), 
    ],
    swiftLanguageVersions: [.v5]
)
