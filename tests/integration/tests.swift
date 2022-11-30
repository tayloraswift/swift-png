import PNG
import _PNGTestsCommon

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
            (
                "gamma",
                [
                    "g03n0g16",
                    "g03n2c08",
                    "g03n3p04",
                    "g04n0g16",
                    "g04n2c08",
                    "g04n3p04",
                    "g05n0g16",
                    "g05n2c08",
                    "g05n3p04",
                    "g07n0g16",
                    "g07n2c08",
                    "g07n3p04",
                    "g10n0g16",
                    "g10n2c08",
                    "g10n3p04",
                    "g25n0g16",
                    "g25n2c08",
                    "g25n3p04"
                ]
            ),
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
        ]
        
        let ios:[String] = 
        [
            "PngSuite", 
            "basi2c08", 
            "basi6a08", 
            "basn2c08", 
            "basn6a08", 
            "bgan6a08", 
            "bgwn6a08", 
            "ccwn2c08", 
            "cdfn2c08", 
            "cdhn2c08", 
            "cdsn2c08", 
            "cdun2c08", 
            "cs5n2c08", 
            "cs8n2c08", 
            "f00n2c08", 
            "f01n2c08", 
            "f02n2c08", 
            "f03n2c08", 
            "f04n2c08", 
            "g03n2c08", 
            "g04n2c08", 
            "g05n2c08", 
            "g07n2c08", 
            "g10n2c08", 
            "g25n2c08", 
            "pp0n6a08", 
            "tbrn2c08", 
            "tp0n2c08", 
            "z00n2c08", 
            "z03n2c08", 
            "z06n2c08", 
            "z09n2c08", 
        ]
        
        return  suite.map 
        {
            (
                "decode-\($0.name)", 
                .string({ Self.decode($0, subdirectory: "common") }, $0.members)
            )
        }
        + 
        [
            (
                "decode-iphone-optimized", 
                .string({ Self.decode($0, subdirectory: "ios") }, ios)
            ),
            (   
                "error-handling", .void(Self.errorHandling)
            ),
            (
                "encode-iphone-optimized", 
                .string({ Self.encode($0, subdirectory: "ios", level: 13) }, ios)
            )
        ]
        +       suite.map 
        {
            (
                "encode-4-\($0.name)", 
                .string({ Self.encode($0, subdirectory: "common", level:  4) }, $0.members)
            )
        }
        +       suite.map 
        {
            (
                "encode-7-\($0.name)",   
                .string({ Self.encode($0, subdirectory: "common", level:  7) }, $0.members)
            )
        }
        +       suite.map 
        {
            (
                "encode-10-\($0.name)",   
                .string({ Self.encode($0, subdirectory: "common", level: 10) }, $0.members)
            )
        } 

    }
    
    static 
    func decode(_ name:String, subdirectory:String) -> Result<Void, Failure>
    {
        let path:(in:String, rgba:String) = 
        (
            "tests/integration/in/\(subdirectory)/\(name).png",
            "tests/integration/rgba/\(name).png.rgba"
        )
        return Self.decode(path: path, premultiplied: subdirectory == "ios")
    }
    
    static 
    func decode(path:(in:String, rgba:String), premultiplied:Bool) 
        -> Result<Void, Failure>
    {
        do
        {
            guard let rectangular:PNG.Data.Rectangular = try .decompress(path: path.in)
            else
            {
                return .failure(.init(message: "failed to open file '\(path.in)'"))
            }

            let image:[PNG.RGBA<UInt16>] = rectangular.unpack(as: PNG.RGBA<UInt16>.self)
            
            if !Global.options.contains(.compact) 
            {
                print(Self.terminal(image: image, size: rectangular.size))
                print(rectangular.metadata)
                print()
            }

            guard let result:[PNG.RGBA<UInt16>]? = (System.File.Source.open(path: path.rgba)
            {
                let pixels:Int = rectangular.size.x * rectangular.size.y,
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
                    
                    let pixel:PNG.RGBA<UInt16> = .init(r, g, b, a)
                    // have to manually premultiply since the CgBI formula does the 
                    // multiplication in 8-bit precision 
                    if premultiplied 
                    {
                        return pixel.premultiplied(as: UInt8.self)
                    }
                    else 
                    {
                        return pixel 
                    }
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
        catch let error
        {
            return .failure(.init(message: "\(error)"))
        }
    }
    
    static 
    func printError<E>(_ error:E) where E:PNG.Error
    {
        guard Global.options.contains(.printExpectedFailures)
        else 
        {
            return
        } 
        
        var width:Int 
        {
            80
        }
        
        let accent:(Double, Double, Double) = (1.0, 0.6, 0.3)
        
        let heading:String = .pad(.init("\(E.namespace): \(error.message)"), right: width)
        print(String.highlight("\(String.bold)\(heading)\(String.reset)", bg: accent))
        if let details:String = error.details 
        {
            // wrap text 
            let characters:[Character] = .init(details)
            for start:Int in stride(from: 0, to: characters.count, by: width - 4) 
            {
                let end:Int = min(start + width - 4, characters.count)
                print("    \(String.color(.init(characters[start ..< end]), fg: accent))")
            }
        }
        print()
    }
    
    static 
    func errorHandling() -> Result<Void, Failure>
    {
        func decode(_ name:String) throws -> Result<Void, Failure>?
        {
            let path:String = "tests/integration/in/invalid/\(name).png"
            if let _:PNG.Data.Rectangular = try .decompress(path: path)
            {
                return .failure(.init(message: "file '\(path)' is invalid, but decoded without errors"))
            }
            else 
            {
                return .failure(.init(message: "failed to read file '\(path)'"))
            }
        }
        
        // invalid signatures 
        for name:String in 
        [
            "xs1n0g01", "xs2n0g01", "xs4n0g01", "xs7n0g01", 
            "xcrn0g04", "xlfn0g04"
        ] 
        {
            do 
            {
                if let result:Result<Void, Failure> = try decode(name)
                {
                    return result 
                }
            }
            catch PNG.LexingError.invalidSignature(let signature) 
            {
                Self.printError(PNG.LexingError.invalidSignature(signature))
            }
            catch let error 
            {
                return .failure(.init(message: "\(error)"))
            }
        }
        
        // invalid ihdr checksum 
        do 
        {
            if let result:Result<Void, Failure> = try decode("xhdn0g08")
            {
                return result 
            }
        }
        catch PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 1443964200)
        {
            Self.printError(
                PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 1443964200))
        }
        catch let error 
        {
            return .failure(.init(message: "\(error)"))
        }
        
        // invalid color format 
        for (name, code):(String, (UInt8, UInt8)) in 
        [
            ("xc1n0g08", ( 8, 1)),
            ("xc9n2c08", ( 8, 9)),
            ("xd0n2c08", ( 0, 2)),
            ("xd3n2c08", ( 3, 2)),
            ("xd9n2c08", (99, 2)),
        ] 
        {
            do 
            {
                if let result:Result<Void, Failure> = try decode(name)
                {
                    return result 
                }
            }
            catch let error 
            {
                // need to work around compiler bug preventing tuple matching
                guard case PNG.ParsingError.invalidHeaderPixelFormatCode(let expected) = error, 
                    expected == code 
                else 
                {
                    return .failure(.init(message: "\(error)"))
                }
                
                Self.printError(PNG.ParsingError.invalidHeaderPixelFormatCode(expected))
            }
        }
        
        // missing idat 
        do 
        {
            if let result:Result<Void, Failure> = try decode("xdtn0g01")
            {
                return result 
            }
        }
        catch PNG.DecodingError.required(chunk: .IDAT, before: .IEND)
        {
            Self.printError(PNG.DecodingError.required(chunk: .IDAT, before: .IEND))
        }
        catch let error 
        {
            return .failure(.init(message: "\(error)"))
        }
        
        // invalid idat checksum 
        do 
        {
            if let result:Result<Void, Failure> = try decode("xcsn0g01")
            {
                return result 
            }
        }
        catch PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 3492746441)
        {
            Self.printError(
                PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 3492746441))
        }
        catch let error 
        {
            return .failure(.init(message: "\(error)"))
        }
        
        return .success(())
    }

    static 
    func encode(_ name:String, subdirectory:String, level:Int) -> Result<Void, Failure>
    {
        let path:(in:String, rgba:String, out:String) = 
        (
            "tests/integration/in/\(subdirectory)/\(name).png",
            "tests/integration/rgba/\(name).png.rgba",
            "tests/integration/out/\(subdirectory)/\(name).png"
        )

        return Self.encode(path: path, level: level, premultiplied: subdirectory == "ios")
    } 
    
    static 
    func encode(path:(in:String, rgba:String, out:String), level:Int, premultiplied:Bool) 
        -> Result<Void, Failure>
    {
        do
        {
            guard let rectangular:PNG.Data.Rectangular = try .decompress(path: path.in)
            else
            {
                return .failure(.init(message: "failed to open file '\(path.in)'"))
            }
            
            try rectangular.compress(path: path.out, level: level)
        }
        catch let error 
        {
            return .failure(.init(message: "\(error)"))
        }
        return Self.decode(path: (in: path.out, rgba: path.rgba), premultiplied: premultiplied)
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
