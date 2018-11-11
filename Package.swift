// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "PNG",
    products:
    [
        .library(name: "PNG", targets: ["PNG"]),
        .executable(name: "tests", targets: ["PNGTests"]),
        .executable(name: "benchmarks", targets: ["PNGBenchmarks"])
    ],
    dependencies:
    [
    .package(url: "https://github.com/SDGGiesbrecht/SDGCornerstone", from: Version(0, 12, 0))
    ],
    targets:
    [
        .systemLibrary(name: "zlib", path: "sources/zlib", pkgConfig: "zlib"),
        .target(name: "PNG", dependencies: ["zlib"], path: "sources/png"),
        .target(name: "PNGTests", dependencies: ["PNG"], path: "tests"),
        .target(name: "PNGBenchmarks", dependencies: ["PNG"], path: "benchmarks"),
        .testTarget(name: "PNGXCTests", dependencies: ["SDGExternalProcess"], path: "XCTest/PNGTests")
    ],
    swiftLanguageVersions: [.v4_2]
)
