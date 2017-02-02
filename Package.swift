import PackageDescription

let package = Package(
    name: "MaxPNG",

    dependencies: [.Package(url: "https://github.com/kelvin13/swift-zlib", majorVersion: 1)]
)
