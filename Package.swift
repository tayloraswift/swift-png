// swift-tools-version:5.2
import PackageDescription

let core:[Target]
#if os(Linux)
core =
[
    .systemLibrary(name: "zlib", path: "sources/zlib", pkgConfig: "zlib"),
    .target(name: "PNG", dependencies: ["zlib"], path: "sources/png")
]

#elseif os(macOS)
core =
[
    .target(name: "PNG", path: "sources/png")
]

#else
    #error("unsupported or untested platform (please open an issue at https://github.com/kelvin13/png/issues)")
#endif

let package = Package(
    name: "PNG",
    products:
    [
        .library(   name: "png",                        targets: ["PNG4"]),
        .executable(name: "unit-test",                  targets: ["PNGUnitTests"]),
        .executable(name: "integration-test",           targets: ["PNGIntegrationTests"]),
        .executable(name: "compression-test",           targets: ["PNGCompressionTests"]),
        .executable(name: "compression-benchmark",      targets: ["PNGCompressionBenchmarks"]), 
        .executable(name: "decompression-benchmark",    targets: ["PNGDecompressionBenchmarks"]), 
        
        .library(   name: "PNG",                        targets: ["PNG"]),
        .executable(name: "benchmarks3",                targets: ["PNGBenchmarks3"]), 
        .executable(name: "examples",                   targets: ["PNGExamples"])
    ],
    targets: core +
    [
        .target(name: "PNG4",                       dependencies: [],       path: "sources/png4"),
        
        .target(name: "PNGUnitTests",               dependencies: ["PNG4"], path: "tests/unit"),
        .target(name: "PNGIntegrationTests",        dependencies: ["PNG4"], path: "tests/integration", 
            exclude: 
            [
                "PngSuite.LICENSE",
                "PngSuite.README",
                "rgba/",
                "png/",
                "out/",
            ]),
        .target(name: "PNGCompressionTests",        dependencies: ["PNG4"], path: "tests/compression", 
            exclude: 
            [
                "baseline/",
                "out/",
            ]),
        .target(name: "PNGCompressionBenchmarks",   dependencies: ["PNG4"], path: "benchmarks/encode/swift"), 
        .target(name: "PNGDecompressionBenchmarks", dependencies: ["PNG4"], path: "benchmarks/decode/swift", 
            exclude: 
            [
                "apollo17.png"
            ]), 
        
        .target(name: "PNGBenchmarks3",             dependencies: ["PNG"],  path: "benchmarks3"), 
        .target(name: "PNGExamples",                dependencies: ["PNG"],  path: "examples", 
            exclude: 
            [
                "LICENSE",
                "example-indexing-output.png",
                "example-border-output.png",
                "example-sepia-input.png",
                "example-luminance-input.png",
                "example-sepia-output.png",
                "example-indexing-input.png",
                "example-crop-output.png",
                "example-crop-input.png",
                "example-border-input.png",
                "example-luminance-output.png",
            ])
    ],
    swiftLanguageVersions: [.v5]
)
