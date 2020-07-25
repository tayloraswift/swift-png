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

import PNG4


func benchmark(_ name:String, function:(String) -> Int)
{
    let t:Int = function("benchmarks/apollo17.png")
    print("\(name): \(Colors.off.1)\(formatInt(t))\(Colors.off.0)")
}

// benchmark("ARGB32* (structured,  internal)", function: PNG._Benchmarks._structuredARGBPremultiplied(_:))
// benchmark("ARGB32* (structured,  public  )", function: structuredARGBPremultiplied(_:))

benchmark("RGBA8   (structured,  internal)", function: PNG._Benchmarks._structuredRGBA(_:))
// benchmark("RGBA8   (structured,  public  )", function: structuredRGBA(_:))
// benchmark("RGBA8   (planar,      internal)", function: PNG._Benchmarks._planarRGBA(_:))
// benchmark("RGBA8   (planar,      public  )", function: planarRGBA(_:))
// benchmark("RGBA8   (interleaved, internal)", function: PNG._Benchmarks._interleavedRGBA(_:))
// benchmark("RGBA8   (interleaved, public  )", function: interleavedRGBA(_:))

// benchmark("  VA8   (structured,  internal)", function: PNG._Benchmarks._structuredVA(_:))
// benchmark("  VA8   (structured,  public  )", function: structuredVA(_:))
// benchmark("  VA8   (planar,      internal)", function: PNG._Benchmarks._planarVA(_:))
// benchmark("  VA8   (planar,      public  )", function: planarVA(_:))
// benchmark("  VA8   (interleaved, internal)", function: PNG._Benchmarks._interleavedVA(_:))
// benchmark("  VA8   (interleaved, public  )", function: interleavedVA(_:))

// benchmark("   V8   (interleaved, internal)", function: PNG._Benchmarks._structuredV(_:))
// benchmark("   V8   (interleaved, public  )", function: structuredV(_:))

// benchmark("RGBA8   (encode,      internal)", function: PNG._Benchmarks._encodeRGBA(_:))
// benchmark("RGBA8   (encode,      public  )", function: encodeRGBA(_:))
