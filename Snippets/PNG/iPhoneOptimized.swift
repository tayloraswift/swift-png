//

//  snippet.LOAD_EXAMPLE
import PNG

let path:String = "Sources/PNG/docs.docc/iPhoneOptimized/iPhoneOptimized"

guard
var image:PNG.Image = try .decompress(path: "\(path).png")
else
{
    fatalError("failed to open file '\(path).png'")
}

//  snippet.INSPECT_FORMAT
print(image.layout.format)

//  snippet.STRAIGHTEN
let rgba:[PNG.RGBA<UInt8>] = image.unpack(
    as: PNG.RGBA<UInt8>.self).map(\.straightened)

//  snippet.INSPECT_STORAGE
print(image.storage[..<16])

//  snippet.REENCODE_RGB
let standard:PNG.Image = .init(
    packing: rgba,
    size:    image.size,
    layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))

try standard.compress(path: "\(path)-rgb8.png")

//  snippet.REENCODE_BGR
let apple:PNG.Image = .init(
    packing: standard.unpack(as: PNG.RGBA<UInt8>.self).map(\.premultiplied),
    size:    standard.size,
    layout: .init(format: .bgr8(palette: [], fill: nil, key: nil)))

try apple.compress(path: "\(path)-bgr8.png")
