// On platforms with built-in file system support (MacOS and Linux), decoding a PNG file to a
// pixel array takes just two function calls.

// snippet.RGBA
import PNG

let path:String = "Sources/PNG/docs.docc/BasicDecoding/BasicDecoding"

guard
let image:PNG.Image = try .decompress(path: "\(path).png")
else
{
    fatalError("failed to open file '\(path).png'")
}

let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)

// snippet.end

guard
let _:Void = (System.File.Destination.open(path: "\(path).png.rgba")
{
    guard
    let _:Void = $0.write(rgba.flatMap{ [$0.r, $0.g, $0.b, $0.a] })
    else
    {
        fatalError("failed to write to file '\(path).png.rgba'")
    }
})
else
{
    fatalError("failed to open file '\(path).png.rgba'")
}

// snippet.VA

let va:[PNG.VA<UInt8>] = image.unpack(as: PNG.VA<UInt8>.self)

// snippet.end

let vaReencoded:PNG.Image = .init(packing: va,
    size: image.size,
    layout: .init(format: .va8(fill: nil)),
    metadata: image.metadata)
try vaReencoded.compress(path: "\(path).va.png", level: 9)

//  snippet.V

let v:[UInt8] = image.unpack(as: UInt8.self)

// snippet.end

let vReencoded:PNG.Image = .init(packing: v,
    size: image.size,
    layout: .init(format: .v8(fill: nil, key: nil)),
    metadata: image.metadata)
try vReencoded.compress(path: "\(path).v.png", level: 9)
