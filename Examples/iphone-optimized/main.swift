import PNG 

let path:String = "examples/iphone-optimized/example"

guard var image:PNG.Data.Rectangular = try .decompress(path: "\(path).png")
else 
{
    fatalError("failed to open file '\(path).png'")
}

print(image.layout.format)

let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self).map(\.straightened)

print(image.storage[..<16])

let standard:PNG.Data.Rectangular = .init(
    packing: rgba, 
    size:    image.size, 
    layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))

try standard.compress(path: "\(path)-rgb8.png")

let apple:PNG.Data.Rectangular = .init(
    packing: standard.unpack(as: PNG.RGBA<UInt8>.self).map(\.premultiplied), 
    size:    standard.size, 
    layout: .init(format: .bgr8(palette: [], fill: nil, key: nil)))

try apple.compress(path: "\(path)-bgr8.png")
