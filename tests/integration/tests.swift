import PNG

extension Test 
{
    static 
    var cases:[(name:String, function:Function)] 
    {
        let suite:[(name:String, members:[String])] =
        [
            (
                "basic",
                [
                    "PngSuite",

                    "basn0g01",
                    "basn0g02",
                    "basn0g04",
                    "basn0g08",
                    "basn0g16",
                    "basn2c08",
                    "basn2c16",
                    "basn3p01",
                    "basn3p02",
                    "basn3p04",
                    "basn3p08",
                    "basn4a08",
                    "basn4a16",
                    "basn6a08",
                    "basn6a16"
                ]
            ),
            (
                "interlaced",
                [
                    "basi0g01",
                    "basi0g02",
                    "basi0g04",
                    "basi0g08",
                    "basi0g16",
                    "basi2c08",
                    "basi2c16",
                    "basi3p01",
                    "basi3p02",
                    "basi3p04",
                    "basi3p08",
                    "basi4a08",
                    "basi4a16",
                    "basi6a08",
                    "basi6a16"
                ]
            ),
            (
                "odd-sizes",
                [
                    "s01i3p01",
                    "s01n3p01",
                    "s02i3p01",
                    "s02n3p01",
                    "s03i3p01",
                    "s03n3p01",
                    "s04i3p01",
                    "s04n3p01",
                    "s05i3p02",
                    "s05n3p02",
                    "s06i3p02",
                    "s06n3p02",
                    "s07i3p02",
                    "s07n3p02",
                    "s08i3p02",
                    "s08n3p02",
                    "s09i3p02",
                    "s09n3p02",
                    "s32i3p04",
                    "s32n3p04",
                    "s33i3p04",
                    "s33n3p04",
                    "s34i3p04",
                    "s34n3p04",
                    "s35i3p04",
                    "s35n3p04",
                    "s36i3p04",
                    "s36n3p04",
                    "s37i3p04",
                    "s37n3p04",
                    "s38i3p04",
                    "s38n3p04",
                    "s39i3p04",
                    "s39n3p04",
                    "s40i3p04",
                    "s40n3p04"
                ]
            ),
            (
                "backgrounds",
                [
                    "bgai4a08",
                    "bgai4a16",
                    "bgan6a08",
                    "bgan6a16",
                    "bgbn4a08",
                    "bggn4a16",
                    "bgwn6a08",
                    "bgyn6a16"
                ]
            ),
            (
                "transparency",
                [
                    "tbbn0g04",
                    "tbbn2c16",
                    "tbbn3p08",
                    "tbgn2c16",
                    "tbgn3p08",
                    "tbrn2c08",
                    "tbwn0g16",
                    "tbwn3p08",
                    "tbyn3p08",
                    "tm3n3p02",
                    "tp0n0g08",
                    "tp0n2c08",
                    "tp0n3p08",
                    "tp1n3p08"
                ]
            ),
            // (
            //     "gamma (inactive)",
            //     [
            //         "g03n0g16",
            //         "g03n2c08",
            //         "g03n3p04",
            //         "g04n0g16",
            //         "g04n2c08",
            //         "g04n3p04",
            //         "g05n0g16",
            //         "g05n2c08",
            //         "g05n3p04",
            //         "g07n0g16",
            //         "g07n2c08",
            //         "g07n3p04",
            //         "g10n0g16",
            //         "g10n2c08",
            //         "g10n3p04",
            //         "g25n0g16",
            //         "g25n2c08",
            //         "g25n3p04"
            //     ]
            // ),
            (
                "filters",
                [
                    "f00n0g08",
                    "f00n2c08",
                    "f01n0g08",
                    "f01n2c08",
                    "f02n0g08",
                    "f02n2c08",
                    "f03n0g08",
                    "f03n2c08",
                    "f04n0g08",
                    "f04n2c08",
                    "f99n0g04"
                ]
            ),
            (
                "palettes",
                [
                    "pp0n2c16",
                    "pp0n6a08",
                    "ps1n0g08",
                    "ps1n2c16",
                    "ps2n0g08",
                    "ps2n2c16"
                ]
            ),
            (
                "ancillary-chunks",
                [
                    "ccwn2c08",
                    "ccwn3p08",
                    "cdfn2c08",
                    "cdhn2c08",
                    "cdsn2c08",
                    "cdun2c08",
                    "ch1n3p04",
                    "ch2n3p08",
                    "cm0n0g04",
                    "cm7n0g04",
                    "cm9n0g04",
                    "cs3n2c16",
                    "cs3n3p08",
                    "cs5n2c08",
                    "cs5n3p08",
                    "cs8n2c08",
                    "cs8n3p08",
                    "ct0n0g04",
                    "ct1n0g04",
                    "cten0g04",
                    "ctfn0g04",
                    "ctgn0g04",
                    "cthn0g04",
                    "ctjn0g04",
                    "ctzn0g04"
                ]
            ),
            (
                "chunk-ordering",
                [
                    "oi1n0g16",
                    "oi1n2c16",
                    "oi2n0g16",
                    "oi2n2c16",
                    "oi4n0g16",
                    "oi4n2c16",
                    "oi9n0g16",
                    "oi9n2c16"
                ]
            ),
            (
                "lz77-compression",
                [
                    "z00n2c08",
                    "z03n2c08",
                    "z06n2c08",
                    "z09n2c08"
                ]
            ),
            (
                "large-images",
                [
                    "becky palette",
                    "if red got the grammy",
                    "taylor",
                    "wildest dreams adam7"
                ]
            ),
        ]
        
        return  suite.map 
        {
            ("decode-\($0.name)", .string(Self.decode(_:), $0.members))
        }
        +       suite.map 
        {
            ("encode-\($0.name)", .string(Self.encode(_:), $0.members))
        }
    }
    
    static 
    func decode(_ name:String) -> Result<Void, Failure>
    {
        let path:(png:String, rgba:String) = 
        (
            "tests/integration/png/\(name).png",
            "tests/integration/rgba/\(name).png.rgba"
        )
        return Self.decode(path: path)
    }
    
    static 
    func decode(path:(png:String, rgba:String)) -> Result<Void, Failure>
    {
        do
        {
            guard let rectangular:PNG.Data.Rectangular = try .decompress(path: path.png)
            else
            {
                return .failure(.init(message: "failed to open file '\(path.png)'"))
            }

            let image:[PNG.RGBA<UInt16>] = rectangular.rgba(of: UInt16.self)

            guard let result:[PNG.RGBA<UInt16>]? = (PNG.File.Source.open(path: path.rgba)
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
                return .failure(.init(message: "failed to open file '\(path.rgba)'"))
            }

            guard let reference:[PNG.RGBA<UInt16>] = result
            else
            {
                return .failure(.init(message: "failed to read file '\(path.rgba)'"))
            }

            for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in
                zip(image, reference).enumerated()
            {
                guard pair.0 == pair.1
                else
                {
                    return .failure(.init(message: "pixel \(i) has value \(pair.0) (expected \(pair.1))"))
                }
            }

            return .success(())
        }
        catch
        {
            return .failure(.init(message: "\(error)"))
        }
    }
    
    static 
    func encode(_ name:String) -> Result<Void, Failure>
    {
        let path:(png:String, rgba:String, out:String) = 
        (
            "tests/integration/png/\(name).png",
            "tests/integration/rgba/\(name).png.rgba",
            "tests/integration/out/\(name).png"
        )

        do
        {
            guard let rectangular:PNG.Data.Rectangular = try .decompress(path: path.png)
            else
            {
                return .failure(.init(message: "failed to open file '\(path.png)'"))
            }

            // compress image into png
            try PNG.encode( rgba: rectangular.rgba(of: UInt16.self),
                            size: rectangular.properties.size,
                              as: rectangular.properties.format.code,
                       chromaKey: rectangular.properties.chromaKey,
                            path: path.out)
        }
        catch
        {
            return .failure(.init(message: "\(error)"))
        }

        return Self.decode(path: (path.png, path.rgba))
    }
}

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
