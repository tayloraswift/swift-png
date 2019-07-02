import PNG

fileprivate
extension Array where Element == UInt8
{
    func load<T, U>(littleEndian:T.Type, as type:U.Type, at byte:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(littleEndian: T.self, as: U.self)
    }
}
fileprivate
extension ArraySlice where Element == UInt8
{
    func load<T, U>(littleEndian:T.Type, as type:U.Type) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer
        {
            (buffer:UnsafeBufferPointer<UInt8>) in

            assert(buffer.count >= MemoryLayout<T>.size,
                "attempt to load \(T.self) from slice of size \(buffer.count)")

            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage)
            {
                $0.deinitialize(count: 1)

                let source:UnsafeRawPointer     = .init(buffer.baseAddress!),
                    raw:UnsafeMutableRawPointer = .init($0)

                raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)

                return raw.load(as: T.self)
            }

            return U(T(littleEndian: value))
        }
    }
}

func testEncode(_ name:String) -> String?
{
    let pngPath:String  = "tests/unit/png/\(name).png",
        rgbaPath:String = "tests/unit/rgba/\(name).png.rgba",
        outPath:String  = "tests/unit/out/\(name).png"

    do
    {
        guard let rectangular:PNG.Data.Rectangular = try .decompress(path: pngPath)
        else
        {
            return "failed to open file '\(pngPath)'"
        }

        // compress image into png
        try PNG.encode( rgba: rectangular.rgba(of: UInt16.self),
                        size: rectangular.properties.size,
                          as: rectangular.properties.format.code,
                   chromaKey: rectangular.properties.chromaKey,
                        path: outPath)
    }
    catch
    {
        return "\(error)"
    }

    return testDecode(png: outPath, rgba: rgbaPath)
}

func testDecode(_ name:String) -> String?
{
    let pngPath:String  = "tests/unit/png/\(name).png",
        rgbaPath:String = "tests/unit/rgba/\(name).png.rgba"
    return testDecode(png: pngPath, rgba: rgbaPath)
}

func testDecode(png pngPath:String, rgba rgbaPath:String) -> String?
{
    do
    {
        guard let rectangular:PNG.Data.Rectangular = try .decompress(path: pngPath)
        else
        {
            return "failed to open file '\(pngPath)'"
        }

        let image:[PNG.RGBA<UInt16>] = rectangular.rgba(of: UInt16.self)

        guard let result:[PNG.RGBA<UInt16>]? =
        (PNG.File.Source.open(path: rgbaPath)
        {
            let pixels:Int = rectangular.properties.size.x * rectangular.properties.size.y,
                bytes:Int  = pixels * MemoryLayout<PNG.RGBA<UInt16>>.stride

            guard let data:[UInt8] = $0.read(count: bytes)
            else
            {
                return nil
            }

            return (0 ..< pixels).map
            {
                let r:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3),
                    g:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 2),
                    b:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 4),
                    a:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 6)

                return .init(r, g, b, a)
            }
        })
        else
        {
            return "failed to open file '\(rgbaPath)'"
        }

        guard let reference:[PNG.RGBA<UInt16>] = result
        else
        {
            return "failed to read file '\(rgbaPath)'"
        }

        for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in
            zip(image, reference).enumerated()
        {
            guard pair.0 == pair.1
            else
            {
                return "pixel \(i) has value \(pair.0) (expected \(pair.1))"
            }
        }

        return nil
    }
    catch
    {
        return "\(error)"
    }
}

func testPremultiplication<Sample>(for _:Sample.Type) -> String?
    where Sample:FixedWidthInteger & UnsignedInteger
{
    for alpha:Sample in Sample.min ... Sample.max
    {
        for color:Sample in Sample.min ... Sample.max
        {
            let direct:PNG.RGBA<Sample>        = .init(color, alpha),
                premultiplied:PNG.RGBA<Sample> = direct.premultiplied

            let unquantized:Double = (Double(alpha) * Double(color) / Double(Sample.max)),
                quantized:Sample   = .init(unquantized)

            // the order is important here,, the short circuiting protects us from
            // overflow when `quantized` == 255
            guard premultiplied.r == quantized || premultiplied.r == quantized + 1
            else
            {
                return "premultiplication of rgba\(Sample.bitWidth)(\(direct.r), \(direct.g), \(direct.b), \(direct.a)) returned (\(premultiplied.r), \(premultiplied.g), \(premultiplied.b), \(premultiplied.a)), expected (\(unquantized), \(unquantized), \(unquantized), \(alpha))"
            }
        }
    }

    return nil
}
