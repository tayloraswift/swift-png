// swift-tools-version:5.5
import PackageDescription

let package:Package = .init(name: "swift-png",
    products:
    [
        .library(   name: "PNG",                        targets: ["PNG"]),
        
        .executable(name: "PNGTests",                   targets: ["PNGTests"]),
        .executable(name: "PNGIntegrationTests",        targets: ["PNGIntegrationTests"]),
        .executable(name: "PNGCompressionTests",        targets: ["PNGCompressionTests"]),
        
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
    dependencies:
    [
        .package(url: "https://github.com/kelvin13/swift-hash", .upToNextMinor(from: "0.4.3")),
    ],
    targets: 
    [
        .target(name: "TerminalColors"),

        .target(name: "PNG",
            dependencies:
            [
                .target(name: "TerminalColors"),
            ]),
        

        .executableTarget(name: "PNGTests",
            dependencies:
            [
                .target(name: "PNG"),
                .product(name: "Testing", package: "swift-hash"),
            ],
            path: "Tests/PNG"),
        
        .executableTarget(name: "PNGIntegrationTests",
            dependencies:
            [
                .target(name: "PNG"),
                .product(name: "Testing", package: "swift-hash"),
            ],
            path: "Tests/PNGIntegration", 
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
                .product(name: "Testing", package: "swift-hash"),
            ],
            path: "Tests/PNGCompression", 
            exclude: 
            [
                "Baselines/", 
                "Outputs/",
            ]),
        
        .executableTarget(name: "PNGCompressionBenchmarks",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/compression/swift"), 
        
        .executableTarget(name: "PNGDecompressionBenchmarks",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Benchmarks/decompression/swift"), 
        
        .executableTarget(name: "PNGDecodeBasic",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/decode-basic", 
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
        .executableTarget(name: "PNGEncodeBasic",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/encode-basic", 
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
        .executableTarget(name: "PNGIndexing",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/indexing", 
            exclude: 
            [
                "example.png", 
                "example-indexed.png", 
                "gradient-visualization.png", 
            ]),
        .executableTarget(name: "PNGiPhoneOptimized",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/iphone-optimized", 
            exclude: 
            [
                "example-bgr8.png", 
                "example-rgb8.png", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGMetadata",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/metadata", 
            exclude: 
            [
                "example-newtime.png", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGInMemory",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/in-memory", 
            exclude: 
            [
                "example.png.rgba.png", 
                "example.png.png", 
                "example.png.rgba", 
                "example.png", 
            ]),
        .executableTarget(name: "PNGDecodeOnline",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/decode-online", 
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
        .executableTarget(name: "PNGCustomColor",
            dependencies:
            [
                .target(name: "PNG"),
            ],
            path: "Examples/custom-color", 
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
