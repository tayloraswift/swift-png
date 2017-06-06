// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MaxPNG",
    products: [.library(name: "MaxPNG", targets: ["MaxPNG"])],
    targets:  [.target(name: "Zlib"),
               .target(name: "MaxPNG", dependencies: ["Zlib"]),
               .testTarget(name: "MaxPNGTests", dependencies: ["MaxPNG"])
                ],
    swiftLanguageVersions: [4]
)
