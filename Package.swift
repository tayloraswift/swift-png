// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "PNG",
    products:  [.library(name: "PNG", targets: ["PNG"]), 
                .executable(name: "tests", targets: ["PNGTests"])],
    targets:   [.systemLibrary(name: "zlib", path: "sources/zlib", pkgConfig: "zlib"),
                .target(name: "PNG", dependencies: ["zlib"], path: "sources/png"),
                .target(name: "PNGTests", dependencies: ["PNG"], path: "tests")
               ],
    swiftLanguageVersions: [.v4_2]
)
