import PNG

let path:String         = "examples/encode-basic/another-explosion-at-hand", 
    size:(x:Int, y:Int) = (800, 1228)
guard let rgba:[PNG.RGBA<UInt8>] = (System.File.Source.open(path: "\(path).rgba")
{
    guard let data:[UInt8] = $0.read(count: 4 * size.x * size.y)
    else 
    {
        fatalError("failed to read from file '\(path).rgba'")
    }

    return (0 ..< size.x * size.y).map 
    {
        (i:Int) -> PNG.RGBA<UInt8> in
        .init(data[4 * i], data[4 * i + 1], data[4 * i + 2], data[4 * i + 3])
    }
}) 
else
{
    fatalError("failed to open file '\(path).rgba'")
}

let layout:PNG.Layout           = .init(format: .rgb8(palette: [], fill: nil, key: nil))
let image:PNG.Data.Rectangular  = .init(size: size, layout: layout, packing: rgba)

for level:Int in 0 ... 13 
{
    try image.compress(path: "\(path)@\(level).png", level: level)
}
