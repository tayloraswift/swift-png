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

extension PNG 
{
    // internal benchmarking functions, to measure module boundary overhead
    public
    enum _Benchmarks
    {
        public static
        func _structuredARGBPremultiplied(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt32] = try? argbPremultiplied(path: path, of: UInt8.self).pixels
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _structuredRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[RGBA<UInt8>] = try? rgba(path: path, of: UInt8.self).pixels
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _planarRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? rgba(path: path, of: UInt8.self).pixels.planar()
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _interleavedRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? rgba(path: path, of: UInt8.self).pixels.interleaved()
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _structuredVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[VA<UInt8>] = try? va(path: path, of: UInt8.self).pixels
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _planarVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? va(path: path, of: UInt8.self).pixels.planar()
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _interleavedVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? va(path: path, of: UInt8.self).pixels.interleaved()
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }
        public static
        func _structuredV(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? v(path: path, of: UInt8.self).pixels
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }

            let t:Int = clock() - t1
            return t
        }

        public static
        func _convertRGBA(_ path:String) -> Int
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
        
        public static
        func _encodeRGBA(_ path:String) -> Int
        {
            guard let (rgba, (x: x, y: y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) =
                try? PNG.rgba(path: path, of: UInt8.self)
            else
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t1:Int = clock()
            guard let _:Void = try? encode(rgba: rgba, size: (x, y), as: .rgba8, path: path + ".png", level: 9)
            else
            {
                fatalError("could not open, write, or encode PNG file '\(path).png'")
            }

            let t:Int = clock() - t1
            return t
        }
    }
}
