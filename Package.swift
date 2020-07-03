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
        .library(   name: "PNG",                targets: ["PNG"]),
        .library(   name: "png",                targets: ["PNG4"]),
        
        .executable(name: "unit-test",          targets: ["PNGUnitTests"]),
        .executable(name: "integration-test",   targets: ["PNGIntegrationTests"]),
        
        .executable(name: "benchmarks",         targets: ["PNGBenchmarks"]), 
        .executable(name: "examples",           targets: ["PNGExamples"])
    ],
    targets: core +
    [
        .target(name: "PNG4",                   dependencies: [],       path: "sources/png4"),
        
        .target(name: "PNGUnitTests",           dependencies: ["PNG4"],  path: "tests/unit"),
        .target(name: "PNGIntegrationTests",    dependencies: ["PNG4"],  path: "tests/integration"),
        .target(name: "PNGBenchmarks",          dependencies: ["PNG"],  path: "benchmarks"), 
        .target(name: "PNGExamples",            dependencies: ["PNG"],  path: "examples")
    ],
    swiftLanguageVersions: [.v4_2, .v5]
)
