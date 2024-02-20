// On platforms with built-in file system support (MacOS and Linux), decoding a PNG file to a
// pixel array takes just two function calls.

// snippet.RGBA
import PNG

let path:String = "Sources/PNG/docs.docc/BasicDecoding/BasicDecoding"

guard
let image:PNG.Data.Rectangular = try .decompress(path: "\(path).png")
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

guard
let _:Void = (System.File.Destination.open(path: "\(path).png.va")
{
    guard
    let _:Void = $0.write(va.flatMap{ [$0.v, $0.a] })
    else
    {
        fatalError("failed to write to file '\(path).png.va'")
    }
})
else
{
    fatalError("failed to open file '\(path).png.va'")
}

let v:[UInt8] = image.unpack(as: UInt8.self)
guard
let _:Void = (System.File.Destination.open(path: "\(path).png.v")
{
    guard
    let _:Void = $0.write(v)
    else
    {
        fatalError("failed to write to file '\(path).png.v'")
    }
})
else
{
    fatalError("failed to open file '\(path).png.v'")
}
