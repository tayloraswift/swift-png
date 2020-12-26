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
        
        .executable(name: "decode-basic",               targets: ["PNGDecodeBasic"]),
        .executable(name: "encode-basic",               targets: ["PNGEncodeBasic"]),
        .executable(name: "indexing",                   targets: ["PNGIndexing"]),
        .executable(name: "iphone-optimized",           targets: ["PNGiPhoneOptimized"]),
        .executable(name: "metadata",                   targets: ["PNGMetadata"]),
        .executable(name: "in-memory",                  targets: ["PNGInMemory"]),
    ],
    targets: 
    [
        .target(name: "PNG",                        dependencies: [],       path: "sources/png"),
        
        .target(name: "PNGUnitTests",               dependencies: ["PNG"],  path: "tests/unit"),
        .target(name: "PNGIntegrationTests",        dependencies: ["PNG"],  path: "tests/integration"),
        .target(name: "PNGCompressionTests",        dependencies: ["PNG"],  path: "tests/compression"),
        .target(name: "PNGCompressionBenchmarks",   dependencies: ["PNG"],  path: "benchmarks/compression/swift"), 
        .target(name: "PNGDecompressionBenchmarks", dependencies: ["PNG"],  path: "benchmarks/decompression/swift"), 
        
        .target(name: "PNGDecodeBasic",             dependencies: ["PNG"],  path: "examples/decode-basic"),
        .target(name: "PNGEncodeBasic",             dependencies: ["PNG"],  path: "examples/encode-basic"),
        .target(name: "PNGIndexing",                dependencies: ["PNG"],  path: "examples/indexing"),
        .target(name: "PNGiPhoneOptimized",         dependencies: ["PNG"],  path: "examples/iphone-optimized"),
        .target(name: "PNGMetadata",                dependencies: ["PNG"],  path: "examples/metadata"),
        .target(name: "PNGInMemory",                dependencies: ["PNG"],  path: "examples/in-memory"),
    ],
    swiftLanguageVersions: [.v5]
)
