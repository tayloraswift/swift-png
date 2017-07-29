// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MaxPNG",
    products:  [.library(name: "MaxPNG", targets: ["MaxPNG"])],
    targets:   [.target(name: "Zlib", path: "sources/zlib"),
                .target(name: "MaxPNG", dependencies: ["Zlib"], path: "sources/maxpng"),
                .testTarget(name: "MaxPNGTests", dependencies: ["MaxPNG"], path: "tests/maxpng")
               ],
    swiftLanguageVersions: [4]
)
