import PNG 

let path:String = "examples/decode-basic/ada-lovelace-1840.png"

guard let image:PNG.Data.Rectangular = try .decompress(path: path)
else 
{
    fatalError("failed to open file '\(path)'")
}

let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
guard let _:Void = (System.File.Destination.open(path: "\(path).rgba")
{
    guard let _:Void = $0.write(rgba.flatMap{ [$0.r, $0.g, $0.b, $0.a] })
    else 
    {
        fatalError("failed to write to file '\(path).rgba'")
    }
}) 
else
{
    fatalError("failed to open file '\(path).rgba'")
}

let va:[PNG.VA<UInt8>] = image.unpack(as: PNG.VA<UInt8>.self)
guard let _:Void = (System.File.Destination.open(path: "\(path).va")
{
    guard let _:Void = $0.write(va.flatMap{ [$0.v, $0.a] })
    else 
    {
        fatalError("failed to write to file '\(path).va'")
    }
}) 
else
{
    fatalError("failed to open file '\(path).va'")
}

let v:[UInt8] = image.unpack(as: UInt8.self)
guard let _:Void = (System.File.Destination.open(path: "\(path).v")
{
    guard let _:Void = $0.write(v)
    else 
    {
        fatalError("failed to write to file '\(path).v'")
    }
}) 
else
{
    fatalError("failed to open file '\(path).v'")
}
