// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MaxPNG",
    products:  [.library(name: "MaxPNG", targets: ["MaxPNG"]),
                .executable(name: "tests", targets: ["MaxPNGTests"])],
    targets:   [.target(name: "Zlib", path: "sources/zlib"),
                .target(name: "MaxPNG", dependencies: ["Zlib"], path: "sources/maxpng"),
                .target(name: "MaxPNGTests", dependencies: ["MaxPNG"], path: "tests/maxpng")
               ],
    swiftLanguageVersions: [4]
)
