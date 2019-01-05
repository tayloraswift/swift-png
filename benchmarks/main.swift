#if os(macOS)
import func Darwin.clock
func clock() -> Int
{
    return .init(Darwin.clock())
}

#elseif os(Linux)
import func Glibc.clock
func clock() -> Int
{
    return Glibc.clock()
}

#else
    #error("unsupported or untested platform (please open an issue at https://github.com/kelvin13/png/issues)")
#endif

import PNG

func structuredARGBPremultiplied(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt32] = try? PNG.argbPremultiplied(path: path, of: UInt8.self).pixels
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}
func structuredRGBA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[PNG.RGBA<UInt8>] = try? PNG.rgba(path: path, of: UInt8.self).pixels
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}
func planarRGBA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt8] = try? PNG.rgba(path: path, of: UInt8.self).pixels.planar()
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}
func interleavedRGBA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt8] = try? PNG.rgba(path: path, of: UInt8.self).pixels.interleaved()
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}

func structuredVA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[PNG.VA<UInt8>] = try? PNG.va(path: path, of: UInt8.self).pixels
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}
func planarVA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt8] = try? PNG.va(path: path, of: UInt8.self).pixels.planar()
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}
func interleavedVA(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt8] = try? PNG.va(path: path, of: UInt8.self).pixels.interleaved()
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}

func structuredV(_ path:String) -> Int
{
    let t1:Int = clock()
    guard let _:[UInt8] = try? PNG.v(path: path, of: UInt8.self).pixels
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    let t:Int = clock() - t1
    return t
}


func convertRGBA(_ path:String) -> Int
{
    guard let (rgba, (x: x, y: y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) =
        try? PNG.rgba(path: path, of: UInt8.self)
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }

    guard let uncompressed:PNG.Data.Uncompressed =
        try? .convert(rgba: rgba, size: (x, y), to: .rgba8)
    else
    {
        fatalError("unreachable")
    }

    let t1:Int = clock()
    guard let _:Void = try? uncompressed.compress(path: path + ".png")
    else
    {
        fatalError("could not open, write, or encode PNG file '\(path).png'")
    }

    let t:Int = clock() - t1
    return t
}

func encodeRGBA(_ path:String) -> Int
{
    guard let (rgba, (x: x, y: y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) =
        try? PNG.rgba(path: path, of: UInt8.self)
    else
    {
        fatalError("could not open, read, or decode PNG file '\(path)'")
    }
    
    let t1:Int = clock()
    guard let _:Void = try? PNG.encode(rgba: rgba, size: (x, y), as: .rgba8, path: path + ".png", level: 9)
    else
    {
        fatalError("could not open, write, or encode PNG file '\(path).png'")
    }

    let t:Int = clock() - t1
    return t
}

func benchmark(_ name:String, function:(String) -> Int)
{
    let t:Int = function("benchmarks/apollo17.png")
    print("\(name): \(Colors.off.1)\(formatInt(t))\(Colors.off.0)")
}

benchmark("ARGB32* (structured,  internal)", function: PNG._Benchmarks._structuredARGBPremultiplied(_:))
benchmark("ARGB32* (structured,  public  )", function: structuredARGBPremultiplied(_:))

benchmark("RGBA8   (structured,  internal)", function: PNG._Benchmarks._structuredRGBA(_:))
benchmark("RGBA8   (structured,  public  )", function: structuredRGBA(_:))
benchmark("RGBA8   (planar,      internal)", function: PNG._Benchmarks._planarRGBA(_:))
benchmark("RGBA8   (planar,      public  )", function: planarRGBA(_:))
benchmark("RGBA8   (interleaved, internal)", function: PNG._Benchmarks._interleavedRGBA(_:))
benchmark("RGBA8   (interleaved, public  )", function: interleavedRGBA(_:))

benchmark("  VA8   (structured,  internal)", function: PNG._Benchmarks._structuredVA(_:))
benchmark("  VA8   (structured,  public  )", function: structuredVA(_:))
benchmark("  VA8   (planar,      internal)", function: PNG._Benchmarks._planarVA(_:))
benchmark("  VA8   (planar,      public  )", function: planarVA(_:))
benchmark("  VA8   (interleaved, internal)", function: PNG._Benchmarks._interleavedVA(_:))
benchmark("  VA8   (interleaved, public  )", function: interleavedVA(_:))

benchmark("   V8   (interleaved, internal)", function: PNG._Benchmarks._structuredV(_:))
benchmark("   V8   (interleaved, public  )", function: structuredV(_:))

benchmark("RGBA8   (encode,      internal)", function: PNG._Benchmarks._encodeRGBA(_:))
benchmark("RGBA8   (encode,      public  )", function: encodeRGBA(_:))
