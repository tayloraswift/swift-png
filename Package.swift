// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-png",
    products:
    [
        .library(   name: "PNG",                        targets: ["PNG"]),
        
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
        .executable(name: "decode-online",              targets: ["PNGDecodeOnline"]),
        .executable(name: "custom-color",               targets: ["PNGCustomColor"]),
    ],
    targets: 
    [
        .target(name: "PNG",                                  dependencies: ["_PNGString"],        path: "sources/png"),

        .target(name: "_PNGString",                           dependencies: [],                    path: "sources/string"),

        .target(name: "_PNGTestsCommon",                      dependencies: ["PNG"],               path: "tests/common"),

        .testTarget(name: "PNGUnitTests",                     dependencies: ["PNG", "_PNGString"], path: "tests/unit"),

        .executableTarget(name: "PNGIntegrationTests",        dependencies: ["PNG", "_PNGString", "_PNGTestsCommon"], path: "tests/integration",
            exclude: 
            [
                "PngSuite.LICENSE",
                "PngSuite.README",
                "in/", 
                "out/",
                "rgba/",
            ]),
        .executableTarget(name: "PNGCompressionTests",        dependencies: ["PNG", "_PNGString", "_PNGTestsCommon"], path: "tests/compression",
            exclude: 
            [
                "baseline/", 
                "out/",
            ]),
        .executableTarget(name: "PNGCompressionBenchmarks",   dependencies: ["PNG"],  path: "benchmarks/compression/swift"), 
        .executableTarget(name: "PNGDecompressionBenchmarks", dependencies: ["PNG"],  path: "benchmarks/decompression/swift"), 
        
        .executableTarget(name: "PNGDecodeBasic",             dependencies: ["PNG"],  path: "examples/decode-basic", 
            exclude: 
            [
                "example.png.rgba", 
                "example.png.v.png", 
                "example.png.rgba.png", 
                "example.png", 
                "example.png.v", 
                "example.png.va.png", 
                "example.png.va", 
            ]),
        .executableTarget(name: "PNGEncodeBasic",             dependencies: ["PNG"],  path: "examples/encode-basic", 
            exclude: 
            [
                "example-color-rgb@0.png",
                "example-color-rgb@4.png",
                "example-color-v.png",
                "example-color-rgb@8.png",
                "example-color-rgb.png",
                "example-luminance-rgb.png",
                "example.rgba",
                "example-color-rgb@13.png",
                "example-luminance-v.png",
            ]),
        .executableTarget(name: "PNGIndexing",                dependencies: ["PNG"],  path: "examples/indexing", 
            exclude: 
            [
                "example.png", 
                "example-indexed.png", 
                "gradient-visualization.png", 
            ]),
        .executableTarget(name: "PNGiPhoneOptimized",         dependencies: ["PNG"],  path: "examples/iphone-optimized", 
            exclude: 
            [
                "example-bgr8.png", 
                "example-rgb8.png", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGMetadata",                dependencies: ["PNG"],  path: "examples/metadata", 
            exclude: 
            [
                "example-newtime.png", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGInMemory",                dependencies: ["PNG"],  path: "examples/in-memory", 
            exclude: 
            [
                "example.png.rgba.png", 
                "example.png.png", 
                "example.png.rgba", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGDecodeOnline",            dependencies: ["PNG"],  path: "examples/decode-online", 
            exclude: 
            [
                "example-progressive-9.png", 
                "example-8.png", 
                "example-progressive-6.png", 
                "example-progressive-11.png", 
                "example-progressive.png", 
                "example-progressive-0.png", 
                "example-progressive-overdrawn-5.png", 
                "example-progressive-3.png", 
                "example-progressive-2.png", 
                "example-progressive-10.png", 
                "example-6.png", 
                "example-5.png", 
                "example-1.png", 
                "example-10.png", 
                "example-progressive-overdrawn-2.png", 
                "example-progressive-overdrawn-4.png", 
                "example-progressive-8.png", 
                "example-progressive-1.png", 
                "example-progressive-overdrawn-10.png", 
                "example-progressive-7.png", 
                "example-0.png", 
                "example-progressive-overdrawn-0.png", 
                "example-7.png", 
                "example-4.png", 
                "example-progressive-overdrawn-3.png", 
                "example-progressive-overdrawn-9.png", 
                "example-9.png", 
                "example-progressive-5.png", 
                "example-progressive-overdrawn-11.png", 
                "example-progressive-4.png", 
                "example-3.png", 
                "example-progressive-overdrawn-8.png", 
                "example.png", 
                "example-2.png", 
                "example-progressive-overdrawn-1.png", 
                "example-progressive-overdrawn-6.png", 
                "example-progressive-overdrawn-7.png", 

            ]),
        .executableTarget(name: "PNGCustomColor",             dependencies: ["PNG"],  path: "examples/custom-color", 
            exclude: 
            [
                "example.png", 
                "example-hue.png", 
                "example.png.png", 
                "example-value.png", 
                "example-saturation.png", 
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
