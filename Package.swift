// swift-tools-version:5.0
import PackageDescription

let coreTargets:[Target]
#if os(Linux)
coreTargets =
[
    .systemLibrary(name: "zlib", path: "sources/zlib", pkgConfig: "zlib"),
    .target(name: "PNG", dependencies: ["zlib"], path: "sources/png")
]

#elseif os(macOS)
coreTargets =
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
        .library(name: "PNG", targets: ["PNG"]),
        .executable(name: "tests", targets: ["PNGTests"]),
        .executable(name: "benchmarks", targets: ["PNGBenchmarks"]), 
        .executable(name: "examples", targets: ["PNGExamples"])
    ],
    targets: coreTargets +
    [
        .target(name: "PNGTests",       dependencies: ["PNG"], path: "tests"),
        .target(name: "PNGBenchmarks",  dependencies: ["PNG"], path: "benchmarks"), 
        .target(name: "PNGExamples",    dependencies: ["PNG"], path: "examples")
    ],
    swiftLanguageVersions: [.v4_2, .v5]
)
