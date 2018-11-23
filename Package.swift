// swift-tools-version:4.2

import PackageDescription

var targets: [Target] = []
#if !os(macOS)
targets += [
    .systemLibrary(name: "zlib", path: "sources/zlib", pkgConfig: "zlib"),
    .target(name: "PNG", dependencies: ["zlib"], path: "sources/png"),
]
#else
targets += [
    // Without “zlib”.
    .target(name: "PNG", path: "sources/png"),
]
#endif
targets += [
        .target(name: "PNGTests", dependencies: ["PNG"], path: "tests"),
        .target(name: "PNGBenchmarks", dependencies: ["PNG"], path: "benchmarks")
]

let package = Package(
    name: "PNG",
    products:
    [
        .library(name: "PNG", targets: ["PNG"]),
        .executable(name: "tests", targets: ["PNGTests"]),
        .executable(name: "benchmarks", targets: ["PNGBenchmarks"])
    ],
    targets: targets,
    swiftLanguageVersions: [.v4_2]
)
